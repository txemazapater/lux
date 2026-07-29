# LUX Status

Last updated: 2026-07-29

## Current phase

**Phase 6 — Layout and common controls** — **in progress** (6A–6D done)

Phases 0–5, 5.1, 5.2, 6A, **6B.1–6B.4**, **6C**, and **6D** are complete with visual review passed. Phase 5.2.1 deferred resize remains experimental.

**Phase 7 — Appearance System** is planned after Phase 6 completes (ADR 0013). Do not start Phase 7 implementation yet.

Former roadmap “Developer usability” is now **Phase 8**; “Lantern readiness” is **Phase 9**.

## Recent closures

| Item | Status |
|------|--------|
| 6B.4 split interaction hardening | done |
| 6C mouse dispatcher + ScrollView | done (visual review passed) |
| 6D Label / CheckBox / RadioButton | done (visual review passed) |

## Verified (latest local)

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **495 passed** |
| `form_demo_windows` | builds |
| Visual review | **passed** (6D) |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target form-demo
.\bin\form_demo_windows.exe
```

## Next

Continue remaining Phase 6 (deferred Toggle/Separator/GroupBox as assigned, then **6E** ProgressBar/Slider). Appearance System is Phase 7 after Phase 6.
