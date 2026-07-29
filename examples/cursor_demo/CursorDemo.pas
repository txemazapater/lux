{ Phase 6B.2 logical cursor positioning demo. }
unit CursorDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Events,
  Lux.Cursor,
  Lux.ControlApplication,
  Lux.Panel,
  Lux.Labels,
  Lux.Button,
  Lux.Color,
  Lux.Layout,
  Lux.Layout.Vertical,
  Lux.Layout.Horizontal,
  Lux.Surface,
  Lux.Cell;

type
  TCursorDemoApp = class(TLuxControlApplication)
  private
    FMain: TLuxVerticalLayout;
    FHint: TLuxLabel;
    FStatus: TLuxLabel;
    FField: TLuxPanel;
    FCaretX: Integer;
    FCaretY: Integer;
    FShape: TLuxCursorShape;
    FActions: TLuxHorizontalLayout;
    FCycle: TLuxButton;
    FQuit: TLuxButton;
    procedure SyncCaret;
    procedure CycleClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
    function ShapeName: string;
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure RenderContent(ASurface: TLuxSurface); override;
  public
    procedure AfterConstruction; override;
  end;

implementation

function TCursorDemoApp.ShapeName: string;
begin
  case FShape of
    lcsBlock: Result := 'block';
    lcsUnderline: Result := 'underline';
    lcsBar: Result := 'bar';
  else
    Result := 'default';
  end;
end;

procedure TCursorDemoApp.SyncCaret;
begin
  if FCaretX < 2 then
    FCaretX := 2;
  if FCaretY < 2 then
    FCaretY := 2;
  if FCaretX > Width - 3 then
    FCaretX := Width - 3;
  if FCaretY > Height - 6 then
    FCaretY := Height - 6;
  Cursor.Request(FCaretX, FCaretY, True, FShape, True);
  FStatus.Text := UnicodeString(Format(
    'Caret (%d,%d) shape=%s  — arrows move, button cycles shape',
    [FCaretX, FCaretY, ShapeName]));
  Invalidate;
end;

procedure TCursorDemoApp.AfterConstruction;
begin
  inherited AfterConstruction;
  Cursor.Capabilities := LuxCursorCapsFull;

  FMain := TLuxVerticalLayout.Create(Root);
  FMain.Padding := LuxPaddingAll(1);
  FMain.Spacing := 1;

  FHint := TLuxLabel.Create(FMain);
  FHint.Text := 'Cursor demo — logical caret via TLuxCursorManager (Esc/q quit).';
  FHint.Foreground := LuxColorRGB(210, 210, 220);
  FHint.Background := LuxColorRGB(16, 16, 24);
  FHint.PreferredHeight := 1;

  FStatus := TLuxLabel.Create(FMain);
  FStatus.Foreground := LuxColorRGB(180, 180, 190);
  FStatus.Background := LuxColorRGB(16, 16, 24);
  FStatus.PreferredHeight := 1;

  FField := TLuxPanel.Create(FMain);
  FField.BorderStyle := lbsSingle;
  FField.Background := LuxColorRGB(24, 28, 36);
  FField.Foreground := LuxColorRGB(120, 140, 160);
  FField.Expand := 1;

  FActions := TLuxHorizontalLayout.Create(FMain);
  FActions.Spacing := 2;
  FActions.PreferredHeight := 1;

  FCycle := TLuxButton.Create(FActions);
  FCycle.Text := 'Cycle shape';
  FCycle.OnClick := @CycleClick;
  FCycle.PreferredWidth := 16;
  FCycle.PreferredHeight := 1;

  FQuit := TLuxButton.Create(FActions);
  FQuit.Text := 'Quit';
  FQuit.OnClick := @QuitClick;
  FQuit.PreferredWidth := 10;
  FQuit.PreferredHeight := 1;

  FCaretX := 4;
  FCaretY := 4;
  FShape := lcsBar;
  Focus.SetFocus(FCycle);
  SyncCaret;
end;

procedure TCursorDemoApp.CycleClick(Sender: TObject);
begin
  case FShape of
    lcsDefault: FShape := lcsBlock;
    lcsBlock: FShape := lcsUnderline;
    lcsUnderline: FShape := lcsBar;
  else
    FShape := lcsDefault;
  end;
  SyncCaret;
end;

procedure TCursorDemoApp.QuitClick(Sender: TObject);
begin
  RequestQuit;
end;

function TCursorDemoApp.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  if (Event.Kind = ekKey) and (Event.Key.Action <> kaRelease) then
  begin
    if (Event.Key.Key = lkEscape) or
       ((Event.Key.Key = lkChar) and (Event.Key.Ch = 'q')) then
    begin
      RequestQuit;
      Exit(True);
    end;
    case Event.Key.Key of
      lkLeft:
        begin
          Dec(FCaretX);
          SyncCaret;
          Exit(True);
        end;
      lkRight:
        begin
          Inc(FCaretX);
          SyncCaret;
          Exit(True);
        end;
      lkUp:
        begin
          Dec(FCaretY);
          SyncCaret;
          Exit(True);
        end;
      lkDown:
        begin
          Inc(FCaretY);
          SyncCaret;
          Exit(True);
        end;
    end;
  end;
  Result := inherited HandleEvent(Event);
end;

procedure TCursorDemoApp.RenderContent(ASurface: TLuxSurface);
begin
  inherited RenderContent(ASurface);
  { Soft mark under caret cell so position is visible even if shape unsupported. }
  if (FCaretX >= 0) and (FCaretY >= 0) and
     (FCaretX < ASurface.Width) and (FCaretY < ASurface.Height) then
    ASurface.PutCell(FCaretX, FCaretY,
      LuxCellMake('_', 1, LuxColorRGB(255, 220, 120), LuxColorRGB(24, 28, 36), []));
end;

end.
