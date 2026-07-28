# ADR 0006: Full repaint without clearing the terminal

## Status

Accepted (Phase 5.2)

## Context

Interactive console resize on Windows produced severe flicker. Diagnosis showed that each resize invalidated the renderer and `PaintAll` emitted `ESC[2J` (`LuxAnsiClearScreen`) before rewriting cells. Clearing blanks the visible terminal for a frame; during a drag this repeats many times and reads as the UI disappearing.

A full repaint and a terminal erase are different operations. Invalidation must force every cell to be rewritten; it must not require erasing the screen first.

## Decision

1. **Full repaint** means rewrite every cell of the current surface (cursor home + paint all). It does **not** emit `ESC[2J`.
2. **Grow** only overwrites cells; no erase.
3. **Shrink** clears leftover glyphs outside the new bounds with differential erase sequences (`ESC[0K` / `ESC[0J`), not a full clear.
4. **Invalidate** forces a full rewrite of cells; it does not erase the terminal.
5. `LuxAnsiClearScreen` remains available for session setup / rare host needs, not for routine `PaintAll`.
6. The portable renderer stays free of platform APIs. Resize coalescing lives in `TLuxApplication` (drain pending input + collapse consecutive `ekResize` to the latest size before paint).

## Consequences

- Flicker during resize is dominated by content overwrite, not blank frames.
- Shrink still removes artifacts without a global clear.
- After one full paint for a size change, subsequent frames return to differential mode (`FInvalidated` cleared).
- Optional compile-time `LUX_RESIZE_TRACE` in `Lux.Renderer` can log full vs diff choices; it is not a general logging framework.
