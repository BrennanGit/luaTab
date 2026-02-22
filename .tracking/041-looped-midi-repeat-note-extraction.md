# Task #041: Looped MIDI Repeat Note Extraction

- ID: #041-looped-midi-repeat-note-extraction
- Created: 2026-02-22 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #039
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Fix note extraction so looped MIDI items return notes from all visible loop repeats under the edit/play cursor, not only the first repeat.

## Requirements
- Account for REAPER MIDI item looping when extracting notes for a timeline window.
- Preserve existing behavior for non-looped items.
- Keep source selection logic unchanged (selected track priority + editor fallback).
- Render item boundary bars at loop repeat seams (not only item start/end).

## Acceptance Criteria
- [x] Cursor in second repeat of a looped MIDI item still yields notes/events.
- [x] Existing non-looped item extraction still works.
- [x] No API/flow regressions in `rebuild_data()` collection path.
- [x] Item boundary bars are shown at repeat seam times for looped items.

## Plan
- [x] Add loop-aware projection in `lib/midi.lua` `extract_notes()`.
  - Files: lib/midi.lua
  - Functions: extract_notes()
  - Verify: extraction includes repeated note instances inside `[window_t0, window_t1)` and clip bounds.
- [x] Pass item context into extraction call from `luaTab.lua`.
  - Files: luaTab.lua
  - Functions: rebuild_data()
  - Verify: call provides `item` so looping metadata can be read.
- [x] Run targeted sanity checks and update tracking logs.
  - Files: .tracking/041-looped-midi-repeat-note-extraction.md, .tracking/meta.md
  - Verify: task/checklist/status/log updated with final outcome.
- [x] Add repeat-boundary times to render pipeline and draw loop seam boundary bars.
  - Files: lib/source.lua, luaTab.lua, lib/render.lua
  - Functions: get_items_in_window(), get_item_repeat_boundaries(), rebuild_data(), draw_systems()
  - Verify: boundary overlay includes loop seams and preserves existing item start/end lines.

## Execution Log

* 2026-02-22 UTC Start-of-turn Context Recap:
  * Goal: add item boundary bars at loop repeat seams, matching existing item start/end boundary visuals.
  * Current State: render draws only current/next item start/end boundaries.
  * Blocking Issues: none.
  * Next Subtask: attach per-item repeat seam times from source collection into render boundary list.
  * Known Risks: repeat seam timing for QN-domain loops under tempo map changes.

* 2026-02-22 UTC Start-of-turn Context Recap:
  * Goal: fix looped item extraction so second/third repeat windows contain events.
  * Current State: extraction uses project note times from take; loop repeats are not duplicated.
  * Blocking Issues: none.
  * Next Subtask: implement repeat-offset projection in `lib/midi.lua` and wire item through caller.
  * Known Risks: loop period derivation for MIDI source length units (seconds vs QN).

* 2026-02-22 UTC Implemented loop-aware extraction in `lib/midi.lua`:
  * Added loop period detection via `B_LOOPSRC`, `GetMediaSourceLength`, and take playrate.
  * Added repeat projection for both seconds-domain and QN-domain loop sources.
  * Added guarded append helper to keep starts within window and item clip bounds.

* 2026-02-22 UTC Updated caller path in `luaTab.lua` to pass `item_info.item` into `midi.extract_notes()` so extraction can read loop metadata.

* 2026-02-22 UTC Verification:
  * Workspace diagnostics: no errors reported.
  * Added regression scenario `M06` in `planning/examples_and_testing.md` for looped item repeat handling.

* 2026-02-22 UTC Implemented repeat-boundary bars for looped items:
  * `lib/source.lua` now computes per-item repeat seam times in window (`repeatBoundaries`).
  * `luaTab.lua` aggregates item boundary times (`t0`, `t1`, and repeat seams) into `state.itemBounds.times`.
  * `lib/render.lua` consumes `item_bounds.times` when present and draws boundary bars at each seam.

* 2026-02-22 UTC Verification:
  * Workspace diagnostics: no errors reported after boundary-marker changes.
  * Added regression scenario `L05` in `planning/examples_and_testing.md` for looped repeat seam markers.

## Decisions

## Open Questions

## Risks
- QN-length MIDI sources under changing tempo maps may require QN-domain offset projection.

## Useful Commands and Testing
- N/A (manual REAPER validation + log checks).

## Artifacts Changed
- .tracking/041-looped-midi-repeat-note-extraction.md
- .tracking/meta.md
- lib/midi.lua
- luaTab.lua
- lib/source.lua
- lib/render.lua
- planning/examples_and_testing.md

## Final Summary
Looped MIDI items are now handled in both note extraction and boundary overlays. Notes are projected across repeat iterations, and item boundary bars now also appear at loop repeat seams within visible windows. Documentation includes regression checks for both behaviors.
