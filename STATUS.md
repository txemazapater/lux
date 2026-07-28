# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 4 — Input and application loop** — **complete**

Phases 0–4 are complete. Next is Phase 5 (control foundation).

## Phase 4 — Input and application loop

| Unit | Path |
|------|------|
| `Lux.Events` | `src/events/Lux.Events.pas` |
| `Lux.EventSource` | `src/events/Lux.EventSource.pas` |
| `Lux.EventQueue` | `src/events/Lux.EventQueue.pas` |
| `Lux.Timers` | `src/events/Lux.Timers.pas` |
| `Lux.Application` | `src/app/Lux.Application.pas` |
| Unix parser / source | `src/platform/unix/Lux.Platform.Unix.InputParser.pas`, `...EventSource.pas` |
| Windows translate / source | `src/platform/windows/Lux.Platform.Windows.InputTranslate.pas`, `...EventSource.pas` |
| Example | `examples/eventloop/` |
| ADR | `docs/adr/0004-event-source-queue-application.md` |

Covered behaviour: portable event model; `ILuxEventSource`; FIFO queue; injectable timers; Unix raw/SGR mouse/SIGWINCH + incremental parser; Windows console input translation; `TLuxApplication` invalidate/repaint loop; eventloop demo (Esc/q to quit).

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 — portable + Windows paths |
| Portable isolation | passed (`src/core`, `terminal`, `rendering`, `events`, `app`) |
| Portable tests | **116 passed** (local Windows + Linux CI) |
| Windows unit tests | **39 passed** (local; includes input translate) |
| Unix platform tests | **passed** (Linux CI; parser + session) |
| `eventloop_windows` | builds locally |
| `eventloop_unix` | builds + PTY smoke on Linux CI |
| CI | **green** on `main` |

## Commands

Windows (local):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
.\bin\eventloop_windows.exe
```

Linux:

```bash
./tools/build.sh all
./tools/test.sh
./tools/test_unix.sh
./tools/build.sh eventloop
# interactive:
./bin/eventloop_unix
# CI-style smoke under PTY (sends Esc after a short delay in workflow)
```

## Next

Begin Phase 5 — control foundation (base control, ownership, focus, panel/label/button).
