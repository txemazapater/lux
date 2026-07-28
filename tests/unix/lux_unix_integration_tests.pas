{ Optional Unix TTY integration tests.
  Run with an interactive terminal:
    ./tools/test_unix_integration.sh }
program lux_unix_integration_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Color,
  Lux.Surface,
  Lux.Renderer,
  Lux.Platform.Unix.Console,
  Lux.Platform.Unix.TerminalSession,
  Lux.TestHarness;

procedure RequireTty;
var
  Caps: TLuxUnixConsoleCaps;
begin
  Caps := TLuxUnixTerminalSession.Probe;
  if (not Caps.OutputIsTty) or Caps.OutputRedirected or
     (not Caps.AnsiLikelySupported) then
  begin
    WriteLn('SKIP: interactive TTY with ANSI required.');
    Halt(0);
  end;
end;

procedure TestLiveRender;
var
  Session: TLuxUnixTerminalSession;
  Surface: TLuxSurface;
  Renderer: TLuxRenderer;
begin
  LuxSection('Live TTY render');
  Session := TLuxUnixTerminalSession.Create;
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
  WriteLn('LUX Unix integration tests');
  RequireTty;
  TestLiveRender;
  Halt(LuxTestExitCode);
end.
