# Task #028: Panel Framework Refactor

- ID: #028-panels-framework
- Created: 2026-02-16 09:10 UTC
- Status: done
- Type: refactor
- Stability: experimental
- Owner: agent
- Related: #026
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Refactor the UI to use the shared panel helpers, move settings/fretboard into dockable panels, and document the panel architecture for future extension.

## Requirements
- Use lib/ui_panels.lua for all top-level windows.
- Convert main, settings, and fretboard windows into dockable panels.
- Keep modals only for atomic, blocking flows (save preset, reset confirm).
- Remove Begin/End mismatch workarounds and unify window patterns.
- Add a markdown architecture note describing the panel framework and extension pattern.

## Acceptance Criteria
- [x] Main, fretboard, and settings windows are dockable panels using Panels.window.
- [x] Settings no longer uses a modal window; modals remain only for save/reset confirmations.
- [x] No direct ImGui_Begin/End calls for top-level windows in luaTab.lua.
- [x] Panel architecture doc is added and referenced in tracking metadata.
- [x] Tracking metadata and architecture notes updated to reflect the new panel system.

-## Plan
- [x] Add panel architecture documentation and update architecture notes — Files: planning/ui_panels.md, .tracking/architecture.md
- [x] Introduce panel state and refactor main window to Panels.window + dockspace + menu toggles — Files: luaTab.lua — Functions: draw_ui()
- [x] Convert fretboard popup to dockable panel and sync with config state — Files: luaTab.lua — Functions: draw_fretboard_panel()
- [x] Convert settings modal to dockable panel and keep save/reset modals — Files: luaTab.lua — Functions: draw_settings_panel(), draw_preset_save_modal()
- [x] Update tracking metadata (verification pending in REAPER UI) — Files: .tracking/meta.md, .tracking/028-panels-framework.md

## Execution Log

* 2026-02-16 09:12 UTC Start-of-turn Context Recap:

	* Goal: Refactor UI to use the panel helpers and dockable windows
	* Current State: Settings/fretboard are modal or popup windows with manual Begin/End handling
	* Blocking Issues: None
	* Next Subtask: Document panel architecture and refactor main window to Panels.window
	* Known Risks: Docking visibility edge cases could hide updates when panels are tabbed

* 2026-02-16 09:30 UTC Added UI panel architecture documentation and updated architecture notes.

* 2026-02-16 09:44 UTC Refactored main, settings, and fretboard windows to use Panels.window with dockspace and panel toggles.

* 2026-02-16 09:46 UTC Updated fretboard panel syncing and settings panel close behavior.

* 2026-02-16 09:54 UTC Verification not run (requires REAPER UI).

## Decisions

## Open Questions

## Risks

## Useful Commands and Testing
- Manual: dock/undock panels, hide/show via menu, confirm save/reset modals still work.

## Artifacts Changed

- luaTab.lua
- planning/ui_panels.md
- .tracking/architecture.md
- .tracking/meta.md
- .tracking/028-panels-framework.md

## Final Summary
Refactored the UI to use Panels.window for main, settings, and fretboard panels with a shared dockspace, documented the panel architecture, and removed the settings modal in favor of a dockable panel. Verification not run (requires REAPER UI).
