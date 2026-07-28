{ Interactive Windows input inspector (keyboard + mouse). }
program input_inspector_windows;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Windows,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.InputTranslate,
  Lux.Terminal.Ansi,
  Lux.Events;

const
  Lux_INPUT_KEY_EVENT = Word(1);
  Lux_INPUT_MOUSE_EVENT = Word(2);
  Lux_INPUT_WINDOW_BUFFER_SIZE_EVENT = Word(4);
  LuxMOUSE_HWHEELED = $0008;

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

function KeyActionName(A: TLuxKeyAction): string;
begin
  case A of
    kaPress: Result := 'kaPress';
    kaRepeat: Result := 'kaRepeat';
    kaRelease: Result := 'kaRelease';
  else
    Result := '?';
  end;
end;

function MouseActionName(A: TLuxMouseAction): string;
begin
  case A of
    maMove: Result := 'maMove';
    maPress: Result := 'maPress';
    maRelease: Result := 'maRelease';
    maWheel: Result := 'maWheel';
    maDoubleClick: Result := 'maDoubleClick';
  else
    Result := '?';
  end;
end;

function MouseButtonName(B: TLuxMouseButton): string;
begin
  case B of
    mbNone: Result := 'mbNone';
    mbLeft: Result := 'mbLeft';
    mbMiddle: Result := 'mbMiddle';
    mbRight: Result := 'mbRight';
    mbX1: Result := 'mbX1';
    mbX2: Result := 'mbX2';
  else
    Result := '?';
  end;
end;

function MouseFlagsStr(AFlags: DWORD): string;
begin
  Result := '';
  if AFlags = 0 then
    Exit('0 (button press/release)');
  if (AFlags and MOUSE_MOVED) <> 0 then
    Result := Result + 'MOVED ';
  if (AFlags and DOUBLE_CLICK) <> 0 then
    Result := Result + 'DOUBLE_CLICK ';
  if (AFlags and MOUSE_WHEELED) <> 0 then
    Result := Result + 'WHEELED ';
  if (AFlags and LuxMOUSE_HWHEELED) <> 0 then
    Result := Result + 'HWHEELED ';
  Result := Trim(Result) + Format(' (0x%0.8X)', [AFlags]);
end;

function ButtonStateStr(AButtons: DWORD): string;
begin
  Result := '';
  if (AButtons and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then
    Result := Result + 'LEFT ';
  if (AButtons and FROM_LEFT_2ND_BUTTON_PRESSED) <> 0 then
    Result := Result + 'MIDDLE ';
  if (AButtons and RIGHTMOST_BUTTON_PRESSED) <> 0 then
    Result := Result + 'RIGHT ';
  Result := Trim(Result);
  if Result = '' then
    Result := '(none)';
  Result := Result + Format(' raw=0x%0.8X', [AButtons]);
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
    ChDesc := '''' + string(UnicodeString(Ch)) + '''';

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

procedure DumpMouseRecord(const Me: MOUSE_EVENT_RECORD);
begin
  WriteLn('--- MOUSE_EVENT_RECORD ---');
  WriteLn(Format('  dwMousePosition   = (%d, %d)',
    [Me.dwMousePosition.X, Me.dwMousePosition.Y]));
  WriteLn(Format('  dwButtonState     = %s', [ButtonStateStr(Me.dwButtonState)]));
  WriteLn(Format('  dwControlKeyState = %d (0x%0.8X)',
    [Me.dwControlKeyState, Me.dwControlKeyState]));
  WriteLn(Format('  dwEventFlags      = %s', [MouseFlagsStr(Me.dwEventFlags)]));
end;

procedure DumpResizeRecord(const We: WINDOW_BUFFER_SIZE_RECORD);
begin
  WriteLn('--- WINDOW_BUFFER_SIZE_EVENT ---');
  WriteLn(Format('  dwSize = (%d x %d)', [We.dwSize.X, We.dwSize.Y]));
end;

procedure DumpLuxEvent(Translated: Boolean; const Ev: TLuxEvent);
begin
  WriteLn('--- TLuxEvent ---');
  if not Translated then
  begin
    WriteLn('  (ignored / not translated)');
    Exit;
  end;
  case Ev.Kind of
    ekKey:
      begin
        WriteLn('  Kind        = ekKey');
        WriteLn(Format('  Key         = %s', [KeyName(Ev.Key.Key)]));
        if Ev.Key.Ch = '' then
          WriteLn('  Character   = (empty)')
        else
          WriteLn(Format('  Character   = "%s" (U+%0.4X)',
            [string(Ev.Key.Ch), Ord(Ev.Key.Ch[1])]));
        WriteLn(Format('  Modifiers   = %s', [ModsStr(Ev.Key.Modifiers)]));
        WriteLn(Format('  Action      = %s', [KeyActionName(Ev.Key.Action)]));
        WriteLn(Format('  RepeatCount = %d', [Ev.Key.RepeatCount]));
      end;
    ekMouse:
      begin
        WriteLn('  Kind        = ekMouse');
        WriteLn(Format('  X,Y         = (%d, %d)', [Ev.Mouse.X, Ev.Mouse.Y]));
        WriteLn(Format('  Button      = %s', [MouseButtonName(Ev.Mouse.Button)]));
        WriteLn(Format('  Action      = %s', [MouseActionName(Ev.Mouse.Action)]));
        WriteLn(Format('  Modifiers   = %s', [ModsStr(Ev.Mouse.Modifiers)]));
        WriteLn(Format('  WheelDelta  = %d (horiz=%s)',
          [Ev.Mouse.WheelDelta, BoolToStr(Ev.Mouse.WheelHorizontal, True)]));
      end;
    ekResize:
      begin
        WriteLn('  Kind        = ekResize');
        WriteLn(Format('  Size        = %d x %d',
          [Ev.Resize.Width, Ev.Resize.Height]));
      end;
  else
    WriteLn(Format('  Kind        = %d', [Ord(Ev.Kind)]));
  end;
end;

procedure ShowBanner(ASession: TLuxWindowsTerminalSession);
var
  Mode: DWORD;
begin
  WriteLn('LUX Windows input inspector');
  WriteLn('Keys and mouse -> INPUT_RECORD -> TLuxEvent. Escape quits.');
  WriteLn('Tip: click inside the console window; Quick Edit is off.');
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
      ReadCount := 0;
      FillChar(Rec, SizeOf(Rec), 0);
      if not ReadConsoleInputW(Session.InputHandle, Rec, 1, ReadCount) then
        Break;
      if ReadCount = 0 then
        Continue;

      case Rec.EventType of
        Lux_INPUT_KEY_EVENT:
          DumpKeyRecord(Rec.Event.KeyEvent);
        Lux_INPUT_MOUSE_EVENT:
          DumpMouseRecord(Rec.Event.MouseEvent);
        Lux_INPUT_WINDOW_BUFFER_SIZE_EVENT:
          DumpResizeRecord(Rec.Event.WindowBufferSizeEvent);
      else
        WriteLn(Format('--- INPUT_RECORD EventType=%d (skipped dump) ---',
          [Rec.EventType]));
      end;

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
