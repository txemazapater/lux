{ In-memory virtual cell surface. Portable and console-free. }
unit Lux.Surface;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell;

type
  ELuxSurface = class(Exception);

  { Rectangular matrix of TLuxCell values. Drawing is clipped safely. }
  TLuxSurface = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FCells: array of TLuxCell;
    function IndexOf(AX, AY: Integer): Integer; inline;
    function GetCell(AX, AY: Integer): TLuxCell;
    procedure SetCell(AX, AY: Integer; const AValue: TLuxCell);
    procedure EnsureInBounds(AX, AY: Integer);
    procedure AllocateCells;
    procedure ClearWidePairAt(AX, AY: Integer);
  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;

    procedure Resize(AWidth, AHeight: Integer);
    procedure Clear;
    procedure Fill(const ACell: TLuxCell);
    procedure FillRect(const ARect: TLuxRect; const ACell: TLuxCell);
    procedure PutCell(AX, AY: Integer; const ACell: TLuxCell);
    procedure PutText(AX, AY: Integer; const AText: UnicodeString); overload;
    procedure PutText(AX, AY: Integer; const AText: UnicodeString;
      const AForeground, ABackground: TLuxColor;
      const AStyle: TLuxTextStyle); overload;

    function Contains(AX, AY: Integer): Boolean;
    function Bounds: TLuxRect;
    function EqualTo(AOther: TLuxSurface): Boolean;

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Cells[AX, AY: Integer]: TLuxCell read GetCell write SetCell; default;
  end;

implementation

constructor TLuxSurface.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  if (AWidth < 0) or (AHeight < 0) then
    raise ELuxSurface.Create('Surface dimensions must be non-negative.');
  FWidth := AWidth;
  FHeight := AHeight;
  AllocateCells;
  Clear;
end;

destructor TLuxSurface.Destroy;
begin
  SetLength(FCells, 0);
  inherited Destroy;
end;

function TLuxSurface.IndexOf(AX, AY: Integer): Integer;
begin
  Result := AY * FWidth + AX;
end;

procedure TLuxSurface.EnsureInBounds(AX, AY: Integer);
begin
  if not Contains(AX, AY) then
    raise ELuxSurface.CreateFmt('Cell coordinates out of bounds: (%d,%d).', [AX, AY]);
end;

procedure TLuxSurface.AllocateCells;
begin
  SetLength(FCells, FWidth * FHeight);
end;

function TLuxSurface.Contains(AX, AY: Integer): Boolean;
begin
  Result := (AX >= 0) and (AY >= 0) and (AX < FWidth) and (AY < FHeight);
end;

function TLuxSurface.Bounds: TLuxRect;
begin
  Result := LuxRect(0, 0, FWidth, FHeight);
end;

function TLuxSurface.GetCell(AX, AY: Integer): TLuxCell;
begin
  EnsureInBounds(AX, AY);
  Result := FCells[IndexOf(AX, AY)];
end;

procedure TLuxSurface.ClearWidePairAt(AX, AY: Integer);
var
  Existing: TLuxCell;
begin
  if not Contains(AX, AY) then
    Exit;
  Existing := FCells[IndexOf(AX, AY)];
  if Existing.Width = 2 then
  begin
    FCells[IndexOf(AX, AY)] := LuxCellEmpty;
    if Contains(AX + 1, AY) and (FCells[IndexOf(AX + 1, AY)].Width = 0) then
      FCells[IndexOf(AX + 1, AY)] := LuxCellEmpty;
  end
  else if Existing.Width = 0 then
  begin
    FCells[IndexOf(AX, AY)] := LuxCellEmpty;
    if Contains(AX - 1, AY) and (FCells[IndexOf(AX - 1, AY)].Width = 2) then
      FCells[IndexOf(AX - 1, AY)] := LuxCellEmpty;
  end;
end;

procedure TLuxSurface.SetCell(AX, AY: Integer; const AValue: TLuxCell);
begin
  PutCell(AX, AY, AValue);
end;

procedure TLuxSurface.PutCell(AX, AY: Integer; const ACell: TLuxCell);
begin
  if not Contains(AX, AY) then
    Exit;

  ClearWidePairAt(AX, AY);
  if (ACell.Width = 2) and Contains(AX + 1, AY) then
    ClearWidePairAt(AX + 1, AY)
  else if (ACell.Width = 2) and not Contains(AX + 1, AY) then
  begin
    { Wide glyph that does not fit is stored as a narrow replacement space. }
    FCells[IndexOf(AX, AY)] := LuxCellMake(' ', 1, ACell.Foreground,
      ACell.Background, ACell.Style);
    Exit;
  end;

  FCells[IndexOf(AX, AY)] := ACell;
  if ACell.Width = 2 then
  begin
    ClearWidePairAt(AX + 1, AY);
    FCells[IndexOf(AX + 1, AY)] := LuxCellContinuation;
    FCells[IndexOf(AX + 1, AY)].Foreground := ACell.Foreground;
    FCells[IndexOf(AX + 1, AY)].Background := ACell.Background;
    FCells[IndexOf(AX + 1, AY)].Style := ACell.Style;
  end;
end;

procedure TLuxSurface.Resize(AWidth, AHeight: Integer);
var
  OldWidth, OldHeight, X, Y, CopyW, CopyH: Integer;
  OldCells: array of TLuxCell;
begin
  if (AWidth < 0) or (AHeight < 0) then
    raise ELuxSurface.Create('Surface dimensions must be non-negative.');
  if (AWidth = FWidth) and (AHeight = FHeight) then
    Exit;

  OldWidth := FWidth;
  OldHeight := FHeight;
  OldCells := FCells;

  FWidth := AWidth;
  FHeight := AHeight;
  AllocateCells;
  Clear;

  CopyW := OldWidth;
  if FWidth < CopyW then
    CopyW := FWidth;
  CopyH := OldHeight;
  if FHeight < CopyH then
    CopyH := FHeight;

  for Y := 0 to CopyH - 1 do
    for X := 0 to CopyW - 1 do
      FCells[IndexOf(X, Y)] := OldCells[Y * OldWidth + X];
end;

procedure TLuxSurface.Clear;
begin
  Fill(LuxCellEmpty);
end;

procedure TLuxSurface.Fill(const ACell: TLuxCell);
begin
  FillRect(Bounds, ACell);
end;

procedure TLuxSurface.FillRect(const ARect: TLuxRect; const ACell: TLuxCell);
var
  Clip: TLuxRect;
  X, Y: Integer;
  CellToWrite: TLuxCell;
begin
  Clip := LuxRectIntersect(ARect, Bounds);
  if LuxRectIsEmpty(Clip) then
    Exit;

  { Filling with wide cells is undefined for bulk fill; force narrow content. }
  CellToWrite := ACell;
  if CellToWrite.Width = 2 then
    CellToWrite.Width := 1;
  if CellToWrite.Width = 0 then
    CellToWrite := LuxCellEmpty;

  for Y := Clip.Top to LuxRectBottom(Clip) - 1 do
    for X := Clip.Left to LuxRectRight(Clip) - 1 do
      FCells[IndexOf(X, Y)] := CellToWrite;
end;

procedure TLuxSurface.PutText(AX, AY: Integer; const AText: UnicodeString);
begin
  PutText(AX, AY, AText, LuxColorDefault, LuxColorDefault, []);
end;

procedure TLuxSurface.PutText(AX, AY: Integer; const AText: UnicodeString;
  const AForeground, ABackground: TLuxColor;
  const AStyle: TLuxTextStyle);
var
  Index, CursorX: Integer;
  Codepoint: Cardinal;
  Glyph: UnicodeString;
  W: Byte;
  Primary: TLuxCell;
begin
  if (AY < 0) or (AY >= FHeight) then
    Exit;

  Index := 1;
  CursorX := AX;
  while LuxNextCodepoint(AText, Index, Codepoint) do
  begin
    W := LuxCodepointWidth(Codepoint);
    if W = 0 then
      Continue;

    if Codepoint <= $FFFF then
      Glyph := WideChar(Codepoint)
    else
      Glyph :=
        WideChar($D800 + ((Codepoint - $10000) shr 10)) +
        WideChar($DC00 + ((Codepoint - $10000) and $3FF));

    if CursorX >= FWidth then
      Exit;
    if CursorX < 0 then
    begin
      Inc(CursorX, W);
      Continue;
    end;

    if (W = 2) and (CursorX + 1 >= FWidth) then
    begin
      Primary := LuxCellMake(' ', 1, AForeground, ABackground, AStyle);
      PutCell(CursorX, AY, Primary);
      Inc(CursorX);
      Continue;
    end;

    Primary := LuxCellMake(Glyph, W, AForeground, ABackground, AStyle);
    PutCell(CursorX, AY, Primary);
    Inc(CursorX, W);
  end;
end;

function TLuxSurface.EqualTo(AOther: TLuxSurface): Boolean;
var
  I: Integer;
begin
  if AOther = nil then
    Exit(False);
  if (FWidth <> AOther.FWidth) or (FHeight <> AOther.FHeight) then
    Exit(False);
  for I := 0 to High(FCells) do
    if not LuxCellEqual(FCells[I], AOther.FCells[I]) then
      Exit(False);
  Result := True;
end;

end.
