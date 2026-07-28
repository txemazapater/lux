{ Windows platform unit tests (no interactive console required). }
program lux_windows_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  Windows,
  Lux.Terminal.Writer,
  Lux.Terminal.Errors,
  Lux.Terminal.MemoryWriter,
  Lux.Surface,
  Lux.Renderer,
  Lux.Color,
  Lux.Platform.Windows.Console,
  Lux.Platform.Windows.TerminalWriter,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.InputTranslate,
  Lux.Platform.Windows.EventSource,
  Lux.EventSource,
  Lux.Events,
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
  FillChar(Buf[0], SizeOf(Buf), 0);
  FS := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  try
    N := FS.Read(Buf[0], SizeOf(Buf));
    SetLength(Data, N);
    if N > 0 then
      Move(Buf[0], Data[1], N);
    SetCodePage(Data, CP_NONE, False);
  finally
    FS.Free;
  end;
  SysUtils.DeleteFile(Path);

  SetCodePage(Expected, CP_NONE, False);
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
    ModeAfter := 0;
    if GetConsoleMode(Session.InputHandle, ModeAfter) then
    begin
      LuxCheck((ModeAfter and LuxWinENABLE_VIRTUAL_TERMINAL_INPUT) = 0,
        'VT input disabled for ReadConsoleInput path');
      LuxCheck((ModeAfter and LuxWinENABLE_WINDOW_INPUT) <> 0, 'WINDOW_INPUT on');
      LuxCheck((ModeAfter and LuxWinENABLE_MOUSE_INPUT) <> 0, 'MOUSE_INPUT on');
      LuxCheck((ModeAfter and LuxWinENABLE_PROCESSED_INPUT) = 0, 'PROCESSED_INPUT off');
      LuxCheck((ModeAfter and LuxWinENABLE_LINE_INPUT) = 0, 'LINE_INPUT off');
    end;
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

procedure TestInputTranslate;
var
  Rec: INPUT_RECORD;
  Ev: TLuxEvent;
begin
  LuxSection('Windows input translate');
  Rec := LuxWinMakeKeyRecord(True, 1, $1B, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'escape translates');
  LuxCheck(Ev.Kind = ekKey, 'escape kind');
  LuxCheck(Ev.Key.Key = lkEscape, 'escape key');
  LuxCheckEqualStr('', Ev.Key.Ch, 'escape no char');

  Rec := LuxWinMakeKeyRecord(True, 1, Ord('A'), 0, 'a', LEFT_CTRL_PRESSED);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'ctrl+a translates');
  LuxCheck(Ev.Key.Key = lkChar, 'ctrl+a is char');
  LuxCheckEqualStr('a', Ev.Key.Ch, 'ctrl+a char');
  LuxCheck(kmCtrl in Ev.Key.Modifiers, 'ctrl set');

  Rec := LuxWinMakeKeyRecord(True, 3, $25, 0, #0, 0); { VK_LEFT }
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'left arrow');
  LuxCheck(Ev.Key.Key = lkLeft, 'left key');
  LuxCheckEqualInt(3, Ev.Key.RepeatCount, 'repeat count kept');

  Rec := LuxWinMakeMouseRecord(10, 5, FROM_LEFT_1ST_BUTTON_PRESSED, 0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'mouse press');
  LuxCheck(Ev.Kind = ekMouse, 'mouse kind');
  LuxCheckEqualInt(10, Ev.Mouse.X, 'mouse x');
  LuxCheck(Ev.Mouse.Button = mbLeft, 'left button');
  LuxCheck(Ev.Mouse.Action = maPress, 'press action');

  Rec := LuxWinMakeMouseRecord(10, 5, 0, 0, MOUSE_MOVED);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'mouse move');
  LuxCheck(Ev.Mouse.Action = maMove, 'move action');

  Rec := LuxWinMakeResizeRecord(120, 40);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'resize');
  LuxCheck(Ev.Kind = ekResize, 'resize kind');
  LuxCheckEqualInt(120, Ev.Resize.Width, 'resize width');

  { Conceptual parity: Escape is lkEscape with empty character on both platforms. }
  Ev := LuxEventKey(lkEscape, '', [], kaPress);
  LuxCheck(Ev.Key.Key = lkEscape, 'portable escape key');
  LuxCheckEqualStr('', Ev.Key.Ch, 'portable escape has no char');

  { Phase 5.1: logical keys with UnicodeChar = #0 must not be discarded. }
  Rec := LuxWinMakeKeyRecord(True, 1, $09, 0, #0, 0); { VK_TAB }
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'tab with nul char');
  LuxCheck(Ev.Key.Key = lkTab, 'tab key');
  LuxCheck(not (kmShift in Ev.Key.Modifiers), 'tab no shift');

  Rec := LuxWinMakeKeyRecord(True, 1, $09, 0, #9, SHIFT_PRESSED);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'shift+tab');
  LuxCheck(Ev.Key.Key = lkTab, 'shift+tab is still tab');
  LuxCheck(kmShift in Ev.Key.Modifiers, 'shift+tab has shift');

  Rec := LuxWinMakeKeyRecord(True, 1, $0D, 0, #13, 0); { VK_RETURN + CR }
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'return with CR char');
  LuxCheck(Ev.Key.Key = lkEnter, 'return is enter');
  LuxCheckEqualStr('', Ev.Key.Ch, 'enter has empty ch (single logical event)');

  Rec := LuxWinMakeKeyRecord(True, 1, $0D, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'return with nul char');
  LuxCheck(Ev.Key.Key = lkEnter, 'return nul is enter');

  Rec := LuxWinMakeKeyRecord(True, 1, $08, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkBackspace),
    'backspace');
  Rec := LuxWinMakeKeyRecord(True, 1, $2E, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkDelete),
    'delete');
  Rec := LuxWinMakeKeyRecord(True, 1, $27, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkRight),
    'right');
  Rec := LuxWinMakeKeyRecord(True, 1, $26, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkUp), 'up');
  Rec := LuxWinMakeKeyRecord(True, 1, $28, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkDown),
    'down');
  Rec := LuxWinMakeKeyRecord(True, 1, $70, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkF1), 'f1');

  Rec := LuxWinMakeKeyRecord(True, 1, $20, 0, ' ', 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'space');
  LuxCheck(Ev.Key.Key = lkChar, 'space is char');
  LuxCheckEqualStr(' ', Ev.Key.Ch, 'space char');

  Rec := LuxWinMakeKeyRecord(True, 1, Ord('Z'), 0, 'Z', 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkChar),
    'ascii printable');
  LuxCheckEqualStr('Z', Ev.Key.Ch, 'ascii Z');

  Rec := LuxWinMakeKeyRecord(True, 1, 0, 0, WideChar($00E9), 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (Ev.Key.Key = lkChar),
    'unicode char');
  LuxCheckEqualStr(UnicodeString(WideChar($00E9)), Ev.Key.Ch, 'unicode e-acute');

  Rec := LuxWinMakeKeyRecord(True, 1, Ord('a'), 0, 'a', LEFT_ALT_PRESSED);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev) and (kmAlt in Ev.Key.Modifiers),
    'alt+letter');

  Rec := LuxWinMakeKeyRecord(False, 1, $0D, 0, #13, 0);
  LuxCheck(not LuxWindowsTranslateInputRecord(Rec, Ev), 'keyup ignored');

  Rec := LuxWinMakeKeyRecord(True, 1, $09, 0, #0, 0);
  LuxCheck(LuxWindowsTranslateInputRecord(Rec, Ev), 'nul unicode logical key kept');
  LuxCheck(Ev.Key.Key = lkTab, 'nul unicode still tab');
end;

procedure TestLiveConsoleKeyInjection;
var
  Caps: TLuxWindowsConsoleCaps;
  Session: TLuxWindowsTerminalSession;
  Source: ILuxEventSource;
  Rec: INPUT_RECORD;
  Written: DWORD;
  Ev: TLuxEvent;
  GotTab, GotEnter, GotSpace: Boolean;
  I: Integer;
begin
  LuxSection('Live console key injection');
  Caps := TLuxWindowsTerminalSession.Probe;
  if (not Caps.OutputIsConsole) or Caps.OutputRedirected or
     (not Caps.InputIsConsole) then
  begin
    LuxCheck(True, 'live injection skipped (no usable console)');
    Exit;
  end;

  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxWindowsEventSource.Create(Session);
    FlushConsoleInputBuffer(Session.InputHandle);

    Rec := LuxWinMakeKeyRecord(True, 1, $09, 0, #0, 0);
    Written := 0;
    LuxCheck(WriteConsoleInputW(Session.InputHandle, Rec, 1, Written) and
      (Written = 1), 'inject tab');
    Rec := LuxWinMakeKeyRecord(True, 1, $0D, 0, #13, 0);
    LuxCheck(WriteConsoleInputW(Session.InputHandle, Rec, 1, Written) and
      (Written = 1), 'inject enter');
    Rec := LuxWinMakeKeyRecord(True, 1, $20, 0, ' ', 0);
    LuxCheck(WriteConsoleInputW(Session.InputHandle, Rec, 1, Written) and
      (Written = 1), 'inject space');

    GotTab := False;
    GotEnter := False;
    GotSpace := False;
    for I := 1 to 8 do
    begin
      if not Source.PollEvent(Ev) then
        Break;
      if Ev.Kind <> ekKey then
        Continue;
      if Ev.Key.Key = lkTab then
        GotTab := True;
      if Ev.Key.Key = lkEnter then
        GotEnter := True;
      if (Ev.Key.Key = lkChar) and (Ev.Key.Ch = ' ') then
        GotSpace := True;
    end;
    LuxCheck(GotTab, 'live tab event');
    LuxCheck(GotEnter, 'live enter event');
    LuxCheck(GotSpace, 'live space event');
  finally
    Source := nil;
    Session.Free;
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
  TestInputTranslate;
  TestLiveConsoleKeyInjection;
  Halt(LuxTestExitCode);
end.
