# ADR 0001: Renderer may depend on terminal units

## Status

Accepted (Phase 2A)

## Context

LUX keeps surfaces portable and console-free. ANSI sequence generation and the terminal writer sink are owned by `src/terminal`. The differential renderer lives in `src/rendering` and must emit ANSI through a writer without talking to a real console.

The original dependency sketch listed `rendering -> core` and `terminal -> core` but did not say whether rendering may use terminal helpers.

## Decision

`Lux.Renderer` may depend on:

- `Lux.Terminal.Writer` (output sink interface)
- `Lux.Terminal.Ansi` (pure sequence builders)

Surfaces (`Lux.Surface`) must not depend on terminal units. Terminal units must not depend on the renderer. Platform backends will implement `ILuxTerminalWriter` later; they are out of scope for Phase 2A.

## Consequences

- Strict separation remains: surface model, ANSI string builders, and byte sink are distinct units.
- Portable tests inject `TLuxMemoryTerminalWriter`.
- Architecture dependency rules are updated accordingly.
