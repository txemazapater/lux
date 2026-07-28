# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 4 — Input and application loop** (in progress / locally verified on Windows; Unix via CI)

Phases 0, 1, 2A, 3A and 3B are complete. Phase 4 portable model, both backends, application loop and eventloop example are implemented.

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
| Portable tests | **116 passed** (local Windows) |
| Windows unit tests | **39 passed** (local; includes input translate) |
| Unix platform tests | pending CI (parser + session; UTF-8 assert hardened) |
| `eventloop_windows` | builds locally |
| CI | push after UTF-8 test literal fix |

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

Confirm Phase 4 on Linux CI (parser tests + eventloop PTY smoke). Do not start Phase 5 controls until both platforms are verified.
