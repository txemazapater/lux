{ Portable button control with keyboard and mouse activation. }
unit Lux.Button;

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
  TLuxButton = class(TLuxControl)
  private
    FText: UnicodeString;
    FOnClick: TLuxNotifyEvent;
    FPressed: Boolean;
    FStyle: TLuxControlStyle;
    procedure SetText(const AValue: UnicodeString);
    procedure SetPressed(AValue: Boolean);
    procedure SetStyle(const AValue: TLuxControlStyle);
    procedure DoClick;
    function ResolveColors(out Fg, Bg: TLuxColor): TLuxTextStyle;
  protected
    procedure Paint(const Ctx: TLuxPaintContext); override;
    function DoHandleEvent(const Event: TLuxEvent): Boolean; override;
  public
    procedure SemanticMouseDown(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseUp(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticClick(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseLeave; override;
    constructor Create(AParent: TLuxControl = nil);
    property Text: UnicodeString read FText write SetText;
    property OnClick: TLuxNotifyEvent read FOnClick write FOnClick;
    property Pressed: Boolean read FPressed write SetPressed;
    property Style: TLuxControlStyle read FStyle write SetStyle;
  end;

implementation

constructor TLuxButton.Create(AParent: TLuxControl = nil);
begin
  inherited Create(AParent);
  FText := '';
  FOnClick := nil;
  FPressed := False;
  FStyle := LuxDefaultControlStyle;
  Focusable := True;
end;

procedure TLuxButton.SetText(const AValue: UnicodeString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  Invalidate;
end;

procedure TLuxButton.SetPressed(AValue: Boolean);
begin
  if FPressed = AValue then
    Exit;
  FPressed := AValue;
  Invalidate;
end;

procedure TLuxButton.SetStyle(const AValue: TLuxControlStyle);
begin
  FStyle := AValue;
  Invalidate;
end;

procedure TLuxButton.DoClick;
begin
  if not IsEffectivelyEnabled then
    Exit;
  if Assigned(FOnClick) then
    FOnClick(Self);
end;

function TLuxButton.ResolveColors(out Fg, Bg: TLuxColor): TLuxTextStyle;
begin
  Result := [];
  if not IsEffectivelyEnabled then
  begin
    Fg := FStyle.DisabledForeground;
    Bg := FStyle.DisabledBackground;
    Exit;
  end;
  if FPressed then
  begin
    Fg := FStyle.FocusForeground;
    Bg := FStyle.FocusBackground;
    Include(Result, tsReverse);
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

procedure TLuxButton.Paint(const Ctx: TLuxPaintContext);
var
  Fg, Bg: TLuxColor;
  St: TLuxTextStyle;
  Caption: UnicodeString;
  X: Integer;
  Fill: TLuxCell;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;
  St := ResolveColors(Fg, Bg);
  Fill := LuxCellMake(' ', 1, Fg, Bg, St);
  LuxPaintFill(Ctx, LuxRect(0, 0, Width, Height), Fill);

  if HasFocus and IsEffectivelyEnabled then
    Caption := '>[' + FText + ']<'
  else
    Caption := '[ ' + FText + ' ]';

  X := (Width - Length(Caption)) div 2;
  if X < 0 then
    X := 0;
  LuxPaintText(Ctx, X, Height div 2, Caption, Fg, Bg, St);
end;

function TLuxButton.DoHandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
  if Event.Kind <> ekKey then
    Exit;
  if Event.Key.Action = kaRelease then
    Exit(False);
  if (Event.Key.Key = lkEnter) or
    ((Event.Key.Key = lkChar) and (Event.Key.Ch = ' ')) then
  begin
    DoClick;
    Exit(True);
  end;
end;

procedure TLuxButton.SemanticMouseDown(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    Pressed := True;
end;

procedure TLuxButton.SemanticMouseUp(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    Pressed := False;
end;

procedure TLuxButton.SemanticClick(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    DoClick;
end;

procedure TLuxButton.SemanticMouseLeave;
begin
  Pressed := False;
end;

end.
