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

### Non-goals

Visible UX changes, theme switching UI, shared border painter API beyond glyph lookup, Range model (S2).

## Consequences

- New controls should consume `LuxCtxAppearance` / glyph IDs instead of new literals.
- Full Appearance System (ADR 0013) builds on this seam later.
- `examples/debug` remains demo-only.
