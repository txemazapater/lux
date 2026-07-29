{ Portable checkbox control. Semantic mouse + Space keyboard. }
unit Lux.CheckBox;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control,
  Lux.Events,
  Lux.Appearance;

type
  TLuxCheckBox = class(TLuxControl)
  private
    FText: UnicodeString;
    FChecked: Boolean;
    FOnChange: TLuxNotifyEvent;
    FStyle: TLuxControlStyle;
    procedure SetText(const AValue: UnicodeString);
    procedure SetChecked(AValue: Boolean);
    procedure SetStyle(const AValue: TLuxControlStyle);
    procedure UpdatePreferredSize;
    function ResolveColors(out Fg, Bg: TLuxColor): TLuxTextStyle;
    function Caption: UnicodeString;
  protected
    procedure Paint(const Ctx: TLuxPaintContext); override;
    function DoHandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure FocusChanged; override;
  public
    constructor Create(AParent: TLuxControl = nil);
    procedure Toggle;
    procedure SemanticClick(const Event: TLuxSemanticMouseEvent); override;

    property Text: UnicodeString read FText write SetText;
    property Checked: Boolean read FChecked write SetChecked;
    property OnChange: TLuxNotifyEvent read FOnChange write FOnChange;
    property Style: TLuxControlStyle read FStyle write SetStyle;
  end;

implementation

constructor TLuxCheckBox.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FText := '';
  FChecked := False;
  FOnChange := nil;
  FStyle := LuxDefaultControlStyle;
  Focusable := True;
  UpdatePreferredSize;
end;

procedure TLuxCheckBox.UpdatePreferredSize;
begin
  PreferredHeight := 1;
  { "[x] " or "> [x] " — preferred uses unfocused glyph width. }
  PreferredWidth := 4 + Length(FText);
  if PreferredWidth < 4 then
    PreferredWidth := 4;
end;

procedure TLuxCheckBox.SetText(const AValue: UnicodeString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  UpdatePreferredSize;
  Invalidate;
end;

procedure TLuxCheckBox.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;
  FChecked := AValue;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TLuxCheckBox.SetStyle(const AValue: TLuxControlStyle);
begin
  FStyle := AValue;
  Invalidate;
end;

procedure TLuxCheckBox.Toggle;
begin
  if not IsEffectivelyEnabled then
    Exit;
  Checked := not FChecked;
end;

function TLuxCheckBox.Caption: UnicodeString;
var
  App: TLuxAppearance;
  Mark: UnicodeString;
begin
  App := LuxBuiltinAppearance;
  if FChecked then
    Mark := App.Glyph(lgCheckChecked) + ' '
  else
    Mark := App.Glyph(lgCheckUnchecked) + ' ';
  if HasFocus and IsEffectivelyEnabled then
    Result := App.Glyph(lgFocusMarker) + Mark + FText
  else
    Result := App.Glyph(lgFocusPad) + Mark + FText;
end;

function TLuxCheckBox.ResolveColors(out Fg, Bg: TLuxColor): TLuxTextStyle;
begin
  Result := [];
  if not IsEffectivelyEnabled then
  begin
    Fg := FStyle.DisabledForeground;
    Bg := FStyle.DisabledBackground;
    Exit;
  end;
  if HasFocus then
  begin
    Fg := FStyle.FocusForeground;
    Bg := FStyle.FocusBackground;
    Include(Result, tsBold);
    Exit;
  end;
  Fg := FStyle.Foreground;
  Bg := FStyle.Background;
end;

procedure TLuxCheckBox.Paint(const Ctx: TLuxPaintContext);
var
  Fg, Bg: TLuxColor;
  St: TLuxTextStyle;
  Fill: TLuxCell;
  Cap: UnicodeString;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;
  St := ResolveColors(Fg, Bg);
  Fill := LuxCellMake(' ', 1, Fg, Bg, St);
  LuxPaintFill(Ctx, LuxRect(0, 0, Width, Height), Fill);
  Cap := Caption;
  LuxPaintText(Ctx, 0, 0, Cap, Fg, Bg, St);
end;

procedure TLuxCheckBox.FocusChanged;
begin
  inherited FocusChanged;
  Invalidate;
end;

function TLuxCheckBox.DoHandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
  if Event.Kind <> ekKey then
    Exit;
  if Event.Key.Action = kaRelease then
    Exit(False);
  if (Event.Key.Key = lkChar) and (Event.Key.Ch = ' ') then
  begin
    Toggle;
    Exit(True);
  end;
end;

procedure TLuxCheckBox.SemanticClick(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    Toggle;
end;

end.
