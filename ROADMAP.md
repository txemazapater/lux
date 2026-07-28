# LUX Roadmap

## Phase 0 - Foundation

Status: **complete**

Goal: make the repository buildable and predictable.

- Define source tree.
- Add Free Pascal project files.
- Add a minimal test runner.
- Add Linux CI (portable path on GitHub Actions).
- Establish compiler switches and warning policy.
- Add a `hello_lux` placeholder example.

Exit criteria:

- Clean checkout builds on Linux CI.
- Tests execute from one documented command.
- Windows builds remain a local developer workflow where applicable.

## Phase 1 - Portable rendering core

Status: **complete**

Goal: create a terminal-independent visual model.

- Implement `TLuxPoint`, `TLuxSize` and `TLuxRect`.
- Implement RGB colours and default/inherit colour semantics.
- Implement text styles.
- Implement `TLuxCell`.
- Implement `TLuxSurface`.
- Add clipping, clearing, rectangle filling and text drawing.
- Define wide-character and continuation-cell behavior.
- Add comprehensive unit tests.

Exit criteria:

- The complete phase runs in memory without accessing a console.
- Surface operations have deterministic tests.

## Phase 2 - Terminal output

Status: **complete** (Phase 2A portable renderer)

Goal: render virtual surfaces efficiently to ANSI/VT terminals.

- Define terminal writer interfaces.
- Implement ANSI sequence generation.
- Implement cursor, colour and style state tracking.
- Implement current/previous frame comparison.
- Emit only changed runs.
- Add a memory-backed writer for tests.

Exit criteria:

- A surface can be converted into deterministic ANSI output.
- Unchanged frames produce no visual output.

Real Windows/Unix console backends remain Phase 3.

## Phase 3 - Platform abstraction

Goal: own and safely restore the host terminal.

### Phase 3A — Windows backend

Status: **complete**

- Windows console probe and capability snapshot.
- `TLuxWindowsTerminalWriter` implementing `ILuxTerminalWriter`.
- `TLuxWindowsTerminalSession` with VT + UTF-8 setup and idempotent restore.
- `examples/windows_demo` against a real console.
- Windows unit tests separated from portable tests; interactive tests optional.

### Phase 3B — Unix backend

Status: **complete**

- Unix TTY probe and capability snapshot (including winsize).
- `TLuxUnixTerminalWriter` implementing `ILuxTerminalWriter`.
- `TLuxUnixTerminalSession` with termios capture and idempotent restore.
- Shared `ELuxTerminalUnavailable` in `Lux.Terminal.Errors`.
- `examples/unix_demo` against a real TTY.
- Unix unit tests on Linux CI; interactive tests optional.
- Session API mirrored with Windows 3A (see `docs/adr/0003-mirrored-session-api.md`).

Raw input mode and mouse/keyboard decoding belong to Phase 4.

Exit criteria for full Phase 3:

- Examples enter and leave terminal mode cleanly on Windows (local) and Linux (CI/local).

## Phase 4 - Input and application loop

Status: **complete**

Goal: normalize user input and host an interactive application.

- Portable `Lux.Events` model (key vs Unicode char, mouse, resize, timer, quit).
- `ILuxEventSource` (`PollEvent` / `WaitEvent`) plus platform Unix/Windows sources.
- Unix: raw termios, incremental ANSI/UTF-8 parser, SGR mouse, SIGWINCH flag.
- Windows: console input record translation to the same `TLuxEvent`.
- `TLuxEventQueue`, portable timers with injectable clock.
- `TLuxApplication` main loop with invalidation-based repaint (no widgets).
- `examples/eventloop` shared demo; platform factory programs only differ.

Exit criteria:

- Same event model and application loop semantics verified on Windows and Unix.
- Eventloop example shows last input, mouse, size and timer; exits with Escape/`q`; restores the terminal.

## Phase 5 - Control foundation

Goal: create a small composable control hierarchy.

- Base control.
- Parent/child ownership.
- Position, size and clipping.
- Visibility and enabled state.
- Focus and tab order.
- Invalidation propagation.
- Panel, label and button.

Exit criteria:

- A small interactive dialog can be built without direct surface access from application code.

## Phase 6 - Layout and common controls

- Dock layout.
- Stack layout.
- Split layout.
- Borders and frames.
- Text input.
- List box.
- Scroll bars.
- Dialogs.
- Theme primitives.

## Phase 7 - Developer usability

- Package distribution strategy.
- API reference generation.
- More examples.
- Diagnostics and debug overlay.
- Performance benchmarks.
- Compatibility matrix.

## Phase 8 - Lantern readiness

Goal: provide the primitives required by the first substantial consumer.

- Tree view.
- Text viewport.
- Command palette.
- Status bar.
- Menu system.
- Split panes.
- Background task/event integration.

Git support, repository models and editor semantics belong to Lantern, not the LUX core.

## Current priority

Phase 4 is closed on Windows (local) and Unix (Linux CI, including eventloop PTY smoke). Begin Phase 5 — control foundation.
