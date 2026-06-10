# Task #051: Drag String Overrides

- ID: #051-drag-string-overrides
- Created: 2026-04-25 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #047, #049, #050
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Replace the first manual override UI/data model with a more musical drag-to-string system: an override stores only the forced string for a pitch/event, and the fret is derived from pitch minus open-string tuning.

## Requirements
- Remove the Manual Overrides panel and its string/fret editing flow.
- Store overrides as event-time/pitch -> string id only.
- Apply overrides through the assignment path so the same pitch moves to another valid string with a derived fret.
- Add direct tab interaction: click/drag an assigned note vertically to another valid string and save immediately on release.
- Add a single Settings -> Tab button to clear all overrides.
- Preserve tests and update them to assert the string-only model.

## Acceptance Criteria
- [x] Override helper accepts only string ids and derives fret from pitch/tuning.
- [x] Invalid string choices are skipped, not transformed into arbitrary pitches.
- [x] Manual Overrides panel/state/menu item is removed.
- [x] Drag-to-string interaction saves overrides while dragging/rebuilds immediately.
- [x] Settings -> Tab contains a clear-all-overrides button.
- [x] Lua 5.3 tests pass and cover string-only override behavior.

## Plan
- [x] Rewrite `lib/overrides.lua` around string-only overrides.
  - Files: lib/overrides.lua, tests/run.lua
  - Functions: overrides.make_key(), overrides.apply_event_overrides()
  - Verify: Lua 5.3 tests for derived fret, invalid string rejection, collision behavior.
- [x] Replace persistence shape and remove panel plumbing.
  - Files: luaTab.lua, lib/config.lua
  - Functions: load_manual_overrides(), save_manual_overrides(), reset_config_to_defaults(), draw_manual_overrides_panel()
  - Verify: no remaining panel/menu/dock layout references; reset clears old and new keys.
- [x] Add note drag hit-testing and drop handling in the main tab window.
  - Files: luaTab.lua
  - Functions: draw_ui(), handle_note_override_drag()
  - Verify: diagnostics/syntax checks; REAPER manual validation required.
- [x] Update docs/tracking.
  - Files: README.md, .tracking/architecture.md, .tracking/meta.md, .tracking/051-drag-string-overrides.md
  - Verify: docs reflect drag UI and string-only model.

## Execution Log

* 2026-04-25 UTC Start-of-turn Context Recap:
  * Goal: replace the first manual override implementation with a drag-to-string, string-id-only override system.
  * Current State: #047 added a separate Manual Overrides panel with editable string/fret values; user reports it is not friendly, not live enough, and allows semantically wrong arbitrary replacement.
  * Blocking Issues: actual drag/drop interaction requires REAPER/ReaImGui validation; pure override model can be tested locally.
  * Next Subtask: rewrite override helper and tests around derived fret behavior.
  * Known Risks: hit-testing must account for continuous draw offset and existing bar-click seek handling.

* 2026-04-25 UTC Rewrote `lib/overrides.lua` so saved entries only force a string id. The helper now derives fret validity from pitch/tuning and passes `event.forcedStringsByPitch` into assignment.

* 2026-04-25 UTC Updated `lib/frets.lua` so forced strings filter candidate generation and valid forced pitches stay included during reduction whenever possible.

* 2026-04-25 UTC Removed Manual Overrides panel/menu/layout state and changed ExtState persistence to write only `.key` and `.string`, deleting legacy `.fret` keys.

* 2026-04-25 UTC Added tab-note hit testing and drag handling in `luaTab.lua`. Dragging an assigned fret number vertically saves a valid target string immediately and rebuilds the tab.

* 2026-04-25 UTC Added Settings -> Tab -> Clear string overrides and updated README/architecture notes for the string-only override model.

* 2026-04-25 UTC Verification:
  * `.\\lua53\\lua53.exe tests\\run.lua` passed with 12 tests.
  * `.\\lua53\\lua53.exe -e "assert(loadfile('lib/frets.lua')); assert(loadfile('lib/overrides.lua')); assert(loadfile('luaTab.lua')); assert(loadfile('tests/run.lua'))"` passed.
  * Editor diagnostics reported no errors in `luaTab.lua`, `lib/frets.lua`, `lib/overrides.lua`, or `tests/run.lua`.

* 2026-04-25 UTC Follow-up Context Recap:
  * Goal: stop note dragging from also moving the main window or triggering bar seek.
  * Current State: note dragging is driven by manual mouse hit testing after draw, so the initial click is still seen as a background window click.
  * Blocking Issues: none; this is isolated to ImGui interaction ownership.
  * Next Subtask: convert note hit regions into ImGui items so note clicks are captured before generic window behaviors.
  * Known Risks: invisible item placement must match drawn note bounds closely enough not to make notes hard to pick.

* 2026-04-25 UTC Replaced the note drag start path with invisible ImGui hit regions placed over each rendered fret number. Note clicks are now captured as real items before generic window/background handling.

* 2026-04-25 UTC Disabled main-window movement while a note drag is active so rebuilds during drag do not let the window start sliding under the cursor.

* 2026-04-25 UTC Fixed a follow-up regression where note clicks correctly blocked secondary effects but also swallowed the actual drag update. Note hit regions now start the drag only on the press frame, and held frames continue into the string-move logic.

* 2026-04-25 UTC Follow-up Verification:
  * `.\\lua53\\lua53.exe tests\\run.lua` passed with 12 tests.
  * `.\\lua53\\lua53.exe -e "assert(loadfile('lib/frets.lua')); assert(loadfile('lib/overrides.lua')); assert(loadfile('luaTab.lua')); assert(loadfile('tests/run.lua'))"` passed.
  * Editor diagnostics reported no errors in `luaTab.lua`.

## Decisions
- Keep event-time/pitch keys for now, but store only `{ string = N }` per key.
- Save overrides immediately on mouse release after a valid drag.

## Open Questions

## Risks
- Existing saved string/fret overrides may become invalid; loader will ignore old entries without a valid string and save the new shape going forward.

## Useful Commands and Testing
- `.\\lua53\\lua53.exe tests\\run.lua`

## Artifacts Changed
- lib/overrides.lua
- lib/frets.lua
- luaTab.lua
- tests/run.lua
- README.md
- .tracking/architecture.md
- .tracking/051-drag-string-overrides.md
- .tracking/meta.md

## Final Summary
The old manual string/fret override editor has been replaced with direct drag-to-string overrides. Overrides now store only a string id, the solver derives frets from pitch and tuning, invalid target strings are skipped, and note clicks are captured as item interactions so dragging a note no longer also moves the window or triggers bar seek while still preserving the actual string-move behavior. REAPER remains required to validate the exact ReaImGui drag feel.
