{ Portable application main loop. No platform conditionals. }
unit Lux.Application;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Events,
  Lux.EventSource,
  Lux.EventQueue,
  Lux.Timers,
  Lux.Surface,
  Lux.Renderer,
  Lux.Terminal.Writer;

type
  { Minimal interactive host.

    Threading: all callbacks run on the thread that calls Run. Events are
    processed one at a time from the queue. Timers are collected before waiting
    and after each wait. Repaint occurs once per loop iteration after event
    dispatch, and only when Invalidate was requested or a resize forced it.

    Does not know about widgets, focus, layout or mouse capture. }
  TLuxApplication = class
  private
    FWriter: ILuxTerminalWriter;
    FSource: ILuxEventSource;
    FQueue: TLuxEventQueue;
    FTimers: TLuxTimerScheduler;
    FSurface: TLuxSurface;
    FRenderer: TLuxRenderer;
    FQuit: Boolean;
    FNeedsPaint: Boolean;
    FWidth: Integer;
    FHeight: Integer;
    function CombinedWaitTimeoutMs: Integer;
    procedure HandleResize(const AResize: TLuxResizeEvent);
    procedure DispatchEvent(const Event: TLuxEvent);
  protected
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
    procedure RequestQuit;
    procedure Invalidate;
    procedure PostEvent(const Event: TLuxEvent);

    function ScheduleOnce(DelayMs: TLuxTimeMs): TLuxTimerId;
    function ScheduleRepeating(IntervalMs: TLuxTimeMs): TLuxTimerId;
    function CancelTimer(AId: TLuxTimerId): Boolean;

    property Surface: TLuxSurface read FSurface;
    property Renderer: TLuxRenderer read FRenderer;
    property Queue: TLuxEventQueue read FQueue;
    property Timers: TLuxTimerScheduler read FTimers;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property QuitRequested: Boolean read FQuit;
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
  FQueue := TLuxEventQueue.Create;
  FTimers := TLuxTimerScheduler.Create(AClock);
  FSurface := TLuxSurface.Create(AWidth, AHeight);
  FRenderer := TLuxRenderer.Create(AWriter);
  FWidth := AWidth;
  FHeight := AHeight;
  FQuit := False;
  FNeedsPaint := True;
end;

destructor TLuxApplication.Destroy;
begin
  FreeAndNil(FRenderer);
  FreeAndNil(FSurface);
  FreeAndNil(FTimers);
  FreeAndNil(FQueue);
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
  Next: TLuxTimeMs;
begin
  Next := FTimers.NextDelayMs;
  if Next < 0 then
    Exit(-1);
  if Next > High(Integer) then
    Exit(High(Integer));
  Result := Integer(Next);
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
        HandleResize(Event.Resize);
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
        FTimers.CollectDueToQueue(FQueue);
      end;

      while FQueue.TryPop(Ev) do
      begin
        DispatchEvent(Ev);
        if FQuit then
          Break;
      end;

      Update;

      if FNeedsPaint and (not FQuit) then
      begin
        RenderContent(FSurface);
        FRenderer.Render(FSurface);
        FNeedsPaint := False;
      end;
    end;
  finally
    { Session restore is the caller's responsibility (try/finally around Run). }
  end;
end;

end.
