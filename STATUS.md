# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 5.1 — Windows keyboard input verification** — **complete**

Phases 0–5 and 5.1 are complete. Phase 6 (layout and common controls) is next and has not started.

## Phase 5.1 — Windows keyboard verification

Detected during manual `controls_demo_windows`: Space activated the focused button, but Tab / Shift+Tab / Enter did not.

Root cause: `TLuxWindowsTerminalSession.ApplyInputModes` preferred `ENABLE_VIRTUAL_TERMINAL_INPUT` while the event source reads `INPUT_RECORD` via `ReadConsoleInputW`. VT input interfered with logical key delivery (Tab/Enter) while printable characters (including Space) still arrived.

Fix:

- Keep stdin on the Win32 record path: WINDOW_INPUT + MOUSE_INPUT, no VT input, no PROCESSED/LINE/ECHO/QUICK_EDIT.
- Translate `wVirtualKeyCode` before Unicode fallback; never drop logical keys with `UnicodeChar = #0`.
- Emit LUX key events only for key-down (ignore key-up).
- Diagnostic tool: `examples/input_inspector/`.

## Phase 5 — Control foundation

| Unit | Path |
|------|------|
| `Lux.Control` | `src/controls/Lux.Control.pas` |
| `Lux.ControlContainer` | `src/controls/Lux.ControlContainer.pas` |
| `Lux.FocusManager` | `src/controls/Lux.FocusManager.pas` |
| `Lux.Panel` | `src/controls/Lux.Panel.pas` |
| `Lux.Labels` | `src/controls/Lux.Labels.pas` (`TLuxLabel`) |
| `Lux.Button` | `src/controls/Lux.Button.pas` |
| `Lux.ControlApplication` | `src/controls/Lux.ControlApplication.pas` |
| Example | `examples/controls_demo/` |
| Inspector | `examples/input_inspector/` |
| ADR | `docs/adr/0005-control-tree-ownership-focus.md` |

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 — portable + Windows paths |
| Portable isolation | passed (includes `src/controls`) |
| Portable tests | **167 passed** (local Windows + Linux CI) |
| Windows unit tests | **68 passed** (local; live injection skipped when redirected) |
| `controls_demo_windows` | keyboard path corrected; please confirm Tab/Enter/Space manually |
| `input_inspector_windows` | builds for live KEY_EVENT diagnosis |
| CI | **green** on `main` |

## Commands

Windows (local):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
.\bin\controls_demo_windows.exe
.\bin\input_inspector_windows.exe
```

Linux:

```bash
./tools/build.sh all
./tools/test.sh
./tools/test_unix.sh
./bin/controls_demo_unix
```

## Next

Begin Phase 6 — layout and common controls — only after Phase 5.1 remains green on Windows locally and Linux CI.
