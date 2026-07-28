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
  Lux.Platform.Unix.InputParser,
  Lux.Events,
  Lux.TestHarness;

function LuxTestBytes(const Hexish: RawByteString): RawByteString;
begin
  Result := Hexish;
  SetCodePage(RawByteString(Result), CP_NONE, False);
end;

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
  ReadFd: cint;
  N: TsSize;
  Buf: array[0..255] of Byte;
begin
  LuxSection('Writer file UTF-8');
  Path := GetTempDir + 'lux_unix_writer_utf8.txt';
  if FileExists(Path) then
    SysUtils.DeleteFile(Path);

  Fd := FpOpen(PChar(Path), O_WrOnly or O_Creat or O_Trunc, &644);
  LuxCheck(Fd >= 0, 'temp file created');
  Writer := TLuxUnixTerminalWriter.Create(Fd, True);
  try
  Expected := '';
  SetLength(Expected, 5);
  SetCodePage(Expected, CP_NONE, False);
  Expected[1] := #$41;
  Expected[2] := #$E4;
  Expected[3] := #$B8;
  Expected[4] := #$80;
  Expected[5] := #$5A;

  Writer.WriteText('A' + UnicodeString(WideChar($4E00)) + 'Z');
  Writer.Flush;
  finally
    Writer.Free;
  end;

  Data := '';
  FillChar(Buf[0], SizeOf(Buf), 0);
  ReadFd := FpOpen(PChar(Path), O_RdOnly);
  LuxCheck(ReadFd >= 0, 'temp file reopened');
  try
    N := FpRead(ReadFd, @Buf[0], SizeOf(Buf));
    LuxCheck(N >= 0, 'temp file read ok');
    SetLength(Data, N);
    if N > 0 then
      Move(Buf[0], Data[1], N);
    SetCodePage(Data, CP_NONE, False);
  finally
    FpClose(ReadFd);
  end;
  SysUtils.DeleteFile(Path);
  LuxCheckEqualInt(System.Length(Expected), System.Length(Data), 'utf8 byte length');
  LuxCheck(Data = Expected, 'file contains UTF-8 bytes');
  LuxCheck(LuxUTF8Bytes('A' + UnicodeString(WideChar($4E00)) + 'Z') = Expected,
    'LuxUTF8Bytes matches canonical CJK sequence');
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

procedure TestUnixInputParser;
var
  P: TLuxUnixInputParser;
  Ev: TLuxEvent;
  St: TLuxUnixParseStatus;
  Arrow: RawByteString;
  Utf8: RawByteString;
  Mouse: RawByteString;
begin
  LuxSection('Unix input parser');
  P := TLuxUnixInputParser.Create;
  try
    P.Feed(LuxTestBytes('a'));
    St := P.TryParse(Ev);
    LuxCheck(St = upsEvent, 'ascii event');
    LuxCheck(Ev.Key.Key = lkChar, 'ascii char key');
    LuxCheckEqualStr('a', Ev.Key.Ch, 'ascii char');

    Utf8 := LuxTestBytes(#$C3);
    P.Feed(Utf8);
    St := P.TryParse(Ev);
    LuxCheck(St = upsNone, 'incomplete utf8 waits');
    P.Feed(LuxTestBytes(#$A9));
    St := P.TryParse(Ev);
    LuxCheck(St = upsEvent, 'utf8 complete');
    LuxCheckEqualStr('é', Ev.Key.Ch, 'utf8 char');

    P.Feed(LuxTestBytes(#27));
    St := P.TryParse(Ev);
    LuxCheck(St = upsAmbiguousEsc, 'lone esc ambiguous');
    P.Feed(LuxTestBytes('['));
    St := P.TryParse(Ev);
    LuxCheck(St = upsNone, 'esc[ incomplete');
    P.Feed(LuxTestBytes('D'));
    St := P.TryParse(Ev);
    LuxCheck(St = upsEvent, 'arrow complete');
    LuxCheck(Ev.Key.Key = lkLeft, 'left arrow');

    Arrow := LuxTestBytes(#27'OA');
    P.Feed(Arrow);
    St := P.TryParse(Ev);
    LuxCheck((St = upsEvent) and (Ev.Key.Key = lkUp), 'ss3 up');

    P.Feed(LuxTestBytes(#27'[15~'));
    St := P.TryParse(Ev);
    LuxCheck((St = upsEvent) and (Ev.Key.Key = lkF5), 'f5');

    P.Feed(LuxTestBytes(#13));
    St := P.TryParse(Ev);
    LuxCheck((St = upsEvent) and (Ev.Key.Key = lkEnter), 'enter');

    P.Feed(LuxTestBytes(#27'b'));
    St := P.TryParse(Ev);
    LuxCheck((St = upsEvent) and (kmAlt in Ev.Key.Modifiers), 'alt+b');
    LuxCheckEqualStr('b', Ev.Key.Ch, 'alt+b char');

    P.Clear;
    P.Feed(LuxTestBytes(#27));
    St := P.TryParse(Ev);
    LuxCheck(St = upsAmbiguousEsc, 'esc alone');
    LuxCheck(P.ResolveAmbiguousEscape(Ev) and (Ev.Key.Key = lkEscape),
      'resolve escape');

    P.Feed(LuxTestBytes(#27'[999q'));
    St := P.TryParse(Ev);
    LuxCheck(St = upsEvent, 'unknown csi yields event');
    LuxCheck(Ev.Kind = ekUnknown, 'unknown kind');

    Mouse := LuxTestBytes(#27'[<0;5;8M');
    P.Feed(Mouse);
    St := P.TryParse(Ev);
    LuxCheck(St = upsEvent, 'sgr mouse');
    LuxCheck(Ev.Kind = ekMouse, 'mouse kind');
    LuxCheckEqualInt(4, Ev.Mouse.X, 'mouse x 0-based');
    LuxCheckEqualInt(7, Ev.Mouse.Y, 'mouse y 0-based');
    LuxCheck(Ev.Mouse.Button = mbLeft, 'mouse left');
    LuxCheck(Ev.Mouse.Action = maPress, 'mouse press');

    P.Feed(LuxTestBytes(#27'[<0;5;8m'));
    St := P.TryParse(Ev);
    LuxCheck((St = upsEvent) and (Ev.Mouse.Action = maRelease), 'mouse release');

    P.Feed(LuxTestBytes(#27'[<'));
    LuxCheck(P.TryParse(Ev) = upsNone, 'mouse incomplete');
    P.Feed(LuxTestBytes('64;2;3M'));
    St := P.TryParse(Ev);
    LuxCheck((St = upsEvent) and (Ev.Mouse.Action = maWheel), 'wheel');
  finally
    P.Free;
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
  TestUnixInputParser;
  Halt(LuxTestExitCode);
end.
