# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 2 — Terminal output** (next)

Phases 0 and 1 are complete.

## Phase 0 — Foundation

Status: **complete**

- Source tree under `src/`
- `hello_lux` example
- `tools/build.ps1`, `tools/build.sh`
- Portable test runner: `tools/test.ps1`, `tools/test.sh`
- CI: `.github/workflows/ci.yml` (Ubuntu + Windows)

## Phase 1 — Portable rendering core

Status: **complete**

Implemented units:

| Unit | Path |
|------|------|
| `Lux.Core` | `src/core/Lux.Core.pas` |
| `Lux.Geometry` | `src/core/Lux.Geometry.pas` |
| `Lux.Color` | `src/core/Lux.Color.pas` |
| `Lux.Cell` | `src/core/Lux.Cell.pas` |
| `Lux.Surface` | `src/rendering/Lux.Surface.pas` |

Covered behaviour: geometry helpers, default/inherit/RGB colours, text styles, cells, surface clear/fill/clip/text, wide characters with continuation cells, resize and equality. All tests run in memory without a console.

## Verified locally

| Item | Result |
|------|--------|
| Host | Windows x86_64 |
| Compiler | Free Pascal 3.2.2 |
| Build | `tools\build.ps1` → success |
| Tests | `tools\test.ps1` → **50 passed, 0 failed** |

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

Phase 2: terminal writer interfaces, ANSI generation, frame diff renderer, memory-backed writer for tests.
