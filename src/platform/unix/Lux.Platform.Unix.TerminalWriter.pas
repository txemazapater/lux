{ Unix TTY / fd implementation of ILuxTerminalWriter. }
unit Lux.Platform.Unix.TerminalWriter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  BaseUnix,
  Lux.Terminal.Writer,
  Lux.Platform.Unix.Console;

type
  { Writes UTF-8 / raw bytes through a Unix file descriptor.
    Does not own the fd lifetime unless AOwnsFd is True. }
  TLuxUnixTerminalWriter = class(TInterfacedObject, ILuxTerminalWriter)
  private
    FFd: cint;
    FOwnsFd: Boolean;
    procedure WriteBuffer(const AData; ACount: Integer);
  public
    constructor Create(AFd: cint; AOwnsFd: Boolean = False);
    destructor Destroy; override;

    procedure WriteText(const AText: UnicodeString);
    procedure WriteRaw(const AData: RawByteString);
    procedure Flush;

    property Fd: cint read FFd;
  end;

implementation

constructor TLuxUnixTerminalWriter.Create(AFd: cint; AOwnsFd: Boolean);
begin
  inherited Create;
  FFd := AFd;
  FOwnsFd := AOwnsFd;
end;

destructor TLuxUnixTerminalWriter.Destroy;
begin
  if FOwnsFd and (FFd >= 0) then
  begin
    FpClose(FFd);
    FFd := -1;
  end;
  inherited Destroy;
end;

procedure TLuxUnixTerminalWriter.WriteBuffer(const AData; ACount: Integer);
var
  P: PByte;
  Remaining: Integer;
  Written: TsSize;
begin
  if ACount <= 0 then
    Exit;
  if FFd < 0 then
    raise ELuxUnixTerminal.CreateOp('write', ESysEBADF);

  P := @AData;
  Remaining := ACount;
  while Remaining > 0 do
  begin
    Written := FpWrite(FFd, P, Remaining);
    if Written < 0 then
      raise ELuxUnixTerminal.CreateOp('write', FpGetErrno);
    if Written = 0 then
      raise ELuxUnixTerminal.CreateOp('write(zero bytes)', ESysEIO);
    Inc(P, Written);
    Dec(Remaining, Integer(Written));
  end;
end;

procedure TLuxUnixTerminalWriter.WriteText(const AText: UnicodeString);
begin
  WriteRaw(LuxUTF8Bytes(AText));
end;

procedure TLuxUnixTerminalWriter.WriteRaw(const AData: RawByteString);
begin
  if AData = '' then
    Exit;
  WriteBuffer(AData[1], System.Length(AData));
end;

procedure TLuxUnixTerminalWriter.Flush;
begin
  if FFd < 0 then
    raise ELuxUnixTerminal.CreateOp('fsync', ESysEBADF);
  { fsync is often unsupported or undesirable on TTYs; only sync regular files. }
  if LuxUnixIsTty(FFd) then
    Exit;
  if FpFSync(FFd) <> 0 then
  begin
    if FpGetErrno <> ESysEINVAL then
      raise ELuxUnixTerminal.CreateOp('fsync', FpGetErrno);
  end;
end;

end.
