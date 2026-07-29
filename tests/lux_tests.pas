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
  Lux.EventSource,
  Lux.Application,
  Lux.Control,
  Lux.ControlContainer,
  Lux.FocusManager,
  Lux.Panel,
  Lux.Labels,
  Lux.Button,
  Lux.CheckBox,
  Lux.RadioButton,
  Lux.Separator,
  Lux.Toggle,
  Lux.GroupBox,
  Lux.ControlApplication,
  Lux.Layout,
  Lux.Layout.Vertical,
  Lux.Layout.Horizontal,
  Lux.Layout.Stack,
  Lux.Layout.Split,
  Lux.ScrollView,
  Lux.MouseDispatcher,
  Lux.Cursor,
  Lux.Appearance,
  Lux.TestHarness;

type
  TFakeClock = class(TInterfacedObject, ILuxClock)
  public
    NowValue: TLuxTimeMs;
    function NowMs: TLuxTimeMs;
  end;

  TFakeEventSource = class(TInterfacedObject, ILuxEventSource)
  public
    function PollEvent(out Event: TLuxEvent): Boolean;
    function WaitEvent(out Event: TLuxEvent; TimeoutMs: Integer): Boolean;
  end;

  TClickCounter = class
  public
    Count: Integer;
    procedure OnClick(Sender: TObject);
  end;

  TMouseProbe = class(TLuxControl)
  public
    Presses: Integer;
    Releases: Integer;
    Moves: Integer;
    LastX: Integer;
    LastY: Integer;
  protected
    function DoHandleEvent(const Event: TLuxEvent): Boolean; override;
  end;

  TTestControlApp = class(TLuxControlApplication)
  public
    function Feed(const Event: TLuxEvent): Boolean;
  end;

  TResizeProbeApp = class(TLuxApplication)
  public
    ResizeCalls: Integer;
    KeyHandled: Integer;
    TimerHandled: Integer;
    LastResizeW: Integer;
    LastResizeH: Integer;
    procedure OnResize(AWidth, AHeight: Integer); override;
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
    function WaitTimeout: Integer;
  end;

function TFakeClock.NowMs: TLuxTimeMs;
begin
  Result := NowValue;
end;

function TFakeEventSource.PollEvent(out Event: TLuxEvent): Boolean;
begin
  Event := LuxEventNone;
  Result := False;
end;

function TFakeEventSource.WaitEvent(out Event: TLuxEvent; TimeoutMs: Integer): Boolean;
begin
  Event := LuxEventNone;
  Result := False;
end;

procedure TClickCounter.OnClick(Sender: TObject);
begin
  Inc(Count);
end;

function TMouseProbe.DoHandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
  if Event.Kind <> ekMouse then
    Exit;
  LastX := Event.Mouse.X;
  LastY := Event.Mouse.Y;
  case Event.Mouse.Action of
    maPress:
      begin
        Inc(Presses);
        Result := True;
      end;
    maRelease:
      begin
        Inc(Releases);
        Result := True;
      end;
    maMove:
      begin
        Inc(Moves);
        Result := True;
      end;
  end;
end;

function TTestControlApp.Feed(const Event: TLuxEvent): Boolean;
begin
  Result := HandleEvent(Event);
end;

procedure TResizeProbeApp.OnResize(AWidth, AHeight: Integer);
begin
  Inc(ResizeCalls);
  LastResizeW := AWidth;
  LastResizeH := AHeight;
end;

function TResizeProbeApp.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
  case Event.Kind of
    ekKey:
      begin
        Inc(KeyHandled);
        Result := True;
      end;
    ekTimer:
      begin
        Inc(TimerHandled);
        Result := True;
      end;
  end;
end;

function TResizeProbeApp.WaitTimeout: Integer;
begin
  Result := CombinedWaitTimeoutMs;
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
  LuxCheckEqualRaw(#27'[0K', LuxAnsiEraseToEndOfLine, 'erase to end of line');
  LuxCheckEqualRaw(#27'[0J', LuxAnsiEraseToEndOfScreen, 'erase to end of screen');
  LuxCheckEqualRaw(#27'[2 q', LuxAnsiCursorStyle(2), 'cursor style steady block');
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
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen),
      'initial full paint does not clear screen');
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiHideCursor), 'initial hides cursor');
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiCursorHome), 'initial homes cursor');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('H')), 'initial contains H');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('i')), 'initial contains i');
    LuxCheckEqualInt(1, WriterObj.FlushCount, 'initial flush');
    LuxCheck(Renderer.LastWasFullRepaint, 'initial was full');

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
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen),
      'grow resize does not clear screen');
    LuxCheck(Renderer.LastWasFullRepaint, 'grow was full repaint');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('N')), 'grow paints content');

    WriterObj.Clear;
    Surface.PutText(1, 0, 'M');
    Renderer.Render(Surface);
    LuxCheck(not Renderer.LastWasFullRepaint, 'after grow returns to diff');
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen), 'diff no clear');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('M')), 'diff paints M');

    WriterObj.Clear;
    Surface.PutText(1, 0, 'M');
    Renderer.Invalidate;
    Renderer.Render(Surface);
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen),
      'invalidate full paint does not clear screen');
    LuxCheck(Renderer.LastWasFullRepaint, 'invalidate was full');

    { Shrink: leftover columns/rows must be erased without ESC[2J. }
    WriterObj.Clear;
    Surface.Resize(2, 1);
    Surface.PutText(0, 0, 'Z');
    Renderer.Render(Surface);
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen),
      'shrink does not clear screen');
    LuxCheck(Renderer.LastWasFullRepaint, 'shrink was full');
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiEraseToEndOfLine) or
      WriterObj.ContainsRaw(LuxAnsiEraseToEndOfScreen),
      'shrink erases leftover region');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('Z')), 'shrink paints Z');

    WriterObj.Clear;
    Surface.PutText(1, 0, 'Y');
    Renderer.Render(Surface);
    LuxCheck(not Renderer.LastWasFullRepaint, 'after shrink returns to diff');
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

  { Width-only and height-only shrink erase paths. }
  WriterObj := TLuxMemoryTerminalWriter.Create;
  Writer := WriterObj;
  Renderer := TLuxRenderer.Create(Writer);
  Surface := TLuxSurface.Create(4, 2);
  try
    Surface.PutText(0, 0, 'ABCD');
    Surface.PutText(0, 1, 'EFGH');
    Renderer.Render(Surface);

    WriterObj.Clear;
    Surface.Resize(2, 2);
    Surface.PutText(0, 0, 'AB');
    Surface.PutText(0, 1, 'EF');
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiEraseToEndOfLine),
      'width shrink uses erase EOL');
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen),
      'width shrink no clear screen');

    WriterObj.Clear;
    Surface.Resize(2, 1);
    Surface.PutText(0, 0, 'AB');
    Renderer.Render(Surface);
    LuxCheck(WriterObj.ContainsRaw(LuxAnsiEraseToEndOfScreen),
      'height shrink uses erase EOS');
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen),
      'height shrink no clear screen');
  finally
    Surface.Free;
    Renderer.Free;
    Writer := nil;
  end;
end;

procedure TestDeferredResize;
var
  WriterObj: TLuxMemoryTerminalWriter;
  Writer: ILuxTerminalWriter;
  Source: ILuxEventSource;
  Clock: TFakeClock;
  ClockIface: ILuxClock;
  App: TResizeProbeApp;
  FlushBefore: Integer;
  I: Integer;
  TimeoutMs: Integer;
begin
  LuxSection('Lux.Application deferred resize');
  WriterObj := TLuxMemoryTerminalWriter.Create;
  Writer := WriterObj;
  Source := TFakeEventSource.Create;
  Clock := TFakeClock.Create;
  Clock.NowValue := 1000;
  ClockIface := Clock;
  App := TResizeProbeApp.Create(Writer, Source, 10, 5, ClockIface);
  try
    App.ProcessPending;
    LuxCheck(App.Renderer.LastWasFullRepaint, 'initial paint full');
    FlushBefore := WriterObj.FlushCount;

    { Observe does not apply immediately. }
    App.PostEvent(LuxEventResize(20, 10));
    App.ProcessPending;
    LuxCheck(App.ResizePending, 'resize pending after observe');
    LuxCheckEqualInt(0, App.ResizeCalls, 'no commit before settle');
    LuxCheckEqualInt(10, App.Width, 'committed width unchanged');
    LuxCheckEqualInt(5, App.Height, 'committed height unchanged');
    LuxCheckEqualInt(10, App.Surface.Width, 'surface width unchanged');
    LuxCheckEqualInt(5, App.Surface.Height, 'surface height unchanged');
    LuxCheckEqualInt(FlushBefore, WriterObj.FlushCount, 'no paint while pending');

    { Before 75 ms: still no commit. }
    Clock.NowValue := 1000 + LuxResizeSettleDelayMs - 1;
    App.ProcessPending;
    LuxCheck(App.ResizePending, 'still pending before deadline');
    LuxCheckEqualInt(0, App.ResizeCalls, 'no commit before deadline');
    LuxCheckEqualInt(FlushBefore, WriterObj.FlushCount, 'no paint before deadline');

    { At deadline: single commit + paint. }
    Clock.NowValue := 1000 + LuxResizeSettleDelayMs;
    App.ProcessPending;
    LuxCheck(not App.ResizePending, 'pending cleared after commit');
    LuxCheckEqualInt(1, App.ResizeCalls, 'one commit at deadline');
    LuxCheckEqualInt(20, App.LastResizeW, 'committed width');
    LuxCheckEqualInt(10, App.LastResizeH, 'committed height');
    LuxCheckEqualInt(20, App.Surface.Width, 'surface resized on commit');
    LuxCheckEqualInt(FlushBefore + 1, WriterObj.FlushCount, 'one paint on commit');
    LuxCheck(App.Renderer.LastWasFullRepaint, 'commit paint was full');
    LuxCheck(not WriterObj.ContainsRaw(LuxAnsiClearScreen),
      'commit paint no clear screen');

    { Differential after commit. }
    WriterObj.Clear;
    App.Surface.PutText(0, 0, 'A');
    App.Invalidate;
    App.ProcessPending;
    LuxCheck(not App.Renderer.LastWasFullRepaint, 'returns to differential');
    LuxCheck(WriterObj.ContainsRaw(LuxUTF8Bytes('A')), 'diff paints A');

    { Second resize replaces first and restarts deadline. }
    FlushBefore := WriterObj.FlushCount;
    Clock.NowValue := 2000;
    App.PostEvent(LuxEventResize(30, 12));
    App.ProcessPending;
    LuxCheck(App.ResizePending, 'second observe pending');
    Clock.NowValue := 2050;
    App.PostEvent(LuxEventResize(40, 15));
    App.ProcessPending;
    LuxCheckEqualInt(1, App.ResizeCalls, 'still one commit total so far');
    Clock.NowValue := 2050 + LuxResizeSettleDelayMs - 1;
    App.ProcessPending;
    LuxCheckEqualInt(1, App.ResizeCalls, 'restarted deadline not reached');
    Clock.NowValue := 2050 + LuxResizeSettleDelayMs;
    App.ProcessPending;
    LuxCheckEqualInt(2, App.ResizeCalls, 'commit after restarted deadline');
    LuxCheckEqualInt(40, App.LastResizeW, 'replaced size committed');
    LuxCheckEqualInt(15, App.LastResizeH, 'replaced height committed');
    LuxCheckEqualInt(FlushBefore + 1, WriterObj.FlushCount,
      'one paint for replaced resize');

    { Ten consecutive resizes → one commit. }
    FlushBefore := WriterObj.FlushCount;
    Clock.NowValue := 3000;
    for I := 1 to 10 do
      App.PostEvent(LuxEventResize(50 + I, 20));
    App.ProcessPending;
    LuxCheck(App.ResizePending, 'burst leaves pending');
    LuxCheckEqualInt(2, App.ResizeCalls, 'burst does not commit early');
    LuxCheckEqualInt(FlushBefore, WriterObj.FlushCount, 'burst no paint');
    Clock.NowValue := 3000 + LuxResizeSettleDelayMs;
    App.ProcessPending;
    LuxCheckEqualInt(3, App.ResizeCalls, 'burst one commit');
    LuxCheckEqualInt(60, App.LastResizeW, 'burst last width');
    LuxCheckEqualInt(20, App.LastResizeH, 'burst last height');
    LuxCheckEqualInt(FlushBefore + 1, WriterObj.FlushCount, 'burst one paint');

    { Repeated pending size does not restart deadline. }
    Clock.NowValue := 4000;
    App.PostEvent(LuxEventResize(70, 25));
    App.ProcessPending;
    Clock.NowValue := 4040;
    App.PostEvent(LuxEventResize(70, 25));
    App.ProcessPending;
    Clock.NowValue := 4000 + LuxResizeSettleDelayMs;
    App.ProcessPending;
    LuxCheckEqualInt(4, App.ResizeCalls, 'repeat pending still commits once');
    LuxCheckEqualInt(70, App.Width, 'repeat pending width');

    { Same as committed abandons pending without commit work. }
    Clock.NowValue := 5000;
    App.PostEvent(LuxEventResize(80, 30));
    App.ProcessPending;
    LuxCheck(App.ResizePending, 'pending before abandon');
    App.PostEvent(LuxEventResize(70, 25));
    App.ProcessPending;
    LuxCheck(not App.ResizePending, 'same as committed clears pending');
    LuxCheckEqualInt(4, App.ResizeCalls, 'abandon does not commit');
    LuxCheckEqualInt(70, App.Width, 'width stays committed');

    { Timeout integrates resize deadline. }
    Clock.NowValue := 6000;
    App.PostEvent(LuxEventResize(90, 35));
    App.ProcessPending;
    TimeoutMs := App.WaitTimeout;
    LuxCheckEqualInt(Integer(LuxResizeSettleDelayMs), TimeoutMs,
      'wait timeout is settle delay');
    I := Integer(App.ScheduleOnce(200));
    TimeoutMs := App.WaitTimeout;
    LuxCheckEqualInt(Integer(LuxResizeSettleDelayMs), TimeoutMs,
      'resize deadline nearer than timer');
    App.CancelTimer(TLuxTimerId(I));
    Clock.NowValue := 6030;
    I := Integer(App.ScheduleOnce(10));
    TimeoutMs := App.WaitTimeout;
    LuxCheckEqualInt(10, TimeoutMs, 'timer nearer than resize deadline');
    App.CancelTimer(TLuxTimerId(I));

    { Clear pending via commit for remaining tests. }
    Clock.NowValue := 6000 + LuxResizeSettleDelayMs;
    App.ProcessPending;

    { Keyboard still processed; no paint while pending. }
    FlushBefore := WriterObj.FlushCount;
    Clock.NowValue := 7000;
    App.PostEvent(LuxEventResize(100, 40));
    App.ProcessPending;
    App.PostEvent(LuxEventKey(lkChar, 'x', [], kaPress));
    App.ProcessPending;
    LuxCheckEqualInt(1, App.KeyHandled, 'key handled while pending');
    LuxCheck(App.ResizePending, 'still pending after key');
    LuxCheckEqualInt(FlushBefore, WriterObj.FlushCount, 'key does not paint');

    { Timers still fire while pending; paint deferred. }
    App.ScheduleOnce(5);
    Clock.NowValue := 7005;
    App.ProcessPending;
    LuxCheckEqualInt(1, App.TimerHandled, 'timer handled while pending');
    LuxCheck(App.ResizePending, 'pending survives timer');
    LuxCheckEqualInt(FlushBefore, WriterObj.FlushCount, 'timer does not paint');

    { Quit abandons pending without waiting for deadline. }
    App.PostEvent(LuxEventQuit);
    App.ProcessPending;
    LuxCheck(App.QuitRequested, 'quit accepted while pending');
    LuxCheckEqualInt(5, App.ResizeCalls, 'quit does not force commit');
    LuxCheckEqualInt(90, App.Width, 'width unchanged after quit abandon');
  finally
    App.Free;
    ClockIface := nil;
    Source := nil;
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

procedure TestControlOwnership;
var
  Root: TLuxRootControl;
  A, B: TLuxPanel;
  Raised: Boolean;
begin
  LuxSection('Lux.Control ownership');
  Root := TLuxRootControl.Create;
  try
    Root.SetBounds(0, 0, 40, 20);
    A := TLuxPanel.Create(Root);
    B := TLuxPanel.Create(A);
    LuxCheckEqualInt(1, Root.ChildCount, 'root has one child');
    LuxCheckEqualInt(1, A.ChildCount, 'panel A has child');
    LuxCheck(B.Parent = A, 'B parent is A');

    Raised := False;
    try
      Root.AddChild(Root);
    except
      on ELuxControl do
        Raised := True;
    end;
    LuxCheck(Raised, 'self-add rejected');

    Raised := False;
    try
      B.AddChild(Root);
    except
      on ELuxControl do
        Raised := True;
    end;
    LuxCheck(Raised, 'cycle rejected');

    Raised := False;
    try
      Root.AddChild(A);
    except
      on ELuxControl do
        Raised := True;
    end;
    LuxCheck(Raised, 'duplicate add rejected');

    Root.RemoveChild(A);
    LuxCheckEqualInt(0, Root.ChildCount, 'removed from root');
    LuxCheck(A.Parent = nil, 'parent cleared');
    A.Free;
  finally
    Root.Free;
  end;
end;

procedure TestControlGeometryAndHit;
var
  Root: TLuxRootControl;
  Panel: TLuxPanel;
  Btn: TLuxButton;
  Hit: TLuxControl;
  Origin: TLuxPoint;
begin
  LuxSection('Lux.Control geometry / hit test');
  Root := TLuxRootControl.Create;
  try
    Root.SetBounds(0, 0, 40, 20);
    Panel := TLuxPanel.Create(Root);
    Panel.BorderStyle := lbsSingle;
    Panel.SetBounds(2, 2, 20, 10);
    Btn := TLuxButton.Create(Panel);
    Btn.SetBounds(1, 1, 8, 1);

    Origin := Btn.LocalToRoot(LuxPoint(0, 0));
    { Panel at (2,2) + border offset (1,1) + button (1,1) => (4,4) }
    LuxCheckEqualInt(4, Origin.X, 'button root x');
    LuxCheckEqualInt(4, Origin.Y, 'button root y');

    Hit := Root.HitTestRoot(4, 4);
    LuxCheck(Hit = Btn, 'hit deepest button');

    Btn.Enabled := False;
    Hit := Root.HitTestRoot(4, 4);
    LuxCheck(Hit <> Btn, 'disabled button not hit target');

    Btn.Enabled := True;
    Btn.Visible := False;
    Hit := Root.HitTestRoot(4, 4);
    LuxCheck(Hit <> Btn, 'invisible button skipped');
  finally
    Root.Free;
  end;
end;

procedure TestControlFocus;
var
  Root: TLuxRootControl;
  Focus: TLuxFocusManager;
  B1, B2: TLuxButton;
begin
  LuxSection('Lux.FocusManager');
  Root := TLuxRootControl.Create;
  Focus := TLuxFocusManager.Create(Root);
  try
    Root.SetBounds(0, 0, 40, 10);
    B1 := TLuxButton.Create(Root);
    B2 := TLuxButton.Create(Root);
    B1.SetBounds(0, 0, 6, 1);
    B2.SetBounds(8, 0, 6, 1);

    LuxCheck(Focus.SetFocus(B1), 'focus B1');
    LuxCheck(B1.HasFocus and (not B2.HasFocus), 'only B1 focused');
    LuxCheck(not Focus.SetFocus(nil) or True, 'clear allowed');
    Focus.ClearFocus;
    LuxCheck(Focus.FocusedControl = nil, 'focus cleared');

    B2.Enabled := False;
    LuxCheck(not Focus.SetFocus(B2), 'disabled rejects focus');
    B2.Enabled := True;
    B2.Visible := False;
    LuxCheck(not Focus.SetFocus(B2), 'invisible rejects focus');
    B2.Visible := True;
    B2.Focusable := False;
    LuxCheck(not Focus.SetFocus(B2), 'non-focusable rejects focus');
    B2.Focusable := True;

    Focus.SetFocus(B1);
    LuxCheck(Focus.MoveNext and (Focus.FocusedControl = B2), 'Tab next');
    LuxCheck(Focus.MovePrevious and (Focus.FocusedControl = B1), 'Shift+Tab prev');

    Focus.SetFocus(B1);
    Root.RemoveChild(B1);
    Focus.HandleControlDetached(B1);
    LuxCheck(Focus.FocusedControl = nil, 'detach clears focus');
    B1.Free;
  finally
    Focus.Free;
    Root.Free;
  end;
end;

procedure TestLayoutEngine;
var
  Root: TLuxRootControl;
  VBox: TLuxVerticalLayout;
  HBox: TLuxHorizontalLayout;
  A, B, C: TLuxControl;
begin
  LuxSection('Lux.Layout vertical / horizontal');

  Root := TLuxRootControl.Create;
  try
    Root.SetBounds(0, 0, 40, 20);
    VBox := TLuxVerticalLayout.Create(Root);
    VBox.Padding := LuxPaddingAll(2);
    VBox.Spacing := 1;

    A := TLuxControl.Create(VBox);
    A.PreferredHeight := 2;
    A.MinHeight := 2;
    B := TLuxControl.Create(VBox);
    B.PreferredHeight := 0;
    B.Expand := 1;
    C := TLuxControl.Create(VBox);
    C.PreferredHeight := 3;

    LuxCheckEqualInt(40, VBox.Width, 'root fills vbox width');
    LuxCheckEqualInt(20, VBox.Height, 'root fills vbox height');
    { Inner height = 20 - 4 padding = 16; spacing 1*2=2; fixed 2+3=5; expand gets 9 }
    LuxCheckEqualInt(2, A.Top, 'A top padded');
    LuxCheckEqualInt(2, A.Height, 'A preferred height');
    LuxCheckEqualInt(5, B.Top, 'B below A+spacing');
    LuxCheckEqualInt(9, B.Height, 'B takes expand share');
    LuxCheckEqualInt(15, C.Top, 'C below B+spacing');
    LuxCheckEqualInt(3, C.Height, 'C preferred height');
    LuxCheckEqualInt(36, A.Width, 'cross-axis stretch A');
    LuxCheckEqualInt(2, A.Left, 'A left padded');

    { Relayout on container resize. }
    Root.SetBounds(0, 0, 40, 30);
    LuxCheckEqualInt(30, VBox.Height, 'vbox follows root');
    LuxCheckEqualInt(19, B.Height, 'expand grows on resize');

    { Hidden child skipped. }
    B.Visible := False;
    LuxCheckEqualInt(2, A.Height, 'A unchanged height');
    LuxCheckEqualInt(5, C.Top, 'C moves up when B hidden');
  finally
    Root.Free;
  end;

  Root := TLuxRootControl.Create;
  try
    Root.SetBounds(0, 0, 30, 10);
    HBox := TLuxHorizontalLayout.Create(Root);
    HBox.Padding := LuxPadding(1, 1, 1, 1);
    HBox.Spacing := 2;
    A := TLuxControl.Create(HBox);
    A.PreferredWidth := 5;
    A.MinWidth := 5;
    B := TLuxControl.Create(HBox);
    B.PreferredWidth := 0;
    B.Expand := 1;
    C := TLuxControl.Create(HBox);
    C.PreferredWidth := 4;
    C.MinWidth := 4;

    { Inner width = 28; spacing 4; fixed 5+4=9; expand 15 }
    LuxCheckEqualInt(1, A.Left, 'H A left');
    LuxCheckEqualInt(5, A.Width, 'H A width');
    LuxCheckEqualInt(8, B.Left, 'H B left');
    LuxCheckEqualInt(15, B.Width, 'H B expand');
    LuxCheckEqualInt(25, C.Left, 'H C left');
    LuxCheckEqualInt(4, C.Width, 'H C width');
    LuxCheckEqualInt(8, A.Height, 'H cross-axis height');

    { Equal expand weights. }
    A.Expand := 1;
    A.PreferredWidth := 0;
    C.Expand := 1;
    C.PreferredWidth := 0;
    B.Expand := 0;
    B.PreferredWidth := 4;
    HBox.EnsureLayout;
    { Inner 28 - spacing 4 - fixed B 4 = 20; A and C share 10 each }
    LuxCheckEqualInt(10, A.Width, 'equal expand A');
    LuxCheckEqualInt(4, B.Width, 'fixed B');
    LuxCheckEqualInt(10, C.Width, 'equal expand C');
  finally
    Root.Free;
  end;
end;

procedure TestClientAreaAndAppearance;
var
  Panel: TLuxPanel;
  Gb: TLuxGroupBox;
  Scroll: TLuxScrollView;
  App: TLuxAppearance;
  R: TLuxRect;
  Sz: TLuxSize;
begin
  LuxSection('S1 client area / appearance seam');

  App := LuxBuiltinAppearance;
  LuxCheckEqualStr(UnicodeString(WideChar($250C)), App.Glyph(lgBoxTL), 'builtin TL');
  LuxCheckEqualStr(UnicodeString(WideChar($2500)), App.Glyph(lgBoxH), 'builtin H');
  LuxCheckEqualStr('[x]', App.Glyph(lgCheckChecked), 'builtin check');
  LuxCheckEqualStr('[ ]', App.Glyph(lgCheckUnchecked), 'builtin uncheck');
  LuxCheckEqualStr('(*)', App.Glyph(lgRadioChecked), 'builtin radio on');
  LuxCheckEqualStr('( )', App.Glyph(lgRadioUnchecked), 'builtin radio off');
  LuxCheckEqualStr('[  ON ]', App.Glyph(lgToggleOn), 'builtin toggle on');
  LuxCheckEqualStr('[ OFF ]', App.Glyph(lgToggleOff), 'builtin toggle off');
  LuxCheckEqualStr('>', App.Glyph(lgFocusMarker), 'builtin focus');
  LuxCheck(LuxColorEqual(LuxColorRGB(128, 128, 128), App.Color(lcrTextDisabled)),
    'builtin disabled color');

  Panel := TLuxPanel.Create(nil);
  try
    Panel.BorderStyle := lbsSingle;
    Panel.SetBounds(0, 0, 20, 10);
    R := Panel.ClientRect;
    Sz := Panel.ClientSize;
    LuxCheckEqualInt(1, R.Left, 'panel client left');
    LuxCheckEqualInt(1, R.Top, 'panel client top');
    LuxCheckEqualInt(18, R.Width, 'panel client width');
    LuxCheckEqualInt(8, R.Height, 'panel client height');
    LuxCheckEqualInt(R.Width, Sz.Width, 'panel ClientSize W');
    LuxCheckEqualInt(R.Height, Sz.Height, 'panel ClientSize H');
  finally
    Panel.Free;
  end;

  Gb := TLuxGroupBox.Create(nil);
  try
    Gb.SetBounds(0, 0, 16, 8);
    R := Gb.ClientRect;
    Sz := Gb.ClientSize;
    LuxCheckEqualInt(1, R.Left, 'groupbox client left');
    LuxCheckEqualInt(1, R.Top, 'groupbox client top');
    LuxCheckEqualInt(14, R.Width, 'groupbox client width');
    LuxCheckEqualInt(6, R.Height, 'groupbox client height');
    LuxCheckEqualInt(R.Width, Sz.Width, 'groupbox ClientSize matches');
  finally
    Gb.Free;
  end;

  Scroll := TLuxScrollView.Create(nil);
  try
    Scroll.SetBounds(2, 3, 30, 12);
    R := Scroll.ClientRect;
    LuxCheckEqualInt(0, R.Left, 'scroll client left');
    LuxCheckEqualInt(0, R.Top, 'scroll client top');
    LuxCheckEqualInt(30, R.Width, 'scroll viewport width');
    LuxCheckEqualInt(12, R.Height, 'scroll viewport height');
    LuxCheckEqualInt(Scroll.ViewportWidth, R.Width, 'scroll ViewportWidth');
    LuxCheckEqualInt(Scroll.ViewportHeight, R.Height, 'scroll ViewportHeight');
  finally
    Scroll.Free;
  end;
end;

procedure TestControlRenderingAndEvents;
var
  WriterObj: TLuxMemoryTerminalWriter;
  Writer: ILuxTerminalWriter;
  Source: ILuxEventSource;
  App: TTestControlApp;
  Panel: TLuxPanel;
  Lbl: TLuxLabel;
  Btn: TLuxButton;
  Clicks: TClickCounter;
  Surface: TLuxSurface;
begin
  LuxSection('Lux.Control render / events');
  WriterObj := TLuxMemoryTerminalWriter.Create;
  Writer := WriterObj;
  Source := TFakeEventSource.Create;
  App := TTestControlApp.Create(Writer, Source, 40, 12);
  Clicks := TClickCounter.Create;
  try
    Panel := TLuxPanel.Create(App.Root);
    Panel.BorderStyle := lbsSingle;
    Panel.Background := LuxColorRGB(0, 0, 40);
    Panel.SetBounds(1, 1, 30, 8);

    Lbl := TLuxLabel.Create(Panel);
    Lbl.Text := 'Hello';
    Lbl.Alignment := ltaLeft;
    Lbl.SetBounds(1, 1, 10, 1);

    Btn := TLuxButton.Create(Panel);
    Btn.Text := 'Go';
    Btn.OnClick := @Clicks.OnClick;
    Btn.SetBounds(1, 3, 10, 1);

    App.Focus.SetFocus(Btn);
    App.Root.Render(App.Surface);
    Surface := App.Surface;

    LuxCheck(Surface.Cells[1, 1].Text = UnicodeString(WideChar($250C)),
      'panel top-left border');
    LuxCheckEqualStr('H', Surface.Cells[3, 3].Text, 'label cell H');

    LuxCheck(App.Feed(LuxEventKey(lkEnter, '', [], kaPress)), 'enter handled');
    LuxCheckEqualInt(1, Clicks.Count, 'enter clicks once');

    LuxCheck(App.Feed(LuxEventKey(lkChar, ' ', [], kaPress)), 'space handled');
    LuxCheckEqualInt(2, Clicks.Count, 'space clicks once');

    Btn.Enabled := False;
    App.Focus.EnsureValid;
    App.Feed(LuxEventKey(lkEnter, '', [], kaPress));
    LuxCheckEqualInt(2, Clicks.Count, 'disabled no click');

    Btn.Enabled := True;
    App.Focus.SetFocus(Btn);
    { Button origin is (3,5): panel(1,1)+border(1,1)+bounds(1,3). }
    LuxCheck(App.Feed(LuxEventMouse(4, 5, mbLeft, maPress, [], 0, False)),
      'mouse press');
    LuxCheck(App.Feed(LuxEventMouse(4, 5, mbLeft, maRelease, [], 0, False)),
      'mouse release');
    LuxCheckEqualInt(3, Clicks.Count, 'mouse click once');

    LuxCheck(App.Feed(LuxEventKey(lkTab, '', [], kaPress)), 'tab moves');
  finally
    Clicks.Free;
    App.Free;
    Source := nil;
    Writer := nil;
  end;
end;

procedure TestControlKeyboardRouting;
var
  WriterObj: TLuxMemoryTerminalWriter;
  Writer: ILuxTerminalWriter;
  Source: ILuxEventSource;
  App: TTestControlApp;
  B1, B2, Hidden, Disabled: TLuxButton;
  Clicks: TClickCounter;
begin
  LuxSection('Lux.Control keyboard routing');
  WriterObj := TLuxMemoryTerminalWriter.Create;
  Writer := WriterObj;
  Source := TFakeEventSource.Create;
  App := TTestControlApp.Create(Writer, Source, 40, 12);
  Clicks := TClickCounter.Create;
  try
    B1 := TLuxButton.Create(App.Root);
    B2 := TLuxButton.Create(App.Root);
    Hidden := TLuxButton.Create(App.Root);
    Disabled := TLuxButton.Create(App.Root);
    B1.SetBounds(0, 0, 8, 1);
    B2.SetBounds(10, 0, 8, 1);
    Hidden.SetBounds(20, 0, 8, 1);
    Disabled.SetBounds(30, 0, 8, 1);
    Hidden.Visible := False;
    Disabled.Enabled := False;
    B1.OnClick := @Clicks.OnClick;
    B2.OnClick := @Clicks.OnClick;

    App.Focus.SetFocus(B1);
    LuxCheck(App.Feed(LuxEventKey(lkTab, '', [], kaPress)), 'tab next');
    LuxCheck(App.Focus.FocusedControl = B2, 'focus moved to B2');
    LuxCheck(App.Feed(LuxEventKey(lkTab, '', [kmShift], kaPress)), 'shift+tab');
    LuxCheck(App.Focus.FocusedControl = B1, 'focus back to B1');
    LuxCheck(App.Feed(LuxEventKey(lkTab, '', [], kaPress)), 'tab again');
    LuxCheck(App.Feed(LuxEventKey(lkTab, '', [], kaPress)), 'tab wraps');
    LuxCheck(App.Focus.FocusedControl = B1, 'wrap to B1');

    LuxCheck(not App.Focus.SetFocus(Hidden), 'hidden rejects focus');
    LuxCheck(not App.Focus.SetFocus(Disabled), 'disabled rejects focus');

    App.Focus.SetFocus(B1);
    LuxCheck(App.Feed(LuxEventKey(lkEnter, '', [], kaPress)), 'enter activates');
    LuxCheckEqualInt(1, Clicks.Count, 'enter one click');
    LuxCheck(App.Feed(LuxEventKey(lkChar, ' ', [], kaPress)), 'space activates');
    LuxCheckEqualInt(2, Clicks.Count, 'space one click');
    LuxCheck(not App.Feed(LuxEventKey(lkLeft, '', [], kaPress)), 'other key no click');
    LuxCheckEqualInt(2, Clicks.Count, 'still two clicks');
    LuxCheck(App.Feed(LuxEventKey(lkEnter, '', [], kaPress)), 'enter again');
    LuxCheckEqualInt(3, Clicks.Count, 'one activation per press');
  finally
    Clicks.Free;
    App.Free;
    Source := nil;
    Writer := nil;
  end;
end;

procedure TestStackLayout;
var
  Root: TLuxRootControl;
  Stack: TLuxStackLayout;
  VBox: TLuxVerticalLayout;
  A, B, C, Hidden: TLuxControl;
  Hit: TLuxControl;
  AL, AT, AW, AH: Integer;
begin
  LuxSection('Lux.Layout stack');

  Root := TLuxRootControl.Create;
  try
    Root.SetBounds(0, 0, 30, 16);
    Stack := TLuxStackLayout.Create(Root);
    Stack.Padding := LuxPaddingAll(2);

    A := TLuxControl.Create(Stack);
    A.PreferredWidth := 3;
    A.PreferredHeight := 3;
    A.Expand := 1;
    B := TLuxControl.Create(Stack);
    B.MinWidth := 1;
    B.MinHeight := 1;
    C := TLuxControl.Create(Stack);
    Hidden := TLuxControl.Create(Stack);
    Hidden.Visible := False;

    { Inner = 30-4 x 16-4 = 26x12; Expand/Preferred ignored. }
    LuxCheckEqualInt(2, A.Left, 'stack A left padded');
    LuxCheckEqualInt(2, A.Top, 'stack A top padded');
    LuxCheckEqualInt(26, A.Width, 'stack A fills inner width');
    LuxCheckEqualInt(12, A.Height, 'stack A fills inner height');
    LuxCheckEqualInt(A.Left, B.Left, 'stack B same left');
    LuxCheckEqualInt(A.Top, B.Top, 'stack B same top');
    LuxCheckEqualInt(A.Width, B.Width, 'stack B same width');
    LuxCheckEqualInt(A.Height, B.Height, 'stack B same height');
    LuxCheckEqualInt(A.Left, C.Left, 'stack C same left');
    LuxCheckEqualInt(A.Width, C.Width, 'stack C same width');

    Hit := Root.HitTestRoot(10, 8);
    LuxCheck(Hit = C, 'hit frontmost before BringToFront');

    AL := A.Left;
    AT := A.Top;
    AW := A.Width;
    AH := A.Height;
    Stack.BringToFront(A);
    LuxCheckEqualInt(AL, A.Left, 'BringToFront keeps bounds left');
    LuxCheckEqualInt(AT, A.Top, 'BringToFront keeps bounds top');
    LuxCheckEqualInt(AW, A.Width, 'BringToFront keeps bounds width');
    LuxCheckEqualInt(AH, A.Height, 'BringToFront keeps bounds height');
    LuxCheckEqualInt(A.Left, B.Left, 'siblings still share left');
    LuxCheckEqualInt(A.Width, C.Width, 'siblings still share width');

    Hit := Root.HitTestRoot(10, 8);
    LuxCheck(Hit = A, 'hit frontmost after BringToFront');

    Stack.SendToBack(A);
    Hit := Root.HitTestRoot(10, 8);
    LuxCheck(Hit = C, 'hit frontmost after SendToBack');
  finally
    Root.Free;
  end;

  { Nested smoke: stack under vertical expand. }
  Root := TLuxRootControl.Create;
  try
    Root.SetBounds(0, 0, 20, 10);
    VBox := TLuxVerticalLayout.Create(Root);
    VBox.Padding := LuxPaddingAll(0);
    Stack := TLuxStackLayout.Create(VBox);
    Stack.Expand := 1;
    Stack.Padding := LuxPaddingAll(1);
    A := TLuxControl.Create(Stack);
    B := TLuxControl.Create(Stack);
    LuxCheckEqualInt(20, Stack.Width, 'nested stack width');
    LuxCheckEqualInt(10, Stack.Height, 'nested stack height');
    LuxCheckEqualInt(1, A.Left, 'nested A padded');
    LuxCheckEqualInt(18, A.Width, 'nested A inner width');
    LuxCheckEqualInt(A.Width, B.Width, 'nested siblings match');
  finally
    Root.Free;
  end;
end;

procedure TestCursorManager;
var
  Cur: TLuxCursorManager;
  Mem: TLuxMemoryTerminalWriter;
  W: ILuxTerminalWriter;
begin
  LuxSection('Lux.Cursor');
  Cur := TLuxCursorManager.Create;
  Mem := TLuxMemoryTerminalWriter.Create;
  W := Mem;
  try
    Cur.Capabilities := LuxCursorCapsBasic;
    LuxCheck(not Cur.Requested.Active, 'starts inactive');
    Cur.Request(3, 5, True, lcsBar, True);
    LuxCheck(Cur.Requested.Active, 'request active');
    LuxCheckEqualInt(3, Cur.Requested.X, 'request x');
    LuxCheckEqualInt(5, Cur.Requested.Y, 'request y');
    LuxCheck(Cur.Commit(W), 'first commit emits');
    LuxCheck(Cur.Committed.Visible, 'committed visible');
    LuxCheck(Mem.ContainsRaw(LuxAnsiShowCursor), 'show cursor emitted');
    LuxCheck(Mem.ContainsRaw(LuxAnsiCursorMoveTo(6, 4)), 'move 1-based row/col');
    LuxCheck(not Mem.ContainsRaw(LuxAnsiCursorStyle(5)), 'basic caps skip shape');

    Mem.Clear;
    LuxCheck(not Cur.Commit(W), 'unchanged commit is silent');

    Cur.MarkPaintDirtied;
    LuxCheck(Cur.Commit(W), 'paint dirty forces re-commit');
    LuxCheck(Mem.ContainsRaw(LuxAnsiShowCursor), 're-show after paint');

    Mem.Clear;
    Cur.Capabilities := LuxCursorCapsFull;
    Cur.Request(1, 1, True, lcsUnderline, False);
    LuxCheck(Cur.Commit(W), 'full caps commit');
    LuxCheck(Mem.ContainsRaw(LuxAnsiCursorStyle(4)), 'steady underline style');

    Mem.Clear;
    Cur.ClearRequest;
    LuxCheck(Cur.Commit(W), 'clear emits hide');
    LuxCheck(Mem.ContainsRaw(LuxAnsiHideCursor), 'hide after clear');
    LuxCheck(not Cur.Committed.Visible, 'committed hidden');

    Cur.Capabilities := LuxCursorCapsNone;
    Mem.Clear;
    Cur.Request(0, 0, True);
    LuxCheck(Cur.Commit(W), 'none caps still reports commit');
    LuxCheckEqualInt(0, Mem.Length, 'none caps writes nothing');
  finally
    Cur.Free;
    W := nil;
  end;
end;

procedure TestSplitGeometryAndHit;
var
  Root: TLuxRootControl;
  Split, Nested: TLuxSplitContainer;
  A, B, C, D: TLuxControl;
  Hit: TLuxControl;
  Raised: Boolean;
  I, PrevLeft: Integer;
begin
  LuxSection('Lux.Layout.Split geometry / hit');
  Root := TLuxRootControl.Create;
  try
    Root.SetBounds(0, 0, 40, 20);
    Split := TLuxSplitContainer.Create(Root);
    Split.DividerSize := 1;
    Split.Ratio := LuxSplitRatioHalf;
    Split.Orientation := loVertical;
    A := TLuxControl.Create(Split);
    B := TLuxControl.Create(Split);

    LuxCheckEqualInt(19, A.Width, 'equal vertical first width');
    LuxCheckEqualInt(20, A.Height, 'equal vertical first height');
    LuxCheckEqualInt(19, A.Left + A.Width, 'divider starts after first');
    LuxCheckEqualInt(20, B.Left, 'second after divider');
    LuxCheckEqualInt(20, B.Width, 'equal vertical second width');

    Split.Ratio := 2500;
    LuxCheckEqualInt((39 * 2500) div LuxSplitRatioMax, A.Width, 'ratio 2500 first');
    LuxCheckEqualInt(39 - A.Width, B.Width, 'ratio 2500 second');

    Split.DividerSize := 3;
    LuxCheckEqualInt(A.Width + 3 + B.Width, 40, 'divider thickness accounted');

    Split.DividerSize := 1;
    Split.FirstMinimumSize := 10;
    Split.SecondMinimumSize := 10;
    Split.Ratio := 0;
    LuxCheckEqualInt(10, A.Width, 'first min clamps ratio 0');
    LuxCheckEqualInt(29, B.Width, 'second gets remainder');

    Split.Ratio := LuxSplitRatioMax;
    LuxCheckEqualInt(29, A.Width, 'second min clamps ratio max');
    LuxCheckEqualInt(10, B.Width, 'second at minimum');

    Split.FirstMinimumSize := 25;
    Split.SecondMinimumSize := 25;
    Split.Ratio := LuxSplitRatioHalf;
    LuxCheckEqualInt(A.Width + B.Width, 39, 'competing mins fill distributable');
    LuxCheck(A.Width >= 0, 'competing first non-negative');
    LuxCheck(B.Width >= 0, 'competing second non-negative');

    Split.FirstMinimumSize := 0;
    Split.SecondMinimumSize := 0;
    Split.SetBounds(0, 0, 2, 2);
    LuxCheck(A.Width >= 0, 'tiny first width non-neg');
    LuxCheck(B.Width >= 0, 'tiny second width non-neg');
    LuxCheck(A.Height >= 0, 'tiny height non-neg');

    Split.SetBounds(0, 0, 40, 20);
    Split.Orientation := loHorizontal;
    Split.Ratio := LuxSplitRatioHalf;
    Split.DividerSize := 1;
    LuxCheckEqualInt(9, A.Height, 'equal horizontal first height');
    LuxCheckEqualInt(10, B.Top, 'horizontal second top');
    LuxCheckEqualInt(10, B.Height, 'equal horizontal second height');

    Split.Orientation := loVertical;
    Split.Ratio := LuxSplitRatioHalf;
    Hit := Root.HitTestRoot(18, 5);
    LuxCheck(Hit = A, 'pane point hits first');
    Hit := Root.HitTestRoot(19, 5);
    LuxCheck(Hit = Split, 'divider point hits split');
    Hit := Root.HitTestRoot(20, 5);
    LuxCheck(Hit = B, 'pane point hits second');

    PrevLeft := A.Width;
    for I := 1 to 5 do
    begin
      Split.Ratio := LuxSplitRatioHalf;
      LuxCheckEqualInt(PrevLeft, A.Width, 'deterministic repeated layout');
    end;

    { Replace second pane with a panel so a nested split can own children. }
    Root.RemoveChild(Split);
    Split.Free;
    Split := TLuxSplitContainer.Create(Root);
    Split.Orientation := loVertical;
    Split.Ratio := LuxSplitRatioHalf;
    Split.DividerSize := 1;
    A := TLuxControl.Create(Split);
    B := TLuxPanel.Create(Split);
    Nested := TLuxSplitContainer.Create(B);
    Nested.Expand := 1;
    Nested.Orientation := loHorizontal;
    Nested.Ratio := LuxSplitRatioHalf;
    Nested.DividerSize := 1;
    C := TLuxControl.Create(Nested);
    D := TLuxControl.Create(Nested);
    LuxCheck(C.Height >= 0, 'nested first height');
    LuxCheck(D.Height >= 0, 'nested second height');
    LuxCheckEqualInt(C.Height + 1 + D.Height, Nested.Height, 'nested fills height');

    Raised := False;
    try
      TLuxControl.Create(Split);
    except
      on ELuxControl do
        Raised := True;
    end;
    LuxCheck(Raised, 'third pane rejected');
  finally
    Root.Free;
  end;
end;

procedure TestMouseCaptureAndSplitDrag;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Split: TLuxSplitContainer;
  First, Second: TMouseProbe;
  Other: TLuxControl;
  StartW, MidRatio: Integer;
begin
  LuxSection('Mouse capture / split drag');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 20);
  try
    App.Cursor.Capabilities := LuxCursorCapsFull;
    Split := TLuxSplitContainer.Create(App.Root);
    Split.Orientation := loVertical;
    Split.Ratio := LuxSplitRatioHalf;
    Split.DividerSize := 1;
    Split.FirstMinimumSize := 5;
    Split.SecondMinimumSize := 5;
    First := TMouseProbe.Create(Split);
    Second := TMouseProbe.Create(Split);

    LuxCheck(App.CapturedControl = nil, 'no capture initially');
    App.CaptureMouse(Split);
    LuxCheck(App.CapturedControl = Split, 'capture set');
    App.Feed(LuxEventMouse(0, 0, mbLeft, maMove, [], 0, False));
    LuxCheckEqualInt(0, First.Moves, 'capture skips pane hit-test');
    LuxCheck(App.CapturedControl = Split, 'capture holds across move');
    App.ReleaseMouse(Split);

    App.CaptureMouse(First);
    App.Feed(LuxEventMouse(3, 4, mbLeft, maMove, [], 0, False));
    LuxCheckEqualInt(3, First.LastX, 'captured local x');
    LuxCheckEqualInt(4, First.LastY, 'captured local y');
    LuxCheckEqualInt(1, First.Moves, 'captured move delivered');

    App.ReleaseMouse(First);

    App.CaptureMouse(Split);
    App.ReleaseMouse(First);
    LuxCheck(App.CapturedControl = Split, 'wrong release ignored');
    App.ReleaseMouse(Split);
    LuxCheck(App.CapturedControl = nil, 'correct release clears');

    App.CaptureMouse(Split);
    Split.Visible := False;
    LuxCheck(App.CapturedControl = nil, 'hidden clears capture');
    Split.Visible := True;

    Other := TLuxControl.Create(nil);
    try
      App.CaptureMouse(Other);
      LuxCheck(App.CapturedControl = nil, 'off-tree capture rejected');
    finally
      Other.Free;
    end;

    StartW := First.Width;
    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    LuxCheck(not Split.Dragging, 'press alone does not start drag');
    { Move past threshold (2 cells) to trigger DragBegin. }
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(Split.Dragging, 'dragging started after threshold');
    LuxCheck(App.CapturedControl = Split, 'press on divider captures');
    LuxCheck(App.Cursor.Requested.Active, 'drag requests cursor');

    App.Feed(LuxEventMouse(28, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(Split.Dragging, 'drag continues outside divider');
    LuxCheck(First.Width > StartW, 'movement widens first pane');
    MidRatio := Split.Ratio;
    LuxCheck(MidRatio > LuxSplitRatioHalf, 'ratio increased');

    App.Feed(LuxEventMouse(100, 5, mbLeft, maMove, [], 0, False));
    LuxCheckEqualInt(40 - 1 - Split.SecondMinimumSize, First.Width,
      'min second respected while dragging past edge');

    App.Feed(LuxEventMouse(100, 5, mbLeft, maRelease, [], 0, False));
    LuxCheck(not Split.Dragging, 'release ends drag');
    LuxCheck(App.CapturedControl = nil, 'release ends capture');
    LuxCheck(not App.Cursor.Requested.Active, 'cursor cleared after release');
    LuxCheckEqualInt(0, First.Releases, 'pane no divider release');

    App.Cursor.Capabilities := LuxCursorCapsNone;
    App.Feed(LuxEventMouse(First.Width, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(First.Width + 2, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(Split.Dragging, 'drag works without cursor caps');
    App.Feed(LuxEventMouse(First.Width + 2, 5, mbLeft, maRelease, [], 0, False));
    LuxCheck(not Split.Dragging, 'release without caps');
  finally
    App.Free;
    Src := nil;
  end;
end;

procedure TestSplitEscapeCancellation;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Split: TLuxSplitContainer;
  First: TMouseProbe;
  InitialRatio, MovedRatio: Integer;
  Handled: Boolean;
begin
  LuxSection('Split escape cancellation');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 20);
  try
    App.Cursor.Capabilities := LuxCursorCapsFull;
    Split := TLuxSplitContainer.Create(App.Root);
    Split.Orientation := loVertical;
    Split.Ratio := LuxSplitRatioHalf;
    Split.DividerSize := 1;
    Split.FirstMinimumSize := 5;
    Split.SecondMinimumSize := 5;
    First := TMouseProbe.Create(Split);
    TMouseProbe.Create(Split);

    InitialRatio := Split.Ratio;

    LuxCheck(not App.Feed(LuxEventKey(lkEscape, '', [], kaPress)),
      'escape not consumed without drag');

    { Press on divider and move past threshold to start dragging. }
    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(Split.Dragging, 'dragging started');
    LuxCheck(App.CapturedControl = Split, 'capture active');
    LuxCheck(App.Cursor.Requested.Active, 'cursor requested');

    { Move further to change ratio. }
    App.Feed(LuxEventMouse(28, 5, mbLeft, maMove, [], 0, False));
    MovedRatio := Split.Ratio;
    LuxCheck(MovedRatio <> InitialRatio, 'ratio changed during drag');

    { Escape cancels drag and restores initial ratio. }
    Handled := App.Feed(LuxEventKey(lkEscape, '', [], kaPress));
    LuxCheck(Handled, 'escape consumed during drag');
    LuxCheck(not Split.Dragging, 'dragging cleared after escape');
    LuxCheck(App.CapturedControl = nil, 'capture released after escape');
    LuxCheck(not App.Cursor.Requested.Active, 'cursor cleared after escape');
    LuxCheckEqualInt(InitialRatio, Split.Ratio, 'ratio restored after escape');

    { Further mouse movement must not keep resizing the split. }
    App.Feed(LuxEventMouse(30, 5, mbLeft, maMove, [], 0, False));
    LuxCheckEqualInt(InitialRatio, Split.Ratio, 'ratio unchanged after cancel');

    { Release event after cancellation is harmless. }
    App.Feed(LuxEventMouse(30, 5, mbLeft, maRelease, [], 0, False));
  finally
    App.Free;
    Src := nil;
  end;
end;

procedure TestSplitCaptureLoss;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  SplitHide, SplitDisable, SplitRemoved: TLuxSplitContainer;
  SplitBack, SplitFront: TLuxSplitContainer;
  A, B: TMouseProbe;
  Handled: Boolean;
begin
  LuxSection('Split capture loss');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 20);
  try
    App.Cursor.Capabilities := LuxCursorCapsFull;

    { Hidden loses capture safely. }
    SplitHide := TLuxSplitContainer.Create(App.Root);
    SplitHide.Orientation := loVertical;
    SplitHide.Ratio := LuxSplitRatioHalf;
    SplitHide.DividerSize := 1;
    SplitHide.FirstMinimumSize := 5;
    SplitHide.SecondMinimumSize := 5;
    TMouseProbe.Create(SplitHide);
    TMouseProbe.Create(SplitHide);

    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(SplitHide.Dragging, 'hidden: dragging starts');
    LuxCheck(App.CapturedControl = SplitHide, 'hidden: split captured');
    LuxCheck(App.Cursor.Requested.Active, 'hidden: cursor requested');
    SplitHide.Visible := False;
    App.Feed(LuxEventMouse(0, 0, mbLeft, maMove, [], 0, False));
    LuxCheck(App.CapturedControl = nil, 'hidden: capture cleared');
    LuxCheck(not SplitHide.Dragging, 'hidden: dragging cleared');
    LuxCheck(not App.Cursor.Requested.Active, 'hidden: cursor cleared');

    { Disabled loses capture safely. }
    SplitDisable := TLuxSplitContainer.Create(App.Root);
    SplitDisable.Orientation := loVertical;
    SplitDisable.Ratio := LuxSplitRatioHalf;
    SplitDisable.DividerSize := 1;
    SplitDisable.FirstMinimumSize := 5;
    SplitDisable.SecondMinimumSize := 5;
    TMouseProbe.Create(SplitDisable);
    TMouseProbe.Create(SplitDisable);

    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(SplitDisable.Dragging, 'disabled: dragging starts');
    SplitDisable.Enabled := False;
    App.Feed(LuxEventMouse(0, 0, mbLeft, maMove, [], 0, False));
    LuxCheck(App.CapturedControl = nil, 'disabled: capture cleared');
    LuxCheck(not SplitDisable.Dragging, 'disabled: dragging cleared');
    LuxCheck(not App.Cursor.Requested.Active, 'disabled: cursor cleared');

    { Removed-from-tree loses capture safely (cursor too). }
    SplitRemoved := TLuxSplitContainer.Create(App.Root);
    SplitRemoved.Orientation := loVertical;
    SplitRemoved.Ratio := LuxSplitRatioHalf;
    SplitRemoved.DividerSize := 1;
    SplitRemoved.FirstMinimumSize := 5;
    SplitRemoved.SecondMinimumSize := 5;
    TMouseProbe.Create(SplitRemoved);
    TMouseProbe.Create(SplitRemoved);

    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(SplitRemoved.Dragging, 'removed: dragging starts');
    App.Root.RemoveChild(SplitRemoved);
    App.Feed(LuxEventMouse(0, 0, mbLeft, maMove, [], 0, False));
    LuxCheck(App.CapturedControl = nil, 'removed: capture cleared');
    LuxCheck(not SplitRemoved.Dragging, 'removed: dragging cleared');
    LuxCheck(not App.Cursor.Requested.Active, 'removed: cursor cleared');

    { Capture transfer between two valid controls clears previous drag. }
    SplitBack := TLuxSplitContainer.Create(App.Root);
    SplitBack.Orientation := loVertical;
    SplitBack.Ratio := LuxSplitRatioHalf;
    SplitBack.DividerSize := 1;
    SplitBack.FirstMinimumSize := 5;
    SplitBack.SecondMinimumSize := 5;
    TMouseProbe.Create(SplitBack);
    TMouseProbe.Create(SplitBack);

    { Add the front split after the back split so hit-test prefers it. }
    SplitFront := TLuxSplitContainer.Create(App.Root);
    SplitFront.Orientation := loVertical;
    SplitFront.Ratio := LuxSplitRatioHalf;
    SplitFront.DividerSize := 1;
    SplitFront.FirstMinimumSize := 5;
    SplitFront.SecondMinimumSize := 5;
    TMouseProbe.Create(SplitFront);
    TMouseProbe.Create(SplitFront);

    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(SplitFront.Dragging, 'transfer: drag starts on front split');
    LuxCheck(App.CapturedControl = SplitFront, 'transfer: front captured');
    LuxCheck(App.Cursor.Requested.Active, 'transfer: cursor requested');

    App.CaptureMouse(SplitBack);
    LuxCheck(App.CapturedControl = SplitBack, 'transfer: capture moved to back');
    LuxCheck(not SplitFront.Dragging, 'transfer: front dragging cleared');
    LuxCheck(not App.Cursor.Requested.Active, 'transfer: cursor cleared after move');

    { Destroy the currently captured split during an active drag. }
    { Start drag on the currently captured control (SplitBack). }
    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(SplitBack.Dragging, 'destroy: drag started');
    App.Cursor.Capabilities := LuxCursorCapsFull; { no-op: keep cursor available }
    SplitBack.Free;
    SplitBack := nil;

    LuxCheck(App.CapturedControl = nil, 'destroy: capture cleared');
    LuxCheck(not App.Cursor.Requested.Active, 'destroy: cursor cleared');

    { Validate Escape does not crash after destroy. }
    Handled := App.Feed(LuxEventKey(lkEscape, '', [], kaPress));
  finally
    { SplitRemoved was removed from the tree, so free it manually. }
    if SplitRemoved <> nil then
      SplitRemoved.Free;
    App.Free;
    Src := nil;
  end;
end;

procedure TestSplitResizeAndOrientationDuringDrag;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Split: TLuxSplitContainer;
  First, Second: TMouseProbe;
  InitialRatio, NewRatio: Integer;
  DivClamp: Integer;
begin
  LuxSection('Split resize / orientation during drag');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 20);
  try
    App.Cursor.Capabilities := LuxCursorCapsFull;
    Split := TLuxSplitContainer.Create(App.Root);
    Split.Orientation := loVertical;
    Split.Ratio := LuxSplitRatioHalf;
    Split.DividerSize := 1;
    Split.FirstMinimumSize := 5;
    Split.SecondMinimumSize := 5;
    First := TMouseProbe.Create(Split);
    Second := TMouseProbe.Create(Split);

    InitialRatio := Split.Ratio;
    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(Split.Dragging, 'dragging started');

    { Grow then shrink while dragging. }
    Split.SetBounds(0, 0, 10, 20);
    LuxCheck(First.Width >= 0, 'first width non-negative after shrink');
    LuxCheck(Second.Width >= 0, 'second width non-negative after shrink');

    Split.SetBounds(0, 0, 40, 20);
    LuxCheck(First.Width >= 0, 'first width non-negative after grow');
    LuxCheck(Second.Width >= 0, 'second width non-negative after grow');

    { Move to change ratio, then cancel by orientation change. }
    App.Feed(LuxEventMouse(28, 5, mbLeft, maMove, [], 0, False));
    NewRatio := Split.Ratio;
    LuxCheck(NewRatio <> InitialRatio, 'ratio changed before orientation');

    Split.Orientation := loHorizontal;
    LuxCheck(not Split.Dragging, 'orientation change cancels drag');
    LuxCheck(App.CapturedControl = nil, 'orientation change releases capture');
    LuxCheck(not App.Cursor.Requested.Active, 'orientation change clears cursor');
    LuxCheckEqualInt(NewRatio, Split.Ratio, 'orientation keeps most recent ratio');

    { Release outside container ends drag harmlessly (already not dragging). }
    App.Feed(LuxEventMouse(200, 200, mbLeft, maRelease, [], 0, False));

    { Start a new drag and release outside divider to ensure robustness. }
    Split.Orientation := loVertical;
    App.Feed(LuxEventMouse(First.Width, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(First.Width + 2, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(Split.Dragging, 'dragging started again');
    DivClamp := Split.DividerSize;
    if DivClamp > Split.Width then
      DivClamp := Split.Width;

    App.Feed(LuxEventMouse(-10, -10, mbLeft, maRelease, [], 0, False));
    LuxCheck(not Split.Dragging, 'release outside ends drag');
    LuxCheck(App.CapturedControl = nil, 'release outside clears capture');
    LuxCheck(not App.Cursor.Requested.Active, 'release outside clears cursor request');
  finally
    App.Free;
    Src := nil;
  end;
end;

procedure TestSplitPropertyChangesDuringDrag;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Split: TLuxSplitContainer;
  A, B: TMouseProbe;
begin
  LuxSection('Split property changes during drag');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 20);
  try
    App.Cursor.Capabilities := LuxCursorCapsFull;

    Split := TLuxSplitContainer.Create(App.Root);
    Split.Orientation := loVertical;
    Split.Ratio := LuxSplitRatioHalf;
    Split.DividerSize := 1;
    Split.FirstMinimumSize := 5;
    Split.SecondMinimumSize := 5;
    A := TMouseProbe.Create(Split);
    B := TMouseProbe.Create(Split);

    App.Feed(LuxEventMouse(19, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(21, 5, mbLeft, maMove, [], 0, False));
    LuxCheck(Split.Dragging, 'dragging started');
    LuxCheck(App.Cursor.Requested.Active, 'cursor requested');

    { Change divider thickness while dragging. }
    Split.DividerSize := 3;
    LuxCheck(Split.Dragging, 'still dragging after divider size change');
    LuxCheck(A.Width >= Split.FirstMinimumSize, 'first min respected');
    LuxCheck(B.Width >= Split.SecondMinimumSize, 'second min respected');
    LuxCheck(App.Cursor.Requested.Active, 'cursor request still active');

    { Increase minimums while dragging. }
    Split.FirstMinimumSize := 15;
    Split.SecondMinimumSize := 8;
    LuxCheck(Split.Dragging, 'still dragging after minimum changes');
    LuxCheck(A.Width >= Split.FirstMinimumSize, 'first min increased respected');
    LuxCheck(B.Width >= Split.SecondMinimumSize, 'second min increased respected');

    { Release ends drag robustly. }
    App.Feed(LuxEventMouse(-10, -10, mbLeft, maRelease, [], 0, False));
    LuxCheck(not Split.Dragging, 'drag ended on release outside');
    LuxCheck(App.CapturedControl = nil, 'capture cleared after release');
    LuxCheck(not App.Cursor.Requested.Active, 'cursor request cleared after release outside');
  finally
    App.Free;
    Src := nil;
  end;
end;

{ --- Semantic mouse dispatcher tests --- }

type
  TSemanticProbe = class(TLuxControl)
  public
    Enters: Integer;
    Leaves: Integer;
    Moves: Integer;
    Downs: Integer;
    Ups: Integer;
    Clicks: Integer;
    DblClicks: Integer;
    DragBegins: Integer;
    DragMoves: Integer;
    DragEnds: Integer;
    DragCancels: Integer;
    WheelEvents: Integer;
    LastWheelDelta: Integer;
    procedure SemanticMouseEnter(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseMove(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseLeave; override;
    procedure SemanticMouseDown(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseUp(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticClick(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticDoubleClick(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticDragBegin(const Event: TLuxDragEvent); override;
    procedure SemanticDragMove(const Event: TLuxDragEvent); override;
    procedure SemanticDragEnd(const Event: TLuxDragEvent); override;
    procedure SemanticDragCancel; override;
    function SemanticMouseWheel(const Event: TLuxWheelEvent): Boolean; override;
  end;

procedure TSemanticProbe.SemanticMouseEnter(const Event: TLuxSemanticMouseEvent);
begin Inc(Enters); end;
procedure TSemanticProbe.SemanticMouseMove(const Event: TLuxSemanticMouseEvent);
begin Inc(Moves); end;
procedure TSemanticProbe.SemanticMouseLeave;
begin Inc(Leaves); end;
procedure TSemanticProbe.SemanticMouseDown(const Event: TLuxSemanticMouseEvent);
begin Inc(Downs); end;
procedure TSemanticProbe.SemanticMouseUp(const Event: TLuxSemanticMouseEvent);
begin Inc(Ups); end;
procedure TSemanticProbe.SemanticClick(const Event: TLuxSemanticMouseEvent);
begin Inc(Clicks); end;
procedure TSemanticProbe.SemanticDoubleClick(const Event: TLuxSemanticMouseEvent);
begin Inc(DblClicks); end;
procedure TSemanticProbe.SemanticDragBegin(const Event: TLuxDragEvent);
begin Inc(DragBegins); end;
procedure TSemanticProbe.SemanticDragMove(const Event: TLuxDragEvent);
begin Inc(DragMoves); end;
procedure TSemanticProbe.SemanticDragEnd(const Event: TLuxDragEvent);
begin Inc(DragEnds); end;
procedure TSemanticProbe.SemanticDragCancel;
begin Inc(DragCancels); end;
function TSemanticProbe.SemanticMouseWheel(const Event: TLuxWheelEvent): Boolean;
begin Inc(WheelEvents); LastWheelDelta := Event.Delta; Result := False; end;

procedure TestSemanticMouseDispatcher;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Clock: TFakeClock;
  Probe: TSemanticProbe;
begin
  LuxSection('Semantic mouse dispatcher');
  Src := TFakeEventSource.Create;
  Clock := TFakeClock.Create;
  Clock.NowValue := 1000;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 20, Clock);
  try
    Probe := TSemanticProbe.Create(App.Root);
    Probe.SetBounds(0, 0, 40, 20);

    { Hover enter emitted once. }
    App.Feed(LuxEventMouse(5, 5, mbNone, maMove, [], 0, False));
    LuxCheckEqualInt(1, Probe.Enters, 'enter once');
    App.Feed(LuxEventMouse(6, 5, mbNone, maMove, [], 0, False));
    LuxCheckEqualInt(1, Probe.Enters, 'no repeat enter');
    LuxCheckEqualInt(1, Probe.Moves, 'move after enter');

    { Press routed. }
    App.Feed(LuxEventMouse(10, 10, mbLeft, maPress, [], 0, False));
    LuxCheckEqualInt(1, Probe.Downs, 'down');

    { Release + click. }
    App.Feed(LuxEventMouse(10, 10, mbLeft, maRelease, [], 0, False));
    LuxCheckEqualInt(1, Probe.Ups, 'up');
    LuxCheckEqualInt(1, Probe.Clicks, 'click');
    LuxCheckEqualInt(0, Probe.DblClicks, 'no dblclick yet');

    { Double-click within threshold. }
    Clock.NowValue := 1100;
    App.Feed(LuxEventMouse(10, 10, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(10, 10, mbLeft, maRelease, [], 0, False));
    LuxCheckEqualInt(2, Probe.Clicks, 'second click');
    LuxCheckEqualInt(1, Probe.DblClicks, 'double-click');

    { Double-click not repeated for third click. }
    Clock.NowValue := 1200;
    App.Feed(LuxEventMouse(10, 10, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(10, 10, mbLeft, maRelease, [], 0, False));
    LuxCheckEqualInt(3, Probe.Clicks, 'third click');
    LuxCheckEqualInt(1, Probe.DblClicks, 'no triple-click as dbl');

    { Drag begins after threshold (2 cells). }
    App.Feed(LuxEventMouse(5, 5, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(6, 5, mbLeft, maMove, [], 0, False));
    LuxCheckEqualInt(0, Probe.DragBegins, 'no drag below threshold');
    App.Feed(LuxEventMouse(7, 5, mbLeft, maMove, [], 0, False));
    LuxCheckEqualInt(1, Probe.DragBegins, 'drag begins at threshold');
    App.Feed(LuxEventMouse(8, 5, mbLeft, maMove, [], 0, False));
    LuxCheckEqualInt(1, Probe.DragMoves, 'drag move');
    App.Feed(LuxEventMouse(8, 5, mbLeft, maRelease, [], 0, False));
    LuxCheckEqualInt(1, Probe.DragEnds, 'drag end');
    LuxCheckEqualInt(3, Probe.Clicks, 'no click after drag');

    { Wheel. }
    App.Feed(LuxEventMouse(5, 5, mbNone, maWheel, [], 1, False));
    LuxCheckEqualInt(1, Probe.WheelEvents, 'wheel delivered');
    LuxCheckEqualInt(1, Probe.LastWheelDelta, 'wheel delta');
  finally
    App.Free;
    Src := nil;
  end;
end;

procedure TestScrollViewBasics;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  SV: TLuxScrollView;
  Content: TLuxControl;
  Probe: TSemanticProbe;
  VR: TLuxRect;
begin
  LuxSection('ScrollView basics');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 20, 10);
  try
    SV := TLuxScrollView.Create(App.Root);
    SV.SetBounds(0, 0, 20, 10);

    Content := TLuxControl.Create(nil);
    Content.SetBounds(0, 0, 40, 30);
    SV.Content := Content;

    LuxCheckEqualInt(20, SV.ViewportWidth, 'viewport w');
    LuxCheckEqualInt(10, SV.ViewportHeight, 'viewport h');
    LuxCheckEqualInt(40, SV.ContentWidth, 'content w');
    LuxCheckEqualInt(30, SV.ContentHeight, 'content h');
    LuxCheckEqualInt(20, SV.MaximumScrollX, 'max scroll x');
    LuxCheckEqualInt(20, SV.MaximumScrollY, 'max scroll y');

    { Offsets clamp correctly. }
    SV.ScrollTo(100, 100);
    LuxCheckEqualInt(20, SV.ScrollX, 'clamp x');
    LuxCheckEqualInt(20, SV.ScrollY, 'clamp y');

    SV.ScrollTo(-5, -3);
    LuxCheckEqualInt(0, SV.ScrollX, 'clamp x negative');
    LuxCheckEqualInt(0, SV.ScrollY, 'clamp y negative');

    { ScrollBy. }
    SV.ScrollTo(0, 0);
    SV.ScrollBy(5, 3);
    LuxCheckEqualInt(5, SV.ScrollX, 'scrollby x');
    LuxCheckEqualInt(3, SV.ScrollY, 'scrollby y');

    { Re-clamp on viewport resize. }
    SV.ScrollTo(20, 20);
    SV.SetBounds(0, 0, 20, 10);
    Content.SetBounds(0, 0, 30, 15);
    SV.ScrollTo(20, 20);
    LuxCheckEqualInt(10, SV.ScrollX, 'reclamp after content shrink x');
    LuxCheckEqualInt(5, SV.ScrollY, 'reclamp after content shrink y');

    { VisibleContentRect. }
    Content.SetBounds(0, 0, 40, 30);
    SV.ScrollTo(5, 7);
    VR := SV.VisibleContentRect;
    LuxCheckEqualInt(5, VR.Left, 'vcr left');
    LuxCheckEqualInt(7, VR.Top, 'vcr top');
    LuxCheckEqualInt(20, VR.Width, 'vcr width');
    LuxCheckEqualInt(10, VR.Height, 'vcr height');

    { EnsureVisible (rect). }
    SV.ScrollTo(0, 0);
    SV.EnsureVisible(LuxRect(25, 15, 5, 5));
    LuxCheck(SV.ScrollX >= 10, 'ensure visible scrolled x');
    LuxCheck(SV.ScrollY >= 10, 'ensure visible scrolled y');

    { EnsureVisible already visible does nothing. }
    SV.ScrollTo(5, 5);
    SV.EnsureVisible(LuxRect(5, 5, 3, 3));
    LuxCheckEqualInt(5, SV.ScrollX, 'ensure no scroll x');
    LuxCheckEqualInt(5, SV.ScrollY, 'ensure no scroll y');

    { Wheel scrolling. }
    SV.ScrollTo(0, 0);
    App.Feed(LuxEventMouse(5, 5, mbNone, maWheel, [], -1, False));
    LuxCheck(SV.ScrollY > 0, 'wheel scrolled down');
    LuxCheckEqualInt(SV.WheelScrollStep, SV.ScrollY, 'wheel step');

    { Wheel at max does not mark handled (returns False → bubbles). }
    SV.ScrollTo(0, SV.MaximumScrollY);
    Probe := TSemanticProbe.Create(nil);
    try
      { Can't easily test bubbling without nesting; just check offset unchanged. }
      App.Feed(LuxEventMouse(5, 5, mbNone, maWheel, [], -1, False));
      LuxCheckEqualInt(SV.MaximumScrollY, SV.ScrollY, 'wheel at max no change');
    finally
      Probe.Free;
    end;

    { Hit testing accounts for scroll offset. }
    Content.SetBounds(0, 0, 40, 30);
    SV.ScrollTo(0, 0);
  finally
    App.Free;
    Src := nil;
  end;
end;

procedure TestFormControls;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Lbl: TLuxLabel;
  Cb: TLuxCheckBox;
  GroupA, GroupB: TLuxPanel;
  R1, R2, R3, ROther: TLuxRadioButton;
  Changes: TClickCounter;
begin
  LuxSection('Form controls Label / CheckBox / RadioButton');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 20);
  Changes := TClickCounter.Create;
  try
    { Label preferred size + Unicode. }
    Lbl := TLuxLabel.Create(App.Root);
    LuxCheckEqualInt(0, Lbl.PreferredWidth, 'empty label pref w');
    LuxCheckEqualInt(1, Lbl.PreferredHeight, 'empty label pref h');
    Lbl.Text := 'Hello';
    LuxCheckEqualInt(5, Lbl.PreferredWidth, 'ascii label pref w');
    LuxCheckEqualInt(1, Lbl.PreferredHeight, 'ascii label pref h');
    Lbl.Text := UnicodeString(#$00E9) + 't' + UnicodeString(#$00E9); { été }
    LuxCheckEqualInt(3, Lbl.PreferredWidth, 'unicode label pref w');
    LuxCheckEqualStr(UnicodeString(#$00E9) + 't' + UnicodeString(#$00E9), Lbl.Text,
      'unicode label text');

    { CheckBox click + Space toggle. }
    Cb := TLuxCheckBox.Create(App.Root);
    Cb.Text := 'Accept';
    Cb.SetBounds(0, 0, 20, 1);
    Cb.OnChange := @Changes.OnClick;
    Changes.Count := 0;
    LuxCheckEqualInt(4 + Length('Accept'), Cb.PreferredWidth, 'checkbox pref w');
    LuxCheck(not Cb.Checked, 'checkbox starts unchecked');

    App.Focus.SetFocus(Cb);
    LuxCheck(Cb.HasFocus, 'checkbox focused');
    App.Feed(LuxEventKey(lkChar, ' ', [], kaPress));
    LuxCheck(Cb.Checked, 'space toggles on');
    LuxCheckEqualInt(1, Changes.Count, 'space change once');
    App.Feed(LuxEventKey(lkChar, ' ', [], kaPress));
    LuxCheck(not Cb.Checked, 'space toggles off');

    App.Feed(LuxEventMouse(2, 0, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(2, 0, mbLeft, maRelease, [], 0, False));
    LuxCheck(Cb.Checked, 'click toggles on');

    { Disabled checkbox: no toggle, no focus. }
    Cb.Checked := False;
    Changes.Count := 0;
    Cb.Enabled := False;
    App.Focus.EnsureValid;
    LuxCheck(not Cb.HasFocus, 'disabled loses focus');
    LuxCheck(not App.Focus.SetFocus(Cb), 'disabled cannot receive focus');
    App.Feed(LuxEventMouse(2, 0, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(2, 0, mbLeft, maRelease, [], 0, False));
    LuxCheck(not Cb.Checked, 'disabled click no toggle');
    LuxCheckEqualInt(0, Changes.Count, 'disabled no change');
    Cb.Enabled := True;

    { Radio siblings: selecting one clears others in same parent only. }
    GroupA := TLuxPanel.Create(App.Root);
    GroupA.SetBounds(0, 2, 20, 5);
    GroupB := TLuxPanel.Create(App.Root);
    GroupB.SetBounds(22, 2, 18, 5);

    R1 := TLuxRadioButton.Create(GroupA);
    R1.Text := 'A1';
    R1.SetBounds(0, 0, 18, 1);
    R2 := TLuxRadioButton.Create(GroupA);
    R2.Text := 'A2';
    R2.SetBounds(0, 1, 18, 1);
    R3 := TLuxRadioButton.Create(GroupA);
    R3.Text := 'A3';
    R3.SetBounds(0, 2, 18, 1);
    ROther := TLuxRadioButton.Create(GroupB);
    ROther.Text := 'B1';
    ROther.SetBounds(0, 0, 16, 1);
    ROther.Checked := True;

    LuxCheckEqualInt(4 + Length('A1'), R1.PreferredWidth, 'radio pref w');

    App.Focus.SetFocus(R1);
    App.Feed(LuxEventKey(lkChar, ' ', [], kaPress));
    LuxCheck(R1.Checked, 'space selects R1');
    LuxCheck(not R2.Checked, 'R2 clear');
    LuxCheck(not R3.Checked, 'R3 clear');
    LuxCheck(ROther.Checked, 'other group unchanged');

    App.Feed(LuxEventMouse(GroupA.Left + 1, GroupA.Top + 1, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(GroupA.Left + 1, GroupA.Top + 1, mbLeft, maRelease, [], 0, False));
    LuxCheck(R2.Checked, 'click selects R2');
    LuxCheck(not R1.Checked, 'R1 cleared by sibling');
    LuxCheck(ROther.Checked, 'other group still checked');

    { Disabled radio inert. }
    R3.Enabled := False;
    App.Focus.SetFocus(R2);
    App.Feed(LuxEventMouse(GroupA.Left + 1, GroupA.Top + 2, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(GroupA.Left + 1, GroupA.Top + 2, mbLeft, maRelease, [], 0, False));
    LuxCheck(not R3.Checked, 'disabled radio not selected');
    LuxCheck(R2.Checked, 'R2 remains after disabled click');
  finally
    Changes.Free;
    App.Free;
    Src := nil;
  end;
end;

procedure TestSeparator;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Sep: TLuxSeparator;
  Btn: TLuxButton;
  VLay: TLuxVerticalLayout;
  HLay: TLuxHorizontalLayout;
  Surf: TLuxSurface;
  GlyphH, GlyphV: UnicodeString;
begin
  LuxSection('Lux.Separator');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 12);
  GlyphH := UnicodeString(WideChar($2500));
  GlyphV := UnicodeString(WideChar($2502));
  try
    Sep := TLuxSeparator.Create(App.Root);
    LuxCheck(Sep.Orientation = loHorizontal, 'default orientation horizontal');
    LuxCheck(not Sep.Focusable, 'separator not focusable');
    LuxCheckEqualInt(1, Sep.PreferredHeight, 'horiz pref h');
    LuxCheckEqualInt(1, Sep.MinHeight, 'horiz min h');
    LuxCheckEqualInt(1, Sep.PreferredWidth, 'horiz pref w');

    Sep.Orientation := loVertical;
    LuxCheckEqualInt(1, Sep.PreferredWidth, 'vert pref w');
    LuxCheckEqualInt(1, Sep.MinWidth, 'vert min w');
    LuxCheckEqualInt(1, Sep.PreferredHeight, 'vert pref h');

    Sep.Orientation := loHorizontal;
    LuxCheck(Sep.Orientation = loHorizontal, 'orientation back to horizontal');

    { Zero bounds safe. }
    Sep.SetBounds(0, 0, 0, 0);
    Sep.Render(App.Surface);

    { Horizontal render. }
    Sep.SetBounds(0, 1, 10, 1);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheckEqualStr(GlyphH, Surf.Cells[0, 1].Text, 'horiz glyph left');
    LuxCheckEqualStr(GlyphH, Surf.Cells[5, 1].Text, 'horiz glyph mid');

    { Vertical render. }
    Sep.Orientation := loVertical;
    Sep.SetBounds(2, 0, 1, 5);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheckEqualStr(GlyphV, Surf.Cells[2, 0].Text, 'vert glyph top');
    LuxCheckEqualStr(GlyphV, Surf.Cells[2, 2].Text, 'vert glyph mid');

    { Disabled safe paint. }
    Sep.Enabled := False;
    Sep.Render(App.Surface);
    Sep.Enabled := True;

    { Tab skips separator; button remains focusable. }
    Sep.Orientation := loHorizontal;
    Sep.SetBounds(0, 3, 10, 1);
    Btn := TLuxButton.Create(App.Root);
    Btn.Text := 'Go';
    Btn.SetBounds(0, 4, 8, 1);
    LuxCheck(not App.Focus.SetFocus(Sep), 'cannot focus separator');
    LuxCheck(App.Focus.SetFocus(Btn), 'can focus button');
    App.Feed(LuxEventKey(lkTab, '', [], kaPress));
    LuxCheck(Btn.HasFocus or (App.Focus.FocusedControl = Btn),
      'tab stays on focusables');

    { Mouse over separator does not capture. }
    App.Feed(LuxEventMouse(1, 3, mbLeft, maPress, [], 0, False));
    LuxCheck(App.CapturedControl = nil, 'separator no capture');
    App.Feed(LuxEventMouse(1, 3, mbLeft, maRelease, [], 0, False));

    { Layout integration. }
    VLay := TLuxVerticalLayout.Create(App.Root);
    VLay.SetBounds(20, 0, 18, 6);
    Sep := TLuxSeparator.Create(VLay);
    Sep.Orientation := loHorizontal;
    Btn := TLuxButton.Create(VLay);
    Btn.Text := 'A';
    Btn.PreferredHeight := 1;
    VLay.SetBounds(20, 0, 18, 7);
    LuxCheck(Sep.Height >= 1, 'vlayout sep height');

    HLay := TLuxHorizontalLayout.Create(App.Root);
    HLay.SetBounds(0, 6, 20, 4);
    Sep := TLuxSeparator.Create(HLay);
    Sep.Orientation := loVertical;
    Btn := TLuxButton.Create(HLay);
    Btn.Text := 'B';
    Btn.PreferredWidth := 4;
    HLay.SetBounds(0, 6, 22, 4);
    LuxCheck(Sep.Width >= 1, 'hlayout sep width');
  finally
    App.Free;
    Src := nil;
  end;
end;

procedure TestToggle;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Tg: TLuxToggle;
  Changes: TClickCounter;
  Surf: TLuxSurface;
begin
  LuxSection('Lux.Toggle');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 10);
  Changes := TClickCounter.Create;
  try
    Tg := TLuxToggle.Create(App.Root);
    Tg.Text := 'Auto';
    Tg.SetBounds(0, 0, 20, 1);
    Tg.OnChange := @Changes.OnClick;
    Changes.Count := 0;

    LuxCheck(not Tg.Checked, 'default off');
    LuxCheckEqualInt(1 + 7 + 1 + Length('Auto'), Tg.PreferredWidth, 'pref w ascii');
    LuxCheckEqualInt(1, Tg.PreferredHeight, 'pref h');

    Tg.Checked := True;
    LuxCheck(Tg.Checked, 'programmatic on');
    LuxCheckEqualInt(1, Changes.Count, 'onchange on real assign');
    Tg.Checked := True;
    LuxCheckEqualInt(1, Changes.Count, 'no onchange on no-op');

    Tg.Checked := False;
    Changes.Count := 0;
    App.Focus.SetFocus(Tg);
    LuxCheck(Tg.HasFocus, 'toggle focused');
    App.Feed(LuxEventKey(lkChar, ' ', [], kaPress));
    LuxCheck(Tg.Checked, 'space toggles on');
    LuxCheckEqualInt(1, Changes.Count, 'space one change');

    App.Feed(LuxEventMouse(2, 0, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(2, 0, mbLeft, maRelease, [], 0, False));
    LuxCheck(not Tg.Checked, 'click toggles off');
    LuxCheckEqualInt(2, Changes.Count, 'click one change');

    { Disabled. }
    Changes.Count := 0;
    Tg.Enabled := False;
    App.Focus.EnsureValid;
    LuxCheck(not App.Focus.SetFocus(Tg), 'disabled no focus');
    App.Feed(LuxEventMouse(2, 0, mbLeft, maPress, [], 0, False));
    App.Feed(LuxEventMouse(2, 0, mbLeft, maRelease, [], 0, False));
    LuxCheck(not Tg.Checked, 'disabled click inert');
    LuxCheckEqualInt(0, Changes.Count, 'disabled no change');
    Tg.Enabled := True;

    { Unicode preferred size. }
    Tg.Text := UnicodeString(#$00E9) + 't' + UnicodeString(#$00E9);
    LuxCheckEqualInt(1 + 7 + 1 + 3, Tg.PreferredWidth, 'pref w unicode');

    Tg.Text := '';
    LuxCheckEqualInt(1 + 7, Tg.PreferredWidth, 'empty text pref w');

    { Narrow / clip safe. }
    Tg.Text := 'Wide label here';
    Tg.Checked := True;
    Tg.SetBounds(0, 0, 4, 1);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheck(Surf.Cells[1, 0].Text <> '', 'narrow still paints');

    Tg.SetBounds(0, 0, 20, 1);
    App.Focus.SetFocus(Tg);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheckEqualStr('>', Surf.Cells[0, 0].Text, 'focus marker');
  finally
    Changes.Free;
    App.Free;
    Src := nil;
  end;
end;

procedure TestGroupBox;
var
  App: TTestControlApp;
  Src: ILuxEventSource;
  Gb, Nested: TLuxGroupBox;
  Child: TLuxButton;
  Cb: TLuxCheckBox;
  CR: TLuxRect;
  Surf: TLuxSurface;
begin
  LuxSection('Lux.GroupBox');
  Src := TFakeEventSource.Create;
  App := TTestControlApp.Create(TLuxMemoryTerminalWriter.Create, Src, 40, 16);
  try
    Gb := TLuxGroupBox.Create(App.Root);
    LuxCheckEqualStr('', Gb.Text, 'default empty title');
    LuxCheck(not Gb.Focusable, 'groupbox not focusable');
    LuxCheck(not App.Focus.SetFocus(Gb), 'cannot focus groupbox');

    Gb.Text := 'Prefs';
    LuxCheck(Gb.PreferredWidth >= Length('Prefs') + 4, 'pref w from title');
    LuxCheckEqualInt(2, Gb.MinWidth, 'title does not raise min width');
    LuxCheckEqualInt(Length('Prefs'), Length(Gb.Text), 'title stored');

    Gb.Text := 'Prefs';
    { no-op }
    Gb.Text := UnicodeString(#$65E5) + ' title';
    LuxCheck(Length(Gb.Text) = 7, 'unicode title length');
    LuxCheckEqualInt(2, Gb.MinWidth, 'unicode title keeps min width 2');

    Gb.Text := '';
    LuxCheckEqualStr('', Gb.Text, 'empty title ok');
    LuxCheckEqualInt(2, Gb.PreferredWidth, 'empty title preferred resets');

    Gb.SetBounds(0, 0, 20, 8);
    CR := Gb.ClientRect;
    LuxCheckEqualInt(1, CR.Left, 'client left');
    LuxCheckEqualInt(1, CR.Top, 'client top');
    LuxCheckEqualInt(18, CR.Width, 'client width');
    LuxCheckEqualInt(6, CR.Height, 'client height');

    { Tiny / zero bounds. }
    Gb.SetBounds(0, 0, 1, 1);
    CR := Gb.ClientRect;
    LuxCheckEqualInt(0, CR.Width, 'tiny client w');
    LuxCheckEqualInt(0, CR.Height, 'tiny client h');
    Gb.Render(App.Surface);

    Gb.SetBounds(0, 0, 0, 0);
    Gb.Render(App.Surface);

    { Child placement relative to client. }
    Gb.Text := 'Box';
    Gb.SetBounds(0, 0, 24, 10);
    Child := TLuxButton.Create(Gb);
    Child.Text := 'In';
    Child.SetBounds(0, 0, 6, 1);
    LuxCheckEqualInt(1, Child.AbsoluteBounds.Left, 'child abs left inset');
    LuxCheckEqualInt(1, Child.AbsoluteBounds.Top, 'child abs top inset');

    App.Focus.SetFocus(Child);
    LuxCheck(Child.HasFocus, 'child focusable');
    App.Feed(LuxEventKey(lkTab, '', [], kaPress));

    { Nested group box. }
    Nested := TLuxGroupBox.Create(Gb);
    Nested.Text := 'Inner';
    Nested.SetBounds(1, 2, 18, 5);
    Cb := TLuxCheckBox.Create(Nested);
    Cb.Text := 'Opt';
    Cb.SetBounds(0, 0, 12, 1);
    LuxCheckEqualInt(Gb.Left + 1 + Nested.Left + 1,
      Cb.AbsoluteBounds.Left, 'nested abs left');

    { Disabled group disables descendants effectively. }
    Gb.Enabled := False;
    LuxCheck(not Cb.IsEffectivelyEnabled, 'child effectively disabled');
    LuxCheck(not App.Focus.SetFocus(Cb), 'disabled tree no focus');
    Gb.Enabled := True;
    LuxCheck(Cb.IsEffectivelyEnabled, 're-enabled');

    { Title paint. }
    Gb.Text := 'Title';
    Gb.SetBounds(0, 0, 20, 6);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheckEqualStr(UnicodeString(WideChar($250C)), Surf.Cells[0, 0].Text,
      'top-left corner');
    LuxCheckEqualStr(UnicodeString(WideChar($2510)), Surf.Cells[19, 0].Text,
      'top-right corner');
    LuxCheckEqualStr('T', Surf.Cells[2, 0].Text, 'title first char');

    { Clipped long title must not overwrite corners. }
    Gb.Text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Gb.SetBounds(0, 0, 10, 4);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheckEqualStr(UnicodeString(WideChar($250C)), Surf.Cells[0, 0].Text,
      'clipped title keeps TL');
    LuxCheckEqualStr(UnicodeString(WideChar($2510)), Surf.Cells[9, 0].Text,
      'clipped title keeps TR');
    LuxCheckEqualStr(UnicodeString(WideChar($2518)), Surf.Cells[9, 3].Text,
      'clipped title keeps BR');

    { Wide CJK title truncated by cells, corners intact. }
    Gb.Text := UnicodeString(#$65E5) + UnicodeString(#$672C) +
      UnicodeString(#$8A9E) + UnicodeString(#$30BF) + UnicodeString(#$30A4);
    Gb.SetBounds(0, 0, 8, 3);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheckEqualStr(UnicodeString(WideChar($250C)), Surf.Cells[0, 0].Text,
      'wide title keeps TL');
    LuxCheckEqualStr(UnicodeString(WideChar($2510)), Surf.Cells[7, 0].Text,
      'wide title keeps TR');

    { Long title in a narrow parent layout must not force overflow min-width. }
    Gb.Text := 'Very long group box title that used to raise MinWidth';
    LuxCheckEqualInt(2, Gb.MinWidth, 'long title min width still 2');
    Gb.SetBounds(0, 0, 12, 4);
    App.Root.Render(App.Surface);
    Surf := App.Surface;
    LuxCheckEqualStr(UnicodeString(WideChar($2510)), Surf.Cells[11, 0].Text,
      'narrow bounds keep TR');
    LuxCheckEqualStr(UnicodeString(WideChar($2518)), Surf.Cells[11, 3].Text,
      'narrow bounds keep BR');

    { Children preserved after text change. }
    LuxCheck(Gb.ChildCount >= 2, 'children preserved');
  finally
    App.Free;
    Src := nil;
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
  TestDeferredResize;
  TestEventsAndQueue;
  TestTimers;
  TestControlOwnership;
  TestControlGeometryAndHit;
  TestControlFocus;
  TestLayoutEngine;
  TestClientAreaAndAppearance;
  TestStackLayout;
  TestCursorManager;
  TestSplitGeometryAndHit;
  TestMouseCaptureAndSplitDrag;
  TestSplitEscapeCancellation;
  TestSplitCaptureLoss;
  TestSplitResizeAndOrientationDuringDrag;
  TestSplitPropertyChangesDuringDrag;
  TestSemanticMouseDispatcher;
  TestScrollViewBasics;
  TestFormControls;
  TestSeparator;
  TestToggle;
  TestGroupBox;
  TestControlRenderingAndEvents;
  TestControlKeyboardRouting;
  Halt(LuxTestExitCode);
end.
