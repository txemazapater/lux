# LUX Status

Last updated: 2026-07-29

## Current phase

**S1 — Shared container & paint contracts** — **complete**

Invisible to applications: same glyphs/colors as before. Next: **S2 — Range model**.

## Implemented baseline

Phases 0–5, 5.1, 5.2, 6A–6D, **S1**. Phase 5.2.1 deferred resize remains experimental.

## S1 summary

- Public `ClientRect` / `ClientSize` contract on `TLuxControl`
- `Lux.Appearance` builtin roles/glyphs; paint context carries appearance
- Panel/GroupBox/Separator/CheckBox/Radio/Toggle/Split consume the seam
- ADR: `docs/adr/0015-client-area-appearance-seam.md`

## Next

1. **S2** — Range model  
2. ProgressBar / Slider on Range  

Do **not** start old Phase 6E without Range.

## Verified

| Item | Result |
|------|--------|
| Portable tests | **594 passed** |
| Visual | unchanged by design (framework-only S1) |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
```
