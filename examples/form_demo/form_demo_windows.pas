{ Phase 6D form controls demo (Windows). }
program form_demo_windows;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  FormDemo;

var
  Session: TLuxWindowsTerminalSession;
  Source: ILuxEventSource;
  App: TFormDemoApp;
begin
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxWindowsEventSource.Create(Session);
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
