{ Shared layout box: padding, spacing, relayout hook. No platform APIs. }
unit Lux.Layout;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Control,
  Lux.ControlContainer;

type
  TLuxPadding = record
    Left: Integer;
    Top: Integer;
    Right: Integer;
    Bottom: Integer;
  end;

  { Container that assigns child Bounds from layout hints. }
  TLuxLayoutBox = class(TLuxControlContainer)
  private
    FPadding: TLuxPadding;
    FSpacing: Integer;
    FLayoutDirty: Boolean;
    FInLayout: Boolean;
    procedure SetSpacing(AValue: Integer);
    procedure SetPadding(const AValue: TLuxPadding);
  protected
    procedure BoundsChanged; override;
    procedure HandleChildLayoutHintsChanged(AChild: TLuxControl); override;
    procedure PerformLayout; virtual; abstract;
    function InnerRect: TLuxRect;
    function VisibleChildCount: Integer;
    function VisibleChild(AIndex: Integer): TLuxControl;
  public
    constructor Create(AParent: TLuxControl = nil);

    procedure AddChild(AControl: TLuxControl); override;
    procedure RemoveChild(AControl: TLuxControl); override;
    procedure RequestLayout;
    procedure EnsureLayout;

    property Padding: TLuxPadding read FPadding write SetPadding;
    property Spacing: Integer read FSpacing write SetSpacing;
  end;

function LuxPadding(ALeft, ATop, ARight, ABottom: Integer): TLuxPadding;
function LuxPaddingAll(AValue: Integer): TLuxPadding;

implementation

function LuxPadding(ALeft, ATop, ARight, ABottom: Integer): TLuxPadding;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
end;

function LuxPaddingAll(AValue: Integer): TLuxPadding;
begin
  Result := LuxPadding(AValue, AValue, AValue, AValue);
end;

constructor TLuxLayoutBox.Create(AParent: TLuxControl = nil);
begin
  inherited Create(AParent);
  FPadding := LuxPadding(0, 0, 0, 0);
  FSpacing := 0;
  FLayoutDirty := True;
  FInLayout := False;
end;

procedure TLuxLayoutBox.SetSpacing(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FSpacing = AValue then
    Exit;
  FSpacing := AValue;
  RequestLayout;
end;

procedure TLuxLayoutBox.SetPadding(const AValue: TLuxPadding);
begin
  if (FPadding.Left = AValue.Left) and (FPadding.Top = AValue.Top) and
     (FPadding.Right = AValue.Right) and (FPadding.Bottom = AValue.Bottom) then
    Exit;
  FPadding := AValue;
  if FPadding.Left < 0 then
    FPadding.Left := 0;
  if FPadding.Top < 0 then
    FPadding.Top := 0;
  if FPadding.Right < 0 then
    FPadding.Right := 0;
  if FPadding.Bottom < 0 then
    FPadding.Bottom := 0;
  RequestLayout;
end;

procedure TLuxLayoutBox.AddChild(AControl: TLuxControl);
begin
  inherited AddChild(AControl);
  RequestLayout;
end;

procedure TLuxLayoutBox.RemoveChild(AControl: TLuxControl);
begin
  inherited RemoveChild(AControl);
  RequestLayout;
end;

procedure TLuxLayoutBox.HandleChildLayoutHintsChanged(AChild: TLuxControl);
begin
  RequestLayout;
end;

procedure TLuxLayoutBox.BoundsChanged;
begin
  inherited BoundsChanged;
  FLayoutDirty := True;
  EnsureLayout;
end;

procedure TLuxLayoutBox.RequestLayout;
begin
  FLayoutDirty := True;
  if FInLayout then
    Exit;
  EnsureLayout;
end;

procedure TLuxLayoutBox.EnsureLayout;
begin
  if not FLayoutDirty then
    Exit;
  if FInLayout then
    Exit;
  FInLayout := True;
  try
    PerformLayout;
    FLayoutDirty := False;
  finally
    FInLayout := False;
  end;
  Invalidate;
end;

function TLuxLayoutBox.InnerRect: TLuxRect;
var
  Sz: TLuxSize;
begin
  Sz := ClientSize;
  Result.Left := FPadding.Left;
  Result.Top := FPadding.Top;
  Result.Width := Sz.Width - FPadding.Left - FPadding.Right;
  Result.Height := Sz.Height - FPadding.Top - FPadding.Bottom;
  if Result.Width < 0 then
    Result.Width := 0;
  if Result.Height < 0 then
    Result.Height := 0;
end;

function TLuxLayoutBox.VisibleChildCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ChildCount - 1 do
    if Children(I).Visible then
      Inc(Result);
end;

function TLuxLayoutBox.VisibleChild(AIndex: Integer): TLuxControl;
var
  I, Seen: Integer;
begin
  Seen := 0;
  for I := 0 to ChildCount - 1 do
  begin
    Result := Children(I);
    if not Result.Visible then
      Continue;
    if Seen = AIndex then
      Exit;
    Inc(Seen);
  end;
  Result := nil;
end;

end.
