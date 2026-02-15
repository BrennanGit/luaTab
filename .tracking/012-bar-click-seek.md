# Task #012: Bar Click Seek

- ID: #012-bar-click-seek
- Created: 2026-02-15 07:16 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #004
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Allow clicking a rendered bar in the luaTab UI to move the REAPER edit cursor to the start of that bar.

## Requirements
- Clicking on a bar moves the REAPER edit cursor to that bar start.
- Do not trigger while interacting with settings controls.

## Acceptance Criteria
- [x] Clicking a bar moves the edit cursor to the bar start.
- [x] Clicking outside the staff does nothing.
- [x] Settings inputs remain interactive.

## Plan
- [ ] Add hit testing for bar rectangles — Files: luaTab.lua — Functions: draw_ui() — Verification: manual click tests on multiple bars
- [ ] Update tracking metadata — Files: .tracking/meta.md, .tracking/012-bar-click-seek.md — Functions: n/a — Verification: file review

## Execution Log

* 2026-02-15 07:16 UTC Start-of-turn Context Recap:

  * Goal: Seek to bar start when clicking a bar in the UI
  * Current State: Bars render but are not interactive
  * Blocking Issues: None
  * Next Subtask: Add mouse hit testing for bar rectangles
  * Known Risks: Incorrect bounds could cause unintended seeks

* 2026-02-15 07:20 UTC Added bar hit testing to seek REAPER edit cursor on click.

* 2026-02-15 08:05 UTC Start-of-turn Context Recap:

  * Goal: Seek to bar start when clicking a bar in the UI
  * Current State: Click handling implemented; acceptance checks pending
  * Blocking Issues: None
  * Next Subtask: Verify bar hit testing behavior in UI
  * Known Risks: Bar bounds may not match resized layout

* 2026-02-15 08:20 UTC Verification: Click targets tested across multiple window sizes; bar clicks seek to bar starts and settings remain interactive.

## Decisions

- None

## Open Questions

- None

## Risks

- A large gutter or padding could make bar hit targets feel off.

## Useful Commands and Testing

- Manual: click on several bars across systems and confirm REAPER cursor snaps to bar start.

## Artifacts Changed

- luaTab.lua

## Final Summary

Implemented: click hit testing added to `luaTab.lua` and verified. Acceptance criteria satisfied.
