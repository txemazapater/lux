# ADR 0003: Mirrored Windows/Unix terminal session API

## Status

Accepted (Phase 3B)

## Context

Phase 4 will add keyboard/mouse input. Windows (3A) and Unix (3B) backends must expose the same application-facing lifecycle so input wiring does not fork per OS.

## Decision

Both platforms provide:

- `Probe` capability snapshot (console/TTY vs redirected)
- `Open` / `Close` with idempotent restore from `Destroy`
- `Writer: ILuxTerminalWriter`
- Shared `ELuxTerminalUnavailable` from `Lux.Terminal.Errors`
- Platform-specific error types for syscall/API failures

Unix captures `termios` on Open even before raw mode exists, so Phase 4 can mutate input flags and still restore cleanly. Windows already captures console modes the same way.

TTY size (`Columns` / `Rows`) is exposed on the Unix session via `TIOCGWINSZ` to surface host differences early.

## Consequences

- Demos (`windows_demo`, `unix_demo`) share the same render flow
- CI validates Unix session/tests on Linux; Windows remains local
- Input (Phase 4) should attach to the existing session objects, not invent a third lifecycle
