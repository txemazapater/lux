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
  Lux.FocusManager;

type
  { Owns a root control and focus manager. Routes events into the tree. }
  TLuxControlApplication = class(TLuxApplication)
  private
    FRoot: TLuxRootControl;
    FFocus: TLuxFocusManager;
    procedure HostInvalidate(Sender: TObject);
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

    property Root: TLuxRootControl read FRoot;
    property Focus: TLuxFocusManager read FFocus;
  end;

implementation

constructor TLuxControlApplication.Create(AWriter: ILuxTerminalWriter;
  ASource: ILuxEventSource; AWidth, AHeight: Integer; AClock: ILuxClock);
begin
  inherited Create(AWriter, ASource, AWidth, AHeight, AClock);
  FRoot := TLuxRootControl.Create;
  FRoot.SetBounds(0, 0, Width, Height);
  FRoot.SetHostInvalidate(@HostInvalidate);
  FFocus := TLuxFocusManager.Create(FRoot);
end;

destructor TLuxControlApplication.Destroy;
begin
  if FFocus <> nil then
    FFocus.ClearFocus;
  FreeAndNil(FFocus);
  FreeAndNil(FRoot);
  inherited Destroy;
end;

procedure TLuxControlApplication.HostInvalidate(Sender: TObject);
begin
  Invalidate;
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
  Result := False;
  case Event.Kind of
    ekKey:
      begin
        if HandleTab(Event) then
          Exit(True);
        Target := FFocus.FocusedControl;
        if Target = nil then
          Target := FRoot;
        Result := Target.HandleEvent(Event);
      end;
    ekMouse:
      begin
        Target := FRoot.HitTestRoot(Event.Mouse.X, Event.Mouse.Y);
        if Target = nil then
          Exit(False);
        if (Event.Mouse.Action = maPress) and (Event.Mouse.Button = mbLeft) and
          Target.Focusable and Target.IsEffectivelyEnabled then
          FFocus.SetFocus(Target);
        LocalEvent := TranslateMouseToLocal(Target, Event);
        Result := Target.HandleEvent(LocalEvent);
      end;
  else
    Result := inherited HandleEvent(Event);
  end;
end;

end.
