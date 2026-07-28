{ Interactive Windows keyboard inspector for Phase 5.1 diagnosis. }
program input_inspector_windows;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Windows,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.InputTranslate,
  Lux.Terminal.Ansi,
  Lux.Events;

function VkName(AVk: Word): string;
begin
  case AVk of
    $08: Result := 'VK_BACK';
    $09: Result := 'VK_TAB';
    $0D: Result := 'VK_RETURN';
    $10: Result := 'VK_SHIFT';
    $11: Result := 'VK_CONTROL';
    $12: Result := 'VK_MENU';
    $1B: Result := 'VK_ESCAPE';
    $20: Result := 'VK_SPACE';
    $21: Result := 'VK_PRIOR';
    $22: Result := 'VK_NEXT';
    $23: Result := 'VK_END';
    $24: Result := 'VK_HOME';
    $25: Result := 'VK_LEFT';
    $26: Result := 'VK_UP';
    $27: Result := 'VK_RIGHT';
    $28: Result := 'VK_DOWN';
    $2D: Result := 'VK_INSERT';
    $2E: Result := 'VK_DELETE';
    $70..$7B: Result := 'VK_F' + IntToStr(AVk - $6F);
  else
    if (AVk >= Ord('0')) and (AVk <= Ord('9')) then
      Result := 'VK_' + Chr(AVk)
    else if (AVk >= Ord('A')) and (AVk <= Ord('Z')) then
      Result := 'VK_' + Chr(AVk)
    else
      Result := 'VK_?';
  end;
end;

function KeyName(K: TLuxKey): string;
begin
  case K of
    lkUnknown: Result := 'lkUnknown';
    lkChar: Result := 'lkChar';
    lkEscape: Result := 'lkEscape';
    lkEnter: Result := 'lkEnter';
    lkTab: Result := 'lkTab';
    lkBackspace: Result := 'lkBackspace';
    lkInsert: Result := 'lkInsert';
    lkDelete: Result := 'lkDelete';
    lkHome: Result := 'lkHome';
    lkEnd: Result := 'lkEnd';
    lkPageUp: Result := 'lkPageUp';
    lkPageDown: Result := 'lkPageDown';
    lkLeft: Result := 'lkLeft';
    lkRight: Result := 'lkRight';
    lkUp: Result := 'lkUp';
    lkDown: Result := 'lkDown';
    lkF1: Result := 'lkF1';
    lkF2: Result := 'lkF2';
    lkF3: Result := 'lkF3';
    lkF4: Result := 'lkF4';
    lkF5: Result := 'lkF5';
    lkF6: Result := 'lkF6';
    lkF7: Result := 'lkF7';
    lkF8: Result := 'lkF8';
    lkF9: Result := 'lkF9';
    lkF10: Result := 'lkF10';
    lkF11: Result := 'lkF11';
    lkF12: Result := 'lkF12';
  else
    Result := '?';
  end;
end;

function ModsStr(const M: TLuxKeyModifiers): string;
begin
  Result := '';
  if kmShift in M then Result := Result + 'Shift ';
  if kmCtrl in M then Result := Result + 'Ctrl ';
  if kmAlt in M then Result := Result + 'Alt ';
  Result := Trim(Result);
  if Result = '' then
    Result := '(none)';
end;

function ActionName(A: TLuxKeyAction): string;
begin
  case A of
    kaPress: Result := 'kaPress';
    kaRepeat: Result := 'kaRepeat';
    kaRelease: Result := 'kaRelease';
  else
    Result := '?';
  end;
end;

procedure DumpKeyRecord(const Ke: KEY_EVENT_RECORD);
var
  Ch: WideChar;
  ChDesc: string;
begin
  Ch := Ke.UnicodeChar;
  if Ch = #0 then
    ChDesc := '(nul)'
  else if Ord(Ch) < 32 then
    ChDesc := Format('ctrl/%d', [Ord(Ch)])
  else
    ChDesc := '''' + UnicodeString(Ch) + '''';

  WriteLn('--- KEY_EVENT_RECORD ---');
  WriteLn(Format('  bKeyDown          = %s', [BoolToStr(Ke.bKeyDown, True)]));
  WriteLn(Format('  wRepeatCount      = %d', [Ke.wRepeatCount]));
  WriteLn(Format('  wVirtualKeyCode   = %d (0x%0.2X) %s',
    [Ke.wVirtualKeyCode, Ke.wVirtualKeyCode, VkName(Ke.wVirtualKeyCode)]));
  WriteLn(Format('  wVirtualScanCode  = %d (0x%0.2X)',
    [Ke.wVirtualScanCode, Ke.wVirtualScanCode]));
  WriteLn(Format('  UnicodeChar       = %d (0x%0.4X) %s',
    [Ord(Ch), Ord(Ch), ChDesc]));
  WriteLn(Format('  dwControlKeyState = %d (0x%0.8X)',
    [Ke.dwControlKeyState, Ke.dwControlKeyState]));
end;

procedure DumpLuxEvent(Translated: Boolean; const Ev: TLuxEvent);
begin
  WriteLn('--- TLuxEvent ---');
  if not Translated then
  begin
    WriteLn('  (ignored / not translated)');
    Exit;
  end;
  WriteLn(Format('  Kind        = %d', [Ord(Ev.Kind)]));
  if Ev.Kind = ekKey then
  begin
    WriteLn(Format('  Key         = %s', [KeyName(Ev.Key.Key)]));
    if Ev.Key.Ch = '' then
      WriteLn('  Character   = (empty)')
    else
      WriteLn(Format('  Character   = "%s" (U+%0.4X)',
        [string(Ev.Key.Ch), Ord(Ev.Key.Ch[1])]));
    WriteLn(Format('  Modifiers   = %s', [ModsStr(Ev.Key.Modifiers)]));
    WriteLn(Format('  Action      = %s', [ActionName(Ev.Key.Action)]));
    WriteLn(Format('  RepeatCount = %d', [Ev.Key.RepeatCount]));
  end
  else
    WriteLn(Format('  (non-key kind %d)', [Ord(Ev.Kind)]));
end;

procedure ShowBanner(ASession: TLuxWindowsTerminalSession);
var
  Mode: DWORD;
begin
  WriteLn('LUX Windows input inspector');
  WriteLn('Press keys to inspect KEY_EVENT_RECORD -> TLuxEvent. Escape quits.');
  WriteLn;
  Mode := 0;
  if GetConsoleMode(ASession.InputHandle, Mode) then
  begin
    WriteLn(Format('Input mode = 0x%0.8X', [Mode]));
    WriteLn(Format('  PROCESSED_INPUT        = %s',
      [BoolToStr((Mode and $0001) <> 0, True)]));
    WriteLn(Format('  LINE_INPUT             = %s',
      [BoolToStr((Mode and $0002) <> 0, True)]));
    WriteLn(Format('  ECHO_INPUT             = %s',
      [BoolToStr((Mode and $0004) <> 0, True)]));
    WriteLn(Format('  WINDOW_INPUT           = %s',
      [BoolToStr((Mode and $0008) <> 0, True)]));
    WriteLn(Format('  MOUSE_INPUT            = %s',
      [BoolToStr((Mode and $0010) <> 0, True)]));
    WriteLn(Format('  QUICK_EDIT_MODE        = %s',
      [BoolToStr((Mode and $0040) <> 0, True)]));
    WriteLn(Format('  VIRTUAL_TERMINAL_INPUT = %s',
      [BoolToStr((Mode and $0200) <> 0, True)]));
  end;
  WriteLn;
end;

var
  Session: TLuxWindowsTerminalSession;
  Rec: INPUT_RECORD;
  ReadCount: DWORD;
  Ev: TLuxEvent;
  Ok: Boolean;
  Quit: Boolean;
begin
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    { Stay on the main buffer so WriteLn diagnostics remain readable. }
    Session.Writer.WriteRaw(LuxAnsiLeaveAltScreen);
    Session.Writer.WriteRaw(LuxAnsiShowCursor);
    Session.Writer.Flush;
    ShowBanner(Session);
    Quit := False;
    while not Quit do
    begin
      if not ReadConsoleInputW(Session.InputHandle, Rec, 1, ReadCount) then
        Break;
      if ReadCount = 0 then
        Continue;
      if Rec.EventType <> KEY_EVENT then
        Continue;
      DumpKeyRecord(Rec.Event.KeyEvent);
      Ok := LuxWindowsTranslateInputRecord(Rec, Ev);
      DumpLuxEvent(Ok, Ev);
      WriteLn;
      if Ok and (Ev.Kind = ekKey) and (Ev.Key.Key = lkEscape) and
        (Ev.Key.Action <> kaRelease) then
        Quit := True;
    end;
  finally
    Session.Free;
  end;
end.
