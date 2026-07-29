{ Portable application main loop. No platform conditionals. }
unit Lux.Application;

{$mode objfpc}{$H+}

{ Define LUX_RESIZE_TRACE to log observe/commit resize decisions to stderr. }
{.$DEFINE LUX_RESIZE_TRACE}

interface

uses
  SysUtils,
  Lux.Events,
  Lux.EventSource,
  Lux.EventQueue,
  Lux.Timers,
  Lux.Surface,
  Lux.Renderer,
  Lux.Terminal.Writer,
  Lux.Cursor;

const
  { Settle delay before committing an observed terminal size (Phase 5.2.1).
    Change this constant for manual experiments; not a public setting. }
  LuxResizeSettleDelayMs: TLuxTimeMs = 75;

type
  { Minimal interactive host.

    Threading: all callbacks run on the thread that calls Run. Events are
    processed one at a time from the queue. Timers are collected before waiting
    and after each wait. Repaint occurs once per loop iteration after event
    dispatch, and only when Invalidate was requested or a committed resize
    forced it.

    Resize uses two reduction levels:
      1. Queue coalescing of consecutive ekResize to the latest size.
      2. Deferred commit after LuxResizeSettleDelayMs without a newer observe.

    Observed terminal size and committed application size may differ while a
    resize is pending. Intermediate sizes do not resize the surface, invalidate
    the renderer, or paint. While pending, logical events still run but paints
    are deferred until commit (or quit abandons the pending resize).

    Does not know about widgets, focus, layout or mouse capture. }
  TLuxApplication = class
  private
    FWriter: ILuxTerminalWriter;
    FSource: ILuxEventSource;
    FClock: ILuxClock;
    FQueue: TLuxEventQueue;
    FTimers: TLuxTimerScheduler;
    FSurface: TLuxSurface;
    FRenderer: TLuxRenderer;
    FCursor: TLuxCursorManager;
    FQuit: Boolean;
    FNeedsPaint: Boolean;
    FWidth: Integer;
    FHeight: Integer;
    FResizePending: Boolean;
    FPendingResize: TLuxResizeEvent;
    FResizeDeadlineMs: TLuxTimeMs;
    procedure ObserveResize(const AResize: TLuxResizeEvent);
    procedure CommitPendingResize;
    procedure ClearPendingResize;
    procedure HandleResize(const AResize: TLuxResizeEvent);
    procedure DispatchEvent(const Event: TLuxEvent);
    procedure DrainAvailableInput;
    procedure DispatchQueuedEvents;
    procedure PaintIfNeeded;
  protected
    function CombinedWaitTimeoutMs: Integer;
    function ClockNowMs: TLuxTimeMs;
    { Return True if the event was fully handled. }
    function HandleEvent(const Event: TLuxEvent): Boolean; virtual;
    procedure Update; virtual;
    procedure RenderContent(ASurface: TLuxSurface); virtual;
    procedure OnResize(AWidth, AHeight: Integer); virtual;
  public
    constructor Create(AWriter: ILuxTerminalWriter; ASource: ILuxEventSource;
      AWidth, AHeight: Integer; AClock: ILuxClock = nil);
    destructor Destroy; override;

    procedure Run;
    { Dispatch queued events, commit due resize, Update, and paint if needed.
      Does not wait. }
    procedure ProcessPending;
    procedure RequestQuit;
    procedure Invalidate;
    procedure PostEvent(const Event: TLuxEvent);

    function ScheduleOnce(DelayMs: TLuxTimeMs): TLuxTimerId;
    function ScheduleRepeating(IntervalMs: TLuxTimeMs): TLuxTimerId;
    function CancelTimer(AId: TLuxTimerId): Boolean;

    property Surface: TLuxSurface read FSurface;
    property Renderer: TLuxRenderer read FRenderer;
    property Cursor: TLuxCursorManager read FCursor;
    property Queue: TLuxEventQueue read FQueue;
    property Timers: TLuxTimerScheduler read FTimers;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property QuitRequested: Boolean read FQuit;
    { True while an observed size awaits settle before commit. }
    property ResizePending: Boolean read FResizePending;
  end;

implementation

constructor TLuxApplication.Create(AWriter: ILuxTerminalWriter;
  ASource: ILuxEventSource; AWidth, AHeight: Integer; AClock: ILuxClock);
begin
  inherited Create;
  if AWriter = nil then
    raise Exception.Create('TLuxApplication requires a terminal writer.');
  if ASource = nil then
    raise Exception.Create('TLuxApplication requires an event source.');
  if (AWidth < 1) or (AHeight < 1) then
  begin
    AWidth := 80;
    AHeight := 24;
  end;
  FWriter := AWriter;
  FSource := ASource;
  if AClock = nil then
    FClock := TLuxSystemClock.Create
  else
    FClock := AClock;
  FQueue := TLuxEventQueue.Create;
  FTimers := TLuxTimerScheduler.Create(FClock);
  FSurface := TLuxSurface.Create(AWidth, AHeight);
  FRenderer := TLuxRenderer.Create(AWriter);
  FCursor := TLuxCursorManager.Create;
  FCursor.Capabilities := LuxCursorCapsBasic;
  FWidth := AWidth;
  FHeight := AHeight;
  FQuit := False;
  FNeedsPaint := True;
  FResizePending := False;
  FPendingResize.Width := 0;
  FPendingResize.Height := 0;
  FResizeDeadlineMs := 0;
end;

destructor TLuxApplication.Destroy;
begin
  FreeAndNil(FCursor);
  FreeAndNil(FRenderer);
  FreeAndNil(FSurface);
  FreeAndNil(FTimers);
  FreeAndNil(FQueue);
  FClock := nil;
  FSource := nil;
  FWriter := nil;
  inherited Destroy;
end;

procedure TLuxApplication.RequestQuit;
begin
  FQuit := True;
end;

procedure TLuxApplication.Invalidate;
begin
  FNeedsPaint := True;
end;

procedure TLuxApplication.PostEvent(const Event: TLuxEvent);
begin
  FQueue.Push(Event);
end;

function TLuxApplication.ScheduleOnce(DelayMs: TLuxTimeMs): TLuxTimerId;
begin
  Result := FTimers.ScheduleOnce(DelayMs);
end;

function TLuxApplication.ScheduleRepeating(IntervalMs: TLuxTimeMs): TLuxTimerId;
begin
  Result := FTimers.ScheduleRepeating(IntervalMs);
end;

function TLuxApplication.CancelTimer(AId: TLuxTimerId): Boolean;
begin
  Result := FTimers.Cancel(AId);
end;

function TLuxApplication.CombinedWaitTimeoutMs: Integer;
var
  Next, ResizeWait, Best: TLuxTimeMs;
  NowT: TLuxTimeMs;
begin
  Best := -1;
  Next := FTimers.NextDelayMs;
  if Next >= 0 then
    Best := Next;

  if FResizePending then
  begin
    NowT := FClock.NowMs;
    ResizeWait := FResizeDeadlineMs - NowT;
    if ResizeWait < 0 then
      ResizeWait := 0;
    if (Best < 0) or (ResizeWait < Best) then
      Best := ResizeWait;
  end;

  if Best < 0 then
    Exit(-1);
  if Best > High(Integer) then
    Exit(High(Integer));
  Result := Integer(Best);
end;

function TLuxApplication.ClockNowMs: TLuxTimeMs;
begin
  Result := FClock.NowMs;
end;

procedure TLuxApplication.ClearPendingResize;
begin
  FResizePending := False;
  FPendingResize.Width := 0;
  FPendingResize.Height := 0;
  FResizeDeadlineMs := 0;
end;

procedure TLuxApplication.ObserveResize(const AResize: TLuxResizeEvent);
var
  W, H: Integer;
begin
  W := AResize.Width;
  H := AResize.Height;
  if W < 1 then
    W := 1;
  if H < 1 then
    H := 1;

  { Same as already committed: drop pending without commit work. }
  if (W = FWidth) and (H = FHeight) then
  begin
    if FResizePending then
      ClearPendingResize;
    Exit;
  end;

  { Same as current pending: do not restart the deadline. }
  if FResizePending and (W = FPendingResize.Width) and
     (H = FPendingResize.Height) then
    Exit;

  FPendingResize.Width := W;
  FPendingResize.Height := H;
  FResizePending := True;
  FResizeDeadlineMs := FClock.NowMs + LuxResizeSettleDelayMs;

  {$IFDEF LUX_RESIZE_TRACE}
  WriteLn(StdErr, Format('LUX observe resize %dx%d deadline=%d',
    [W, H, FResizeDeadlineMs]));
  {$ENDIF}
end;

procedure TLuxApplication.CommitPendingResize;
var
  Pending: TLuxResizeEvent;
begin
  if not FResizePending then
    Exit;
  if FClock.NowMs < FResizeDeadlineMs then
    Exit;

  Pending := FPendingResize;

  {$IFDEF LUX_RESIZE_TRACE}
  WriteLn(StdErr, Format('LUX commit resize %dx%d',
    [Pending.Width, Pending.Height]));
  {$ENDIF}

  ClearPendingResize;
  HandleResize(Pending);
end;

procedure TLuxApplication.HandleResize(const AResize: TLuxResizeEvent);
var
  W, H: Integer;
begin
  W := AResize.Width;
  H := AResize.Height;
  if W < 1 then
    W := 1;
  if H < 1 then
    H := 1;
  if (W = FWidth) and (H = FHeight) then
  begin
    FRenderer.Invalidate;
    FNeedsPaint := True;
    Exit;
  end;
  FWidth := W;
  FHeight := H;
  FSurface.Resize(W, H);
  FRenderer.Invalidate;
  FNeedsPaint := True;
  OnResize(W, H);
end;

function TLuxApplication.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
end;

procedure TLuxApplication.Update;
begin
end;

procedure TLuxApplication.RenderContent(ASurface: TLuxSurface);
begin
end;

procedure TLuxApplication.OnResize(AWidth, AHeight: Integer);
begin
end;

procedure TLuxApplication.DispatchEvent(const Event: TLuxEvent);
begin
  case Event.Kind of
    ekQuit:
      begin
        FQuit := True;
        HandleEvent(Event);
      end;
    ekResize:
      begin
        ObserveResize(Event.Resize);
        HandleEvent(Event);
      end;
    ekTimer:
      begin
        HandleEvent(Event);
        Invalidate;
      end;
  else
    if HandleEvent(Event) then
      Invalidate;
  end;
end;

procedure TLuxApplication.DrainAvailableInput;
var
  Ev: TLuxEvent;
begin
  while FSource.PollEvent(Ev) do
    FQueue.Push(Ev);
end;

procedure TLuxApplication.DispatchQueuedEvents;
var
  Ev, Next: TLuxEvent;
begin
  while FQueue.TryPop(Ev) do
  begin
    { Level 1: coalesce back-to-back resizes to the latest queued size. }
    if Ev.Kind = ekResize then
      while FQueue.Peek(Next) and (Next.Kind = ekResize) do
        FQueue.TryPop(Ev);

    DispatchEvent(Ev);
    if FQuit then
      Break;
  end;
end;

procedure TLuxApplication.PaintIfNeeded;
var
  C: TLuxCursorState;
  DidWork: Boolean;
begin
  if FQuit or FResizePending then
    Exit;

  DidWork := False;
  if FNeedsPaint then
  begin
    RenderContent(FSurface);
    FRenderer.Render(FSurface, False);
    FCursor.MarkPaintDirtied;
    FNeedsPaint := False;
    DidWork := True;
  end;

  if FCursor.Commit(FWriter) then
  begin
    C := FCursor.Committed;
    FRenderer.SyncExternalCursor(C.X, C.Y, C.Visible);
    DidWork := True;
  end;

  if DidWork then
    FWriter.Flush;
end;

procedure TLuxApplication.ProcessPending;
begin
  FTimers.CollectDueToQueue(FQueue);
  DispatchQueuedEvents;
  if FQuit then
    Exit;

  CommitPendingResize;
  if FQuit then
    Exit;

  Update;
  PaintIfNeeded;
end;

procedure TLuxApplication.Run;
var
  Ev: TLuxEvent;
  WaitMs: Integer;
begin
  FQuit := False;
  FNeedsPaint := True;
  try
    while not FQuit do
    begin
      FTimers.CollectDueToQueue(FQueue);

      if FQueue.IsEmpty then
      begin
        WaitMs := CombinedWaitTimeoutMs;
        if FSource.WaitEvent(Ev, WaitMs) then
          FQueue.Push(Ev);
        { Pull any further events already pending so resizes can coalesce. }
        DrainAvailableInput;
        FTimers.CollectDueToQueue(FQueue);
      end;

      ProcessPending;
    end;
  finally
    { Session restore is the caller's responsibility (try/finally around Run).
      Pending resize is abandoned on quit; no wait for the settle deadline. }
  end;
end;

end.
