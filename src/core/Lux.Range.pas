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
    procedure AssignValue64(AValue: Int64; ANotify: Boolean);
    procedure NotifyChange;
  public
    constructor Create(AMinimum: Integer = 0; AMaximum: Integer = 100;
      AValue: Integer = 0; AStep: Integer = 1);

    { Maximum - Minimum as Int64 so full signed Integer bounds never overflow. }
    function Span: Int64;
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

procedure TLuxRange.AssignValue64(AValue: Int64; ANotify: Boolean);
var
  NewValue: Integer;
begin
  if AValue < FMinimum then
    NewValue := FMinimum
  else if AValue > FMaximum then
    NewValue := FMaximum
  else
    NewValue := Integer(AValue);
  if NewValue = FValue then
    Exit;
  FValue := NewValue;
  if ANotify then
    NotifyChange;
end;

procedure TLuxRange.AssignValue(AValue: Integer; ANotify: Boolean);
begin
  AssignValue64(AValue, ANotify);
end;

procedure TLuxRange.SetMinimum(AValue: Integer);
begin
  if AValue = FMinimum then
    Exit;
  FMinimum := AValue;
  if FMaximum < FMinimum then
    FMaximum := FMinimum;
  AssignValue64(FValue, True);
end;

procedure TLuxRange.SetMaximum(AValue: Integer);
begin
  if AValue = FMaximum then
    Exit;
  FMaximum := AValue;
  if FMinimum > FMaximum then
    FMinimum := FMaximum;
  AssignValue64(FValue, True);
end;

procedure TLuxRange.SetValue(AValue: Integer);
begin
  AssignValue64(AValue, True);
end;

procedure TLuxRange.SetStep(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
  FStep := AValue;
end;

function TLuxRange.Span: Int64;
begin
  Result := Int64(FMaximum) - Int64(FMinimum);
end;

function TLuxRange.Ratio: Double;
var
  S: Int64;
begin
  S := Span;
  if S <= 0 then
    Result := 0.0
  else
    Result := Double(Int64(FValue) - Int64(FMinimum)) / Double(S);
end;

procedure TLuxRange.SetRatio(ARatio: Double);
var
  S: Int64;
  Offset: Int64;
begin
  if ARatio < 0.0 then
    ARatio := 0.0
  else if ARatio > 1.0 then
    ARatio := 1.0;
  S := Span;
  if S <= 0 then
    AssignValue64(FMinimum, True)
  else
  begin
    Offset := Round(ARatio * Double(S));
    if Offset < 0 then
      Offset := 0
    else if Offset > S then
      Offset := S;
    AssignValue64(Int64(FMinimum) + Offset, True);
  end;
end;

procedure TLuxRange.Increment;
begin
  AssignValue64(Int64(FValue) + Int64(FStep), True);
end;

procedure TLuxRange.Decrement;
begin
  AssignValue64(Int64(FValue) - Int64(FStep), True);
end;

end.
