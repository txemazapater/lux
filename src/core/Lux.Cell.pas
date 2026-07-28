{ Virtual screen cell model and display-width helpers. }
unit Lux.Cell;

{$mode objfpc}{$H+}

interface

uses
  Lux.Color;

type
  { One terminal cell. Width is the display column span:
    0 = continuation of a preceding wide character,
    1 = narrow character,
    2 = wide character occupying this cell and the next. }
  TLuxCell = record
    Text: UnicodeString;
    Foreground: TLuxColor;
    Background: TLuxColor;
    Style: TLuxTextStyle;
    Width: Byte;
  end;

function LuxCellEmpty: TLuxCell;
function LuxCellMake(const AText: UnicodeString; AWidth: Byte;
  const AForeground, ABackground: TLuxColor;
  const AStyle: TLuxTextStyle): TLuxCell;
function LuxCellContinuation: TLuxCell;
function LuxCellEqual(const A, B: TLuxCell): Boolean;

{ Approximate terminal display width for a Unicode scalar value. }
function LuxCodepointWidth(ACodepoint: Cardinal): Byte;

{ Read the next UTF-16 code point from S starting at Index (1-based).
  Advances Index past the consumed units. Returns False at end of string. }
function LuxNextCodepoint(const S: UnicodeString; var Index: Integer;
  out ACodepoint: Cardinal): Boolean;

implementation

function LuxCellEmpty: TLuxCell;
begin
  Result.Text := ' ';
  Result.Foreground := LuxColorDefault;
  Result.Background := LuxColorDefault;
  Result.Style := [];
  Result.Width := 1;
end;

function LuxCellMake(const AText: UnicodeString; AWidth: Byte;
  const AForeground, ABackground: TLuxColor;
  const AStyle: TLuxTextStyle): TLuxCell;
begin
  Result.Text := AText;
  Result.Foreground := AForeground;
  Result.Background := ABackground;
  Result.Style := AStyle;
  Result.Width := AWidth;
end;

function LuxCellContinuation: TLuxCell;
begin
  Result.Text := '';
  Result.Foreground := LuxColorDefault;
  Result.Background := LuxColorDefault;
  Result.Style := [];
  Result.Width := 0;
end;

function LuxCellEqual(const A, B: TLuxCell): Boolean;
begin
  Result := (A.Text = B.Text) and
    LuxColorEqual(A.Foreground, B.Foreground) and
    LuxColorEqual(A.Background, B.Background) and
    LuxTextStyleEqual(A.Style, B.Style) and
    (A.Width = B.Width);
end;

function LuxCodepointWidth(ACodepoint: Cardinal): Byte;
begin
  { Zero-width / non-spacing marks (selected common ranges). }
  if ((ACodepoint >= $0300) and (ACodepoint <= $036F)) or
     ((ACodepoint >= $1AB0) and (ACodepoint <= $1AFF)) or
     ((ACodepoint >= $1DC0) and (ACodepoint <= $1DFF)) or
     ((ACodepoint >= $20D0) and (ACodepoint <= $20FF)) or
     ((ACodepoint >= $FE20) and (ACodepoint <= $FE2F)) then
    Exit(0);

  { C0 controls are not printable content for surfaces. }
  if ACodepoint < $20 then
    Exit(0);
  if (ACodepoint >= $7F) and (ACodepoint <= $9F) then
    Exit(0);

  { East Asian Wide / Fullwidth approximations used by terminals. }
  if ((ACodepoint >= $1100) and (ACodepoint <= $115F)) or
     ((ACodepoint >= $2329) and (ACodepoint <= $232A)) or
     ((ACodepoint >= $2E80) and (ACodepoint <= $A4CF)) or
     ((ACodepoint >= $AC00) and (ACodepoint <= $D7A3)) or
     ((ACodepoint >= $F900) and (ACodepoint <= $FAFF)) or
     ((ACodepoint >= $FE10) and (ACodepoint <= $FE19)) or
     ((ACodepoint >= $FE30) and (ACodepoint <= $FE6F)) or
     ((ACodepoint >= $FF00) and (ACodepoint <= $FF60)) or
     ((ACodepoint >= $FFE0) and (ACodepoint <= $FFE6)) or
     ((ACodepoint >= $1F300) and (ACodepoint <= $1F64F)) or
     ((ACodepoint >= $1F900) and (ACodepoint <= $1F9FF)) or
     ((ACodepoint >= $20000) and (ACodepoint <= $3FFFD)) then
    Exit(2);

  Result := 1;
end;

function LuxNextCodepoint(const S: UnicodeString; var Index: Integer;
  out ACodepoint: Cardinal): Boolean;
var
  W, W2: WideChar;
begin
  if (Index < 1) or (Index > Length(S)) then
  begin
    ACodepoint := 0;
    Exit(False);
  end;

  W := S[Index];
  Inc(Index);

  { Decode UTF-16 surrogate pairs. }
  if (Ord(W) >= $D800) and (Ord(W) <= $DBFF) then
  begin
    if Index <= Length(S) then
    begin
      W2 := S[Index];
      if (Ord(W2) >= $DC00) and (Ord(W2) <= $DFFF) then
      begin
        Inc(Index);
        ACodepoint := $10000 +
          ((Cardinal(Ord(W) - $D800) shl 10) or Cardinal(Ord(W2) - $DC00));
        Exit(True);
      end;
    end;
  end;

  ACodepoint := Ord(W);
  Result := True;
end;

end.
