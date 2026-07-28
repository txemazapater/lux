{ Colour and text style value types for LUX cells. }
unit Lux.Color;

{$mode objfpc}{$H+}

interface

type
  { How a colour value should be interpreted. }
  TLuxColorKind = (
    ckDefault, { terminal / theme default }
    ckInherit, { take colour from parent or previous cell }
    ckRGB      { explicit 24-bit colour }
  );

  { Portable colour value. RGB channels are meaningful only for ckRGB. }
  TLuxColor = record
    Kind: TLuxColorKind;
    R: Byte;
    G: Byte;
    B: Byte;
  end;

  { ANSI-style text attributes applied to a cell. }
  TLuxTextStyle = set of (
    tsBold,
    tsDim,
    tsItalic,
    tsUnderline,
    tsBlink,
    tsReverse,
    tsStrikeout
  );

function LuxColorDefault: TLuxColor;
function LuxColorInherit: TLuxColor;
function LuxColorRGB(AR, AG, AB: Byte): TLuxColor;
function LuxColorEqual(const A, B: TLuxColor): Boolean;
function LuxTextStyleEqual(const A, B: TLuxTextStyle): Boolean;

implementation

function LuxColorDefault: TLuxColor;
begin
  Result.Kind := ckDefault;
  Result.R := 0;
  Result.G := 0;
  Result.B := 0;
end;

function LuxColorInherit: TLuxColor;
begin
  Result.Kind := ckInherit;
  Result.R := 0;
  Result.G := 0;
  Result.B := 0;
end;

function LuxColorRGB(AR, AG, AB: Byte): TLuxColor;
begin
  Result.Kind := ckRGB;
  Result.R := AR;
  Result.G := AG;
  Result.B := AB;
end;

function LuxColorEqual(const A, B: TLuxColor): Boolean;
begin
  if A.Kind <> B.Kind then
    Exit(False);
  if A.Kind = ckRGB then
    Result := (A.R = B.R) and (A.G = B.G) and (A.B = B.B)
  else
    Result := True;
end;

function LuxTextStyleEqual(const A, B: TLuxTextStyle): Boolean;
begin
  Result := A = B;
end;

end.
