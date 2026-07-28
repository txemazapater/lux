# LUX Architecture

## System shape

LUX is divided into strict layers. Higher layers may depend on lower layers. Lower layers must not know about higher layers.

```text
Applications
  -> Controls and layouts
  -> Application loop and events
  -> Virtual surfaces and composition
  -> Terminal renderer
  -> Platform backend
```

## Dependency rules

- `core` depends only on the Free Pascal RTL.
- `rendering` depends on `core`.
- `events` depends on `core`.
- `terminal` depends on `core` and exposes terminal-oriented interfaces.
- `platform` implements OS-specific services behind interfaces.
- `controls` depends on `core`, `rendering` and `events`.
- Applications depend on public LUX units only.

Circular dependencies are forbidden.

## Portable core

The portable core contains geometry, colours, text styles, cells, surfaces and frame comparison. It must compile and run in tests without opening a terminal.

## Virtual surface

Controls render into `TLuxSurface`. A surface is a rectangular matrix of `TLuxCell` values. Drawing operations must clip safely. Out-of-bounds writes must never corrupt memory.

The surface API is responsible for:

- dimensions;
- indexed access;
- clear and fill;
- clipped rectangle operations;
- text drawing;
- resize behavior;
- deterministic equality and comparison.

## Rendering pipeline

The application produces a new frame in memory. The renderer compares it with the previous frame, groups changed cells into runs and asks a terminal writer to emit the smallest practical output.

The renderer must track terminal state such as cursor position, foreground colour, background colour and text style to avoid redundant sequences.

## Platform boundary

Operating-system code is isolated behind backend interfaces. The rest of LUX must not call Windows Console APIs, Unix termios functions or signal APIs directly.

A backend owns terminal setup and restoration. Restoration must be idempotent.

## Event model

Platform input is converted into normalized LUX events before reaching controls. Controls must not parse raw ANSI input sequences or native key records.

Initial event classes:

- key;
- mouse;
- resize;
- timer;
- focus;
- command;
- shutdown.

## Ownership and lifetime

Prefer explicit ownership. Objects that own child objects must free them. Interfaces are reserved for stable boundaries and replaceable services, not used indiscriminately.

## Extensibility

LUX should be extensible through composition and subclassing, but no plugin system is required initially. New terminal protocols and controls must be addable without modifying portable core types unnecessarily.
