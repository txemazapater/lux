{ Unix terminal session: acquire, configure, restore. }
unit Lux.Platform.Unix.TerminalSession;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  BaseUnix,
  Termio,
  Lux.Terminal.Writer,
  Lux.Terminal.Errors,
  Lux.Terminal.Ansi,
  Lux.Platform.Unix.Console,
  Lux.Platform.Unix.TerminalWriter;

type
  { Owns termios / cursor visibility for the lifetime of a LUX run.
    API mirrors TLuxWindowsTerminalSession for Phase 4 alignment.
    Restoration is idempotent and invoked from Destroy. }
  TLuxUnixTerminalSession = class
  private
    FOpen: Boolean;
    FRestored: Boolean;
    FOutputFd: cint;
    FInputFd: cint;
    FOriginalTermios: Termios;
    FHaveTermios: Boolean;
    FCaps: TLuxUnixConsoleCaps;
    FWriterObj: TLuxUnixTerminalWriter;
    FWriter: ILuxTerminalWriter;
    procedure CaptureState;
    procedure ApplyLuxState;
    procedure RestoreState;
  public
    constructor Create;
    destructor Destroy; override;

    class function Probe: TLuxUnixConsoleCaps; static;

    { Acquire a TTY-backed stdout. Raises if stdout is redirected or TERM is dumb. }
    procedure Open;
    procedure Close;

    property IsOpen: Boolean read FOpen;
    property Capabilities: TLuxUnixConsoleCaps read FCaps;
    property Writer: ILuxTerminalWriter read FWriter;
    property OutputFd: cint read FOutputFd;
    property InputFd: cint read FInputFd;
    property Columns: Integer read FCaps.Columns;
    property Rows: Integer read FCaps.Rows;
  end;

implementation

constructor TLuxUnixTerminalSession.Create;
begin
  inherited Create;
  FOpen := False;
  FRestored := True;
  FHaveTermios := False;
  FWriterObj := nil;
  FWriter := nil;
  FOutputFd := StdOutputHandle;
  FInputFd := StdInputHandle;
end;

destructor TLuxUnixTerminalSession.Destroy;
begin
  Close;
  FWriter := nil;
  FWriterObj := nil;
  inherited Destroy;
end;

class function TLuxUnixTerminalSession.Probe: TLuxUnixConsoleCaps;
begin
  Result := LuxUnixProbeStdFds;
end;

procedure TLuxUnixTerminalSession.CaptureState;
var
  TtyFd: cint;
begin
  { Prefer stdin for termios (controlling terminal); fall back to stdout. }
  TtyFd := FInputFd;
  if not LuxUnixIsTty(TtyFd) then
    TtyFd := FOutputFd;

  FHaveTermios := False;
  if LuxUnixIsTty(TtyFd) then
  begin
    FillChar(FOriginalTermios, SizeOf(FOriginalTermios), 0);
    if TCGetAttr(TtyFd, FOriginalTermios) = 0 then
      FHaveTermios := True
    else
      raise ELuxUnixTerminal.CreateOp('tcgetattr', FpGetErrno);
  end;
end;

procedure TLuxUnixTerminalSession.ApplyLuxState;
begin
  { Phase 3B does not enter raw input mode (Phase 4). Capture termios now so
    future input changes can restore cleanly. Hide cursor via ANSI. }
  if FWriter <> nil then
  begin
    FWriter.WriteRaw(LuxAnsiHideCursor);
    FWriter.Flush;
  end;
end;

procedure TLuxUnixTerminalSession.RestoreState;
var
  TtyFd: cint;
begin
  if FRestored then
    Exit;

  if FWriter <> nil then
  begin
    try
      FWriter.WriteRaw(LuxAnsiShowCursor);
      FWriter.Flush;
    except
      { Best-effort cursor restore during teardown. }
    end;
  end;

  if FHaveTermios then
  begin
    TtyFd := FInputFd;
    if not LuxUnixIsTty(TtyFd) then
      TtyFd := FOutputFd;
    if LuxUnixIsTty(TtyFd) then
      TCSetAttr(TtyFd, TCSANOW, FOriginalTermios);
  end;

  FRestored := True;
  FOpen := False;
end;

procedure TLuxUnixTerminalSession.Open;
begin
  if FOpen then
    Exit;

  FCaps := Probe;
  FOutputFd := StdOutputHandle;
  FInputFd := StdInputHandle;

  if not FCaps.OutputFdValid then
    raise ELuxTerminalUnavailable.Create(
      'Standard output is invalid; cannot open a Unix terminal session.');
  if FCaps.OutputRedirected or (not FCaps.OutputIsTty) then
    raise ELuxTerminalUnavailable.Create(
      'Standard output is redirected or not a TTY.');
  if not FCaps.AnsiLikelySupported then
    raise ELuxTerminalUnavailable.Create(
      'TERM is unset or dumb; ANSI/VT output is not available.');

  CaptureState;
  FRestored := False;
  try
    FWriterObj := TLuxUnixTerminalWriter.Create(FOutputFd, False);
    FWriter := FWriterObj;
    ApplyLuxState;
    FOpen := True;
  except
    RestoreState;
    FWriter := nil;
    FWriterObj := nil;
    raise;
  end;
end;

procedure TLuxUnixTerminalSession.Close;
begin
  { Restore while writer is still alive so cursor show can be emitted. }
  RestoreState;
  FWriter := nil;
  FWriterObj := nil;
end;

end.
