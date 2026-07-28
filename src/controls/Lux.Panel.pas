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
  X, Y, W, H: Integer;
  Ch: UnicodeString;
begin
  W := Width;
  H := Height;
  if (W <= 0) or (H <= 0) then
    Exit;

  Fill := LuxCellMake(' ', 1, FForeground, FBackground, []);
  LuxPaintFill(Ctx, LuxRect(0, 0, W, H), Fill);

  if FBorderStyle <> lbsSingle then
    Exit;
  if (W < 2) or (H < 2) then
    Exit;

  { Box-drawing: U+250C U+2510 U+2514 U+2518 U+2500 U+2502 }
  LuxPaintText(Ctx, 0, 0, UnicodeString(WideChar($250C)), FForeground, FBackground, []);
  LuxPaintText(Ctx, W - 1, 0, UnicodeString(WideChar($2510)), FForeground, FBackground, []);
  LuxPaintText(Ctx, 0, H - 1, UnicodeString(WideChar($2514)), FForeground, FBackground, []);
  LuxPaintText(Ctx, W - 1, H - 1, UnicodeString(WideChar($2518)), FForeground, FBackground, []);

  Ch := UnicodeString(WideChar($2500));
  for X := 1 to W - 2 do
  begin
    LuxPaintText(Ctx, X, 0, Ch, FForeground, FBackground, []);
    LuxPaintText(Ctx, X, H - 1, Ch, FForeground, FBackground, []);
  end;
  Ch := UnicodeString(WideChar($2502));
  for Y := 1 to H - 2 do
  begin
    LuxPaintText(Ctx, 0, Y, Ch, FForeground, FBackground, []);
    LuxPaintText(Ctx, W - 1, Y, Ch, FForeground, FBackground, []);
  end;
end;

end.
