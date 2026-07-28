{ Incremental Unix terminal byte stream decoder. No I/O; testable offline. }
unit Lux.Platform.Unix.InputParser;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Events;

const
  { After a lone ESC byte with no continuation, wait this long before treating
    it as the Escape key rather than the start of a CSI/SS3/Alt sequence. }
  LuxUnixEscAmbiguityTimeoutMs = 50;

type
  TLuxUnixParseStatus = (
    upsNone,        { no complete event yet; may need more bytes }
    upsEvent,       { Event is fully initialized }
    upsAmbiguousEsc { buffer holds a lone ESC; caller should wait then ResolveEsc }
  );

  TLuxUnixInputParser = class
  private
    FBuf: RawByteString;
    procedure Consume(ACount: Integer);
    function PeekByte(AIndex: Integer): Byte;
    function BufLen: Integer;
    function TryUtf8(out Event: TLuxEvent): TLuxUnixParseStatus;
    function TryEscape(out Event: TLuxEvent): TLuxUnixParseStatus;
    function TryCsi(out Event: TLuxEvent): TLuxUnixParseStatus;
    function TrySs3(out Event: TLuxEvent): TLuxUnixParseStatus;
    function ParseCsiKey(const Params: string; FinalByte: Char;
      out Event: TLuxEvent): Boolean;
    function ParseSgrMouse(const Body: string; FinalByte: Char;
      out Event: TLuxEvent): Boolean;
    function ModsFromParam(AParam: Integer): TLuxKeyModifiers;
    function KeyFromTildeCode(ACode: Integer): TLuxKey;
    function MakeCtrlOrSpecial(AByte: Byte; AMods: TLuxKeyModifiers;
      out Event: TLuxEvent): Boolean;
  public
    constructor Create;
    procedure Clear;
    procedure Feed(const AData: RawByteString);
    function TryParse(out Event: TLuxEvent): TLuxUnixParseStatus;
    function ResolveAmbiguousEscape(out Event: TLuxEvent): Boolean;
    property BufferedLength: Integer read BufLen;
  end;

implementation

constructor TLuxUnixInputParser.Create;
begin
  inherited Create;
  Clear;
end;

procedure TLuxUnixInputParser.Clear;
begin
  FBuf := '';
  SetCodePage(RawByteString(FBuf), CP_NONE, False);
end;

function TLuxUnixInputParser.BufLen: Integer;
begin
  Result := Length(FBuf);
end;

procedure TLuxUnixInputParser.Feed(const AData: RawByteString);
var
  Piece: RawByteString;
begin
  if AData = '' then
    Exit;
  Piece := AData;
  SetCodePage(RawByteString(Piece), CP_NONE, False);
  FBuf := FBuf + Piece;
  SetCodePage(RawByteString(FBuf), CP_NONE, False);
end;

procedure TLuxUnixInputParser.Consume(ACount: Integer);
begin
  if ACount <= 0 then
    Exit;
  if ACount >= Length(FBuf) then
    Clear
  else
  begin
    Delete(FBuf, 1, ACount);
    SetCodePage(RawByteString(FBuf), CP_NONE, False);
  end;
end;

function TLuxUnixInputParser.PeekByte(AIndex: Integer): Byte;
begin
  if (AIndex < 1) or (AIndex > Length(FBuf)) then
    Exit(0);
  Result := Byte(FBuf[AIndex]);
end;

function TLuxUnixInputParser.ModsFromParam(AParam: Integer): TLuxKeyModifiers;
begin
  Result := [];
  if AParam <= 1 then
    Exit;
  Dec(AParam);
  if (AParam and 1) <> 0 then
    Include(Result, kmShift);
  if (AParam and 2) <> 0 then
    Include(Result, kmAlt);
  if (AParam and 4) <> 0 then
    Include(Result, kmCtrl);
end;

function TLuxUnixInputParser.KeyFromTildeCode(ACode: Integer): TLuxKey;
begin
  case ACode of
    1: Result := lkHome;
    2: Result := lkInsert;
    3: Result := lkDelete;
    4: Result := lkEnd;
    5: Result := lkPageUp;
    6: Result := lkPageDown;
    11: Result := lkF1;
    12: Result := lkF2;
    13: Result := lkF3;
    14: Result := lkF4;
    15: Result := lkF5;
    17: Result := lkF6;
    18: Result := lkF7;
    19: Result := lkF8;
    20: Result := lkF9;
    21: Result := lkF10;
    23: Result := lkF11;
    24: Result := lkF12;
  else
    Result := lkUnknown;
  end;
end;

function TLuxUnixInputParser.MakeCtrlOrSpecial(AByte: Byte; AMods: TLuxKeyModifiers;
  out Event: TLuxEvent): Boolean;
var
  Ch: UnicodeString;
  Mods: TLuxKeyModifiers;
begin
  Mods := AMods;
  Result := True;
  case AByte of
    8, 127:
      Event := LuxEventKey(lkBackspace, '', Mods, kaPress);
    9:
      Event := LuxEventKey(lkTab, #9, Mods, kaPress);
    10, 13:
      Event := LuxEventKey(lkEnter, '', Mods, kaPress);
    27:
      begin
        Result := False;
        Event := LuxEventNone;
      end;
  else
    if (AByte >= 1) and (AByte <= 26) then
    begin
      Include(Mods, kmCtrl);
      Ch := UnicodeString(WideChar(Ord('a') + AByte - 1));
      Event := LuxEventKey(lkChar, Ch, Mods, kaPress);
    end
    else
    begin
      Event := LuxEventUnknown;
      Result := True;
    end;
  end;
end;

function TLuxUnixInputParser.ParseSgrMouse(const Body: string; FinalByte: Char;
  out Event: TLuxEvent): Boolean;
var
  Parts: array of string;
  Cb, Cx, Cy: Integer;
  Mods: TLuxKeyModifiers;
  Button: TLuxMouseButton;
  Action: TLuxMouseAction;
  WheelDelta: Integer;
  WheelHoriz: Boolean;
  I, N: Integer;
  Part: string;
begin
  Result := False;
  Event := LuxEventNone;

  { Split Body by ';' without relying on TStringHelper availability quirks. }
  SetLength(Parts, 0);
  Part := '';
  for I := 1 to Length(Body) do
  begin
    if Body[I] = ';' then
    begin
      N := Length(Parts);
      SetLength(Parts, N + 1);
      Parts[N] := Part;
      Part := '';
    end
    else
      Part := Part + Body[I];
  end;
  N := Length(Parts);
  SetLength(Parts, N + 1);
  Parts[N] := Part;

  if Length(Parts) < 3 then
    Exit;
  if not TryStrToInt(Parts[0], Cb) then
    Exit;
  if not TryStrToInt(Parts[1], Cx) then
    Exit;
  if not TryStrToInt(Parts[2], Cy) then
    Exit;

  Mods := [];
  if (Cb and 4) <> 0 then
    Include(Mods, kmShift);
  if (Cb and 8) <> 0 then
    Include(Mods, kmAlt);
  if (Cb and 16) <> 0 then
    Include(Mods, kmCtrl);

  WheelDelta := 0;
  WheelHoriz := False;
  Button := mbNone;
  Action := maPress;

  if (Cb and 64) <> 0 then
  begin
    Action := maWheel;
    case (Cb and 3) of
      0: WheelDelta := 1;
      1: WheelDelta := -1;
      2:
        begin
          WheelHoriz := True;
          WheelDelta := -1;
        end;
      3:
        begin
          WheelHoriz := True;
          WheelDelta := 1;
        end;
    end;
  end
  else if (Cb and 32) <> 0 then
  begin
    Action := maMove;
    case (Cb and 3) of
      0: Button := mbLeft;
      1: Button := mbMiddle;
      2: Button := mbRight;
    else
      Button := mbNone;
    end;
  end
  else
  begin
    case (Cb and 3) of
      0: Button := mbLeft;
      1: Button := mbMiddle;
      2: Button := mbRight;
    else
      Button := mbNone;
    end;
    if FinalByte = 'm' then
      Action := maRelease
    else
      Action := maPress;
  end;

  Event := LuxEventMouse(Cx - 1, Cy - 1, Button, Action, Mods, WheelDelta, WheelHoriz);
  Result := True;
end;

function TLuxUnixInputParser.ParseCsiKey(const Params: string; FinalByte: Char;
  out Event: TLuxEvent): Boolean;
var
  Parts: array of string;
  P0, P1, I, N: Integer;
  Part: string;
  Mods: TLuxKeyModifiers;
  Key: TLuxKey;
begin
  Result := False;
  Event := LuxEventNone;
  Mods := [];
  P0 := 1;
  P1 := 1;

  SetLength(Parts, 0);
  Part := '';
  for I := 1 to Length(Params) do
  begin
    if Params[I] = ';' then
    begin
      N := Length(Parts);
      SetLength(Parts, N + 1);
      Parts[N] := Part;
      Part := '';
    end
    else
      Part := Part + Params[I];
  end;
  if (Params <> '') or (Part <> '') then
  begin
    N := Length(Parts);
    SetLength(Parts, N + 1);
    Parts[N] := Part;
  end;

  if Length(Parts) >= 1 then
    TryStrToInt(Parts[0], P0);
  if Length(Parts) >= 2 then
  begin
    TryStrToInt(Parts[1], P1);
    Mods := ModsFromParam(P1);
  end;

  case FinalByte of
    'A': Key := lkUp;
    'B': Key := lkDown;
    'C': Key := lkRight;
    'D': Key := lkLeft;
    'H': Key := lkHome;
    'F': Key := lkEnd;
    'Z':
      begin
        Include(Mods, kmShift);
        Event := LuxEventKey(lkTab, #9, Mods, kaPress);
        Exit(True);
      end;
    '~':
      begin
        Key := KeyFromTildeCode(P0);
        if Key = lkUnknown then
          Exit(False);
        Event := LuxEventKey(Key, '', Mods, kaPress);
        Exit(True);
      end;
  else
    Exit(False);
  end;

  Event := LuxEventKey(Key, '', Mods, kaPress);
  Result := True;
end;

function TLuxUnixInputParser.TryCsi(out Event: TLuxEvent): TLuxUnixParseStatus;
var
  I: Integer;
  B: Byte;
  Body: string;
  FinalCh: Char;
begin
  Event := LuxEventNone;
  if BufLen < 3 then
    Exit(upsNone);

  if PeekByte(3) = Ord('<') then
  begin
    I := 4;
    while I <= BufLen do
    begin
      B := PeekByte(I);
      if (B = Ord('M')) or (B = Ord('m')) then
      begin
        Body := Copy(string(FBuf), 4, I - 4);
        FinalCh := Char(B);
        if ParseSgrMouse(Body, FinalCh, Event) then
        begin
          Consume(I);
          Exit(upsEvent);
        end;
        Consume(I);
        Event := LuxEventUnknown;
        Exit(upsEvent);
      end;
      if not (Char(B) in ['0'..'9', ';']) then
      begin
        Consume(I);
        Event := LuxEventUnknown;
        Exit(upsEvent);
      end;
      Inc(I);
    end;
    Exit(upsNone);
  end;

  I := 3;
  while I <= BufLen do
  begin
    B := PeekByte(I);
    if (B >= Ord('@')) and (B <= Ord('~')) then
    begin
      if I > 3 then
        Body := Copy(string(FBuf), 3, I - 3)
      else
        Body := '';
      FinalCh := Char(B);
      if ParseCsiKey(Body, FinalCh, Event) then
      begin
        Consume(I);
        Exit(upsEvent);
      end;
      Consume(I);
      Event := LuxEventUnknown;
      Exit(upsEvent);
    end;
    if not (Char(B) in ['0'..'9', ';', '?', '=', '<', '>']) then
    begin
      Consume(I);
      Event := LuxEventUnknown;
      Exit(upsEvent);
    end;
    Inc(I);
  end;
  Result := upsNone;
end;

function TLuxUnixInputParser.TrySs3(out Event: TLuxEvent): TLuxUnixParseStatus;
var
  B: Byte;
  Key: TLuxKey;
begin
  Event := LuxEventNone;
  if BufLen < 3 then
    Exit(upsNone);
  B := PeekByte(3);
  case Char(B) of
    'A': Key := lkUp;
    'B': Key := lkDown;
    'C': Key := lkRight;
    'D': Key := lkLeft;
    'H': Key := lkHome;
    'F': Key := lkEnd;
    'P': Key := lkF1;
    'Q': Key := lkF2;
    'R': Key := lkF3;
    'S': Key := lkF4;
  else
    Consume(3);
    Event := LuxEventUnknown;
    Exit(upsEvent);
  end;
  Event := LuxEventKey(Key, '', [], kaPress);
  Consume(3);
  Result := upsEvent;
end;

function TLuxUnixInputParser.TryEscape(out Event: TLuxEvent): TLuxUnixParseStatus;
var
  B: Byte;
  Ch: UnicodeString;
  Mods: TLuxKeyModifiers;
  St: TLuxUnixParseStatus;
  Saved: RawByteString;
begin
  Event := LuxEventNone;
  if PeekByte(1) <> 27 then
    Exit(upsNone);

  if BufLen = 1 then
    Exit(upsAmbiguousEsc);

  B := PeekByte(2);
  if B = Ord('[') then
    Exit(TryCsi(Event));
  if B = Ord('O') then
    Exit(TrySs3(Event));

  Mods := [kmAlt];

  if B < $80 then
  begin
    if B < 32 then
    begin
      if MakeCtrlOrSpecial(B, Mods, Event) then
      begin
        Consume(2);
        Exit(upsEvent);
      end;
      Consume(2);
      Event := LuxEventUnknown;
      Exit(upsEvent);
    end;
    if B = 127 then
    begin
      Event := LuxEventKey(lkBackspace, '', Mods, kaPress);
      Consume(2);
      Exit(upsEvent);
    end;
    Ch := UnicodeString(WideChar(B));
    Event := LuxEventKey(lkChar, Ch, Mods, kaPress);
    Consume(2);
    Exit(upsEvent);
  end;

  { ESC + multibyte UTF-8: decode UTF-8 from byte 2 onward, then add Alt. }
  Saved := FBuf;
  Consume(1);
  St := TryUtf8(Event);
  if St = upsEvent then
  begin
    if Event.Kind = ekKey then
      Include(Event.Key.Modifiers, kmAlt);
    Exit(upsEvent);
  end;
  if St = upsNone then
  begin
    { Incomplete UTF-8 — restore and wait. }
    FBuf := Saved;
    SetCodePage(RawByteString(FBuf), CP_NONE, False);
    Exit(upsNone);
  end;
  Result := St;
end;

function TLuxUnixInputParser.TryUtf8(out Event: TLuxEvent): TLuxUnixParseStatus;
var
  B0, Need, I: Integer;
  CP: Cardinal;
  Ch: UnicodeString;
begin
  Event := LuxEventNone;
  if BufLen < 1 then
    Exit(upsNone);

  B0 := PeekByte(1);
  if B0 < $80 then
  begin
    if B0 < 32 then
    begin
      if MakeCtrlOrSpecial(B0, [], Event) then
      begin
        Consume(1);
        Exit(upsEvent);
      end;
      Exit(upsNone);
    end;
    if B0 = 127 then
    begin
      Event := LuxEventKey(lkBackspace, '', [], kaPress);
      Consume(1);
      Exit(upsEvent);
    end;
    Ch := UnicodeString(WideChar(B0));
    Event := LuxEventKey(lkChar, Ch, [], kaPress);
    Consume(1);
    Exit(upsEvent);
  end;

  if (B0 and $E0) = $C0 then
    Need := 2
  else if (B0 and $F0) = $E0 then
    Need := 3
  else if (B0 and $F8) = $F0 then
    Need := 4
  else
  begin
    Consume(1);
    Event := LuxEventUnknown;
    Exit(upsEvent);
  end;

  if BufLen < Need then
    Exit(upsNone);

  for I := 2 to Need do
    if (PeekByte(I) and $C0) <> $80 then
    begin
      Consume(1);
      Event := LuxEventUnknown;
      Exit(upsEvent);
    end;

  case Need of
    2: CP := ((B0 and $1F) shl 6) or (PeekByte(2) and $3F);
    3: CP := ((B0 and $0F) shl 12) or ((PeekByte(2) and $3F) shl 6) or
         (PeekByte(3) and $3F);
    4: CP := ((B0 and $07) shl 18) or ((PeekByte(2) and $3F) shl 12) or
         ((PeekByte(3) and $3F) shl 6) or (PeekByte(4) and $3F);
  else
    CP := $FFFD;
  end;

  if CP <= $FFFF then
    Ch := UnicodeString(WideChar(CP))
  else
  begin
    CP := CP - $10000;
    Ch := UnicodeString(WideChar($D800 + (CP shr 10))) +
      UnicodeString(WideChar($DC00 + (CP and $3FF)));
  end;

  Event := LuxEventKey(lkChar, Ch, [], kaPress);
  Consume(Need);
  Result := upsEvent;
end;

function TLuxUnixInputParser.ResolveAmbiguousEscape(out Event: TLuxEvent): Boolean;
begin
  if (BufLen = 1) and (PeekByte(1) = 27) then
  begin
    Event := LuxEventKey(lkEscape, '', [], kaPress);
    Consume(1);
    Exit(True);
  end;
  Event := LuxEventNone;
  Result := False;
end;

function TLuxUnixInputParser.TryParse(out Event: TLuxEvent): TLuxUnixParseStatus;
begin
  Event := LuxEventNone;
  if BufLen < 1 then
    Exit(upsNone);
  if PeekByte(1) = 27 then
    Exit(TryEscape(Event));
  Result := TryUtf8(Event);
end;

end.
