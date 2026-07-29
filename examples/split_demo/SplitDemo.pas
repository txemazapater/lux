{ Phase 6B.3 split container demo body. }
unit SplitDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.ControlApplication,
  Lux.Panel,
  Lux.Labels,
  Lux.Button,
  Lux.Color,
  Lux.Cursor,
  Lux.Layout,
  Lux.Layout.Vertical,
  Lux.Layout.Split,
  Lux.Events;

type
  TSplitDemoApp = class(TLuxControlApplication)
  private
    FMain: TLuxVerticalLayout;
    FHint: TLuxLabel;
    FStatus: TLuxLabel;
    FOuter: TLuxSplitContainer;
    FLeft: TLuxPanel;
    FLeftLabel: TLuxLabel;
    FRightHost: TLuxPanel;
    FInner: TLuxSplitContainer;
    FTop: TLuxPanel;
    FTopLabel: TLuxLabel;
    FBottom: TLuxPanel;
    FBottomLabel: TLuxLabel;
    FActions: TLuxVerticalLayout;
    FQuit: TLuxButton;
    procedure QuitClick(Sender: TObject);
    procedure RefreshStatus;
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure Update; override;
  public
    procedure AfterConstruction; override;
  end;

implementation

function TSplitDemoApp.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  if (Event.Kind = ekKey) and (Event.Key.Action <> kaRelease) then
  begin
    if (Event.Key.Key = lkEscape) or
       ((Event.Key.Key = lkChar) and (Event.Key.Ch = 'q')) then
    begin
      RequestQuit;
      Exit(True);
    end;
  end;
  Result := inherited HandleEvent(Event);
end;

procedure TSplitDemoApp.RefreshStatus;
begin
  FStatus.Text := UnicodeString(Format(
    'Outer ratio=%d  left=%d  right=%d  |  Inner ratio=%d  drag=%s hover=%s',
    [FOuter.Ratio, FLeft.Width, FRightHost.Width, FInner.Ratio,
     BoolToStr(FOuter.Dragging or FInner.Dragging, True),
     BoolToStr(FOuter.Hovered or FInner.Hovered, True)]));
end;

procedure TSplitDemoApp.Update;
begin
  inherited Update;
  RefreshStatus;
end;

procedure TSplitDemoApp.AfterConstruction;
begin
  inherited AfterConstruction;
  Cursor.Capabilities := LuxCursorCapsFull;

  FMain := TLuxVerticalLayout.Create(Root);
  FMain.Padding := LuxPaddingAll(1);
  FMain.Spacing := 1;

  FHint := TLuxLabel.Create(FMain);
  FHint.Text :=
    'Split demo — drag dividers. Nested split on the right. Esc/q quit.';
  FHint.Foreground := LuxColorRGB(200, 200, 210);
  FHint.Background := LuxColorRGB(16, 16, 24);
  FHint.PreferredHeight := 1;

  FStatus := TLuxLabel.Create(FMain);
  FStatus.Foreground := LuxColorRGB(180, 220, 180);
  FStatus.Background := LuxColorRGB(16, 16, 24);
  FStatus.PreferredHeight := 1;

  FOuter := TLuxSplitContainer.Create(FMain);
  FOuter.Expand := 1;
  FOuter.Orientation := loVertical;
  FOuter.Ratio := LuxSplitRatioHalf;
  FOuter.DividerSize := 1;
  FOuter.FirstMinimumSize := 8;
  FOuter.SecondMinimumSize := 12;

  FLeft := TLuxPanel.Create(FOuter);
  FLeft.BorderStyle := lbsSingle;
  FLeft.Background := LuxColorRGB(35, 55, 80);
  FLeft.Foreground := LuxColorRGB(180, 210, 240);

  FLeftLabel := TLuxLabel.Create(FLeft);
  FLeftLabel.Text := 'LEFT pane';
  FLeftLabel.Foreground := LuxColorRGB(220, 235, 255);
  FLeftLabel.Background := FLeft.Background;
  FLeftLabel.Expand := 1;

  FRightHost := TLuxPanel.Create(FOuter);
  FRightHost.BorderStyle := lbsNone;
  FRightHost.Background := LuxColorRGB(20, 20, 28);

  FInner := TLuxSplitContainer.Create(FRightHost);
  FInner.Expand := 1;
  FInner.Orientation := loHorizontal;
  FInner.Ratio := 4000;
  FInner.DividerSize := 1;
  FInner.FirstMinimumSize := 3;
  FInner.SecondMinimumSize := 3;

  FTop := TLuxPanel.Create(FInner);
  FTop.BorderStyle := lbsSingle;
  FTop.Background := LuxColorRGB(70, 45, 55);
  FTop.Foreground := LuxColorRGB(240, 200, 210);

  FTopLabel := TLuxLabel.Create(FTop);
  FTopLabel.Text := 'TOP (nested)';
  FTopLabel.Foreground := LuxColorRGB(255, 220, 230);
  FTopLabel.Background := FTop.Background;
  FTopLabel.Expand := 1;

  FBottom := TLuxPanel.Create(FInner);
  FBottom.BorderStyle := lbsSingle;
  FBottom.Background := LuxColorRGB(45, 70, 50);
  FBottom.Foreground := LuxColorRGB(200, 240, 200);

  FBottomLabel := TLuxLabel.Create(FBottom);
  FBottomLabel.Text := 'BOTTOM (nested)';
  FBottomLabel.Foreground := LuxColorRGB(220, 255, 220);
  FBottomLabel.Background := FBottom.Background;
  FBottomLabel.Expand := 1;

  FActions := TLuxVerticalLayout.Create(FMain);
  FActions.PreferredHeight := 1;

  FQuit := TLuxButton.Create(FActions);
  FQuit.Text := 'Quit';
  FQuit.OnClick := @QuitClick;
  FQuit.PreferredHeight := 1;
  FQuit.PreferredWidth := 10;

  Focus.SetFocus(FQuit);
  RefreshStatus;
end;

procedure TSplitDemoApp.QuitClick(Sender: TObject);
begin
  RequestQuit;
end;

end.
