{ Portable LUX unit tests. No console / platform APIs. }
program lux_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Core,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Surface,
  Lux.Terminal.Writer,
  Lux.Terminal.Ansi,
  Lux.Terminal.MemoryWriter,
  Lux.Renderer,
  Lux.Events,
  Lux.EventQueue,
  Lux.Timers,
  Lux.TestHarness;

type
  TFakeClock = class(TInterfacedObject, ILuxClock)
  public
    NowValue: TLuxTimeMs;
    function NowMs: TLuxTimeMs;
  end;

function TFakeClock.NowMs: TLuxTimeMs;
begin
  Result := NowValue;
end;

procedure TestVersion;
begin
  LuxSection('Lux.Core');
  LuxCheckEqualStr('0.1.0-prealpha', LuxVersion, 'LuxVersion');
end;

procedure TestGeometry;
var
  R, A, B, I: TLuxRect;
begin
  LuxSection('Lux.Geometry');
  LuxCheck(LuxPointEqual(LuxPoint(2, 3), LuxPoint(2, 3)), 'point equal');
  LuxCheck(not LuxPointEqual(LuxPoint(2, 3), LuxPoint(3, 2)), 'point unequal');
  LuxCheck(LuxSizeEqual(LuxSize(4, 5), LuxSize(4, 5)), 'size equal');
  R := LuxRect(1, 2, 3, 4);
  LuxCheckEqualInt(4, LuxRectRight(R), 'rect right');
  LuxCheckEqualInt(6, LuxRectBottom(R), 'rect bottom');
  LuxCheck(LuxRectContainsXY(R, 1, 2), 'contains top-left');
  LuxCheck(LuxRectContainsXY(R, 3, 5), 'contains bottom-right-inner');
  LuxCheck(not LuxRectContainsXY(R, 4, 2), 'excludes right edge');
  LuxCheck(LuxRectIsEmpty(LuxRect(0, 0, 0, 5)), 'empty width');
  A := LuxRect(0, 0, 10, 10);
  B := LuxRect(5, 5, 10, 10);
  I := LuxRectIntersect(A, B);
  LuxCheck(LuxRectEqual(I, LuxRect(5, 5, 5, 5)), 'intersection');
  LuxCheck(LuxRectEqual(LuxRectNormalize(LuxRect(5, 5, -3, -2)), LuxRect(2, 3, 3, 2)),
    'normalize');
end;

procedure TestColorAndCell;
var
  C1, C2, Cont: TLuxCell;
  Idx: Integer;
  CP: Cardinal;
begin
  LuxSection('Lux.Color / Lux.Cell');
  LuxCheck(LuxColorEqual(LuxColorDefault, LuxColorDefault), 'default colour');
  LuxCheck(LuxColorEqual(LuxColorInherit, LuxColorInherit), 'inherit colour');
  LuxCheck(LuxColorEqual(LuxColorRGB(1, 2, 3), LuxColorRGB(1, 2, 3)), 'rgb equal');
  LuxCheck(not LuxColorEqual(LuxColorRGB(1, 2, 3), LuxColorRGB(3, 2, 1)), 'rgb unequal');
  LuxCheck(not LuxColorEqual(LuxColorDefault, LuxColorInherit), 'kind mismatch');

  C1 := LuxCellEmpty;
  LuxCheckEqualInt(1, C1.Width, 'empty cell width');
  LuxCheckEqualStr(' ', C1.Text, 'empty cell text');
  Cont := LuxCellContinuation;
  LuxCheckEqualInt(0, Cont.Width, 'continuation width');
  C2 := LuxCellMake('A', 1, LuxColorRGB(255, 0, 0), LuxColorDefault, [tsBold]);
  LuxCheck(not LuxCellEqual(C1, C2), 'cells differ');
  LuxCheck(LuxCellEqual(C2, LuxCellMake('A', 1, LuxColorRGB(255, 0, 0),
    LuxColorDefault, [tsBold])), 'cells equal');

  LuxCheckEqualInt(1, LuxCodepointWidth(Ord('A')), 'narrow A');
  LuxCheckEqualInt(2, LuxCodepointWidth($4E00), 'wide CJK');
  LuxCheckEqualInt(2, LuxCodepointWidth($FF21), 'fullwidth A');
  LuxCheckEqualInt(0, LuxCodepointWidth($0301), 'combining acute');

  Idx := 1;
  LuxCheck(LuxNextCodepoint('Z', Idx, CP) and (CP = Ord('Z')) and (Idx = 2),
    'next codepoint BMP');
end;

procedure TestSurface;
var
  S, T: TLuxSurface;
  Cell: TLuxCell;
begin
  LuxSection('Lux.Surface');
  S := TLuxSurface.Create(5, 3);
  try
    LuxCheckEqualInt(5, S.Width, 'width');
    LuxCheckEqualInt(3, S.Height, 'height');
    LuxCheck(S.Contains(0, 0) and not S.Contains(5, 0), 'contains');
    LuxCheckEqualStr(' ', S.Cells[0, 0].Text, 'cleared to space');

    Cell := LuxCellMake('#', 1, LuxColorRGB(0, 255, 0), LuxColorDefault, [tsUnderline]);
    S.FillRect(LuxRect(1, 1, 2, 1), Cell);
    LuxCheckEqualStr('#', S.Cells[1, 1].Text, 'fill rect cell');
    LuxCheckEqualStr('#', S.Cells[2, 1].Text, 'fill rect second cell');
    LuxCheckEqualStr(' ', S.Cells[0, 1].Text, 'outside fill untouched');

    S.FillRect(LuxRect(-1, -1, 3, 3), LuxCellMake('X', 1, LuxColorDefault,
      LuxColorDefault, []));
    LuxCheckEqualStr('X', S.Cells[0, 0].Text, 'clipped fill writes visible part');
    LuxCheckEqualStr('X', S.Cells[1, 1].Text, 'clipped fill interior');
    LuxCheckEqualStr(' ', S.Cells[2, 2].Text, 'outside clipped fill untouched');

    S.Clear;
    S.PutText(1, 0, 'Hi', LuxColorRGB(255, 255, 255), LuxColorDefault, [tsBold]);
    LuxCheckEqualStr('H', S.Cells[1, 0].Text, 'puttext H');
    LuxCheckEqualStr('i', S.Cells[2, 0].Text, 'puttext i');
    LuxCheck(tsBold in S.Cells[1, 0].Style, 'puttext style');

    S.Clear;
    S.PutText(0, 1, WideChar($4E00));
    LuxCheckEqualInt(2, S.Cells[0, 1].Width, 'wide primary width');
    LuxCheckEqualInt(0, S.Cells[1, 1].Width, 'wide continuation width');
    LuxCheckEqualStr('', S.Cells[1, 1].Text, 'wide continuation text');

    S.Clear;
    S.PutText(4, 0, WideChar($4E00));
    LuxCheckEqualInt(1, S.Cells[4, 0].Width, 'truncated wide becomes narrow');
    LuxCheckEqualStr(' ', S.Cells[4, 0].Text, 'truncated wide replacement');

    S.PutCell(100, 100, LuxCellMake('!', 1, LuxColorDefault, LuxColorDefault, []));
    LuxCheck(True, 'oob putcell ignored');

    S.Resize(2, 2);
    LuxCheckEqualInt(2, S.Width, 'resized width');
    LuxCheckEqualInt(2, S.Height, 'resized height');

    T := TLuxSurface.Create(2, 2);
    try
      LuxCheck(S.EqualTo(T), 'equal cleared surfaces');
      T.PutText(0, 0, 'A');
      LuxCheck(not S.EqualTo(T), 'surfaces differ after edit');
      S.AssignCellsFrom(T);
      LuxCheck(S.EqualTo(T), 'assign cells from');
    finally
      T.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TestAnsiHelpers;
begin
  LuxSection('Lux.Terminal.Ansi');
  LuxCheckEqualRaw(#27'[2;3H', LuxAnsiCursorMoveTo(2, 3), 'cursor move');
  LuxCheckEqualRaw(#27'[0m', LuxAnsiResetAttributes, 'reset');
  LuxCheckEqualRaw(#27'[38;2;1;2;3m', LuxAnsiFgRGB(1, 2, 3), 'fg rgb');
  LuxCheckEqualRaw(#27'[48;2;4;5;6m', LuxAnsiBgRGB(4, 5, 6), 'bg rgb');
  LuxCheckEqualRaw(#27'[1m', LuxAnsiApplyStyle([tsBold]), 'bold style');
  LuxCheckEqualRaw(#27'[?25l', LuxAnsiHideCursor, 'hide cursor');
  LuxCheckEqualRaw(#27'[?25h', LuxAnsiShowCursor, 'show cursor');
  LuxCheckEqualRaw(#27'[2J', LuxAnsiClearScreen, 'clear screen');
end;

procedure TestMemoryWriter;
var
  W: TLuxMemoryTerminalWriter;
begin
  LuxSection('Lux.Terminal.MemoryWriter');
  W := TLuxMemoryTerminalWriter.Create;
  try
    W.WriteRaw('AB');
    W.WriteText('C');
    W.Flush;
    LuxCheckEqualRaw('ABC', W.Data, 'memory buffer');
    LuxCheckEqualInt(1, W.FlushCount, 'flush count');
    LuxCheckEqualInt(1, W.CountRaw('B'), 'count raw');
    W.Clear;
    LuxCheckEqualInt(0, W.Length, 'cleared length');
  finally
    W.Free;
  end;
end;

procedure TestRenderer;
var
  WriterObj: TLuxMemoryTerminalWriter;
  Writer: ILuxTerminalWriter;
  Renderer: TLuxRenderer;
  Surface: TLuxSurface;
  FirstLen: Integer;
  FgRed: RawByteString;
begin
  LuxSection('Lux.Renderer');

  WriterObj := TLuxMemoryTerminalWriter.Create;
  Writer := WriterObj;
  Renderer := TLuxRenderer.Create(Writer);
  Surface := TLuxSurface.Create(4, 2);
  try
    FgRed := LuxAnsiFgRGB(255, 0, 0);

    Surface.PutText(0, 0, 'Hi');
    Renderer.Render(Surface);
    FirstLen := WriterObj.Length;
    LuxCheck(FirstLen > 0, 'initial frame emits output');
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiClearScreen), 'initial clears screen');
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiHideCursor), 'initial hides cursor');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('H')), 'initial contains H');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('i')), 'initial contains i');
    LuxCheckEqualInt(1, WriterObj.FlushCount, 'initial flush');

    WriterObj.Clear;
    Renderer.Render(Surface);
    LuxCheckEqualInt(0, WriterObj.Length, 'unchanged frame emits empty output');
    LuxCheckEqualInt(1, WriterObj.FlushCount, 'unchanged still flushes');

    WriterObj.Clear;
    Surface.PutText(2, 0, 'X');
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('X')), 'single cell emits X');
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen), 'single cell no clear');
    LuxCheckEqualInt(1, WriterObj.CountRaw(LuxAnsiCursorMoveTo(1, 3)),
      'single cell one cursor move');

    WriterObj.Clear;
    Surface.PutText(0, 1, 'AB');
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('AB')), 'contiguous run AB');
    LuxCheckEqualInt(1, WriterObj.CountRaw(LuxAnsiCursorMoveTo(2, 1)),
      'contiguous one cursor move');

    WriterObj.Clear;
    Surface.PutText(0, 0, 'Q');
    Surface.PutText(3, 1, 'Z');
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('Q')), 'separated Q');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('Z')), 'separated Z');
    LuxCheckEqualInt(1, WriterObj.CountRaw(LuxAnsiCursorMoveTo(1, 1)), 'move to Q');
    LuxCheckEqualInt(1, WriterObj.CountRaw(LuxAnsiCursorMoveTo(2, 4)), 'move to Z');

    WriterObj.Clear;
    Surface.PutText(0, 0, 'R', LuxColorRGB(255, 0, 0), LuxColorDefault, []);
    Renderer.Render(Surface);
    LuxCheckEqualInt(1, WriterObj.CountRaw(FgRed), 'colour emitted once');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('R')), 'coloured glyph');

    { Fresh contiguous dirty run with same colour after clearing glyphs. }
    WriterObj.Clear;
    Surface.PutText(0, 0, 'AB', LuxColorDefault, LuxColorDefault, []);
    Renderer.Render(Surface);
    Surface.PutText(0, 0, 'RS', LuxColorRGB(255, 0, 0), LuxColorDefault, []);
    WriterObj.Clear;
    Renderer.Render(Surface);
    LuxCheckEqualInt(1, WriterObj.CountRaw(FgRed), 'no redundant fg in run');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('RS')), 'red run glyphs');

    WriterObj.Clear;
    Surface.PutText(0, 0, 'B', LuxColorDefault, LuxColorDefault, [tsBold]);
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiApplyStyle([tsBold])), 'bold style emitted');
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiResetAttributes), 'style uses reset');

    WriterObj.Clear;
    Surface.Clear;
    Renderer.Invalidate;
    Surface.PutText(0, 0, UnicodeString(WideChar($4E00)));
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes(UnicodeString(WideChar($4E00)))),
      'wide glyph utf8');
    LuxCheckEqualInt(1, WriterObj.CountRaw(LuxUTF8Bytes(UnicodeString(WideChar($4E00)))),
      'wide glyph emitted once');

    WriterObj.Clear;
    Surface.Resize(5, 2);
    Surface.PutText(0, 0, 'N');
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiClearScreen), 'resize clears screen');

    WriterObj.Clear;
    Surface.PutText(1, 0, 'M');
    Renderer.Invalidate;
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiClearScreen), 'invalidate clears screen');
  finally
    Surface.Free;
    Renderer.Free;
    Writer := nil;
  end;

  { Fresh renderer: sequential glyphs after home need no extra cursor moves. }
  WriterObj := TLuxMemoryTerminalWriter.Create;
  Writer := WriterObj;
  Renderer := TLuxRenderer.Create(Writer);
  Surface := TLuxSurface.Create(3, 1);
  try
    Surface.PutText(0, 0, 'ABC');
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiCursorHome), 'full paint homes cursor');
    LuxCheckEqualInt(0, WriterObj.CountRaw(LuxAnsiCursorMoveTo(1, 2)),
      'no move before B');
    LuxCheckEqualInt(0, WriterObj.CountRaw(LuxAnsiCursorMoveTo(1, 3)),
      'no move before C');
    LuxCheckEqualInt(1, WriterObj.CountRaw(LuxAnsiResetAttributes),
      'single reset on full paint');
  finally
    Surface.Free;
    Renderer.Free;
    Writer := nil;
  end;
end;

procedure TestEventsAndQueue;
var
  Q: TLuxEventQueue;
  E: TLuxEvent;
begin
  LuxSection('Lux.Events / Lux.EventQueue');
  E := LuxEventKey(lkEscape, '', [], kaPress);
  LuxCheck(E.Kind = ekKey, 'key kind');
  LuxCheck(E.Key.Key = lkEscape, 'escape key');
  LuxCheckEqualStr('', E.Key.Ch, 'escape has no char');
  E := LuxEventKey(lkChar, UnicodeString(WideChar($00E9)), [kmAlt], kaPress);
  LuxCheckEqualStr(UnicodeString(WideChar($00E9)), E.Key.Ch, 'unicode char preserved');
  LuxCheck(kmAlt in E.Key.Modifiers, 'alt modifier');
  E := LuxEventMouse(3, 4, mbLeft, maPress, [kmCtrl], 0, False);
  LuxCheckEqualInt(3, E.Mouse.X, 'mouse x');
  LuxCheck(E.Mouse.Button = mbLeft, 'mouse button');
  E := LuxEventResize(100, 40);
  LuxCheckEqualInt(100, E.Resize.Width, 'resize w');
  E := LuxEventTimer(7);
  LuxCheckEqualInt(7, E.Timer.TimerId, 'timer id');
  LuxCheck(LuxEventQuit.Kind = ekQuit, 'quit');

  Q := TLuxEventQueue.Create;
  try
    LuxCheck(Q.IsEmpty, 'queue empty');
    Q.Push(LuxEventQuit);
    Q.Push(LuxEventTimer(1));
    LuxCheckEqualInt(2, Q.Count, 'queue count');
    LuxCheck(Q.TryPop(E) and (E.Kind = ekQuit), 'fifo quit first');
    LuxCheck(Q.TryPop(E) and (E.Kind = ekTimer), 'fifo timer second');
    LuxCheck(not Q.TryPop(E), 'queue drained');
  finally
    Q.Free;
  end;
end;

procedure TestTimers;
var
  Clock: TFakeClock;
  ClockIf: ILuxClock;
  Sched: TLuxTimerScheduler;
  Q: TLuxEventQueue;
  E: TLuxEvent;
  Id1, Id2: TLuxTimerId;
begin
  LuxSection('Lux.Timers');
  Clock := TFakeClock.Create;
  Clock.NowValue := 1000;
  ClockIf := Clock;
  Sched := TLuxTimerScheduler.Create(ClockIf);
  Q := TLuxEventQueue.Create;
  try
    Id1 := Sched.ScheduleOnce(100);
    Id2 := Sched.ScheduleRepeating(50);
    LuxCheckEqualInt(50, Integer(Sched.NextDelayMs), 'next delay is soonest timer');
    Clock.NowValue := 1100;
    Sched.CollectDueToQueue(Q);
    LuxCheck(Q.TryPop(E) and (E.Kind = ekTimer) and (E.Timer.TimerId = Id1),
      'one-shot fired');
    LuxCheck(Q.TryPop(E) and (E.Timer.TimerId = Id2), 'repeat fired at 1100');
    LuxCheck(Q.IsEmpty, 'no extras');
    Clock.NowValue := 1150;
    Sched.CollectDueToQueue(Q);
    LuxCheck(Q.TryPop(E) and (E.Timer.TimerId = Id2), 'repeat fired again');
    LuxCheck(Sched.Cancel(Id2), 'cancel repeat');
    Clock.NowValue := 1300;
    Sched.CollectDueToQueue(Q);
    LuxCheck(Q.IsEmpty, 'cancelled timer silent');
  finally
    Q.Free;
    Sched.Free;
    ClockIf := nil;
  end;
end;

begin
  WriteLn('LUX portable tests');
  TestVersion;
  TestGeometry;
  TestColorAndCell;
  TestSurface;
  TestAnsiHelpers;
  TestMemoryWriter;
  TestRenderer;
  TestEventsAndQueue;
  TestTimers;
  Halt(LuxTestExitCode);
end.
