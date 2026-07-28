{ Phase 4 event-loop example (Windows). }
program eventloop_windows;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.EventSource,
  Lux.EventSource,
  Lux.Application,
  EventLoopDemo;

var
  Session: TLuxWindowsTerminalSession;
  Source: ILuxEventSource;
  App: TEventLoopDemoApp;
begin
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxWindowsEventSource.Create(Session);
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
