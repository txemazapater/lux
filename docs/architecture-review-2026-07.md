# LUX — Architecture Review and Complete Capability Map

**Date:** 2026-07-29  
**Status:** Review complete — implementation paused pending adoption of recommendations  
**Scope:** Architecture only (no code changes required by this document)

> Define now what conditions many future pieces; defer what can be added later without breaking existing contracts.

### Naming and product boundaries

These names refer to different architectural levels and must not be used interchangeably:

| Name | Role |
|------|------|
| **LUX** | Technical name of the framework and this codebase |
| **Lighthouse** | Provisional commercial / public-facing name of LUX (same product, different label) |
| **Lantern** | Provisional name of a possible future *application* built on LUX/Lighthouse. Lantern does not currently exist. It is a consumer, not part of the framework |

Therefore:

- LUX and Lighthouse may refer to the same product from technical and commercial perspectives respectively.
- Lantern must remain architecturally separate from LUX.
- Lantern-specific models, commands, persistence, panels and workflows must not enter the LUX core.
- This document must not treat “Lantern” and “Lighthouse” as synonyms.

**Note on Phase 6D:** Separator, Toggle and GroupBox are **already implemented**. The review treats them as present, not as pending controls.

---

## 0. Executive summary

LUX has a mature **portable TUI core**: cell surfaces, differential ANSI render, Windows/Unix backends, normalized events, application loop, control tree, focus, layouts, split/capture, semantic mouse, ScrollView, and a first set of form controls.

Continuing the current Phase 6 sequence (**6E ProgressBar/Slider → 6F Toolbar → 6G Menus → … → 6J Docking → then Phase 7 Appearance**) would implement several controls **before** shared models they need (range, commands, overlays, client-area discipline, appearance). That is the main risk this review addresses.

**Recommended next implementation subphase (after adopting this review):**  
**Stabilization S1 — Shared container & paint contracts** (client area / `ContentOffset`, paint appearance injection points, freeze provisional glyphs), **then S2 — Range model**, **before** ProgressBar/Slider. Do **not** start 6E as currently worded. Do **not** start full Phase 7 theme files yet; do pull forward a **thin appearance contract** (roles + glyph sets in memory) so new controls stop hardcoding literals.

---

## 1. LUX Vision and Scope

### 1.1 What LUX is

LUX is a **portable, Free Pascal TUI framework**: a component-oriented, event-driven toolkit for building interactive terminal applications.

More precisely, it is the combination of:

| Concept | In LUX? | Meaning |
|---------|---------|---------|
| TUI framework | **Yes** | Application loop, events, invalidation, session lifecycle |
| Control toolkit | **Yes** | Composable controls + layouts |
| Backend-independent UI engine | **Partially** | Logic is portable; first-class output is ANSI/VT cell terminals |
| Full application architecture | **No** | No document model, no domain services, no plugin host |

LUX (commercially referred to as **Lighthouse**) is **not** a GUI framework and **not** a terminal emulator. It is the framework product. **Lantern** would be a separate consumer application, not a synonym for Lighthouse.

### 1.2 Applications it aims to support

**In scope (framework-level):**

- Interactive console tools and admin TUIs
- Multi-panel workbenches and dashboards
- Modal dialogs and form-driven flows
- Long-running interactive sessions
- Keyboard-first workflows with optional mouse
- Split / (later) dockable layouts
- Editors and explorers **as consumers**, once editing/list/tree primitives exist

**Possible future consumer (provisional):** Lantern — a Git-oriented terminal workbench. It does not exist yet and must not define LUX APIs.

### 1.3 Architectural properties to protect

- Portability (Windows + Unix; no OS APIs in controls/layouts)
- Layered dependencies (no cycles; platform behind interfaces)
- Differential cell rendering (full paint ≠ clear screen)
- Normalized input and **semantic** gestures in LUX, not per-platform
- Composition via ownership tree + layout hints
- Testability without a real TTY for portable behavior
- Keyboard accessibility as a first-class path
- Stable contracts over convenience from demos
- Controlled degradation by terminal capability
- UTF-8 / `UnicodeString` at public text boundaries

### 1.4 Core vs optional vs application

**Core (without these, it is not LUX):**

- Geometry, color, cell, surface
- Terminal writer + ANSI differential renderer
- Platform session + event source
- Event queue, timers, application loop
- Control tree, focus, invalidation, paint context
- Layout contracts (min / preferred / expand)
- Semantic mouse dispatch + capture hooks

**Optional packages / later modules (framework, but not required to boot):**

- Advanced controls (grid, tree, table, rich editor)
- Docking host
- Theme file loading and path discovery
- Visual diagnostics overlays
- Automation / accessibility bridges
- Alternate render backends (if ever)

**Consumer applications such as Lantern (must not enter LUX core):**

- Git document model, staging, diff, history, branches
- Repository workspace and process integration
- Product-specific panels and commands
- Session persistence keyed to that application’s identity
- Specialized editors (commit message semantics, etc.)

Lighthouse branding, packaging and public naming are product concerns for LUX itself; they are not a separate framework layer and are not Lantern.

### 1.5 Explicit non-goals (near term)

- General-purpose GUI replacement
- Advanced typography / image protocols as product features
- Identical pixels on every terminal emulator
- Implementing terminal protocols beyond needed VT usage
- Business logic or Git inside LUX
- Forcing a single application shell / DI container
- CSS-like styling engines
- Windows Registry as configuration store

---

## 2. LUX Architecture Map

### 2.1 Layers (current + target)

```text
Applications (demos; future consumers such as Lantern)
  -> Controls / Layouts / (future Appearance consumers)
    -> ControlApplication / Focus / MouseDispatcher
      -> Application loop / EventQueue / Timers
        -> Events (normalized)
          -> Platform EventSource + Session + Writer
        -> Surface / Cell / Renderer / ANSI
          -> TerminalWriter (platform)
```

### 2.2 Subsystem responsibilities

| Subsystem | Owns | Must not own |
|-----------|------|--------------|
| **Platform** | Session enter/restore, raw I/O, size, signals, clipboard (later) | Controls, layout, themes |
| **Terminal capabilities** | What the active terminal can do | Widget policy |
| **Input normalization** | Physical → `TLuxEvent` | Click/drag semantics |
| **Gesture / interaction** | Click, dblclick, drag, capture, hover | Platform APIs |
| **Application** | Loop, invalidate, timers, session wiring | Domain models |
| **Control tree** | Ownership, bounds, visibility, enabled, paint, hit | ANSI emission |
| **Layout** | Measure/arrange from hints | Paint, input |
| **Focus / navigation** | Focused control, tab order | Commands (yet) |
| **Rendering** | Diff, cursor/color state, erase strategies | Interaction |
| **PaintContext** | Origin, clip, surface, (future) resolved appearance | Arbitrary services bag |
| **Appearance (planned)** | Roles, glyphs, metrics, themes | Layout geometry rules |
| **Commands (missing)** | Execute / CanExecute / presentation hooks | Business Git ops |

### 2.3 Dependency rules (allowed / forbidden)

**Allowed:**

- Controls → core, events, surface/paint helpers, layouts contracts
- Layouts → controls geometry/hints only
- App → events, rendering, terminal interfaces, controls host
- Platform → OS APIs; exposes interfaces upward
- Renderer → surface + terminal writer/ANSI helpers (ADR 0001)

**Forbidden:**

- Controls / layouts → Win32 / termios / platform units
- Layout → ANSI renderer
- Backend → control types
- Renderer → mouse/focus policy
- Commands → specific Button class as sole definition of an action
- Consumer-app domain types (e.g. Lantern Git models) → `src/` LUX units
- Demos (`examples/debug`) → treated as stable public API

### 2.4 Trees: one tree for now

**Decision provisional (stable enough):** one ownership/visual tree (`TLuxRootControl` + children), with z-order = child list order (Stack).  

**Overlay / popup / modal** will likely need an **overlay layer or scoped root** later. Do **not** invent three trees now. Introduce overlays when Menu/Dialog demand them, with an explicit ADR.

### 2.5 Client area (emerging contract)

Already present in practice:

- `ContentOffset` on containers (Panel border, GroupBox, ScrollView)
- `ClientSize` / GroupBox `ClientRect`
- Children use **client-local** coordinates

**Stabilize as shared contract before TabControl / Dialog / ScrollBar chrome.**  
Do not let each new container invent a different inset rule.

---

## 3. Capability Matrix

Legend — **Class:** C = core, O = optional framework, A = consumer application (e.g. Lantern).  
**State:** done / partial / planned / missing / experimental.

| Capability | Class | Owner | State | Depends on | Consumers | Phase hint | Decide by | Early risk | Late risk |
|------------|-------|-------|-------|------------|-----------|------------|-----------|------------|-----------|
| Application loop | C | `TLuxApplication` | done | events, timers, writer | all | 4 | — | — | — |
| Event cycle | C | queue + source | done | platform | app, controls | 4 | — | — | — |
| Control tree | C | `TLuxControl*` | done | geometry | all widgets | 5 | — | — | — |
| Layout V/H/Stack/Split | C | `src/layouts` | done | hints | demos, forms | 6A–6B | grid later | over-abstract | ad-hoc bounds forever |
| Focus / Tab | C | FocusManager | done | tree | form controls | 5 | scopes before modal | premature scopes | modal focus bugs |
| Invalidation | C | control/app | done (full-frame) | — | all | 5 | damage regions later | premature optimization | perf cliffs |
| Surface / render | C | Surface, Renderer | done | cell, ANSI | all | 1–2 | — | — | — |
| Terminal capabilities | C | probe/session | partial | platform | theme map, cursor | 3 / 7 | before theme map | fake matrix | hardcoded assumptions |
| Input normalize | C | platform sources | done | — | gestures | 4 | — | — | — |
| Gestures / mouse | C | MouseDispatcher | done | events | Button, Split, Scroll | 6C | — | — | — |
| Mouse capture | C | Root + Split | done | gestures | Split, future DnD | 6B | — | — | — |
| Commands / actions | C/O | missing | missing | notify | Menu, Toolbar, Button | **before 6F/6G** | before menus | overbuilt ICommand | each control owns callbacks only |
| Shortcuts | C/O | missing | missing | commands, focus | app | with commands | before palette | key-eating chaos | inconsistent UX |
| Appearance / themes | C | planned ADR 0013 | planned | capabilities | all paints | **thin contract now; files later** | before more glyphs | full CSS | permanent literals |
| Glyphs / metrics | C | provisional consts | provisional | appearance | CheckBox, borders | with appearance | now | theme engine | migration tax |
| Client area | C | ContentOffset | partial | geometry | Panel, GroupBox, Scroll, Tab | **stabilize now** | before Tab/Dialog | wrong abstraction | every container forks |
| Border / padding | C | mixed | partial | appearance + layout | Panel, GroupBox | with client area | — | — | — |
| Range model | C | missing | missing | — | Progress, Slider, ScrollBar, Spin | **before 6E** | before ProgressBar | one size fits none | 4 incompatible APIs |
| Selection model | O | missing | missing | items/text | lists, trees, text | before List/Tree/Edit | before ListBox | forced unity | copy-paste selection |
| Scroll model | C | ScrollView partial | partial | range? | ScrollView, lists, editor | harden before ScrollBar | before ScrollBar chrome | — | desync chrome |
| Text / edit model | O | missing | missing | Unicode width | TextBox, editor | own phase | before TextBox | TinyMCE-in-TUI | unusable editors |
| Validation | O | missing | missing | — | forms, dialogs | with edit | optional | — | — |
| Menus | O | missing | missing | commands, overlay | apps | after commands+overlay | — | — | — |
| Popups / overlays | C/O | missing | missing | focus, hit, z | menus, combo, tip | **before 6G** | before menus | second tree early | hit-test nightmares |
| Dialogs / tooltips | O | missing | missing | overlay, focus | apps | after overlay | — | — | — |
| Tabs | O | missing | missing | client area | apps | after client area | — | — | — |
| Lists / tables / trees | O | missing | missing | selection, scroll, virt | consumers (e.g. Lantern) | after scroll+selection | — | — | — |
| Virtualization | O | missing | missing | scroll | large lists | with lists | — | — | — |
| Timers | C | TimerScheduler | done | clock | app, later caret | 4 | — | — | — |
| Async tasks | O | missing | missing | UI dispatch | long-running app work | Phase 9 / consumers | before heavy async UI | threads in core | update-from-worker bugs |
| Clipboard | C | missing | missing | platform | edit, paste | before TextBox | — | — | — |
| Drag-drop data | O | missing | missing | capture | docking, files | late | after docking need | — | — |
| Persistence / config | O | missing | missing | — | themes, layout | interfaces in LUX | before docking persist | Registry temptation | ad-hoc files |
| Layout serialization | O | missing | missing | split tree | docking, workspace | before 6J persist | before docking | — | irreversible layouts |
| Docking | O | missing | missing | split persist, overlay? | multi-panel apps | late optional | after persist model | docking-first | rewrite splits |
| Diagnostics | O | demos only | partial | — | developers | Phase 8 | — | — | — |
| Visual testing | O | surface tests | partial | surface | CI | grow with controls | — | golden hell | regressions |
| Accessibility | O | keyboard only | partial | focus | all | incremental | — | screen-reader promises | unusable TUIs |
| i18n / Unicode | C | width approx | partial | cell width | text, layout | continuous | cursor unit before edit | wrong cursor unit | editor rewrite |
| Automation | O | missing | missing | — | tests | late | — | — | — |
| Consumer app integration | A | — | — | LUX contracts | e.g. Lantern | Phase 9 | — | domain in core | — |

---

## 4. Control Taxonomy (infrastructure needs)

### Primitives
| Control | Status | Shared needs |
|---------|--------|--------------|
| Label | done | Unicode width |
| Separator | done | glyphs, orientation |
| Spacer | missing | layout only |
| Panel / Border | done | client area, glyphs |
| GroupBox | done | client area, title metrics |
| Icon / Canvas | missing | glyphs / free paint |

### State / action
| Control | Status | Shared needs |
|---------|--------|--------------|
| Button | done | (future) Command |
| CheckBox / Radio / Toggle | done | glyphs, OnChange |
| Link / CommandButton | missing | Command, shortcuts |

### Range
| Control | Status | Shared needs |
|---------|--------|--------------|
| ProgressBar / Slider / SpinBox | missing | **Range** |
| ScrollBar | missing | Range + **Scroll** sync |
| Gauge | missing | Range |

### Containers
| Control | Status | Shared needs |
|---------|--------|--------------|
| ScrollView | done (foundation) | Scroll model harden, later ScrollBar |
| Split | done | persistable ratio (later) |
| Stack / V/H | done | — |
| Grid / DockPanel / Expander | missing | layout + client area |

### Navigation / collection / edit / menus / overlays
Mostly **missing**; require selection, scroll, text, commands, overlay as per matrix.

### Consumer-application controls (e.g. provisional Lantern)

RepositoryTree, StagingView, DiffView, CommitEditor, etc. — **application layer**, built on LUX list/tree/edit/split/command primitives. Not LUX core. Not Lighthouse (commercial name of LUX).

---

## 5. Shared Models Review

| Model | Verdict | Why | When |
|-------|---------|-----|------|
| **Client-area / ContentOffset** | **Adopt now (stabilize)** | Panel, GroupBox, ScrollView, future Tab/Dialog already share the idea | S1 |
| **Border / padding vs theme glyphs** | Split: geometry in layout/control; glyphs in appearance | Mixing caused provisional constants | S1 + thin appearance |
| **Range** | **Adopt before Progress/Slider/ScrollBar** | Same min/max/value/step/clamp story | S2 before 6E |
| **Scroll** | **Harden existing ScrollView model**; ScrollBar is a view | Avoid second scroll truth | before ScrollBar chrome |
| **Command / Action** | **Adopt before Menu/Toolbar/Palette** | Otherwise three callback styles | before 6F/6G |
| **Shortcut** | With Command; scoped routing | Conflicts need policy | with commands |
| **Selection** | **Do not unify text + items yet** | Different semantics; share only tiny helpers if any | before List/Tree; text with editor |
| **Item model** | Minimal interfaces later; no binding framework | Premature abstraction risk | with ListBox |
| **Text model** | **Separate subsystem** | Not a `Text` property | own phase before CodeEditor |
| **Validation** | Defer | Few consumers | with forms/dialogs |
| **Async task** | Contracts in LUX optional; threads careful | Consumers may need progress/cancel | before heavy async UI |
| **Persistable layout** | Model before docking UI | Split ratios already exist | before 6J / docking |
| **Overlay manager** | Required before menus/tooltips | Focus + hit-test | before 6G |

---

## 6. Dependency Graph (conceptual)

```text
MenuBar / Popup / Toolbar / Button / Palette
        └──> Command (+ Shortcut)

ProgressBar / Slider / SpinBox / ScrollBar
        └──> Range
ScrollBar / ScrollView / Lists / Editor
        └──> Scroll (ScrollView is source of truth for viewport)

Panel / GroupBox / Tab / Dialog / Scroll chrome
        └──> Client-area (+ Border geometry)
        └──> Appearance glyphs (borders, markers)

List / Table / Tree / Combo
        └──> Selection (item) + Scroll (+ virtualization later)

TextBox / TextArea / CodeEditor
        └──> Text model + text selection + Clipboard + Undo

Splitter / Docking / Workspace
        └──> Persistable layout tree

Menu / Combo / Tooltip / ContextMenu
        └──> Overlay layer + Focus scope

Git ops / Search / Index (consumer apps such as Lantern)
        └──> Async task + UI marshal
```

---

## 7. Roadmap Review

### 7.1 Problem with current Phase 6 → 7 sequencing

Current: finish **all** of 6E–6J, **then** Appearance (ADR 0013).

That forces ProgressBar, Toolbar, Menus, Tabs, Docking prep to ship with **more** provisional colors/glyphs and **without** Range / Command / Overlay contracts.

### 7.2 Proposed reorganization (numbers illustrative)

Keep completed work as history (0–6D). Re-slice **remaining** work:

| New slice | Content | Replaces / absorbs |
|-----------|---------|-------------------|
| **S0** | Adopt this review; freeze demo-only APIs; update ROADMAP | — |
| **S1** | Shared container & paint contracts: client area, ContentOffset docs/tests, appearance **injection points** (no `.luxtheme` yet), migrate obvious glyph consts behind a narrow API | part of old “foundation” + early 7A |
| **S2** | Range model + tests | precondition for old 6E |
| **S3** | ProgressBar, Slider (thin) using Range | old 6E |
| **S4** | Scroll model hardening + ScrollBar (optional chrome) | part 6C leftover |
| **S5** | Command + Shortcut (+ Button/Toggle binding) | precondition for 6F/6G |
| **S6** | Overlay + focus scopes | precondition for menus/dialogs |
| **S7** | Toolbar / StatusBar using Commands | old 6F |
| **S8** | MenuBar / PopupMenu | old 6G |
| **S9** | TabControl (client area) | old 6H |
| **S10** | Grid layout | old 6I |
| **S11** | Persistable split tree | old 6J |
| **A1–A5** | Full Appearance (built-ins → files → paths → demo) | old Phase 7, can interleave after S1 |
| **E\*** | Editing infrastructure | before consumer editors |
| **C\*** | Collection + selection + virtualization | before consumer tree/list |
| **D\*** | Docking host (optional package?) | after S11 |
| **L\*** | Consumer readiness contracts (e.g. for Lantern) | old Phase 9 |
| **U\*** | Developer usability / diagnostics | old Phase 8 |

**Phase 6 as a monolith “layout + all common controls” should end at 6D.** Remaining items are cross-cutting infrastructure plus controls that consume it.

### 7.3 What can stay deferred safely

- Docking / floating windows
- Full `.luxtheme` path discovery
- Text editor / CodeEditor
- Tables, trees, virtualization
- Drag-drop payloads
- Async scheduler beyond timers
- Visual golden-file systems
- Triple-click / long-press

### 7.4 What must not be deferred further

- Treating demo EventLog as core API
- More controls with hardcoded glyphs without an escape hatch
- ProgressBar/Slider without Range
- Menus without Overlay + Command
- TabControl without stabilized client area
- Docking without persistable layout model

---

## 8. Architecture Decision Backlog (prioritized)

| # | Question | Provisional answer | Decide by | Defer OK? |
|---|----------|--------------------|-----------|-----------|
| D1 | Single control tree vs overlay root? | Single tree until menus | before Menu | yes until S6 |
| D2 | Client area common API? | Stabilize `ContentOffset` + `ClientRect` pattern | **S1** | no |
| D3 | Appearance: roles now or after all controls? | Thin in-memory roles/glyphs **now**; files later | **S1 / A1** | files yes; roles no |
| D4 | PaintContext contents? | Surface, origin, clip, + resolved theme ref; no service locator | S1 | — |
| D5 | Command vs Action? | One `ILuxCommand` / class; presentation optional | S5 | no if menus soon |
| D6 | Shortcut routing order? | Focused control first, then scopes, then app | S5 | — |
| D7 | One Range for Slider/Progress/ScrollBar? | Yes for value span; ScrollBar adds viewport/window | **S2** | no |
| D8 | Unified Selection? | No — item vs text separate | before lists/edit | yes |
| D9 | Scroll ownership? | ScrollView owns offsets; ScrollBar reflects/commands | S4 | — |
| D10 | Overlay ownership? | Application/OverlayManager, not each menu | S6 | no if menus |
| D11 | Modality home? | Overlay/focus scope, not every dialog class | S6 | — |
| D12 | Timers? | Keep app scheduler (done) | — | — |
| D13 | Async? | Interface + marshal-to-UI; no raw thread UI | before heavy consumer async | yes short-term |
| D14 | Clipboard? | Platform service, text first | before TextBox | yes until edit |
| D15 | DnD payloads? | Defer | docking need | yes |
| D16 | Persistence? | LUX interfaces; app stores bytes/files | before layout persist | — |
| D17 | Docking in core? | Prefer optional module | D\* | yes |
| D18 | Unicode cursor unit? | Cell + grapheme policy for editor | before Text model | no for editor |
| D19 | Visual testing? | Keep surface asserts; goldens optional | ongoing | yes |
| D20 | Diagnostics in core? | Keep demo EventLog out of core | always | — |

---

## 9. Current Architecture Assessment

### 9.1 Stable contracts (protect)

- Geometry / Color / Cell / Surface clipping and wide-char rules
- `ILuxTerminalWriter`, ANSI diff renderer, full paint without clear (ADR 0006)
- Mirrored Windows/Unix session API (ADR 0003)
- `TLuxEvent` + `ILuxEventSource` + application loop (ADR 0004)
- Control ownership, local coords, focus Tab order (ADR 0005)
- Layout hints min/preferred/expand (ADR 0008)
- Logical cursor manager (ADR 0009)
- Split + mouse capture (ADR 0010)
- Semantic mouse dispatcher + ScrollView foundation (ADR 0011)
- Sibling-only radio grouping (ADR 0012)
- GroupBox client inset via ContentOffset (ADR 0014)

### 9.2 Provisional / experimental

- Hardcoded colors and box-drawing glyphs in controls (Phase 7 migration)
- Focus marker `>` as layout width consumer
- Phase 5.2.1 deferred resize commit
- Demo-only `Lux.Debug.EventLog`
- Preferred size using `Length` in places vs display width (Labels vs GroupBox title fix divergence)
- Invalidation always full-frame
- No overlay layer (menus will force the issue)
- Appearance ADR 0013 accepted as design, not implemented; sequencing vs Phase 6 needs revision

### 9.3 Technical debt / couplings

- Form demo previously overlaying Actions log (fixed) shows how demos can invent “layout” by absolute sibling paint order
- `UpdatePreferredFromTitle` / glyph literals scattered (partially isolated)
- Toolbar/Menu roadmap items assume Command model that does not exist
- ScrollView without ScrollBar leaves scrolling UX incomplete but model is ahead of chrome — good; keep it that way
- ARCHITECTURE.md still slightly behind (mentions Phase 6D partially)

### 9.4 Duplications to avoid growing

- Per-control orientation enums (mitigated: `TLuxOrientation` in geometry)
- Per-control border painting (Panel vs GroupBox) — candidate for shared border painter **after** appearance glyphs exist
- OnChange vs OnClick patterns — document convention; Command later unifies activation

---

## 10. Recommended Next Subphase

### Do not resume with Phase 6E (ProgressBar, Slider) as written.

### Next: **S0 + S1 — Architecture adoption and shared contracts**

**S0 (docs only, this pause):**

1. Mark implementation paused in `ROADMAP.md` / `STATUS.md` / `AGENTS.md`
2. Treat this document as the capability map of record
3. Visually accept 6D form demo (already improved) and close 6D formally if desired

**S1 (first implementation slice after pause):**

1. **Client-area contract:** document + tests for `ContentOffset` / `ClientSize` / `ClientRect` consistency across Panel, GroupBox, ScrollView
2. **Paint appearance seam:** introduce a minimal in-memory appearance object or glyph/role table injectable via Application → PaintContext (**no** `.luxtheme` files, **no** Registry)
3. Migrate the worst duplicated border/indicator literals behind that seam (Panel, GroupBox, Separator, CheckBox/Radio/Toggle markers)
4. Explicit rule: `examples/debug` stays demo-only

**Then S2:** Range model + portable tests  
**Then S3:** ProgressBar + Slider on Range  

Appearance **file loading** (old 7C–7D) stays after more controls stabilize against the in-memory seam.

---

## 11. Answers to the closing questions

| Question | Answer |
|----------|--------|
| What is LUX? | Portable Free Pascal TUI framework + control toolkit over a cell surface and ANSI backends (commercial name: Lighthouse) |
| Architecture to protect? | Layered deps, normalized input, semantic gestures, portable controls, differential render |
| Core? | Geometry→surface→render→platform session/events→app loop→tree/focus/layout/gestures |
| Optional? | Advanced controls, docking, theme files, diagnostics, automation |
| Lighthouse? | Provisional commercial name of LUX — same product, not a separate codebase |
| Lantern? | Possible future consumer app (Git/workbench domain); does not exist yet; must not enter LUX core |
| Provisional today? | Glyphs/colors, deferred resize, demo EventLog, no overlays/commands/range |
| Contracts before more controls? | Client area, thin appearance seam, Range, (soon) Command + Overlay |
| Shared capabilities? | Client area, Range, Scroll, Command, Overlay; not a universal Selection |
| Independent controls now? | Mostly polish on existing 6D; Spacer maybe |
| Must wait? | ProgressBar/Slider → Range; Menu/Toolbar → Command+Overlay; Tab → client area; Docking → persist model |
| Reorganize roadmap? | **Yes** — end Phase 6 at 6D; insert S1/S2 before old 6E |
| Does Phase 6 still make sense? | As history through 6D yes; as “do 6E–6J then appearance” **no** |
| Next subphase? | **S1 Shared container & paint contracts** (after S0 doc adoption) |
| Defer safely? | Docking, theme files, editor, trees, DnD, async framework |
| Decide now? | Client area, Range-before-6E, Command/Overlay-before-menus, thin appearance before more glyphs |

---

## 12. Adoption checklist

- [ ] Maintainer accepts S1 as next implementation slice (not 6E)
- [ ] ROADMAP “Current priority” points here
- [ ] ADR 0013 sequencing note updated (thin appearance may precede end of old Phase 6)
- [ ] Phase 6D marked visually accepted when maintainer confirms
- [ ] No new control PRs until S0/S1 agreement
