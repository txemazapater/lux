{ Portable FIFO event queue. }
unit Lux.EventQueue;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Events;

type
  { Simple FIFO queue for terminal, timer and synthetic events.
    Not thread-safe. Phase 4 assumes a single application thread. }
  TLuxEventQueue = class
  private
    FItems: array of TLuxEvent;
    FHead: Integer;
    FCount: Integer;
    procedure Grow;
  public
    constructor Create;
    procedure Clear;
    procedure Push(const Event: TLuxEvent);
    function TryPop(out Event: TLuxEvent): Boolean;
    function Peek(out Event: TLuxEvent): Boolean;
    function IsEmpty: Boolean;
    property Count: Integer read FCount;
  end;

implementation

constructor TLuxEventQueue.Create;
begin
  inherited Create;
  SetLength(FItems, 32);
  FHead := 0;
  FCount := 0;
end;

procedure TLuxEventQueue.Clear;
begin
  FHead := 0;
  FCount := 0;
end;

procedure TLuxEventQueue.Grow;
var
  NewItems: array of TLuxEvent;
  I, Idx: Integer;
begin
  SetLength(NewItems, Length(FItems) * 2);
  for I := 0 to FCount - 1 do
  begin
    Idx := (FHead + I) mod Length(FItems);
    NewItems[I] := FItems[Idx];
  end;
  FItems := NewItems;
  FHead := 0;
end;

procedure TLuxEventQueue.Push(const Event: TLuxEvent);
var
  Tail: Integer;
begin
  if FCount = Length(FItems) then
    Grow;
  Tail := (FHead + FCount) mod Length(FItems);
  FItems[Tail] := Event;
  Inc(FCount);
end;

function TLuxEventQueue.TryPop(out Event: TLuxEvent): Boolean;
begin
  if FCount = 0 then
  begin
    Event := LuxEventNone;
    Exit(False);
  end;
  Event := FItems[FHead];
  FHead := (FHead + 1) mod Length(FItems);
  Dec(FCount);
  Result := True;
end;

function TLuxEventQueue.Peek(out Event: TLuxEvent): Boolean;
begin
  if FCount = 0 then
  begin
    Event := LuxEventNone;
    Exit(False);
  end;
  Event := FItems[FHead];
  Result := True;
end;

function TLuxEventQueue.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

end.
