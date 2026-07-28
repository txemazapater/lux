{ Portable keyboard focus manager. One focused control per root. }
unit Lux.FocusManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  Lux.Control,
  Lux.ControlContainer;

type
  TLuxFocusManager = class
  private
    FRoot: TLuxRootControl;
    FFocused: TLuxControl;
    function CanFocus(AControl: TLuxControl): Boolean;
  public
    constructor Create(ARoot: TLuxRootControl);
    destructor Destroy; override;

    function SetFocus(AControl: TLuxControl): Boolean;
    procedure ClearFocus;
    function MoveNext: Boolean;
    function MovePrevious: Boolean;
    procedure EnsureValid;
    { Call when a control may no longer hold focus. }
    procedure HandleControlDetached(AControl: TLuxControl);

    property FocusedControl: TLuxControl read FFocused;
    property Root: TLuxRootControl read FRoot;
  end;

implementation

constructor TLuxFocusManager.Create(ARoot: TLuxRootControl);
begin
  inherited Create;
  if ARoot = nil then
    raise ELuxControl.Create('Focus manager requires a root control.');
  FRoot := ARoot;
  FFocused := nil;
end;

destructor TLuxFocusManager.Destroy;
begin
  FFocused := nil;
  FRoot := nil;
  inherited Destroy;
end;

function TLuxFocusManager.CanFocus(AControl: TLuxControl): Boolean;
var
  Cur: TLuxControl;
begin
  if AControl = nil then
    Exit(False);
  if not AControl.Focusable then
    Exit(False);
  if not AControl.IsEffectivelyVisible then
    Exit(False);
  if not AControl.IsEffectivelyEnabled then
    Exit(False);
  Cur := AControl;
  while Cur <> nil do
  begin
    if Cur = FRoot then
      Exit(True);
    Cur := Cur.Parent;
  end;
  Result := False;
end;

function TLuxFocusManager.SetFocus(AControl: TLuxControl): Boolean;
var
  Old: TLuxControl;
begin
  if AControl = FFocused then
    Exit(True);
  if (AControl <> nil) and (not CanFocus(AControl)) then
    Exit(False);
  Old := FFocused;
  FFocused := AControl;
  if Old <> nil then
    Old.ApplyFocusState(False);
  if FFocused <> nil then
    FFocused.ApplyFocusState(True);
  Result := True;
end;

procedure TLuxFocusManager.ClearFocus;
begin
  SetFocus(nil);
end;

function TLuxFocusManager.MoveNext: Boolean;
var
  List: TFPList;
  Idx, I: Integer;
begin
  List := TFPList.Create;
  try
    FRoot.CollectFocusable(List);
    if List.Count = 0 then
    begin
      ClearFocus;
      Exit(False);
    end;
    Idx := -1;
    if FFocused <> nil then
      Idx := List.IndexOf(FFocused);
    if Idx < 0 then
      I := 0
    else
      I := (Idx + 1) mod List.Count;
    Result := SetFocus(TLuxControl(List[I]));
  finally
    List.Free;
  end;
end;

function TLuxFocusManager.MovePrevious: Boolean;
var
  List: TFPList;
  Idx, I: Integer;
begin
  List := TFPList.Create;
  try
    FRoot.CollectFocusable(List);
    if List.Count = 0 then
    begin
      ClearFocus;
      Exit(False);
    end;
    Idx := -1;
    if FFocused <> nil then
      Idx := List.IndexOf(FFocused);
    if Idx < 0 then
      I := List.Count - 1
    else if Idx = 0 then
      I := List.Count - 1
    else
      I := Idx - 1;
    Result := SetFocus(TLuxControl(List[I]));
  finally
    List.Free;
  end;
end;

procedure TLuxFocusManager.EnsureValid;
begin
  if (FFocused <> nil) and (not CanFocus(FFocused)) then
    ClearFocus;
end;

procedure TLuxFocusManager.HandleControlDetached(AControl: TLuxControl);
var
  Cur: TLuxControl;
begin
  if AControl = nil then
    Exit;
  Cur := FFocused;
  while Cur <> nil do
  begin
    if Cur = AControl then
    begin
      ClearFocus;
      Exit;
    end;
    Cur := Cur.Parent;
  end;
end;

end.
