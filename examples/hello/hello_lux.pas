{ Minimal LUX example.

  Prints the framework version. This is a Phase 0 placeholder and does not
  yet exercise terminal rendering or the application loop. }
program hello_lux;

{$mode objfpc}{$H+}

uses
  Lux.Core;

begin
  WriteLn('LUX ', LuxVersion);
end.
