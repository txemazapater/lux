{ Portable radio button. Sibling-only mutual exclusion under same parent. }
unit Lux.RadioButton;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control,
  Lux.ControlContainer,
  Lux.Events,
  Lux.Appearance;

type
  TLuxRadioButton = class(TLuxControl)
  private
    FText: UnicodeString;
    FChecked: Boolean;
    FOnChange: TLuxNotifyEvent;
    FStyle: TLuxControlStyle;
    FUpdatingGroup: Boolean;
    procedure SetText(const AValue: UnicodeString);
    procedure SetChecked(AValue: Boolean);
    procedure SetStyle(const AValue: TLuxControlStyle);
    procedure UpdatePreferredSize;
    procedure ClearSiblingRadios;
    function ResolveColors(out Fg, Bg: TLuxColor): TLuxTextStyle;
    function Caption: UnicodeString;
  protected
    procedure Paint(const Ctx: TLuxPaintContext); override;
    function DoHandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure FocusChanged; override;
  public
    constructor Create(AParent: TLuxControl = nil);
    procedure Select;
    procedure SemanticClick(const Event: TLuxSemanticMouseEvent); override;

    property Text: UnicodeString read FText write SetText;
    property Checked: Boolean read FChecked write SetChecked;
    property OnChange: TLuxNotifyEvent read FOnChange write FOnChange;
    property Style: TLuxControlStyle read FStyle write SetStyle;
  end;

implementation

constructor TLuxRadioButton.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FText := '';
  FChecked := False;
  FOnChange := nil;
  FStyle := LuxDefaultControlStyle;
  FUpdatingGroup := False;
  Focusable := True;
  UpdatePreferredSize;
end;

procedure TLuxRadioButton.UpdatePreferredSize;
begin
  PreferredHeight := 1;
  { "(*) " unfocused glyph width. }
  PreferredWidth := 4 + Length(FText);
  if PreferredWidth < 4 then
    PreferredWidth := 4;
end;

procedure TLuxRadioButton.SetText(const AValue: UnicodeString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  UpdatePreferredSize;
  Invalidate;
end;

procedure TLuxRadioButton.ClearSiblingRadios;
var
  Cont: TLuxControlContainer;
  Sibling: TLuxControl;
  Radio: TLuxRadioButton;
  I: Integer;
begin
  if not (Parent is TLuxControlContainer) then
    Exit;
  Cont := TLuxControlContainer(Parent);
  for I := 0 to Cont.ChildCount - 1 do
  begin
    Sibling := Cont.Children(I);
    if Sibling = Self then
      Continue;
    if not (Sibling is TLuxRadioButton) then
      Continue;
    Radio := TLuxRadioButton(Sibling);
    if Radio.FChecked then
    begin
      Radio.FUpdatingGroup := True;
      try
        Radio.FChecked := False;
        Radio.Invalidate;
        if Assigned(Radio.FOnChange) then
          Radio.FOnChange(Radio);
      finally
        Radio.FUpdatingGroup := False;
      end;
    end;
  end;
end;

procedure TLuxRadioButton.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;
  if AValue and not FUpdatingGroup then
    ClearSiblingRadios;
  FChecked := AValue;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TLuxRadioButton.SetStyle(const AValue: TLuxControlStyle);
begin
  FStyle := AValue;
  Invalidate;
end;

procedure TLuxRadioButton.Select;
begin
  if not IsEffectivelyEnabled then
    Exit;
  Checked := True;
end;

function TLuxRadioButton.Caption: UnicodeString;
var
  App: TLuxAppearance;
  Mark: UnicodeString;
begin
  App := LuxBuiltinAppearance;
  if FChecked then
    Mark := App.Glyph(lgRadioChecked) + ' '
  else
    Mark := App.Glyph(lgRadioUnchecked) + ' ';
  if HasFocus and IsEffectivelyEnabled then
    Result := App.Glyph(lgFocusMarker) + Mark + FText
  else
    Result := App.Glyph(lgFocusPad) + Mark + FText;
end;

function TLuxRadioButton.ResolveColors(out Fg, Bg: TLuxColor): TLuxTextStyle;
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

procedure TLuxRadioButton.Paint(const Ctx: TLuxPaintContext);
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

procedure TLuxRadioButton.FocusChanged;
begin
  inherited FocusChanged;
  Invalidate;
end;

function TLuxRadioButton.DoHandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
  if Event.Kind <> ekKey then
    Exit;
  if Event.Key.Action = kaRelease then
    Exit(False);
  if (Event.Key.Key = lkChar) and (Event.Key.Ch = ' ') then
  begin
    Select;
    Exit(True);
  end;
end;

procedure TLuxRadioButton.SemanticClick(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    Select;
end;

end.
