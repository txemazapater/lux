# ADR 0007: Deferred resize commit (experimental)

## Status

**Experimental / pending manual verification** (Phase 5.2.1)

Do not treat this as final until interactive Windows resize is confirmed better than Phase 5.2 alone. The change is isolated to `TLuxApplication` so it can be reverted without undoing ADR 0006 (full repaint without clear).

## Context

Phase 5.2 removed `ESC[2J` from full repaint and coalesced queued resize events. During a continuous drag the loop could still commit and repaint intermediate sizes (for example 100→101→102→…), which feels like the UI chasing the border.

Classic Windows-style resize often keeps the previous client content until the drag settles, then applies the final size once.

## Decision

LUX treats interactive resize as a **deferred** operation:

1. **Observed terminal size** — each `ekResize` updates a pending candidate and a settle deadline (`Now + LuxResizeSettleDelayMs`, initially 75). No `Surface.Resize`, no renderer invalidate, no paint.
2. **Committed application size** — when the deadline elapses without a newer observation, apply the last pending size via the existing `HandleResize` path (surface, `OnResize`, invalidate, one paint).
3. Queue coalescing (level 1) remains; deferred settle (level 2) sits on top.
4. While pending: process keyboard, mouse, timers and quit; **defer all paints**. Quit abandons pending resize without waiting.
5. Identical observations do not restart the deadline; size equal to the committed size clears pending without commit work.

## Consequences

- A drag with many `WINDOW_BUFFER_SIZE_EVENT`s normally yields one commit and one full repaint.
- During the drag the last committed composition stays visible (console may clip or show empty margins).
- ~75 ms latency after the last size change before layout updates; tune `LuxResizeSettleDelayMs` for experiments (not a public setting yet).
- Manual Windows verification required before accepting or reverting this ADR.
