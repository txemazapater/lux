# ADR 0005: Control tree, ownership and focus

## Status

Accepted — Phase 5.

## Context

Phase 5 introduces the first portable control layer. The application loop, surfaces and normalized events already exist. Controls must compose into a tree without platform APIs, without a layout engine, and without LCL `TComponent` coupling.

## Decision

1. **Parent ownership.** A `TLuxControlContainer` owns its direct children as ordinary objects (`TObjectList` with `OwnsObjects`). Destroying a parent destroys its children. Controls are not reference-counted interfaces.
2. **Local coordinates.** `Bounds` are relative to the parent's content origin (`ContentOffset`). `(0,0)` inside a control is its own top-left. Mouse events are hit-tested in root/surface coordinates, then translated to the target's local coordinates before `HandleEvent`.
3. **Paint context, not surface copies.** Rendering uses `TLuxPaintContext` (surface pointer, absolute origin, clip rect). Children are clipped to the parent's client area. No per-control full-surface allocation.
4. **Root + control application.** `TLuxRootControl` owns the tree. `TLuxControlApplication` subclasses `TLuxApplication` and adds root, focus, control routing and control rendering. Widget logic stays out of the base loop.
5. **One focused control.** `TLuxFocusManager` tracks a single focus. Tab / Shift+Tab walk focusable controls in tree order. No `TabIndex` yet.
6. **Full-frame invalidation.** `Invalidate` bubbles to the host and requests a full repaint. Dirty rectangles are deferred.
7. **No mouse capture (Phase 5).** A button click completes only if press and release both occur inside the control. Generic capture arrives in Phase 6B.3 (`docs/adr/0010-split-container-mouse-capture.md`).
8. **No layout engine in Phase 5.** Callers set bounds explicitly. Panel client area excludes a single optional border. Phase 6A adds layout boxes (`docs/adr/0008-layout-model.md`) without changing ownership.
9. **Unit naming.** The label control lives in unit `Lux.Labels` because `Label` is a Free Pascal reserved word; the class remains `TLuxLabel`.

## Consequences

- The same control tree runs on Windows and Unix; only bootstrap programs differ.
- Phase 6 can add layout, capture and richer widgets without rewriting ownership or focus.
- Tests observe `TLuxSurface` cells and injected `TLuxEvent` values without a real terminal.
