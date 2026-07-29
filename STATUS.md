# LUX Status

Last updated: 2026-07-29

## Current phase

**Phase 6B.3 — Split container, mouse capture and drag** — implemented; awaiting maintainer visual sign-off

Phases 0–5, 5.1, 5.2, 6A, **6B.1** and **6B.2** are complete (6B.2 visual review passed). Phase 5.2.1 deferred resize remains experimental.

## Phase 6B.3 — Split + capture

- `TLuxSplitContainer` (`Lux.Layout.Split`): two panes, internal divider, ratio `0..10000`
- Generic mouse capture on `TLuxControlApplication`
- Divider hover/drag + logical cursor requests
- ADR: `docs/adr/0010-split-container-mouse-capture.md`
- Demo: `examples/split_demo/`

## Verified

| Item | Result |
|------|--------|
| Host (dev) | Windows x86_64 FPC 3.2.2 |
| Portable tests | **366 passed** |
| `split_demo_windows` | builds |
| Visual review | pending maintainers |

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
.\bin\split_demo_windows.exe
```

## Next

Maintainer visual review of divider feel, nested splits and cursor feedback. Then **6B.4** interaction polish (keyboard, focus, appearance).
