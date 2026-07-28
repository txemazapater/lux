# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 5.2 — Resize and repaint stability** — **complete**

Phases 0–5, 5.1 and 5.2 are complete. Phase 6 (layout and common controls) is next and has not started.

## Phase 5.2 — Resize and repaint stability

Manual Windows resize showed severe flicker (UI blanking while dragging the console border).

Root cause: `PaintAll` emitted `ESC[2J` on every full repaint, and the loop often painted once per `WINDOW_BUFFER_SIZE_EVENT` without coalescing.

Fix:

- Full repaint rewrites all cells; it does **not** clear the screen.
- Shrink clears leftover strips with `ESC[0K` / `ESC[0J` only.
- Application drains pending input after wait and coalesces consecutive `ekResize` to the latest size before paint.
- Diagnosis: `docs/phase-5.2-resize-repaint.md`; ADR: `docs/adr/0006-full-repaint-without-clear.md`.

## Phase 5.1 — Windows keyboard verification

Detected during manual `controls_demo_windows`: Space activated the focused button, but Tab / Shift+Tab / Enter did not.

Root cause: `ENABLE_VIRTUAL_TERMINAL_INPUT` on stdin while using `ReadConsoleInputW`. Fix: Win32 record path without VT input; VK-first translation; ignore key-up. Inspector: `examples/input_inspector/`.

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
| Portable tests | **197 passed** (local Windows) |
| Windows unit tests | **68 passed** (local; live injection skipped when redirected) |
| Resize flicker | fixed in renderer + loop; confirm manually with demos |
| CI | push Phase 5.2 then confirm Linux green |

## Commands

Windows (local):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
.\bin\controls_demo_windows.exe
.\bin\eventloop_windows.exe
```

Linux:

```bash
./tools/build.sh all
./tools/test.sh
./tools/test_unix.sh
./bin/controls_demo_unix
```

## Next

Begin Phase 6 — layout and common controls — only after Phase 5.2 remains green on Windows locally and Linux CI, and manual resize looks stable.
