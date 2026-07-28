# ADR 0008: Layout model (Phase 6A)

## Status

Accepted — Phase 6A.

## Context

Phase 5 controls use explicit `Bounds` in local coordinates. Phase 6 must compute those bounds from layout rules without a second ownership tree, without platform code, and without mixing layout into paint or event routing.

## Decision

### One tree

Layout does **not** introduce a parallel tree. Children remain ordinary `TLuxControl` instances owned by `TLuxControlContainer`. Layout containers are containers that **write** child `Bounds` via `SetBounds`.

### Layout hints on the control

Every `TLuxControl` carries hints used by parent layout boxes:

| Hint | Meaning |
|------|---------|
| `MinWidth` / `MinHeight` | Floor for assigned size (>= 0). |
| `PreferredWidth` / `PreferredHeight` | Ideal size along each axis (>= 0). Resolved preferred = `Max(Preferred, Min)`. |
| `Expand` | Non-negative weight on the **main axis** of the parent layout. `0` = fixed at resolved preferred; `>0` = share leftover main-axis space proportionally. |

**Fixed size** = `Expand = 0` with preferred (and optional min) set. There is no separate “fixed” flag.

Cross-axis behaviour in 6A: children stretch to the full inner cross-axis size of the layout (width in a vertical box, height in a horizontal box), clamped to `Min*`.

### Layout containers

`TLuxLayoutBox` (`src/layouts/`) subclasses `TLuxControlContainer` and owns:

- `Padding` (left/top/right/bottom)
- `Spacing` between consecutive **visible** children
- `PerformLayout` (implemented by `TLuxVerticalLayout` / `TLuxHorizontalLayout`)

Inner area (child coordinates, where `(0,0)` is already after `ContentOffset`):

```text
Left   = Padding.Left
Top    = Padding.Top
Width  = ClientSize.Width  - Padding.Left - Padding.Right
Height = ClientSize.Height - Padding.Top  - Padding.Bottom
```

`ClientSize` is `Width/Height` minus a symmetric `ContentOffset` inset (so bordered panels keep a correct client region).

### Who triggers relayout

1. Layout box `BoundsChanged` → mark dirty → `PerformLayout`.
2. Child added/removed on a layout box → request layout.
3. Child visibility or layout-hint changes → `HandleChildLayoutHintsChanged` on parent → request layout.
4. Nested layout boxes relayout when their own bounds change (parent layout assigned them).

`FInLayout` prevents re-entrant layout on the same box while assigning child bounds.

### Root fill (no app coordinates)

`TLuxRootControl` assigns each visible child the full client rectangle when the root resizes. Application code hosts a single top-level layout under `Root` and never calls `SetBounds` for composition.

### Non-goals (6A)

Align/anchors enums, Grid, Splitter, ScrollView, measure/ intrinsic text APIs beyond preferred hints, mouse capture.

## Consequences

- Paint, hit-testing and focus keep using `Bounds` / `ContentOffset` / `TLuxPaintContext` unchanged.
- Existing demos that set bounds manually still work; layout boxes are additive.
- Later subphases (Stack, Splitter, Grid) extend `TLuxLayoutBox` or add sibling containers without changing ownership.
