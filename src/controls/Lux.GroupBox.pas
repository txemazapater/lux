{ Titled bordered container with a real client area for children.
  Temporary box glyphs migrate to Phase 7 glyph sets. }
unit Lux.GroupBox;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control,
  Lux.ControlContainer;

type
  { One-cell border on all sides; title drawn into the top border.
    Children are parented in client space via ContentOffset=(1,1). }
  TLuxGroupBox = class(TLuxControlContainer)
  private
    FText: UnicodeString;
    FForeground: TLuxColor;
    FBackground: TLuxColor;
    procedure SetText(const AValue: UnicodeString);
    procedure SetForeground(const AValue: TLuxColor);
    procedure SetBackground(const AValue: TLuxColor);
    procedure UpdatePreferredFromTitle;
  protected
    function ContentOffset: TLuxPoint; override;
    procedure BoundsChanged; override;
    procedure HandleChildLayoutHintsChanged(AChild: TLuxControl); override;
    procedure Paint(const Ctx: TLuxPaintContext); override;
  public
    constructor Create(AParent: TLuxControl = nil);
    function ClientRect: TLuxRect;

    property Text: UnicodeString read FText write SetText;
    property Foreground: TLuxColor read FForeground write SetForeground;
    property Background: TLuxColor read FBackground write SetBackground;
  end;

implementation

{ Temporary Phase 6 box-drawing glyphs (same codepoints as TLuxPanel). }
const
  LuxGbTL = WideChar($250C); { ┌ }
  LuxGbTR = WideChar($2510); { ┐ }
  LuxGbBL = WideChar($2514); { └ }
  LuxGbBR = WideChar($2518); { ┘ }
  LuxGbH = WideChar($2500);  { ─ }
  LuxGbV = WideChar($2502);  { │ }

constructor TLuxGroupBox.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FText := '';
  FForeground := LuxColorDefault;
  FBackground := LuxColorDefault;
  Focusable := False;
  MinWidth := 2;
  MinHeight := 2;
  PreferredWidth := 2;
  PreferredHeight := 2;
end;

procedure TLuxGroupBox.UpdatePreferredFromTitle;
var
  TitleW: Integer;
begin
  TitleW := Length(FText);
  { corners + spaces around title: "┌ Title ─…┐" needs TitleW + 4 when titled }
  if TitleW > 0 then
  begin
    if PreferredWidth < TitleW + 4 then
      PreferredWidth := TitleW + 4;
    if MinWidth < TitleW + 4 then
      MinWidth := TitleW + 4;
  end
  else
  begin
    if MinWidth < 2 then
      MinWidth := 2;
  end;
  if PreferredHeight < 2 then
    PreferredHeight := 2;
  if MinHeight < 2 then
    MinHeight := 2;
end;

procedure TLuxGroupBox.SetText(const AValue: UnicodeString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  UpdatePreferredFromTitle;
  Invalidate;
end;

procedure TLuxGroupBox.SetForeground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FForeground, AValue) then
    Exit;
  FForeground := AValue;
  Invalidate;
end;

procedure TLuxGroupBox.SetBackground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FBackground, AValue) then
    Exit;
  FBackground := AValue;
  Invalidate;
end;

function TLuxGroupBox.ContentOffset: TLuxPoint;
begin
  Result := LuxPoint(1, 1);
end;

function TLuxGroupBox.ClientRect: TLuxRect;
var
  W, H: Integer;
begin
  W := Width - 2;
  H := Height - 2;
  if W < 0 then
    W := 0;
  if H < 0 then
    H := 0;
  Result := LuxRect(1, 1, W, H);
end;

procedure TLuxGroupBox.BoundsChanged;
var
  I: Integer;
  Child: TLuxControl;
  Sz: TLuxSize;
begin
  inherited BoundsChanged;
  Sz := ClientSize;
  for I := 0 to ChildCount - 1 do
  begin
    Child := Children(I);
    if Child.Visible and (Child.Expand > 0) then
      Child.SetBounds(0, 0, Sz.Width, Sz.Height);
  end;
end;

procedure TLuxGroupBox.HandleChildLayoutHintsChanged(AChild: TLuxControl);
var
  Sz: TLuxSize;
begin
  if AChild.Visible and (AChild.Expand > 0) then
  begin
    Sz := ClientSize;
    AChild.SetBounds(0, 0, Sz.Width, Sz.Height);
  end;
end;

procedure TLuxGroupBox.Paint(const Ctx: TLuxPaintContext);
var
  Fill: TLuxCell;
  X, Y, W, H, TitleStart, TitleEnd, MaxTitle: Integer;
  Ch: UnicodeString;
  Fg: TLuxColor;
  Title: UnicodeString;
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

  if (W < 2) or (H < 2) then
    Exit;

  LuxPaintText(Ctx, 0, 0, UnicodeString(LuxGbTL), Fg, FBackground, []);
  LuxPaintText(Ctx, W - 1, 0, UnicodeString(LuxGbTR), Fg, FBackground, []);
  LuxPaintText(Ctx, 0, H - 1, UnicodeString(LuxGbBL), Fg, FBackground, []);
  LuxPaintText(Ctx, W - 1, H - 1, UnicodeString(LuxGbBR), Fg, FBackground, []);

  Ch := UnicodeString(LuxGbH);
  for X := 1 to W - 2 do
  begin
    LuxPaintText(Ctx, X, 0, Ch, Fg, FBackground, []);
    LuxPaintText(Ctx, X, H - 1, Ch, Fg, FBackground, []);
  end;
  Ch := UnicodeString(LuxGbV);
  for Y := 1 to H - 2 do
  begin
    LuxPaintText(Ctx, 0, Y, Ch, Fg, FBackground, []);
    LuxPaintText(Ctx, W - 1, Y, Ch, Fg, FBackground, []);
  end;

  { Title into top border: " Title " between corners. }
  if FText = '' then
    Exit;
  MaxTitle := W - 4;
  if MaxTitle < 1 then
    Exit;
  Title := FText;
  if Length(Title) > MaxTitle then
    Title := Copy(Title, 1, MaxTitle);
  TitleStart := 2;
  TitleEnd := TitleStart + Length(Title) - 1;
  LuxPaintText(Ctx, 1, 0, ' ', Fg, FBackground, []);
  LuxPaintText(Ctx, TitleStart, 0, Title, Fg, FBackground, []);
  if TitleEnd + 1 <= W - 2 then
    LuxPaintText(Ctx, TitleEnd + 1, 0, ' ', Fg, FBackground, []);
end;

end.
