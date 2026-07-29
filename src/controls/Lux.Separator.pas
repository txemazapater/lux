{ Non-interactive separator line. Temporary glyphs migrate to Phase 7. }
unit Lux.Separator;

{$mode objfpc}{$H+}

interface

uses
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control;

type
  TLuxSeparator = class(TLuxControl)
  private
    FOrientation: TLuxOrientation;
    FForeground: TLuxColor;
    FBackground: TLuxColor;
    procedure SetOrientation(AValue: TLuxOrientation);
    procedure SetForeground(const AValue: TLuxColor);
    procedure SetBackground(const AValue: TLuxColor);
    procedure UpdatePreferredSize;
  protected
    procedure Paint(const Ctx: TLuxPaintContext); override;
  public
    constructor Create(AParent: TLuxControl = nil);
    property Orientation: TLuxOrientation read FOrientation write SetOrientation;
    property Foreground: TLuxColor read FForeground write SetForeground;
    property Background: TLuxColor read FBackground write SetBackground;
  end;

implementation

{ Temporary Phase 6 glyphs (U+2500 / U+2502). Migrate to Phase 7 glyph sets. }
const
  LuxSepGlyphHorizontal = WideChar($2500); { ─ }
  LuxSepGlyphVertical = WideChar($2502);   { │ }

constructor TLuxSeparator.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FOrientation := loHorizontal;
  FForeground := LuxColorDefault;
  FBackground := LuxColorDefault;
  Focusable := False;
  UpdatePreferredSize;
end;

procedure TLuxSeparator.UpdatePreferredSize;
begin
  if FOrientation = loHorizontal then
  begin
    MinWidth := 0;
    MinHeight := 1;
    PreferredHeight := 1;
    PreferredWidth := 1;
    Expand := 1;
  end
  else
  begin
    MinWidth := 1;
    MinHeight := 0;
    PreferredWidth := 1;
    PreferredHeight := 1;
    Expand := 1;
  end;
end;

procedure TLuxSeparator.SetOrientation(AValue: TLuxOrientation);
begin
  if FOrientation = AValue then
    Exit;
  FOrientation := AValue;
  UpdatePreferredSize;
  Invalidate;
end;

procedure TLuxSeparator.SetForeground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FForeground, AValue) then
    Exit;
  FForeground := AValue;
  Invalidate;
end;

procedure TLuxSeparator.SetBackground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FBackground, AValue) then
    Exit;
  FBackground := AValue;
  Invalidate;
end;

procedure TLuxSeparator.Paint(const Ctx: TLuxPaintContext);
var
  Fill: TLuxCell;
  Glyph: UnicodeString;
  X, Y, W, H: Integer;
  Fg: TLuxColor;
begin
  W := Width;
  H := Height;
  if (W <= 0) or (H <= 0) then
    Exit;

  Fg := FForeground;
  if not IsEffectivelyEnabled then
    Fg := LuxColorRGB(128, 128, 128);

  Fill := LuxCellMake(' ', 1, Fg, FBackground, []);
  LuxPaintFill(Ctx, LuxRect(0, 0, W, H), Fill);

  if FOrientation = loHorizontal then
  begin
    Glyph := UnicodeString(LuxSepGlyphHorizontal);
    for X := 0 to W - 1 do
      LuxPaintText(Ctx, X, H div 2, Glyph, Fg, FBackground, []);
  end
  else
  begin
    Glyph := UnicodeString(LuxSepGlyphVertical);
    for Y := 0 to H - 1 do
      LuxPaintText(Ctx, W div 2, Y, Glyph, Fg, FBackground, []);
  end;
end;

end.
