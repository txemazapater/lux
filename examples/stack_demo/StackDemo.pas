{ Phase 6B.1 stack overlay demo body. }
unit StackDemo;

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
  Lux.Layout.Stack,
  Lux.Events;

type
  TStackDemoApp = class(TLuxControlApplication)
  private
    FMain: TLuxVerticalLayout;
    FHint: TLuxLabel;
    FStack: TLuxStackLayout;
    FBack: TLuxPanel;
    FFront: TLuxPanel;
    FBackLabel: TLuxLabel;
    FFrontLabel: TLuxLabel;
    FActions: TLuxVerticalLayout;
    FSwap: TLuxButton;
    FQuit: TLuxButton;
    procedure SwapClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
  public
    procedure AfterConstruction; override;
  end;

implementation

function TStackDemoApp.HandleEvent(const Event: TLuxEvent): Boolean;
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

procedure TStackDemoApp.AfterConstruction;
begin
  inherited AfterConstruction;

  FMain := TLuxVerticalLayout.Create(Root);
  FMain.Padding := LuxPaddingAll(1);
  FMain.Spacing := 1;

  FHint := TLuxLabel.Create(FMain);
  FHint.Text := 'Stack demo — layers share one area. BringToFront cycles z-order.';
  FHint.Foreground := LuxColorRGB(200, 200, 210);
  FHint.Background := LuxColorRGB(16, 16, 24);
  FHint.PreferredHeight := 1;

  FStack := TLuxStackLayout.Create(FMain);
  FStack.Expand := 1;
  FStack.Padding := LuxPaddingAll(0);

  FBack := TLuxPanel.Create(FStack);
  FBack.BorderStyle := lbsSingle;
  FBack.Background := LuxColorRGB(40, 60, 90);
  FBack.Foreground := LuxColorRGB(180, 200, 230);

  FBackLabel := TLuxLabel.Create(FBack);
  FBackLabel.Text := 'BACK layer';
  FBackLabel.Foreground := LuxColorRGB(220, 230, 255);
  FBackLabel.Background := FBack.Background;
  FBackLabel.Expand := 1;

  FFront := TLuxPanel.Create(FStack);
  FFront.BorderStyle := lbsSingle;
  FFront.Background := LuxColorRGB(90, 40, 50);
  FFront.Foreground := LuxColorRGB(240, 200, 200);

  FFrontLabel := TLuxLabel.Create(FFront);
  FFrontLabel.Text := 'FRONT layer (on top)';
  FFrontLabel.Foreground := LuxColorRGB(255, 220, 220);
  FFrontLabel.Background := FFront.Background;
  FFrontLabel.Expand := 1;

  FActions := TLuxVerticalLayout.Create(FMain);
  FActions.Spacing := 1;
  FActions.PreferredHeight := 3;

  FSwap := TLuxButton.Create(FActions);
  FSwap.Text := 'Bring back to front';
  FSwap.OnClick := @SwapClick;
  FSwap.PreferredHeight := 1;
  FSwap.PreferredWidth := 24;

  FQuit := TLuxButton.Create(FActions);
  FQuit.Text := 'Quit';
  FQuit.OnClick := @QuitClick;
  FQuit.PreferredHeight := 1;
  FQuit.PreferredWidth := 12;

  Focus.SetFocus(FSwap);
end;

procedure TStackDemoApp.SwapClick(Sender: TObject);
begin
  if FStack.IndexOfChild(FBack) < FStack.IndexOfChild(FFront) then
  begin
    FStack.BringToFront(FBack);
    FHint.Text := 'BACK is now frontmost (hit-test / paint order).';
    FSwap.Text := 'Bring other to front';
  end
  else
  begin
    FStack.BringToFront(FFront);
    FHint.Text := 'FRONT is now frontmost again.';
    FSwap.Text := 'Bring back to front';
  end;
end;

procedure TStackDemoApp.QuitClick(Sender: TObject);
begin
  RequestQuit;
end;

end.
