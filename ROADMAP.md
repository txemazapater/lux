# LUX Roadmap

## Phase 0 - Foundation

Status: **complete**

Goal: make the repository buildable and predictable.

- Define source tree.
- Add Free Pascal project files.
- Add a minimal test runner.
- Add Windows and Linux CI.
- Establish compiler switches and warning policy.
- Add a `hello_lux` placeholder example.

Exit criteria:

- Clean checkout builds on Windows and Linux.
- Tests execute from one documented command.

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

Status: **pending**

- Unix backend.
- Terminal size detection (shared / per platform as needed).
- Raw input mode.
- Alternate screen support.
- Cursor visibility control beyond the Windows 3A baseline.
- Reliable cleanup after handled exceptions on Unix.

Exit criteria for full Phase 3:

- Examples enter and leave terminal mode cleanly on Windows and Linux.

## Phase 4 - Input and application loop

Goal: normalize user input and host an interactive application.

- Keyboard events.
- Modifier keys.
- Mouse events.
- Resize events.
- Timer events.
- Command events.
- `TLuxApplication` main loop.
- Invalidation and repaint scheduling.

Exit criteria:

- `hello_lux` reacts to resize and exits using Escape or `q`.

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

Cursor and other coding agents must work on Phase 3B (Unix terminal backend). Do not begin controls yet. Do not write directly to stdout from the renderer. Keep Win32 confined to `src/platform/windows`.
