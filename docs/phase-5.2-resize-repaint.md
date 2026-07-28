# Phase 5.2 — Resize and repaint stability

## Diagnosis (before Phase 5.2)

Complete path on Windows:

```text
WINDOW_BUFFER_SIZE_EVENT
        ↓
LuxWinTranslateInputRecord → TLuxEvent (ekResize)
        ↓
ILuxEventSource.WaitEvent / PollEvent
        ↓
TLuxEventQueue
        ↓
TLuxApplication.HandleResize
        ↓
TLuxSurface.Resize + TLuxRenderer.Invalidate + FNeedsPaint
        ↓
RenderContent → TLuxRenderer.Render
        ↓
NeedsFullRepaint (size change or invalidated)
        ↓
PaintAll → HideCursor + ResetAttributes + ClearScreen + CursorHome + all cells
        ↓
ILuxTerminalWriter (ANSI bytes)
```

### Why it flickered

1. **`PaintAll` called `LuxAnsiClearScreen` (`ESC[2J`)**. Full repaint was implemented as erase-then-draw.
2. **One paint per resize when events arrive one-at-a-time.**
3. **No coalescing** of consecutive `ekResize` in the queue.

Root cause of the visual flash: **erase-screen on every full repaint**, amplified by **per-resize paints**.

## Architecture after Phase 5.2 (renderer contract)

Still in force:

- Full repaint rewrites every cell; **no `ESC[2J`**.
- Shrink uses erase-to-EOL / erase-to-EOS for leftover strips.
- After a full paint, the renderer returns to differential mode.
- Queue coalescing of consecutive `ekResize` (level 1).

See `docs/adr/0006-full-repaint-without-clear.md`.

## Phase 5.2.1 — Deferred resize commit (experimental)

**Status: pending manual verification.** Isolated to `TLuxApplication`; can be reverted without undoing 5.2 renderer fixes. See `docs/adr/0007-deferred-resize-commit.md`.

Two distinct sizes:

| Concept | Meaning |
|---------|---------|
| Observed terminal size | Last `ekResize` dimensions from the host; may change every drag sample. |
| Committed application size | Size applied to surface / controls / renderer; updated only after settle. |

While they differ, the last committed composition stays on screen. The console may clip it or show empty margins.

```text
WINDOW_BUFFER_SIZE_EVENT(s)
        ↓
WaitEvent + DrainAvailableInput
        ↓
Queue coalesce (level 1) → latest size in this burst
        ↓
ObserveResize → pending size + deadline (Now + 75 ms)
        ↓
(no Surface.Resize / Invalidate / paint)
        ↓
… further observes replace pending and restart deadline …
        ↓
Deadline reached (loop timeout integrates resize deadline)
        ↓
CommitPendingResize → HandleResize once
        ↓
Surface.Resize + OnResize + Invalidate + one full paint
```

### Policy while resize is pending

- Keyboard, mouse, timers and quit still dispatch.
- **All paints are deferred** until commit (or quit abandons the pending resize).
- Avoids painting a stale surface into a console that is still changing.

### Instrumentation

Define `LUX_RESIZE_TRACE` in `Lux.Application.pas` and/or `Lux.Renderer.pas` (off by default) for observe/commit/render lines on stderr.

### Settle delay

`LuxResizeSettleDelayMs = 75` in `Lux.Application` — internal constant for experiments, not a public setting.

## Manual verification

Must be checked interactively on a real console:

- `bin/controls_demo_windows.exe`
- `bin/eventloop_windows.exe`

**Phase 5.2:** content tracks size without blank flashes; no leftover glyphs after shrink.

**Phase 5.2.1 (compare):** during drag the previous composition stays put; after ~75 ms of stability the UI jumps once to the final size. Escape during drag must still quit. Confirm this feels better than chasing every intermediate size; if not, revert only the deferred-commit layer.
