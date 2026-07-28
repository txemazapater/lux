# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 3B — Unix terminal backend** (next)

Phases 0, 1, 2A and **3A** are complete.

## Phase 3A — Windows terminal backend

Status: **complete** (local verification)

| Unit | Path |
|------|------|
| `Lux.Platform.Windows.Console` | `src/platform/windows/Lux.Platform.Windows.Console.pas` |
| `Lux.Platform.Windows.TerminalWriter` | `src/platform/windows/Lux.Platform.Windows.TerminalWriter.pas` |
| `Lux.Platform.Windows.TerminalSession` | `src/platform/windows/Lux.Platform.Windows.TerminalSession.pas` |
| Demo | `examples/windows_demo/windows_demo.pas` |

Covered behaviour: console probe, VT enablement, UTF-8 code pages, `ILuxTerminalWriter` via `WriteFile`, idempotent restore, redirected-stdout rejection, differential render against a real console. No Unix backend yet. No Win32 in core/surface/renderer.

## Verified locally (Windows x86_64, FPC 3.2.2)

| Item | Result |
|------|--------|
| Portable isolation | `tools\check_portable.ps1` → passed |
| Portable tests | `tools\test.ps1` → **94 passed, 0 failed** |
| Windows unit tests | `tools\test_windows.ps1` → **16 passed, 0 failed** |
| `windows_demo` | compiled; ran in a new console via `Start-Process` → **exit 0** |
| Integration tests | compiled; ran in a new console → **exit 0** |
| Classic console | not separately instrumented in this session; demo used the host default console host via `Start-Process` |
| Win32 (i386) | **not claimed** (not built) |

CI workflow updated (Ubuntu portable job + Windows job, no `lazarus-version: recursive`). Green status depends on the next GitHub Actions run after push.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target windows-demo
.\bin\windows_demo.exe
```

Optional interactive integration:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test_windows_integration.ps1
```

## Next

Phase 3B: Unix terminal backend. Do not start controls yet.
