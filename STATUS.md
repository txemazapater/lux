# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 4 — Input and application loop** (next)

Phases 0, 1, 2A, **3A** and **3B** are complete.

## Phase 3A — Windows terminal backend

Status: **complete** (local verification)

## Phase 3B — Unix terminal backend

Status: **complete** (CI + local sources; interactive TTY via CI pseudo-TTY smoke)

| Unit | Path |
|------|------|
| `Lux.Terminal.Errors` | `src/terminal/Lux.Terminal.Errors.pas` |
| `Lux.Platform.Unix.Console` | `src/platform/unix/Lux.Platform.Unix.Console.pas` |
| `Lux.Platform.Unix.TerminalWriter` | `src/platform/unix/Lux.Platform.Unix.TerminalWriter.pas` |
| `Lux.Platform.Unix.TerminalSession` | `src/platform/unix/Lux.Platform.Unix.TerminalSession.pas` |
| Demo | `examples/unix_demo/unix_demo.pas` |

Covered behaviour: TTY probe, termios capture/restore, `ILuxTerminalWriter` via `write(2)`, redirected-stdout rejection, TTY size via `TIOCGWINSZ`, differential render against a real TTY. Session API mirrors Windows 3A for Phase 4 input alignment. No raw keyboard/mouse yet.

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 — portable + Windows paths |
| Portable isolation | passed |
| Portable tests | **94 passed** (local Windows) |
| Windows unit tests | **16 passed** (local) |
| Unix sources | authored; compiled/tested on GitHub Actions Linux |
| CI | Linux-only: portable + Unix platform tests + `unix_demo` under `script` PTY |

## Commands

Windows (local):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
.\bin\windows_demo.exe
```

Linux:

```bash
./tools/build.sh all
./tools/test.sh
./tools/test_unix.sh
./bin/unix_demo
```

## Next

Phase 4: normalized input (keyboard/mouse/resize) on top of the mirrored Windows/Unix sessions. Do not start controls yet.
