{ Shared integer range model (S2). No UI; Progress/Slider/ScrollBar consume later. }
unit Lux.Range;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TLuxRangeChangeEvent = procedure(Sender: TObject) of object;

  { Min/max/value/step with clamp. ScrollBar viewport/window stays outside this type. }
  TLuxRange = class
  private
    FMinimum: Integer;
    FMaximum: Integer;
    FValue: Integer;
    FStep: Integer;
    FOnChange: TLuxRangeChangeEvent;
    procedure SetMinimum(AValue: Integer);
    procedure SetMaximum(AValue: Integer);
    procedure SetValue(AValue: Integer);
    procedure SetStep(AValue: Integer);
    procedure AssignValue(AValue: Integer; ANotify: Boolean);
    procedure NotifyChange;
  public
    constructor Create(AMinimum: Integer = 0; AMaximum: Integer = 100;
      AValue: Integer = 0; AStep: Integer = 1);

    { Maximum - Minimum; always >= 0. }
    function Span: Integer;
    { Normalized position in [0, 1]. Zero when Span = 0. }
    function Ratio: Double;
    { Sets Value from a ratio in [0, 1] (clamped). }
    procedure SetRatio(ARatio: Double);

    procedure Increment;
    procedure Decrement;

    property Minimum: Integer read FMinimum write SetMinimum;
    property Maximum: Integer read FMaximum write SetMaximum;
    property Value: Integer read FValue write SetValue;
    { Positive single-step size used by Increment/Decrement. Values < 1 become 1. }
    property Step: Integer read FStep write SetStep;
    property OnChange: TLuxRangeChangeEvent read FOnChange write FOnChange;
  end;

{ Clamp AValue into [AMin, AMax]. If AMin > AMax the bounds are swapped. }
function LuxClampInt(AValue, AMin, AMax: Integer): Integer;

implementation

function LuxClampInt(AValue, AMin, AMax: Integer): Integer;
var
  Lo, Hi: Integer;
begin
  if AMin <= AMax then
  begin
    Lo := AMin;
    Hi := AMax;
  end
  else
  begin
    Lo := AMax;
    Hi := AMin;
  end;
  if AValue < Lo then
    Result := Lo
  else if AValue > Hi then
    Result := Hi
  else
    Result := AValue;
end;

constructor TLuxRange.Create(AMinimum: Integer; AMaximum: Integer;
  AValue: Integer; AStep: Integer);
begin
  inherited Create;
  FOnChange := nil;
  if AMaximum < AMinimum then
    AMaximum := AMinimum;
  FMinimum := AMinimum;
  FMaximum := AMaximum;
  if AStep < 1 then
    AStep := 1;
  FStep := AStep;
  FValue := LuxClampInt(AValue, FMinimum, FMaximum);
end;

procedure TLuxRange.NotifyChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TLuxRange.AssignValue(AValue: Integer; ANotify: Boolean);
var
  NewValue: Integer;
begin
  NewValue := LuxClampInt(AValue, FMinimum, FMaximum);
  if NewValue = FValue then
    Exit;
  FValue := NewValue;
  if ANotify then
    NotifyChange;
end;

procedure TLuxRange.SetMinimum(AValue: Integer);
begin
  if AValue = FMinimum then
    Exit;
  FMinimum := AValue;
  if FMaximum < FMinimum then
    FMaximum := FMinimum;
  AssignValue(FValue, True);
end;

procedure TLuxRange.SetMaximum(AValue: Integer);
begin
  if AValue = FMaximum then
    Exit;
  FMaximum := AValue;
  if FMinimum > FMaximum then
    FMinimum := FMaximum;
  AssignValue(FValue, True);
end;

procedure TLuxRange.SetValue(AValue: Integer);
begin
  AssignValue(AValue, True);
end;

procedure TLuxRange.SetStep(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
  FStep := AValue;
end;

function TLuxRange.Span: Integer;
begin
  Result := FMaximum - FMinimum;
end;

function TLuxRange.Ratio: Double;
var
  S: Integer;
begin
  S := Span;
  if S <= 0 then
    Result := 0.0
  else
    Result := (FValue - FMinimum) / S;
end;

procedure TLuxRange.SetRatio(ARatio: Double);
var
  S: Integer;
begin
  if ARatio < 0.0 then
    ARatio := 0.0
  else if ARatio > 1.0 then
    ARatio := 1.0;
  S := Span;
  if S <= 0 then
    AssignValue(FMinimum, True)
  else
    AssignValue(FMinimum + Round(ARatio * S), True);
end;

procedure TLuxRange.Increment;
begin
  AssignValue(FValue + FStep, True);
end;

procedure TLuxRange.Decrement;
begin
  AssignValue(FValue - FStep, True);
end;

end.
