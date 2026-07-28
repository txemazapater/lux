{ Portable input and runtime event model. No platform APIs. }
unit Lux.Events;

{$mode objfpc}{$H+}

interface

type
  TLuxEventKind = (
    ekNone,
    ekKey,
    ekMouse,
    ekResize,
    ekTimer,
    ekQuit,
    ekUnknown
  );

  TLuxKey = (
    lkUnknown,
    lkChar,
    lkEscape,
    lkEnter,
    lkTab,
    lkBackspace,
    lkInsert,
    lkDelete,
    lkHome,
    lkEnd,
    lkPageUp,
    lkPageDown,
    lkLeft,
    lkRight,
    lkUp,
    lkDown,
    lkF1, lkF2, lkF3, lkF4, lkF5, lkF6,
    lkF7, lkF8, lkF9, lkF10, lkF11, lkF12
  );

  TLuxKeyModifier = (kmShift, kmCtrl, kmAlt);
  TLuxKeyModifiers = set of TLuxKeyModifier;

  TLuxKeyAction = (kaPress, kaRepeat, kaRelease);

  TLuxKeyEvent = record
    Key: TLuxKey;
    { Unicode character produced by the key, if any. Empty when Key is not lkChar
      and the platform did not supply a printable character. }
    Ch: UnicodeString;
    Modifiers: TLuxKeyModifiers;
    Action: TLuxKeyAction;
    { Platform repeat count. Unix sources normally set 1. Windows may pass the
      console repeat counter without expanding into multiple events. }
    RepeatCount: Integer;
  end;

  TLuxMouseButton = (
    mbNone,
    mbLeft,
    mbMiddle,
    mbRight,
    mbX1,
    mbX2
  );

  TLuxMouseAction = (
    maMove,
    maPress,
    maRelease,
    maWheel,
    maDoubleClick
  );

  TLuxMouseEvent = record
    X: Integer;
    Y: Integer;
    Button: TLuxMouseButton;
    Action: TLuxMouseAction;
    Modifiers: TLuxKeyModifiers;
    { Positive = up/away, negative = down/toward for vertical.
      Horizontal wheel uses WheelDelta with Button = mbNone and Action = maWheel;
      WheelHorizontal distinguishes axis. }
    WheelDelta: Integer;
    WheelHorizontal: Boolean;
  end;

  TLuxResizeEvent = record
    Width: Integer;
    Height: Integer;
  end;

  TLuxTimerId = Integer;

  TLuxTimerEvent = record
    TimerId: TLuxTimerId;
  end;

  TLuxEvent = record
    Kind: TLuxEventKind;
    Key: TLuxKeyEvent;
    Mouse: TLuxMouseEvent;
    Resize: TLuxResizeEvent;
    Timer: TLuxTimerEvent;
  end;

function LuxEventNone: TLuxEvent;
function LuxEventQuit: TLuxEvent;
function LuxEventKey(AKey: TLuxKey; const ACh: UnicodeString;
  AModifiers: TLuxKeyModifiers; AAction: TLuxKeyAction;
  ARepeatCount: Integer = 1): TLuxEvent;
function LuxEventMouse(AX, AY: Integer; AButton: TLuxMouseButton;
  AAction: TLuxMouseAction; AModifiers: TLuxKeyModifiers;
  AWheelDelta: Integer = 0; AWheelHorizontal: Boolean = False): TLuxEvent;
function LuxEventResize(AWidth, AHeight: Integer): TLuxEvent;
function LuxEventTimer(ATimerId: TLuxTimerId): TLuxEvent;
function LuxEventUnknown: TLuxEvent;

implementation

procedure LuxZeroKey(var K: TLuxKeyEvent);
begin
  K.Key := lkUnknown;
  K.Ch := '';
  K.Modifiers := [];
  K.Action := kaPress;
  K.RepeatCount := 0;
end;

procedure LuxZeroMouse(var M: TLuxMouseEvent);
begin
  M.X := 0;
  M.Y := 0;
  M.Button := mbNone;
  M.Action := maMove;
  M.Modifiers := [];
  M.WheelDelta := 0;
  M.WheelHorizontal := False;
end;

function LuxClearEvent: TLuxEvent;
begin
  { Do not FillChar records that contain managed types (UnicodeString). }
  Result.Kind := ekNone;
  LuxZeroKey(Result.Key);
  LuxZeroMouse(Result.Mouse);
  Result.Resize.Width := 0;
  Result.Resize.Height := 0;
  Result.Timer.TimerId := 0;
end;

function LuxEventNone: TLuxEvent;
begin
  Result := LuxClearEvent;
  Result.Kind := ekNone;
end;

function LuxEventQuit: TLuxEvent;
begin
  Result := LuxClearEvent;
  Result.Kind := ekQuit;
end;

function LuxEventKey(AKey: TLuxKey; const ACh: UnicodeString;
  AModifiers: TLuxKeyModifiers; AAction: TLuxKeyAction;
  ARepeatCount: Integer): TLuxEvent;
begin
  Result := LuxClearEvent;
  Result.Kind := ekKey;
  Result.Key.Key := AKey;
  Result.Key.Ch := ACh;
  Result.Key.Modifiers := AModifiers;
  Result.Key.Action := AAction;
  if ARepeatCount < 1 then
    Result.Key.RepeatCount := 1
  else
    Result.Key.RepeatCount := ARepeatCount;
end;

function LuxEventMouse(AX, AY: Integer; AButton: TLuxMouseButton;
  AAction: TLuxMouseAction; AModifiers: TLuxKeyModifiers;
  AWheelDelta: Integer; AWheelHorizontal: Boolean): TLuxEvent;
begin
  Result := LuxClearEvent;
  Result.Kind := ekMouse;
  Result.Mouse.X := AX;
  Result.Mouse.Y := AY;
  Result.Mouse.Button := AButton;
  Result.Mouse.Action := AAction;
  Result.Mouse.Modifiers := AModifiers;
  Result.Mouse.WheelDelta := AWheelDelta;
  Result.Mouse.WheelHorizontal := AWheelHorizontal;
end;

function LuxEventResize(AWidth, AHeight: Integer): TLuxEvent;
begin
  Result := LuxClearEvent;
  Result.Kind := ekResize;
  Result.Resize.Width := AWidth;
  Result.Resize.Height := AHeight;
end;

function LuxEventTimer(ATimerId: TLuxTimerId): TLuxEvent;
begin
  Result := LuxClearEvent;
  Result.Kind := ekTimer;
  Result.Timer.TimerId := ATimerId;
end;

function LuxEventUnknown: TLuxEvent;
begin
  Result := LuxClearEvent;
  Result.Kind := ekUnknown;
end;

end.
