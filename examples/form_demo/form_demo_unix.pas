{ Phase 6D form controls demo (Unix). }
program form_demo_unix;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Unix.TerminalSession,
  Lux.Platform.Unix.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  FormDemo;

var
  Session: TLuxUnixTerminalSession;
  Source: ILuxEventSource;
  App: TFormDemoApp;
begin
  Session := TLuxUnixTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxUnixEventSource.Create(Session);
    App := TFormDemoApp.Create(Session.Writer, Source,
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
