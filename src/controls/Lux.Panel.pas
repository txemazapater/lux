{ Portable panel container with optional single-line border. }
unit Lux.Panel;

{$mode objfpc}{$H+}

interface

uses
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control,
  Lux.ControlContainer;

type
  TLuxBorderStyle = (lbsNone, lbsSingle);

  TLuxPanel = class(TLuxControlContainer)
  private
    FBackground: TLuxColor;
    FForeground: TLuxColor;
    FBorderStyle: TLuxBorderStyle;
    procedure SetBackground(const AValue: TLuxColor);
    procedure SetForeground(const AValue: TLuxColor);
    procedure SetBorderStyle(AValue: TLuxBorderStyle);
  protected
    function ContentOffset: TLuxPoint; override;
    procedure BoundsChanged; override;
    procedure HandleChildLayoutHintsChanged(AChild: TLuxControl); override;
    procedure Paint(const Ctx: TLuxPaintContext); override;
  public
    constructor Create(AParent: TLuxControl = nil);
    property Background: TLuxColor read FBackground write SetBackground;
    property Foreground: TLuxColor read FForeground write SetForeground;
    property BorderStyle: TLuxBorderStyle read FBorderStyle write SetBorderStyle;
  end;

implementation

constructor TLuxPanel.Create(AParent: TLuxControl = nil);
begin
  inherited Create(AParent);
  FBackground := LuxColorDefault;
  FForeground := LuxColorDefault;
  FBorderStyle := lbsNone;
end;

procedure TLuxPanel.SetBackground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FBackground, AValue) then
    Exit;
  FBackground := AValue;
  Invalidate;
end;

procedure TLuxPanel.SetForeground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FForeground, AValue) then
    Exit;
  FForeground := AValue;
  Invalidate;
end;

procedure TLuxPanel.SetBorderStyle(AValue: TLuxBorderStyle);
begin
  if FBorderStyle = AValue then
    Exit;
  FBorderStyle := AValue;
  Invalidate;
end;

function TLuxPanel.ContentOffset: TLuxPoint;
begin
  if FBorderStyle = lbsSingle then
    Result := LuxPoint(1, 1)
  else
    Result := LuxPoint(0, 0);
end;

procedure TLuxPanel.BoundsChanged;
var
  I: Integer;
  Child: TLuxControl;
  Sz: TLuxSize;
begin
  inherited BoundsChanged;
  { Phase 6A: expanding children fill the client so a layout can live inside
    a bordered panel without manual SetBounds. Expand=0 keeps Phase 5 placement. }
  Sz := ClientSize;
  for I := 0 to ChildCount - 1 do
  begin
    Child := Children(I);
    if Child.Visible and (Child.Expand > 0) then
      Child.SetBounds(0, 0, Sz.Width, Sz.Height);
  end;
end;

procedure TLuxPanel.HandleChildLayoutHintsChanged(AChild: TLuxControl);
var
  Sz: TLuxSize;
begin
  if AChild.Visible and (AChild.Expand > 0) then
  begin
    Sz := ClientSize;
    AChild.SetBounds(0, 0, Sz.Width, Sz.Height);
  end;
end;

procedure TLuxPanel.Paint(const Ctx: TLuxPaintContext);
var
  Fill: TLuxCell;
  W, H: Integer;
begin
  W := Width;
  H := Height;
  if (W <= 0) or (H <= 0) then
    Exit;

  Fill := LuxCellMake(' ', 1, FForeground, FBackground, []);
  LuxPaintFill(Ctx, LuxRect(0, 0, W, H), Fill);

  if FBorderStyle <> lbsSingle then
    Exit;
  LuxPaintSingleLineBorder(Ctx, W, H, FForeground, FBackground);
end;

end.
