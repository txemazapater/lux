{ Phase 6D form controls acceptance demo. }
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
  Lux.Separator,
  Lux.Toggle,
  Lux.GroupBox,
  Lux.Layout,
  Lux.Layout.Vertical,
  Lux.Layout.Horizontal,
  Lux.Events,
  Lux.Debug.EventLog;

type
  TFormDemoApp = class(TLuxControlApplication)
  private
    FColumns: TLuxHorizontalLayout;
    FMain: TLuxVerticalLayout;
    FTitle: TLuxLabel;
    FUnicode: TLuxLabel;
    FCb1, FCb2: TLuxCheckBox;
    FToggle: TLuxToggle;
    FSep: TLuxSeparator;
    FThemeBox: TLuxGroupBox;
    FRadDark, FRadLight, FRadSystem: TLuxRadioButton;
    FDisabledBox: TLuxGroupBox;
    FCbDisabled: TLuxCheckBox;
    FTgDisabled: TLuxToggle;
    FStatus: TLuxLabel;
    FDiag: TLuxLabel;
    FQuit: TLuxButton;
    FLog: TEventLogControl;
    FLastAction: UnicodeString;
    procedure RefreshStatus;
    procedure OnAnyChange(Sender: TObject);
    procedure QuitClick(Sender: TObject);
    function FocusName: UnicodeString;
    function RadioChoice: UnicodeString;
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

  FLastAction := 'ready';

  { Two columns: form controls | Actions log. Do not overlay the log on top of
    FMain — that clipped GroupBox right borders under the opaque log fill. }
  FColumns := TLuxHorizontalLayout.Create(Root);
  FColumns.Padding := LuxPaddingAll(1);
  FColumns.Spacing := 1;
  FColumns.Expand := 1;

  FMain := TLuxVerticalLayout.Create(FColumns);
  FMain.Padding := LuxPaddingAll(0);
  FMain.Spacing := 0;
  FMain.Expand := 1;
  FMain.MinWidth := 24;

  FTitle := TLuxLabel.Create(FMain);
  FTitle.Text := 'Phase 6D — Form controls';
  FTitle.PreferredHeight := 1;

  FUnicode := TLuxLabel.Create(FMain);
  FUnicode.Text := 'Unicode: caf' + UnicodeString(#$00E9) + ' · ' +
    UnicodeString(#$65E5) + UnicodeString(#$672C);
  FUnicode.PreferredHeight := 1;

  FCb1 := TLuxCheckBox.Create(FMain);
  FCb1.Text := 'Show line numbers';
  FCb1.Checked := True;
  FCb1.OnChange := @OnAnyChange;

  FCb2 := TLuxCheckBox.Create(FMain);
  FCb2.Text := 'Highlight current line';
  FCb2.OnChange := @OnAnyChange;

  FToggle := TLuxToggle.Create(FMain);
  FToggle.Text := 'Auto save';
  FToggle.OnChange := @OnAnyChange;

  FSep := TLuxSeparator.Create(FMain);
  FSep.Orientation := loHorizontal;

  FThemeBox := TLuxGroupBox.Create(FMain);
  FThemeBox.Text := 'Theme preference (labels only)';
  FThemeBox.PreferredHeight := 5;
  FThemeBox.Expand := 0;

  FRadDark := TLuxRadioButton.Create(FThemeBox);
  FRadDark.Text := 'Dark';
  FRadDark.SetBounds(0, 0, 20, 1);
  FRadDark.Checked := True;
  FRadDark.OnChange := @OnAnyChange;

  FRadLight := TLuxRadioButton.Create(FThemeBox);
  FRadLight.Text := 'Light';
  FRadLight.SetBounds(0, 1, 20, 1);
  FRadLight.OnChange := @OnAnyChange;

  FRadSystem := TLuxRadioButton.Create(FThemeBox);
  FRadSystem.Text := 'System';
  FRadSystem.SetBounds(0, 2, 20, 1);
  FRadSystem.OnChange := @OnAnyChange;

  FDisabledBox := TLuxGroupBox.Create(FMain);
  FDisabledBox.Text := 'Disabled group';
  FDisabledBox.PreferredHeight := 4;
  FDisabledBox.Expand := 0;
  FDisabledBox.Enabled := False;

  FCbDisabled := TLuxCheckBox.Create(FDisabledBox);
  FCbDisabled.Text := 'Disabled option';
  FCbDisabled.SetBounds(0, 0, 22, 1);

  FTgDisabled := TLuxToggle.Create(FDisabledBox);
  FTgDisabled.Text := 'Disabled toggle';
  FTgDisabled.SetBounds(0, 1, 24, 1);

  FStatus := TLuxLabel.Create(FMain);
  FStatus.PreferredHeight := 1;

  FDiag := TLuxLabel.Create(FMain);
  FDiag.PreferredHeight := 1;

  FQuit := TLuxButton.Create(FMain);
  FQuit.Text := 'Quit';
  FQuit.PreferredWidth := 10;
  FQuit.PreferredHeight := 1;
  FQuit.OnClick := @QuitClick;

  FLog := TEventLogControl.Create(FColumns);
  FLog.Title := 'Actions';
  FLog.Capacity := 64;
  FLog.PreferredWidth := 28;
  FLog.MinWidth := 20;
  FLog.Expand := 0;
  FLog.Add('Demo ready — Tab/Space/Click Q=quit');

  Focus.SetFocus(FCb1);
  RefreshStatus;
end;

function TFormDemoApp.FocusName: UnicodeString;
var
  C: TLuxControl;
begin
  C := Focus.FocusedControl;
  if C = nil then
    Exit('(none)');
  if C is TLuxCheckBox then
    Exit('Cb:' + TLuxCheckBox(C).Text);
  if C is TLuxToggle then
    Exit('Tg:' + TLuxToggle(C).Text);
  if C is TLuxRadioButton then
    Exit('Rad:' + TLuxRadioButton(C).Text);
  if C is TLuxButton then
    Exit('Btn:' + TLuxButton(C).Text);
  Result := C.ClassName;
end;

function TFormDemoApp.RadioChoice: UnicodeString;
begin
  if FRadDark.Checked then
    Exit('Dark');
  if FRadLight.Checked then
    Exit('Light');
  if FRadSystem.Checked then
    Exit('System');
  Result := '(none)';
end;

procedure TFormDemoApp.OnAnyChange(Sender: TObject);
var
  Msg: UnicodeString;
begin
  if Sender is TLuxCheckBox then
    Msg := 'Check ' + TLuxCheckBox(Sender).Text + '=' +
      BoolToStr(TLuxCheckBox(Sender).Checked, True)
  else if Sender is TLuxToggle then
    Msg := 'Toggle ' + TLuxToggle(Sender).Text + '=' +
      BoolToStr(TLuxToggle(Sender).Checked, True)
  else if Sender is TLuxRadioButton then
    Msg := 'Radio ' + TLuxRadioButton(Sender).Text
  else
    Msg := 'Change';
  FLastAction := Msg;
  if FLog <> nil then
    FLog.Add(Msg);
  RefreshStatus;
end;

procedure TFormDemoApp.QuitClick(Sender: TObject);
begin
  RequestQuit;
end;

procedure TFormDemoApp.RefreshStatus;
begin
  FStatus.Text := Format(
    'Cb1=%s Cb2=%s Tg=%s Radio=%s  %dx%d',
    [BoolToStr(FCb1.Checked, True), BoolToStr(FCb2.Checked, True),
     BoolToStr(FToggle.Checked, True), RadioChoice, Width, Height]);
  FDiag.Text := Format('Focus=%s  Last=%s', [FocusName, FLastAction]);
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
