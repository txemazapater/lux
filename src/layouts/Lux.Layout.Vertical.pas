{ Vertical layout box: stacks visible children top to bottom. }
unit Lux.Layout.Vertical;

{$mode objfpc}{$H+}

interface

uses
  Lux.Geometry,
  Lux.Control,
  Lux.Layout;

type
  TLuxVerticalLayout = class(TLuxLayoutBox)
  protected
    procedure PerformLayout; override;
  end;

implementation

procedure TLuxVerticalLayout.PerformLayout;
var
  Inner: TLuxRect;
  N, I, Y, H, W, Extra, WeightSum, Share, Remain, LastExpand: Integer;
  Child: TLuxControl;
  PrefHeights: array of Integer;
  Weights: array of Integer;
begin
  Inner := InnerRect;
  N := VisibleChildCount;
  if N = 0 then
    Exit;

  SetLength(PrefHeights, N);
  SetLength(Weights, N);
  WeightSum := 0;
  Extra := Inner.Height;
  if N > 1 then
    Dec(Extra, Spacing * (N - 1));

  for I := 0 to N - 1 do
  begin
    Child := VisibleChild(I);
    PrefHeights[I] := Child.ResolvedPreferredHeight;
    Weights[I] := Child.Expand;
    Inc(WeightSum, Weights[I]);
    Dec(Extra, PrefHeights[I]);
  end;

  if Extra < 0 then
    Extra := 0;
  Remain := Extra;
  Y := Inner.Top;
  LastExpand := -1;
  for I := 0 to N - 1 do
    if Weights[I] > 0 then
      LastExpand := I;

  for I := 0 to N - 1 do
  begin
    Child := VisibleChild(I);
    if Weights[I] > 0 then
    begin
      if WeightSum > 0 then
        Share := (Extra * Weights[I]) div WeightSum
      else
        Share := 0;
      if I = LastExpand then
        Share := Remain;
      Dec(Remain, Share);
      H := PrefHeights[I] + Share;
    end
    else
      H := PrefHeights[I];

    if H < Child.MinHeight then
      H := Child.MinHeight;

    W := Inner.Width;
    if W < Child.MinWidth then
      W := Child.MinWidth;
    Child.SetBounds(Inner.Left, Y, W, H);
    Inc(Y, H);
    if I < N - 1 then
      Inc(Y, Spacing);
  end;
end;

end.
