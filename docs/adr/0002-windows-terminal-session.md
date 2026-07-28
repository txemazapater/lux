# ADR 0002: Windows terminal session owns console restore

## Status

Accepted (Phase 3A)

## Context

Phase 3A introduces a real Windows console backend. Console mode, code pages and cursor visibility must always be restored, including after exceptions. The portable `TLuxRenderer` must not know about Win32 handles.

## Decision

`TLuxWindowsTerminalSession` is the sole owner of console mutation and restoration:

- `Open` captures original state, enables VT **output** + UTF-8, and exposes `ILuxTerminalWriter`
- Input mode for Phase 4+ uses `ReadConsoleInputW` on `STD_INPUT_HANDLE` with
  `ENABLE_WINDOW_INPUT` + `ENABLE_MOUSE_INPUT`, and **without**
  `ENABLE_VIRTUAL_TERMINAL_INPUT` (VT input is for ReadFile consumers and breaks
  logical KEY_EVENT_RECORD delivery for Tab/Enter)
- `Close` / `Destroy` restore state idempotently
- `TLuxWindowsTerminalWriter` writes through a handle but does not own console mode

Applications should keep the session alive for the whole render lifetime and free it in `finally`.

Input backends are validated with synthetic `KEY_EVENT_RECORD` unit tests and an
interactive `input_inspector_windows` tool on a real console.

## Consequences

- No Win32 code in `Lux.Renderer` / `Lux.Surface`
- Redirected stdout is rejected at `Open` with `ELuxTerminalUnavailable`
- Interactive demos require a real console
- GitHub Actions CI is Linux/portable only; Windows builds are validated locally
