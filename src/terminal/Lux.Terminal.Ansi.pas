{ Portable ANSI/VT sequence builders. No console I/O. }
unit Lux.Terminal.Ansi;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Color;

const
  LuxAnsiEsc = #27;

{ Cursor is addressed with 1-based row/column as required by ANSI. }
function LuxAnsiCursorMoveTo(ARow1Based, AColumn1Based: Integer): RawByteString;
function LuxAnsiCursorHome: RawByteString;
function LuxAnsiHideCursor: RawByteString;
function LuxAnsiShowCursor: RawByteString;

function LuxAnsiResetAttributes: RawByteString;
function LuxAnsiFgDefault: RawByteString;
function LuxAnsiBgDefault: RawByteString;
function LuxAnsiFgRGB(AR, AG, AB: Byte): RawByteString;
function LuxAnsiBgRGB(AR, AG, AB: Byte): RawByteString;
function LuxAnsiApplyColor(const AColor: TLuxColor; AForeground: Boolean): RawByteString;
function LuxAnsiApplyStyle(const AStyle: TLuxTextStyle): RawByteString;

function LuxAnsiClearScreen: RawByteString;
function LuxAnsiClearLine: RawByteString;

implementation

function LuxAnsiCSI(const AParams: RawByteString): RawByteString;
begin
  Result := LuxAnsiEsc + '[' + AParams;
end;

function LuxAnsiCursorMoveTo(ARow1Based, AColumn1Based: Integer): RawByteString;
begin
  if ARow1Based < 1 then
    ARow1Based := 1;
  if AColumn1Based < 1 then
    AColumn1Based := 1;
  Result := LuxAnsiCSI(RawByteString(IntToStr(ARow1Based)) + ';' +
    RawByteString(IntToStr(AColumn1Based)) + 'H');
end;

function LuxAnsiCursorHome: RawByteString;
begin
  Result := LuxAnsiCursorMoveTo(1, 1);
end;

function LuxAnsiHideCursor: RawByteString;
begin
  Result := LuxAnsiCSI('?25l');
end;

function LuxAnsiShowCursor: RawByteString;
begin
  Result := LuxAnsiCSI('?25h');
end;

function LuxAnsiResetAttributes: RawByteString;
begin
  Result := LuxAnsiCSI('0m');
end;

function LuxAnsiFgDefault: RawByteString;
begin
  Result := LuxAnsiCSI('39m');
end;

function LuxAnsiBgDefault: RawByteString;
begin
  Result := LuxAnsiCSI('49m');
end;

function LuxAnsiFgRGB(AR, AG, AB: Byte): RawByteString;
begin
  Result := LuxAnsiCSI('38;2;' + RawByteString(IntToStr(AR)) + ';' +
    RawByteString(IntToStr(AG)) + ';' + RawByteString(IntToStr(AB)) + 'm');
end;

function LuxAnsiBgRGB(AR, AG, AB: Byte): RawByteString;
begin
  Result := LuxAnsiCSI('48;2;' + RawByteString(IntToStr(AR)) + ';' +
    RawByteString(IntToStr(AG)) + ';' + RawByteString(IntToStr(AB)) + 'm');
end;

function LuxAnsiApplyColor(const AColor: TLuxColor; AForeground: Boolean): RawByteString;
begin
  case AColor.Kind of
    ckRGB:
      if AForeground then
        Result := LuxAnsiFgRGB(AColor.R, AColor.G, AColor.B)
      else
        Result := LuxAnsiBgRGB(AColor.R, AColor.G, AColor.B);
    ckDefault, ckInherit:
      if AForeground then
        Result := LuxAnsiFgDefault
      else
        Result := LuxAnsiBgDefault;
  else
    if AForeground then
      Result := LuxAnsiFgDefault
    else
      Result := LuxAnsiBgDefault;
  end;
end;

function LuxAnsiApplyStyle(const AStyle: TLuxTextStyle): RawByteString;
begin
  Result := '';
  if tsBold in AStyle then
    Result := Result + LuxAnsiCSI('1m');
  if tsDim in AStyle then
    Result := Result + LuxAnsiCSI('2m');
  if tsItalic in AStyle then
    Result := Result + LuxAnsiCSI('3m');
  if tsUnderline in AStyle then
    Result := Result + LuxAnsiCSI('4m');
  if tsBlink in AStyle then
    Result := Result + LuxAnsiCSI('5m');
  if tsReverse in AStyle then
    Result := Result + LuxAnsiCSI('7m');
  if tsStrikeout in AStyle then
    Result := Result + LuxAnsiCSI('9m');
end;

function LuxAnsiClearScreen: RawByteString;
begin
  Result := LuxAnsiCSI('2J');
end;

function LuxAnsiClearLine: RawByteString;
begin
  Result := LuxAnsiCSI('2K');
end;

end.
