{ Minimal assertion helpers for LUX unit tests. }
unit Lux.TestHarness;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

var
  LuxTestsRun: Integer = 0;
  LuxTestsFailed: Integer = 0;

procedure LuxCheck(ACondition: Boolean; const AMessage: string);
procedure LuxCheckEqualInt(AExpected, AActual: Integer; const AMessage: string);
procedure LuxCheckEqualStr(const AExpected, AActual: UnicodeString;
  const AMessage: string);
procedure LuxSection(const AName: string);
function LuxTestExitCode: Integer;

implementation

procedure LuxSection(const AName: string);
begin
  WriteLn('== ', AName);
end;

procedure LuxCheck(ACondition: Boolean; const AMessage: string);
begin
  Inc(LuxTestsRun);
  if ACondition then
    WriteLn('  OK  ', AMessage)
  else
  begin
    Inc(LuxTestsFailed);
    WriteLn('  FAIL ', AMessage);
  end;
end;

procedure LuxCheckEqualInt(AExpected, AActual: Integer; const AMessage: string);
begin
  LuxCheck(AExpected = AActual,
    Format('%s (expected %d, got %d)', [AMessage, AExpected, AActual]));
end;

procedure LuxCheckEqualStr(const AExpected, AActual: UnicodeString;
  const AMessage: string);
begin
  LuxCheck(AExpected = AActual,
    Format('%s (expected "%s", got "%s")',
      [AMessage, string(AExpected), string(AActual)]));
end;

function LuxTestExitCode: Integer;
begin
  WriteLn;
  WriteLn(Format('Tests: %d  Failures: %d', [LuxTestsRun, LuxTestsFailed]));
  if LuxTestsFailed = 0 then
    Result := 0
  else
    Result := 1;
end;

end.
