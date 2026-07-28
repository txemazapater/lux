# Phase 5.2 — Resize and repaint stability

## Diagnosis (before change)

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

1. **`PaintAll` called `LuxAnsiClearScreen` (`ESC[2J`)**. Full repaint was implemented as erase-then-draw. Each clear blanks the console before cells are rewritten.
2. **One paint per resize when events arrive one-at-a-time.** `WaitEvent` returned a single `WINDOW_BUFFER_SIZE_EVENT`; the loop painted; the next wait got the next size. A continuous drag therefore produced many intermediate full clears (often on the order of “N resizes → N full paints”), not a single final frame.
3. **No coalescing** of consecutive `ekResize` in the queue, and pending input was not drained after `WaitEvent`, so multiple buffer-size records already available were not collapsed before paint.

Root cause of the visual flash: **erase-screen on every full repaint**, amplified by **per-resize paints**. Not a slow differential path.

## Architecture after Phase 5.2

```text
WINDOW_BUFFER_SIZE_EVENT(s)
        ↓
WaitEvent + DrainAvailableInput (PollEvent)
        ↓
Queue (possibly many ekResize)
        ↓
DispatchQueuedEvents — coalesce consecutive ekResize → latest only
        ↓
HandleResize (once per coalesced batch)
        ↓
Surface.Resize + Renderer.Invalidate + NeedsPaint
        ↓
One RenderContent + Render per loop iteration
        ↓
PaintAll: hide cursor if needed, home, rewrite all cells
        ↓
If shrunk: erase leftover columns/rows (0K / 0J)
        ↓
CapturePrevious; FInvalidated := False → next frames differential
```

### Contracts

| Concept | Meaning |
|---------|---------|
| Invalidate | Next render rewrites every cell. Does not erase the terminal. |
| Full repaint | All cells written. No `ESC[2J` by default. |
| Erase terminal | Explicit clear; not part of routine full repaint. |
| Grow | Overwrite only. |
| Shrink | Overwrite + erase-to-EOL / erase-to-EOS for discarded strips. |

### Instrumentation

Define `LUX_RESIZE_TRACE` at the top of `Lux.Renderer.pas` to log full vs diff and size to stderr. Off by default.

## Manual verification

Must be checked interactively on a real console (agent cannot drag the window):

- `bin/controls_demo_windows.exe` — fast and slow border drags.
- `bin/eventloop_windows.exe` — same.

Expect: content tracks size without blank flashes; no leftover glyphs after shrink; after drag ends, small updates stay differential.
