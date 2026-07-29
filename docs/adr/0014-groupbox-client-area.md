# ADR 0014: GroupBox client area and container semantics

## Status

Accepted (Phase 6D.3)

## Context

`TLuxPanel` already insets children with `ContentOffset` when bordered. Phase 6D needs a titled group container whose children are laid out in an interior client region without application code compensating for borders.

## Decision

`TLuxGroupBox` is a `TLuxControlContainer` with:

- one-cell border on all sides;
- title painted into the top border between corners;
- `ContentOffset = (1,1)` so child local `(0,0)` maps to the first interior cell;
- public `ClientRect` returning the interior rectangle in local coordinates (empty when bounds are too small);
- non-focusable chrome; descendants remain focusable and participate in Tab order;
- disabled parent state disables descendants through existing `IsEffectivelyEnabled`;
- title influences `PreferredWidth` only (`display cells + 4`); `MinWidth` stays `2` so layouts never force the control wider than the parent and clip the right border;
- title is clipped by display columns into the top edge; corners are painted last.

Children are painted and clipped through the normal container pipeline. Expand>0 children fill `ClientSize`, matching `TLuxPanel`.

## Consequences

Applications parent controls under the group box and use client-local coordinates. No second child collection. Temporary box-drawing glyphs are local constants pending Phase 7 glyph sets.

## Rejected

- Manual child painting
- Collapsing / checkable titles
- Separate `Caption` property naming for this control alone
