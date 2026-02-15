# Task #013: Bar Layout Resize Fit

- ID: #013-bar-layout-resize
- Created: 2026-02-15 08:05 UTC
 - Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #007, #012
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Fix bar/system width calculations so window resizing fits the expected number of bars and systems after styling changes.

## Requirements
- Bars per system should match the available width without counting a trailing gutter.
- Bar hit targets and boundary markers align with the actual bar body width.

## Acceptance Criteria
- [x] Resizing the window yields the expected number of bars per system based on configured widths.
- [x] Bar boundaries and click targets align with visible bar bodies.

## Plan
- [ ] Normalize bar width math (bar body vs gutter) in layout and render code — Files: lib/layout.lua, lib/render.lua, luaTab.lua — Functions: layout.calc_bars_per_system(), layout.build_systems(), render.draw_systems(), handle_bar_click() — Verification: resize window and compare bar count vs expected math
- [ ] Update tracking metadata — Files: .tracking/meta.md, .tracking/013-bar-layout-resize.md — Functions: n/a — Verification: file review

## Execution Log

* 2026-02-15 08:05 UTC Start-of-turn Context Recap:

  * Goal: Restore correct bar/system fit after styling changes
  * Current State: Bars per system feel off; gutters appear to be counted incorrectly
  * Blocking Issues: None
  * Next Subtask: Normalize bar width math in layout/render
  * Known Risks: Off-by-one math could still miscount in tight widths

* 2026-02-15 08:10 UTC Normalized bar width math in layout, render, and click hit tests.

* 2026-02-15 08:20 UTC Verification: Resized window across various widths — bar count matched calculated expectation; boundary markers and click targets aligned.

## Decisions

- None

## Open Questions

- None

## Risks

- Changes in bar math could affect sweep and boundary marker placement.

## Useful Commands and Testing

- Manual: resize the luaTab window and verify bars per system vs configured bar width settings.

## Artifacts Changed

- lib/layout.lua
- lib/render.lua
- luaTab.lua

## Final Summary

Implemented and verified: layout, render, and click hit logic updated so bars fit correctly on window resize. All acceptance criteria satisfied.
