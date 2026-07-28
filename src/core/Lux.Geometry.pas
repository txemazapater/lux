{ Portable 2D geometry helpers for LUX. }
unit Lux.Geometry;

{$mode objfpc}{$H+}

interface

type
  { Integer point in surface or layout coordinates. }
  TLuxPoint = record
    X: Integer;
    Y: Integer;
  end;

  { Non-negative size in cells. }
  TLuxSize = record
    Width: Integer;
    Height: Integer;
  end;

  { Axis-aligned rectangle using origin plus extent. }
  TLuxRect = record
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
  end;

function LuxPoint(AX, AY: Integer): TLuxPoint;
function LuxSize(AWidth, AHeight: Integer): TLuxSize;
function LuxRect(ALeft, ATop, AWidth, AHeight: Integer): TLuxRect;
function LuxRectBounds(ALeft, ATop, ARight, ABottom: Integer): TLuxRect;

function LuxPointEqual(const A, B: TLuxPoint): Boolean;
function LuxSizeEqual(const A, B: TLuxSize): Boolean;
function LuxRectEqual(const A, B: TLuxRect): Boolean;

function LuxRectRight(const R: TLuxRect): Integer;
function LuxRectBottom(const R: TLuxRect): Integer;
function LuxRectIsEmpty(const R: TLuxRect): Boolean;
function LuxRectContainsPoint(const R: TLuxRect; const P: TLuxPoint): Boolean;
function LuxRectContainsXY(const R: TLuxRect; AX, AY: Integer): Boolean;
function LuxRectIntersect(const A, B: TLuxRect): TLuxRect;
function LuxRectNormalize(const R: TLuxRect): TLuxRect;

implementation

function LuxPoint(AX, AY: Integer): TLuxPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function LuxSize(AWidth, AHeight: Integer): TLuxSize;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

function LuxRect(ALeft, ATop, AWidth, AHeight: Integer): TLuxRect;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

function LuxRectBounds(ALeft, ATop, ARight, ABottom: Integer): TLuxRect;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := ARight - ALeft;
  Result.Height := ABottom - ATop;
end;

function LuxPointEqual(const A, B: TLuxPoint): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

function LuxSizeEqual(const A, B: TLuxSize): Boolean;
begin
  Result := (A.Width = B.Width) and (A.Height = B.Height);
end;

function LuxRectEqual(const A, B: TLuxRect): Boolean;
begin
  Result := (A.Left = B.Left) and (A.Top = B.Top) and
    (A.Width = B.Width) and (A.Height = B.Height);
end;

function LuxRectRight(const R: TLuxRect): Integer;
begin
  Result := R.Left + R.Width;
end;

function LuxRectBottom(const R: TLuxRect): Integer;
begin
  Result := R.Top + R.Height;
end;

function LuxRectIsEmpty(const R: TLuxRect): Boolean;
begin
  Result := (R.Width <= 0) or (R.Height <= 0);
end;

function LuxRectContainsPoint(const R: TLuxRect; const P: TLuxPoint): Boolean;
begin
  Result := LuxRectContainsXY(R, P.X, P.Y);
end;

function LuxRectContainsXY(const R: TLuxRect; AX, AY: Integer): Boolean;
begin
  Result := (not LuxRectIsEmpty(R)) and
    (AX >= R.Left) and (AX < LuxRectRight(R)) and
    (AY >= R.Top) and (AY < LuxRectBottom(R));
end;

function LuxRectIntersect(const A, B: TLuxRect): TLuxRect;
var
  L, T, Ri, Bo: Integer;
begin
  L := A.Left;
  if B.Left > L then
    L := B.Left;
  T := A.Top;
  if B.Top > T then
    T := B.Top;
  Ri := LuxRectRight(A);
  if LuxRectRight(B) < Ri then
    Ri := LuxRectRight(B);
  Bo := LuxRectBottom(A);
  if LuxRectBottom(B) < Bo then
    Bo := LuxRectBottom(B);
  Result := LuxRectBounds(L, T, Ri, Bo);
  if (Result.Width < 0) or (Result.Height < 0) then
  begin
    Result.Width := 0;
    Result.Height := 0;
  end;
end;

function LuxRectNormalize(const R: TLuxRect): TLuxRect;
begin
  Result := R;
  if Result.Width < 0 then
  begin
    Result.Left := Result.Left + Result.Width;
    Result.Width := -Result.Width;
  end;
  if Result.Height < 0 then
  begin
    Result.Top := Result.Top + Result.Height;
    Result.Height := -Result.Height;
  end;
end;

end.
