{ Phase 6B.2 cursor demo (Unix). }
program cursor_demo_unix;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Unix.TerminalSession,
  Lux.Platform.Unix.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  CursorDemo;

var
  Session: TLuxUnixTerminalSession;
  Source: ILuxEventSource;
  App: TCursorDemoApp;
begin
  Session := TLuxUnixTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxUnixEventSource.Create(Session);
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
