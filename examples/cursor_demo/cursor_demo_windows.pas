{ Phase 6B.2 cursor demo (Windows). }
program cursor_demo_windows;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  CursorDemo;

var
  Session: TLuxWindowsTerminalSession;
  Source: ILuxEventSource;
  App: TCursorDemoApp;
begin
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxWindowsEventSource.Create(Session);
    App := TCursorDemoApp.Create(Session.Writer, Source,
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
