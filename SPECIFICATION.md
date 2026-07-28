# LUX Initial Specification

## 1. Purpose

LUX is an open-source framework for building modern terminal user interfaces with Free Pascal.

Its goal is to offer Object Pascal developers a structured, component-oriented and event-driven way to create native console applications without depending on Electron, browser runtimes or heavyweight GUI stacks.

LUX is not a clone of Turbo Vision, ncurses or the VCL. It may borrow proven ideas from them, but it is designed for modern terminals and current development practices.

## 2. Target environments

Initial targets:

- Windows 10/11 through Windows Terminal and compatible consoles
- Linux terminals with ANSI/VT support
- Free Pascal 3.2.2 or later

Future targets may include macOS and BSD systems.

## 3. Core principles

1. Native and lightweight.
2. Free Pascal first.
3. UTF-8 throughout the public API.
4. Modern ANSI/VT terminal support.
5. Clear separation between platform, terminal, rendering and controls.
6. Double-buffered rendering with minimal terminal updates.
7. Event-driven architecture.
8. No mandatory external runtime dependencies.
9. Testable core independent from the physical terminal.
10. Stable, readable and Pascal-friendly APIs.

## 4. Non-goals for the first milestone

The first milestone will not include:

- A visual form designer
- Plugin infrastructure
- Git integration
- AI integration
- A complete text editor
- Remote terminal protocols
- Image rendering protocols
- Full accessibility support

These may be added later. The immediate goal is a solid terminal and rendering foundation.

## 5. Proposed architecture

```text
Application
    |
    v
Controls and layouts
    |
    v
Windows and composition
    |
    v
Virtual screen / cell buffer
    |
    v
Terminal renderer
    |
    v
Platform backend
```

### 5.1 Core

Defines common value types, geometry, colours, errors and shared interfaces.

Candidate units:

- `Lux.Core`
- `Lux.Types`
- `Lux.Geometry`
- `Lux.Color`

### 5.2 Platform

Encapsulates operating-system-specific console operations.

Responsibilities:

- Enter and restore terminal mode
- Input mode configuration
- Terminal size detection
- Raw keyboard input
- Mouse event support where available
- Signal and shutdown handling

Candidate units:

- `Lux.Platform`
- `Lux.Platform.Windows`
- `Lux.Platform.Unix`

### 5.3 Terminal

Encapsulates ANSI/VT capabilities and terminal output.

Responsibilities:

- Cursor control
- Screen clearing
- Foreground and background colours
- Text attributes
- Alternate screen buffer
- Mouse mode activation
- Capability detection

Candidate units:

- `Lux.Terminal`
- `Lux.Terminal.Ansi`
- `Lux.Terminal.Capabilities`

### 5.4 Rendering

LUX must not render controls directly to the physical terminal.

All visual output is written to a virtual cell surface. A renderer compares the current frame with the previous frame and emits only the terminal changes required.

Initial cell model:

```pascal
type
  TLuxTextStyle = set of (
    tsBold,
    tsDim,
    tsItalic,
    tsUnderline,
    tsBlink,
    tsReverse,
    tsStrikeout
  );

  TLuxCell = record
    Text: UnicodeString;
    Foreground: TLuxColor;
    Background: TLuxColor;
    Style: TLuxTextStyle;
    Width: Byte;
  end;
```

`Text` is used instead of a single `WideChar` so the design can later support grapheme clusters and combining characters.

Candidate units:

- `Lux.Surface`
- `Lux.Renderer`
- `Lux.Renderer.Ansi`
- `Lux.Diff`

### 5.5 Input and events

Raw platform input is normalized into LUX events.

Initial event categories:

- Keyboard
- Mouse
- Resize
- Focus
- Timer
- Command
- Application shutdown

Candidate units:

- `Lux.Events`
- `Lux.Input`
- `Lux.Keys`

### 5.6 Application and controls

The first public application layer should provide:

- `TLuxApplication`
- Root surface management
- Main event loop
- Invalidation and repaint scheduling
- Focus management
- Basic control hierarchy

Initial controls after the rendering foundation:

- Label
- Panel
- Button
- Text input
- List box
- Scroll bar
- Dialog

## 6. Repository structure

```text
lux/
├── src/
│   ├── core/
│   ├── platform/
│   ├── terminal/
│   ├── rendering/
│   ├── events/
│   └── controls/
├── examples/
├── tests/
├── docs/
├── tools/
├── AGENTS.md
├── SPECIFICATION.md
├── ROADMAP.md
├── README.md
└── LICENSE
```

The directory structure may evolve, but platform-dependent code must remain separated from portable code.

## 7. Coding conventions

- Language: Object Pascal, Free Pascal mode.
- Preferred mode directive: `{$mode objfpc}{$H+}`.
- Source encoding: UTF-8.
- Unit namespace prefix: `Lux`.
- Public types: `TLux...`.
- Interfaces: `ILux...`.
- Exceptions: `ELux...`.
- Constants: Pascal-style descriptive names; avoid cryptic abbreviations.
- One principal responsibility per unit.
- No hidden global application state unless justified.
- Platform-specific conditional compilation must be isolated.

## 8. Error handling

- Programming errors should fail fast with clear exceptions.
- Recoverable terminal or capability failures should return structured results where practical.
- The terminal state must be restored on normal exit and after handled exceptions.
- Application code should never need to emit ANSI escape sequences directly.

## 9. Testing strategy

The renderer and surface model must be testable without a real terminal.

Required early tests:

- Cell creation and equality
- Surface bounds and clipping
- Rectangle fill
- Text drawing
- Wide character handling
- Frame diff generation
- Resize behavior
- Event normalization

A memory-backed terminal output implementation should be used in tests.

## 10. First executable milestone

The first milestone is complete when an example program can:

1. Enter the alternate terminal screen.
2. Detect the terminal dimensions.
3. Render a bordered panel and styled UTF-8 text through a virtual surface.
4. React to terminal resize.
5. Exit when Escape or `q` is pressed.
6. Restore the terminal correctly.
7. Build and run on Windows and Linux.
8. Pass unit tests for the portable rendering core.

## 11. First consumer application

The first substantial application built on LUX will be Lantern, a Git-oriented terminal editor and developer workbench.

Lantern is a consumer of LUX and must not drive Git-specific concerns into the LUX core.
