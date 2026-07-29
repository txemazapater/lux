# ADR 0015: Shared client-area contract and thin appearance seam (S1)

## Status

Accepted — Stabilization S1.

## Context

Architecture review (`docs/architecture-review-2026-07.md`) asked to stabilize client-area geometry and stop scattering glyph/color literals before more controls. Success criterion for S1: **nobody notices except framework developers** — demos and apps keep the same pixels.

## Decision

### Client area

On every `TLuxControl`:

- `ContentOffset` — top-left inset of the child coordinate origin (symmetric bottom/right for current chrome).
- `ClientRect` — client rectangle in **control-local** coordinates: origin = `ContentOffset`, size = available client cells.
- `ClientSize` — `ClientRect` width/height (derived; not an independent policy).

Panel (border), GroupBox, and ScrollView (full bounds as viewport) obey this contract. Layout and expand-fill continue to place children in content space where `(0,0)` is the client origin.

### Thin appearance seam

- Unit `Lux.Appearance` provides `TLuxAppearance` with `Color(role)` and `Glyph(id)`.
- `LuxBuiltinAppearance` returns the same values previously hardcoded in Phase 6 controls.
- `TLuxPaintContext.Appearance` carries the active appearance (nil → builtin).
- `TLuxControlApplication` injects the app appearance when rendering the root.
- **No** `.luxtheme` files, path discovery, or Registry (Phase 7 / ADR 0013).

Controls migrate border/indicator literals to glyph IDs without changing strings or colors.

### Public API + memory ownership (S1)

S1 exposes a minimal public hook to swap the active appearance used by paint:

- `TLuxControlApplication.Appearance`: read-only reference to the currently active appearance.
- `TLuxControlApplication.SetAppearance(AAppearance)`: sets the active appearance used by `TLuxPaintContext`.

Memory ownership:

- `TLuxControlApplication` does **not** take ownership of the `TLuxAppearance` instance passed to `SetAppearance`.
- The caller must keep the appearance object alive while the application may paint.
- Passing `nil` reverts to the builtin appearance.

### Do active appearance colors work in S1?

S1 installs the seam, but it does **not** yet guarantee that *all* controls fully use
`TLuxAppearance.Color(role)` for their runtime colors.

Reasons:

- Many existing controls still cache colors in control-local state (`TLuxControlStyle`,
  or explicit `Foreground` / `Background`) initialized from the builtin defaults.
- In this slice we route `TLuxPaintContext.Appearance` and migrate the most visible glyph/disabled
  cases behind `Lux.Appearance`, so visual output stays identical for builtin appearance.

Result:

- Active appearance switching is available for framework developers.
- Visible color role remapping across every control is deferred to the full Appearance work
  (Phase 7 / follow-up slices).

### Non-goals

Visible UX changes, theme switching UI, shared border painter API beyond glyph lookup, Range model (S2).

## Consequences

- New controls should consume `LuxCtxAppearance` / glyph IDs instead of new literals.
- Full Appearance System (ADR 0013) builds on this seam later.
- `examples/debug` remains demo-only.
