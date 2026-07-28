{ Phase 4 event-loop example (Unix). }
program eventloop_unix;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Unix.TerminalSession,
  Lux.Platform.Unix.EventSource,
  Lux.EventSource,
  Lux.Application,
  EventLoopDemo;

var
  Session: TLuxUnixTerminalSession;
  Source: ILuxEventSource;
  App: TEventLoopDemoApp;
begin
  Session := TLuxUnixTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxUnixEventSource.Create(Session);
    App := TEventLoopDemoApp.Create(Session.Writer, Source,
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
