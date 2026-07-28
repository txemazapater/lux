{ Shared Phase 5 controls demo body. }
unit ControlsDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Events,
  Lux.ControlApplication,
  Lux.Panel,
  Lux.Labels,
  Lux.Button,
  Lux.Color,
  Lux.Geometry,
  Lux.Control;

type
  TControlsDemoApp = class(TLuxControlApplication)
  private
    FPanel: TLuxPanel;
    FTitle: TLuxLabel;
    FStatus: TLuxLabel;
    FOk: TLuxButton;
    FQuit: TLuxButton;
    procedure LayoutControls;
    procedure OkClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
  protected
    procedure OnResize(AWidth, AHeight: Integer); override;
  public
    procedure AfterConstruction; override;
  end;

implementation

procedure TControlsDemoApp.AfterConstruction;
begin
  inherited AfterConstruction;
  FPanel := TLuxPanel.Create(Root);
  FPanel.BorderStyle := lbsSingle;
  FPanel.Background := LuxColorRGB(20, 20, 40);
  FPanel.Foreground := LuxColorRGB(200, 200, 220);

  FTitle := TLuxLabel.Create(FPanel);
  FTitle.Text := 'LUX Controls Demo';
  FTitle.Foreground := LuxColorRGB(220, 220, 255);
  FTitle.Background := FPanel.Background;

  FStatus := TLuxLabel.Create(FPanel);
  FStatus.Text := 'Tab / Shift+Tab to focus. Enter/Space or click.';
  FStatus.Foreground := LuxColorRGB(180, 180, 180);
  FStatus.Background := FPanel.Background;

  FOk := TLuxButton.Create(FPanel);
  FOk.Text := 'OK';
  FOk.OnClick := @OkClick;

  FQuit := TLuxButton.Create(FPanel);
  FQuit.Text := 'Quit';
  FQuit.OnClick := @QuitClick;

  LayoutControls;
  Focus.SetFocus(FOk);
end;

procedure TControlsDemoApp.LayoutControls;
var
  W, H: Integer;
begin
  W := Width;
  H := Height;
  if W < 20 then
    W := 20;
  if H < 10 then
    H := 10;

  FPanel.SetBounds(2, 1, W - 4, H - 2);
  FTitle.SetBounds(2, 1, FPanel.Width - 6, 1);
  FStatus.SetBounds(2, 3, FPanel.Width - 6, 1);
  FOk.SetBounds(2, 5, 12, 1);
  FQuit.SetBounds(16, 5, 12, 1);
end;

procedure TControlsDemoApp.OnResize(AWidth, AHeight: Integer);
begin
  inherited OnResize(AWidth, AHeight);
  LayoutControls;
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
