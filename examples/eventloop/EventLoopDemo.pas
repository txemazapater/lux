{ Shared Phase 4 event-loop demo body (platform factory in program files). }
unit EventLoopDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Events,
  Lux.Application,
  Lux.Surface,
  Lux.Color,
  Lux.Cell;

type
  TEventLoopDemoApp = class(TLuxApplication)
  private
    FLastKind: string;
    FLastKey: string;
    FLastChar: UnicodeString;
    FLastMods: string;
    FLastMouse: string;
    FTimerCount: Integer;
    FTimerId: TLuxTimerId;
    function ModsToStr(const M: TLuxKeyModifiers): string;
    function KeyToStr(K: TLuxKey): string;
    function KindToStr(K: TLuxEventKind): string;
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure RenderContent(ASurface: TLuxSurface); override;
  public
    procedure AfterConstruction; override;
  end;

implementation

procedure TEventLoopDemoApp.AfterConstruction;
begin
  inherited AfterConstruction;
  FLastKind := '(none)';
  FLastKey := '-';
  FLastChar := '-';
  FLastMods := '-';
  FLastMouse := '-';
  FTimerCount := 0;
  FTimerId := ScheduleRepeating(500);
end;

function TEventLoopDemoApp.ModsToStr(const M: TLuxKeyModifiers): string;
begin
  Result := '';
  if kmShift in M then
    Result := Result + 'Shift ';
  if kmCtrl in M then
    Result := Result + 'Ctrl ';
  if kmAlt in M then
    Result := Result + 'Alt ';
  Result := Trim(Result);
  if Result = '' then
    Result := '(none)';
end;

function TEventLoopDemoApp.KeyToStr(K: TLuxKey): string;
begin
  case K of
    lkUnknown: Result := 'Unknown';
    lkChar: Result := 'Char';
    lkEscape: Result := 'Escape';
    lkEnter: Result := 'Enter';
    lkTab: Result := 'Tab';
    lkBackspace: Result := 'Backspace';
    lkInsert: Result := 'Insert';
    lkDelete: Result := 'Delete';
    lkHome: Result := 'Home';
    lkEnd: Result := 'End';
    lkPageUp: Result := 'PageUp';
    lkPageDown: Result := 'PageDown';
    lkLeft: Result := 'Left';
    lkRight: Result := 'Right';
    lkUp: Result := 'Up';
    lkDown: Result := 'Down';
    lkF1: Result := 'F1';
    lkF2: Result := 'F2';
    lkF3: Result := 'F3';
    lkF4: Result := 'F4';
    lkF5: Result := 'F5';
    lkF6: Result := 'F6';
    lkF7: Result := 'F7';
    lkF8: Result := 'F8';
    lkF9: Result := 'F9';
    lkF10: Result := 'F10';
    lkF11: Result := 'F11';
    lkF12: Result := 'F12';
  else
    Result := '?';
  end;
end;

function TEventLoopDemoApp.KindToStr(K: TLuxEventKind): string;
begin
  case K of
    ekNone: Result := 'None';
    ekKey: Result := 'Key';
    ekMouse: Result := 'Mouse';
    ekResize: Result := 'Resize';
    ekTimer: Result := 'Timer';
    ekQuit: Result := 'Quit';
    ekUnknown: Result := 'Unknown';
  else
    Result := '?';
  end;
end;

function TEventLoopDemoApp.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := True;
  FLastKind := KindToStr(Event.Kind);
  case Event.Kind of
    ekKey:
      begin
        FLastKey := KeyToStr(Event.Key.Key);
        if Event.Key.Ch <> '' then
          FLastChar := Event.Key.Ch
        else
          FLastChar := '(none)';
        FLastMods := ModsToStr(Event.Key.Modifiers);
        if (Event.Key.Key = lkEscape) or
           ((Event.Key.Key = lkChar) and (Event.Key.Ch = 'q')) then
          RequestQuit;
      end;
    ekMouse:
      FLastMouse := Format('(%d,%d) btn=%d act=%d wheel=%d horiz=%s mods=%s',
        [Event.Mouse.X, Event.Mouse.Y, Ord(Event.Mouse.Button),
         Ord(Event.Mouse.Action), Event.Mouse.WheelDelta,
         BoolToStr(Event.Mouse.WheelHorizontal, True),
         ModsToStr(Event.Mouse.Modifiers)]);
    ekResize:
      begin
        FLastKind := Format('Resize %dx%d', [Event.Resize.Width, Event.Resize.Height]);
      end;
    ekTimer:
      Inc(FTimerCount);
    ekQuit:
      RequestQuit;
  else
    Result := True;
  end;
end;

procedure TEventLoopDemoApp.RenderContent(ASurface: TLuxSurface);
var
  Fg, Bg: TLuxColor;
  Line: UnicodeString;
begin
  Fg := LuxColorRGB(220, 220, 220);
  Bg := LuxColorRGB(20, 24, 32);
  ASurface.Fill(LuxCellMake(' ', 1, Fg, Bg, []));
  ASurface.PutText(1, 0, 'LUX event loop demo — Esc or q to quit', Fg, Bg, [tsBold]);
  Line := 'Size: ' + UnicodeString(IntToStr(Width)) + 'x' + UnicodeString(IntToStr(Height));
  ASurface.PutText(1, 2, Line, Fg, Bg, []);
  ASurface.PutText(1, 3, 'Last event: ' + UnicodeString(FLastKind), Fg, Bg, []);
  ASurface.PutText(1, 4, 'Last key: ' + UnicodeString(FLastKey) +
    '  char: ' + FLastChar, Fg, Bg, []);
  ASurface.PutText(1, 5, 'Modifiers: ' + UnicodeString(FLastMods), Fg, Bg, []);
  ASurface.PutText(1, 6, 'Mouse: ' + UnicodeString(FLastMouse), Fg, Bg, []);
  ASurface.PutText(1, 8, 'Timer ticks: ' + UnicodeString(IntToStr(FTimerCount)), Fg, Bg, []);
  ASurface.PutText(1, 10, 'Loop blocks while idle; timers wake every 500ms.', Fg, Bg, []);
end;

end.
