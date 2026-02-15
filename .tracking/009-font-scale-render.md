# Task #009: Font Scale Rendering

- ID: #009-font-scale-render
- Created: 2026-02-15 00:00 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #007
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Make font scaling affect actual rendered sizes for frets and time signatures.

## Requirements
- Fret numbers render larger when `fonts.fretScale` increases.
- Time signature numerals render larger when `fonts.timeSigScale` increases.
- Dropped notes scale with `fonts.droppedScale`.

## Acceptance Criteria
- [x] Fret text visibly scales with settings.
- [x] Time signature text visibly scales with settings.
- [x] Dropped notes visibly scale with settings.

## Plan
- [x] Use ImGui_DrawList_AddTextEx with explicit font size — Files: lib/render.lua — Functions: draw_time_sig(), draw_text_with_bg() — Verification: manual UI check.
- [x] Adjust text size calculations for scaled font sizes — Files: lib/render.lua — Functions: calc_text_size() — Verification: centered text remains aligned.
- [x] Update tracking/meta — Files: .tracking/meta.md, .tracking/009-font-scale-render.md — Functions: n/a — Verification: file review.

## Execution Log

* 2026-02-15 00:00 UTC Start-of-turn Context Recap:

  * Goal: Fix font scaling so text size changes visibly.
  * Current State: Scaling only affects spacing.
  * Blocking Issues: None.
  * Next Subtask: Switch to AddTextEx with explicit font size.
  * Known Risks: Requires REAPER 6.24+.

* 2026-02-15 00:00 UTC Switched text rendering to ImGui_DrawList_AddTextEx with explicit font sizes.

* 2026-02-15 00:00 UTC Updated text size calculations to scale with requested font size.

## Decisions

* Use ImGui_DrawList_AddTextEx when available, with fallback to AddText.

## Open Questions

* None.

## Risks

* Older REAPER builds might not expose AddTextEx.

## Useful Commands and Testing

* Manual: increase font scales and verify larger frets and time signatures.

## Artifacts Changed

* lib/render.lua — explicit font size rendering via AddTextEx.

## Final Summary

Font scaling now affects rendered fret, time signature, and dropped note sizes.
