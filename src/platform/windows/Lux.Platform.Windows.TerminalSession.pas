{ Windows console session: acquire, configure, restore. }
unit Lux.Platform.Windows.TerminalSession;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Windows,
  Lux.Terminal.Writer,
  Lux.Terminal.Errors,
  Lux.Platform.Windows.Console,
  Lux.Platform.Windows.TerminalWriter;

type
  { Owns console mode / code-page / cursor state for the lifetime of a LUX run.
    Restoration is idempotent and invoked from Destroy. }
  TLuxWindowsTerminalSession = class
  private
    FOpen: Boolean;
    FRestored: Boolean;
    FOutput: THandle;
    FInput: THandle;
    FOriginalOutputMode: DWORD;
    FOriginalInputMode: DWORD;
    FOriginalOutputCP: UINT;
    FOriginalInputCP: UINT;
    FOriginalCursor: CONSOLE_CURSOR_INFO;
    FHaveOutputMode: Boolean;
    FHaveInputMode: Boolean;
    FHaveCursor: Boolean;
    FCaps: TLuxWindowsConsoleCaps;
    FWriterObj: TLuxWindowsTerminalWriter;
    FWriter: ILuxTerminalWriter;
    procedure CaptureState;
    procedure ApplyLuxState;
    procedure RestoreState;
  public
    constructor Create;
    destructor Destroy; override;

    { Probe std handles without mutating console state permanently. }
    class function Probe: TLuxWindowsConsoleCaps; static;

    { Acquire and configure the console. Raises if stdout is not a console
      or Virtual Terminal Processing cannot be enabled. }
    procedure Open;
    { Restore original console state. Safe to call multiple times. }
    procedure Close;

    property IsOpen: Boolean read FOpen;
    property Capabilities: TLuxWindowsConsoleCaps read FCaps;
    property Writer: ILuxTerminalWriter read FWriter;
    property OutputHandle: THandle read FOutput;
    property InputHandle: THandle read FInput;
  end;

implementation

constructor TLuxWindowsTerminalSession.Create;
begin
  inherited Create;
  FOpen := False;
  FRestored := True;
  FWriterObj := nil;
  FWriter := nil;
end;

destructor TLuxWindowsTerminalSession.Destroy;
begin
  Close;
  FWriter := nil;
  FWriterObj := nil;
  inherited Destroy;
end;

class function TLuxWindowsTerminalSession.Probe: TLuxWindowsConsoleCaps;
begin
  Result := LuxWindowsProbeStdHandles;
end;

procedure TLuxWindowsTerminalSession.CaptureState;
var
  Err: DWORD;
begin
  FHaveOutputMode := LuxWindowsIsConsoleHandle(FOutput, FOriginalOutputMode, Err);
  if not FHaveOutputMode then
    raise ELuxWindowsTerminal.CreateOp('GetConsoleMode(stdout)', Err);

  FHaveInputMode := LuxWindowsIsConsoleHandle(FInput, FOriginalInputMode, Err);

  FOriginalOutputCP := GetConsoleOutputCP;
  FOriginalInputCP := GetConsoleCP;

  FHaveCursor := GetConsoleCursorInfo(FOutput, FOriginalCursor);
end;

procedure TLuxWindowsTerminalSession.ApplyLuxState;
var
  Mode: DWORD;
  Err: DWORD;
  Cursor: CONSOLE_CURSOR_INFO;
begin
  Mode := FOriginalOutputMode;
  if not LuxWindowsTryEnableVirtualTerminal(FOutput, Mode, Err) then
    raise ELuxWindowsTerminal.CreateOp('SetConsoleMode(ENABLE_VIRTUAL_TERMINAL_PROCESSING)', Err);
  FCaps.VirtualTerminalSupported := True;

  if not SetConsoleOutputCP(LuxWinCP_UTF8) then
    raise ELuxWindowsTerminal.CreateOp('SetConsoleOutputCP(UTF-8)', GetLastError);
  if not SetConsoleCP(LuxWinCP_UTF8) then
    raise ELuxWindowsTerminal.CreateOp('SetConsoleCP(UTF-8)', GetLastError);

  if FHaveCursor then
  begin
    Cursor := FOriginalCursor;
    Cursor.bVisible := False;
    SetConsoleCursorInfo(FOutput, Cursor);
  end;
end;

procedure TLuxWindowsTerminalSession.RestoreState;
begin
  if FRestored then
    Exit;

  if FHaveCursor and (FOutput <> 0) and (FOutput <> INVALID_HANDLE_VALUE) then
    SetConsoleCursorInfo(FOutput, FOriginalCursor);

  if FOriginalOutputCP <> 0 then
    SetConsoleOutputCP(FOriginalOutputCP);
  if FOriginalInputCP <> 0 then
    SetConsoleCP(FOriginalInputCP);

  if FHaveOutputMode and (FOutput <> 0) and (FOutput <> INVALID_HANDLE_VALUE) then
    SetConsoleMode(FOutput, FOriginalOutputMode);
  if FHaveInputMode and (FInput <> 0) and (FInput <> INVALID_HANDLE_VALUE) then
    SetConsoleMode(FInput, FOriginalInputMode);

  FRestored := True;
  FOpen := False;
end;

procedure TLuxWindowsTerminalSession.Open;
begin
  if FOpen then
    Exit;

  FCaps := Probe;
  if not FCaps.OutputHandleValid then
    raise ELuxTerminalUnavailable.Create(
      'Standard output handle is invalid; cannot open a Windows terminal session.');
  if FCaps.OutputRedirected or (not FCaps.OutputIsConsole) then
    raise ELuxTerminalUnavailable.Create(
      'Standard output is redirected or not attached to a console.');
  if not FCaps.VirtualTerminalSupported then
    raise ELuxTerminalUnavailable.Create(
      'Virtual Terminal Processing is not available on this console.');

  FOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  FInput := GetStdHandle(STD_INPUT_HANDLE);

  CaptureState;
  FRestored := False;
  try
    ApplyLuxState;
    FWriterObj := TLuxWindowsTerminalWriter.Create(FOutput, False);
    FWriter := FWriterObj;
    FOpen := True;
  except
    RestoreState;
    FWriter := nil;
    FWriterObj := nil;
    raise;
  end;
end;

procedure TLuxWindowsTerminalSession.Close;
begin
  FWriter := nil;
  FWriterObj := nil;
  RestoreState;
end;

end.
