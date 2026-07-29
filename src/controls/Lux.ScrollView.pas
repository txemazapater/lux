{ Scrollable viewport container. No platform APIs. }
unit Lux.ScrollView;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control,
  Lux.ControlContainer,
  Lux.Events;

type
  TLuxScrollBarVisibility = (sbvAuto, sbvHidden, sbvVisible);

  TLuxScrollView = class(TLuxControlContainer)
  private
    FContent: TLuxControl;
    FScrollX: Integer;
    FScrollY: Integer;
    FWheelScrollStep: Integer;
    FHorizontalWheelScrollStep: Integer;
    FHorizontalScrollBarVisibility: TLuxScrollBarVisibility;
    FVerticalScrollBarVisibility: TLuxScrollBarVisibility;
    procedure SetContent(AValue: TLuxControl);
    procedure ClampOffsets;
    function MaxScrollX: Integer;
    function MaxScrollY: Integer;
  protected
    function ContentOffset: TLuxPoint; override;
    procedure BoundsChanged; override;
    procedure PaintChildren(const Ctx: TLuxPaintContext); override;
    function HitTestInternalRoot(AX, AY: Integer): Boolean; override;
  public
    constructor Create(AParent: TLuxControl = nil);

    procedure ScrollTo(AX, AY: Integer);
    procedure ScrollBy(ADeltaX, ADeltaY: Integer);
    procedure EnsureVisible(AControl: TLuxControl); overload;
    procedure EnsureVisible(const ARect: TLuxRect); overload;

    function SemanticMouseWheel(const Event: TLuxWheelEvent): Boolean; override;

    function ViewportWidth: Integer;
    function ViewportHeight: Integer;
    function ContentWidth: Integer;
    function ContentHeight: Integer;
    function MaximumScrollX: Integer;
    function MaximumScrollY: Integer;
    function VisibleContentRect: TLuxRect;

    function HitTestRoot(AX, AY: Integer): TLuxControl; override;

    property Content: TLuxControl read FContent write SetContent;
    property ScrollX: Integer read FScrollX;
    property ScrollY: Integer read FScrollY;
    property WheelScrollStep: Integer read FWheelScrollStep write FWheelScrollStep;
    property HorizontalWheelScrollStep: Integer read FHorizontalWheelScrollStep
      write FHorizontalWheelScrollStep;
    property HorizontalScrollBarVisibility: TLuxScrollBarVisibility
      read FHorizontalScrollBarVisibility write FHorizontalScrollBarVisibility;
    property VerticalScrollBarVisibility: TLuxScrollBarVisibility
      read FVerticalScrollBarVisibility write FVerticalScrollBarVisibility;
  end;

implementation

constructor TLuxScrollView.Create(AParent: TLuxControl = nil);
begin
  inherited Create(AParent);
  FContent := nil;
  FScrollX := 0;
  FScrollY := 0;
  FWheelScrollStep := 3;
  FHorizontalWheelScrollStep := 3;
  FHorizontalScrollBarVisibility := sbvHidden;
  FVerticalScrollBarVisibility := sbvAuto;
end;

procedure TLuxScrollView.SetContent(AValue: TLuxControl);
begin
  if FContent = AValue then
    Exit;
  if FContent <> nil then
    RemoveChild(FContent);
  FContent := AValue;
  if FContent <> nil then
  begin
    if FContent.Parent <> Self then
      AddChild(FContent);
    FContent.SetBounds(-FScrollX, -FScrollY, FContent.Width, FContent.Height);
  end;
  ClampOffsets;
  Invalidate;
end;

function TLuxScrollView.MaxScrollX: Integer;
var
  CW: Integer;
begin
  CW := ContentWidth;
  Result := CW - ViewportWidth;
  if Result < 0 then
    Result := 0;
end;

function TLuxScrollView.MaxScrollY: Integer;
var
  CH: Integer;
begin
  CH := ContentHeight;
  Result := CH - ViewportHeight;
  if Result < 0 then
    Result := 0;
end;

procedure TLuxScrollView.ClampOffsets;
var
  MX, MY: Integer;
begin
  MX := MaxScrollX;
  MY := MaxScrollY;
  if FScrollX > MX then
    FScrollX := MX;
  if FScrollX < 0 then
    FScrollX := 0;
  if FScrollY > MY then
    FScrollY := MY;
  if FScrollY < 0 then
    FScrollY := 0;
  if FContent <> nil then
    FContent.SetBounds(-FScrollX, -FScrollY, FContent.Width, FContent.Height);
end;

function TLuxScrollView.ContentOffset: TLuxPoint;
begin
  { Viewport is the full control bounds until scrollbar chrome exists. }
  Result := LuxPoint(0, 0);
end;

procedure TLuxScrollView.BoundsChanged;
begin
  inherited BoundsChanged;
  ClampOffsets;
end;

function TLuxScrollView.ViewportWidth: Integer;
begin
  Result := Width;
  if Result < 0 then
    Result := 0;
end;

function TLuxScrollView.ViewportHeight: Integer;
begin
  Result := Height;
  if Result < 0 then
    Result := 0;
end;

function TLuxScrollView.ContentWidth: Integer;
begin
  if FContent <> nil then
    Result := FContent.Width
  else
    Result := 0;
end;

function TLuxScrollView.ContentHeight: Integer;
begin
  if FContent <> nil then
    Result := FContent.Height
  else
    Result := 0;
end;

function TLuxScrollView.MaximumScrollX: Integer;
begin
  Result := MaxScrollX;
end;

function TLuxScrollView.MaximumScrollY: Integer;
begin
  Result := MaxScrollY;
end;

function TLuxScrollView.VisibleContentRect: TLuxRect;
begin
  Result := LuxRect(FScrollX, FScrollY, ViewportWidth, ViewportHeight);
end;

procedure TLuxScrollView.ScrollTo(AX, AY: Integer);
var
  OldX, OldY: Integer;
begin
  OldX := FScrollX;
  OldY := FScrollY;
  FScrollX := AX;
  FScrollY := AY;
  ClampOffsets;
  if (FScrollX <> OldX) or (FScrollY <> OldY) then
    Invalidate;
end;

procedure TLuxScrollView.ScrollBy(ADeltaX, ADeltaY: Integer);
begin
  ScrollTo(FScrollX + ADeltaX, FScrollY + ADeltaY);
end;

procedure TLuxScrollView.EnsureVisible(AControl: TLuxControl);
var
  R: TLuxRect;
  ControlOrigin: TLuxPoint;
begin
  if AControl = nil then
    Exit;
  if FContent = nil then
    Exit;
  ControlOrigin := AControl.LocalToRoot(LuxPoint(0, 0));
  { Convert to content coordinates by adding scroll offset and subtracting
    our own origin. }
  R.Left := ControlOrigin.X - LocalToRoot(LuxPoint(0, 0)).X + FScrollX;
  R.Top := ControlOrigin.Y - LocalToRoot(LuxPoint(0, 0)).Y + FScrollY;
  R.Width := AControl.Width;
  R.Height := AControl.Height;
  EnsureVisible(R);
end;

procedure TLuxScrollView.EnsureVisible(const ARect: TLuxRect);
var
  NewX, NewY: Integer;
begin
  NewX := FScrollX;
  NewY := FScrollY;

  if ARect.Left < NewX then
    NewX := ARect.Left;
  if LuxRectRight(ARect) > NewX + ViewportWidth then
    NewX := LuxRectRight(ARect) - ViewportWidth;

  if ARect.Top < NewY then
    NewY := ARect.Top;
  if LuxRectBottom(ARect) > NewY + ViewportHeight then
    NewY := LuxRectBottom(ARect) - ViewportHeight;

  ScrollTo(NewX, NewY);
end;

function TLuxScrollView.SemanticMouseWheel(const Event: TLuxWheelEvent): Boolean;
var
  OldX, OldY: Integer;
begin
  OldX := FScrollX;
  OldY := FScrollY;
  if Event.Horizontal then
    ScrollBy(-Event.Delta * FHorizontalWheelScrollStep, 0)
  else
    ScrollBy(0, -Event.Delta * FWheelScrollStep);
  Result := (FScrollX <> OldX) or (FScrollY <> OldY);
end;

procedure TLuxScrollView.PaintChildren(const Ctx: TLuxPaintContext);
var
  Child: TLuxControl;
  ChildCtx: TLuxPaintContext;
  ViewClip: TLuxRect;
  I: Integer;
begin
  if ChildCount = 0 then
    Exit;
  ViewClip := LuxRect(Ctx.OriginX, Ctx.OriginY, ViewportWidth, ViewportHeight);
  ViewClip := LuxRectIntersect(ViewClip, Ctx.Clip);
  if LuxRectIsEmpty(ViewClip) then
    Exit;
  for I := 0 to ChildCount - 1 do
  begin
    Child := Children(I);
    ChildCtx := Child.BuildPaintContext(Ctx.Surface, Ctx, True);
    ChildCtx.Clip := LuxRectIntersect(ChildCtx.Clip, ViewClip);
    Child.Render(ChildCtx);
  end;
end;

function TLuxScrollView.HitTestInternalRoot(AX, AY: Integer): Boolean;
begin
  Result := False;
end;

function TLuxScrollView.HitTestRoot(AX, AY: Integer): TLuxControl;
var
  AbsBounds: TLuxRect;
  I: Integer;
  Child, Hit: TLuxControl;
begin
  Result := nil;
  if not IsEffectivelyVisible then
    Exit;
  AbsBounds := Self.AbsoluteBounds;
  if not LuxRectContainsXY(AbsBounds, AX, AY) then
    Exit;
  { Only hit test within the viewport. }
  for I := ChildCount - 1 downto 0 do
  begin
    Child := Children(I);
    if not Child.IsEffectivelyVisible then
      Continue;
    if Child is TLuxControlContainer then
      Hit := TLuxControlContainer(Child).HitTestRoot(AX, AY)
    else if Child.ContainsRootPoint(AX, AY) then
      Hit := Child
    else
      Hit := nil;
    if Hit <> nil then
    begin
      { Clip hit test to viewport. }
      if not LuxRectContainsXY(AbsBounds, AX, AY) then
        Continue;
      if not Hit.IsEffectivelyEnabled then
      begin
        if IsEffectivelyEnabled then
          Exit(Self);
        Exit(nil);
      end;
      Exit(Hit);
    end;
  end;
  if IsEffectivelyEnabled then
    Result := Self;
end;

end.
