{ In-memory terminal writer for portable tests. }
unit Lux.Terminal.MemoryWriter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Terminal.Writer;

type
  { Accumulates all writes without touching a real console. }
  TLuxMemoryTerminalWriter = class(TInterfacedObject, ILuxTerminalWriter)
  private
    FBuffer: RawByteString;
    FFlushCount: Integer;
  public
    constructor Create;
    procedure WriteText(const AText: UnicodeString);
    procedure WriteRaw(const AData: RawByteString);
    procedure Flush;
    procedure Clear;
    function Data: RawByteString;
    function AsUnicodeString: UnicodeString;
    function Length: Integer;
    function ContainsRaw(const AFragment: RawByteString): Boolean;
    function CountRaw(const AFragment: RawByteString): Integer;
    property FlushCount: Integer read FFlushCount;
  end;

implementation

constructor TLuxMemoryTerminalWriter.Create;
begin
  inherited Create;
  FBuffer := '';
  FFlushCount := 0;
end;

procedure TLuxMemoryTerminalWriter.WriteText(const AText: UnicodeString);
begin
  WriteRaw(LuxUTF8Bytes(AText));
end;

procedure TLuxMemoryTerminalWriter.WriteRaw(const AData: RawByteString);
begin
  FBuffer := FBuffer + AData;
end;

procedure TLuxMemoryTerminalWriter.Flush;
begin
  Inc(FFlushCount);
end;

procedure TLuxMemoryTerminalWriter.Clear;
begin
  FBuffer := '';
  FFlushCount := 0;
end;

function TLuxMemoryTerminalWriter.Data: RawByteString;
begin
  Result := FBuffer;
end;

function TLuxMemoryTerminalWriter.AsUnicodeString: UnicodeString;
begin
  Result := UTF8Decode(FBuffer);
end;

function TLuxMemoryTerminalWriter.Length: Integer;
begin
  Result := System.Length(FBuffer);
end;

function TLuxMemoryTerminalWriter.ContainsRaw(const AFragment: RawByteString): Boolean;
begin
  Result := Pos(AFragment, FBuffer) > 0;
end;

function TLuxMemoryTerminalWriter.CountRaw(const AFragment: RawByteString): Integer;
var
  P, LFrag: Integer;
begin
  Result := 0;
  if AFragment = '' then
    Exit;
  LFrag := System.Length(AFragment);
  P := 1;
  while P <= System.Length(FBuffer) - LFrag + 1 do
  begin
    if Copy(FBuffer, P, LFrag) = AFragment then
    begin
      Inc(Result);
      Inc(P, LFrag);
    end
    else
      Inc(P);
  end;
end;

end.
