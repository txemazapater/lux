# ADR 0009: Logical cursor manager

## Status

Accepted — Phase 6B.2.

## Context

Controls must not drive the hardware terminal cursor during paint (the differential renderer already hides and moves the cursor while writing cells). Interactive carets (text fields, splitters later) need a portable way to request a visible caret without coupling to Win32 `CONSOLE_CURSOR_INFO` or raw ANSI in control code.

## Decision

- `TLuxCursorManager` (`Lux.Cursor`) holds a **requested** caret (cell X/Y, visibility, shape, blink) and the last **committed** state.
- `TLuxCursorCapabilities` describes what the terminal can honour (`CanHideShow`, `CanMove`, `CanSetShape`, `CanBlink`). Unsupported features are skipped at commit time.
- Controls/applications call `Request` / `ClearRequest`. They never emit CSI sequences themselves.
- After each frame paint, `TLuxApplication` calls `MarkPaintDirtied` then `Commit` on the writer, and syncs the renderer’s paint-cursor tracking via `SyncExternalCursor`.
- Shape uses DECSCUSR (`ESC[n q`) when `CanSetShape` is true; otherwise shape/blink requests are ignored.

Default application capabilities are **basic** (hide/show + move). Demos that exercise shape set **full** caps explicitly.

## Consequences

- Limited terminals still work: caret may lack shape/blink but position/visibility remain correct when supported.
- Split-container drag (6B.3) temporarily `Request`s a shape without platform code.
- No change to control hit-testing or focus.
