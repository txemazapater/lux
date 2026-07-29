{ Phase 6B.1 stack overlay demo (Unix). }
program stack_demo_unix;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Unix.TerminalSession,
  Lux.Platform.Unix.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  StackDemo;

var
  Session: TLuxUnixTerminalSession;
  Source: ILuxEventSource;
  App: TStackDemoApp;
begin
  Session := TLuxUnixTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxUnixEventSource.Create(Session);
    App := TStackDemoApp.Create(Session.Writer, Source,
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
