{ Unix platform unit tests (no interactive TTY required). }
program lux_unix_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  BaseUnix,
  Lux.Terminal.Writer,
  Lux.Terminal.Errors,
  Lux.Terminal.MemoryWriter,
  Lux.Surface,
  Lux.Renderer,
  Lux.Color,
  Lux.Platform.Unix.Console,
  Lux.Platform.Unix.TerminalWriter,
  Lux.Platform.Unix.TerminalSession,
  Lux.TestHarness;

procedure TestCreateDestroySafe;
var
  Session: TLuxUnixTerminalSession;
begin
  LuxSection('Session lifecycle');
  Session := TLuxUnixTerminalSession.Create;
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
  Caps: TLuxUnixConsoleCaps;
begin
  LuxSection('Probe');
  Caps := TLuxUnixTerminalSession.Probe;
  LuxCheck(True, Format('output tty=%s redirected=%s ansi=%s size=%dx%d',
    [BoolToStr(Caps.OutputIsTty, True),
     BoolToStr(Caps.OutputRedirected, True),
     BoolToStr(Caps.AnsiLikelySupported, True),
     Caps.Columns, Caps.Rows]));
end;

procedure TestInvalidWriterFd;
var
  Writer: TLuxUnixTerminalWriter;
  Raised: Boolean;
begin
  LuxSection('Writer invalid fd');
  Writer := TLuxUnixTerminalWriter.Create(-1, False);
  try
    Raised := False;
    try
      Writer.WriteRaw('x');
    except
      on E: ELuxUnixTerminal do
        Raised := True;
    end;
    LuxCheck(Raised, 'WriteRaw raises on invalid fd');

    Raised := False;
    try
      Writer.Flush;
    except
      on E: ELuxUnixTerminal do
        Raised := True;
    end;
    LuxCheck(Raised, 'Flush raises on invalid fd');
  finally
    Writer.Free;
  end;
end;

procedure TestWriterFileUtf8;
var
  Path: string;
  Fd: cint;
  Writer: TLuxUnixTerminalWriter;
  Expected, Data: RawByteString;
  F: File of Byte;
  B: Byte;
  N: Integer;
begin
  LuxSection('Writer file UTF-8');
  Path := GetTempDir + 'lux_unix_writer_utf8.txt';
  if FileExists(Path) then
    SysUtils.DeleteFile(Path);

  Fd := FpOpen(PChar(Path), O_WrOnly or O_Creat or O_Trunc, &644);
  LuxCheck(Fd >= 0, 'temp file created');
  Writer := TLuxUnixTerminalWriter.Create(Fd, True);
  try
    Expected := LuxUTF8Bytes('A' + UnicodeString(WideChar($4E00)) + 'Z');
    Writer.WriteText('A' + UnicodeString(WideChar($4E00)) + 'Z');
    Writer.Flush;
  finally
    Writer.Free;
  end;

  Data := '';
  AssignFile(F, Path);
  Reset(F);
  try
    N := 0;
    while not Eof(F) do
    begin
      Read(F, B);
      Inc(N);
      SetLength(Data, N);
      Data[N] := AnsiChar(B);
    end;
  finally
    CloseFile(F);
  end;
  SysUtils.DeleteFile(Path);
  LuxCheck(Data = Expected, 'file contains UTF-8 bytes');
end;

procedure TestRedirectedOpenFails;
var
  Caps: TLuxUnixConsoleCaps;
  Session: TLuxUnixTerminalSession;
  Raised: Boolean;
begin
  LuxSection('Redirected stdout');
  Caps := TLuxUnixTerminalSession.Probe;
  if Caps.OutputIsTty and (not Caps.OutputRedirected) and Caps.AnsiLikelySupported then
  begin
    LuxCheck(True, 'stdout is a TTY; redirected Open failure skipped');
    Exit;
  end;

  Session := TLuxUnixTerminalSession.Create;
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

procedure TestTtyOpenRestore;
var
  Caps: TLuxUnixConsoleCaps;
  Session: TLuxUnixTerminalSession;
begin
  LuxSection('TTY open/restore');
  Caps := TLuxUnixTerminalSession.Probe;
  if (not Caps.OutputIsTty) or Caps.OutputRedirected or (not Caps.AnsiLikelySupported) then
  begin
    LuxCheck(True, 'TTY open/restore skipped (no usable TTY)');
    Exit;
  end;

  Session := TLuxUnixTerminalSession.Create;
  try
    Session.Open;
    LuxCheck(Session.IsOpen, 'session open');
    LuxCheck(Session.Writer <> nil, 'writer available');
    LuxCheck(Session.Columns > 0, 'columns probed');
    Session.Close;
    Session.Close;
    LuxCheck(not Session.IsOpen, 'session closed idempotently');
  finally
    Session.Free;
  end;
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
  E: ELuxUnixTerminal;
begin
  LuxSection('Error formatting');
  E := ELuxUnixTerminal.CreateOp('UnitTestOp', ESysEBADF);
  try
    LuxCheck(Pos('UnitTestOp', E.Message) > 0, 'message has operation');
    LuxCheck(Pos(IntToStr(ESysEBADF), E.Message) > 0, 'message has errno');
    LuxCheck(E.ErrorCode = ESysEBADF, 'ErrorCode property');
  finally
    E.Free;
  end;
end;

begin
  WriteLn('LUX Unix platform tests');
  TestCreateDestroySafe;
  TestProbe;
  TestInvalidWriterFd;
  TestWriterFileUtf8;
  TestRedirectedOpenFails;
  TestTtyOpenRestore;
  TestSeparationMemoryRenderer;
  TestErrorMessageIncludesCode;
  Halt(LuxTestExitCode);
end.
