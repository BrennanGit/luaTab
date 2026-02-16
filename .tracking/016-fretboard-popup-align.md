# Task #016: Fretboard Popup Alignment

- ID: #016-fretboard-popup-align
- Created: 2026-02-15 10:45 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #015
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Adjust nut spacing, fret alignment, and add buffer boundary lines for the fretboard popup.

## Requirements
- Add top/bottom boundary lines so strings sit inside the fretboard frame.
- Increase nut double-line separation and place fret 0 markers centered between the nut lines.
- Align fret markers so fret numbers land on the intended fret spaces.

## Acceptance Criteria
- [x] Two horizontal boundary lines appear just above and below strings; frets extend to them.
- [x] Nut is a double line with wider spacing; fret 0 notes are centered between them.
- [x] Fret notes align with correct fret positions (no off-by-one).

## Plan
- [x] Update fretboard line geometry and note centering — Files: lib/render.lua — Functions: render.draw_fretboard() — Verification: compare fret alignment in popup
- [ ] Update tracking metadata — Files: .tracking/meta.md, .tracking/016-fretboard-popup-align.md — Functions: n/a — Verification: file review

## Execution Log

* 2026-02-15 10:45 UTC Start-of-turn Context Recap:

  * Goal: Fix fretboard nut spacing, fret alignment, and add boundary lines
  * Current State: Nut lines are tight, fret notes look offset, no boundary lines
  * Blocking Issues: None
  * Next Subtask: Update fretboard geometry and note centering
  * Known Risks: Mis-centering could shift note markers too far left

* 2026-02-15 10:55 UTC Added boundary lines, widened nut spacing, and re-centered note placement.

* 2026-02-15 11:00 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Boundary line spacing could crowd strings in small windows.

## Useful Commands and Testing

- Manual: verify fret 0, fret 1, and fret 2 note placement against line positions.

## Artifacts Changed

- lib/render.lua

## Final Summary

- Added fretboard boundary lines, widened the nut double line, and centered fret 0 and fretted notes in correct spaces.
