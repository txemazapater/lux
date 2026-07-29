# LUX Status

Last updated: 2026-07-29

## Current phase

**Technical pause — architecture review**

Implementation of new controls is suspended. Capability map and sequencing:

- [`docs/architecture-review-2026-07.md`](docs/architecture-review-2026-07.md)

## Implemented baseline

Phases 0–5, 5.1, 5.2, 6A, **6B.1–6B.4**, **6C**, and **6D** (Label, CheckBox, RadioButton, Separator, Toggle, GroupBox).

Phase 5.2.1 deferred resize remains experimental.

## Next (after adopting the review)

1. **S1** — Shared container & paint contracts (client area, thin appearance seam)
2. **S2** — Range model
3. ProgressBar / Slider on Range

**Do not start old Phase 6E as previously worded.**

## Verified (latest local)

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **567 passed** (after GroupBox border fixes) |
| `form_demo` | layout columns; visual OK for GroupBox borders |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target form-demo
```
