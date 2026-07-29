{ Portable single-line label control. }
unit Lux.Labels;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Control;

type
  TLuxTextAlignment = (ltaLeft, ltaCenter, ltaRight);

  TLuxLabel = class(TLuxControl)
  private
    FText: UnicodeString;
    FForeground: TLuxColor;
    FBackground: TLuxColor;
    FAlignment: TLuxTextAlignment;
    procedure SetText(const AValue: UnicodeString);
    procedure SetForeground(const AValue: TLuxColor);
    procedure SetBackground(const AValue: TLuxColor);
    procedure SetAlignment(AValue: TLuxTextAlignment);
    procedure UpdatePreferredSize;
  protected
    procedure Paint(const Ctx: TLuxPaintContext); override;
  public
    constructor Create(AParent: TLuxControl = nil);
    property Text: UnicodeString read FText write SetText;
    property Foreground: TLuxColor read FForeground write SetForeground;
    property Background: TLuxColor read FBackground write SetBackground;
    property Alignment: TLuxTextAlignment read FAlignment write SetAlignment;
  end;

implementation

constructor TLuxLabel.Create(AParent: TLuxControl = nil);
begin
  inherited Create(AParent);
  FText := '';
  FForeground := LuxColorDefault;
  FBackground := LuxColorDefault;
  FAlignment := ltaLeft;
  Focusable := False;
  UpdatePreferredSize;
end;

procedure TLuxLabel.UpdatePreferredSize;
begin
  PreferredHeight := 1;
  PreferredWidth := Length(FText);
end;

procedure TLuxLabel.SetText(const AValue: UnicodeString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  UpdatePreferredSize;
  Invalidate;
end;

procedure TLuxLabel.SetForeground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FForeground, AValue) then
    Exit;
  FForeground := AValue;
  Invalidate;
end;

procedure TLuxLabel.SetBackground(const AValue: TLuxColor);
begin
  if LuxColorEqual(FBackground, AValue) then
    Exit;
  FBackground := AValue;
  Invalidate;
end;

procedure TLuxLabel.SetAlignment(AValue: TLuxTextAlignment);
begin
  if FAlignment = AValue then
    Exit;
  FAlignment := AValue;
  Invalidate;
end;

procedure TLuxLabel.Paint(const Ctx: TLuxPaintContext);
var
  X, TextLen, W: Integer;
begin
  W := Width;
  if (W <= 0) or (Height <= 0) then
    Exit;
  TextLen := Length(FText);
  case FAlignment of
    ltaCenter:
      X := (W - TextLen) div 2;
    ltaRight:
      X := W - TextLen;
  else
    X := 0;
  end;
  if X < 0 then
    X := 0;
  LuxPaintText(Ctx, X, 0, FText, FForeground, FBackground, []);
end;

end.
