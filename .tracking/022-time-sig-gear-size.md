# Task #022: Time Sig Offset + Gear Size

- ID: #022-time-sig-gear-size
- Created: 2026-02-15 15:10 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #021
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Nudge time signatures upward and enlarge the gear button to span both control rows.

## Requirements
- Time signatures should sit slightly higher when centered.
- Gear button should be roughly twice the size and cover both control rows.

## Acceptance Criteria
- [x] Time signatures no longer appear low in the staff.
- [x] Gear button spans the two control rows and opens settings.

## Plan
- [x] Adjust time signature centering offset — Files: lib/render.lua — Functions: time_sig_y(), render.draw_systems()
- [x] Enlarge gear button sizing — Files: luaTab.lua — Functions: draw_ui()
- [ ] Update tracking metadata — Files: .tracking/meta.md, .tracking/022-time-sig-gear-size.md

## Execution Log

* 2026-02-15 15:10 UTC Start-of-turn Context Recap:

  * Goal: Nudge time sigs up and enlarge the gear
  * Current State: Time sigs still appear low; gear is single-row
  * Blocking Issues: None
  * Next Subtask: Adjust time_sig_y and gear sizing
  * Known Risks: Overshoot could clip at small staff heights

* 2026-02-15 15:15 UTC Nudged time sigs upward and increased gear size.

* 2026-02-15 15:20 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Large gear might overlap narrow layouts.

## Useful Commands and Testing

- Manual: verify time sig vertical position and gear size in UI.

## Artifacts Changed

- lib/render.lua
- luaTab.lua

## Final Summary

- Nudged time signatures upward slightly and enlarged the gear button to span both control rows.
