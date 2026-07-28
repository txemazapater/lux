{ Shared terminal errors used by platform backends. }
unit Lux.Terminal.Errors;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  { Raised when a real interactive terminal cannot be acquired. }
  ELuxTerminalUnavailable = class(Exception);

implementation

end.
