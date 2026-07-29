{ Phase 6C scroll demo. Shows a ScrollView with clickable content,
  wheel scrolling, EnsureVisible, and an event log. }
unit ScrollDemo;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Geometry,
  Lux.Color,
  Lux.Cell,
  Lux.Events,
  Lux.EventSource,
  Lux.Terminal.Writer,
  Lux.Surface,
  Lux.Control,
  Lux.ControlContainer,
  Lux.ControlApplication,
  Lux.ScrollView,
  Lux.Panel,
  Lux.Button;

type
  TScrollDemoApp = class(TLuxControlApplication)
  private
    FScrollView: TLuxScrollView;
    FContent: TLuxPanel;
    FStatusLine: UnicodeString;
    FButtons: array[0..9] of TLuxButton;
    FEnsureBtn: TLuxButton;
    procedure OnButtonClick(Sender: TObject);
    procedure OnEnsureClick(Sender: TObject);
    procedure RefreshStatus;
  protected
    function HandleEvent(const Event: TLuxEvent): Boolean; override;
  public
    constructor Create(AWriter: ILuxTerminalWriter; ASource: ILuxEventSource;
      AWidth, AHeight: Integer);
  end;

implementation

constructor TScrollDemoApp.Create(AWriter: ILuxTerminalWriter;
  ASource: ILuxEventSource; AWidth, AHeight: Integer);
var
  I: Integer;
begin
  inherited Create(AWriter, ASource, AWidth, AHeight);

  FScrollView := TLuxScrollView.Create(Root);
  FScrollView.SetBounds(0, 1, Width, Height - 2);
  FScrollView.WheelScrollStep := 2;

  FContent := TLuxPanel.Create(nil);
  FContent.BorderStyle := lbsNone;
  FContent.SetBounds(0, 0, Width - 2, 40);
  FScrollView.Content := FContent;

  for I := 0 to 9 do
  begin
    FButtons[I] := TLuxButton.Create(FContent);
    FButtons[I].SetBounds(1, I * 3, 16, 1);
    FButtons[I].Text := 'Button ' + IntToStr(I);
    FButtons[I].OnClick := @OnButtonClick;
  end;

  FEnsureBtn := TLuxButton.Create(Root);
  FEnsureBtn.SetBounds(0, Height - 1, 20, 1);
  FEnsureBtn.Text := 'EnsureVisible #9';
  FEnsureBtn.OnClick := @OnEnsureClick;

  Focus.SetFocus(FEnsureBtn);
  RefreshStatus;
end;

procedure TScrollDemoApp.OnButtonClick(Sender: TObject);
begin
  FStatusLine := 'Clicked: ' + TLuxButton(Sender).Text;
  Invalidate;
end;

procedure TScrollDemoApp.OnEnsureClick(Sender: TObject);
begin
  FScrollView.EnsureVisible(FButtons[9]);
  FStatusLine := 'EnsureVisible #9 done';
  Invalidate;
end;

procedure TScrollDemoApp.RefreshStatus;
begin
  FStatusLine := Format('Scroll Y=%d/%d  Q=quit',
    [FScrollView.ScrollY, FScrollView.MaximumScrollY]);
end;

function TScrollDemoApp.HandleEvent(const Event: TLuxEvent): Boolean;
begin
  Result := inherited HandleEvent(Event);
  if (Event.Kind = ekKey) and (Event.Key.Action = kaPress) then
  begin
    if (Event.Key.Key = lkChar) and ((Event.Key.Ch = 'q') or (Event.Key.Ch = 'Q')) then
      RequestQuit
    else
      RefreshStatus;
  end
  else if Event.Kind = ekMouse then
    RefreshStatus;
end;

end.
