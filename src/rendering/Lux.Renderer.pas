{ Differential ANSI renderer for virtual surfaces. Portable; no console I/O. }
unit Lux.Renderer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Color,
  Lux.Cell,
  Lux.Surface,
  Lux.Terminal.Writer,
  Lux.Terminal.Ansi;

type
  ELuxRenderer = class(Exception);

  { Compares successive frames and emits the minimal ANSI required. }
  TLuxRenderer = class
  private
    FWriter: ILuxTerminalWriter;
    FPrevious: TLuxSurface;
    FCursorX: Integer;
    FCursorY: Integer;
    FForeground: TLuxColor;
    FBackground: TLuxColor;
    FStyle: TLuxTextStyle;
    FAttrsKnown: Boolean;
    FCursorVisible: Boolean;
    FInvalidated: Boolean;
    FHasPrevious: Boolean;
    procedure ResetTrackedState;
    procedure EmitRaw(const AData: RawByteString);
    procedure EnsureCursorAt(AX, AY: Integer);
    procedure EnsureAttributes(const AForeground, ABackground: TLuxColor;
      const AStyle: TLuxTextStyle);
    procedure EmitCellGlyph(const ACell: TLuxCell);
    procedure PaintCell(AX, AY: Integer; const ACell: TLuxCell);
    procedure PaintAll(ASurface: TLuxSurface);
    procedure PaintDiff(ASurface: TLuxSurface);
    function CellDirty(ASurface: TLuxSurface; AX, AY: Integer): Boolean;
    function SameRunAttrs(const A, B: TLuxCell): Boolean;
    procedure CapturePrevious(ASurface: TLuxSurface);
    function NeedsFullRepaint(ASurface: TLuxSurface): Boolean;
  public
    constructor Create(AWriter: ILuxTerminalWriter);
    destructor Destroy; override;

    { Force the next Render to redraw the entire frame. }
    procedure Invalidate;
    { Diff ASurface against the previous frame and write ANSI output. }
    procedure Render(ASurface: TLuxSurface);

    property CursorX: Integer read FCursorX;
    property CursorY: Integer read FCursorY;
    property CursorVisible: Boolean read FCursorVisible;
    property Invalidated: Boolean read FInvalidated;
  end;

implementation

constructor TLuxRenderer.Create(AWriter: ILuxTerminalWriter);
begin
  inherited Create;
  if AWriter = nil then
    raise ELuxRenderer.Create('Renderer requires a terminal writer.');
  FWriter := AWriter;
  FPrevious := nil;
  FHasPrevious := False;
  FInvalidated := True;
  FCursorVisible := True;
  ResetTrackedState;
end;

destructor TLuxRenderer.Destroy;
begin
  FreeAndNil(FPrevious);
  FWriter := nil;
  inherited Destroy;
end;

procedure TLuxRenderer.ResetTrackedState;
begin
  FCursorX := -1;
  FCursorY := -1;
  FForeground := LuxColorDefault;
  FBackground := LuxColorDefault;
  FStyle := [];
  FAttrsKnown := False;
end;

procedure TLuxRenderer.EmitRaw(const AData: RawByteString);
begin
  if AData <> '' then
    FWriter.WriteRaw(AData);
end;

procedure TLuxRenderer.Invalidate;
begin
  FInvalidated := True;
end;

procedure TLuxRenderer.EnsureCursorAt(AX, AY: Integer);
begin
  if (FCursorX = AX) and (FCursorY = AY) then
    Exit;
  EmitRaw(LuxAnsiCursorMoveTo(AY + 1, AX + 1));
  FCursorX := AX;
  FCursorY := AY;
end;

procedure TLuxRenderer.EnsureAttributes(const AForeground, ABackground: TLuxColor;
  const AStyle: TLuxTextStyle);
var
  NeedStyleReset: Boolean;
begin
  if FAttrsKnown and
     LuxColorEqual(FForeground, AForeground) and
     LuxColorEqual(FBackground, ABackground) and
     LuxTextStyleEqual(FStyle, AStyle) then
    Exit;

  NeedStyleReset := (not FAttrsKnown) or (not LuxTextStyleEqual(FStyle, AStyle));
  if NeedStyleReset then
  begin
    EmitRaw(LuxAnsiResetAttributes);
    EmitRaw(LuxAnsiApplyStyle(AStyle));
    EmitRaw(LuxAnsiApplyColor(AForeground, True));
    EmitRaw(LuxAnsiApplyColor(ABackground, False));
  end
  else
  begin
    if not LuxColorEqual(FForeground, AForeground) then
      EmitRaw(LuxAnsiApplyColor(AForeground, True));
    if not LuxColorEqual(FBackground, ABackground) then
      EmitRaw(LuxAnsiApplyColor(ABackground, False));
  end;

  FForeground := AForeground;
  FBackground := ABackground;
  FStyle := AStyle;
  FAttrsKnown := True;
end;

procedure TLuxRenderer.EmitCellGlyph(const ACell: TLuxCell);
var
  Glyph: UnicodeString;
  Advance: Integer;
begin
  if ACell.Width = 0 then
    Exit;

  Glyph := ACell.Text;
  if Glyph = '' then
    Glyph := ' ';

  FWriter.WriteText(Glyph);

  Advance := ACell.Width;
  if Advance < 1 then
    Advance := 1;
  Inc(FCursorX, Advance);
end;

procedure TLuxRenderer.PaintCell(AX, AY: Integer; const ACell: TLuxCell);
begin
  if ACell.Width = 0 then
    Exit;
  EnsureCursorAt(AX, AY);
  EnsureAttributes(ACell.Foreground, ACell.Background, ACell.Style);
  EmitCellGlyph(ACell);
end;

function TLuxRenderer.SameRunAttrs(const A, B: TLuxCell): Boolean;
begin
  Result := LuxColorEqual(A.Foreground, B.Foreground) and
    LuxColorEqual(A.Background, B.Background) and
    LuxTextStyleEqual(A.Style, B.Style);
end;

function TLuxRenderer.CellDirty(ASurface: TLuxSurface; AX, AY: Integer): Boolean;
begin
  if not FHasPrevious then
    Exit(True);
  Result := not LuxCellEqual(ASurface.Cells[AX, AY], FPrevious.Cells[AX, AY]);
end;

procedure TLuxRenderer.PaintAll(ASurface: TLuxSurface);
var
  X, Y: Integer;
  Cell: TLuxCell;
begin
  EmitRaw(LuxAnsiHideCursor);
  FCursorVisible := False;
  EmitRaw(LuxAnsiResetAttributes);
  EmitRaw(LuxAnsiClearScreen);
  EmitRaw(LuxAnsiCursorHome);
  ResetTrackedState;
  FCursorX := 0;
  FCursorY := 0;
  FAttrsKnown := True;
  FForeground := LuxColorDefault;
  FBackground := LuxColorDefault;
  FStyle := [];

  for Y := 0 to ASurface.Height - 1 do
  begin
    X := 0;
    while X < ASurface.Width do
    begin
      Cell := ASurface.Cells[X, Y];
      if Cell.Width = 0 then
      begin
        Inc(X);
        Continue;
      end;
      PaintCell(X, Y, Cell);
      if Cell.Width > 1 then
        Inc(X, Cell.Width)
      else
        Inc(X);
    end;
  end;
end;

procedure TLuxRenderer.PaintDiff(ASurface: TLuxSurface);
var
  X, Y, RunStart, RunX: Integer;
  Cell, RunCell: TLuxCell;
begin
  for Y := 0 to ASurface.Height - 1 do
  begin
    X := 0;
    while X < ASurface.Width do
    begin
      Cell := ASurface.Cells[X, Y];
      if Cell.Width = 0 then
      begin
        Inc(X);
        Continue;
      end;

      if not CellDirty(ASurface, X, Y) then
      begin
        if Cell.Width > 1 then
          Inc(X, Cell.Width)
        else
          Inc(X);
        Continue;
      end;

      { Grow a contiguous dirty run with identical attributes on this row. }
      RunStart := X;
      RunCell := Cell;
      RunX := X;
      EnsureCursorAt(RunStart, Y);
      EnsureAttributes(RunCell.Foreground, RunCell.Background, RunCell.Style);

      while RunX < ASurface.Width do
      begin
        Cell := ASurface.Cells[RunX, Y];
        if Cell.Width = 0 then
        begin
          Inc(RunX);
          Continue;
        end;
        if not CellDirty(ASurface, RunX, Y) then
          Break;
        if not SameRunAttrs(RunCell, Cell) then
          Break;
        EmitCellGlyph(Cell);
        if Cell.Width > 1 then
          Inc(RunX, Cell.Width)
        else
          Inc(RunX);
      end;
      X := RunX;
    end;
  end;
end;

function TLuxRenderer.NeedsFullRepaint(ASurface: TLuxSurface): Boolean;
begin
  Result := FInvalidated or (not FHasPrevious) or (FPrevious = nil) or
    (FPrevious.Width <> ASurface.Width) or (FPrevious.Height <> ASurface.Height);
end;

procedure TLuxRenderer.CapturePrevious(ASurface: TLuxSurface);
begin
  if (FPrevious = nil) or (FPrevious.Width <> ASurface.Width) or
     (FPrevious.Height <> ASurface.Height) then
  begin
    FreeAndNil(FPrevious);
    FPrevious := TLuxSurface.Create(ASurface.Width, ASurface.Height);
  end;

  FPrevious.AssignCellsFrom(ASurface);
  FHasPrevious := True;
end;

procedure TLuxRenderer.Render(ASurface: TLuxSurface);
begin
  if ASurface = nil then
    raise ELuxRenderer.Create('Renderer.Render requires a surface.');

  if NeedsFullRepaint(ASurface) then
    PaintAll(ASurface)
  else
    PaintDiff(ASurface);

  CapturePrevious(ASurface);
  FInvalidated := False;
  FWriter.Flush;
end;

end.
