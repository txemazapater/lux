{ Phase 6D form controls demo: Label, CheckBox, RadioButton. }
unit FormDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Control,
  Lux.ControlApplication,
  Lux.Panel,
  Lux.Labels,
  Lux.Button,
  Lux.CheckBox,
  Lux.RadioButton,
  Lux.Layout,
  Lux.Layout.Vertical,
  Lux.Events;

type
  TFormDemoApp = class(TLuxControlApplication)
  private
    FMain: TLuxVerticalLayout;
    FTitle: TLuxLabel;
    FUnicode: TLuxLabel;
    FCb1, FCb2, FCbDisabled: TLuxCheckBox;
    FGroupSize: TLuxPanel;
    FSizeLbl: TLuxLabel;
    FRadS, FRadM, FRadL: TLuxRadioButton;
    FGroupColor: TLuxPanel;
    FColorLbl: TLuxLabel;
    FRadRed, FRadGreen, FRadBlue: TLuxRadioButton;
    FStatus: TLuxLabel;
    FQuit: TLuxButton;
    procedure RefreshStatus;
    procedure OnAnyChange(Sender: TObject);
    procedure QuitClick(Sender: TObject);
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
    procedure Update; override;
  public
    procedure AfterConstruction; override;
  end;

implementation

procedure TFormDemoApp.AfterConstruction;
begin
  inherited AfterConstruction;

  FMain := TLuxVerticalLayout.Create(Root);
  FMain.Padding := LuxPaddingAll(1);
  FMain.Spacing := 0;
  FMain.Expand := 1;

  FTitle := TLuxLabel.Create(FMain);
  FTitle.Text := 'Phase 6D — Label / CheckBox / RadioButton';
  FTitle.PreferredHeight := 1;

  FUnicode := TLuxLabel.Create(FMain);
  FUnicode.Text := 'Unicode: caf' + UnicodeString(#$00E9) + ' · ' +
    UnicodeString(#$65E5) + UnicodeString(#$672C) + UnicodeString(#$8A9E);
  FUnicode.PreferredHeight := 1;

  FCb1 := TLuxCheckBox.Create(FMain);
  FCb1.Text := 'Enable notifications';
  FCb1.OnChange := @OnAnyChange;

  FCb2 := TLuxCheckBox.Create(FMain);
  FCb2.Text := 'Remember me';
  FCb2.Checked := True;
  FCb2.OnChange := @OnAnyChange;

  FCbDisabled := TLuxCheckBox.Create(FMain);
  FCbDisabled.Text := 'Disabled option';
  FCbDisabled.Enabled := False;

  FGroupSize := TLuxPanel.Create(FMain);
  FGroupSize.BorderStyle := lbsSingle;
  FGroupSize.PreferredHeight := 5;
  FGroupSize.Expand := 0;

  FSizeLbl := TLuxLabel.Create(FGroupSize);
  FSizeLbl.Text := 'Size (group A)';
  FSizeLbl.SetBounds(1, 0, 20, 1);

  FRadS := TLuxRadioButton.Create(FGroupSize);
  FRadS.Text := 'Small';
  FRadS.SetBounds(1, 1, 18, 1);
  FRadS.OnChange := @OnAnyChange;

  FRadM := TLuxRadioButton.Create(FGroupSize);
  FRadM.Text := 'Medium';
  FRadM.SetBounds(1, 2, 18, 1);
  FRadM.Checked := True;
  FRadM.OnChange := @OnAnyChange;

  FRadL := TLuxRadioButton.Create(FGroupSize);
  FRadL.Text := 'Large';
  FRadL.SetBounds(1, 3, 18, 1);
  FRadL.OnChange := @OnAnyChange;

  FGroupColor := TLuxPanel.Create(FMain);
  FGroupColor.BorderStyle := lbsSingle;
  FGroupColor.PreferredHeight := 5;
  FGroupColor.Expand := 0;

  FColorLbl := TLuxLabel.Create(FGroupColor);
  FColorLbl.Text := 'Color (group B — independent)';
  FColorLbl.SetBounds(1, 0, 30, 1);

  FRadRed := TLuxRadioButton.Create(FGroupColor);
  FRadRed.Text := 'Red';
  FRadRed.SetBounds(1, 1, 18, 1);
  FRadRed.Checked := True;
  FRadRed.OnChange := @OnAnyChange;

  FRadGreen := TLuxRadioButton.Create(FGroupColor);
  FRadGreen.Text := 'Green';
  FRadGreen.SetBounds(1, 2, 18, 1);
  FRadGreen.OnChange := @OnAnyChange;

  FRadBlue := TLuxRadioButton.Create(FGroupColor);
  FRadBlue.Text := 'Blue';
  FRadBlue.SetBounds(1, 3, 18, 1);
  FRadBlue.OnChange := @OnAnyChange;

  FStatus := TLuxLabel.Create(FMain);
  FStatus.PreferredHeight := 1;

  FQuit := TLuxButton.Create(FMain);
  FQuit.Text := 'Quit';
  FQuit.PreferredWidth := 10;
  FQuit.PreferredHeight := 1;
  FQuit.OnClick := @QuitClick;

  Focus.SetFocus(FCb1);
  RefreshStatus;
end;

procedure TFormDemoApp.OnAnyChange(Sender: TObject);
begin
  RefreshStatus;
end;

procedure TFormDemoApp.QuitClick(Sender: TObject);
begin
  RequestQuit;
end;

procedure TFormDemoApp.RefreshStatus;
var
  SizeSel, ColorSel: UnicodeString;
begin
  if FRadS.Checked then
    SizeSel := 'Small'
  else if FRadM.Checked then
    SizeSel := 'Medium'
  else if FRadL.Checked then
    SizeSel := 'Large'
  else
    SizeSel := '(none)';

  if FRadRed.Checked then
    ColorSel := 'Red'
  else if FRadGreen.Checked then
    ColorSel := 'Green'
  else if FRadBlue.Checked then
    ColorSel := 'Blue'
  else
    ColorSel := '(none)';

  FStatus.Text := Format(
    'Cb1=%s Cb2=%s Size=%s Color=%s Focus=%s  Tab/Space/Click  Q=quit',
    [BoolToStr(FCb1.Checked, True), BoolToStr(FCb2.Checked, True),
     SizeSel, ColorSel,
     BoolToStr(Focus.FocusedControl <> nil, True)]);
end;

function TFormDemoApp.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  if (Event.Kind = ekKey) and (Event.Key.Action <> kaRelease) then
  begin
    if (Event.Key.Key = lkChar) and
      ((Event.Key.Ch = 'q') or (Event.Key.Ch = 'Q')) then
    begin
      RequestQuit;
      Exit(True);
    end;
  end;
  Result := inherited HandleEvent(Event);
end;

procedure TFormDemoApp.Update;
begin
  inherited Update;
  RefreshStatus;
end;

end.
