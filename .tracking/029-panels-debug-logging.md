# Task #029: Panel Debug Logging

- ID: #029-panels-debug-logging
- Created: 2026-02-16 10:12 UTC
- Status: in-progress
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #028
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add verbose panel Begin/End diagnostics and enable extended logging to pinpoint the ImGui_End imbalance.

## Requirements
- Enable panel debug logging when verbose logging is on.
- Add Begin/End tracing with window title, visibility, and stack depth.
- Capture and report when Begin returns nil or false.
- Check luaTab.log for context to identify problematic panels.

## Acceptance Criteria
- [x] Panel debug logs appear in luaTab.log with Begin/End details.
- [ ] Logging can be enabled/disabled via existing verbose logging settings.
- [x] No new crashes introduced by the logging.

## Plan
- [x] Read util logging helpers and wire Panels.log to util.log — Files: lib/util.lua, luaTab.lua
- [x] Add Begin/End trace logging in ui_panels.lua — Files: lib/ui_panels.lua
- [x] Enable verbose logging and record guidance to inspect luaTab.log — Files: luaTab.lua, .tracking/029-panels-debug-logging.md
- [x] Add scope wrappers and use them in menus — Files: lib/ui_panels.lua, luaTab.lua
- [x] Update tracking metadata and note verification results — Files: .tracking/meta.md, .tracking/029-panels-debug-logging.md

## Execution Log

* 2026-02-16 10:13 UTC Start-of-turn Context Recap:

	* Goal: Add panel Begin/End diagnostics to trace the ImGui_End imbalance
	* Current State: Panels.window still hits ImGui_End too many times under certain docking states
	* Blocking Issues: None
	* Next Subtask: Inspect logging helpers and wire Panels.log to util.log
	* Known Risks: Verbose logging may be noisy but needed for trace ordering

* 2026-02-16 10:17 UTC Added panel Begin/End tracing and forced verbose logging.

* 2026-02-16 10:22 UTC Adjusted End pairing to only close visible=true panels after log showed Settings visible=false before crash.

* 2026-02-16 10:31 UTC Added scope wrappers and minimal docking test script.

* 2026-02-16 10:36 UTC Updated dock test to match ReaImGui Begin/End behavior.

* 2026-02-16 10:40 UTC Verification: dock test passes; docking/tabbing/collapsing panels no longer crash.

## Decisions

## Open Questions

## Risks

## Useful Commands and Testing
- Manual: run luaTab, reproduce crash, inspect luaTab.log for panel trace ordering.

## Artifacts Changed

- luaTab.lua
- lib/ui_panels.lua
- tests/dock_test.lua
- planning/ui_panels.md

## Final Summary
Confirmed ReaImGui Begin/End behavior with the dock test, added scope wrappers and logging, and stabilized docking/tabbing/collapse without crashes. Logging disablement remains optional if you want it removed.
