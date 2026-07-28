{ Optional Windows console integration tests.
  Run only with an interactive console:
    powershell -File tools\test_windows_integration.ps1 }
program lux_windows_integration_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Windows,
  Lux.Color,
  Lux.Surface,
  Lux.Renderer,
  Lux.Platform.Windows.Console,
  Lux.Platform.Windows.TerminalSession,
  Lux.TestHarness;

procedure RequireConsole;
var
  Caps: TLuxWindowsConsoleCaps;
begin
  Caps := TLuxWindowsTerminalSession.Probe;
  if (not Caps.OutputIsConsole) or Caps.OutputRedirected or
     (not Caps.VirtualTerminalSupported) then
  begin
    WriteLn('SKIP: interactive console with VT required.');
    Halt(0);
  end;
end;

procedure TestLiveRender;
var
  Session: TLuxWindowsTerminalSession;
  Surface: TLuxSurface;
  Renderer: TLuxRenderer;
begin
  LuxSection('Live console render');
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Surface := TLuxSurface.Create(20, 5);
    try
      Renderer := TLuxRenderer.Create(Session.Writer);
      try
        Surface.PutText(1, 1, 'LUX', LuxColorRGB(0, 255, 0), LuxColorDefault, [tsBold]);
        Renderer.Render(Surface);
        Surface.PutText(1, 2, 'OK', LuxColorRGB(255, 255, 0), LuxColorDefault, []);
        Renderer.Render(Surface);
        LuxCheck(True, 'live render completed');
      finally
        Renderer.Free;
      end;
    finally
      Surface.Free;
    end;
  finally
    Session.Free;
  end;
end;

begin
  WriteLn('LUX Windows integration tests');
  RequireConsole;
  TestLiveRender;
  Halt(LuxTestExitCode);
end.
