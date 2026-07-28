# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 5 — Control foundation** — **complete**

Phases 0–5 are complete. Next is Phase 6 (layout and common controls).

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
| ADR | `docs/adr/0005-control-tree-ownership-focus.md` |

Covered behaviour: parent-owned control tree; local coordinates and clipping via paint context; hit testing; focus + Tab/Shift+Tab; panel/label/button; keyboard and mouse activation; portable tests against `TLuxSurface`.

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 — portable + Windows paths |
| Portable isolation | passed (includes `src/controls`) |
| Portable tests | **150 passed** (local Windows + Linux CI) |
| Windows unit tests | **39 passed** (local) |
| `controls_demo_windows` | builds locally |
| `controls_demo_unix` | builds + PTY smoke on Linux CI |
| CI | **green** on `main` |

## Commands

Windows (local):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
.\bin\controls_demo_windows.exe
```

Linux:

```bash
./tools/build.sh all
./tools/test.sh
./tools/test_unix.sh
./bin/controls_demo_unix
```

## Next

Begin Phase 6 — layout and common controls (dock/stack/split, text input, list box, scroll bars, dialogs, theme primitives).
