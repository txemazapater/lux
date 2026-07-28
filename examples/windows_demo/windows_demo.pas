{ Windows console demo for LUX Phase 3A.
  Opens a real console session, renders two frames, restores on exit. }
program windows_demo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Windows,
  Lux.Color,
  Lux.Cell,
  Lux.Surface,
  Lux.Renderer,
  Lux.Terminal.Ansi,
  Lux.Platform.Windows.TerminalSession;

procedure DrawFrame(ASurface: TLuxSurface; const ATitle: UnicodeString;
  AAccent: TLuxColor);
var
  X, Y, W, H: Integer;
begin
  W := ASurface.Width;
  H := ASurface.Height;
  ASurface.Clear;
  for X := 0 to W - 1 do
  begin
    ASurface.PutCell(X, 0, LuxCellMake('-', 1, AAccent, LuxColorDefault, []));
    ASurface.PutCell(X, H - 1, LuxCellMake('-', 1, AAccent, LuxColorDefault, []));
  end;
  for Y := 0 to H - 1 do
  begin
    ASurface.PutCell(0, Y, LuxCellMake('|', 1, AAccent, LuxColorDefault, []));
    ASurface.PutCell(W - 1, Y, LuxCellMake('|', 1, AAccent, LuxColorDefault, []));
  end;
  ASurface.PutCell(0, 0, LuxCellMake('+', 1, AAccent, LuxColorDefault, []));
  ASurface.PutCell(W - 1, 0, LuxCellMake('+', 1, AAccent, LuxColorDefault, []));
  ASurface.PutCell(0, H - 1, LuxCellMake('+', 1, AAccent, LuxColorDefault, []));
  ASurface.PutCell(W - 1, H - 1, LuxCellMake('+', 1, AAccent, LuxColorDefault, []));
  ASurface.PutText(2, 1, ATitle, LuxColorRGB(255, 255, 255), LuxColorDefault, [tsBold]);
  ASurface.PutText(2, 3, 'LUX Phase 3A — Windows backend', LuxColorRGB(120, 200, 255),
    LuxColorDefault, []);
  ASurface.PutText(2, 4, 'TrueColor + VT + UTF-8', LuxColorRGB(120, 255, 160),
    LuxColorDefault, []);
end;

var
  Session: TLuxWindowsTerminalSession;
  Surface: TLuxSurface;
  Renderer: TLuxRenderer;
begin
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Surface := TLuxSurface.Create(48, 12);
    try
      Renderer := TLuxRenderer.Create(Session.Writer);
      try
        DrawFrame(Surface, 'Frame 1', LuxColorRGB(255, 180, 60));
        Surface.PutText(2, 6, 'First frame rendered.', LuxColorRGB(220, 220, 220),
          LuxColorDefault, []);
        Renderer.Render(Surface);

        Sleep(800);

        Surface.PutText(2, 6, 'Second frame (diff only).', LuxColorRGB(255, 220, 100),
          LuxColorDefault, [tsUnderline]);
        Surface.PutText(2, 8, 'Console will restore on exit.', LuxColorRGB(180, 180, 255),
          LuxColorDefault, []);
        Renderer.Render(Surface);

        Sleep(800);
        Session.Writer.WriteRaw(LuxAnsiShowCursor);
        Session.Writer.Flush;
      finally
        Renderer.Free;
      end;
    finally
      Surface.Free;
    end;
  finally
    Session.Free;
  end;
end.
