{ Two-state toggle switch. Distinct from CheckBox; same Checked/OnChange API. }
unit Lux.Toggle;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control,
  Lux.Events;

type
  { Terminal representation: "[ OFF ] text" / "[  ON ] text" with optional
    leading focus marker. Temporary Phase 6 glyphs — migrate in Phase 7. }
  TLuxToggle = class(TLuxControl)
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
    function Indicator: UnicodeString;
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

{ Indicator width is always 7 cells: "[ OFF ]" / "[  ON ]". }
const
  LuxToggleIndicatorWidth = 7;
  LuxToggleSpacing = 1;

constructor TLuxToggle.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FText := '';
  FChecked := False;
  FOnChange := nil;
  FStyle := LuxDefaultControlStyle;
  Focusable := True;
  UpdatePreferredSize;
end;

function TLuxToggle.Indicator: UnicodeString;
begin
  if FChecked then
    Result := '[  ON ]'
  else
    Result := '[ OFF ]';
end;

procedure TLuxToggle.UpdatePreferredSize;
begin
  PreferredHeight := 1;
  { focus marker + indicator + optional spacing + text }
  PreferredWidth := 1 + LuxToggleIndicatorWidth;
  if FText <> '' then
    PreferredWidth := PreferredWidth + LuxToggleSpacing + Length(FText);
end;

procedure TLuxToggle.SetText(const AValue: UnicodeString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  UpdatePreferredSize;
  Invalidate;
end;

procedure TLuxToggle.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;
  FChecked := AValue;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TLuxToggle.SetStyle(const AValue: TLuxControlStyle);
begin
  FStyle := AValue;
  Invalidate;
end;

procedure TLuxToggle.Toggle;
begin
  if not IsEffectivelyEnabled then
    Exit;
  Checked := not FChecked;
end;

function TLuxToggle.Caption: UnicodeString;
var
  Body: UnicodeString;
begin
  Body := Indicator;
  if FText <> '' then
    Body := Body + ' ' + FText;
  if HasFocus and IsEffectivelyEnabled then
    Result := '>' + Body
  else
    Result := ' ' + Body;
end;

function TLuxToggle.ResolveColors(out Fg, Bg: TLuxColor): TLuxTextStyle;
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

procedure TLuxToggle.Paint(const Ctx: TLuxPaintContext);
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

procedure TLuxToggle.FocusChanged;
begin
  inherited FocusChanged;
  Invalidate;
end;

function TLuxToggle.DoHandleEvent(const Event: TLuxEvent): Boolean;
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

procedure TLuxToggle.SemanticClick(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    Toggle;
end;

end.
