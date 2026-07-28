{ Windows console implementation of ILuxTerminalWriter. }
unit Lux.Platform.Windows.TerminalWriter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Windows,
  Lux.Terminal.Writer,
  Lux.Platform.Windows.Console;

type
  { Writes UTF-8 / raw bytes through a Windows console or file handle.
    Does not own the handle lifetime. }
  TLuxWindowsTerminalWriter = class(TInterfacedObject, ILuxTerminalWriter)
  private
    FHandle: THandle;
    FOwnsHandle: Boolean;
    procedure WriteBuffer(APtr: Pointer; ACount: Integer);
  public
    constructor Create(AHandle: THandle; AOwnsHandle: Boolean = False);
    destructor Destroy; override;

    procedure WriteText(const AText: UnicodeString);
    procedure WriteRaw(const AData: RawByteString);
    procedure Flush;

    property Handle: THandle read FHandle;
  end;

implementation

constructor TLuxWindowsTerminalWriter.Create(AHandle: THandle;
  AOwnsHandle: Boolean);
begin
  inherited Create;
  FHandle := AHandle;
  FOwnsHandle := AOwnsHandle;
end;

destructor TLuxWindowsTerminalWriter.Destroy;
begin
  if FOwnsHandle and (FHandle <> 0) and (FHandle <> INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
  inherited Destroy;
end;

procedure TLuxWindowsTerminalWriter.WriteBuffer(APtr: Pointer; ACount: Integer);
var
  P: PByte;
  Remaining: Integer;
  Written: DWORD;
begin
  if (ACount <= 0) or (APtr = nil) then
    Exit;
  if (FHandle = 0) or (FHandle = INVALID_HANDLE_VALUE) then
    raise ELuxWindowsTerminal.CreateOp('WriteFile', ERROR_INVALID_HANDLE);

  P := APtr;
  Remaining := ACount;
  while Remaining > 0 do
  begin
    Written := 0;
    if not WriteFile(FHandle, P^, DWORD(Remaining), Written, nil) then
      raise ELuxWindowsTerminal.CreateOp('WriteFile', GetLastError);
    if Written = 0 then
      raise ELuxWindowsTerminal.CreateOp('WriteFile(zero bytes)', ERROR_WRITE_FAULT);
    Inc(P, Written);
    Dec(Remaining, Integer(Written));
  end;
end;

procedure TLuxWindowsTerminalWriter.WriteText(const AText: UnicodeString);
var
  Bytes: RawByteString;
begin
  Bytes := LuxUTF8Bytes(AText);
  WriteRaw(Bytes);
end;

procedure TLuxWindowsTerminalWriter.WriteRaw(const AData: RawByteString);
begin
  if AData = '' then
    Exit;
  WriteBuffer(@AData[1], System.Length(AData));
end;

procedure TLuxWindowsTerminalWriter.Flush;
var
  FileType: DWORD;
begin
  if (FHandle = 0) or (FHandle = INVALID_HANDLE_VALUE) then
    raise ELuxWindowsTerminal.CreateOp('FlushFileBuffers', ERROR_INVALID_HANDLE);

  FileType := GetFileType(FHandle);
  if FileType = FILE_TYPE_CHAR then
    Exit; { Console handles typically reject FlushFileBuffers. }

  if not FlushFileBuffers(FHandle) then
    raise ELuxWindowsTerminal.CreateOp('FlushFileBuffers', GetLastError);
end;

end.
