# Task #025: Reset Settings Emergency Fix

- ID: #025-reset-settings
- Created: 2026-02-16 00:30 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #024
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add an emergency reset path to clear cached ExtState settings and provide a Reset to Defaults button in Settings.

## Requirements
- Provide a reliable way to clear saved ExtState settings from a previous run.
- Add a Settings UI button to reset all settings to defaults.

## Acceptance Criteria
- [x] A reset marker file triggers ExtState clearing on startup.
- [x] Settings popup exposes a "Reset all settings" action with confirmation.
- [x] Defaults are reloaded and saved after reset.

## Plan
- [x] Add reset helper to config module — Files: lib/config.lua — Functions: config.reset()
- [x] Add startup reset marker handling + UI reset action — Files: luaTab.lua — Functions: draw_ui()
- [x] Document reset behavior — Files: planning/configuration.md
- [x] Update tracking metadata — Files: .tracking/meta.md, .tracking/025-reset-settings.md

## Execution Log

* 2026-02-16 00:35 UTC Start-of-turn Context Recap:

	* Goal: Add an emergency settings reset path and Settings reset button
	* Current State: Settings are stored in ExtState; no reset action exists
	* Blocking Issues: User cannot interact due to flashing window state
	* Next Subtask: Implement config.reset() and startup marker handling
	* Known Risks: Reset may not clear ImGui docking layout

* 2026-02-16 00:48 UTC Added config.reset() to delete ExtState keys.

* 2026-02-16 00:50 UTC Added reset marker handling at startup and UI reset action.

* 2026-02-16 00:52 UTC Documented reset behavior.

* 2026-02-16 00:55 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 01:05 UTC Updated marker reset to clear ImGui ini layout file.

* 2026-02-16 01:20 UTC Start-of-turn Context Recap:

	* Goal: Ensure marker reset fully clears cached settings/layout
	* Current State: Marker reset clears ExtState and ImGui ini, but flashing persists
	* Blocking Issues: None
	* Next Subtask: Investigate fretboard docking flicker separately
	* Known Risks: Issue may be unrelated to cached settings

* 2026-02-16 01:56 UTC Verification: user confirmed marker reset stops flicker by disabling fretboard.

## Decisions

- Use a marker file in the script directory (luaTab.reset) for emergency resets.

## Open Questions

- None.

## Risks

- Resetting ExtState does not clear ImGui docking layout if stored elsewhere.

## Useful Commands and Testing

- Manual: create luaTab.reset in script dir, run script, confirm defaults restored.
- Manual: click "Reset all settings" and confirm defaults apply.

## Artifacts Changed

- lib/config.lua
- luaTab.lua
- planning/configuration.md

## Final Summary

- Added marker-file reset and settings UI reset to restore defaults.
