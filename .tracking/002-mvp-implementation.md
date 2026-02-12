# Task #002: MVP implementation

- ID: #002-mvp-implementation
- Created: 2026-02-12 00:05 UTC
- Status: in-progress
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #001-mvp-plan
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Implement the MVP described in the planning docs, following the step-by-step checklist from task #001.

## Requirements
- Implement the MVP feature set (cursor follow, timeline, layout, MIDI extraction, fret solving, rendering).
- Keep modules separated per repo layout in planning/implementation_plan.md.
- Ensure performance avoids full MIDI scans every frame.

## Acceptance Criteria
- [ ] App window renders joined tab layout and follows cursor.
- [ ] MIDI events render as frets on strings with chord support.
- [ ] Unplayable chords reduce to highest notes and show dropped notes in red.
- [ ] Time signature changes render correctly mid-system.
- [ ] MVP regression checklist passes (L02, T02, M02, F02, F04).

## Out of Scope
- V1 preloading and multi-item source modes beyond active MIDI editor take.

## Design Contracts (Do Not Break)
- Open strings do not count toward fretted span.
- Reduction policy prefers highest notes.
- Systems render as continuous joined rows (no tiles).

## Plan
- [x] Set up module stubs and main loop skeleton. Files: luaTab.lua, lib/config.lua, lib/timeline.lua, lib/layout.lua, lib/midi.lua, lib/frets.lua, lib/render.lua, lib/util.lua. Functions: module init stubs, main loop. Verification: script loads and window opens.
- [x] Implement config model + ExtState persistence + UI strip. Files: lib/config.lua, luaTab.lua. Functions: Config.load(), Config.save(), drawControls(). References: planning/configuration.md, planning/reascript_api.md. Verification: settings persist across reloads.
- [x] Build timeline bar window + time signature markers. Files: lib/timeline.lua, luaTab.lua. Functions: getCursorTime(), buildBars(). References: planning/project_bried.md, planning/implementation_plan.md, planning/reascript_api.md. Verification: T01/T02 in planning/examples_and_testing.md.
- [x] Build layout geometry and system wrapping. Files: lib/layout.lua. Functions: computeSystems(). References: planning/project_bried.md, planning/implementation_plan.md. Verification: L01-L03 in planning/examples_and_testing.md.
- [x] Implement MIDI extraction and event grouping. Files: lib/midi.lua. Functions: extractNotes(), groupEvents(). References: planning/implementation_plan.md, planning/reascript_api.md. Verification: M01-M03 in planning/examples_and_testing.md.
- [x] Implement fret candidate generation, solver, and reduction. Files: lib/frets.lua. Functions: buildCandidates(), solveChord(), reduceChord(). References: planning/implementation_plan.md, planning/project_bried.md. Verification: F01-F05 in planning/examples_and_testing.md.
- [x] Render systems, frets, and dropped notes. Files: lib/render.lua, luaTab.lua. Functions: renderSystems(), renderEvents(). References: planning/implementation_plan.md, planning/project_bried.md, planning/configuration.md. Verification: M02, F04 visual checks.
- [x] Add minimal caching to avoid per-frame rescans. Files: luaTab.lua, lib/midi.lua. Functions: cache invalidation checks. References: planning/project_bried.md. Verification: UI remains responsive during playback.
- [ ] Run MVP regression checklist. Files: planning/examples_and_testing.md. Functions: n/a. Verification: L02, T02, M02, F02, F04.

## Regression Checklist (Optional)
- [ ] L02 wrap test
- [ ] T02 mid-system time signature
- [ ] M02 double stops
- [ ] F02 open-strings-free span
- [ ] F04 reduction keeps highest notes

## Snippet Cache
<!-- Essential snippets only (<=100 lines total). Include file path + line ranges. -->

## Execution Log

* 2026-02-12 00:05 UTC Start-of-turn Context Recap:

  * Goal: start MVP implementation from the approved plan
  * Current State: planning complete; no implementation started
  * Blocking Issues: none
  * Next Subtask: set up module stubs and main loop skeleton
  * Known Risks: none
* 2026-02-12 00:15 UTC Implemented MVP modules and integrated main loop, solver, and renderer.
* 2026-02-12 00:15 UTC Verification: not run (requires REAPER session).

## Decisions

* Implementation will follow the step order in the MVP plan.

## Open Questions

* None.

## Follow-ons (Chained Tasks)
- none

## Risks

* Large surface area across modules could slow iteration. Mitigation: implement minimal stubs first.

## Useful Commands and Testing

* Manual verification in REAPER using planning/examples_and_testing.md.

## Artifacts Changed

* luaTab.lua — wired MVP loop and rendering pipeline.
* lib/config.lua — expanded config defaults and persistence.
* lib/timeline.lua — added cursor follow + bar window logic.
* lib/layout.lua — added system wrapping and bar geometry.
* lib/midi.lua — added note extraction and event grouping.
* lib/frets.lua — added solver + reduction logic.
* lib/render.lua — added draw pipeline for bars and frets.
* .tracking/002-mvp-implementation.md — updated plan progress and log.

## Final Summary

{To be completed when task is done.}
