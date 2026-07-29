{ Portable base control. No platform APIs. }
unit Lux.Control;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Surface,
  Lux.Events;

type
  ELuxControl = class(Exception);

  TLuxNotifyEvent = procedure(Sender: TObject) of object;

  { Lightweight paint target: root surface, local origin in surface coords,
    and an absolute clip rectangle. No surface copies. }
  TLuxPaintContext = record
    Surface: TLuxSurface;
    OriginX: Integer;
    OriginY: Integer;
    Clip: TLuxRect;
  end;

  TLuxControlStyle = record
    Foreground: TLuxColor;
    Background: TLuxColor;
    FocusForeground: TLuxColor;
    FocusBackground: TLuxColor;
    DisabledForeground: TLuxColor;
    DisabledBackground: TLuxColor;
  end;

  TLuxControl = class
  private
    FParent: TLuxControl;
    FBounds: TLuxRect;
    FVisible: Boolean;
    FEnabled: Boolean;
    FFocusable: Boolean;
    FHasFocus: Boolean;
    FInvalidated: Boolean;
    FMinWidth: Integer;
    FMinHeight: Integer;
    FPreferredWidth: Integer;
    FPreferredHeight: Integer;
    FExpand: Integer;
    FOnHostInvalidate: TLuxNotifyEvent;
    FOnWillFree: TLuxNotifyEvent;
    procedure SetLeft(AValue: Integer);
    procedure SetTop(AValue: Integer);
    procedure SetWidth(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    function GetLeft: Integer;
    function GetTop: Integer;
    function GetWidth: Integer;
    function GetHeight: Integer;
    procedure SetMinWidth(AValue: Integer);
    procedure SetMinHeight(AValue: Integer);
    procedure SetPreferredWidth(AValue: Integer);
    procedure SetPreferredHeight(AValue: Integer);
    procedure SetExpand(AValue: Integer);
  protected
    { Containers override to accept ownership of a child. }
    function AcceptChild(AChild: TLuxControl): Boolean; virtual;
    procedure DetachChild(AChild: TLuxControl); virtual;
    procedure NotifyHostInvalidate;
    function ContentOffset: TLuxPoint; virtual;
    { Size available for children after ContentOffset inset (symmetric). }
    function ClientSize: TLuxSize; virtual;
    procedure Paint(const Ctx: TLuxPaintContext); virtual;
    function DoHandleEvent(const Event: TLuxEvent): Boolean; virtual;
    procedure BoundsChanged; virtual;
    procedure FocusChanged; virtual;
    { Parent layout boxes override to request relayout. }
    procedure HandleChildLayoutHintsChanged(AChild: TLuxControl); virtual;
    procedure LayoutHintsChanged;
    property OnHostInvalidate: TLuxNotifyEvent read FOnHostInvalidate
      write FOnHostInvalidate;
  public
    constructor Create(AParent: TLuxControl = nil);
    destructor Destroy; override;

    { Internal ownership / paint helpers used by containers and focus. }
    procedure SetParentInternal(AParent: TLuxControl);
    function BuildPaintContext(ATarget: TLuxSurface;
      const AParentCtx: TLuxPaintContext; AHasParentCtx: Boolean): TLuxPaintContext;
    procedure ApplyFocusState(AHasFocus: Boolean);

    procedure SetBounds(const ABounds: TLuxRect); overload;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); overload;
    procedure SetVisible(AValue: Boolean);
    procedure SetEnabled(AValue: Boolean);
    procedure SetFocusable(AValue: Boolean);

    function ResolvedPreferredWidth: Integer;
    function ResolvedPreferredHeight: Integer;

    procedure Invalidate;
    procedure Render(ATarget: TLuxSurface); overload;
    procedure Render(const Ctx: TLuxPaintContext); overload; virtual;
    function HandleEvent(const Event: TLuxEvent): Boolean;
    { Called by the application when this control stops being the mouse target. }
    procedure MouseLeave; virtual;

    function LocalToRoot(const P: TLuxPoint): TLuxPoint;
    function RootToLocal(const P: TLuxPoint): TLuxPoint;
    function AbsoluteBounds: TLuxRect;
    function ContainsRootPoint(AX, AY: Integer): Boolean;
    function IsEffectivelyVisible: Boolean;
    function IsEffectivelyEnabled: Boolean;

    property Parent: TLuxControl read FParent;
    property Bounds: TLuxRect read FBounds write SetBounds;
    property Left: Integer read GetLeft write SetLeft;
    property Top: Integer read GetTop write SetTop;
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property Visible: Boolean read FVisible write SetVisible;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Focusable: Boolean read FFocusable write SetFocusable;
    property HasFocus: Boolean read FHasFocus;
    property MinWidth: Integer read FMinWidth write SetMinWidth;
    property MinHeight: Integer read FMinHeight write SetMinHeight;
    property PreferredWidth: Integer read FPreferredWidth write SetPreferredWidth;
    property PreferredHeight: Integer read FPreferredHeight write SetPreferredHeight;
    { Main-axis expand weight for parent layout boxes. 0 = fixed at preferred. }
    property Expand: Integer read FExpand write SetExpand;
    { Invoked at the start of Destroy so hosts can drop capture refs. }
    property OnWillFree: TLuxNotifyEvent read FOnWillFree write FOnWillFree;
  end;

function LuxDefaultControlStyle: TLuxControlStyle;
function LuxPaintContext(ASurface: TLuxSurface; AOriginX, AOriginY: Integer;
  const AClip: TLuxRect): TLuxPaintContext;
procedure LuxPaintFill(const Ctx: TLuxPaintContext; const ALocalRect: TLuxRect;
  const ACell: TLuxCell);
procedure LuxPaintText(const Ctx: TLuxPaintContext; AX, AY: Integer;
  const AText: UnicodeString; const AForeground, ABackground: TLuxColor;
  const AStyle: TLuxTextStyle);

implementation

function LuxDefaultControlStyle: TLuxControlStyle;
begin
  Result.Foreground := LuxColorDefault;
  Result.Background := LuxColorDefault;
  Result.FocusForeground := LuxColorRGB(0, 0, 0);
  Result.FocusBackground := LuxColorRGB(200, 200, 200);
  Result.DisabledForeground := LuxColorRGB(128, 128, 128);
  Result.DisabledBackground := LuxColorDefault;
end;

function LuxPaintContext(ASurface: TLuxSurface; AOriginX, AOriginY: Integer;
  const AClip: TLuxRect): TLuxPaintContext;
begin
  Result.Surface := ASurface;
  Result.OriginX := AOriginX;
  Result.OriginY := AOriginY;
  Result.Clip := AClip;
end;

procedure LuxPaintFill(const Ctx: TLuxPaintContext; const ALocalRect: TLuxRect;
  const ACell: TLuxCell);
var
  AbsRect, Clip: TLuxRect;
begin
  if Ctx.Surface = nil then
    Exit;
  AbsRect := LuxRect(Ctx.OriginX + ALocalRect.Left, Ctx.OriginY + ALocalRect.Top,
    ALocalRect.Width, ALocalRect.Height);
  Clip := LuxRectIntersect(AbsRect, Ctx.Clip);
  Clip := LuxRectIntersect(Clip, Ctx.Surface.Bounds);
  if not LuxRectIsEmpty(Clip) then
    Ctx.Surface.FillRect(Clip, ACell);
end;

procedure LuxPaintText(const Ctx: TLuxPaintContext; AX, AY: Integer;
  const AText: UnicodeString; const AForeground, ABackground: TLuxColor;
  const AStyle: TLuxTextStyle);
var
  AbsX, AbsY, MaxX, I, CursorX: Integer;
  Codepoint: Cardinal;
  Glyph: UnicodeString;
  W: Byte;
  Primary: TLuxCell;
  CellRect: TLuxRect;
begin
  if (Ctx.Surface = nil) or (AText = '') then
    Exit;
  AbsY := Ctx.OriginY + AY;
  if (AbsY < Ctx.Clip.Top) or (AbsY >= LuxRectBottom(Ctx.Clip)) then
    Exit;
  AbsX := Ctx.OriginX + AX;
  MaxX := LuxRectRight(Ctx.Clip);
  I := 1;
  CursorX := AbsX;
  while LuxNextCodepoint(AText, I, Codepoint) do
  begin
    if CursorX >= MaxX then
      Break;
    if CursorX < Ctx.Clip.Left then
    begin
      W := LuxCodepointWidth(Codepoint);
      if W = 0 then
        W := 1;
      Inc(CursorX, W);
      Continue;
    end;
    W := LuxCodepointWidth(Codepoint);
    if W = 0 then
      W := 1;
    if Codepoint <= $FFFF then
      Glyph := UnicodeString(WideChar(Codepoint))
    else
    begin
      Codepoint := Codepoint - $10000;
      Glyph := UnicodeString(WideChar($D800 + (Codepoint shr 10))) +
        UnicodeString(WideChar($DC00 + (Codepoint and $3FF)));
    end;
    CellRect := LuxRect(CursorX, AbsY, W, 1);
    if LuxRectIsEmpty(LuxRectIntersect(CellRect, Ctx.Clip)) then
    begin
      Inc(CursorX, W);
      Continue;
    end;
    Primary := LuxCellMake(Glyph, W, AForeground, ABackground, AStyle);
    Ctx.Surface.PutCell(CursorX, AbsY, Primary);
    Inc(CursorX, W);
  end;
end;

constructor TLuxControl.Create(AParent: TLuxControl = nil);
begin
  inherited Create;
  FParent := nil;
  FBounds := LuxRect(0, 0, 0, 0);
  FVisible := True;
  FEnabled := True;
  FFocusable := False;
  FHasFocus := False;
  FInvalidated := True;
  FMinWidth := 0;
  FMinHeight := 0;
  FPreferredWidth := 0;
  FPreferredHeight := 0;
  FExpand := 0;
  FOnHostInvalidate := nil;
  FOnWillFree := nil;
  if AParent <> nil then
  begin
    if not AParent.AcceptChild(Self) then
      raise ELuxControl.Create('Parent cannot accept children.');
  end;
end;

destructor TLuxControl.Destroy;
var
  OldParent: TLuxControl;
begin
  if Assigned(FOnWillFree) then
    FOnWillFree(Self);
  if FHasFocus then
    FHasFocus := False;
  OldParent := FParent;
  FParent := nil;
  if OldParent <> nil then
    OldParent.DetachChild(Self);
  inherited Destroy;
end;

function TLuxControl.AcceptChild(AChild: TLuxControl): Boolean;
begin
  Result := False;
end;

procedure TLuxControl.DetachChild(AChild: TLuxControl);
begin
  { Base controls have no children. }
end;

procedure TLuxControl.SetParentInternal(AParent: TLuxControl);
begin
  FParent := AParent;
end;

procedure TLuxControl.NotifyHostInvalidate;
begin
  if Assigned(FOnHostInvalidate) then
    FOnHostInvalidate(Self)
  else if FParent <> nil then
    FParent.NotifyHostInvalidate;
end;

procedure TLuxControl.Invalidate;
begin
  FInvalidated := True;
  NotifyHostInvalidate;
end;

function TLuxControl.ContentOffset: TLuxPoint;
begin
  Result := LuxPoint(0, 0);
end;

function TLuxControl.ClientSize: TLuxSize;
var
  Off: TLuxPoint;
begin
  Off := ContentOffset;
  Result := LuxSize(FBounds.Width - Off.X * 2, FBounds.Height - Off.Y * 2);
  if Result.Width < 0 then
    Result.Width := 0;
  if Result.Height < 0 then
    Result.Height := 0;
end;

procedure TLuxControl.HandleChildLayoutHintsChanged(AChild: TLuxControl);
begin
  { Base control has no layout children. }
end;

procedure TLuxControl.LayoutHintsChanged;
begin
  Invalidate;
  if FParent <> nil then
    FParent.HandleChildLayoutHintsChanged(Self);
end;

function TLuxControl.ResolvedPreferredWidth: Integer;
begin
  Result := FPreferredWidth;
  if Result < FMinWidth then
    Result := FMinWidth;
end;

function TLuxControl.ResolvedPreferredHeight: Integer;
begin
  Result := FPreferredHeight;
  if Result < FMinHeight then
    Result := FMinHeight;
end;

procedure TLuxControl.SetMinWidth(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FMinWidth = AValue then
    Exit;
  FMinWidth := AValue;
  LayoutHintsChanged;
end;

procedure TLuxControl.SetMinHeight(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FMinHeight = AValue then
    Exit;
  FMinHeight := AValue;
  LayoutHintsChanged;
end;

procedure TLuxControl.SetPreferredWidth(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FPreferredWidth = AValue then
    Exit;
  FPreferredWidth := AValue;
  LayoutHintsChanged;
end;

procedure TLuxControl.SetPreferredHeight(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FPreferredHeight = AValue then
    Exit;
  FPreferredHeight := AValue;
  LayoutHintsChanged;
end;

procedure TLuxControl.SetExpand(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FExpand = AValue then
    Exit;
  FExpand := AValue;
  LayoutHintsChanged;
end;

function TLuxControl.GetLeft: Integer;
begin
  Result := FBounds.Left;
end;

function TLuxControl.GetTop: Integer;
begin
  Result := FBounds.Top;
end;

function TLuxControl.GetWidth: Integer;
begin
  Result := FBounds.Width;
end;

function TLuxControl.GetHeight: Integer;
begin
  Result := FBounds.Height;
end;

procedure TLuxControl.SetLeft(AValue: Integer);
begin
  SetBounds(AValue, FBounds.Top, FBounds.Width, FBounds.Height);
end;

procedure TLuxControl.SetTop(AValue: Integer);
begin
  SetBounds(FBounds.Left, AValue, FBounds.Width, FBounds.Height);
end;

procedure TLuxControl.SetWidth(AValue: Integer);
begin
  SetBounds(FBounds.Left, FBounds.Top, AValue, FBounds.Height);
end;

procedure TLuxControl.SetHeight(AValue: Integer);
begin
  SetBounds(FBounds.Left, FBounds.Top, FBounds.Width, AValue);
end;

procedure TLuxControl.SetBounds(const ABounds: TLuxRect);
begin
  SetBounds(ABounds.Left, ABounds.Top, ABounds.Width, ABounds.Height);
end;

procedure TLuxControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if AWidth < 0 then
    AWidth := 0;
  if AHeight < 0 then
    AHeight := 0;
  if (FBounds.Left = ALeft) and (FBounds.Top = ATop) and
    (FBounds.Width = AWidth) and (FBounds.Height = AHeight) then
    Exit;
  FBounds := LuxRect(ALeft, ATop, AWidth, AHeight);
  BoundsChanged;
  Invalidate;
end;

procedure TLuxControl.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then
    Exit;
  FVisible := AValue;
  LayoutHintsChanged;
end;

procedure TLuxControl.SetEnabled(AValue: Boolean);
begin
  if FEnabled = AValue then
    Exit;
  FEnabled := AValue;
  Invalidate;
end;

procedure TLuxControl.SetFocusable(AValue: Boolean);
begin
  FFocusable := AValue;
end;

procedure TLuxControl.BoundsChanged;
begin
end;

procedure TLuxControl.FocusChanged;
begin
end;

procedure TLuxControl.ApplyFocusState(AHasFocus: Boolean);
begin
  if FHasFocus = AHasFocus then
    Exit;
  FHasFocus := AHasFocus;
  FocusChanged;
  Invalidate;
end;

function TLuxControl.LocalToRoot(const P: TLuxPoint): TLuxPoint;
var
  Off: TLuxPoint;
  Cur: TLuxControl;
begin
  Result := P;
  Cur := Self;
  while Cur <> nil do
  begin
    if Cur.FParent <> nil then
    begin
      Off := Cur.FParent.ContentOffset;
      Result.X := Result.X + Cur.FBounds.Left + Off.X;
      Result.Y := Result.Y + Cur.FBounds.Top + Off.Y;
      Cur := Cur.FParent;
    end
    else
    begin
      Result.X := Result.X + Cur.FBounds.Left;
      Result.Y := Result.Y + Cur.FBounds.Top;
      Break;
    end;
  end;
end;

function TLuxControl.RootToLocal(const P: TLuxPoint): TLuxPoint;
var
  Origin: TLuxPoint;
begin
  Origin := LocalToRoot(LuxPoint(0, 0));
  Result.X := P.X - Origin.X;
  Result.Y := P.Y - Origin.Y;
end;

function TLuxControl.AbsoluteBounds: TLuxRect;
var
  Origin: TLuxPoint;
begin
  Origin := LocalToRoot(LuxPoint(0, 0));
  Result := LuxRect(Origin.X, Origin.Y, FBounds.Width, FBounds.Height);
end;

function TLuxControl.ContainsRootPoint(AX, AY: Integer): Boolean;
begin
  Result := LuxRectContainsXY(AbsoluteBounds, AX, AY);
end;

function TLuxControl.IsEffectivelyVisible: Boolean;
var
  Cur: TLuxControl;
begin
  Cur := Self;
  while Cur <> nil do
  begin
    if not Cur.FVisible then
      Exit(False);
    Cur := Cur.FParent;
  end;
  Result := True;
end;

function TLuxControl.IsEffectivelyEnabled: Boolean;
var
  Cur: TLuxControl;
begin
  Cur := Self;
  while Cur <> nil do
  begin
    if not Cur.FEnabled then
      Exit(False);
    Cur := Cur.FParent;
  end;
  Result := True;
end;

function TLuxControl.BuildPaintContext(ATarget: TLuxSurface;
  const AParentCtx: TLuxPaintContext; AHasParentCtx: Boolean): TLuxPaintContext;
var
  Origin: TLuxPoint;
  AbsBounds, ParentClip: TLuxRect;
begin
  Origin := LocalToRoot(LuxPoint(0, 0));
  AbsBounds := LuxRect(Origin.X, Origin.Y, FBounds.Width, FBounds.Height);
  if AHasParentCtx then
    ParentClip := AParentCtx.Clip
  else if ATarget <> nil then
    ParentClip := ATarget.Bounds
  else
    ParentClip := LuxRect(0, 0, 0, 0);
  Result := LuxPaintContext(ATarget, Origin.X, Origin.Y,
    LuxRectIntersect(AbsBounds, ParentClip));
end;

procedure TLuxControl.Paint(const Ctx: TLuxPaintContext);
begin
  { Base control draws nothing. }
end;

procedure TLuxControl.Render(ATarget: TLuxSurface);
var
  Dummy: TLuxPaintContext;
begin
  FillChar(Dummy, SizeOf(Dummy), 0);
  Render(BuildPaintContext(ATarget, Dummy, False));
end;

procedure TLuxControl.Render(const Ctx: TLuxPaintContext);
begin
  if not FVisible then
    Exit;
  if LuxRectIsEmpty(Ctx.Clip) then
    Exit;
  Paint(Ctx);
  FInvalidated := False;
end;

function TLuxControl.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  if not IsEffectivelyVisible then
    Exit(False);
  if (Event.Kind = ekKey) or (Event.Kind = ekMouse) then
    if not IsEffectivelyEnabled then
      Exit(False);
  Result := DoHandleEvent(Event);
end;

function TLuxControl.DoHandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := False;
end;

procedure TLuxControl.MouseLeave;
begin
end;

end.
