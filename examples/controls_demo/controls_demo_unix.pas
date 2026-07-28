{ Phase 5 controls demo (Unix). }
program controls_demo_unix;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Unix.TerminalSession,
  Lux.Platform.Unix.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  ControlsDemo;

var
  Session: TLuxUnixTerminalSession;
  Source: ILuxEventSource;
  App: TControlsDemoApp;
begin
  Session := TLuxUnixTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxUnixEventSource.Create(Session);
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
