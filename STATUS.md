# LUX Status

Last updated: 2026-07-29

## Current phase

**Phase 6D — Form controls** — **implemented** (expanded `form_demo` awaits visual review)

Phases 0–5, 5.1, 5.2, 6A, **6B.1–6B.4**, **6C**, and **6D** controls are implemented. Phase 5.2.1 deferred resize remains experimental.

**Phase 7 — Appearance System** remains planned after Phase 6 completes. Do not start Phase 7 or Phase 6E until 6D visual sign-off.

## Phase 6D controls

| Control | Status |
|---------|--------|
| Label / CheckBox / RadioButton | done (visual passed) |
| Separator (6D.1) | done |
| Toggle (6D.2) | done |
| GroupBox (6D.3) | done |

## Verified (latest local)

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **555 passed** |
| `form_demo_windows` | builds |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target form-demo
.\bin\form_demo_windows.exe
```

## Next

Visual review of expanded `form_demo`, then **6E — ProgressBar, Slider**.
