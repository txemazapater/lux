# ADR 0016: Shared Range model (S2)

## Status

Accepted — Stabilization S2.

## Context

Architecture review (`docs/architecture-review-2026-07.md`, D7) requires one
min/max/value/step/clamp story before ProgressBar, Slider, SpinBox, and ScrollBar.
Shipping those controls with independent APIs would create four incompatible
value models.

## Decision

- Unit `Lux.Range` in the portable core (`src/core`).
- `TLuxRange` holds `Minimum`, `Maximum`, `Value`, and `Step`.
- Invariants: `Minimum <= Maximum`; `Value` always clamped into that closed
  interval; `Step >= 1`.
- `OnChange` fires only when `Value` actually changes (including when a bound
  change forces a reclamp).
- Helpers: `Span` (`Int64`), `Ratio` / `SetRatio`, `Increment` / `Decrement`, plus
  `LuxClampInt` for ad-hoc clamping.
- Arithmetic that can overflow `Integer` (`Span`, ratio mapping, step) uses
  `Int64` intermediates; public `Minimum` / `Maximum` / `Value` / `Step` stay
  `Integer`.
- **Not** included: viewport / page / window size. ScrollBar adds that beside
  Range (value span stays shared).

## Non-goals

ProgressBar / Slider widgets (S3), ScrollBar chrome (S4), floating-point ranges,
theme glyphs for range chrome.

## Consequences

- S3 controls compose or own a `TLuxRange` instead of inventing local min/max.
- ScrollView offsets remain the scroll source of truth; a future ScrollBar
  reflects/commands scroll using Range for the thumb position span only.
