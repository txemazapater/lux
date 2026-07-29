# ADR 0013: Appearance themes, glyph sets and portable configuration

## Status

Accepted as architecture for **Phase 7 — Appearance System** (planned; not yet implemented).

## Context

Phase 6 builds layout and common controls. Temporary concrete colors and glyph literals in controls work for demos but will not scale. Hardcoding appearance inside every widget couples product look to control code, blocks runtime theme changes, and mixes terminal capability concerns into UI logic.

Appearance is therefore a separate top-level phase **after** Phase 6 completes, and before Developer usability (now Phase 8) and Lantern readiness (now Phase 9). Phase 6 subphase numbers (6A–6J) are unchanged.

## Decision

### Semantic appearance

Controls request semantic color **roles** (for example Background, Surface, Text, TextMuted, TextDisabled, Border, Accent, AccentText, Selection, SelectionText, Focus, Error, Warning, Success). The active theme resolves roles to `TLuxColor`. Exact role enumeration may be refined during Phase 7.

### Control state is separate from color

Appearance accounts for visual states such as Normal, Hovered, Focused, Pressed, Selected, Disabled via explicit state-aware theme queries or style records.

Do **not** implement a CSS selector engine, class/ID matching, or arbitrary tree-based style cascading.

### Glyphs and metrics are theme resources

Indicator characters (checkbox/radio marks, arrows, scroll marks, borders, tree expanders, splitter marks, selection marks) belong in a reusable glyph-set abstraction with at least Unicode and ASCII-compatible sets. Shared visual cell metrics (padding, indicator spacing, focus-marker width, separator spacing) are appearance resources. Layout remains owned by the existing layout system.

### Theme ownership and access

Prefer an application-owned active theme (for example `TLuxTheme` / `TLuxThemeManager`) and expose it through the paint context (`Ctx.Theme`) or another explicit rendering context. Avoid a hidden global mutable singleton.

### External format: `.luxtheme` (UTF-8 INI)

External themes use the `.luxtheme` extension and UTF-8 INI-style syntax (for example via Free Pascal `TIniFile`). Sections may include `[theme]`, `[colors]`, `[glyphs]`, and `[metrics]`, with `version=1` and optional `base=<BuiltInName>` for a single built-in parent.

**LUX themes are declarative, portable UTF-8 files inspired by semantic styling concepts, but they do not implement CSS.** The `.css` extension and a real CSS parser are rejected: full CSS semantics would create expectations (cascading, selectors, specificity, inheritance, pseudoclasses, media queries) and complexity that a console framework does not need.

### Built-in themes and fallback

Ship at least `LuxDark`, `LuxLight`, and `LuxMonochrome` (restricted color + ASCII glyph option). An invalid, missing, or unreadable external theme falls back to a built-in theme with diagnostics. Loading failure must not crash interactive applications unless the caller requests strict mode.

### Configuration storage and paths

Theme **definitions** (`.luxtheme` files) are separate from user **preferences** selecting the active theme (INI-style `config.ini`).

Do **not** use the Windows Registry for theme definitions or normal appearance preferences.

Portable path conventions:

- Windows: `%APPDATA%\<ApplicationName>\` and optional `<ApplicationDirectory>\themes\`
- Unix: XDG (`$XDG_CONFIG_HOME/<app>/` or `~/.config/<app>/`); optional system shares under `/usr/local/share/lux/themes/` and `/usr/share/lux/themes/` (read-only)
- Portable mode: directories relative to the executable (explicit API and/or conventional flag), not solely the process CWD

Search precedence for a named theme: explicit path → portable themes → user themes → application-local themes → system shared themes → built-in registry. Higher priority wins; do not silently merge same-named files from different directories.

### Terminal capability mapping

Themes describe desired semantic colors. The output backend maps RGB/default colors to true color, 256-color, 16-color, or monochrome. Capability conversion stays out of controls and out of theme parsing.

### Runtime switching

Replacing the active theme updates the application theme reference, invalidates the root, and triggers a full logical repaint while preserving control state, focus, layout tree and application data. Color/glyph-only changes repaint; metric changes that affect preferred sizes may relayout then repaint.

### Fonts

LUX does not select, install or persist terminal fonts. The emulator and user own the typeface. LUX may document recommended font characteristics but manages glyph selection and capability fallback only.

### Implementation increments

7A model → 7B integration/migration → 7C external files → 7D path discovery → 7E acceptance demo. Suggested units under `src/appearance/`. Platform path discovery may use `src/platform/windows` and `src/platform/unix` behind a portable API.

## Consequences

- Phase 6 continues without an appearance refactor until Phase 6 is complete.
- Existing controls will migrate in Phase 7B away from unnecessary hardcoded colors/glyphs.
- Demo-only diagnostic colors may remain local when they intentionally communicate debug meaning.
- Tests must use temporary directories and injected environment/path providers — never the real Registry, user profile, or `/usr/share` for assertions.

## Rejected alternatives

- Windows Registry as primary store
- Real CSS parser / `.css` as the theme format
- JSON or TOML requiring an additional parser for v1
- Hardcoded themes only (no external files)
- Global mutable theme singleton
- Application-specific (Lantern/Lighthouse) theming inside the LUX core
- Multi-level theme inheritance beyond a single optional built-in base in v1
- Terminal font installation/selection, Nerd Font dependency, remote theme repositories, hot filesystem watchers

## References

- Roadmap: Phase 7 — Appearance System (`ROADMAP.md`)
- Related: portable rendering core, ANSI backend, control paint context
