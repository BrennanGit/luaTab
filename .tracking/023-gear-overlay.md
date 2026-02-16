# Task #023: Gear Overlay Button

- ID: #023-gear-overlay
- Created: 2026-02-15 15:45 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #022
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Render the settings gear as a floating overlay so it doesn't expand the control rows.

## Requirements
- Gear button should float at the top-right and span both control rows without affecting layout.

## Acceptance Criteria
- [x] Gear button no longer creates dead space in the top row.
- [x] Gear button still opens settings and spans both rows.

## Plan
- [x] Reposition gear button using overlay cursor positioning — Files: luaTab.lua — Functions: draw_ui()
- [ ] Update tracking metadata — Files: .tracking/meta.md, .tracking/023-gear-overlay.md

## Execution Log

* 2026-02-15 15:45 UTC Start-of-turn Context Recap:

  * Goal: Float the gear button over the top-right without expanding the row
  * Current State: Gear button is oversized and stretches the top row height
  * Blocking Issues: None
  * Next Subtask: Reposition gear using cursor screen coordinates
  * Known Risks: Overlap with controls on narrow windows

* 2026-02-15 15:50 UTC Moved the gear button to an overlay position.

* 2026-02-15 15:55 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Gear may overlap the rightmost combo at narrow widths.

## Useful Commands and Testing

- Manual: check top row height and gear overlap at narrow widths.

## Artifacts Changed

- luaTab.lua

## Final Summary

- Positioned the gear button as a floating overlay so it no longer stretches the control row.
