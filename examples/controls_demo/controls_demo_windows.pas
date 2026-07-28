{ Phase 5 controls demo (Windows). }
program controls_demo_windows;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  ControlsDemo;

var
  Session: TLuxWindowsTerminalSession;
  Source: ILuxEventSource;
  App: TControlsDemoApp;
begin
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxWindowsEventSource.Create(Session);
    App := TControlsDemoApp.Create(Session.Writer, Source,
      Session.Columns, Session.Rows);
    try
      App.Run;
    finally
      App.Free;
      Source := nil;
    end;
  finally
    Session.Free;
  end;
end.
