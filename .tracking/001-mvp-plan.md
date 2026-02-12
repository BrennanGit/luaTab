# Task #001: MVP plan and guidance

- ID: #001-mvp-plan
- Created: 2026-02-12 00:00 UTC
- Status: done
- Type: docs
- Stability: stable
- Owner: agent
- Related: none
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Create a step-by-step MVP implementation plan that links each step to the planning sources so an agent can follow it without guessing.

## Requirements
- Provide an ordered MVP plan with file/function targets and verification steps.
- Link each step to the planning sources that define it.
- Update the active task stack in .tracking/meta.md.

## Acceptance Criteria
- [x] MVP plan is a checklist with clear file targets and verification steps.
- [x] Each plan step includes links to the source planning docs.
- [x] .tracking/meta.md lists this task and sets it as the active task.

## Out of Scope
- Implementing code changes for the MVP itself.

## Plan
- [ ] Confirm MVP scope and core behaviors from the brief and implementation plan; list any assumptions to validate. Files: planning/project_bried.md, planning/implementation_plan.md. Functions: n/a. Verification: cross-check MVP criteria and core behaviors align across sources.
- [ ] Scaffold MVP modules and main loop structure per repo layout. Files: luaTab.lua, lib/config.lua, lib/timeline.lua, lib/layout.lua, lib/midi.lua, lib/frets.lua, lib/render.lua, lib/util.lua. Functions: module init stubs. Verification: script loads without errors and window opens.
- [ ] Implement config model + persistence (ExtState) and UI controls. Files: lib/config.lua, luaTab.lua. Functions: Config load/save, UI bindings. References: planning/configuration.md, planning/reascript_api.md. Verification: toggles and sliders persist across reloads.
- [ ] Implement cursor follow + bar window timeline with time signatures. Files: lib/timeline.lua, luaTab.lua. Functions: getCursorTime(), buildBars(). References: planning/project_bried.md, planning/implementation_plan.md, planning/reascript_api.md. Verification: T01/T02 from planning/examples_and_testing.md.
- [ ] Implement layout wrapping and system geometry. Files: lib/layout.lua. Functions: computeSystems(). References: planning/project_bried.md, planning/implementation_plan.md. Verification: L01-L03 from planning/examples_and_testing.md.
- [ ] Implement MIDI extraction + event grouping for active MIDI editor take. Files: lib/midi.lua. Functions: extractNotes(), groupEvents(). References: planning/implementation_plan.md, planning/reascript_api.md. Verification: M01-M03 from planning/examples_and_testing.md.
- [ ] Implement fret candidate generation, solver, and reduction with open-strings-free span rule. Files: lib/frets.lua. Functions: buildCandidates(), solveChord(), reduceChord(). References: planning/implementation_plan.md, planning/project_bried.md. Verification: F01-F05 from planning/examples_and_testing.md.
- [ ] Integrate solver output into render pipeline; draw frets and dropped notes. Files: lib/render.lua, luaTab.lua. Functions: renderSystems(), renderEvents(). References: planning/implementation_plan.md, planning/project_bried.md, planning/configuration.md. Verification: M02, F04, and visual checks for dropped notes in red.
- [ ] Add minimal caching to avoid full MIDI scans each frame. Files: luaTab.lua, lib/midi.lua. Functions: cache invalidation checks. References: planning/project_bried.md, planning/implementation_plan.md. Verification: UI responsiveness during playback.
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

* 2026-02-12 00:00 UTC Start-of-turn Context Recap:

  * Goal: create an MVP plan and link to planning sources
  * Current State: no active tasks; planning docs exist under planning/
  * Blocking Issues: none
  * Next Subtask: draft the step-by-step MVP plan
  * Known Risks: missing links to source planning docs
* 2026-02-12 00:00 UTC Created MVP plan task and documented step-by-step checklist with references.
* 2026-02-12 00:00 UTC Verification: manual check that plan steps reference planning docs and meta will be updated.
* 2026-02-12 00:05 UTC Start-of-turn Context Recap:

  * Goal: transition from planning to MVP implementation work
  * Current State: MVP plan captured; task remains on stack
  * Blocking Issues: none
  * Next Subtask: mark plan task complete and start implementation task
  * Known Risks: none
* 2026-02-12 00:05 UTC Marked MVP plan task complete in tracking and prepared to start implementation task.

## Decisions

* Treat this as a docs task to capture the MVP plan before implementation.

## Open Questions

* None.

## Follow-ons (Chained Tasks)
- none

## Risks

* Plan could drift if planning docs change. Mitigation: update this task when sources change.

## Useful Commands and Testing

* Manual verification in REAPER using the test cases in planning/examples_and_testing.md.

## Artifacts Changed

* .tracking/001-mvp-plan.md — created MVP plan and references.

## Final Summary

MVP plan captured with references to the planning sources and verification steps; task closed to begin implementation.
