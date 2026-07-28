# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 0 — Foundation** (in progress)

Scaffolding is in place. A minimal `hello_lux` example compiles and prints the framework version. Renderer, events, controls and platform backends are not implemented yet.

## Verified build

| Item | Result |
|------|--------|
| Host | Windows 10/11 (x86_64) |
| Compiler | Free Pascal 3.2.2 (`C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe`) |
| Command | `powershell -ExecutionPolicy Bypass -File tools\build.ps1` |
| Output | `bin\hello_lux.exe` |
| Runtime | prints `LUX 0.1.0-prealpha` |
| Exit code | 0 |

Linux CI and a test runner are still outstanding for Phase 0 exit criteria.

## Tree

```text
src/
  core/          Lux.Core.pas (LuxVersion)
  platform/      (empty placeholder)
  terminal/      (empty placeholder)
  rendering/     (empty placeholder)
  events/        (empty placeholder)
  controls/      (empty placeholder)
examples/
  hello/         hello_lux.pas
tests/           (placeholder)
tools/           build.ps1, build.sh
docs/            ARCHITECTURE.md, BUILDING.md
```

## Next

Complete remaining Phase 0 items (minimal test runner, CI), then Phase 1 portable rendering core per `ROADMAP.md` and `AGENTS.md`.
