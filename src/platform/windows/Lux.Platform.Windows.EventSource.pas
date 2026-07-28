{ Windows ILuxEventSource using Peek/ReadConsoleInputW. }
unit Lux.Platform.Windows.EventSource;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Windows,
  Lux.Events,
  Lux.EventSource,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.InputTranslate;

type
  TLuxWindowsEventSource = class(TInterfacedObject, ILuxEventSource)
  private
    FSession: TLuxWindowsTerminalSession;
    FPending: array of TLuxEvent;
    procedure PushPending(const Event: TLuxEvent);
    function PopPending(out Event: TLuxEvent): Boolean;
    function TranslateAndPush(const Rec: INPUT_RECORD): Boolean;
    function DrainConsole(AMax: Integer): Boolean;
  public
    constructor Create(ASession: TLuxWindowsTerminalSession);
    destructor Destroy; override;
    function PollEvent(out Event: TLuxEvent): Boolean;
    function WaitEvent(out Event: TLuxEvent; TimeoutMs: Integer): Boolean;
  end;

implementation

constructor TLuxWindowsEventSource.Create(ASession: TLuxWindowsTerminalSession);
begin
  inherited Create;
  if ASession = nil then
    raise Exception.Create('Windows event source requires a terminal session.');
  FSession := ASession;
  SetLength(FPending, 0);
end;

destructor TLuxWindowsEventSource.Destroy;
begin
  FSession := nil;
  inherited Destroy;
end;

procedure TLuxWindowsEventSource.PushPending(const Event: TLuxEvent);
var
  N: Integer;
begin
  N := Length(FPending);
  SetLength(FPending, N + 1);
  FPending[N] := Event;
end;

function TLuxWindowsEventSource.PopPending(out Event: TLuxEvent): Boolean;
var
  I: Integer;
begin
  if Length(FPending) = 0 then
  begin
    Event := LuxEventNone;
    Exit(False);
  end;
  Event := FPending[0];
  for I := 1 to High(FPending) do
    FPending[I - 1] := FPending[I];
  SetLength(FPending, Length(FPending) - 1);
  Result := True;
end;

function TLuxWindowsEventSource.TranslateAndPush(const Rec: INPUT_RECORD): Boolean;
var
  Ev: TLuxEvent;
begin
  Result := False;
  if not LuxWindowsTranslateInputRecord(Rec, Ev) then
    Exit;
  if Ev.Kind = ekResize then
  begin
    FSession.RefreshSize;
    Ev := LuxEventResize(FSession.Columns, FSession.Rows);
  end;
  PushPending(Ev);
  Result := True;
end;

function TLuxWindowsEventSource.DrainConsole(AMax: Integer): Boolean;
var
  Rec: INPUT_RECORD;
  ReadCount: DWORD;
  N: Integer;
begin
  Result := False;
  N := 0;
  while N < AMax do
  begin
    if not PeekConsoleInputW(FSession.InputHandle, Rec, 1, ReadCount) then
      Exit;
    if ReadCount = 0 then
      Exit;
    if not ReadConsoleInputW(FSession.InputHandle, Rec, 1, ReadCount) then
      Exit;
    if TranslateAndPush(Rec) then
      Result := True;
    Inc(N);
  end;
end;

function TLuxWindowsEventSource.PollEvent(out Event: TLuxEvent): Boolean;
begin
  if PopPending(Event) then
    Exit(True);
  DrainConsole(32);
  if PopPending(Event) then
    Exit(True);
  Event := LuxEventNone;
  Result := False;
end;

function TLuxWindowsEventSource.WaitEvent(out Event: TLuxEvent; TimeoutMs: Integer): Boolean;
var
  Rc: DWORD;
begin
  if TimeoutMs = 0 then
    Exit(PollEvent(Event));

  if PollEvent(Event) then
    Exit(True);

  if TimeoutMs < 0 then
    Rc := WaitForSingleObject(FSession.InputHandle, INFINITE)
  else
    Rc := WaitForSingleObject(FSession.InputHandle, DWORD(TimeoutMs));

  if Rc = WAIT_OBJECT_0 then
    Exit(PollEvent(Event));

  Event := LuxEventNone;
  Result := False;
end;

end.
