# Task #050: Diagnostics and Readability Polish

- ID: #050-diagnostics-readability
- Created: 2026-04-25 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #047, #048, #049
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Improve professional usability by making source/filter state, dropped notes, and playback/readability diagnostics visible without digging into logs.

## Requirements
- Add a compact diagnostics/status surface for source, bars, events, assigned notes, dropped notes, and filters.
- Make dropped-note labels more readable than raw MIDI pitch numbers where possible.
- Preserve current status bar behavior and avoid visual clutter by default.
- Keep diagnostics cheap enough for the render loop.

## Acceptance Criteria
- [x] A diagnostics panel or status section exposes useful runtime state.
- [x] Dropped notes can render as note names or clearer labels.
- [x] Runtime state is updated during rebuild without full per-frame rescans.
- [x] Lua 5.3 tests cover pure note-name formatting if added.
- [x] Documentation mentions diagnostics and remaining REAPER validation gaps.

## Plan
- [x] Add runtime stats collection during rebuild/assignment.
  - Files: luaTab.lua
  - Functions: rebuild_data(), apply_fret_assignments()
  - Verify: syntax check and manual code review.
- [x] Add diagnostics panel and menu toggle.
  - Files: luaTab.lua
  - Functions: draw_diagnostics_panel(), draw_ui()
  - Verify: syntax check; REAPER UI validation required.
- [x] Improve dropped-note labeling through a pure formatter.
  - Files: lib/midi.lua or lib/render.lua, tests/run.lua
  - Functions: midi.pitch_name(), render.draw_systems()
  - Verify: Lua 5.3 tests for pitch naming.
- [x] Update docs and tracking metadata.
  - Files: README.md, .tracking/architecture.md, .tracking/meta.md
  - Verify: docs match implemented UI.

## Execution Log

* 2026-04-25 UTC Start-of-turn Context Recap:
  * Goal: add a hidden-by-default diagnostics/readability surface and clearer dropped-note labeling after completing manual overrides, source filters, and local tests.
  * Current State: status bar only shows a simple bar/source state; dropped notes render as raw MIDI numbers; rebuild has enough information to collect event/assignment/drop stats cheaply.
  * Blocking Issues: ReaImGui panel validation requires REAPER; pitch-name formatting can be tested locally.
  * Next Subtask: add pure pitch-name formatting and use it for dropped-note labels.
  * Known Risks: diagnostics should remain cheap and unobtrusive in continuous mode.

* 2026-04-25 UTC Added `midi.pitch_name()` and updated dropped-note rendering to show note names instead of raw MIDI pitch numbers.

* 2026-04-25 UTC Added rebuild-time diagnostics counters for source/mode/filter state, visible bars/items, note/event counts, assigned/dropped notes, manual overrides, and visible window range.

* 2026-04-25 UTC Added a hidden-by-default Diagnostics panel to the panels menu, with layout persistence support via existing panel layout capture keys.

* 2026-04-25 UTC Updated README and architecture notes for diagnostics behavior.

* 2026-04-25 UTC Verification:
  * `.\\lua53\\lua53.exe tests\\run.lua` passed with 12 tests, including pitch-name formatting.
  * Editor diagnostics reported no errors in `luaTab.lua`, `lib/midi.lua`, `lib/render.lua`, or `tests/run.lua`.
  * REAPER validation remains required for the Diagnostics panel UI and dropped-note rendering in the actual ReaImGui draw list.

## Decisions
- Diagnostics should be hidden unless enabled from the panel menu to keep the core tab view clean.

## Open Questions

## Risks
- Extra status detail should not become noisy or slow in continuous mode.

## Useful Commands and Testing
- `.\\lua53\\lua53.exe tests\\run.lua`

## Artifacts Changed
- luaTab.lua
- lib/midi.lua
- lib/render.lua
- tests/run.lua
- README.md
- .tracking/architecture.md
- .tracking/050-diagnostics-readability.md

## Final Summary
Diagnostics/readability polish is implemented. Dropped notes now render as scientific pitch names, rebuilds collect cheap runtime counters, and a hidden-by-default Diagnostics panel exposes source/filter state plus bars/items/notes/events/assignments/drops/override counts. Local Lua 5.3 coverage now includes pitch-name formatting; REAPER remains required for UI/render validation.
