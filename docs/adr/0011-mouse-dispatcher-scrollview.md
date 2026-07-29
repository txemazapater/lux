# ADR 0011: Centralized Mouse Dispatcher and ScrollView Foundation

## Status

Accepted (Phase 6C)

## Context

Controls previously handled raw platform mouse events independently (press/release/move). This led to duplicated hit-testing logic, inconsistent hover tracking, and tightly coupled interaction code. Double-click recognition was platform-specific (Windows emitted `maDoubleClick`). There was no scrollable container.

## Decision

### Mouse Dispatcher

A centralized `TLuxMouseDispatcher` owned by `TLuxControlApplication` processes all raw mouse events and derives semantic interactions:

- **Hover**: `SemanticMouseEnter` / `SemanticMouseMove` / `SemanticMouseLeave` — tracks one hovered control via physical hit-testing.
- **Press/Release**: `SemanticMouseDown` / `SemanticMouseUp` — tracks pressed control.
- **Click**: `SemanticClick` — emitted only when press and release occur on the same control without drag.
- **Double-click**: `SemanticDoubleClick` — dispatcher-owned recognition using configurable time (500ms) and distance (2 cells) thresholds. Platform `maDoubleClick` is suppressed (Windows emits `maPress` instead).
- **Drag**: `SemanticDragBegin` / `SemanticDragMove` / `SemanticDragEnd` / `SemanticDragCancel` — threshold-based (2 cells displacement from press origin, configurable).
- **Wheel**: `SemanticMouseWheel` — routed to hit target, bubbles up parent chain until consumed.

### Pointer state diagram

```
Idle
├─ move → Hover update
└─ press → Pressed

Pressed
├─ move below threshold → Pressed (click candidate)
├─ move above threshold → Dragging (DragBegin)
├─ release same target → Click → Idle
└─ cancel → Idle

Dragging
├─ move → DragMove
├─ release → DragEnd → Idle
└─ cancel → DragCancel → Idle
```

### Lifecycle safety

`ControlInvalidated` silently clears all dispatcher references to a control being destroyed, without invoking callbacks (since the control's children may already be freed during destruction).

### ScrollView

`TLuxScrollView` is a `TLuxControlContainer` with:

- Single `Content` child positioned at `(-ScrollX, -ScrollY)`.
- Integer scroll offsets, clamped to `[0, max(0, ContentSize - ViewportSize)]`.
- `SemanticMouseWheel` override returns `True` only when scrolling occurred (enabling wheel bubbling for nested ScrollViews).
- `EnsureVisible(AControl)` and `EnsureVisible(ARect)` adjust offsets minimally.
- `VisibleContentRect` expressed in content coordinates.
- Scrollbar visibility properties as foundation (no visual thumb/track).

### Coordinate consistency

Content is clipped to the viewport via `PaintChildren` override. Hit-testing uses the same content position (`-ScrollX, -ScrollY`) ensuring rendering and interaction agree.

## Consequences

- Controls override semantic virtual methods instead of inspecting raw `TLuxEvent.Mouse` in `DoHandleEvent`.
- `TLuxButton` uses `SemanticMouseDown`/`SemanticMouseUp`/`SemanticClick` for mouse interaction.
- `TLuxSplitContainer` uses `SemanticDragBegin`/`Move`/`End`/`Cancel` — drag starts after 2-cell threshold (previously immediate on press).
- Double-click is framework-owned, deterministic, and testable with `TFakeClock`.

## Deferred

- Visual scrollbar thumb/track controls.
- Smooth/kinetic scrolling.
- List/tree/grid virtualization (but `VisibleContentRect` enables future implementations).
- Touch and multi-pointer input.
- Drag-and-drop data transfer between controls.
