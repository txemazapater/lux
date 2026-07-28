# ADR 0002: Windows terminal session owns console restore

## Status

Accepted (Phase 3A)

## Context

Phase 3A introduces a real Windows console backend. Console mode, code pages and cursor visibility must always be restored, including after exceptions. The portable `TLuxRenderer` must not know about Win32 handles.

## Decision

`TLuxWindowsTerminalSession` is the sole owner of console mutation and restoration:

- `Open` captures original state, enables VT + UTF-8, and exposes `ILuxTerminalWriter`
- `Close` / `Destroy` restore state idempotently
- `TLuxWindowsTerminalWriter` writes through a handle but does not own console mode

Applications should keep the session alive for the whole render lifetime and free it in `finally`.

## Consequences

- No Win32 code in `Lux.Renderer` / `Lux.Surface`
- Redirected stdout is rejected at `Open` with `ELuxTerminalUnavailable`
- Interactive demos require a real console; CI compiles the demo but does not require an interactive run
