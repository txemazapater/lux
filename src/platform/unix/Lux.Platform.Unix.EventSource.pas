{ Unix ILuxEventSource: poll(2) + incremental parser + SIGWINCH flag. }
unit Lux.Platform.Unix.EventSource;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  BaseUnix,
  Unix,
  Lux.Events,
  Lux.EventSource,
  Lux.Platform.Unix.TerminalSession,
  Lux.Platform.Unix.InputParser,
  Lux.Platform.Unix.Console;

type
  TLuxUnixEventSource = class(TInterfacedObject, ILuxEventSource)
  private
    FSession: TLuxUnixTerminalSession;
    FParser: TLuxUnixInputParser;
    FPending: array of TLuxEvent;
    FOwnsSession: Boolean;
    FEscDeadlineMs: Int64;
    FEscWaiting: Boolean;
    FPrevHandler: signalhandler;
    FWinchInstalled: Boolean;
    procedure InstallWinch;
    procedure UninstallWinch;
    procedure DrainResize;
    procedure PushPending(const Event: TLuxEvent);
    function PopPending(out Event: TLuxEvent): Boolean;
    function ReadAvailable: Boolean;
    function DecodeAvailable(out Event: TLuxEvent): Boolean;
    function WaitReadable(TimeoutMs: Integer): Boolean;
    function NowMs: Int64;
  public
    constructor Create(ASession: TLuxUnixTerminalSession);
    destructor Destroy; override;
    function PollEvent(out Event: TLuxEvent): Boolean;
    function WaitEvent(out Event: TLuxEvent; TimeoutMs: Integer): Boolean;
  end;

implementation

var
  LuxUnixWinchFlag: cint = 0;

procedure LuxUnixWinchHandler(Sig: cint); cdecl;
begin
  LuxUnixWinchFlag := 1;
  if Sig = 0 then
    ; { keep parameter referenced }
end;

constructor TLuxUnixEventSource.Create(ASession: TLuxUnixTerminalSession);
begin
  inherited Create;
  if ASession = nil then
    raise Exception.Create('Unix event source requires a terminal session.');
  FSession := ASession;
  FOwnsSession := False;
  FParser := TLuxUnixInputParser.Create;
  SetLength(FPending, 0);
  FEscWaiting := False;
  FEscDeadlineMs := 0;
  FWinchInstalled := False;
  InstallWinch;
end;

destructor TLuxUnixEventSource.Destroy;
begin
  UninstallWinch;
  FreeAndNil(FParser);
  FSession := nil;
  inherited Destroy;
end;

procedure TLuxUnixEventSource.InstallWinch;
begin
  LuxUnixWinchFlag := 0;
  FPrevHandler := FpSignal(SIGWINCH, @LuxUnixWinchHandler);
  FWinchInstalled := True;
end;

procedure TLuxUnixEventSource.UninstallWinch;
begin
  if not FWinchInstalled then
    Exit;
  FpSignal(SIGWINCH, FPrevHandler);
  FWinchInstalled := False;
end;

function TLuxUnixEventSource.NowMs: Int64;
begin
  Result := Int64(GetTickCount64);
end;

procedure TLuxUnixEventSource.PushPending(const Event: TLuxEvent);
var
  N: Integer;
begin
  N := Length(FPending);
  SetLength(FPending, N + 1);
  FPending[N] := Event;
end;

function TLuxUnixEventSource.PopPending(out Event: TLuxEvent): Boolean;
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

procedure TLuxUnixEventSource.DrainResize;
var
  W, H: Integer;
begin
  if LuxUnixWinchFlag = 0 then
    Exit;
  LuxUnixWinchFlag := 0;
  FSession.RefreshSize;
  W := FSession.Columns;
  H := FSession.Rows;
  if (W > 0) and (H > 0) then
    PushPending(LuxEventResize(W, H));
end;

function TLuxUnixEventSource.ReadAvailable: Boolean;
var
  Buf: array[0..511] of Byte;
  N: TsSize;
  Piece: RawByteString;
begin
  Result := False;
  N := FpRead(FSession.InputFd, @Buf[0], SizeOf(Buf));
  if N <= 0 then
    Exit;
  SetLength(Piece, N);
  SetCodePage(RawByteString(Piece), CP_NONE, False);
  Move(Buf[0], Piece[1], N);
  FParser.Feed(Piece);
  FEscWaiting := False;
  Result := True;
end;

function TLuxUnixEventSource.DecodeAvailable(out Event: TLuxEvent): Boolean;
var
  St: TLuxUnixParseStatus;
begin
  Event := LuxEventNone;
  while True do
  begin
    St := FParser.TryParse(Event);
    case St of
      upsEvent:
        Exit(True);
      upsAmbiguousEsc:
        begin
          if not FEscWaiting then
          begin
            FEscWaiting := True;
            FEscDeadlineMs := NowMs + LuxUnixEscAmbiguityTimeoutMs;
          end
          else if NowMs >= FEscDeadlineMs then
          begin
            FEscWaiting := False;
            if FParser.ResolveAmbiguousEscape(Event) then
              Exit(True);
          end;
          Exit(False);
        end;
    else
      FEscWaiting := False;
      Exit(False);
    end;
  end;
end;

function TLuxUnixEventSource.WaitReadable(TimeoutMs: Integer): Boolean;
var
  Fd: pollfd;
  Rc: cint;
begin
  Fd.fd := FSession.InputFd;
  Fd.events := POLLIN;
  Fd.revents := 0;
  Rc := FpPoll(@Fd, 1, TimeoutMs);
  Result := (Rc > 0) and ((Fd.revents and POLLIN) <> 0);
end;

function TLuxUnixEventSource.PollEvent(out Event: TLuxEvent): Boolean;
begin
  DrainResize;
  if PopPending(Event) then
    Exit(True);

  if DecodeAvailable(Event) then
    Exit(True);

  if ReadAvailable then
  begin
    if DecodeAvailable(Event) then
      Exit(True);
  end;

  DrainResize;
  if PopPending(Event) then
    Exit(True);

  { Ambiguous ESC may become ready without new bytes. }
  if FEscWaiting and (NowMs >= FEscDeadlineMs) then
  begin
    FEscWaiting := False;
    if FParser.ResolveAmbiguousEscape(Event) then
      Exit(True);
  end;

  Event := LuxEventNone;
  Result := False;
end;

function TLuxUnixEventSource.WaitEvent(out Event: TLuxEvent; TimeoutMs: Integer): Boolean;
var
  Deadline, NowT, Slice, Remaining: Int64;
  Infinite: Boolean;
begin
  if TimeoutMs = 0 then
    Exit(PollEvent(Event));

  Infinite := TimeoutMs < 0;
  if Infinite then
    Deadline := 0
  else
    Deadline := NowMs + TimeoutMs;

  while True do
  begin
    if PollEvent(Event) then
      Exit(True);

    NowT := NowMs;
    if FEscWaiting then
      Slice := FEscDeadlineMs - NowT
    else
      Slice := 50;

    if Slice < 0 then
      Slice := 0;

    if not Infinite then
    begin
      Remaining := Deadline - NowT;
      if Remaining <= 0 then
      begin
        Event := LuxEventNone;
        Exit(False);
      end;
      if Slice > Remaining then
        Slice := Remaining;
    end;

    if FEscWaiting and (Slice = 0) then
      Continue;

    WaitReadable(Integer(Slice));
  end;
end;

end.
