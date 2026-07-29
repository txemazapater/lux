# LUX Status

Last updated: 2026-07-29

## Current phase

**Phase 6B.2 — Cursor infrastructure** — implemented; awaiting maintainer visual sign-off

Phases 0–5, 5.1, 5.2, 6A and **6B.1** are complete. Phase 5.2.1 deferred resize remains experimental.

## Phase 6B.2 — Logical cursor

- `Lux.Cursor` / `TLuxCursorManager` (request vs commit, capabilities)
- Wired through `TLuxApplication.Cursor` after each paint (single flush)
- ADR: `docs/adr/0009-logical-cursor-manager.md`
- Demo: `examples/cursor_demo/`

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **307 passed** |
| `cursor_demo_windows` | builds |
| Visual review | pending maintainers |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
.\bin\cursor_demo_windows.exe
```

## Next

Maintainer visual review of caret positioning/shape. Then **6B.3** static split layout.
