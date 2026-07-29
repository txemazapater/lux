{ Portable application host for a control tree. }
unit Lux.ControlApplication;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Events,
  Lux.EventSource,
  Lux.Timers,
  Lux.Terminal.Writer,
  Lux.Application,
  Lux.Surface,
  Lux.Control,
  Lux.ControlContainer,
  Lux.FocusManager,
  Lux.MouseDispatcher;

type
  { Owns a root control and focus manager. Routes events into the tree. }
  TLuxControlApplication = class(TLuxApplication)
  private
    FRoot: TLuxRootControl;
    FFocus: TLuxFocusManager;
    FDispatcher: TLuxMouseDispatcher;
    FCaptured: TLuxControl;
    FLastMouseTarget: TLuxControl;
    function GetDispatcherTime: Int64;
    procedure HostInvalidate(Sender: TObject);
    procedure ControlWillFree(Sender: TObject);
    procedure HookWillFree(AControl: TLuxControl);
    procedure UnhookWillFreeIfUnused(AControl: TLuxControl);
    function BelongsToRoot(AControl: TLuxControl): Boolean;
    function CaptureStillValid(AControl: TLuxControl): Boolean;
    procedure ClearCapture;
    procedure EnsureCaptureValid;
    function QueryCaptured: TLuxControl;
    function QueryCursor: TObject;
    procedure SetMouseTarget(ATarget: TLuxControl);
    function TranslateMouseToLocal(AControl: TLuxControl;
      const Event: TLuxEvent): TLuxEvent;
    function HandleTab(const Event: TLuxEvent): Boolean;
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure RenderContent(ASurface: TLuxSurface); override;
    procedure OnResize(AWidth, AHeight: Integer); override;
  public
    constructor Create(AWriter: ILuxTerminalWriter; ASource: ILuxEventSource;
      AWidth, AHeight: Integer; AClock: ILuxClock = nil);
    destructor Destroy; override;

    procedure CaptureMouse(AControl: TLuxControl);
    procedure ReleaseMouse(AControl: TLuxControl);
    function CapturedControl: TLuxControl;

    property Root: TLuxRootControl read FRoot;
    property Focus: TLuxFocusManager read FFocus;
    property Dispatcher: TLuxMouseDispatcher read FDispatcher;
  end;

implementation

function TLuxControlApplication.GetDispatcherTime: Int64;
begin
  Result := ClockNowMs;
end;

constructor TLuxControlApplication.Create(AWriter: ILuxTerminalWriter;
  ASource: ILuxEventSource; AWidth, AHeight: Integer; AClock: ILuxClock);
begin
  inherited Create(AWriter, ASource, AWidth, AHeight, AClock);
  FRoot := TLuxRootControl.Create;
  FRoot.SetBounds(0, 0, Width, Height);
  FRoot.SetHostInvalidate(@HostInvalidate);
  FRoot.SetInteractionHandlers(@CaptureMouse, @ReleaseMouse, @QueryCaptured,
    @QueryCursor);
  FFocus := TLuxFocusManager.Create(FRoot);
  FDispatcher := TLuxMouseDispatcher.Create(FRoot, @GetDispatcherTime);
  FCaptured := nil;
  FLastMouseTarget := nil;
end;

destructor TLuxControlApplication.Destroy;
begin
  ClearCapture;
  SetMouseTarget(nil);
  if FFocus <> nil then
    FFocus.ClearFocus;
  FreeAndNil(FDispatcher);
  FreeAndNil(FFocus);
  FreeAndNil(FRoot);
  inherited Destroy;
end;

procedure TLuxControlApplication.HostInvalidate(Sender: TObject);
begin
  Invalidate;
end;

procedure TLuxControlApplication.ControlWillFree(Sender: TObject);
begin
  if FDispatcher <> nil then
    FDispatcher.ControlInvalidated(TLuxControl(Sender));
  if Sender = FCaptured then
  begin
    TLuxControl(Sender).MouseCaptureLost;
    FCaptured := nil;
  end;
  if Sender = FLastMouseTarget then
    FLastMouseTarget := nil;
end;

procedure TLuxControlApplication.HookWillFree(AControl: TLuxControl);
begin
  if AControl = nil then
    Exit;
  AControl.OnWillFree := @ControlWillFree;
end;

procedure TLuxControlApplication.UnhookWillFreeIfUnused(AControl: TLuxControl);
begin
  if AControl = nil then
    Exit;
  if (AControl <> FCaptured) and (AControl <> FLastMouseTarget) then
    if AControl.OnWillFree = @ControlWillFree then
      AControl.OnWillFree := nil;
end;

function TLuxControlApplication.BelongsToRoot(AControl: TLuxControl): Boolean;
var
  Cur: TLuxControl;
begin
  Result := False;
  Cur := AControl;
  while Cur <> nil do
  begin
    if Cur = FRoot then
      Exit(True);
    Cur := Cur.Parent;
  end;
end;

function TLuxControlApplication.CaptureStillValid(AControl: TLuxControl): Boolean;
begin
  Result := (AControl <> nil) and BelongsToRoot(AControl) and
    AControl.IsEffectivelyVisible and AControl.IsEffectivelyEnabled;
end;

procedure TLuxControlApplication.ClearCapture;
var
  Old: TLuxControl;
begin
  Old := FCaptured;
  FCaptured := nil;
  if Old <> nil then
    Old.MouseCaptureLost;
  UnhookWillFreeIfUnused(Old);
end;

procedure TLuxControlApplication.EnsureCaptureValid;
begin
  if FCaptured = nil then
    Exit;
  if not CaptureStillValid(FCaptured) then
    ClearCapture;
end;

function TLuxControlApplication.QueryCaptured: TLuxControl;
begin
  EnsureCaptureValid;
  Result := FCaptured;
end;

function TLuxControlApplication.QueryCursor: TObject;
begin
  Result := Cursor;
end;

procedure TLuxControlApplication.CaptureMouse(AControl: TLuxControl);
begin
  if AControl = nil then
  begin
    ClearCapture;
    Exit;
  end;
  if not CaptureStillValid(AControl) then
    Exit;
  if FCaptured = AControl then
    Exit;
  ClearCapture;
  FCaptured := AControl;
  HookWillFree(FCaptured);
end;

procedure TLuxControlApplication.ReleaseMouse(AControl: TLuxControl);
begin
  if (AControl = nil) or (AControl <> FCaptured) then
    Exit;
  ClearCapture;
end;

function TLuxControlApplication.CapturedControl: TLuxControl;
begin
  EnsureCaptureValid;
  Result := FCaptured;
end;

procedure TLuxControlApplication.SetMouseTarget(ATarget: TLuxControl);
var
  Old: TLuxControl;
begin
  if FLastMouseTarget = ATarget then
    Exit;
  Old := FLastMouseTarget;
  FLastMouseTarget := ATarget;
  if Old <> nil then
  begin
    Old.MouseLeave;
    UnhookWillFreeIfUnused(Old);
  end;
  if FLastMouseTarget <> nil then
    HookWillFree(FLastMouseTarget);
end;

procedure TLuxControlApplication.OnResize(AWidth, AHeight: Integer);
begin
  inherited OnResize(AWidth, AHeight);
  FRoot.SetBounds(0, 0, AWidth, AHeight);
end;

procedure TLuxControlApplication.RenderContent(ASurface: TLuxSurface);
begin
  ASurface.Clear;
  FRoot.Render(ASurface);
end;

function TLuxControlApplication.TranslateMouseToLocal(AControl: TLuxControl;
  const Event: TLuxEvent): TLuxEvent;
var
  Local: TLuxPoint;
begin
  Result := Event;
  Local := AControl.RootToLocal(LuxPoint(Event.Mouse.X, Event.Mouse.Y));
  Result.Mouse.X := Local.X;
  Result.Mouse.Y := Local.Y;
end;

function TLuxControlApplication.HandleTab(const Event: TLuxEvent): Boolean;
begin
  Result := False;
  if Event.Kind <> ekKey then
    Exit;
  if Event.Key.Action = kaRelease then
    Exit;
  if Event.Key.Key <> lkTab then
    Exit;
  if kmShift in Event.Key.Modifiers then
    Result := FFocus.MovePrevious
  else
    Result := FFocus.MoveNext;
end;

function TLuxControlApplication.HandleEvent(const Event: TLuxEvent): Boolean;
var
  Target: TLuxControl;
  LocalEvent: TLuxEvent;
begin
  FFocus.EnsureValid;
  EnsureCaptureValid;
  Result := False;
  case Event.Kind of
    ekKey:
      begin
        if HandleTab(Event) then
          Exit(True);
        { While capturing we route Escape to the captured control first so
          split drag cancellation can work even if the control is not a
          focus tab stop. }
        if (Event.Key.Action <> kaRelease) and (Event.Key.Key = lkEscape) and
          (FCaptured <> nil) then
        begin
          Target := FCaptured;
          Result := Target.HandleEvent(Event);
          if Result then
            Exit(True);
        end;

        Target := FFocus.FocusedControl;
        if Target = nil then
          Target := FRoot;
        Result := Target.HandleEvent(Event);
      end;
    ekMouse:
      begin
        FDispatcher.HandleMouseEvent(Event.Mouse);

        if CaptureStillValid(FCaptured) then
          Target := FCaptured
        else
          Target := FRoot.HitTestRoot(Event.Mouse.X, Event.Mouse.Y);
        SetMouseTarget(Target);
        if Target = nil then
          Exit(False);
        if (Event.Mouse.Action = maPress) and (Event.Mouse.Button = mbLeft) and
          Target.Focusable and Target.IsEffectivelyEnabled then
          FFocus.SetFocus(Target);
        LocalEvent := TranslateMouseToLocal(Target, Event);
        Target.HandleEvent(LocalEvent);
        Result := True;
        if (Event.Mouse.Action = maRelease) and (Event.Mouse.Button = mbLeft) then
          ReleaseMouse(FCaptured);
      end;
  else
    Result := inherited HandleEvent(Event);
  end;
end;

end.
