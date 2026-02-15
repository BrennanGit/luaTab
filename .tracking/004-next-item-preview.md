# Task #004: Next Item Preview + Item Barlines

- ID: #004-next-item-preview
- Created: 2026-02-15 02:30 UTC
- Status: in-progress
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #001
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add next-item lookup on the timeline and render thicker barlines at item starts/ends so upcoming item boundaries are visible before they arrive.

## Requirements
- Keep current MIDI item under cursor as the primary source.
- Detect the next MIDI item on the same track and surface its start/end times.
- Draw thicker vertical lines at current and next item boundaries.
- Preserve existing bar rendering and event placement.

## Acceptance Criteria
- [ ] When an item boundary falls within the visible bar window, a thicker line is drawn at that time.
- [ ] If a new MIDI item starts after the current one, its start line appears before the cursor reaches it.
- [ ] Behavior remains unchanged when no MIDI item is available (message still shown).

## Out of Scope
- Preloading or merging MIDI content from the next item.
- Overlap handling for multiple simultaneous items.

## Plan
- [ ] Add item boundary lookup (current + next) — Files: lib/source.lua, luaTab.lua — Functions: source.get_take(), rebuild_data() — Verification: manual REAPER playback across item boundary
- [ ] Render thick item boundary lines — Files: lib/render.lua, lib/config.lua — Functions: render.draw_systems() — Verification: manual visual check with two adjacent MIDI items
- [ ] Clamp events to item bounds — Files: lib/midi.lua, luaTab.lua — Functions: midi.extract_notes(), rebuild_data() — Verification: trim item start/end and confirm notes outside item are hidden
- [ ] Allow preview of upcoming item when cursor is before it — Files: lib/source.lua, luaTab.lua — Functions: source.get_take(), rebuild_data() — Verification: place cursor in gap before item and confirm empty bars until item start
- [ ] Update docs/tracking — Files: .tracking/meta.md, .tracking/004-next-item-preview.md, .tracking/architecture.md, planning/examples_and_testing.md — Functions: n/a — Verification: file review

## Execution Log

* 2026-02-15 02:30 UTC Start-of-turn Context Recap:

  * Goal: Add next-item preview and item boundary barlines
  * Current State: luaTab renders current item only with standard barlines
  * Blocking Issues: None
  * Next Subtask: Add item boundary lookup in source.lua and wire into rebuild_data
  * Known Risks: Boundary lines could misalign with bar prefix/content mapping

* 2026-02-15 02:39 UTC Added current/next MIDI item boundary lookup in lib/source.lua and wired item bounds into luaTab state.

* 2026-02-15 02:47 UTC Rendered item boundary lines with thicker strokes and added barline thickness config defaults.

* 2026-02-15 02:52 UTC Updated architecture and testing/config docs for item boundary markers.

* 2026-02-15 03:05 UTC Start-of-turn Context Recap:

  * Goal: Hide trimmed MIDI outside item bounds and show empty bars before item start
  * Current State: Item boundaries drawn, but notes render outside item edges
  * Blocking Issues: None
  * Next Subtask: Clamp MIDI extraction to item bounds and add next-item fallback
  * Known Risks: Picking a next item when no current item could mask "no MIDI" state

* 2026-02-15 03:18 UTC Added selected-track fallback to the next MIDI item when cursor is before any item.

* 2026-02-15 03:22 UTC Clamped MIDI extraction to item bounds to avoid rendering trimmed content.

* 2026-02-15 03:26 UTC Updated architecture notes and added testing coverage for gaps/trim handling.

## Decisions

* Item boundaries are drawn as thicker vertical lines spanning the staff.

## Open Questions

* None

## Follow-ons (Chained Tasks)
- None

## Risks

* Item boundary occurring exactly on a barline could be double-drawn if not deduped.

## Useful Commands and Testing

* Manual: place two MIDI items back-to-back on a selected track and play through the boundary.

## Artifacts Changed

* lib/source.lua — added item boundary lookup and next-item scan.
* luaTab.lua — stored item bounds and passed into renderer.
* lib/render.lua — rendered item boundary lines.
* lib/config.lua — added barline/item boundary thickness defaults.
* lib/midi.lua — clamped extraction to item bounds.
* .tracking/architecture.md — updated data flow and non-goals.
* planning/configuration.md — documented item boundary thickness.
* planning/examples_and_testing.md — added item boundary and gap/trim test cases.

## Final Summary

Implementation complete; manual verification in REAPER still needed.
