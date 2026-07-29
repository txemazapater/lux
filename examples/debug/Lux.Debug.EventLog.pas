{ Demo/debug event log control. Not part of the stable LUX core API. }
unit Lux.Debug.EventLog;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Control;

type
  { Simple ring-buffer log of UnicodeString lines for interactive demos.
    Newest entries appear at the bottom. }
  TEventLogControl = class(TLuxControl)
  private
    FLines: array of UnicodeString;
    FCount: Integer;
    FCapacity: Integer;
    FHead: Integer;
    FForeground: TLuxColor;
    FBackground: TLuxColor;
    FTitle: UnicodeString;
    procedure SetCapacity(AValue: Integer);
    procedure SetTitle(const AValue: UnicodeString);
    function LineAt(AIndex: Integer): UnicodeString;
  protected
    procedure Paint(const Ctx: TLuxPaintContext); override;
  public
    constructor Create(AParent: TLuxControl = nil);
    procedure Add(const ALine: UnicodeString);
    procedure Clear;
    property Capacity: Integer read FCapacity write SetCapacity;
    property Title: UnicodeString read FTitle write SetTitle;
    property Foreground: TLuxColor read FForeground write FForeground;
    property Background: TLuxColor read FBackground write FBackground;
    property Count: Integer read FCount;
  end;

implementation

constructor TEventLogControl.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FCapacity := 64;
  SetLength(FLines, FCapacity);
  FCount := 0;
  FHead := 0;
  FTitle := 'Event log';
  FForeground := LuxColorDefault;
  FBackground := LuxColorDefault;
  Focusable := False;
end;

procedure TEventLogControl.SetCapacity(AValue: Integer);
var
  NewLines: array of UnicodeString;
  I, N: Integer;
begin
  if AValue < 1 then
    AValue := 1;
  if AValue = FCapacity then
    Exit;
  SetLength(NewLines, AValue);
  N := FCount;
  if N > AValue then
    N := AValue;
  for I := 0 to N - 1 do
    NewLines[I] := LineAt(FCount - N + I);
  FLines := NewLines;
  FCapacity := AValue;
  FCount := N;
  FHead := N mod FCapacity;
  Invalidate;
end;

procedure TEventLogControl.SetTitle(const AValue: UnicodeString);
begin
  if FTitle = AValue then
    Exit;
  FTitle := AValue;
  Invalidate;
end;

function TEventLogControl.LineAt(AIndex: Integer): UnicodeString;
var
  Idx: Integer;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    Exit('');
  if FCount < FCapacity then
    Idx := AIndex
  else
    Idx := (FHead + AIndex) mod FCapacity;
  Result := FLines[Idx];
end;

procedure TEventLogControl.Add(const ALine: UnicodeString);
begin
  if FCapacity <= 0 then
    Exit;
  FLines[FHead] := ALine;
  FHead := (FHead + 1) mod FCapacity;
  if FCount < FCapacity then
    Inc(FCount);
  Invalidate;
end;

procedure TEventLogControl.Clear;
begin
  FCount := 0;
  FHead := 0;
  Invalidate;
end;

procedure TEventLogControl.Paint(const Ctx: TLuxPaintContext);
var
  Fill: TLuxCell;
  VisibleRows, Start, I, Row: Integer;
  Line: UnicodeString;
begin
  Fill := LuxCellMake(' ', 1, FForeground, FBackground, []);
  LuxPaintFill(Ctx, LuxRect(0, 0, Width, Height), Fill);
  if Height < 1 then
    Exit;
  LuxPaintText(Ctx, 0, 0, FTitle, FForeground, FBackground, []);
  VisibleRows := Height - 1;
  if VisibleRows < 1 then
    Exit;
  Start := FCount - VisibleRows;
  if Start < 0 then
    Start := 0;
  Row := 1;
  for I := Start to FCount - 1 do
  begin
    Line := LineAt(I);
    if Length(Line) > Width then
      Line := Copy(Line, 1, Width);
    LuxPaintText(Ctx, 0, Row, Line, FForeground, FBackground, []);
    Inc(Row);
  end;
end;

end.
