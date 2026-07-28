# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 6A — Layout core** — **complete**

Phases 0–5, 5.1, 5.2 and 6A are complete. Phase 5.2.1 (deferred resize) remains experimental. Next: Phase 6B (Stack + Splitter).

## Phase 6A — Layout core

- Layout hints on `TLuxControl`: Min*, Preferred*, Expand
- `TLuxLayoutBox` / Vertical / Horizontal in `src/layouts/`
- Padding, spacing, expand share, relayout on resize
- Root fills top-level children; panel fills `Expand > 0` children
- Demo without application `SetBounds`
- ADR: `docs/adr/0008-layout-model.md`

## Phase 5.2.1 — Deferred resize commit

Experimental; pending sustained manual preference vs immediate commit. Unchanged by 6A.

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **263 passed** (includes layout) |
| Windows unit tests | run `tools/test_windows.ps1` after push |
| CI | push 6A then confirm Linux green |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
.\bin\controls_demo_windows.exe
```

## Next

Phase 6B — Stack layout + Splitter (see ROADMAP subphase table).
