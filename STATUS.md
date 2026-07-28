# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 3 — Platform abstraction** (next)

Phases 0, 1 and 2A are complete.

## Phase 0 — Foundation

Status: **complete**

## Phase 1 — Portable rendering core

Status: **complete**

## Phase 2A — Portable ANSI renderer

Status: **complete**

| Unit | Path |
|------|------|
| `Lux.Terminal.Writer` | `src/terminal/Lux.Terminal.Writer.pas` |
| `Lux.Terminal.MemoryWriter` | `src/terminal/Lux.Terminal.MemoryWriter.pas` |
| `Lux.Terminal.Ansi` | `src/terminal/Lux.Terminal.Ansi.pas` |
| `Lux.Renderer` | `src/rendering/Lux.Renderer.pas` |

Covered behaviour: writer interface, memory sink, ANSI cursor/colour/style/clear helpers, differential frame rendering with run coalescing, wide-character continuation handling, invalidate/resize full repaint, redundant sequence suppression. No Win32, termios, stdout or input code.

## Verified locally

| Item | Result |
|------|--------|
| Host | Windows x86_64 |
| Compiler | Free Pascal 3.2.2 |
| Build | `tools\build.ps1` → success |
| Tests | `tools\test.ps1` → **94 passed, 0 failed** |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
powershell -ExecutionPolicy Bypass -File tools\test.ps1
```

```bash
./tools/build.sh
./tools/test.sh
```

## Next

Phase 3: Windows and Unix backends that own the real terminal and implement `ILuxTerminalWriter`. Do not start controls yet.
