{ Portable timer scheduler with injectable clock. }
unit Lux.Timers;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Events;

type
  { Milliseconds since an arbitrary origin. Must be monotonic for a given clock. }
  TLuxTimeMs = Int64;

  ILuxClock = interface
    ['{0D9E6A21-4C7B-4F8A-9E1D-2B5C8F3A7D64}']
    function NowMs: TLuxTimeMs;
  end;

  { Default clock using SysUtils.GetTickCount64. }
  TLuxSystemClock = class(TInterfacedObject, ILuxClock)
  public
    function NowMs: TLuxTimeMs;
  end;

  TLuxTimerSlot = record
    Id: TLuxTimerId;
    DueMs: TLuxTimeMs;
    IntervalMs: TLuxTimeMs;
    Repeating: Boolean;
    Active: Boolean;
  end;

  TLuxTimerEventSink = procedure(const Event: TLuxEvent) of object;

  TLuxTimerScheduler = class
  private
    FClock: ILuxClock;
    FSlots: array of TLuxTimerSlot;
    FNextId: TLuxTimerId;
    function FindSlot(AId: TLuxTimerId): Integer;
    function AllocSlot: Integer;
  public
    constructor Create(AClock: ILuxClock);
    { One-shot timer. Returns id. DelayMs must be >= 0. }
    function ScheduleOnce(DelayMs: TLuxTimeMs): TLuxTimerId;
    { Repeating timer. First fire after IntervalMs. }
    function ScheduleRepeating(IntervalMs: TLuxTimeMs): TLuxTimerId;
    function Cancel(AId: TLuxTimerId): Boolean;
    { Milliseconds until next due timer, or -1 if none. }
    function NextDelayMs: TLuxTimeMs;
    { Push due timer events into the provided procedure. }
    procedure CollectDue(APush: TLuxTimerEventSink);
    procedure CollectDueToQueue(AQueue: TObject);
  end;

implementation

uses
  Lux.EventQueue;

function TLuxSystemClock.NowMs: TLuxTimeMs;
begin
  Result := TLuxTimeMs(GetTickCount64);
end;

constructor TLuxTimerScheduler.Create(AClock: ILuxClock);
begin
  inherited Create;
  if AClock = nil then
    FClock := TLuxSystemClock.Create
  else
    FClock := AClock;
  FNextId := 1;
  SetLength(FSlots, 0);
end;

function TLuxTimerScheduler.FindSlot(AId: TLuxTimerId): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FSlots) do
    if FSlots[I].Active and (FSlots[I].Id = AId) then
      Exit(I);
  Result := -1;
end;

function TLuxTimerScheduler.AllocSlot: Integer;
var
  I: Integer;
begin
  for I := 0 to High(FSlots) do
    if not FSlots[I].Active then
      Exit(I);
  I := Length(FSlots);
  SetLength(FSlots, I + 1);
  Result := I;
end;

function TLuxTimerScheduler.ScheduleOnce(DelayMs: TLuxTimeMs): TLuxTimerId;
var
  I: Integer;
begin
  if DelayMs < 0 then
    DelayMs := 0;
  I := AllocSlot;
  Result := FNextId;
  Inc(FNextId);
  FSlots[I].Id := Result;
  FSlots[I].DueMs := FClock.NowMs + DelayMs;
  FSlots[I].IntervalMs := 0;
  FSlots[I].Repeating := False;
  FSlots[I].Active := True;
end;

function TLuxTimerScheduler.ScheduleRepeating(IntervalMs: TLuxTimeMs): TLuxTimerId;
var
  I: Integer;
begin
  if IntervalMs < 1 then
    IntervalMs := 1;
  I := AllocSlot;
  Result := FNextId;
  Inc(FNextId);
  FSlots[I].Id := Result;
  FSlots[I].DueMs := FClock.NowMs + IntervalMs;
  FSlots[I].IntervalMs := IntervalMs;
  FSlots[I].Repeating := True;
  FSlots[I].Active := True;
end;

function TLuxTimerScheduler.Cancel(AId: TLuxTimerId): Boolean;
var
  I: Integer;
begin
  I := FindSlot(AId);
  if I < 0 then
    Exit(False);
  FSlots[I].Active := False;
  Result := True;
end;

function TLuxTimerScheduler.NextDelayMs: TLuxTimeMs;
var
  I: Integer;
  NowT, Best, Delta: TLuxTimeMs;
  Have: Boolean;
begin
  Have := False;
  Best := 0;
  NowT := FClock.NowMs;
  for I := 0 to High(FSlots) do
    if FSlots[I].Active then
    begin
      Delta := FSlots[I].DueMs - NowT;
      if Delta < 0 then
        Delta := 0;
      if (not Have) or (Delta < Best) then
      begin
        Best := Delta;
        Have := True;
      end;
    end;
  if not Have then
    Exit(-1);
  Result := Best;
end;

procedure TLuxTimerScheduler.CollectDue(APush: TLuxTimerEventSink);
var
  I: Integer;
  NowT: TLuxTimeMs;
begin
  if not Assigned(APush) then
    Exit;
  NowT := FClock.NowMs;
  for I := 0 to High(FSlots) do
    if FSlots[I].Active and (FSlots[I].DueMs <= NowT) then
    begin
      APush(LuxEventTimer(FSlots[I].Id));
      if FSlots[I].Repeating then
        FSlots[I].DueMs := NowT + FSlots[I].IntervalMs
      else
        FSlots[I].Active := False;
    end;
end;

procedure TLuxTimerScheduler.CollectDueToQueue(AQueue: TObject);
var
  Q: TLuxEventQueue;
  I: Integer;
  NowT: TLuxTimeMs;
begin
  Q := AQueue as TLuxEventQueue;
  NowT := FClock.NowMs;
  for I := 0 to High(FSlots) do
    if FSlots[I].Active and (FSlots[I].DueMs <= NowT) then
    begin
      Q.Push(LuxEventTimer(FSlots[I].Id));
      if FSlots[I].Repeating then
        FSlots[I].DueMs := NowT + FSlots[I].IntervalMs
      else
        FSlots[I].Active := False;
    end;
end;

end.
