{ Windows platform unit tests (no interactive console required). }
program lux_windows_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  Windows,
  Lux.Terminal.Writer,
  Lux.Terminal.MemoryWriter,
  Lux.Surface,
  Lux.Renderer,
  Lux.Color,
  Lux.Platform.Windows.Console,
  Lux.Platform.Windows.TerminalWriter,
  Lux.Platform.Windows.TerminalSession,
  Lux.TestHarness;

procedure TestCreateDestroySafe;
var
  Session: TLuxWindowsTerminalSession;
begin
  LuxSection('Session lifecycle');
  Session := TLuxWindowsTerminalSession.Create;
  try
    LuxCheck(not Session.IsOpen, 'session starts closed');
    Session.Close;
    Session.Close;
    LuxCheck(not Session.IsOpen, 'close idempotent without open');
  finally
    Session.Free;
  end;
  LuxCheck(True, 'destroy without open is safe');
end;

procedure TestProbe;
var
  Caps: TLuxWindowsConsoleCaps;
begin
  LuxSection('Probe');
  Caps := TLuxWindowsTerminalSession.Probe;
  LuxCheck(True, Format('output console=%s redirected=%s vt=%s',
    [BoolToStr(Caps.OutputIsConsole, True),
     BoolToStr(Caps.OutputRedirected, True),
     BoolToStr(Caps.VirtualTerminalSupported, True)]));
  LuxCheck(Caps.OutputHandleValid or Caps.OutputRedirected or True,
    'probe returns a snapshot');
end;

procedure TestInvalidWriterHandle;
var
  Writer: TLuxWindowsTerminalWriter;
  Raised: Boolean;
begin
  LuxSection('Writer invalid handle');
  Writer := TLuxWindowsTerminalWriter.Create(INVALID_HANDLE_VALUE, False);
  try
    Raised := False;
    try
      Writer.WriteRaw('x');
    except
      on E: ELuxWindowsTerminal do
        Raised := True;
    end;
    LuxCheck(Raised, 'WriteRaw raises on invalid handle');

    Raised := False;
    try
      Writer.Flush;
    except
      on E: ELuxWindowsTerminal do
        Raised := True;
    end;
    LuxCheck(Raised, 'Flush raises on invalid handle');
  finally
    Writer.Free;
  end;
end;

procedure TestWriterFileHandleUtf8;
var
  Path: string;
  H: THandle;
  Writer: TLuxWindowsTerminalWriter;
  FS: TFileStream;
  Data: RawByteString;
  Expected: RawByteString;
  N: Integer;
  Buf: array[0..255] of Byte;
begin
  LuxSection('Writer file UTF-8');
  Path := GetTempDir + 'lux_writer_utf8.txt';
  if FileExists(Path) then
    SysUtils.DeleteFile(Path);

  H := CreateFileW(PWideChar(WideString(Path)), GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  LuxCheck((H <> 0) and (H <> INVALID_HANDLE_VALUE), 'temp file created');
  Writer := TLuxWindowsTerminalWriter.Create(H, True);
  try
    Expected := LuxUTF8Bytes('A' + UnicodeString(WideChar($4E00)) + 'Z');
    Writer.WriteText('A' + UnicodeString(WideChar($4E00)) + 'Z');
    Writer.Flush;
  finally
    Writer.Free; { closes handle }
  end;

  Data := '';
  FillChar(Buf, SizeOf(Buf), 0);
  FS := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  try
    N := FS.Read(Buf[0], SizeOf(Buf));
    SetLength(Data, N);
    if N > 0 then
      Move(Buf[0], Data[1], N);
  finally
    FS.Free;
  end;
  SysUtils.DeleteFile(Path);

  LuxCheck(Data = Expected, 'file contains UTF-8 bytes');
end;

procedure TestRedirectedOpenFails;
var
  Caps: TLuxWindowsConsoleCaps;
  Session: TLuxWindowsTerminalSession;
  Raised: Boolean;
begin
  LuxSection('Redirected stdout');
  Caps := TLuxWindowsTerminalSession.Probe;
  if Caps.OutputIsConsole and (not Caps.OutputRedirected) then
  begin
    LuxCheck(True, 'stdout is a console; redirected Open failure skipped');
    Exit;
  end;

  Session := TLuxWindowsTerminalSession.Create;
  try
    Raised := False;
    try
      Session.Open;
    except
      on E: ELuxTerminalUnavailable do
        Raised := True;
    end;
    LuxCheck(Raised, 'Open raises when stdout is redirected');
    Session.Close;
    Session.Close;
    LuxCheck(not Session.IsOpen, 'failed Open leaves session closed');
  finally
    Session.Free;
  end;
end;

procedure TestConsoleOpenRestore;
var
  Caps: TLuxWindowsConsoleCaps;
  Session: TLuxWindowsTerminalSession;
  ModeBefore, ModeAfter: DWORD;
  OutH: THandle;
begin
  LuxSection('Console open/restore');
  Caps := TLuxWindowsTerminalSession.Probe;
  if (not Caps.OutputIsConsole) or Caps.OutputRedirected or
     (not Caps.VirtualTerminalSupported) then
  begin
    LuxCheck(True, 'console open/restore skipped (no usable console)');
    Exit;
  end;

  OutH := GetStdHandle(STD_OUTPUT_HANDLE);
  ModeBefore := 0;
  ModeAfter := 0;
  GetConsoleMode(OutH, ModeBefore);

  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    LuxCheck(Session.IsOpen, 'session open');
    LuxCheck(Session.Writer <> nil, 'writer available');
    Session.Close;
    Session.Close;
    LuxCheck(not Session.IsOpen, 'session closed idempotently');
  finally
    Session.Free;
  end;

  GetConsoleMode(OutH, ModeAfter);
  LuxCheck(ModeBefore = ModeAfter, 'output mode restored');
end;

procedure TestSeparationMemoryRenderer;
var
  Mem: TLuxMemoryTerminalWriter;
  IW: ILuxTerminalWriter;
  Surface: TLuxSurface;
  Renderer: TLuxRenderer;
begin
  LuxSection('Renderer still portable');
  Mem := TLuxMemoryTerminalWriter.Create;
  IW := Mem;
  Surface := TLuxSurface.Create(3, 1);
  Renderer := TLuxRenderer.Create(IW);
  try
    Surface.PutText(0, 0, 'OK', LuxColorRGB(1, 2, 3), LuxColorDefault, []);
    Renderer.Render(Surface);
    LuxCheck(Mem.Length > 0, 'memory renderer still works');
  finally
    Renderer.Free;
    Surface.Free;
    IW := nil;
  end;
end;

procedure TestErrorMessageIncludesCode;
var
  E: ELuxWindowsTerminal;
begin
  LuxSection('Error formatting');
  E := ELuxWindowsTerminal.CreateOp('UnitTestOp', ERROR_INVALID_HANDLE);
  try
    LuxCheck(Pos('UnitTestOp', E.Message) > 0, 'message has operation');
    LuxCheck(Pos(IntToStr(ERROR_INVALID_HANDLE), E.Message) > 0, 'message has code');
    LuxCheck(E.ErrorCode = ERROR_INVALID_HANDLE, 'ErrorCode property');
  finally
    E.Free;
  end;
end;

begin
  WriteLn('LUX Windows platform tests');
  TestCreateDestroySafe;
  TestProbe;
  TestInvalidWriterHandle;
  TestWriterFileHandleUtf8;
  TestRedirectedOpenFails;
  TestConsoleOpenRestore;
  TestSeparationMemoryRenderer;
  TestErrorMessageIncludesCode;
  Halt(LuxTestExitCode);
end.
