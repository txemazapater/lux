{ Windows console session: acquire, configure input/output modes, restore. }
unit Lux.Platform.Windows.TerminalSession;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Windows,
  Lux.Terminal.Writer,
  Lux.Terminal.Errors,
  Lux.Terminal.Ansi,
  Lux.Platform.Windows.Console,
  Lux.Platform.Windows.TerminalWriter;

const
  LuxWinENABLE_PROCESSED_INPUT = $0001;
  LuxWinENABLE_LINE_INPUT = $0002;
  LuxWinENABLE_ECHO_INPUT = $0004;
  LuxWinENABLE_WINDOW_INPUT = $0008;
  LuxWinENABLE_MOUSE_INPUT = $0010;
  LuxWinENABLE_INSERT_MODE = $0020;
  LuxWinENABLE_QUICK_EDIT_MODE = $0040;
  LuxWinENABLE_EXTENDED_FLAGS = $0080;
  LuxWinENABLE_VIRTUAL_TERMINAL_INPUT = $0200;

type
  { Owns console mode / code-page / cursor / mouse for the lifetime of a LUX run.
    Restoration is idempotent and invoked from Destroy.
    Input record decoding lives in the event source / translator. }
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
    FAltScreenActive: Boolean;
    FCaps: TLuxWindowsConsoleCaps;
    FWriterObj: TLuxWindowsTerminalWriter;
    FWriter: ILuxTerminalWriter;
    FColumns: Integer;
    FRows: Integer;
    procedure CaptureState;
    procedure ApplyLuxState;
    procedure RestoreState;
    procedure ApplyInputModes;
    procedure EmitAltScreen(AEnable: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    class function Probe: TLuxWindowsConsoleCaps; static;

    procedure Open;
    procedure Close;

    { Refresh Columns/Rows from console screen buffer info. }
    procedure RefreshSize;

    property IsOpen: Boolean read FOpen;
    property Capabilities: TLuxWindowsConsoleCaps read FCaps;
    property Writer: ILuxTerminalWriter read FWriter;
    property OutputHandle: THandle read FOutput;
    property InputHandle: THandle read FInput;
    property Columns: Integer read FColumns;
    property Rows: Integer read FRows;
  end;

implementation

constructor TLuxWindowsTerminalSession.Create;
begin
  inherited Create;
  FOpen := False;
  FRestored := True;
  FAltScreenActive := False;
  FWriterObj := nil;
  FWriter := nil;
  FColumns := 80;
  FRows := 24;
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

procedure TLuxWindowsTerminalSession.ApplyInputModes;
var
  Mode: DWORD;
begin
  if not FHaveInputMode then
    Exit;
  Mode := FOriginalInputMode;
  Mode := Mode and not (LuxWinENABLE_PROCESSED_INPUT or LuxWinENABLE_LINE_INPUT or
    LuxWinENABLE_ECHO_INPUT or LuxWinENABLE_QUICK_EDIT_MODE);
  Mode := Mode or LuxWinENABLE_WINDOW_INPUT or LuxWinENABLE_MOUSE_INPUT or
    LuxWinENABLE_EXTENDED_FLAGS;
  { VT input is optional; ignore failure. }
  if not SetConsoleMode(FInput, Mode or LuxWinENABLE_VIRTUAL_TERMINAL_INPUT) then
    if not SetConsoleMode(FInput, Mode) then
      raise ELuxWindowsTerminal.CreateOp('SetConsoleMode(stdin)', GetLastError);
end;

procedure TLuxWindowsTerminalSession.EmitAltScreen(AEnable: Boolean);
begin
  if FWriter = nil then
    Exit;
  if AEnable then
  begin
    FWriter.WriteRaw(LuxAnsiEnterAltScreen);
    FWriter.Flush;
    FAltScreenActive := True;
  end
  else if FAltScreenActive then
  begin
    try
      FWriter.WriteRaw(LuxAnsiLeaveAltScreen);
      FWriter.Flush;
    except
    end;
    FAltScreenActive := False;
  end;
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

  ApplyInputModes;

  if FHaveCursor then
  begin
    Cursor := FOriginalCursor;
    Cursor.bVisible := False;
    SetConsoleCursorInfo(FOutput, Cursor);
  end;

  FWriterObj := TLuxWindowsTerminalWriter.Create(FOutput, False);
  FWriter := FWriterObj;
  EmitAltScreen(True);
  RefreshSize;
end;

procedure TLuxWindowsTerminalSession.RestoreState;
begin
  if FRestored then
    Exit;

  EmitAltScreen(False);

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

procedure TLuxWindowsTerminalSession.RefreshSize;
var
  Info: CONSOLE_SCREEN_BUFFER_INFO;
begin
  if GetConsoleScreenBufferInfo(FOutput, Info) then
  begin
    FColumns := Info.srWindow.Right - Info.srWindow.Left + 1;
    FRows := Info.srWindow.Bottom - Info.srWindow.Top + 1;
    if FColumns < 1 then
      FColumns := Info.dwSize.X;
    if FRows < 1 then
      FRows := Info.dwSize.Y;
  end;
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
  { Restore while writer is still alive so alt-screen leave can be emitted. }
  RestoreState;
  FWriter := nil;
  FWriterObj := nil;
end;

end.
