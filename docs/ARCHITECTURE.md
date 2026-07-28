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
- `rendering` may also use `terminal` writer interfaces and ANSI helpers (see `docs/adr/0001-renderer-depends-on-terminal.md`).
- `events` depends on `core` (and uses `SysUtils` for queues/timers).
- `app` depends on `events`, `rendering` and `terminal`.
- `terminal` depends on `core` and exposes terminal-oriented interfaces.
- `platform` implements OS-specific services behind interfaces.
- `controls` depends on `core`, `rendering`, `events` and `app` (`TLuxControlApplication`).
- Applications depend on public LUX units only.

Circular dependencies are forbidden. Surfaces must not depend on terminal or platform units.

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

Platform input is converted into normalized LUX events (`Lux.Events`) before reaching the application or future controls. Controls must not parse raw ANSI input sequences or native key records.

`ILuxEventSource` supplies events via non-blocking `PollEvent` and blocking `WaitEvent`. `TLuxApplication` merges terminal input with `TLuxTimerScheduler` firings through `TLuxEventQueue`. See `docs/adr/0004-event-source-queue-application.md`.

Event kinds in Phase 4:

- key (logical `TLuxKey` separate from Unicode `Ch`);
- mouse (cell coordinates, button, action, wheel);
- resize;
- timer;
- quit;
- unknown / none.

Focus, command routing and widget trees belong to Phase 5+.

## Controls

Portable controls live under `src/controls` and must not reference platform units. They draw only through `TLuxSurface` (via `TLuxPaintContext`) and consume only `TLuxEvent`.

- Parents own children; cycles and duplicate inserts are rejected.
- Coordinates are local; mouse hit-testing uses root coordinates then translates to local.
- `TLuxFocusManager` holds one focused control; Tab / Shift+Tab walk tree order.
- `TLuxControlApplication` hosts `TLuxRootControl`, routes input and renders the tree.
- Phase 5 widgets: panel (optional single border), label, button.
- Invalidation is full-frame. Mouse capture and layout managers are out of scope (see `docs/adr/0005-control-tree-ownership-focus.md`).
- Platform input backends are validated with synthetic translation tests and a small interactive inspector on the real host (`examples/input_inspector/`). Windows stdin uses Win32 `INPUT_RECORD` mode without `ENABLE_VIRTUAL_TERMINAL_INPUT` (see `docs/adr/0002-windows-terminal-session.md`).

## Application loop

`TLuxApplication` runs on a single thread: wait → drain timers into the queue → dispatch events one by one → `Update` → render only if invalidated or resized. Session open/restore remains outside `Run` (`try`/`finally` in the example).

`TLuxControlApplication` extends the loop with control routing and root rendering without platform conditionals.

## Ownership and lifetime

Prefer explicit ownership. Objects that own child objects must free them. Interfaces are reserved for stable boundaries and replaceable services, not used indiscriminately.

## Extensibility

LUX should be extensible through composition and subclassing, but no plugin system is required initially. New terminal protocols and controls must be addable without modifying portable core types unnecessarily.
