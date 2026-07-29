{ Portable logical cursor request and commit. No platform APIs. }
unit Lux.Cursor;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Terminal.Writer;

type
  { Logical caret shapes. Unsupported shapes degrade via capabilities. }
  TLuxCursorShape = (
    lcsDefault,
    lcsBlock,
    lcsUnderline,
    lcsBar
  );

  { What the attached terminal can honour. Unsupported fields are ignored
    at commit time so limited backends still behave correctly. }
  TLuxCursorCapabilities = record
    CanHideShow: Boolean;
    CanMove: Boolean;
    CanSetShape: Boolean;
    CanBlink: Boolean;
  end;

  { One caret request from application/control code (cell coordinates, 0-based). }
  TLuxCursorState = record
    Active: Boolean;
    Visible: Boolean;
    X: Integer;
    Y: Integer;
    Shape: TLuxCursorShape;
    Blink: Boolean;
  end;

  { Controls request a caret; the manager diffs against the last committed
    logical state and emits sequences. Call MarkPaintDirtied after the
    renderer hides/moves the hardware cursor during a frame paint. }
  TLuxCursorManager = class
  private
    FCaps: TLuxCursorCapabilities;
    FRequested: TLuxCursorState;
    FCommitted: TLuxCursorState;
    FHaveCommitted: Boolean;
    FPaintDirtied: Boolean;
    procedure SetCapabilities(const AValue: TLuxCursorCapabilities);
    function DecscusrStyle(AShape: TLuxCursorShape; ABlink: Boolean): Integer;
    function EffectiveRequested: TLuxCursorState;
  public
    constructor Create;

    { Replace the outstanding request. Coordinates are surface cells. }
    procedure Request(AX, AY: Integer; AVisible: Boolean = True;
      AShape: TLuxCursorShape = lcsDefault; ABlink: Boolean = True);
    { Clear the outstanding request (no application caret). }
    procedure ClearRequest;
    { Renderer temporarily hid/moved the hardware cursor while painting. }
    procedure MarkPaintDirtied;
    { Emit sequences so the hardware cursor matches the request. }
    function Commit(AWriter: ILuxTerminalWriter): Boolean;

    property Capabilities: TLuxCursorCapabilities read FCaps write SetCapabilities;
    property Requested: TLuxCursorState read FRequested;
    property Committed: TLuxCursorState read FCommitted;
    property HaveCommitted: Boolean read FHaveCommitted;
  end;

function LuxCursorCapsNone: TLuxCursorCapabilities;
function LuxCursorCapsBasic: TLuxCursorCapabilities;
function LuxCursorCapsFull: TLuxCursorCapabilities;
function LuxCursorStateEqual(const A, B: TLuxCursorState): Boolean;

implementation

uses
  Lux.Terminal.Ansi;

function LuxCursorCapsNone: TLuxCursorCapabilities;
begin
  Result.CanHideShow := False;
  Result.CanMove := False;
  Result.CanSetShape := False;
  Result.CanBlink := False;
end;

function LuxCursorCapsBasic: TLuxCursorCapabilities;
begin
  Result.CanHideShow := True;
  Result.CanMove := True;
  Result.CanSetShape := False;
  Result.CanBlink := False;
end;

function LuxCursorCapsFull: TLuxCursorCapabilities;
begin
  Result.CanHideShow := True;
  Result.CanMove := True;
  Result.CanSetShape := True;
  Result.CanBlink := True;
end;

function LuxCursorStateEqual(const A, B: TLuxCursorState): Boolean;
begin
  Result := (A.Active = B.Active) and (A.Visible = B.Visible) and
    (A.X = B.X) and (A.Y = B.Y) and (A.Shape = B.Shape) and (A.Blink = B.Blink);
end;

constructor TLuxCursorManager.Create;
begin
  inherited Create;
  FCaps := LuxCursorCapsBasic;
  FillChar(FRequested, SizeOf(FRequested), 0);
  FillChar(FCommitted, SizeOf(FCommitted), 0);
  FHaveCommitted := False;
  FPaintDirtied := True;
end;

procedure TLuxCursorManager.SetCapabilities(const AValue: TLuxCursorCapabilities);
begin
  FCaps := AValue;
  FHaveCommitted := False;
  FPaintDirtied := True;
end;

function TLuxCursorManager.DecscusrStyle(AShape: TLuxCursorShape;
  ABlink: Boolean): Integer;
begin
  case AShape of
    lcsBlock:
      if ABlink then Result := 1 else Result := 2;
    lcsUnderline:
      if ABlink then Result := 3 else Result := 4;
    lcsBar:
      if ABlink then Result := 5 else Result := 6;
  else
    if ABlink then Result := 1 else Result := 2;
  end;
end;

function TLuxCursorManager.EffectiveRequested: TLuxCursorState;
begin
  Result := FRequested;
  if not Result.Active then
  begin
    Result.Visible := False;
    Result.X := 0;
    Result.Y := 0;
    Result.Shape := lcsDefault;
    Result.Blink := False;
  end
  else
    Result.Visible := FRequested.Visible;
end;

procedure TLuxCursorManager.Request(AX, AY: Integer; AVisible: Boolean;
  AShape: TLuxCursorShape; ABlink: Boolean);
begin
  if AX < 0 then
    AX := 0;
  if AY < 0 then
    AY := 0;
  FRequested.Active := True;
  FRequested.Visible := AVisible;
  FRequested.X := AX;
  FRequested.Y := AY;
  FRequested.Shape := AShape;
  FRequested.Blink := ABlink;
end;

procedure TLuxCursorManager.ClearRequest;
begin
  FillChar(FRequested, SizeOf(FRequested), 0);
  FRequested.Active := False;
  FRequested.Visible := False;
end;

procedure TLuxCursorManager.MarkPaintDirtied;
begin
  FPaintDirtied := True;
end;

function TLuxCursorManager.Commit(AWriter: ILuxTerminalWriter): Boolean;
var
  Target: TLuxCursorState;
  Blink: Boolean;
  NeedEmit: Boolean;
begin
  Result := False;
  if AWriter = nil then
    Exit;

  Target := EffectiveRequested;
  NeedEmit := FPaintDirtied or (not FHaveCommitted) or
    (not LuxCursorStateEqual(Target, FCommitted));
  if not NeedEmit then
    Exit(False);

  if Target.Visible then
  begin
    Blink := Target.Blink and FCaps.CanBlink;
    if FCaps.CanSetShape then
      AWriter.WriteRaw(LuxAnsiCursorStyle(DecscusrStyle(Target.Shape, Blink)));
    if FCaps.CanMove then
      AWriter.WriteRaw(LuxAnsiCursorMoveTo(Target.Y + 1, Target.X + 1));
    if FCaps.CanHideShow then
      AWriter.WriteRaw(LuxAnsiShowCursor);
  end
  else if FCaps.CanHideShow then
    AWriter.WriteRaw(LuxAnsiHideCursor);

  FCommitted := Target;
  FHaveCommitted := True;
  FPaintDirtied := False;
  Result := True;
end;

end.
