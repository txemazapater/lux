{ Portable control container: ownership, hit testing, focus traversal. }
unit Lux.ControlContainer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Classes,
  Contnrs,
  Lux.Geometry,
  Lux.Control;

type
  TLuxControlContainer = class(TLuxControl)
  private
    FChildren: TObjectList;
  protected
    function AcceptChild(AChild: TLuxControl): Boolean; override;
    procedure DetachChild(AChild: TLuxControl); override;
    procedure Paint(const Ctx: TLuxPaintContext); override;
    procedure PaintChildren(const Ctx: TLuxPaintContext); virtual;
    { Return True when (AX,AY) in root space hits internal chrome (not a child).
      When True, HitTestRoot returns Self (if enabled). }
    function HitTestInternalRoot(AX, AY: Integer): Boolean; virtual;
  public
    constructor Create(AParent: TLuxControl = nil);
    destructor Destroy; override;

    procedure AddChild(AControl: TLuxControl); virtual;
    procedure RemoveChild(AControl: TLuxControl); virtual;
    function ChildCount: Integer;
    function Children(AIndex: Integer): TLuxControl;
    function IndexOfChild(AControl: TLuxControl): Integer;

    procedure Render(const Ctx: TLuxPaintContext); override;
    function HitTestRoot(AX, AY: Integer): TLuxControl; virtual;
    procedure CollectFocusable(AList: TFPList); virtual;

    procedure BringToFront(AControl: TLuxControl);
    procedure SendToBack(AControl: TLuxControl);
  end;

  { Application drawable root. No parent; owns the tree.
    On resize, each visible child fills the client area so a single top-level
    layout can host the UI without application SetBounds calls. }
  TLuxCaptureMouseEvent = procedure(AControl: TLuxControl) of object;
  TLuxQueryCapturedEvent = function: TLuxControl of object;
  TLuxQueryCursorEvent = function: TObject of object;

  TLuxRootControl = class(TLuxControlContainer)
  private
    FCaptureMouse: TLuxCaptureMouseEvent;
    FReleaseMouse: TLuxCaptureMouseEvent;
    FQueryCaptured: TLuxQueryCapturedEvent;
    FQueryCursor: TLuxQueryCursorEvent;
  protected
    procedure BoundsChanged; override;
  public
    constructor Create; reintroduce;
    procedure AddChild(AControl: TLuxControl); override;
    procedure SetHostInvalidate(AHandler: TLuxNotifyEvent);
    procedure SetInteractionHandlers(ACapture, ARelease: TLuxCaptureMouseEvent;
      AQueryCaptured: TLuxQueryCapturedEvent; AQueryCursor: TLuxQueryCursorEvent);
    procedure RequestCaptureMouse(AControl: TLuxControl);
    procedure RequestReleaseMouse(AControl: TLuxControl);
    function CurrentCapturedControl: TLuxControl;
    function CurrentCursorManager: TObject;
  end;

function LuxFindRootControl(AControl: TLuxControl): TLuxRootControl;

implementation

constructor TLuxControlContainer.Create(AParent: TLuxControl = nil);
begin
  FChildren := TObjectList.Create(True);
  inherited Create(AParent);
end;

destructor TLuxControlContainer.Destroy;
var
  I: Integer;
  Child: TLuxControl;
begin
  if FChildren <> nil then
  begin
    { Nil parent links first so child destructors do not mutate the list. }
    for I := 0 to FChildren.Count - 1 do
      TLuxControl(FChildren[I]).SetParentInternal(nil);
    for I := FChildren.Count - 1 downto 0 do
    begin
      Child := TLuxControl(FChildren[I]);
      FChildren.OwnsObjects := False;
      FChildren.Delete(I);
      FChildren.OwnsObjects := True;
      Child.Free;
    end;
    FreeAndNil(FChildren);
  end;
  inherited Destroy;
end;

function TLuxControlContainer.AcceptChild(AChild: TLuxControl): Boolean;
begin
  AddChild(AChild);
  Result := True;
end;

procedure TLuxControlContainer.DetachChild(AChild: TLuxControl);
var
  Idx: Integer;
begin
  if FChildren = nil then
    Exit;
  Idx := FChildren.IndexOf(AChild);
  if Idx >= 0 then
  begin
    FChildren.OwnsObjects := False;
    try
      FChildren.Delete(Idx);
    finally
      FChildren.OwnsObjects := True;
    end;
    AChild.SetParentInternal(nil);
  end;
end;

procedure TLuxControlContainer.AddChild(AControl: TLuxControl);
var
  OldParent: TLuxControl;
  Cur: TLuxControl;
begin
  if AControl = nil then
    raise ELuxControl.Create('Cannot add a nil child.');
  if AControl = Self then
    raise ELuxControl.Create('Cannot add a control to itself.');

  { Reject cycles: AControl must not be an ancestor of Self. }
  Cur := Self;
  while Cur <> nil do
  begin
    if Cur = AControl then
      raise ELuxControl.Create('Cannot create a parent/child cycle.');
    Cur := Cur.Parent;
  end;

  if IndexOfChild(AControl) >= 0 then
    raise ELuxControl.Create('Child is already in this container.');

  OldParent := AControl.Parent;
  if OldParent = Self then
    Exit;
  if OldParent <> nil then
  begin
    if OldParent is TLuxControlContainer then
      TLuxControlContainer(OldParent).RemoveChild(AControl)
    else
      raise ELuxControl.Create('Cannot reparent from a non-container parent.');
  end;

  FChildren.Add(AControl);
  AControl.SetParentInternal(Self);
  Invalidate;
end;

procedure TLuxControlContainer.RemoveChild(AControl: TLuxControl);
var
  Idx: Integer;
begin
  Idx := IndexOfChild(AControl);
  if Idx < 0 then
    Exit;
  FChildren.OwnsObjects := False;
  try
    FChildren.Delete(Idx);
  finally
    FChildren.OwnsObjects := True;
  end;
  AControl.SetParentInternal(nil);
  Invalidate;
end;

function TLuxControlContainer.ChildCount: Integer;
begin
  if FChildren = nil then
    Exit(0);
  Result := FChildren.Count;
end;

function TLuxControlContainer.Children(AIndex: Integer): TLuxControl;
begin
  Result := TLuxControl(FChildren[AIndex]);
end;

function TLuxControlContainer.IndexOfChild(AControl: TLuxControl): Integer;
begin
  if FChildren = nil then
    Exit(-1);
  Result := FChildren.IndexOf(AControl);
end;

procedure TLuxControlContainer.Paint(const Ctx: TLuxPaintContext);
begin
end;

procedure TLuxControlContainer.PaintChildren(const Ctx: TLuxPaintContext);
var
  I: Integer;
  Child: TLuxControl;
  ChildCtx: TLuxPaintContext;
  Off: TLuxPoint;
  ClientAbs, ChildClip: TLuxRect;
begin
  Off := ContentOffset;
  ClientAbs := LuxRect(Ctx.OriginX + Off.X, Ctx.OriginY + Off.Y,
    Width - (Off.X * 2), Height - (Off.Y * 2));
  if (ClientAbs.Width < 0) or (ClientAbs.Height < 0) then
    Exit;
  ChildClip := LuxRectIntersect(Ctx.Clip, ClientAbs);
  if LuxRectIsEmpty(ChildClip) then
    Exit;

  for I := 0 to ChildCount - 1 do
  begin
    Child := Children(I);
    ChildCtx := Child.BuildPaintContext(Ctx.Surface, Ctx, True);
    ChildCtx.Clip := LuxRectIntersect(ChildCtx.Clip, ChildClip);
    Child.Render(ChildCtx);
  end;
end;

procedure TLuxControlContainer.Render(const Ctx: TLuxPaintContext);
begin
  if not Visible then
    Exit;
  if LuxRectIsEmpty(Ctx.Clip) then
    Exit;
  Paint(Ctx);
  PaintChildren(Ctx);
end;

function TLuxControlContainer.HitTestInternalRoot(AX, AY: Integer): Boolean;
begin
  Result := False;
end;

function TLuxControlContainer.HitTestRoot(AX, AY: Integer): TLuxControl;
var
  I: Integer;
  Child: TLuxControl;
  Hit: TLuxControl;
begin
  Result := nil;
  if not IsEffectivelyVisible then
    Exit;
  if not ContainsRootPoint(AX, AY) then
    Exit;

  { Internal chrome (e.g. split divider) before children. }
  if HitTestInternalRoot(AX, AY) then
  begin
    if IsEffectivelyEnabled then
      Exit(Self);
    Exit(nil);
  end;

  for I := ChildCount - 1 downto 0 do
  begin
    Child := Children(I);
    if not Child.IsEffectivelyVisible then
      Continue;
    if Child is TLuxControlContainer then
      Hit := TLuxControlContainer(Child).HitTestRoot(AX, AY)
    else if Child.ContainsRootPoint(AX, AY) then
      Hit := Child
    else
      Hit := nil;
    if Hit <> nil then
    begin
      if not Hit.IsEffectivelyEnabled then
      begin
        { Disabled controls do not receive mouse; fall through to parent. }
        if IsEffectivelyEnabled then
          Exit(Self);
        Exit(nil);
      end;
      Exit(Hit);
    end;
  end;

  if IsEffectivelyEnabled then
    Result := Self;
end;

procedure TLuxControlContainer.CollectFocusable(AList: TFPList);
var
  I: Integer;
  Child: TLuxControl;
begin
  if not IsEffectivelyVisible then
    Exit;
  if Focusable and IsEffectivelyEnabled then
    AList.Add(Self);
  for I := 0 to ChildCount - 1 do
  begin
    Child := Children(I);
    if Child is TLuxControlContainer then
      TLuxControlContainer(Child).CollectFocusable(AList)
    else if Child.Focusable and Child.IsEffectivelyVisible and
      Child.IsEffectivelyEnabled then
      AList.Add(Child);
  end;
end;

procedure TLuxControlContainer.BringToFront(AControl: TLuxControl);
var
  Idx: Integer;
begin
  Idx := IndexOfChild(AControl);
  if Idx < 0 then
    Exit;
  FChildren.Move(Idx, FChildren.Count - 1);
  Invalidate;
end;

procedure TLuxControlContainer.SendToBack(AControl: TLuxControl);
var
  Idx: Integer;
begin
  Idx := IndexOfChild(AControl);
  if Idx < 0 then
    Exit;
  FChildren.Move(Idx, 0);
  Invalidate;
end;

constructor TLuxRootControl.Create;
begin
  inherited Create(nil);
end;

procedure TLuxRootControl.AddChild(AControl: TLuxControl);
var
  Sz: TLuxSize;
begin
  inherited AddChild(AControl);
  Sz := ClientSize;
  if AControl.Visible then
    AControl.SetBounds(0, 0, Sz.Width, Sz.Height);
end;

procedure TLuxRootControl.BoundsChanged;
var
  I: Integer;
  Child: TLuxControl;
  Sz: TLuxSize;
begin
  inherited BoundsChanged;
  Sz := ClientSize;
  for I := 0 to ChildCount - 1 do
  begin
    Child := Children(I);
    if not Child.Visible then
      Continue;
    Child.SetBounds(0, 0, Sz.Width, Sz.Height);
  end;
end;

procedure TLuxRootControl.SetHostInvalidate(AHandler: TLuxNotifyEvent);
begin
  OnHostInvalidate := AHandler;
end;

procedure TLuxRootControl.SetInteractionHandlers(ACapture, ARelease: TLuxCaptureMouseEvent;
  AQueryCaptured: TLuxQueryCapturedEvent; AQueryCursor: TLuxQueryCursorEvent);
begin
  FCaptureMouse := ACapture;
  FReleaseMouse := ARelease;
  FQueryCaptured := AQueryCaptured;
  FQueryCursor := AQueryCursor;
end;

procedure TLuxRootControl.RequestCaptureMouse(AControl: TLuxControl);
begin
  if Assigned(FCaptureMouse) then
    FCaptureMouse(AControl);
end;

procedure TLuxRootControl.RequestReleaseMouse(AControl: TLuxControl);
begin
  if Assigned(FReleaseMouse) then
    FReleaseMouse(AControl);
end;

function TLuxRootControl.CurrentCapturedControl: TLuxControl;
begin
  Result := nil;
  if Assigned(FQueryCaptured) then
    Result := FQueryCaptured();
end;

function TLuxRootControl.CurrentCursorManager: TObject;
begin
  Result := nil;
  if Assigned(FQueryCursor) then
    Result := FQueryCursor();
end;

function LuxFindRootControl(AControl: TLuxControl): TLuxRootControl;
var
  Cur: TLuxControl;
begin
  Result := nil;
  Cur := AControl;
  while Cur <> nil do
  begin
    if Cur is TLuxRootControl then
      Exit(TLuxRootControl(Cur));
    Cur := Cur.Parent;
  end;
end;

end.
