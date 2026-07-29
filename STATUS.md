# LUX Status

Last updated: 2026-07-29

## Current phase

**Phase 6B.1 — Stack Layout** — implemented; awaiting maintainer visual sign-off

Phases 0–5, 5.1, 5.2 and **6A** are complete. Phase 5.2.1 deferred resize remains experimental. Phase 6B continues as 6B.1–6B.5 (see ROADMAP).

## Phase 6B.1 — Stack Layout

- `TLuxStackLayout` in `src/layouts/Lux.Layout.Stack.pas`
- Portable tests for shared bounds + BringToFront hit-test
- Demo: `examples/stack_demo/` (`stack_demo_windows` / `stack_demo_unix`)
- ADR 0008 updated with stack note

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **287 passed** (includes stack) |
| `stack_demo_windows` | builds |
| Visual review | pending maintainers on real terminals |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
.\bin\stack_demo_windows.exe
```

## Next

Maintainer visual review of stack overlay / z-order. Then **6B.2** (cursor infrastructure).
