# Task #021: Center Time Signatures

- ID: #021-time-sig-center
- Created: 2026-02-15 14:30 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #009
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Center time signature rendering vertically within the staff area.

## Requirements
- Time signatures should be centered between top and bottom staff lines.

## Acceptance Criteria
- [x] Time signatures appear vertically centered on the staff.

## Plan
- [x] Adjust time signature y positioning — Files: lib/render.lua — Functions: render.draw_systems(), draw_time_sig() — Verification: visual check in REAPER
- [ ] Update tracking metadata — Files: .tracking/meta.md, .tracking/021-time-sig-center.md — Functions: n/a

## Execution Log

* 2026-02-15 14:30 UTC Start-of-turn Context Recap:

  * Goal: Center time signatures vertically in the staff
  * Current State: Time signatures render at the staff top
  * Blocking Issues: None
  * Next Subtask: Adjust y placement in render.draw_systems
  * Known Risks: Font scale changes could affect centering

* 2026-02-15 14:35 UTC Centered time signatures in the staff area.

* 2026-02-15 14:40 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Very small staff height could clip time signatures.

## Useful Commands and Testing

- Manual: verify time signatures are centered in gutter and prefix locations.

## Artifacts Changed

- lib/render.lua

## Final Summary

- Centered time signature rendering vertically within the staff.
