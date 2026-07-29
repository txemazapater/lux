# Phase 6D — Form controls

Status: **complete** pending visual review of the expanded `form_demo`.

## Controls

| Control | Unit | Interaction |
|---------|------|-------------|
| `TLuxLabel` | `Lux.Labels` | Non-focusable text; preferred size from Unicode length |
| `TLuxCheckBox` | `Lux.CheckBox` | Space + semantic click toggle; `Checked` / `OnChange` |
| `TLuxRadioButton` | `Lux.RadioButton` | Space + semantic click select; sibling-only exclusion |
| `TLuxSeparator` | `Lux.Separator` | Non-interactive H/V line; expandable in layouts |
| `TLuxToggle` | `Lux.Toggle` | `[ OFF ]` / `[  ON ]` + label; Space + semantic click |
| `TLuxGroupBox` | `Lux.GroupBox` | Titled border; client area via `ContentOffset` / `ClientRect` |

## Keyboard

- Tab / Shift+Tab: focus traversal (Separator and GroupBox are not focus stops)
- Space: activate CheckBox, RadioButton, Toggle
- Disabled controls: no focus, no state change

## Preferred sizes

- Label: width = `Length(Text)`, height = 1
- CheckBox: 4 + text (unfocused glyph budget)
- RadioButton: 4 + text
- Toggle: 1 (focus marker) + 7 (indicator) + optional spacing + text
- Separator: 1×1 preferred; Expand=1 on main axis
- GroupBox: minimum 2×2 (border only); preferred width grows with title display width (`+4` for corners/spaces); title never raises `MinWidth`

## GroupBox client area

See `docs/adr/0014-groupbox-client-area.md`. Children use client-local coordinates; one-cell border inset.

## Demo

`examples/form_demo/` exercises all Phase 6D controls, a disabled group, Unicode, Tab/Space/click, and a demo-only event log (`examples/debug/Lux.Debug.EventLog.pas`).

Theme preference radios are **demo labels only** — they do not load themes.

## Appearance (deferred to Phase 7)

Temporary centralized glyph constants live in Separator / GroupBox / Panel paint. No `TLuxTheme`, `.luxtheme`, or semantic color roles in Phase 6D.

## Known limitations

- No Toggle/CheckBox tri-state
- No GroupBox collapse / checkable titles
- Radio grouping remains sibling-only (no GroupName)
- Toggle indicator is text, not a graphical switch
