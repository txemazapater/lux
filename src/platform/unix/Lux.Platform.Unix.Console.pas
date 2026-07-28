{ Unix TTY capability probes and platform exceptions. }
unit Lux.Platform.Unix.Console;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  BaseUnix,
  Termio,
  Lux.Terminal.Errors;

type
  { Lightweight TTY capability snapshot (mirrors Windows caps where possible). }
  TLuxUnixConsoleCaps = record
    OutputFdValid: Boolean;
    InputFdValid: Boolean;
    OutputIsTty: Boolean;
    OutputRedirected: Boolean;
    InputIsTty: Boolean;
    AnsiLikelySupported: Boolean;
    Columns: Integer;
    Rows: Integer;
    LastError: cint;
  end;

  ELuxUnixTerminal = class(Exception)
  private
    FErrorCode: cint;
    FOperation: string;
  public
    constructor CreateOp(const AOperation: string; AErrorCode: cint);
    property ErrorCode: cint read FErrorCode;
    property Operation: string read FOperation;
  end;

function LuxUnixFormatError(AErrorCode: cint): string;
function LuxUnixProbeStdFds: TLuxUnixConsoleCaps;
function LuxUnixIsTty(AFd: cint): Boolean;
function LuxUnixQueryWinSize(AFd: cint; out AColumns, ARows: Integer): Boolean;

implementation

constructor ELuxUnixTerminal.CreateOp(const AOperation: string; AErrorCode: cint);
begin
  FOperation := AOperation;
  FErrorCode := AErrorCode;
  inherited Create(Format('%s failed (errno=%d): %s',
    [AOperation, AErrorCode, LuxUnixFormatError(AErrorCode)]));
end;

function LuxUnixFormatError(AErrorCode: cint): string;
begin
  Result := StrError(AErrorCode);
  if Result = '' then
    Result := 'unknown error';
end;

function LuxUnixIsTty(AFd: cint): Boolean;
begin
  Result := FpIsATTY(AFd) = 1;
end;

function LuxUnixQueryWinSize(AFd: cint; out AColumns, ARows: Integer): Boolean;
var
  WS: TWinSize;
begin
  AColumns := 0;
  ARows := 0;
  FillChar(WS, SizeOf(WS), 0);
  if FpIOCtl(AFd, TIOCGWINSZ, @WS) <> 0 then
    Exit(False);
  AColumns := WS.ws_col;
  ARows := WS.ws_row;
  Result := (AColumns > 0) and (ARows > 0);
end;

function LuxUnixProbeStdFds: TLuxUnixConsoleCaps;
var
  TermName: string;
begin
  FillChar(Result, SizeOf(Result), 0);

  Result.OutputFdValid := True;
  Result.InputFdValid := True;

  Result.OutputIsTty := LuxUnixIsTty(StdOutputHandle);
  Result.InputIsTty := LuxUnixIsTty(StdInputHandle);
  Result.OutputRedirected := not Result.OutputIsTty;

  if Result.OutputIsTty then
  begin
    TermName := GetEnvironmentVariable('TERM');
    Result.AnsiLikelySupported := (TermName <> '') and
      (CompareText(TermName, 'dumb') <> 0);
    if not LuxUnixQueryWinSize(StdOutputHandle, Result.Columns, Result.Rows) then
      LuxUnixQueryWinSize(StdInputHandle, Result.Columns, Result.Rows);
  end
  else
    Result.LastError := FpGetErrno;

  if not Result.AnsiLikelySupported then
  begin
    { Many CI/script environments still accept ANSI when forced; keep the flag honest. }
  end;
end;

end.
