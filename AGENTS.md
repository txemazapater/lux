# AGENTS.md

## Mission

Build LUX as a modern, native and testable TUI framework for Free Pascal.

The immediate objective is not to create a full widget library. The immediate objective is to establish a correct portable core, a virtual cell surface, an ANSI renderer and a minimal event loop that work on Windows and Linux.

## Read first

Before changing code, read:

1. `README.md`
2. `SPECIFICATION.md`
3. `ROADMAP.md`
4. `docs/ARCHITECTURE.md`
5. Relevant ADR files under `docs/adr/`

## Working rules

- Work in small, compilable increments.
- Do not add Git, editor or AI features to the LUX core.
- Keep platform-specific code isolated.
- Do not emit ANSI sequences outside terminal backend units.
- Keep the portable rendering core testable without a real console.
- Prefer explicit code over premature abstractions.
- Avoid dependencies unless they solve a demonstrated problem.
- Preserve terminal state on every controlled exit path.
- Use UTF-8 source files and `UnicodeString` at public text boundaries.
- Add or update tests with each portable behavior change.

## Language conventions

Use:

```pascal
{$mode objfpc}{$H+}
```

Naming:

- Types: `TLux...`
- Interfaces: `ILux...`
- Exceptions: `ELux...`
- Units: `Lux.*`
- Private fields: `FName`
- Methods and properties: PascalCase

## Architectural boundaries

### Portable core

May contain:

- Geometry
- Colours
- Cells
- Surfaces
- Clipping
- Frame comparison
- Normalized events

Must not call OS console APIs.

### Platform backends

May contain:

- Windows Console API
- Unix terminal mode and signals
- Raw input acquisition
- Terminal dimension queries

Must expose normalized behavior to the rest of LUX.

### ANSI backend

Owns:

- Escape sequence generation
- Cursor movement
- Colour and style changes
- Alternate screen handling
- Mouse protocol activation

### Controls

Must draw only through LUX surfaces and consume normalized events.

## First implementation sequence

Follow this order unless an existing implementation makes another order safer:

1. Repository build skeleton.
2. `TLuxPoint`, `TLuxSize`, `TLuxRect`.
3. `TLuxColor` and text styles.
4. `TLuxCell`.
5. `TLuxSurface` with bounds, clear, fill and text drawing.
6. Tests for the portable surface.
7. Terminal writer interface.
8. ANSI writer implementation.
9. Frame diff renderer.
10. Minimal application loop.
11. Windows backend.
12. Unix backend.
13. First `hello_lux` example.

## Definition of done for every task

A task is done only when:

- The code compiles with the supported Free Pascal version.
- Portable behavior has tests where practical.
- No unrelated feature is added.
- Public APIs are documented briefly.
- Existing documentation remains accurate.
- Terminal cleanup behavior is preserved.

## Current instruction to coding agents

Phase 0 and Phase 1 are complete. Continue with Phase 2 from `ROADMAP.md`: terminal writer interfaces, ANSI sequence generation, frame diff rendering and a memory-backed writer for tests. Do not begin controls yet.
