{ Shared Phase 6A layout demo body — composition without absolute coordinates. }
unit ControlsDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.ControlApplication,
  Lux.Panel,
  Lux.Labels,
  Lux.Button,
  Lux.Color,
  Lux.Layout,
  Lux.Layout.Vertical,
  Lux.Layout.Horizontal;

type
  TControlsDemoApp = class(TLuxControlApplication)
  private
    FMain: TLuxVerticalLayout;
    FPanel: TLuxPanel;
    FBody: TLuxVerticalLayout;
    FTitle: TLuxLabel;
    FStatus: TLuxLabel;
    FButtons: TLuxHorizontalLayout;
    FOk: TLuxButton;
    FQuit: TLuxButton;
    procedure OkClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
  public
    procedure AfterConstruction; override;
  end;

implementation

procedure TControlsDemoApp.AfterConstruction;
begin
  inherited AfterConstruction;

  { Root fills FMain; FMain lays out children. No SetBounds in app code. }
  FMain := TLuxVerticalLayout.Create(Root);
  FMain.Padding := LuxPaddingAll(1);
  FMain.Spacing := 0;

  FPanel := TLuxPanel.Create(FMain);
  FPanel.BorderStyle := lbsSingle;
  FPanel.Background := LuxColorRGB(20, 20, 40);
  FPanel.Foreground := LuxColorRGB(200, 200, 220);
  FPanel.Expand := 1;

  FBody := TLuxVerticalLayout.Create(FPanel);
  FBody.Padding := LuxPaddingAll(1);
  FBody.Spacing := 1;
  FBody.Expand := 1;

  FTitle := TLuxLabel.Create(FBody);
  FTitle.Text := 'LUX Layout Demo';
  FTitle.Foreground := LuxColorRGB(220, 220, 255);
  FTitle.Background := FPanel.Background;
  FTitle.PreferredHeight := 1;

  FStatus := TLuxLabel.Create(FBody);
  FStatus.Text := 'Tab / Shift+Tab to focus. Enter/Space or click.';
  FStatus.Foreground := LuxColorRGB(180, 180, 180);
  FStatus.Background := FPanel.Background;
  FStatus.PreferredHeight := 1;

  FButtons := TLuxHorizontalLayout.Create(FBody);
  FButtons.Spacing := 2;
  FButtons.PreferredHeight := 1;

  FOk := TLuxButton.Create(FButtons);
  FOk.Text := 'OK';
  FOk.OnClick := @OkClick;
  FOk.PreferredWidth := 12;
  FOk.PreferredHeight := 1;

  FQuit := TLuxButton.Create(FButtons);
  FQuit.Text := 'Quit';
  FQuit.OnClick := @QuitClick;
  FQuit.PreferredWidth := 12;
  FQuit.PreferredHeight := 1;

  Focus.SetFocus(FOk);
end;

procedure TControlsDemoApp.OkClick(Sender: TObject);
begin
  FStatus.Text := 'OK clicked';
end;

procedure TControlsDemoApp.QuitClick(Sender: TObject);
begin
  RequestQuit;
end;

end.
