# LUX Status

Last updated: 2026-07-28

## Current phase

**Phase 5.2.1 — Deferred resize commit** — **implemented, pending manual verification**

Phases 0–5, 5.1 and 5.2 are complete. Phase 5.2.1 adds experimental deferred resize on top of 5.2. Phase 6 remains stopped until resize strategy is accepted after Windows manual testing.

## Phase 5.2.1 — Deferred resize commit

Interactive resize still painted intermediate sizes after 5.2. New strategy: observe sizes during drag; commit the last size only after `LuxResizeSettleDelayMs` (75) of stability. No surface/renderer updates and no paints while pending. Queue coalescing kept.

- ADR: `docs/adr/0007-deferred-resize-commit.md` (experimental)
- Diagnosis / flow: `docs/phase-5.2-resize-repaint.md`

## Phase 5.2 — Resize and repaint stability

Root cause: `PaintAll` used `ESC[2J`; loop painted per resize. Fix: full repaint without clear; shrink erase strips; queue coalesce. ADR `0006`.

## Phase 5.1 — Windows keyboard verification

Win32 record path without VT input; VK-first translation. Inspector: `examples/input_inspector/`.

## Phase 5 — Control foundation

| Unit | Path |
|------|------|
| Controls | `src/controls/` |
| Example | `examples/controls_demo/` |
| ADR | `docs/adr/0005-control-tree-ownership-focus.md` |

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **239 passed** (local Windows; includes deferred resize) |
| Windows unit tests | **68 passed** (local; live injection skipped when redirected) |
| Deferred resize | unit-tested with injectable clock; **manual Windows comparison vs 5.2 still required** |
| CI | push then confirm Linux green |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
.\bin\controls_demo_windows.exe
.\bin\eventloop_windows.exe
```

## Next

Complete Windows manual resize comparison for 5.2.1. Accept, tune `LuxResizeSettleDelayMs`, or revert only the deferred-commit layer. Do not start Phase 6 until that decision.
