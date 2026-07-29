{ Phase 6B.1 stack overlay demo (Windows). }
program stack_demo_windows;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Lux.Platform.Windows.TerminalSession,
  Lux.Platform.Windows.EventSource,
  Lux.EventSource,
  Lux.ControlApplication,
  StackDemo;

var
  Session: TLuxWindowsTerminalSession;
  Source: ILuxEventSource;
  App: TStackDemoApp;
begin
  Session := TLuxWindowsTerminalSession.Create;
  try
    Session.Open;
    Source := TLuxWindowsEventSource.Create(Session);
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
