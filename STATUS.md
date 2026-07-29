# LUX Status

Last updated: 2026-07-29

## Current phase

**S2 — Range model** — **complete**

Portable `TLuxRange` (min/max/value/step/clamp). Next: **S3 — ProgressBar + Slider**.

## Implemented baseline

Phases 0–5, 5.1, 5.2, 6A–6D, **S1**, **S2**. Phase 5.2.1 deferred resize remains experimental.

## S2 summary

- `Lux.Range` / `TLuxRange` in `src/core`
- Shared clamp + `OnChange`; no viewport/page size (ScrollBar later)
- ADR: `docs/adr/0016-range-model.md`

## Next

1. **S3** — ProgressBar / Slider on Range  
2. Later: Scroll hardening / ScrollBar (S4)

## Verified

| Item | Result |
|------|--------|
| Portable tests | **644 passed** |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
```
