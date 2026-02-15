# Task #001: MVP Implementation Plan

- ID: #001-mvp-implementation
- Created: 2026-02-15 00:00 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: none
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Implement the MVP for the REAPER luaTab tool based on the planning docs and confirmed display decisions.

## Requirements
- Follow play cursor, or edit cursor when stopped if enabled.
- Display joined, wrapped tab across systems with bar prefix gutters.
- Support chords/double stops with fret assignment, span constraints, and reduction.

## Acceptance Criteria
- [x] Follows play/edit cursor and updates by bar.
- [x] Joined tab layout wraps cleanly with barlines and time signatures.
- [x] Chords map to unique strings when possible; reduction keeps highest notes.
- [x] Span constraint treats open strings as free.
- [x] Dropped notes render in red.

## Out of Scope
- Preloading next items (v1 extension)
- Tie/hold markers
- Export or alternate fingerings

## Design Contracts (Do Not Break) (Optional)
- Time signature changes render in prefix region unless first bar in system uses gutter.
- Open strings do not contribute to fretted span.

## Plan
- [x] Record confirmed display decisions in planning docs — Files: planning/project_brief.md — Functions: n/a — Verification: manual review
- [x] Scaffold module files and config persistence — Files: luaTab.lua, lib/config.lua — Functions: config.load(), config.save() — Verification: run script, confirm load/save
- [x] Implement cursor + timeline window calculation — Files: lib/timeline.lua, luaTab.lua — Functions: timeline.build_bars(), timeline.get_measure_index() — Verification: debug overlay shows correct measure index
- [x] Implement layout and base rendering (strings + barlines) — Files: lib/layout.lua, lib/render.lua — Functions: layout.build_systems(), render.draw_systems() — Verification: L02 resize test
- [x] Implement MIDI extraction + event grouping — Files: lib/midi.lua — Functions: midi.extract_notes(), midi.group_events() — Verification: M01/M02 tests
- [x] Implement fret mapping + chord solver + reduction — Files: lib/frets.lua — Functions: frets.assign_event() — Verification: F02/F04 tests
- [x] Render frets, time signatures, dropped notes — Files: lib/render.lua — Functions: render.draw_systems() — Verification: T02 + dropped notes visible
- [x] Add no-MIDI fallback message and logging — Files: luaTab.lua, lib/midi.lua, planning/project_brief.md, planning/implementation_plan.md, planning/examples_and_testing.md — Functions: midi.get_active_take() — Verification: M00 test
- [x] Prefer selected track MIDI item source — Files: lib/source.lua, luaTab.lua, planning/project_brief.md, planning/implementation_plan.md, planning/examples_and_testing.md, .tracking/architecture.md — Functions: source.get_take() — Verification: M01a test
- [x] Add update mode controls — Files: luaTab.lua, lib/config.lua, lib/layout.lua, planning/project_brief.md, planning/implementation_plan.md, planning/examples_and_testing.md — Functions: layout.calc_bars_per_system(), config.load(), config.save() — Verification: U01/U02 tests
- [x] Add antidelay and continuous sweep — Files: luaTab.lua, lib/config.lua, planning/project_brief.md, planning/implementation_plan.md, planning/examples_and_testing.md — Functions: compute_virtual_bar(), compute_sweep_offset_px() — Verification: U03 test
- [ ] MVP regression pass — Files: tests/tests.lua, planning/examples_and_testing.md — Functions: n/a — Verification: L02, T02, M02, F02, F04
- [ ] Tests/Verification — Manual regression against examples

## Regression Checklist (Optional)
- [ ] Time signature change renders in bar prefix (mid-system)
- [ ] Open strings do not affect span

## Snippet Cache
<!-- Essential snippets only (<=100 lines total). Include file path + line ranges. -->

## Execution Log

* 2026-02-15 00:00 UTC Start-of-turn Context Recap:

  * Goal: Create MVP implementation task and record confirmed display decisions
  * Current State: No active tasks; planning docs define MVP; clarifications received
  * Blocking Issues: None
  * Next Subtask: Record confirmed display decisions in planning docs
  * Known Risks: None

* 2026-02-15 00:05 UTC Updated planning/project_brief.md to capture confirmed display decisions.
* 2026-02-15 00:05 UTC Verification: Manual review of planning/project_brief.md.

* 2026-02-15 00:10 UTC Start-of-turn Context Recap:

  * Goal: Implement MVP modules and main script until task completion
  * Current State: Task in progress; no module files yet; planning docs define scope
  * Blocking Issues: None
  * Next Subtask: Scaffold module files and config persistence
  * Known Risks: ReaImGui availability; REAPER API differences

* 2026-02-15 00:35 UTC Added core modules and main script (luaTab.lua, lib/*.lua) with config persistence, timeline, layout, MIDI extraction, fret solver, and renderer.
* 2026-02-15 00:35 UTC Added tests/tests.lua with layout and fretting tests.
* 2026-02-15 00:35 UTC Updated architecture notes to reflect current module structure.
* 2026-02-15 00:35 UTC Verification: Not run (requires REAPER session for UI/timeline and MIDI tests).
* 2026-02-15 00:40 UTC Status set to blocked pending manual REAPER regression checks.
* 2026-02-15 00:45 UTC Fixed ImGui_GetCurrentContext crash by passing font size from luaTab.lua into render.draw_systems().
* 2026-02-15 00:50 UTC Added file logging with enable/verbose toggles and debug messages across timeline, MIDI, and main loop.
* 2026-02-15 00:55 UTC Added no-MIDI fallback message and updated planning docs and tests.
* 2026-02-15 00:55 UTC Status set to blocked pending manual REAPER regression checks.
* 2026-02-15 01:00 UTC Throttled logging and set initial window size/position to ensure visibility.
* 2026-02-15 01:05 UTC Added selected track item source with MIDI editor fallback and updated planning docs.
* 2026-02-15 01:06 UTC Added window size constraints to avoid tiny window.
* 2026-02-15 01:15 UTC Added update mode config and input fields for prev/next bars.
* 2026-02-15 01:25 UTC Added antidelay beats and continuous sweep offset for update mode.
* 2026-02-15 01:35 UTC Added current-bar marker, note background blocks, and emphasized time signatures.
* 2026-02-15 01:40 UTC User confirmed MVP looks good; task marked done.

## Decisions

* String 1 renders at bottom of staff — Confirmed by user.
* Fret numbers centered on string line — Confirmed by user.
* Open strings render as normal frets — Confirmed by user.

## Open Questions

* None

## Follow-ons (Chained Tasks)
- None

## Risks

* None

## Useful Commands and Testing

* None

## Artifacts Changed

* planning/project_brief.md — Recorded confirmed display decisions.
* luaTab.lua — Main script and UI loop.
* lib/config.lua — Defaults and ExtState persistence.
* lib/timeline.lua — Bar window and measure index helpers.
* lib/layout.lua — System layout and wrapping.
* lib/midi.lua — Active take and event grouping.
* lib/frets.lua — Candidate solver and reduction.
* lib/render.lua — Draw strings, barlines, time signatures, and frets.
* lib/util.lua — Helpers.
* tests/tests.lua — Pure logic tests.
* .tracking/architecture.md — Project architecture notes.

## Final Summary

MVP delivered and accepted by user. Manual regression checks not run by agent.
