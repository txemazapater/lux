{ Translate Win32 console input records to portable TLuxEvent. No I/O. }
unit Lux.Platform.Windows.InputTranslate;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Windows,
  Lux.Events;

{ Maps a single INPUT_RECORD to zero or one portable event.
  Returns False for records that should be ignored (e.g. key-up if undesired,
  focus events, menu events). Virtual-key codes never leave this unit. }
function LuxWindowsTranslateInputRecord(const Rec: INPUT_RECORD;
  out Event: TLuxEvent): Boolean;

{ Test helpers that build records in memory. }
function LuxWinMakeKeyRecord(ADown: Boolean; ARepeatCount: Word;
  AVirtKey: Word; AScan: Word; AChar: WideChar; ACtrlState: DWORD): INPUT_RECORD;
function LuxWinMakeMouseRecord(AX, AY: Integer; AButtonState, ACtrlState,
  AFlags: DWORD; AWheel: SHORT = 0): INPUT_RECORD;
function LuxWinMakeResizeRecord(AWidth, AHeight: Integer): INPUT_RECORD;

implementation

const
  LuxMOUSE_HWHEELED = $0008;
  LuxVK_BACK = $08;
  LuxVK_TAB = $09;
  LuxVK_RETURN = $0D;
  LuxVK_ESCAPE = $1B;
  LuxVK_SPACE = $20;
  LuxVK_PRIOR = $21;
  LuxVK_NEXT = $22;
  LuxVK_END = $23;
  LuxVK_HOME = $24;
  LuxVK_LEFT = $25;
  LuxVK_UP = $26;
  LuxVK_RIGHT = $27;
  LuxVK_DOWN = $28;
  LuxVK_INSERT = $2D;
  LuxVK_DELETE = $2E;
  LuxVK_F1 = $70;
  LuxVK_SHIFT = $10;
  LuxVK_CONTROL = $11;
  LuxVK_MENU = $12;
  { Avoid MOUSE_EVENT identifier: it collides with mouse_event() under FPC. }
  Lux_INPUT_KEY_EVENT = Word(1);
  Lux_INPUT_MOUSE_EVENT = Word(2);
  Lux_INPUT_WINDOW_BUFFER_SIZE_EVENT = Word(4);

function LuxWinMods(ACtrlState: DWORD): TLuxKeyModifiers;
begin
  Result := [];
  if (ACtrlState and SHIFT_PRESSED) <> 0 then
    Include(Result, kmShift);
  if (ACtrlState and (LEFT_CTRL_PRESSED or RIGHT_CTRL_PRESSED)) <> 0 then
    Include(Result, kmCtrl);
  if (ACtrlState and (LEFT_ALT_PRESSED or RIGHT_ALT_PRESSED)) <> 0 then
    Include(Result, kmAlt);
end;

function LuxWinKeyFromVk(AVirtKey: Word; AChar: WideChar;
  out Key: TLuxKey; out Ch: UnicodeString): Boolean;
begin
  { Resolve logical keys from wVirtualKeyCode first. Many non-printable keys
    arrive with UnicodeChar = #0 and must not be discarded. }
  Result := True;
  Ch := '';
  case AVirtKey of
    LuxVK_ESCAPE: Key := lkEscape;
    LuxVK_RETURN: Key := lkEnter;
    LuxVK_TAB: Key := lkTab;
    LuxVK_BACK: Key := lkBackspace;
    LuxVK_INSERT: Key := lkInsert;
    LuxVK_DELETE: Key := lkDelete;
    LuxVK_HOME: Key := lkHome;
    LuxVK_END: Key := lkEnd;
    LuxVK_PRIOR: Key := lkPageUp;
    LuxVK_NEXT: Key := lkPageDown;
    LuxVK_LEFT: Key := lkLeft;
    LuxVK_RIGHT: Key := lkRight;
    LuxVK_UP: Key := lkUp;
    LuxVK_DOWN: Key := lkDown;
    LuxVK_F1..LuxVK_F1 + 11: Key := TLuxKey(Ord(lkF1) + (AVirtKey - LuxVK_F1));
    LuxVK_SHIFT, LuxVK_CONTROL, LuxVK_MENU:
      Exit(False);
    LuxVK_SPACE:
      begin
        { Keep Space as printable character — buttons already activate on ' '. }
        Key := lkChar;
        if AChar <> #0 then
          Ch := UnicodeString(AChar)
        else
          Ch := ' ';
      end;
  else
    if AChar <> #0 then
    begin
      Key := lkChar;
      Ch := UnicodeString(AChar);
    end
    else
      Exit(False);
  end;
end;

function LuxWindowsTranslateKey(const Ke: KEY_EVENT_RECORD;
  out Event: TLuxEvent): Boolean;
var
  Key: TLuxKey;
  Ch: UnicodeString;
  Action: TLuxKeyAction;
  Mods: TLuxKeyModifiers;
  Rep: Integer;
begin
  Result := False;
  Event := LuxEventNone;

  { Phase 5 / 5.1 policy: emit LUX key events only for key-down.
    Key-up is ignored to avoid duplicate activations. }
  if not Ke.bKeyDown then
    Exit;

  if not LuxWinKeyFromVk(Ke.wVirtualKeyCode, Ke.UnicodeChar, Key, Ch) then
    Exit;

  Mods := LuxWinMods(Ke.dwControlKeyState);
  if Ke.wRepeatCount > 1 then
    Action := kaRepeat
  else
    Action := kaPress;

  Rep := Ke.wRepeatCount;
  if Rep < 1 then
    Rep := 1;

  Event := LuxEventKey(Key, Ch, Mods, Action, Rep);
  Result := True;
end;

function LuxWindowsTranslateMouse(const Me: MOUSE_EVENT_RECORD;
  out Event: TLuxEvent): Boolean;
var
  Mods: TLuxKeyModifiers;
  Button: TLuxMouseButton;
  Action: TLuxMouseAction;
  WheelDelta: Integer;
  WheelHoriz: Boolean;
  Flags: DWORD;
  Buttons: DWORD;
begin
  Result := False;
  Event := LuxEventNone;
  Mods := LuxWinMods(Me.dwControlKeyState);
  Flags := Me.dwEventFlags;
  Buttons := Me.dwButtonState;
  Button := mbNone;
  WheelDelta := 0;
  WheelHoriz := False;

  if (Flags and MOUSE_WHEELED) <> 0 then
  begin
    Action := maWheel;
    WheelDelta := SmallInt(HiWord(Buttons));
    if WheelDelta > 0 then
      WheelDelta := 1
    else if WheelDelta < 0 then
      WheelDelta := -1;
    Event := LuxEventMouse(Me.dwMousePosition.X, Me.dwMousePosition.Y,
      mbNone, Action, Mods, WheelDelta, False);
    Exit(True);
  end;

  if (Flags and LuxMOUSE_HWHEELED) <> 0 then
  begin
    Action := maWheel;
    WheelHoriz := True;
    WheelDelta := SmallInt(HiWord(Buttons));
    if WheelDelta > 0 then
      WheelDelta := 1
    else if WheelDelta < 0 then
      WheelDelta := -1;
    Event := LuxEventMouse(Me.dwMousePosition.X, Me.dwMousePosition.Y,
      mbNone, Action, Mods, WheelDelta, True);
    Exit(True);
  end;

  if (Flags and DOUBLE_CLICK) <> 0 then
    Action := maPress
  else if Flags = 0 then
  begin
    { Button press or release — infer from button state bits. }
    if Buttons = 0 then
      Action := maRelease
    else
      Action := maPress;
  end
  else if (Flags and MOUSE_MOVED) <> 0 then
    Action := maMove
  else
    Action := maPress;

  if (Buttons and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then
    Button := mbLeft
  else if (Buttons and FROM_LEFT_2ND_BUTTON_PRESSED) <> 0 then
    Button := mbMiddle
  else if (Buttons and RIGHTMOST_BUTTON_PRESSED) <> 0 then
    Button := mbRight;

  if (Action = maRelease) and (Button = mbNone) then
    Button := mbLeft; { release often reports zero buttons }

  Event := LuxEventMouse(Me.dwMousePosition.X, Me.dwMousePosition.Y,
    Button, Action, Mods, 0, WheelHoriz);
  Result := True;
end;

function LuxWindowsTranslateInputRecord(const Rec: INPUT_RECORD;
  out Event: TLuxEvent): Boolean;
begin
  Event := LuxEventNone;
  case Rec.EventType of
    Lux_INPUT_KEY_EVENT:
      Result := LuxWindowsTranslateKey(Rec.Event.KeyEvent, Event);
    Lux_INPUT_MOUSE_EVENT:
      Result := LuxWindowsTranslateMouse(Rec.Event.MouseEvent, Event);
    Lux_INPUT_WINDOW_BUFFER_SIZE_EVENT:
      begin
        Event := LuxEventResize(Rec.Event.WindowBufferSizeEvent.dwSize.X,
          Rec.Event.WindowBufferSizeEvent.dwSize.Y);
        Result := True;
      end;
  else
    Result := False;
  end;
end;

function LuxWinMakeKeyRecord(ADown: Boolean; ARepeatCount: Word;
  AVirtKey: Word; AScan: Word; AChar: WideChar; ACtrlState: DWORD): INPUT_RECORD;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.EventType := Lux_INPUT_KEY_EVENT;
  Result.Event.KeyEvent.bKeyDown := ADown;
  Result.Event.KeyEvent.wRepeatCount := ARepeatCount;
  Result.Event.KeyEvent.wVirtualKeyCode := AVirtKey;
  Result.Event.KeyEvent.wVirtualScanCode := AScan;
  Result.Event.KeyEvent.UnicodeChar := AChar;
  Result.Event.KeyEvent.dwControlKeyState := ACtrlState;
end;

function LuxWinMakeMouseRecord(AX, AY: Integer; AButtonState, ACtrlState,
  AFlags: DWORD; AWheel: SHORT): INPUT_RECORD;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.EventType := Lux_INPUT_MOUSE_EVENT;
  Result.Event.MouseEvent.dwMousePosition.X := AX;
  Result.Event.MouseEvent.dwMousePosition.Y := AY;
  Result.Event.MouseEvent.dwButtonState := AButtonState;
  if AWheel <> 0 then
    Result.Event.MouseEvent.dwButtonState :=
      (Result.Event.MouseEvent.dwButtonState and $FFFF) or (DWORD(Word(AWheel)) shl 16);
  Result.Event.MouseEvent.dwControlKeyState := ACtrlState;
  Result.Event.MouseEvent.dwEventFlags := AFlags;
end;

function LuxWinMakeResizeRecord(AWidth, AHeight: Integer): INPUT_RECORD;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.EventType := Lux_INPUT_WINDOW_BUFFER_SIZE_EVENT;
  Result.Event.WindowBufferSizeEvent.dwSize.X := AWidth;
  Result.Event.WindowBufferSizeEvent.dwSize.Y := AHeight;
end;

end.
