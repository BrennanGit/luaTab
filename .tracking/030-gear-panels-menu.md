# Task #030: Gear Panels Menu

- ID: #030-gear-panels-menu
- Created: 2026-02-16 11:05 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #028
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Refine the main UI controls by removing the fretboard toggle button, moving panel toggles into the gear button, and updating the gear icon to a window glyph.

## Requirements
- Remove the "Show/Hide fretboard" button from the main control row.
- Move the "Panels" toggles into the gear button popup.
- Replace the gear icon with a window-shaped glyph (rect with a top bar).
- Remove the menu bar Panels entry and its open/close behavior for settings.

## Acceptance Criteria
- [x] Main controls no longer include a "Show/Hide fretboard" button.
- [x] Gear button opens a popup with panel toggles for Fretboard and Settings.
- [x] Gear icon is rendered as a window rectangle with a top bar.
- [x] Menu bar Panels dropdown is removed.

## Plan
- [x] Update main controls to remove the fretboard toggle button in draw_ui() — File: luaTab.lua — Function: draw_ui()
- [x] Replace Panels menu bar with a gear popup menu and window icon — File: luaTab.lua — Functions: draw_ui()
- [x] Clean up unused menu bar helper code — File: luaTab.lua — Function: draw_panel_menu()
- [ ] Verify the UI flow manually in REAPER (menu popup opens, toggles work).

## Execution Log

* 2026-02-16 11:05 UTC Start-of-turn Context Recap:

	* Goal: Move panel toggles into the gear button and remove the fretboard toggle button
	* Current State: Panels menu bar and gear button opens Settings panel directly
	* Blocking Issues: None
	* Next Subtask: Update main controls to remove the fretboard toggle button
	* Known Risks: Popup positioning and toggle sync for the fretboard panel

* 2026-02-16 11:15 UTC Removed the main fretboard toggle button and menu bar Panels entry.

* 2026-02-16 11:20 UTC Reworked the gear button into a panels popup and replaced the icon with a window glyph.

## Decisions

## Open Questions

## Risks

## Useful Commands and Testing
- Manual: run luaTab, click the gear button to open panel toggles, verify panel open/close behavior.

## Artifacts Changed
- luaTab.lua
- .tracking/030-gear-panels-menu.md
## Final Summary
Removed the fretboard toggle button and Panels menu bar, then converted the gear overlay into a panels popup with a window-style icon. Manual UI verification remains.
