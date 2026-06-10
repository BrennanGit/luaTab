# Task #049: Local Regression Tests

- ID: #049-local-regression-tests
- Created: 2026-04-25 UTC
- Status: done
- Type: infra
- Stability: experimental
- Owner: agent
- Related: #047, #048
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Build a Lua 5.3 regression test harness for algorithm-heavy luaTab modules so fret assignment, layout, grouping, overrides, and filters can be verified outside REAPER.

## Requirements
- Use the local `lua53/lua53.exe` binary.
- Keep tests lightweight and runnable with one command.
- Cover algorithm-heavy paths: frets, layout, grouping, override application, and filters.
- Avoid requiring REAPER or ReaImGui for pure tests.
- Document the test command and remaining REAPER-only gaps.

## Acceptance Criteria
- [x] `tests/run.lua` executes with `.\\lua53\\lua53.exe tests\\run.lua`.
- [x] Tests cover fret candidate/assignment behavior including open-string span and reduction.
- [x] Tests cover layout wrapping and MIDI event grouping.
- [x] Tests cover manual override helper and MIDI filter helper behavior.
- [x] Documentation records how to run tests.

## Plan
- [x] Add a tiny Lua assertion harness and package path setup.
  - Files: tests/run.lua
  - Functions: assert_eq(), assert_true(), test runner helpers
  - Verify: command starts and reports failures clearly.
- [x] Add tests for frets, layout, and grouping.
  - Files: tests/run.lua
  - Functions: frets.assign_event(), layout.build_systems(), midi.group_events()
  - Verify: tests pass under Lua 5.3.
- [x] Add tests for overrides and MIDI filters introduced by #047/#048.
  - Files: tests/run.lua, lib/overrides.lua, lib/midi.lua
  - Functions: overrides.apply_event_overrides(), midi.note_passes_filters()
  - Verify: tests pass under Lua 5.3.
- [x] Update docs and tracking metadata.
  - Files: planning/examples_and_testing.md, README.md, .tracking/meta.md
  - Verify: command and gaps are accurate.

## Execution Log

* 2026-04-25 UTC Start-of-turn Context Recap:
  * Goal: expand the new local Lua 5.3 test harness so algorithm-heavy modules have meaningful regression coverage.
  * Current State: `tests/run.lua` exists with manual override and MIDI filter tests; frets/layout/grouping still need coverage.
  * Blocking Issues: none for pure tests; REAPER API behavior remains outside this harness.
  * Next Subtask: add frets, layout, and grouping regression tests.
  * Known Risks: modules touching global `reaper` must only be tested through pure functions or with stubs.

* 2026-04-25 UTC Expanded `tests/run.lua` with fret solver tests for open-string preference, open-string-free span handling, and high-note-preserving reduction; added layout wrapping and MIDI grouping tests.

* 2026-04-25 UTC Updated README and examples/testing docs with the local Lua 5.3 test command and REAPER-only validation gaps.

* 2026-04-25 UTC Verification:
  * `.\\lua53\\lua53.exe tests\\run.lua` passed with 11 tests.
  * Editor diagnostics reported no errors in `tests/run.lua`, `lib/midi.lua`, `lib/frets.lua`, or `lib/layout.lua`.

## Decisions
- Keep this as a pure Lua harness rather than a REAPER integration test runner.

## Open Questions

## Risks
- Modules that reference global `reaper` at require-time may need guards or stubs.

## Useful Commands and Testing
- `.\\lua53\\lua53.exe tests\\run.lua`

## Artifacts Changed
- tests/run.lua
- README.md
- planning/examples_and_testing.md
- .tracking/049-local-regression-tests.md

## Final Summary
Local regression testing is now available through `tests/run.lua` and the bundled Lua 5.3 binary. Coverage includes manual overrides, MIDI filters, fret assignment, open-string span behavior, high-note-preserving reduction, layout wrapping, and MIDI grouping. REAPER validation remains required for API-bound extraction and UI behavior.
