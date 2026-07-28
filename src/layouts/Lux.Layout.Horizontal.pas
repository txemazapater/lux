{ Horizontal layout box: stacks visible children left to right. }
unit Lux.Layout.Horizontal;

{$mode objfpc}{$H+}

interface

uses
  Lux.Geometry,
  Lux.Control,
  Lux.Layout;

type
  TLuxHorizontalLayout = class(TLuxLayoutBox)
  protected
    procedure PerformLayout; override;
  end;

implementation

procedure TLuxHorizontalLayout.PerformLayout;
var
  Inner: TLuxRect;
  N, I, X, W, H, Extra, WeightSum, Share, Remain, LastExpand: Integer;
  Child: TLuxControl;
  PrefWidths: array of Integer;
  Weights: array of Integer;
begin
  Inner := InnerRect;
  N := VisibleChildCount;
  if N = 0 then
    Exit;

  SetLength(PrefWidths, N);
  SetLength(Weights, N);
  WeightSum := 0;
  Extra := Inner.Width;
  if N > 1 then
    Dec(Extra, Spacing * (N - 1));

  for I := 0 to N - 1 do
  begin
    Child := VisibleChild(I);
    PrefWidths[I] := Child.ResolvedPreferredWidth;
    Weights[I] := Child.Expand;
    Inc(WeightSum, Weights[I]);
    Dec(Extra, PrefWidths[I]);
  end;

  if Extra < 0 then
    Extra := 0;
  Remain := Extra;
  X := Inner.Left;
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
      W := PrefWidths[I] + Share;
    end
    else
      W := PrefWidths[I];

    if W < Child.MinWidth then
      W := Child.MinWidth;

    H := Inner.Height;
    if H < Child.MinHeight then
      H := Child.MinHeight;
    Child.SetBounds(X, Inner.Top, W, H);
    Inc(X, W);
    if I < N - 1 then
      Inc(X, Spacing);
  end;
end;

end.
