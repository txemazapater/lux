# ADR 0010: Split container and mouse capture

## Status

Accepted — Phases 6B.3–6B.4.

## Context

Phase 6B needs resizable two-pane layouts. A standalone `TLuxSplitter` child would complicate hit-testing, ownership and painting. Dragging a divider also requires mouse events after the pointer leaves the divider, which Phase 5 explicitly deferred (`docs/adr/0005-control-tree-ownership-focus.md`).

## Decision

1. **`TLuxSplitContainer`** (`Lux.Layout.Split`) is a specialized `TLuxControlContainer`. It owns at most two pane children (`FirstPane` / `SecondPane`). The divider is **internal** geometry: layout, paint, hit-test chrome, hover and drag live on the container. There is no `TLuxSplitter` control.
2. **Ratio model.** Requested proportion is an integer `0..10000`. Layout converts ratio → first-pane main-axis size with integer arithmetic, then clamps using `DividerSize`, `FirstMinimumSize` and `SecondMinimumSize`. Stored ratio is the request; geometry may differ when minimums bind.
3. **Hit-test chrome.** `TLuxControlContainer.HitTestInternalRoot` lets a container claim root-space points before children. The split container returns True for the divider rectangle so panes never see divider presses.
4. **Generic mouse capture** on `TLuxControlApplication`: `CaptureMouse` / `ReleaseMouse` / `CapturedControl`. While valid, capture overrides `HitTestRoot`; coordinates are still translated to the captured control’s local space. Capture clears on LMB release, explicit release, destroy (`OnWillFree`), hide, disable, removal from the tree, or application shutdown. Additionally, when capture is revoked from a still-valid control, the application calls `TLuxControl.MouseCaptureLost` so interactive state/cursor requests can be cleared safely. Wrong-control `ReleaseMouse` is ignored.
5. **Cursor.** Hover/drag request a logical caret via `TLuxCursorManager` (Phase 6B.2). Interaction does not depend on shape support.
6. **Keyboard resize / focus polish** are deferred beyond Phase 6B.4. Phase 6B.4 adds split-only drag cancellation (Escape), cursor/lifecycle cleanup, and deterministic orientation-change behaviour during drag.

## Consequences

- Nested splits compose as ordinary control trees.
- Controls and layouts remain free of platform units.
- Button click-without-capture behaviour is unchanged unless a control explicitly captures.
