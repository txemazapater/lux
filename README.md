# LUX

**A modern TUI application framework for Free Pascal.**

LUX aims to bring a Delphi/VCL-inspired development experience to modern terminal applications: structured, reusable, event-driven and pleasant to use.

The project is written in **Free Pascal**, is **open source**, and treats the terminal as a first-class user interface rather than a compatibility fallback.

> Let there be light in the terminal.

## Vision

LUX will provide the foundations needed to build rich console applications with:

- ANSI/VT terminal rendering
- Unicode and UTF-8 support
- Keyboard and mouse input
- Windows, controls and dialogs
- Flexible layouts
- Themes and 24-bit colour
- Event-driven application architecture
- Cross-platform support
- A clean, Pascal-friendly API

The first real application built with LUX is expected to be **Lantern**, a Git-oriented terminal editor and developer workbench.

## Early design principles

1. **Free Pascal first** — portable, native and lightweight.
2. **Terminal-native** — designed for modern terminals, not emulated DOS screens.
3. **Composable** — small controls and services that can be combined into larger applications.
4. **Pragmatic** — useful software before theoretical perfection.
5. **Accessible API** — familiar to Delphi and Object Pascal developers.
6. **Open source by default** — transparent development and community participation.

## Tentative package structure

```text
src/
  lux.core/
  lux.terminal/
  lux.rendering/
  lux.events/
  lux.layout/
  lux.controls/
  lux.dialogs/
  lux.themes/
examples/
docs/
tests/
```

This structure is provisional and will evolve as the architecture becomes clearer.

## Status

**Phase 0** complete. **Phase 1** portable rendering core is implemented. See [STATUS.md](STATUS.md), [ROADMAP.md](ROADMAP.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Building

See [docs/BUILDING.md](docs/BUILDING.md).

Quick start (Windows):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
powershell -ExecutionPolicy Bypass -File tools\test.ps1
.\bin\hello_lux.exe
```

Quick start (Linux / macOS):

```bash
./tools/build.sh
./tools/test.sh
./bin/hello_lux
```

Expected toolchain:

- Free Pascal Compiler 3.2.2 or later
- Lazarus tools where useful, without requiring the Lazarus IDE at runtime
- Git

## License

LUX is released under the [MIT License](LICENSE).

---

Created in 2026 during project number 7156 of the Txema era.
