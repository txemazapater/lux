{ Stack layout: all visible children share the same client area. }
unit Lux.Layout.Stack;

{$mode objfpc}{$H+}

interface

uses
  Lux.Geometry,
  Lux.Control,
  Lux.Layout;

type
  { Overlapping layout box. Visible children receive identical bounds
    (InnerRect). Expand/Preferred are ignored for geometry. Z-order is the
    existing child list order (BringToFront / SendToBack). }
  TLuxStackLayout = class(TLuxLayoutBox)
  protected
    procedure PerformLayout; override;
  end;

implementation

procedure TLuxStackLayout.PerformLayout;
var
  Inner: TLuxRect;
  N, I, W, H: Integer;
  Child: TLuxControl;
begin
  Inner := InnerRect;
  N := VisibleChildCount;
  if N = 0 then
    Exit;

  for I := 0 to N - 1 do
  begin
    Child := VisibleChild(I);
    W := Inner.Width;
    H := Inner.Height;
    if W < Child.MinWidth then
      W := Child.MinWidth;
    if H < Child.MinHeight then
      H := Child.MinHeight;
    Child.SetBounds(Inner.Left, Inner.Top, W, H);
  end;
end;

end.
