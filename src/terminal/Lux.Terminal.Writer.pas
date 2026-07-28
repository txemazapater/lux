{ Terminal output sink. Portable; no console APIs. }
unit Lux.Terminal.Writer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  { Destination for rendered terminal bytes. Implementations must not
    assume a physical console; Phase 2A uses a memory-backed writer. }
  ILuxTerminalWriter = interface
    ['{6E2F8A41-9C3B-4D7E-A1F0-52B8D4E9C7A3}']
    { Append UTF-8 text. UnicodeString is encoded as UTF-8. }
    procedure WriteText(const AText: UnicodeString);
    { Append raw bytes (ANSI sequences or pre-encoded UTF-8). }
    procedure WriteRaw(const AData: RawByteString);
    { Flush any buffered output. Memory writers may treat this as a no-op
      beyond marking a flush boundary for tests. }
    procedure Flush;
  end;

{ Encode Unicode as raw UTF-8 bytes without ANSI code-page loss. }
function LuxUTF8Bytes(const AText: UnicodeString): RawByteString;

implementation

function LuxUTF8Bytes(const AText: UnicodeString): RawByteString;
var
  U: UTF8String;
  N: Integer;
begin
  U := UTF8Encode(AText);
  N := System.Length(U);
  Result := '';
  SetLength(Result, N);
  if N > 0 then
    Move(U[1], Result[1], N);
end;

end.
