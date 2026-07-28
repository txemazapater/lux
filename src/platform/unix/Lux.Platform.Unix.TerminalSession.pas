{ Unix terminal session: acquire, configure (raw/mouse/alt), restore. }
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
  { Owns termios / cursor / alt-screen / mouse for the lifetime of a LUX run.
    API mirrors TLuxWindowsTerminalSession for Phase 4 alignment.
    Restoration is idempotent and invoked from Destroy.
    Raw mode and mouse enablement live here; byte decoding lives in the
    event source / input parser. }
  TLuxUnixTerminalSession = class
  private
    FOpen: Boolean;
    FRestored: Boolean;
    FRawActive: Boolean;
    FMouseActive: Boolean;
    FAltScreenActive: Boolean;
    FOutputFd: cint;
    FInputFd: cint;
    FTermiosFd: cint;
    FOriginalTermios: Termios;
    FHaveTermios: Boolean;
    FCaps: TLuxUnixConsoleCaps;
    FWriterObj: TLuxUnixTerminalWriter;
    FWriter: ILuxTerminalWriter;
    procedure CaptureState;
    procedure ApplyLuxState;
    procedure RestoreState;
    procedure ApplyRawMode;
    procedure EmitModes(AEnable: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    class function Probe: TLuxUnixConsoleCaps; static;

    { Acquire a TTY-backed stdout. Raises if stdout is redirected or TERM is dumb. }
    procedure Open;
    procedure Close;

    { Refresh Columns/Rows from TIOCGWINSZ (safe outside signal handlers). }
    procedure RefreshSize;

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
  FRawActive := False;
  FMouseActive := False;
  FAltScreenActive := False;
  FHaveTermios := False;
  FWriterObj := nil;
  FWriter := nil;
  FOutputFd := StdOutputHandle;
  FInputFd := StdInputHandle;
  FTermiosFd := StdInputHandle;
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
begin
  FTermiosFd := FInputFd;
  if not LuxUnixIsTty(FTermiosFd) then
    FTermiosFd := FOutputFd;

  FHaveTermios := False;
  if LuxUnixIsTty(FTermiosFd) then
  begin
    FillChar(FOriginalTermios, SizeOf(FOriginalTermios), 0);
    if TCGetAttr(FTermiosFd, FOriginalTermios) = 0 then
      FHaveTermios := True
    else
      raise ELuxUnixTerminal.CreateOp('tcgetattr', FpGetErrno);
  end;
end;

procedure TLuxUnixTerminalSession.ApplyRawMode;
var
  Raw: Termios;
begin
  if not FHaveTermios then
    Exit;
  Raw := FOriginalTermios;
  Raw.c_lflag := Raw.c_lflag and not (ECHO or ICANON or ISIG or IEXTEN);
  Raw.c_iflag := Raw.c_iflag and not (IXON or ICRNL or INLCR or IGNCR or
    BRKINT or PARMRK or ISTRIP);
  Raw.c_oflag := Raw.c_oflag and not OPOST;
  Raw.c_cflag := (Raw.c_cflag and not CSIZE) or CS8;
  Raw.c_cc[VMIN] := 0;
  Raw.c_cc[VTIME] := 0;
  if TCSetAttr(FTermiosFd, TCSANOW, Raw) <> 0 then
    raise ELuxUnixTerminal.CreateOp('tcsetattr(raw)', FpGetErrno);
  FRawActive := True;
end;

procedure TLuxUnixTerminalSession.EmitModes(AEnable: Boolean);
begin
  if FWriter = nil then
    Exit;
  if AEnable then
  begin
    FWriter.WriteRaw(LuxAnsiEnterAltScreen);
    FWriter.WriteRaw(LuxAnsiHideCursor);
    FWriter.WriteRaw(LuxAnsiEnableMouseSgr);
    FWriter.Flush;
    FAltScreenActive := True;
    FMouseActive := True;
  end
  else
  begin
    if FMouseActive then
    begin
      try
        FWriter.WriteRaw(LuxAnsiDisableMouseSgr);
      except
      end;
      FMouseActive := False;
    end;
    if FAltScreenActive then
    begin
      try
        FWriter.WriteRaw(LuxAnsiLeaveAltScreen);
      except
      end;
      FAltScreenActive := False;
    end;
    try
      FWriter.WriteRaw(LuxAnsiShowCursor);
      FWriter.Flush;
    except
    end;
  end;
end;

procedure TLuxUnixTerminalSession.ApplyLuxState;
begin
  ApplyRawMode;
  EmitModes(True);
end;

procedure TLuxUnixTerminalSession.RestoreState;
begin
  if FRestored then
    Exit;

  EmitModes(False);

  if FHaveTermios and LuxUnixIsTty(FTermiosFd) then
  begin
    TCSetAttr(FTermiosFd, TCSANOW, FOriginalTermios);
    FRawActive := False;
  end;

  FRestored := True;
  FOpen := False;
end;

procedure TLuxUnixTerminalSession.RefreshSize;
var
  Cols, Rows: Integer;
begin
  if LuxUnixQueryWinSize(FOutputFd, Cols, Rows) or
     LuxUnixQueryWinSize(FInputFd, Cols, Rows) then
  begin
    FCaps.Columns := Cols;
    FCaps.Rows := Rows;
  end;
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
  RestoreState;
  FWriter := nil;
  FWriterObj := nil;
end;

end.
