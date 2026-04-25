# Task #047: Manual Fret Overrides

- ID: #047-manual-fret-overrides
- Created: 2026-04-25 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #046
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add a first practical manual override path for computed fret assignments so users can correct automatic string/fret choices and keep those corrections across rebuilds.

## Requirements
- Preserve automatic fret assignment as the default behavior.
- Allow user-entered overrides keyed by item/time/pitch where feasible.
- Apply overrides during assignment without breaking dropped-note handling.
- Persist overrides in ExtState so they survive script restart.
- Keep UI minimal and consistent with the existing ReaImGui panels.

## Acceptance Criteria
- [x] Override persistence load/save/reset path exists and is documented.
- [x] Manual overrides are applied after automatic assignment and maintain one-note-per-string constraints.
- [x] A user-facing panel/action can add and remove overrides for visible events.
- [x] Lua 5.3 tests cover override application logic where it is pure/offline-testable.
- [x] REAPER-only validation gaps are documented.

## Plan
- [x] Add a pure override helper module.
  - Files: lib/overrides.lua
  - Functions: overrides.make_key(), overrides.apply_event_overrides()
  - Verify: Lua 5.3 unit tests for replacement, invalid fret/string rejection, and string collision handling.
- [x] Wire override persistence and assignment application into rebuild flow.
  - Files: luaTab.lua
  - Functions: load_manual_overrides(), save_manual_overrides(), apply_fret_assignments()
  - Verify: Lua syntax check and code review against event assignment invariants.
- [x] Add a compact Manual Overrides panel for current visible assigned notes.
  - Files: luaTab.lua
  - Functions: draw_manual_overrides_panel(), draw_ui()
  - Verify: syntax check; manual REAPER validation required for UI interaction.
- [x] Update docs and tracking metadata.
  - Files: README.md, .tracking/architecture.md, .tracking/meta.md
  - Verify: references match implemented behavior.

## Execution Log

* 2026-04-25 UTC Start-of-turn Context Recap:
  * Goal: implement the first requested improvement, manual fret overrides, while queued tasks cover source filters, local tests, and diagnostics.
  * Current State: active stack was empty; automatic assignment is centralized in `apply_fret_assignments()` and `lib/frets.lua`; README notes manual overrides are missing.
  * Blocking Issues: full UI validation requires REAPER/ReaImGui.
  * Next Subtask: add a pure override helper module with Lua 5.3 tests.
  * Known Risks: override keys may need to be robust enough across repeated/looped items without overcomplicating the first pass.

* 2026-04-25 UTC Added `lib/overrides.lua` with rounded event-time/pitch keys and pure override application that can replace automatic assignments, skip invalid string/fret choices, and drop displaced assignments on string collision.

* 2026-04-25 UTC Added initial `tests/run.lua` using the local Lua 5.3 binary path and override tests for replacement, collision handling, and invalid override rejection.

* 2026-04-25 UTC Wired manual overrides into `luaTab.lua` ExtState persistence, rebuild assignment application, panel state, panel layout capture, and a Manual Overrides panel available from the panels menu.

* 2026-04-25 UTC Updated README and architecture notes for manual override behavior and invariants.

* 2026-04-25 UTC Verification:
  * `.\\lua53\\lua53.exe tests\\run.lua` passed with 3 override tests.
  * Editor diagnostics reported no errors in `luaTab.lua`, `lib/config.lua`, `lib/overrides.lua`, or `tests/run.lua`.
  * REAPER/ReaImGui manual validation is still required for panel interaction and ExtState persistence in host.

## Decisions
- Use a conservative first version keyed by rounded event time and pitch, with optional item identity added later if REAPER pointer persistence proves stable enough.

## Open Questions

## Risks
- User-entered overrides can conflict with other notes in a chord; first implementation should skip conflicting overrides rather than create impossible assignments.
- Override keys are rounded event-time/pitch pairs; they are practical for the first UI pass but may need item/take identity if identical repeated phrases require distinct corrections.

## Useful Commands and Testing
- `.\\lua53\\lua53.exe tests\\run.lua`

## Artifacts Changed
- lib/overrides.lua
- tests/run.lua
- luaTab.lua
- lib/config.lua
- README.md
- .tracking/architecture.md
- .tracking/047-manual-fret-overrides.md

## Final Summary
Manual fret overrides are implemented with ExtState persistence, a pure override application module, a Manual Overrides panel, reset cleanup, README/architecture documentation, and local Lua 5.3 coverage for replacement, collision, and invalid override behavior. REAPER validation remains needed for the actual ReaImGui panel workflow.
