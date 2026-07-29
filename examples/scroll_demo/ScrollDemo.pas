{ Phase 6C scroll demo — acceptance criteria exercise.
  Uses demo/debug EventLog; does not extend the stable core API. }
unit ScrollDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Events,
  Lux.Control,
  Lux.ControlApplication,
  Lux.ScrollView,
  Lux.Panel,
  Lux.Button,
  Lux.Labels,
  Lux.Debug.EventLog;

type
  { Clickable button that also logs semantic mouse events. }
  TLogButton = class(TLuxButton)
  private
    FLog: TEventLogControl;
    FTagName: UnicodeString;
  public
    procedure SemanticMouseEnter(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseLeave; override;
    procedure SemanticMouseDown(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseUp(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticClick(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticDoubleClick(const Event: TLuxSemanticMouseEvent); override;
    property Log: TEventLogControl read FLog write FLog;
    property TagName: UnicodeString read FTagName write FTagName;
  end;

  { Drag-sensitive pad: moves within its parent on DragBegin/Move. }
  TDragPad = class(TLuxControl)
  private
    FLog: TEventLogControl;
    FLabel: UnicodeString;
    FDragging: Boolean;
    FPressed: Boolean;
    FHovered: Boolean;
    FGrabX, FGrabY: Integer;
    FOriginLeft, FOriginTop: Integer;
  protected
    procedure Paint(const Ctx: TLuxPaintContext); override;
  public
    constructor Create(AParent: TLuxControl = nil);
    procedure SemanticMouseEnter(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseLeave; override;
    procedure SemanticMouseDown(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticMouseUp(const Event: TLuxSemanticMouseEvent); override;
    procedure SemanticDragBegin(const Event: TLuxDragEvent); override;
    procedure SemanticDragMove(const Event: TLuxDragEvent); override;
    procedure SemanticDragEnd(const Event: TLuxDragEvent); override;
    procedure SemanticDragCancel; override;
    property Log: TEventLogControl read FLog write FLog;
    property IsPadDragging: Boolean read FDragging;
    property IsPadPressed: Boolean read FPressed;
    property IsPadHovered: Boolean read FHovered;
  end;

  { ScrollView that logs wheel consumption. }
  TLogScrollView = class(TLuxScrollView)
  private
    FLog: TEventLogControl;
    FTagName: UnicodeString;
  public
    function SemanticMouseWheel(const Event: TLuxWheelEvent): Boolean; override;
    property Log: TEventLogControl read FLog write FLog;
    property TagName: UnicodeString read FTagName write FTagName;
  end;

  TScrollDemoApp = class(TLuxControlApplication)
  private
    FOuterSV: TLogScrollView;
    FOuterContent: TLuxPanel;
    FInnerSV: TLogScrollView;
    FInnerContent: TLuxPanel;
    FEventLog: TEventLogControl;
    FDiagPanel: TLuxPanel;
    FDiagLabels: array[0..7] of TLuxLabel;
    FEnsureBtn: TLogButton;
    FQuitBtn: TLogButton;
    FFarBtn: TLogButton;
    FDragPad: TDragPad;
    FShowDiag: Boolean;
    FHint: TLuxLabel;
    procedure LayoutDemo;
    procedure OnEnsureClick(Sender: TObject);
    procedure OnQuitClick(Sender: TObject);
    procedure OnFarClick(Sender: TObject);
    procedure RefreshDiagnostics;
    function ControlName(AControl: TLuxControl): UnicodeString;
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure Update; override;
  public
    procedure AfterConstruction; override;
  end;

implementation

{ TLogButton }

procedure TLogButton.SemanticMouseEnter(const Event: TLuxSemanticMouseEvent);
begin
  inherited SemanticMouseEnter(Event);
  if FLog <> nil then
    FLog.Add(FTagName + ' Enter');
end;

procedure TLogButton.SemanticMouseLeave;
begin
  inherited SemanticMouseLeave;
  if FLog <> nil then
    FLog.Add(FTagName + ' Leave');
end;

procedure TLogButton.SemanticMouseDown(const Event: TLuxSemanticMouseEvent);
begin
  inherited SemanticMouseDown(Event);
  if FLog <> nil then
    FLog.Add(FTagName + ' Down');
end;

procedure TLogButton.SemanticMouseUp(const Event: TLuxSemanticMouseEvent);
begin
  inherited SemanticMouseUp(Event);
  if FLog <> nil then
    FLog.Add(FTagName + ' Up');
end;

procedure TLogButton.SemanticClick(const Event: TLuxSemanticMouseEvent);
begin
  inherited SemanticClick(Event);
  if FLog <> nil then
    FLog.Add(FTagName + ' Click');
end;

procedure TLogButton.SemanticDoubleClick(const Event: TLuxSemanticMouseEvent);
begin
  inherited SemanticDoubleClick(Event);
  if FLog <> nil then
    FLog.Add(FTagName + ' DblClick');
end;

{ TDragPad }

constructor TDragPad.Create(AParent: TLuxControl);
begin
  inherited Create(AParent);
  FLabel := 'DRAG';
  FDragging := False;
  FPressed := False;
  FHovered := False;
  Focusable := False;
end;

procedure TDragPad.Paint(const Ctx: TLuxPaintContext);
var
  Fill: TLuxCell;
  Fg, Bg: TLuxColor;
  State: UnicodeString;
begin
  if FDragging then
  begin
    Fg := LuxColorRGB(0, 0, 0);
    Bg := LuxColorRGB(220, 180, 40);
    State := 'DRAGGING';
  end
  else if FPressed then
  begin
    Fg := LuxColorRGB(255, 255, 255);
    Bg := LuxColorRGB(180, 80, 40);
    State := 'PRESSED';
  end
  else if FHovered then
  begin
    Fg := LuxColorRGB(0, 0, 0);
    Bg := LuxColorRGB(160, 200, 255);
    State := 'HOVERED';
  end
  else
  begin
    Fg := LuxColorRGB(255, 255, 255);
    Bg := LuxColorRGB(60, 100, 160);
    State := FLabel;
  end;
  Fill := LuxCellMake(' ', 1, Fg, Bg, []);
  LuxPaintFill(Ctx, LuxRect(0, 0, Width, Height), Fill);
  LuxPaintText(Ctx, 1, Height div 2, State, Fg, Bg, []);
end;

procedure TDragPad.SemanticMouseEnter(const Event: TLuxSemanticMouseEvent);
begin
  FHovered := True;
  if FLog <> nil then
    FLog.Add('DragPad Enter');
  Invalidate;
end;

procedure TDragPad.SemanticMouseLeave;
begin
  FHovered := False;
  if not FDragging then
    FPressed := False;
  if FLog <> nil then
    FLog.Add('DragPad Leave');
  Invalidate;
end;

procedure TDragPad.SemanticMouseDown(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    FPressed := True;
  if FLog <> nil then
    FLog.Add('DragPad Down');
  Invalidate;
end;

procedure TDragPad.SemanticMouseUp(const Event: TLuxSemanticMouseEvent);
begin
  if Event.Button = mbLeft then
    FPressed := False;
  if FLog <> nil then
    FLog.Add('DragPad Up');
  Invalidate;
end;

procedure TDragPad.SemanticDragBegin(const Event: TLuxDragEvent);
begin
  FDragging := True;
  FPressed := True;
  FGrabX := Event.StartX;
  FGrabY := Event.StartY;
  FOriginLeft := Left;
  FOriginTop := Top;
  if FLog <> nil then
    FLog.Add('DragPad DragBegin');
  Invalidate;
end;

procedure TDragPad.SemanticDragMove(const Event: TLuxDragEvent);
var
  NewLeft, NewTop: Integer;
begin
  NewLeft := FOriginLeft + (Event.X - FGrabX);
  NewTop := FOriginTop + (Event.Y - FGrabY);
  if NewLeft < 0 then
    NewLeft := 0;
  if NewTop < 0 then
    NewTop := 0;
  SetBounds(NewLeft, NewTop, Width, Height);
  if FLog <> nil then
    FLog.Add(Format('DragPad Move %d,%d', [NewLeft, NewTop]));
end;

procedure TDragPad.SemanticDragEnd(const Event: TLuxDragEvent);
begin
  FDragging := False;
  FPressed := False;
  if FLog <> nil then
    FLog.Add('DragPad DragEnd');
  Invalidate;
end;

procedure TDragPad.SemanticDragCancel;
begin
  FDragging := False;
  FPressed := False;
  if FLog <> nil then
    FLog.Add('DragPad DragCancel');
  Invalidate;
end;

{ TLogScrollView }

function TLogScrollView.SemanticMouseWheel(const Event: TLuxWheelEvent): Boolean;
begin
  Result := inherited SemanticMouseWheel(Event);
  if FLog <> nil then
  begin
    if Result then
      FLog.Add(Format('%s Wheel d=%d -> %d,%d',
        [FTagName, Event.Delta, ScrollX, ScrollY]))
    else
      FLog.Add(FTagName + ' Wheel (no scroll)');
  end;
end;

{ TScrollDemoApp }

procedure TScrollDemoApp.AfterConstruction;
var
  B: TLogButton;
  I: Integer;
begin
  inherited AfterConstruction;

  FShowDiag := True;

  FHint := TLuxLabel.Create(Root);
  FHint.Text := 'Wheel=scroll  Drag pad  D=diag  E=EnsureVisible far  Q=quit';

  FEventLog := TEventLogControl.Create(Root);
  FEventLog.Title := 'Semantic event log';
  FEventLog.Capacity := 128;

  FOuterSV := TLogScrollView.Create(Root);
  FOuterSV.Log := FEventLog;
  FOuterSV.TagName := 'OuterSV';
  FOuterSV.WheelScrollStep := 2;
  FOuterSV.HorizontalWheelScrollStep := 2;

  FOuterContent := TLuxPanel.Create(nil);
  FOuterContent.BorderStyle := lbsSingle;
  FOuterContent.Background := LuxColorRGB(20, 20, 30);
  { Larger than any typical viewport: horizontal + vertical overflow. }
  FOuterContent.SetBounds(0, 0, 90, 36);
  FOuterSV.Content := FOuterContent;

  for I := 0 to 5 do
  begin
    B := TLogButton.Create(FOuterContent);
    B.Log := FEventLog;
    B.TagName := 'Btn' + IntToStr(I);
    B.Text := 'Click ' + IntToStr(I);
    B.SetBounds(2, 1 + I * 2, 12, 1);
  end;

  FDragPad := TDragPad.Create(FOuterContent);
  FDragPad.Log := FEventLog;
  FDragPad.SetBounds(16, 2, 12, 3);

  FInnerSV := TLogScrollView.Create(FOuterContent);
  FInnerSV.Log := FEventLog;
  FInnerSV.TagName := 'InnerSV';
  FInnerSV.SetBounds(40, 2, 22, 8);
  FInnerSV.WheelScrollStep := 1;

  FInnerContent := TLuxPanel.Create(nil);
  FInnerContent.BorderStyle := lbsSingle;
  FInnerContent.Background := LuxColorRGB(30, 40, 30);
  FInnerContent.SetBounds(0, 0, 40, 20);
  FInnerSV.Content := FInnerContent;

  for I := 0 to 7 do
  begin
    B := TLogButton.Create(FInnerContent);
    B.Log := FEventLog;
    B.TagName := 'In' + IntToStr(I);
    B.Text := 'Inner ' + IntToStr(I);
    B.SetBounds(1, 1 + I * 2, 14, 1);
  end;

  FFarBtn := TLogButton.Create(FOuterContent);
  FFarBtn.Log := FEventLog;
  FFarBtn.TagName := 'Far';
  FFarBtn.Text := 'FAR TARGET';
  FFarBtn.SetBounds(70, 30, 14, 1);
  FFarBtn.OnClick := @OnFarClick;

  FEnsureBtn := TLogButton.Create(Root);
  FEnsureBtn.Log := FEventLog;
  FEnsureBtn.TagName := 'Ensure';
  FEnsureBtn.Text := 'EnsureVisible Far';
  FEnsureBtn.OnClick := @OnEnsureClick;

  FQuitBtn := TLogButton.Create(Root);
  FQuitBtn.Log := FEventLog;
  FQuitBtn.TagName := 'Quit';
  FQuitBtn.Text := 'Quit';
  FQuitBtn.OnClick := @OnQuitClick;

  FDiagPanel := TLuxPanel.Create(Root);
  FDiagPanel.BorderStyle := lbsSingle;
  FDiagPanel.Background := LuxColorRGB(10, 10, 10);
  for I := 0 to High(FDiagLabels) do
  begin
    FDiagLabels[I] := TLuxLabel.Create(FDiagPanel);
    FDiagLabels[I].SetBounds(1, 1 + I, 60, 1);
  end;

  LayoutDemo;
  Focus.SetFocus(FEnsureBtn);
  FEventLog.Add('Demo ready');
  RefreshDiagnostics;
end;

procedure TScrollDemoApp.LayoutDemo;
var
  LogW, MainW, MainH, DiagH, BottomY: Integer;
  I: Integer;
begin
  LogW := 28;
  if Width < 60 then
    LogW := 20;
  MainW := Width - LogW - 1;
  if MainW < 20 then
    MainW := Width div 2;
  DiagH := 0;
  if FShowDiag then
    DiagH := 10;
  BottomY := Height - 1 - DiagH;
  MainH := BottomY - 2;
  if MainH < 4 then
    MainH := 4;

  FHint.SetBounds(0, 0, Width, 1);
  FOuterSV.SetBounds(0, 1, MainW, MainH);
  FEventLog.SetBounds(MainW + 1, 1, Width - MainW - 1, MainH);
  FEnsureBtn.SetBounds(0, BottomY, 20, 1);
  FQuitBtn.SetBounds(22, BottomY, 8, 1);

  if FShowDiag then
  begin
    FDiagPanel.Visible := True;
    FDiagPanel.SetBounds(0, Height - DiagH, Width, DiagH);
    for I := 0 to High(FDiagLabels) do
      FDiagLabels[I].SetBounds(1, 1 + I, Width - 2, 1);
  end
  else
    FDiagPanel.Visible := False;
end;

function TScrollDemoApp.ControlName(AControl: TLuxControl): UnicodeString;
begin
  if AControl = nil then
    Exit('(nil)');
  if AControl is TLogButton then
    Exit(TLogButton(AControl).TagName);
  if AControl is TLogScrollView then
    Exit(TLogScrollView(AControl).TagName);
  if AControl is TDragPad then
    Exit('DragPad');
  if AControl is TEventLogControl then
    Exit('EventLog');
  if AControl = FOuterContent then
    Exit('OuterContent');
  if AControl = FInnerContent then
    Exit('InnerContent');
  if AControl = Root then
    Exit('Root');
  Result := AControl.ClassName;
end;

procedure TScrollDemoApp.RefreshDiagnostics;
var
  VR: TLuxRect;
  Hover, Pressed, Cap: TLuxControl;
begin
  if not FShowDiag then
    Exit;
  VR := FOuterSV.VisibleContentRect;
  Hover := Dispatcher.HoveredControl;
  Pressed := Dispatcher.PressedControl;
  Cap := CapturedControl;

  FDiagLabels[0].Text := Format(
    'Outer viewport=%dx%d content=%dx%d scroll=%d,%d max=%d,%d',
    [FOuterSV.ViewportWidth, FOuterSV.ViewportHeight,
     FOuterSV.ContentWidth, FOuterSV.ContentHeight,
     FOuterSV.ScrollX, FOuterSV.ScrollY,
     FOuterSV.MaximumScrollX, FOuterSV.MaximumScrollY]);
  FDiagLabels[1].Text := Format(
    'Outer VisibleContentRect=(%d,%d %dx%d) absBounds=(%d,%d %dx%d)',
    [VR.Left, VR.Top, VR.Width, VR.Height,
     FOuterSV.AbsoluteBounds.Left, FOuterSV.AbsoluteBounds.Top,
     FOuterSV.AbsoluteBounds.Width, FOuterSV.AbsoluteBounds.Height]);
  FDiagLabels[2].Text := Format(
    'Inner viewport=%dx%d content=%dx%d scroll=%d,%d max=%d,%d',
    [FInnerSV.ViewportWidth, FInnerSV.ViewportHeight,
     FInnerSV.ContentWidth, FInnerSV.ContentHeight,
     FInnerSV.ScrollX, FInnerSV.ScrollY,
     FInnerSV.MaximumScrollX, FInnerSV.MaximumScrollY]);
  FDiagLabels[3].Text := Format(
    'Hover=%s  Pressed=%s  Captured=%s  Dragging=%s',
    [ControlName(Hover), ControlName(Pressed), ControlName(Cap),
     BoolToStr(Dispatcher.IsDragging, True)]);
  FDiagLabels[4].Text := Format(
    'DragPad at (%d,%d) hovered=%s pressed=%s',
    [FDragPad.Left, FDragPad.Top,
     BoolToStr(FDragPad.IsPadHovered, True),
     BoolToStr(FDragPad.IsPadPressed, True)]);
  FDiagLabels[5].Text := Format(
    'Far btn local=(%d,%d) root=(%d,%d)',
    [FFarBtn.Left, FFarBtn.Top,
     FFarBtn.AbsoluteBounds.Left, FFarBtn.AbsoluteBounds.Top]);
  FDiagLabels[6].Text :=
    'D toggles this panel. Wheel over nested SV: inner consumes until limit.';
  FDiagLabels[7].Text :=
    'Click scrolled buttons / drag pad / EnsureVisible Far to verify hit-test.';
end;

procedure TScrollDemoApp.OnEnsureClick(Sender: TObject);
begin
  FOuterSV.EnsureVisible(FFarBtn);
  FEventLog.Add(Format('EnsureVisible Far -> scroll %d,%d',
    [FOuterSV.ScrollX, FOuterSV.ScrollY]));
  RefreshDiagnostics;
end;

procedure TScrollDemoApp.OnQuitClick(Sender: TObject);
begin
  RequestQuit;
end;

procedure TScrollDemoApp.OnFarClick(Sender: TObject);
begin
  FEventLog.Add('Far target clicked (hit-test OK after scroll)');
end;

function TScrollDemoApp.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  if (Event.Kind = ekKey) and (Event.Key.Action <> kaRelease) then
  begin
    if (Event.Key.Key = lkChar) and
      ((Event.Key.Ch = 'q') or (Event.Key.Ch = 'Q')) then
    begin
      RequestQuit;
      Exit(True);
    end;
    if (Event.Key.Key = lkChar) and
      ((Event.Key.Ch = 'd') or (Event.Key.Ch = 'D')) then
    begin
      FShowDiag := not FShowDiag;
      LayoutDemo;
      RefreshDiagnostics;
      FEventLog.Add('Diag ' + BoolToStr(FShowDiag, True));
      Exit(True);
    end;
    if (Event.Key.Key = lkChar) and
      ((Event.Key.Ch = 'e') or (Event.Key.Ch = 'E')) then
    begin
      OnEnsureClick(FEnsureBtn);
      Exit(True);
    end;
  end;
  Result := inherited HandleEvent(Event);
end;

procedure TScrollDemoApp.Update;
begin
  inherited Update;
  if (FOuterSV.Width <> Width - 29) or (FOuterSV.Height < 1) then
    LayoutDemo;
  RefreshDiagnostics;
end;

end.
