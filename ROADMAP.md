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

Status: **complete** (plus Phase 5.1 Windows keyboard verification and Phase 5.2 resize/repaint stability)

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

### Phase 5.2 — Resize and repaint stability

Status: **complete**

- Full repaint rewrites cells without `ESC[2J`.
- Shrink uses erase-to-end sequences for leftover strips.
- Application coalesces consecutive resize events (single-threaded, no timers).
- See `docs/phase-5.2-resize-repaint.md` and `docs/adr/0006-full-repaint-without-clear.md`.

### Phase 5.2.1 — Deferred resize commit

Status: **experimental / pending manual verification**

- Observe intermediate sizes; commit after `LuxResizeSettleDelayMs` (75) of stability.
- No surface/renderer/paint updates while pending; paints deferred; quit abandons pending.
- Reversible without undoing 5.2 renderer fixes (`docs/adr/0007-deferred-resize-commit.md`).

## Phase 6 - Layout and common controls

Status: **in progress** (6A–6D implemented; expanded `form_demo` awaits visual sign-off; next **6E**)

### Subphase plan

| Subphase | Scope |
|----------|--------|
| **6A** | Layout engine + Vertical/Horizontal (padding, spacing, min/preferred, expand). ADR 0008. **Done.** |
| **6B** | Stack + Splitter via subphases **6B.1–6B.4**. **Done.** |
| **6C** | Mouse semantics + ScrollView foundation. **Done.** |
| **6D** | Form controls: Label, CheckBox, RadioButton, Separator, Toggle, GroupBox (**complete**, visual review pending) |
| **6E** | ProgressBar, Slider |
| **6F** | Toolbar + StatusBar |
| **6G** | Shared menu model + MenuBar + PopupMenu |
| **6H** | TabControl (client area decoupled) |
| **6I** | Grid layout |
| **6J** | Docking preparation (persistable split tree; no floating windows yet) |

Do not implement consumer-application widgets (e.g. TreeView, Editor for a future Lantern) in LUX Phase 6.

### Phase 6A — Layout core

Status: **complete**

- `TLuxLayoutBox`, `TLuxVerticalLayout`, `TLuxHorizontalLayout` under `src/layouts/`
- Layout hints on `TLuxControl` (min / preferred / expand)
- Relayout on container resize; root fills top-level children
- `controls_demo` builds UI without application `SetBounds`
- See `docs/adr/0008-layout-model.md`

### Phase 6B — Stack, cursor, split (incremental)

Status: **complete** (6B.1–6B.4 done)

Process for every 6B subphase: clean compile, automated tests where useful, a dedicated visual demo, then manual review on real terminals. Prefer small commits. No docking and no consumer-application (Lantern) widgets in 6B.

| Subphase | Scope | Status |
|----------|--------|--------|
| **6B.1** | `TLuxStackLayout`: shared client area; z-order / BringToFront; overlay demo. | **done** |
| **6B.2** | Portable logical cursor manager (request/commit, capabilities). | **done** |
| **6B.3** | Split container with internal divider, generic mouse capture, drag, cursor integration, tests + interactive demo. | **done** |
| **6B.4** | Interaction hardening and closure (escape cancel, capture loss, resize/orientation safety). | **done** |

Do not implement docking or consumer-application widgets in 6B.

### Phase 6C — Mouse Semantics & ScrollView Foundation

Status: **complete** (visual review passed)

- Centralized `TLuxMouseDispatcher` owned by `TLuxControlApplication`.
- Semantic mouse callbacks on `TLuxControl` (enter/leave/move/down/up/click/double-click/drag/wheel).
- Dispatcher-owned double-click recognition (configurable thresholds; platform `maDoubleClick` suppressed).
- Threshold-based drag initiation (2-cell default, configurable).
- Wheel event bubbling via parent chain.
- `TLuxButton` and `TLuxSplitContainer` migrated to semantic callbacks.
- `TLuxScrollView`: viewport, content child, scroll offsets, clamping, wheel consumption, `EnsureVisible`, `VisibleContentRect`.
- Tests: 468 assertions covering semantic dispatch, ScrollView correctness, and threshold-based split drag.
- `scroll_demo` interactive example with semantic event log, nested ScrollViews, H/V overflow, drag pad, EnsureVisible, and geometry diagnostics (`examples/debug/Lux.Debug.EventLog.pas` is demo-only).
- See `docs/adr/0011-mouse-dispatcher-scrollview.md`.

Deferred: visual scrollbar controls, kinetic scrolling, virtualization, drag-and-drop data transfer.

### Phase 6D — Label, CheckBox, RadioButton, Separator, Toggle, GroupBox

Status: **implemented** (visual review pending for expanded `form_demo`)

Subphases:

| Subphase | Status |
|----------|--------|
| Label / CheckBox / RadioButton | **done** (visual review passed) |
| **6D.1** Separator | **done** |
| **6D.2** Toggle | **done** |
| **6D.3** GroupBox | **done** |

- `TLuxLabel` preferred width/height derived from Unicode text.
- `TLuxCheckBox`: Space + semantic click toggle; disabled inert.
- `TLuxRadioButton`: Space + semantic click select; sibling-only mutual exclusion.
- `TLuxSeparator`: non-focusable H/V line; layout Expand on main axis.
- `TLuxToggle`: `[ OFF ]` / `[  ON ]` indicator; Space + semantic click; CheckBox-aligned API.
- `TLuxGroupBox`: titled border; client area via `ContentOffset` / `ClientRect` (ADR 0014).
- Focus indication unambiguous; invalidation only on actual state change.
- Portable tests cover preferred size, Unicode, click/Space, siblings, disabled/focus, separator, toggle, group box.
- `form_demo` exercises all Phase 6D controls + disabled group + event log.
- Docs: `docs/phase-6d-form-controls.md`, ADR 0012, ADR 0014.

Temporary box/toggle glyphs are isolated constants for Phase 7 migration. No Appearance System in 6D.

## Phase 7 — Appearance System

Status: **planned** (not started)

Goal: create a portable, semantic and application-independent appearance system for LUX.

Controls must express visual intent through semantic roles and control states instead of embedding concrete colors, glyphs or platform-specific appearance decisions.

The appearance system must support:

- semantic color roles;
- reusable glyph sets;
- shared visual metrics;
- application-level active themes;
- external theme files (`.luxtheme`, UTF-8 INI — not CSS);
- built-in fallback themes (`LuxDark`, `LuxLight`, `LuxMonochrome`);
- runtime theme changes;
- portable configuration lookup (Windows APPDATA, Unix XDG, portable mode — no Registry);
- graceful degradation according to terminal color capabilities.

Principles (formalized in `docs/adr/0013-appearance-themes-glyphs-config.md`):

- Semantic roles (`Background`, `Surface`, `Text`, `Accent`, `Focus`, …) instead of hardcoded colors.
- Control visual state (`Normal`, `Hovered`, `Focused`, `Pressed`, `Selected`, `Disabled`) is separate from color lookup — no CSS selector engine.
- Glyphs (checkbox/radio marks, arrows, borders, …) live in theme glyph sets (Unicode and ASCII-compatible).
- Metrics (padding cells, indicator spacing, focus-marker width) are appearance resources; layout remains owned by `src/layouts/`.
- LUX does not select or install terminal fonts.

### Subphases

| Subphase | Scope |
|----------|--------|
| **7A** | Appearance model: roles, states, glyph sets, metrics, theme object, built-in default — in-memory only. |
| **7B** | Theme integration: application / paint context, control migration, runtime switch between built-ins. |
| **7C** | External `.luxtheme` loader: UTF-8 INI, validation, single base inheritance, strict/fallback modes. |
| **7D** | Portable configuration discovery: APPDATA, XDG, portable mode, search precedence. |
| **7E** | Acceptance theme demo + CI wiring + closure. |

Suggested source tree (when implementation begins): `src/appearance/`.

**Sequencing (under review):** ADR 0013 still describes the Appearance System. The 2026-07 architecture review recommends a **thin in-memory appearance seam (roles/glyphs) before more glyph-heavy controls**, while deferring `.luxtheme` path discovery. See `docs/architecture-review-2026-07.md`. Do not assume “all of Phase 6 then Phase 7” without that review.

## Phase 8 — Developer usability

- Package distribution strategy.
- API reference generation.
- More examples.
- Diagnostics and debug overlay.
- Performance benchmarks.
- Compatibility matrix.

## Phase 9 — Consumer readiness (Lantern)

Goal: provide framework primitives that a substantial consumer application (provisionally **Lantern**) would need. Lantern is not part of LUX; **Lighthouse** is only the provisional commercial name of LUX itself.

- Tree view.
- Text viewport.
- Command palette.
- Status bar.
- Menu system.
- Split panes.
- Background task/event integration.

Git support, repository models and editor semantics belong to the consumer application (Lantern), not the LUX core.

## Current priority

**S1 complete.** Next: **S2 — Range model**, then ProgressBar/Slider on Range.

- Record: [`docs/architecture-review-2026-07.md`](docs/architecture-review-2026-07.md)
- S1 ADR: [`docs/adr/0015-client-area-appearance-seam.md`](docs/adr/0015-client-area-appearance-seam.md)
- Phases **0–6D** + **S1** are the implemented baseline.
- **Do not start old 6E (ProgressBar/Slider)** without a Range model.

Phase 5.2.1 deferred resize remains experimental. Do not pull consumer-application (Lantern) widgets into the LUX core.
