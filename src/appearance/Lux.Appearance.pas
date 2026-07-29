{ Thin in-memory appearance seam (S1). No theme files. Visual defaults match Phase 6. }
unit Lux.Appearance;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Lux.Color;

type
  { Semantic color roles. Values match today's LuxDefaultControlStyle / defaults. }
  TLuxColorRole = (
    lcrDefault,
    lcrText,
    lcrTextDisabled,
    lcrSurface,
    lcrFocusForeground,
    lcrFocusBackground,
    lcrBorder
  );

  { Glyph identifiers used by controls. Strings are identical to Phase 6 literals. }
  TLuxGlyphId = (
    lgBoxTL,
    lgBoxTR,
    lgBoxBL,
    lgBoxBR,
    lgBoxH,
    lgBoxV,
    lgCheckChecked,
    lgCheckUnchecked,
    lgRadioChecked,
    lgRadioUnchecked,
    lgToggleOn,
    lgToggleOff,
    lgFocusMarker,
    lgFocusPad,
    lgSepHorizontal,
    lgSepVertical
  );

  TLuxAppearance = class
  public
    function Color(ARole: TLuxColorRole): TLuxColor; virtual;
    function Glyph(AId: TLuxGlyphId): UnicodeString; virtual;
  end;

{ Shared built-in appearance. Same pixels as pre-S1 hardcoded controls. }
function LuxBuiltinAppearance: TLuxAppearance;

implementation

type
  TLuxBuiltinAppearance = class(TLuxAppearance)
  end;

var
  GBuiltin: TLuxAppearance = nil;

function LuxBuiltinAppearance: TLuxAppearance;
begin
  if GBuiltin = nil then
    GBuiltin := TLuxBuiltinAppearance.Create;
  Result := GBuiltin;
end;

function TLuxAppearance.Color(ARole: TLuxColorRole): TLuxColor;
begin
  case ARole of
    lcrDefault, lcrText, lcrSurface, lcrBorder:
      Result := LuxColorDefault;
    lcrTextDisabled:
      Result := LuxColorRGB(128, 128, 128);
    lcrFocusForeground:
      Result := LuxColorRGB(0, 0, 0);
    lcrFocusBackground:
      Result := LuxColorRGB(200, 200, 200);
  else
    Result := LuxColorDefault;
  end;
end;

function TLuxAppearance.Glyph(AId: TLuxGlyphId): UnicodeString;
begin
  case AId of
    lgBoxTL:
      Result := UnicodeString(WideChar($250C));
    lgBoxTR:
      Result := UnicodeString(WideChar($2510));
    lgBoxBL:
      Result := UnicodeString(WideChar($2514));
    lgBoxBR:
      Result := UnicodeString(WideChar($2518));
    lgBoxH, lgSepHorizontal:
      Result := UnicodeString(WideChar($2500));
    lgBoxV, lgSepVertical:
      Result := UnicodeString(WideChar($2502));
    lgCheckChecked:
      Result := '[x]';
    lgCheckUnchecked:
      Result := '[ ]';
    lgRadioChecked:
      Result := '(*)';
    lgRadioUnchecked:
      Result := '( )';
    lgToggleOn:
      Result := '[  ON ]';
    lgToggleOff:
      Result := '[ OFF ]';
    lgFocusMarker:
      Result := '>';
    lgFocusPad:
      Result := ' ';
  else
    Result := ' ';
  end;
end;

finalization
  FreeAndNil(GBuiltin);

end.
