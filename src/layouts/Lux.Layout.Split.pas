{ Two-pane split container with an internal draggable divider.
  No standalone splitter control. No platform APIs. }
unit Lux.Layout.Split;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Events,
  Lux.Control,
  Lux.ControlContainer,
  Lux.Cursor;

const
  LuxSplitRatioMax = 10000;
  LuxSplitRatioHalf = 5000;

type
  { loVertical = vertical divider (panes left/right).
    loHorizontal = horizontal divider (panes top/bottom). }
  TLuxOrientation = (loHorizontal, loVertical);

  TLuxSplitContainer = class(TLuxControlContainer)
  private
    FFirstPane: TLuxControl;
    FSecondPane: TLuxControl;
    FOrientation: TLuxOrientation;
    FRatio: Integer;
    FDividerSize: Integer;
    FFirstMinimumSize: Integer;
    FSecondMinimumSize: Integer;
    FHovered: Boolean;
    FDragging: Boolean;
    FDragGrab: Integer;
    FCursorActive: Boolean;
    FLayouting: Boolean;
    procedure SetOrientation(AValue: TLuxOrientation);
    procedure SetRatio(AValue: Integer);
    procedure SetDividerSize(AValue: Integer);
    procedure SetFirstMinimumSize(AValue: Integer);
    procedure SetSecondMinimumSize(AValue: Integer);
    procedure SetFirstPane(AControl: TLuxControl);
    procedure SetSecondPane(AControl: TLuxControl);
    function EffectiveDividerSize(AClientMain: Integer): Integer;
    function DistributableMain(AClientMain: Integer): Integer;
    function ClampFirstMain(AIdeal, ADist, AMin1, AMin2: Integer): Integer;
    function FirstMainFromRatio(ADist: Integer): Integer;
    function RatioFromFirstMain(AFirstMain, ADist: Integer): Integer;
    function DividerLocalRect: TLuxRect;
    procedure ApplyLayout;
    procedure InvalidateDivider;
    procedure UpdateHoverFromLocal(AX, AY: Integer);
    procedure BeginDrag(AX, AY: Integer);
    procedure UpdateDrag(AX, AY: Integer);
    procedure EndDrag(AX, AY: Integer);
    procedure RequestSplitCursor;
    procedure ClearSplitCursor;
    function CursorManager: TLuxCursorManager;
  protected
    function AcceptChild(AChild: TLuxControl): Boolean; override;
    procedure DetachChild(AChild: TLuxControl); override;
    procedure BoundsChanged; override;
    function HitTestInternalRoot(AX, AY: Integer): Boolean; override;
    procedure Paint(const Ctx: TLuxPaintContext); override;
    procedure PaintDivider(const Ctx: TLuxPaintContext); virtual;
    function DoHandleEvent(const Event: TLuxEvent): Boolean; override;
  public
    constructor Create(AParent: TLuxControl = nil);
    destructor Destroy; override;

    procedure Render(const Ctx: TLuxPaintContext); override;
    procedure MouseLeave; override;

    property FirstPane: TLuxControl read FFirstPane write SetFirstPane;
    property SecondPane: TLuxControl read FSecondPane write SetSecondPane;
    property Orientation: TLuxOrientation read FOrientation write SetOrientation;
    property Ratio: Integer read FRatio write SetRatio;
    property DividerSize: Integer read FDividerSize write SetDividerSize;
    property FirstMinimumSize: Integer read FFirstMinimumSize write SetFirstMinimumSize;
    property SecondMinimumSize: Integer read FSecondMinimumSize write SetSecondMinimumSize;
    property Hovered: Boolean read FHovered;
    property Dragging: Boolean read FDragging;
  end;

implementation

constructor TLuxSplitContainer.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FOrientation := loVertical;
  FRatio := LuxSplitRatioHalf;
  FDividerSize := 1;
  FFirstMinimumSize := 0;
  FSecondMinimumSize := 0;
  FHovered := False;
  FDragging := False;
  FDragGrab := 0;
  FCursorActive := False;
  FLayouting := False;
  Focusable := False;
end;

destructor TLuxSplitContainer.Destroy;
begin
  ClearSplitCursor;
  inherited Destroy;
end;

procedure TLuxSplitContainer.SetOrientation(AValue: TLuxOrientation);
begin
  if FOrientation = AValue then
    Exit;
  FOrientation := AValue;
  ApplyLayout;
  Invalidate;
end;

procedure TLuxSplitContainer.SetRatio(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if AValue > LuxSplitRatioMax then
    AValue := LuxSplitRatioMax;
  if FRatio = AValue then
    Exit;
  FRatio := AValue;
  ApplyLayout;
  Invalidate;
end;

procedure TLuxSplitContainer.SetDividerSize(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FDividerSize = AValue then
    Exit;
  FDividerSize := AValue;
  ApplyLayout;
  Invalidate;
end;

procedure TLuxSplitContainer.SetFirstMinimumSize(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FFirstMinimumSize = AValue then
    Exit;
  FFirstMinimumSize := AValue;
  ApplyLayout;
  Invalidate;
end;

procedure TLuxSplitContainer.SetSecondMinimumSize(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FSecondMinimumSize = AValue then
    Exit;
  FSecondMinimumSize := AValue;
  ApplyLayout;
  Invalidate;
end;

procedure TLuxSplitContainer.SetFirstPane(AControl: TLuxControl);
var
  Old: TLuxControl;
begin
  if FFirstPane = AControl then
    Exit;
  Old := FFirstPane;
  FFirstPane := nil;
  if Old <> nil then
    RemoveChild(Old);
  FFirstPane := AControl;
  if AControl <> nil then
  begin
    if IndexOfChild(AControl) < 0 then
      AddChild(AControl);
  end;
  ApplyLayout;
end;

procedure TLuxSplitContainer.SetSecondPane(AControl: TLuxControl);
var
  Old: TLuxControl;
begin
  if FSecondPane = AControl then
    Exit;
  Old := FSecondPane;
  FSecondPane := nil;
  if Old <> nil then
    RemoveChild(Old);
  FSecondPane := AControl;
  if AControl <> nil then
  begin
    if IndexOfChild(AControl) < 0 then
      AddChild(AControl);
  end;
  ApplyLayout;
end;

function TLuxSplitContainer.AcceptChild(AChild: TLuxControl): Boolean;
begin
  if (AChild <> FFirstPane) and (AChild <> FSecondPane) then
  begin
    if (FFirstPane <> nil) and (FSecondPane <> nil) then
      raise ELuxControl.Create('TLuxSplitContainer accepts at most two pane controls.');
  end;
  Result := inherited AcceptChild(AChild);
  if AChild = FFirstPane then
    { assigned via setter }
  else if AChild = FSecondPane then
    { assigned via setter }
  else if FFirstPane = nil then
    FFirstPane := AChild
  else if FSecondPane = nil then
    FSecondPane := AChild;
  ApplyLayout;
end;

procedure TLuxSplitContainer.DetachChild(AChild: TLuxControl);
begin
  if AChild = FFirstPane then
    FFirstPane := nil;
  if AChild = FSecondPane then
    FSecondPane := nil;
  inherited DetachChild(AChild);
  if not FLayouting then
    ApplyLayout;
end;

procedure TLuxSplitContainer.BoundsChanged;
begin
  inherited BoundsChanged;
  ApplyLayout;
end;

function TLuxSplitContainer.EffectiveDividerSize(AClientMain: Integer): Integer;
begin
  Result := FDividerSize;
  if Result < 0 then
    Result := 0;
  if Result > AClientMain then
    Result := AClientMain;
end;

function TLuxSplitContainer.DistributableMain(AClientMain: Integer): Integer;
begin
  Result := AClientMain - EffectiveDividerSize(AClientMain);
  if Result < 0 then
    Result := 0;
end;

function TLuxSplitContainer.ClampFirstMain(AIdeal, ADist, AMin1, AMin2: Integer): Integer;
var
  MaxFirst: Integer;
begin
  if ADist < 0 then
    ADist := 0;
  if AMin1 < 0 then
    AMin1 := 0;
  if AMin2 < 0 then
    AMin2 := 0;

  if AMin1 + AMin2 > ADist then
  begin
    if AMin1 + AMin2 = 0 then
      Result := ADist div 2
    else
      Result := (ADist * AMin1) div (AMin1 + AMin2);
    Exit;
  end;

  Result := AIdeal;
  if Result < AMin1 then
    Result := AMin1;
  MaxFirst := ADist - AMin2;
  if Result > MaxFirst then
    Result := MaxFirst;
end;

function TLuxSplitContainer.FirstMainFromRatio(ADist: Integer): Integer;
var
  Ideal: Integer;
begin
  if ADist <= 0 then
    Exit(0);
  Ideal := (FRatio * ADist) div LuxSplitRatioMax;
  Result := ClampFirstMain(Ideal, ADist, FFirstMinimumSize, FSecondMinimumSize);
end;

function TLuxSplitContainer.RatioFromFirstMain(AFirstMain, ADist: Integer): Integer;
begin
  if ADist <= 0 then
    Exit(FRatio);
  if AFirstMain < 0 then
    AFirstMain := 0;
  if AFirstMain > ADist then
    AFirstMain := ADist;
  { Ceiling division so FirstMainFromRatio reconstructs AFirstMain. }
  Result := (AFirstMain * LuxSplitRatioMax + ADist - 1) div ADist;
  if Result < 0 then
    Result := 0;
  if Result > LuxSplitRatioMax then
    Result := LuxSplitRatioMax;
end;

procedure TLuxSplitContainer.ApplyLayout;
var
  Sz: TLuxSize;
  Dist, DivSz, FirstMain, SecondMain: Integer;
begin
  if FLayouting then
    Exit;
  FLayouting := True;
  try
    Sz := ClientSize;
    if FOrientation = loVertical then
    begin
      Dist := DistributableMain(Sz.Width);
      DivSz := EffectiveDividerSize(Sz.Width);
      FirstMain := FirstMainFromRatio(Dist);
      SecondMain := Dist - FirstMain;
      if FFirstPane <> nil then
        FFirstPane.SetBounds(0, 0, FirstMain, Sz.Height);
      if FSecondPane <> nil then
        FSecondPane.SetBounds(FirstMain + DivSz, 0, SecondMain, Sz.Height);
    end
    else
    begin
      Dist := DistributableMain(Sz.Height);
      DivSz := EffectiveDividerSize(Sz.Height);
      FirstMain := FirstMainFromRatio(Dist);
      SecondMain := Dist - FirstMain;
      if FFirstPane <> nil then
        FFirstPane.SetBounds(0, 0, Sz.Width, FirstMain);
      if FSecondPane <> nil then
        FSecondPane.SetBounds(0, FirstMain + DivSz, Sz.Width, SecondMain);
    end;
  finally
    FLayouting := False;
  end;
end;

function TLuxSplitContainer.DividerLocalRect: TLuxRect;
var
  Sz: TLuxSize;
  Dist, DivSz, FirstMain: Integer;
begin
  Sz := ClientSize;
  if FOrientation = loVertical then
  begin
    Dist := DistributableMain(Sz.Width);
    DivSz := EffectiveDividerSize(Sz.Width);
    FirstMain := FirstMainFromRatio(Dist);
    Result := LuxRect(FirstMain, 0, DivSz, Sz.Height);
  end
  else
  begin
    Dist := DistributableMain(Sz.Height);
    DivSz := EffectiveDividerSize(Sz.Height);
    FirstMain := FirstMainFromRatio(Dist);
    Result := LuxRect(0, FirstMain, Sz.Width, DivSz);
  end;
end;

function TLuxSplitContainer.HitTestInternalRoot(AX, AY: Integer): Boolean;
var
  Local: TLuxPoint;
  DivR: TLuxRect;
begin
  Result := False;
  if (FFirstPane = nil) or (FSecondPane = nil) then
    Exit;
  DivR := DividerLocalRect;
  if LuxRectIsEmpty(DivR) then
    Exit;
  Local := RootToLocal(LuxPoint(AX, AY));
  Result := LuxRectContainsXY(DivR, Local.X, Local.Y);
end;

procedure TLuxSplitContainer.Paint(const Ctx: TLuxPaintContext);
begin
  { Transparent host: panes paint their own backgrounds. }
end;

procedure TLuxSplitContainer.PaintDivider(const Ctx: TLuxPaintContext);
var
  DivR: TLuxRect;
  Fg, Bg: TLuxColor;
  Fill: TLuxCell;
  Ch: UnicodeString;
  X, Y: Integer;
begin
  DivR := DividerLocalRect;
  if LuxRectIsEmpty(DivR) then
    Exit;

  if FDragging then
  begin
    Fg := LuxColorRGB(240, 240, 255);
    Bg := LuxColorRGB(80, 120, 200);
  end
  else if FHovered then
  begin
    Fg := LuxColorRGB(220, 230, 255);
    Bg := LuxColorRGB(60, 90, 150);
  end
  else
  begin
    Fg := LuxColorRGB(160, 160, 180);
    Bg := LuxColorRGB(40, 40, 55);
  end;

  if FOrientation = loVertical then
    Ch := UnicodeString(WideChar($2502))
  else
    Ch := UnicodeString(WideChar($2500));

  Fill := LuxCellMake(Ch, 1, Fg, Bg, []);
  for Y := 0 to DivR.Height - 1 do
    for X := 0 to DivR.Width - 1 do
      LuxPaintFill(Ctx, LuxRect(DivR.Left + X, DivR.Top + Y, 1, 1), Fill);
end;

procedure TLuxSplitContainer.Render(const Ctx: TLuxPaintContext);
begin
  if not Visible then
    Exit;
  if LuxRectIsEmpty(Ctx.Clip) then
    Exit;
  Paint(Ctx);
  PaintChildren(Ctx);
  PaintDivider(Ctx);
end;

procedure TLuxSplitContainer.InvalidateDivider;
begin
  Invalidate;
end;

function TLuxSplitContainer.CursorManager: TLuxCursorManager;
var
  Root: TLuxRootControl;
  Obj: TObject;
begin
  Result := nil;
  Root := LuxFindRootControl(Self);
  if Root = nil then
    Exit;
  Obj := Root.CurrentCursorManager;
  if Obj is TLuxCursorManager then
    Result := TLuxCursorManager(Obj);
end;

procedure TLuxSplitContainer.RequestSplitCursor;
var
  Mgr: TLuxCursorManager;
  DivR: TLuxRect;
  Origin: TLuxPoint;
  Shape: TLuxCursorShape;
begin
  Mgr := CursorManager;
  if Mgr = nil then
    Exit;
  DivR := DividerLocalRect;
  Origin := LocalToRoot(LuxPoint(DivR.Left + DivR.Width div 2,
    DivR.Top + DivR.Height div 2));
  if FOrientation = loVertical then
    Shape := lcsBar
  else
    Shape := lcsUnderline;
  Mgr.Request(Origin.X, Origin.Y, True, Shape, False);
  FCursorActive := True;
end;

procedure TLuxSplitContainer.ClearSplitCursor;
var
  Mgr: TLuxCursorManager;
begin
  if not FCursorActive then
    Exit;
  Mgr := CursorManager;
  if Mgr <> nil then
    Mgr.ClearRequest;
  FCursorActive := False;
end;

procedure TLuxSplitContainer.UpdateHoverFromLocal(AX, AY: Integer);
var
  Over: Boolean;
begin
  Over := LuxRectContainsXY(DividerLocalRect, AX, AY);
  if Over = FHovered then
  begin
    if Over then
      RequestSplitCursor;
    Exit;
  end;
  FHovered := Over;
  if FHovered or FDragging then
    RequestSplitCursor
  else
    ClearSplitCursor;
  InvalidateDivider;
end;

procedure TLuxSplitContainer.BeginDrag(AX, AY: Integer);
var
  DivR: TLuxRect;
  Root: TLuxRootControl;
begin
  DivR := DividerLocalRect;
  if FOrientation = loVertical then
    FDragGrab := AX - DivR.Left
  else
    FDragGrab := AY - DivR.Top;
  FDragging := True;
  FHovered := True;
  Root := LuxFindRootControl(Self);
  if Root <> nil then
    Root.RequestCaptureMouse(Self);
  RequestSplitCursor;
  InvalidateDivider;
end;

procedure TLuxSplitContainer.UpdateDrag(AX, AY: Integer);
var
  Sz: TLuxSize;
  Dist, DesiredFirst: Integer;
  NewRatio: Integer;
begin
  Sz := ClientSize;
  if FOrientation = loVertical then
  begin
    Dist := DistributableMain(Sz.Width);
    DesiredFirst := AX - FDragGrab;
  end
  else
  begin
    Dist := DistributableMain(Sz.Height);
    DesiredFirst := AY - FDragGrab;
  end;
  DesiredFirst := ClampFirstMain(DesiredFirst, Dist, FFirstMinimumSize,
    FSecondMinimumSize);
  NewRatio := RatioFromFirstMain(DesiredFirst, Dist);
  if NewRatio = FRatio then
  begin
    ApplyLayout;
    RequestSplitCursor;
    Exit;
  end;
  FRatio := NewRatio;
  ApplyLayout;
  RequestSplitCursor;
  Invalidate;
end;

procedure TLuxSplitContainer.EndDrag(AX, AY: Integer);
var
  Root: TLuxRootControl;
begin
  if not FDragging then
    Exit;
  FDragging := False;
  Root := LuxFindRootControl(Self);
  if Root <> nil then
    Root.RequestReleaseMouse(Self);
  UpdateHoverFromLocal(AX, AY);
  if not FHovered then
    ClearSplitCursor;
  InvalidateDivider;
end;

function TLuxSplitContainer.DoHandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
  if Event.Kind <> ekMouse then
    Exit;

  case Event.Mouse.Action of
    maPress:
      if Event.Mouse.Button = mbLeft then
      begin
        if LuxRectContainsXY(DividerLocalRect, Event.Mouse.X, Event.Mouse.Y) then
        begin
          BeginDrag(Event.Mouse.X, Event.Mouse.Y);
          Exit(True);
        end;
      end;
    maMove:
      begin
        if FDragging then
        begin
          UpdateDrag(Event.Mouse.X, Event.Mouse.Y);
          Exit(True);
        end;
        UpdateHoverFromLocal(Event.Mouse.X, Event.Mouse.Y);
        if FHovered then
          Exit(True);
      end;
    maRelease:
      if Event.Mouse.Button = mbLeft then
      begin
        if FDragging then
        begin
          EndDrag(Event.Mouse.X, Event.Mouse.Y);
          Exit(True);
        end;
      end;
  end;
end;

procedure TLuxSplitContainer.MouseLeave;
begin
  if FDragging then
    Exit;
  if FHovered then
  begin
    FHovered := False;
    ClearSplitCursor;
    InvalidateDivider;
  end;
end;

end.
