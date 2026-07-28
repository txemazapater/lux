{ Windows console capability probes and platform exceptions. }
unit Lux.Platform.Windows.Console;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Windows;

const
  LuxWinCP_UTF8 = 65001;
  LuxWinENABLE_VIRTUAL_TERMINAL_PROCESSING = $0004;
  LuxWinENABLE_PROCESSED_OUTPUT = $0001;
  LuxWinENABLE_WRAP_AT_EOL_OUTPUT = $0002;

type
  { Lightweight console capability snapshot. }
  TLuxWindowsConsoleCaps = record
    OutputHandleValid: Boolean;
    InputHandleValid: Boolean;
    OutputIsConsole: Boolean;
    OutputRedirected: Boolean;
    InputIsConsole: Boolean;
    CanQueryOutputMode: Boolean;
    CanQueryInputMode: Boolean;
    VirtualTerminalSupported: Boolean;
    LastError: DWORD;
  end;

  ELuxTerminalUnavailable = class(Exception);

  ELuxWindowsTerminal = class(Exception)
  private
    FErrorCode: DWORD;
    FOperation: string;
  public
    constructor CreateOp(const AOperation: string; AErrorCode: DWORD);
    property ErrorCode: DWORD read FErrorCode;
    property Operation: string read FOperation;
  end;

function LuxWindowsFormatError(AErrorCode: DWORD): string;
function LuxWindowsProbeStdHandles: TLuxWindowsConsoleCaps;
function LuxWindowsIsConsoleHandle(AHandle: THandle; out AMode: DWORD;
  out AError: DWORD): Boolean;
function LuxWindowsTryEnableVirtualTerminal(AOutput: THandle;
  var AMode: DWORD; out AError: DWORD): Boolean;

implementation

constructor ELuxWindowsTerminal.CreateOp(const AOperation: string;
  AErrorCode: DWORD);
begin
  FOperation := AOperation;
  FErrorCode := AErrorCode;
  inherited Create(Format('%s failed (GetLastError=%d): %s',
    [AOperation, AErrorCode, LuxWindowsFormatError(AErrorCode)]));
end;

function LuxWindowsFormatError(AErrorCode: DWORD): string;
var
  Buf: array[0..511] of WideChar;
  N: DWORD;
begin
  FillChar(Buf[0], SizeOf(Buf), 0);
  N := FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
    nil, AErrorCode, 0, @Buf[0], Length(Buf), nil);
  if N = 0 then
    Result := 'unknown error'
  else
  begin
    Result := string(PWideChar(@Buf[0]));
    Result := Trim(Result);
  end;
end;

function LuxWindowsIsConsoleHandle(AHandle: THandle; out AMode: DWORD;
  out AError: DWORD): Boolean;
begin
  AMode := 0;
  AError := 0;
  if (AHandle = 0) or (AHandle = INVALID_HANDLE_VALUE) then
  begin
    AError := ERROR_INVALID_HANDLE;
    Exit(False);
  end;
  if GetConsoleMode(AHandle, AMode) then
    Exit(True);
  AError := GetLastError;
  Result := False;
end;

function LuxWindowsProbeStdHandles: TLuxWindowsConsoleCaps;
var
  OutH, InH: THandle;
  Mode: DWORD;
  Err: DWORD;
begin
  FillChar(Result, SizeOf(Result), 0);
  OutH := GetStdHandle(STD_OUTPUT_HANDLE);
  InH := GetStdHandle(STD_INPUT_HANDLE);

  Result.OutputHandleValid := (OutH <> 0) and (OutH <> INVALID_HANDLE_VALUE);
  Result.InputHandleValid := (InH <> 0) and (InH <> INVALID_HANDLE_VALUE);

  if Result.OutputHandleValid then
  begin
    Result.OutputIsConsole := LuxWindowsIsConsoleHandle(OutH, Mode, Err);
    Result.CanQueryOutputMode := Result.OutputIsConsole;
    if not Result.OutputIsConsole then
    begin
      Result.OutputRedirected := True;
      Result.LastError := Err;
    end
    else
    begin
      Result.OutputRedirected := False;
      { Probe VT without permanently enabling it. }
      if (Mode and LuxWinENABLE_VIRTUAL_TERMINAL_PROCESSING) <> 0 then
        Result.VirtualTerminalSupported := True
      else
      begin
        if SetConsoleMode(OutH, Mode or LuxWinENABLE_VIRTUAL_TERMINAL_PROCESSING) then
        begin
          Result.VirtualTerminalSupported := True;
          SetConsoleMode(OutH, Mode); { restore probe }
        end
        else
        begin
          Result.VirtualTerminalSupported := False;
          Result.LastError := GetLastError;
          SetConsoleMode(OutH, Mode);
        end;
      end;
    end;
  end
  else
  begin
    Result.OutputRedirected := True;
    Result.LastError := ERROR_INVALID_HANDLE;
  end;

  if Result.InputHandleValid then
  begin
    Result.InputIsConsole := LuxWindowsIsConsoleHandle(InH, Mode, Err);
    Result.CanQueryInputMode := Result.InputIsConsole;
  end;
end;

function LuxWindowsTryEnableVirtualTerminal(AOutput: THandle;
  var AMode: DWORD; out AError: DWORD): Boolean;
var
  NewMode: DWORD;
begin
  AError := 0;
  NewMode := AMode or LuxWinENABLE_VIRTUAL_TERMINAL_PROCESSING
    or LuxWinENABLE_PROCESSED_OUTPUT or LuxWinENABLE_WRAP_AT_EOL_OUTPUT;
  if SetConsoleMode(AOutput, NewMode) then
  begin
    AMode := NewMode;
    Exit(True);
  end;
  AError := GetLastError;
  Result := False;
end;

end.
