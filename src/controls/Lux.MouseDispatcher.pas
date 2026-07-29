{ Centralized semantic mouse dispatcher. Portable; no platform APIs. }
unit Lux.MouseDispatcher;

{$mode objfpc}{$H+}

interface

uses
  Lux.Geometry,
  Lux.Events,
  Lux.Control,
  Lux.ControlContainer;

type
  TLuxGetTimeFunc = function: Int64 of object;

  TLuxMouseDispatcher = class
  private
    FRoot: TLuxRootControl;
    FGetTime: TLuxGetTimeFunc;

    FHoveredControl: TLuxControl;
    FPressedControl: TLuxControl;
    FPressedButton: TLuxMouseButton;
    FPressX: Integer;
    FPressY: Integer;
    FPressRootX: Integer;
    FPressRootY: Integer;
    FIsDragCandidate: Boolean;
    FIsDragging: Boolean;
    FLastRootX: Integer;
    FLastRootY: Integer;

    FLastClickControl: TLuxControl;
    FLastClickButton: TLuxMouseButton;
    FLastClickTime: Int64;
    FLastClickX: Integer;
    FLastClickY: Integer;

    FDragThreshold: Integer;
    FDoubleClickTimeMs: Int64;
    FDoubleClickDistance: Integer;

    function HitTest(AX, AY: Integer): TLuxControl;
    function CapturedControl: TLuxControl;
    procedure UpdateHover(ATarget: TLuxControl; AX, AY: Integer; AModifiers: TLuxKeyModifiers);
    procedure ClearPress;
    procedure CancelDrag;
    function MakeSemanticEvent(AControl: TLuxControl; ARootX, ARootY: Integer;
      AButton: TLuxMouseButton; AModifiers: TLuxKeyModifiers): TLuxSemanticMouseEvent;
    function MakeDragEvent(AControl: TLuxControl; ARootX, ARootY: Integer;
      AButton: TLuxMouseButton; AModifiers: TLuxKeyModifiers): TLuxDragEvent;
    function MakeWheelEvent(AControl: TLuxControl; ARootX, ARootY: Integer;
      ADelta: Integer; AHorizontal: Boolean; AModifiers: TLuxKeyModifiers): TLuxWheelEvent;
  public
    constructor Create(ARoot: TLuxRootControl; AGetTime: TLuxGetTimeFunc);

    procedure HandleMouseEvent(const Event: TLuxMouseEvent);
    procedure CancelPointerInteraction;
    procedure ControlInvalidated(AControl: TLuxControl);

    property DragThreshold: Integer read FDragThreshold write FDragThreshold;
    property DoubleClickTimeMs: Int64 read FDoubleClickTimeMs write FDoubleClickTimeMs;
    property DoubleClickDistance: Integer read FDoubleClickDistance write FDoubleClickDistance;
    property HoveredControl: TLuxControl read FHoveredControl;
    property PressedControl: TLuxControl read FPressedControl;
    property IsDragging: Boolean read FIsDragging;
  end;

implementation

constructor TLuxMouseDispatcher.Create(ARoot: TLuxRootControl; AGetTime: TLuxGetTimeFunc);
begin
  inherited Create;
  FRoot := ARoot;
  FGetTime := AGetTime;
  FHoveredControl := nil;
  FPressedControl := nil;
  FPressedButton := mbNone;
  FIsDragCandidate := False;
  FIsDragging := False;
  FLastClickControl := nil;
  FLastClickButton := mbNone;
  FLastClickTime := 0;
  FLastClickX := 0;
  FLastClickY := 0;
  FDragThreshold := 2;
  FDoubleClickTimeMs := 500;
  FDoubleClickDistance := 2;
  FLastRootX := 0;
  FLastRootY := 0;
end;

function TLuxMouseDispatcher.HitTest(AX, AY: Integer): TLuxControl;
var
  Captured: TLuxControl;
begin
  Captured := CapturedControl;
  if Captured <> nil then
    Result := Captured
  else
    Result := FRoot.HitTestRoot(AX, AY);
end;

function TLuxMouseDispatcher.CapturedControl: TLuxControl;
begin
  Result := FRoot.CurrentCapturedControl;
end;

function TLuxMouseDispatcher.MakeSemanticEvent(AControl: TLuxControl;
  ARootX, ARootY: Integer; AButton: TLuxMouseButton;
  AModifiers: TLuxKeyModifiers): TLuxSemanticMouseEvent;
var
  Local: TLuxPoint;
begin
  Local := AControl.RootToLocal(LuxPoint(ARootX, ARootY));
  Result.X := Local.X;
  Result.Y := Local.Y;
  Result.Button := AButton;
  Result.Modifiers := AModifiers;
end;

function TLuxMouseDispatcher.MakeDragEvent(AControl: TLuxControl;
  ARootX, ARootY: Integer; AButton: TLuxMouseButton;
  AModifiers: TLuxKeyModifiers): TLuxDragEvent;
var
  Local, Start: TLuxPoint;
begin
  Local := AControl.RootToLocal(LuxPoint(ARootX, ARootY));
  Start := AControl.RootToLocal(LuxPoint(FPressRootX, FPressRootY));
  Result.X := Local.X;
  Result.Y := Local.Y;
  Result.StartX := Start.X;
  Result.StartY := Start.Y;
  Result.DeltaX := ARootX - FLastRootX;
  Result.DeltaY := ARootY - FLastRootY;
  Result.Button := AButton;
  Result.Modifiers := AModifiers;
end;

function TLuxMouseDispatcher.MakeWheelEvent(AControl: TLuxControl;
  ARootX, ARootY: Integer; ADelta: Integer; AHorizontal: Boolean;
  AModifiers: TLuxKeyModifiers): TLuxWheelEvent;
var
  Local: TLuxPoint;
begin
  Local := AControl.RootToLocal(LuxPoint(ARootX, ARootY));
  Result.X := Local.X;
  Result.Y := Local.Y;
  Result.Delta := ADelta;
  Result.Horizontal := AHorizontal;
  Result.Modifiers := AModifiers;
end;

procedure TLuxMouseDispatcher.UpdateHover(ATarget: TLuxControl; AX, AY: Integer;
  AModifiers: TLuxKeyModifiers);
var
  PhysicalTarget: TLuxControl;
  Ev: TLuxSemanticMouseEvent;
begin
  PhysicalTarget := FRoot.HitTestRoot(AX, AY);
  if PhysicalTarget = FHoveredControl then
  begin
    if (FHoveredControl <> nil) and (not FIsDragging) then
    begin
      Ev := MakeSemanticEvent(FHoveredControl, AX, AY, mbNone, AModifiers);
      FHoveredControl.SemanticMouseMove(Ev);
    end;
    Exit;
  end;
  if FHoveredControl <> nil then
    FHoveredControl.SemanticMouseLeave;
  FHoveredControl := PhysicalTarget;
  if FHoveredControl <> nil then
  begin
    Ev := MakeSemanticEvent(FHoveredControl, AX, AY, mbNone, AModifiers);
    FHoveredControl.SemanticMouseEnter(Ev);
  end;
end;

procedure TLuxMouseDispatcher.ClearPress;
begin
  FPressedControl := nil;
  FPressedButton := mbNone;
  FIsDragCandidate := False;
  FIsDragging := False;
end;

procedure TLuxMouseDispatcher.CancelDrag;
var
  Ctrl: TLuxControl;
begin
  if FIsDragging then
  begin
    Ctrl := FPressedControl;
    ClearPress;
    if Ctrl <> nil then
      Ctrl.SemanticDragCancel;
  end
  else
    ClearPress;
end;

procedure TLuxMouseDispatcher.HandleMouseEvent(const Event: TLuxMouseEvent);
var
  Target: TLuxControl;
  Ev: TLuxSemanticMouseEvent;
  DragEv: TLuxDragEvent;
  WheelEv: TLuxWheelEvent;
  DX, DY: Integer;
  NowT: Int64;
  Cur: TLuxControl;
begin
  case Event.Action of
    maPress:
      begin
        Target := HitTest(Event.X, Event.Y);
        UpdateHover(Target, Event.X, Event.Y, Event.Modifiers);
        if Target = nil then
          Exit;
        FPressedControl := Target;
        FPressedButton := Event.Button;
        FPressX := Event.X;
        FPressY := Event.Y;
        FPressRootX := Event.X;
        FPressRootY := Event.Y;
        FIsDragCandidate := True;
        FIsDragging := False;
        FLastRootX := Event.X;
        FLastRootY := Event.Y;
        Ev := MakeSemanticEvent(Target, Event.X, Event.Y, Event.Button, Event.Modifiers);
        Target.SemanticMouseDown(Ev);
      end;

    maMove:
      begin
        Target := HitTest(Event.X, Event.Y);
        UpdateHover(Target, Event.X, Event.Y, Event.Modifiers);

        if FPressedControl <> nil then
        begin
          if FIsDragging then
          begin
            DragEv := MakeDragEvent(FPressedControl, Event.X, Event.Y,
              FPressedButton, Event.Modifiers);
            FLastRootX := Event.X;
            FLastRootY := Event.Y;
            FPressedControl.SemanticDragMove(DragEv);
          end
          else if FIsDragCandidate then
          begin
            DX := Event.X - FPressRootX;
            DY := Event.Y - FPressRootY;
            if (Abs(DX) >= FDragThreshold) or (Abs(DY) >= FDragThreshold) then
            begin
              FIsDragCandidate := False;
              FIsDragging := True;
              DragEv := MakeDragEvent(FPressedControl, Event.X, Event.Y,
                FPressedButton, Event.Modifiers);
              FLastRootX := Event.X;
              FLastRootY := Event.Y;
              FPressedControl.SemanticDragBegin(DragEv);
            end;
          end;
        end;
      end;

    maRelease:
      begin
        Target := HitTest(Event.X, Event.Y);
        UpdateHover(Target, Event.X, Event.Y, Event.Modifiers);

        if FPressedControl <> nil then
        begin
          if FIsDragging then
          begin
            DragEv := MakeDragEvent(FPressedControl, Event.X, Event.Y,
              FPressedButton, Event.Modifiers);
            FLastRootX := Event.X;
            FLastRootY := Event.Y;
            FPressedControl.SemanticDragEnd(DragEv);
            ClearPress;
          end
          else
          begin
            Ev := MakeSemanticEvent(FPressedControl, Event.X, Event.Y,
              Event.Button, Event.Modifiers);
            FPressedControl.SemanticMouseUp(Ev);

            if (Event.Button = FPressedButton) and
              (FRoot.HitTestRoot(Event.X, Event.Y) = FPressedControl) then
            begin
              FPressedControl.SemanticClick(Ev);

              NowT := FGetTime();
              if (FLastClickControl = FPressedControl) and
                (FLastClickButton = FPressedButton) and
                (NowT - FLastClickTime <= FDoubleClickTimeMs) and
                (Abs(Event.X - FLastClickX) <= FDoubleClickDistance) and
                (Abs(Event.Y - FLastClickY) <= FDoubleClickDistance) then
              begin
                FPressedControl.SemanticDoubleClick(Ev);
                FLastClickControl := nil;
                FLastClickTime := 0;
              end
              else
              begin
                FLastClickControl := FPressedControl;
                FLastClickButton := FPressedButton;
                FLastClickTime := NowT;
                FLastClickX := Event.X;
                FLastClickY := Event.Y;
              end;
            end
            else
            begin
              FLastClickControl := nil;
              FLastClickTime := 0;
            end;
            ClearPress;
          end;
        end;
      end;

    maWheel:
      begin
        Target := FRoot.HitTestRoot(Event.X, Event.Y);
        if Target = nil then
          Exit;
        Cur := Target;
        while Cur <> nil do
        begin
          WheelEv := MakeWheelEvent(Cur, Event.X, Event.Y, Event.WheelDelta,
            Event.WheelHorizontal, Event.Modifiers);
          if Cur.SemanticMouseWheel(WheelEv) then
            Exit;
          Cur := Cur.Parent;
        end;
      end;

    maDoubleClick:
      begin
        { Platform double-click treated as a normal press for dispatcher's own
          recognition. Forward as maPress. }
        Target := HitTest(Event.X, Event.Y);
        UpdateHover(Target, Event.X, Event.Y, Event.Modifiers);
        if Target = nil then
          Exit;
        FPressedControl := Target;
        FPressedButton := Event.Button;
        FPressX := Event.X;
        FPressY := Event.Y;
        FPressRootX := Event.X;
        FPressRootY := Event.Y;
        FIsDragCandidate := True;
        FIsDragging := False;
        FLastRootX := Event.X;
        FLastRootY := Event.Y;
        Ev := MakeSemanticEvent(Target, Event.X, Event.Y, Event.Button, Event.Modifiers);
        Target.SemanticMouseDown(Ev);
      end;
  end;
end;

procedure TLuxMouseDispatcher.CancelPointerInteraction;
var
  Ctrl: TLuxControl;
  WasDragging: Boolean;
begin
  Ctrl := FPressedControl;
  WasDragging := FIsDragging;
  ClearPress;
  if WasDragging and (Ctrl <> nil) then
    Ctrl.SemanticDragCancel;
  if FHoveredControl <> nil then
  begin
    FHoveredControl.SemanticMouseLeave;
    FHoveredControl := nil;
  end;
  FLastClickControl := nil;
  FLastClickTime := 0;
end;

procedure TLuxMouseDispatcher.ControlInvalidated(AControl: TLuxControl);
begin
  if AControl = FHoveredControl then
    FHoveredControl := nil;
  if AControl = FPressedControl then
    ClearPress;
  if AControl = FLastClickControl then
  begin
    FLastClickControl := nil;
    FLastClickTime := 0;
  end;
end;

end.
