# Task #006: Settings Popup Stability

- ID: #006-settings-popup-stability
- Created: 2026-02-15 00:00 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #005
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Fix Settings popup sizing and guard against styling-section crashes, plus prevent stale toggle state when the script crashes.

## Requirements
- Settings popup opens at a sane minimum width.
- Styling section does not crash even if color editor API is missing or unstable.
- Toggle button recovers if the script crashes.

## Acceptance Criteria
- [x] Settings popup opens at a reasonable width and is resizable.
- [x] Entering the Styling section no longer crashes.
- [x] If luaTab crashes, rerunning the script clears the stuck toggle and reopens normally.

## Plan
- [x] Adjust popup sizing flags/constraints — Files: luaTab.lua — Functions: draw_ui() — Verification: open Settings and confirm size.
- [x] Harden color editor calls with pcall + fallback — Files: luaTab.lua — Functions: edit_color() — Verification: open Styling section without crash.
- [x] Add heartbeat + stale toggle recovery — Files: luaTab.lua — Functions: cleanup(), draw_ui() — Verification: simulate crash by forcing early return and rerun.
- [x] Update tracking/meta — Files: .tracking/meta.md, .tracking/006-settings-popup-stability.md — Functions: n/a — Verification: file review.

## Execution Log

* 2026-02-15 00:00 UTC Start-of-turn Context Recap:

  * Goal: Fix Settings popup sizing and stability regressions.
  * Current State: Settings popup opens too narrow; Styling section crash can leave toggle stuck.
  * Blocking Issues: None.
  * Next Subtask: Adjust popup sizing flags/constraints.
  * Known Risks: Compatibility across ReaImGui versions.

* 2026-02-15 00:00 UTC Adjusted popup sizing constraints and removed AlwaysAutoResize.

* 2026-02-15 00:00 UTC Simplified color editing to RGBA sliders to avoid styling crashes.

* 2026-02-15 00:00 UTC Added heartbeat tracking and stale-instance recovery for stuck toggle.

## Decisions

* None yet.

## Open Questions

* None.

## Risks

* Color editor availability varies across ReaImGui versions.

## Useful Commands and Testing

* Manual: open Settings, expand Styling, verify no crash.

## Artifacts Changed

* luaTab.lua — popup sizing, color editor fallback, heartbeat recovery.

## Final Summary

Settings popup now opens with sane dimensions, styling controls use safe sliders, and stale toggle state is cleared via a heartbeat check.
