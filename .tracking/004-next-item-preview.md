# Task #004: Next Item Preview + Item Barlines

- ID: #004-next-item-preview
- Created: 2026-02-15 02:30 UTC
- Status: done
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
- [x] When an item boundary falls within the visible bar window, a thicker line is drawn at that time.
- [x] If a new MIDI item starts after the current one, its start line appears before the cursor reaches it.
- [x] Behavior remains unchanged when no MIDI item is available (message still shown).

## Out of Scope
- Preloading or merging MIDI content from the next item.
- Overlap handling for multiple simultaneous items.

## Plan
- [x] Add item boundary lookup (current + next) — Files: lib/source.lua, luaTab.lua — Functions: source.get_take(), rebuild_data() — Verification: manual REAPER playback across item boundary
- [x] Render thick item boundary lines — Files: lib/render.lua, lib/config.lua — Functions: render.draw_systems() — Verification: manual visual check with two adjacent MIDI items
- [x] Clamp events to item bounds — Files: lib/midi.lua, luaTab.lua — Functions: midi.extract_notes(), rebuild_data() — Verification: trim item start/end and confirm notes outside item are hidden
- [x] Allow preview of upcoming item when cursor is before it — Files: lib/source.lua, luaTab.lua — Functions: source.get_take(), rebuild_data() — Verification: place cursor in gap before item and confirm empty bars until item start
- [x] Extend bar window to include next item boundary — Files: luaTab.lua — Functions: rebuild_data() — Verification: keep cursor on current item and ensure next item boundary appears
- [x] Update docs/tracking — Files: .tracking/meta.md, .tracking/004-next-item-preview.md, .tracking/architecture.md, planning/examples_and_testing.md — Functions: n/a — Verification: file review

## Execution Log

* 2026-02-15 06:20 UTC Start-of-turn Context Recap:

  * Goal: Ensure next item boundary is visible even when cursor is still on the current item
  * Current State: Next boundary appears only after leaving the current item (window ends too soon)
  * Blocking Issues: None
  * Next Subtask: Extend the bar window to include the next item boundary when it is beyond nextBars
  * Known Risks: Expanding the window could increase per-update work in large gaps

* 2026-02-15 06:26 UTC Extended rebuild_data to widen the bar window when the next item boundary falls beyond the current range.

* 2026-02-15 06:34 UTC Start-of-turn Context Recap:

  * Goal: Show notes from all MIDI items inside the visible bar window
  * Current State: Notes are clipped to the current item, so upcoming items are not visible
  * Blocking Issues: None
  * Next Subtask: Gather all MIDI items in the bar window and extract notes across them
  * Known Risks: Multiple items on the track could increase per-update work

* 2026-02-15 06:41 UTC Added multi-item note extraction within the bar window to show all notes across chopped items.

* 2026-02-15 07:12 UTC Marked task complete after user confirmation.

* 2026-02-15 06:10 UTC Start-of-turn Context Recap:

  * Goal: Fix next item preview visibility when cursor is on an item
  * Current State: Item boundaries render, but next item line is missing while cursor sits on current item
  * Blocking Issues: None
  * Next Subtask: Inspect next-item lookup timing and adjust selection logic
  * Known Risks: Changing lookup time may surface overlapping-item boundaries

* 2026-02-15 06:14 UTC Adjusted next-item lookup to use cursor time when the cursor sits on an item.

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

* 2026-02-15 04:25 UTC Start-of-turn Context Recap:

  * Goal: Address settings popup sizing/crash regression without derailing current task stack.
  * Current State: Settings popup is narrow; Styling section crashes; toggle can get stuck on crash.
  * Blocking Issues: None.
  * Next Subtask: Push a small bugfix task to harden Settings UI and stale toggle recovery.
  * Known Risks: ReaImGui color edit compatibility differences.

* 2026-02-15 04:40 UTC Start-of-turn Context Recap:

  * Goal: Refine Settings UI layout (playback/general split), add log path configuration, and improve color/font controls.
  * Current State: Prev/next bars in General, log path fixed, color edits are raw RGBA sliders, fonts not configurable.
  * Blocking Issues: None.
  * Next Subtask: Push a settings refinement task with config + UI updates.
  * Known Risks: Font customization depends on ReaImGui support.

* 2026-02-15 05:10 UTC Start-of-turn Context Recap:

  * Goal: Add background color control and improve color UI with previews.
  * Current State: Colors are hex inputs only; no background color entry; no preview swatch.
  * Blocking Issues: None.
  * Next Subtask: Push a small UI refinement task for color swatches and background color.
  * Known Risks: ReaImGui color button argument mismatch.

* 2026-02-15 05:30 UTC Start-of-turn Context Recap:

  * Goal: Fix font scaling so fret and time signature text actually renders larger.
  * Current State: Scale only affects spacing; draw text size unchanged.
  * Blocking Issues: None.
  * Next Subtask: Use ImGui_DrawList_AddTextEx with explicit font size.
  * Known Risks: ReaImGui version compatibility (requires 6.24+).

* 2026-02-15 05:48 UTC Start-of-turn Context Recap:

  * Goal: Add light/dark color presets in Settings.
  * Current State: Colors are per-field hex inputs only.
  * Blocking Issues: None.
  * Next Subtask: Push a small task to add color presets + persistence.
  * Known Risks: Need to sync hex buffers after preset changes.

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

Item boundaries and multi-item window rendering are complete and verified in REAPER.
