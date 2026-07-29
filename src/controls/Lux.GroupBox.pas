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
    Children are parented in client space via ContentOffset=(1,1).
    Title affects PreferredWidth only — never MinWidth — so layouts cannot
    force the control wider than the parent and clip the right border. }
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

function LuxGbDisplayWidth(const S: UnicodeString): Integer;
var
  I: Integer;
  Cp: Cardinal;
  W: Byte;
begin
  Result := 0;
  I := 1;
  while LuxNextCodepoint(S, I, Cp) do
  begin
    W := LuxCodepointWidth(Cp);
    if W = 0 then
      W := 1;
    Inc(Result, W);
  end;
end;

{ Truncate S so its display width is at most MaxCells (never splits a wide glyph). }
function LuxGbTruncateToCells(const S: UnicodeString; MaxCells: Integer): UnicodeString;
var
  I, Used: Integer;
  Cp: Cardinal;
  W: Byte;
  Glyph: UnicodeString;
begin
  Result := '';
  if MaxCells <= 0 then
    Exit;
  I := 1;
  Used := 0;
  while LuxNextCodepoint(S, I, Cp) do
  begin
    W := LuxCodepointWidth(Cp);
    if W = 0 then
      W := 1;
    if Used + W > MaxCells then
      Break;
    if Cp <= $FFFF then
      Glyph := UnicodeString(WideChar(Cp))
    else
    begin
      Cp := Cp - $10000;
      Glyph := UnicodeString(WideChar($D800 + (Cp shr 10))) +
        UnicodeString(WideChar($DC00 + (Cp and $3FF)));
    end;
    Result := Result + Glyph;
    Inc(Used, W);
  end;
end;

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
  Need: Integer;
  TitleCells: Integer;
begin
  { Border minimum only — title must not raise MinWidth or vertical layouts
    will assign Width > parent Inner.Width and clip the right edge. }
  MinWidth := 2;
  MinHeight := 2;

  TitleCells := LuxGbDisplayWidth(FText);
  if TitleCells > 0 then
    Need := TitleCells + 4 { corners + flanking spaces }
  else
    Need := 2;
  PreferredWidth := Need;
  if PreferredHeight < 2 then
    PreferredHeight := 2;
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
  X, Y, W, H, MaxTitleCells, TitleCells: Integer;
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

  { Edges first (including corner cells as horizontals/verticals placeholders). }
  Ch := UnicodeString(LuxGbH);
  for X := 0 to W - 1 do
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

  { Title into top border between corners: " Title " clipped by cell columns.
    Never write into column 0 or W-1. }
  if (FText <> '') and (W >= 5) then
  begin
    MaxTitleCells := W - 4;
    Title := LuxGbTruncateToCells(FText, MaxTitleCells);
    TitleCells := LuxGbDisplayWidth(Title);
    if TitleCells > 0 then
    begin
      LuxPaintText(Ctx, 1, 0, ' ', Fg, FBackground, []);
      LuxPaintText(Ctx, 2, 0, Title, Fg, FBackground, []);
      if 2 + TitleCells <= W - 2 then
        LuxPaintText(Ctx, 2 + TitleCells, 0, ' ', Fg, FBackground, []);
    end;
  end;

  { Corners last so a long / wide title cannot corrupt them. }
  LuxPaintText(Ctx, 0, 0, UnicodeString(LuxGbTL), Fg, FBackground, []);
  LuxPaintText(Ctx, W - 1, 0, UnicodeString(LuxGbTR), Fg, FBackground, []);
  LuxPaintText(Ctx, 0, H - 1, UnicodeString(LuxGbBL), Fg, FBackground, []);
  LuxPaintText(Ctx, W - 1, H - 1, UnicodeString(LuxGbBR), Fg, FBackground, []);
end;

end.
