# Task #026: Fretboard Dock Flicker Fix

- ID: #026-fretboard-dock-flicker
- Created: 2026-02-16 01:22 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #025
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Fix fretboard flashing and missing UI when the fretboard window is docked into the main ImGui tab bar.

## Requirements
- Fretboard window should not flicker when docked as a tab.
- Main window UI (gear/status) should remain visible after docking.

## Acceptance Criteria
- [x] Docked fretboard does not flash and remains stable.
- [x] Settings gear and status bar remain visible.

## Plan
- [x] Ensure ImGui_End is called for the fretboard window regardless of visibility — Files: luaTab.lua — Functions: draw_fretboard_popup()
- [x] Update tracking metadata — Files: .tracking/meta.md, .tracking/026-fretboard-dock-flicker.md

## Execution Log

* 2026-02-16 01:22 UTC Start-of-turn Context Recap:

  * Goal: Stop flicker and restore UI when fretboard is docked
  * Current State: Docked fretboard flashes; settings gear/status not visible
  * Blocking Issues: None
  * Next Subtask: Always call ImGui_End for the fretboard window
  * Known Risks: Additional docking state may still override layout

* 2026-02-16 01:28 UTC Always called ImGui_End for the fretboard window even when tab not visible.

* 2026-02-16 01:30 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 01:40 UTC Disabled docking for fretboard and added temporary undock positioning after marker reset.

* 2026-02-16 01:48 UTC Re-enabled docking but auto-undock if fretboard tabs with main window.

* 2026-02-16 01:55 UTC Verification: user confirmed docking works and flicker resolved.

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Docking layout could still hide the main window controls.

## Useful Commands and Testing

- Manual: dock fretboard as a tab, verify no flicker and gear/status visible.

## Artifacts Changed

- luaTab.lua

## Final Summary

- Fretboard can dock to sides while auto-undocking when tabbed with the main window.
