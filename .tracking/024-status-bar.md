# Task #024: Status Bar Overlay

- ID: #024-status-bar
- Created: 2026-02-16 00:00 UTC
- Status: in-progress
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #023
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Move the status message into a small status bar that overlays the bottom of the main window content.

## Requirements
- Status text should render in a compact bar overlaying the bottom of the content area.
- The bar should not shift layout or consume vertical space.

## Acceptance Criteria
- [ ] Status text appears in a small bar over the bottom content area.
- [ ] Bar does not push the main content upward.
- [ ] When no status message is active, the bar shows the current bar number.

## Plan
- [x] Replace inline status text with overlay drawing — Files: luaTab.lua — Functions: draw_ui()
- [x] Update tracking metadata — Files: .tracking/meta.md, .tracking/024-status-bar.md

## Execution Log

* 2026-02-16 00:05 UTC Start-of-turn Context Recap:

	* Goal: Move the status message into a small overlay bar at the bottom
	* Current State: Status text is inline above the separator and pushes content
	* Blocking Issues: None
	* Next Subtask: Draw status bar overlay in draw_ui()
	* Known Risks: Bar could cover content in short windows

* 2026-02-16 00:10 UTC Moved status rendering to a bottom overlay bar in draw_ui().

* 2026-02-16 00:12 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 00:20 UTC Clamped gear overlay position to content bounds to avoid ImGui cursor boundary warning.

* 2026-02-16 02:00 UTC Start-of-turn Context Recap:

	* Goal: Restore missing status bar and gear overlay after docking fixes
	* Current State: Fretboard docking works, but overlay items are missing
	* Blocking Issues: None
	* Next Subtask: Redraw overlays using foreground draw list + invisible button
	* Known Risks: Foreground draw list may not be available on older ReaImGui

* 2026-02-16 02:05 UTC Moved gear and status to a foreground overlay pass with an invisible button for clicks.

* 2026-02-16 02:12 UTC Added window-size fallback for overlay bounds and foreground draw list compatibility.

* 2026-02-16 02:18 UTC Added Dummy() after overlay cursor positioning to avoid ImGui boundary error.

* 2026-02-16 02:25 UTC Nudged overlay gear button down for better alignment.

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Overlay could cover low notes on very short window heights.

## Useful Commands and Testing

- Manual: verify bar overlays content and still shows bar number when no status message.

## Artifacts Changed

- luaTab.lua

## Final Summary

- (pending)
