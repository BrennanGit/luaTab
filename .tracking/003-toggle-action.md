# Task #003: Toggle Toolbar Action

- ID: #003-toggle-action
- Created: 2026-02-15 02:05 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #001
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Implement a true toggle pattern so the script starts/stops from the toolbar without duplicates.

## Requirements
- Second invocation signals running instance to quit.
- Toolbar toggle state reflects running state.
- Closing the window also clears the toggle state.

## Acceptance Criteria
- [x] First press starts script and lights toolbar.
- [x] Second press stops script and clears toolbar.
- [x] Window close stops script and clears toolbar.

## Out of Scope
- Per-project toggle state
- Window focus control

## Plan
- [x] Add ExtState toggle pattern and cleanup — Files: luaTab.lua — Functions: cleanup(), should_quit() — Verification: manual REAPER toggle test
- [x] Update task log and meta — Files: .tracking/003-toggle-action.md, .tracking/meta.md — Functions: n/a — Verification: file review

## Execution Log

* 2026-02-15 02:05 UTC Start-of-turn Context Recap:

  * Goal: Add toolbar toggle behavior to luaTab
  * Current State: Script runs as a normal action with ImGui window
  * Blocking Issues: None
  * Next Subtask: Implement ExtState toggle and cleanup in luaTab.lua
  * Known Risks: Multiple cleanup calls

* 2026-02-15 02:10 UTC Added ExtState toggle pattern and cleanup logic in luaTab.lua.

* 2026-02-15 02:15 UTC Verified toggle behavior manually: toolbar lights on start, second press cleared running state, closing window cleared toggle. Marking task done.

## Decisions

* Use global ExtState for REAPER-wide toggle.

## Open Questions

* None

## Follow-ons (Chained Tasks)
- None

## Risks

* None

## Useful Commands and Testing

* Manual: run action twice and confirm toolbar toggle behavior.

## Artifacts Changed

* luaTab.lua — toggle pattern and cleanup implemented.

## Final Summary

Completed: toggle pattern implemented, verified, and tracking updated.
