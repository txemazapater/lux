{ Differential ANSI renderer for virtual surfaces. Portable; no console I/O. }
unit Lux.Renderer;

{$mode objfpc}{$H+}

{ Define LUX_RESIZE_TRACE to log full/diff paint choices to stderr. }
{.$DEFINE LUX_RESIZE_TRACE}

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

  { Compares successive frames and emits the minimal ANSI required.

    Full repaint means every cell of the current surface is rewritten. It does
    not imply erasing the terminal first (no ESC[2J). When the surface shrinks,
    leftover glyphs outside the new bounds are cleared with erase-to-end
    sequences so the update stays differential in spirit. }
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
    FLastWasFullRepaint: Boolean;
    procedure ResetTrackedState;
    procedure EmitRaw(const AData: RawByteString);
    procedure EnsureCursorHidden;
    procedure EnsureCursorAt(AX, AY: Integer);
    procedure EnsureAttributes(const AForeground, ABackground: TLuxColor;
      const AStyle: TLuxTextStyle);
    procedure EmitCellGlyph(const ACell: TLuxCell);
    procedure PaintCell(AX, AY: Integer; const ACell: TLuxCell);
    procedure EraseShrinkArtifacts(AOldWidth, AOldHeight, ANewWidth,
      ANewHeight: Integer);
    procedure PaintAll(ASurface: TLuxSurface);
    procedure PaintDiff(ASurface: TLuxSurface);
    function CellDirty(ASurface: TLuxSurface; AX, AY: Integer): Boolean;
    function SameRunAttrs(const A, B: TLuxCell): Boolean;
    procedure CapturePrevious(ASurface: TLuxSurface);
    function NeedsFullRepaint(ASurface: TLuxSurface): Boolean;
  public
    constructor Create(AWriter: ILuxTerminalWriter);
    destructor Destroy; override;

    { Force the next Render to rewrite every cell (no terminal clear). }
    procedure Invalidate;
    { Diff ASurface against the previous frame and write ANSI output.
      AFlush controls whether the writer is flushed before return. }
    procedure Render(ASurface: TLuxSurface; AFlush: Boolean = True);
    { Sync tracked paint cursor after an external caret commit. }
    procedure SyncExternalCursor(AX, AY: Integer; AVisible: Boolean);

    property CursorX: Integer read FCursorX;
    property CursorY: Integer read FCursorY;
    property CursorVisible: Boolean read FCursorVisible;
    property Invalidated: Boolean read FInvalidated;
    property LastWasFullRepaint: Boolean read FLastWasFullRepaint;
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
  FLastWasFullRepaint := False;
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

procedure TLuxRenderer.EnsureCursorHidden;
begin
  if not FCursorVisible then
    Exit;
  EmitRaw(LuxAnsiHideCursor);
  FCursorVisible := False;
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

procedure TLuxRenderer.EraseShrinkArtifacts(AOldWidth, AOldHeight, ANewWidth,
  ANewHeight: Integer);
var
  Y: Integer;
begin
  if (AOldWidth <= ANewWidth) and (AOldHeight <= ANewHeight) then
    Exit;

  EmitRaw(LuxAnsiResetAttributes);
  FAttrsKnown := True;
  FForeground := LuxColorDefault;
  FBackground := LuxColorDefault;
  FStyle := [];

  if AOldWidth > ANewWidth then
    for Y := 0 to ANewHeight - 1 do
    begin
      EnsureCursorAt(ANewWidth, Y);
      EmitRaw(LuxAnsiEraseToEndOfLine);
    end;

  if AOldHeight > ANewHeight then
  begin
    EnsureCursorAt(0, ANewHeight);
    EmitRaw(LuxAnsiEraseToEndOfScreen);
  end;
end;

procedure TLuxRenderer.PaintAll(ASurface: TLuxSurface);
var
  X, Y: Integer;
  Cell: TLuxCell;
  OldW, OldH: Integer;
begin
  OldW := 0;
  OldH := 0;
  if FHasPrevious and (FPrevious <> nil) then
  begin
    OldW := FPrevious.Width;
    OldH := FPrevious.Height;
  end;

  EnsureCursorHidden;
  EmitRaw(LuxAnsiResetAttributes);
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

  if (OldW > 0) and (OldH > 0) then
    EraseShrinkArtifacts(OldW, OldH, ASurface.Width, ASurface.Height);
end;

procedure TLuxRenderer.PaintDiff(ASurface: TLuxSurface);
var
  X, Y, RunStart, RunX: Integer;
  Cell, RunCell: TLuxCell;
begin
  EnsureCursorHidden;
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

procedure TLuxRenderer.Render(ASurface: TLuxSurface; AFlush: Boolean);
var
  Full: Boolean;
begin
  if ASurface = nil then
    raise ELuxRenderer.Create('Renderer.Render requires a surface.');

  Full := NeedsFullRepaint(ASurface);
  FLastWasFullRepaint := Full;

  {$IFDEF LUX_RESIZE_TRACE}
  WriteLn(StdErr, Format('LUX render: full=%s size=%dx%d invalidated=%s',
    [BoolToStr(Full, True), ASurface.Width, ASurface.Height,
     BoolToStr(FInvalidated, True)]));
  {$ENDIF}

  if Full then
    PaintAll(ASurface)
  else
    PaintDiff(ASurface);

  CapturePrevious(ASurface);
  FInvalidated := False;
  if AFlush then
    FWriter.Flush;
end;

procedure TLuxRenderer.SyncExternalCursor(AX, AY: Integer; AVisible: Boolean);
begin
  FCursorX := AX;
  FCursorY := AY;
  FCursorVisible := AVisible;
end;

end.
