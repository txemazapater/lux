# LUX Status

Last updated: 2026-07-29

## Current phase

**Phase 6B.4 — Split interaction hardening and closure** — **done**

Phases 0–5, 5.1, 5.2, 6A, and **6B.1–6B.4** are complete. Phase 5.2.1 deferred resize remains experimental.

## Phase 6B.4 — Split interaction hardening

- Escape cancels active divider drag and restores the initial ratio
- Capture loss always clears dragging state and cursor requests
- Drag remains safe across resize/orientation/property changes; orientation change cancels drag
- Ratio updates use deterministic integer arithmetic
- ADR: `docs/adr/0010-split-container-mouse-capture.md` (updated for 6B.4)
- Demo: `examples/split_demo/` (Escape cancels drag while active)

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **426 passed** |
| `split_demo_windows` | builds |
| Visual review | **passed** (6B.3 maintainers) |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
.\bin\split_demo_windows.exe
```

## Next

Phase **6C** — ScrollView and scrollbars.
