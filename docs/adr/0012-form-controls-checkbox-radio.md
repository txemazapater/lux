# ADR 0012: Form controls — CheckBox, RadioButton, Label preferred size

## Status

Accepted (Phase 6D)

## Context

Phase 6D needs basic form controls that participate in layout (preferred size), focus, and the semantic mouse dispatcher introduced in 6C. Radio buttons need mutual exclusion without inventing GroupBox yet.

## Decision

- Reuse existing `TLuxLabel`; auto-update `PreferredWidth` / `PreferredHeight` from text.
- Add `TLuxCheckBox` and `TLuxRadioButton` in `src/controls/`.
- Interaction uses semantic `SemanticClick` and keyboard Space via `DoHandleEvent` — no raw platform mouse handling.
- CheckBox toggles; RadioButton selects (`Checked := True`) and never toggles off via click/Space.
- Radio grouping is **sibling-only**: when checked, clear other `TLuxRadioButton` children of the same `TLuxControlContainer` parent. Separate parents are independent groups.
- Focus indication uses focus colors plus a leading `>` glyph; disabled uses muted colors and rejects focus/state changes.

## Consequences

- GroupBox / named `GroupName` / Toggle / Separator remain deferred.
- Apps group radios by parenting them under the same panel (or layout cell container).

## Deferred

- Toggle, Separator, GroupBox
- Tri-state checkbox
- Accelerator / mnemonic keys
