# Task #008: Color Swatches + Background

- ID: #008-color-swatch-bg
- Created: 2026-02-15 00:00 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #007
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add configurable window background color and show color preview swatches next to hex inputs.

## Requirements
- Add a background color setting for the main window.
- Show a small color preview square next to each color hex input.
- Avoid ImGui_ColorButton argument issues.

## Acceptance Criteria
- [x] Background color can be set via Settings and affects the main window.
- [x] Color inputs show a preview swatch.
- [x] No use of ImGui_ColorButton to avoid argument mismatch errors.

## Plan
- [x] Add background color to config load/save — Files: lib/config.lua — Functions: config.load(), config.save() — Verification: persistence.
- [x] Add swatch helper and apply background color — Files: luaTab.lua — Functions: draw_ui() — Verification: visible swatches and window bg change.
- [x] Update docs/tracking — Files: planning/configuration.md, .tracking/meta.md, .tracking/008-color-swatch-bg.md — Functions: n/a — Verification: file review.

## Execution Log

* 2026-02-15 00:00 UTC Start-of-turn Context Recap:

  * Goal: Add background color control and color swatches.
  * Current State: Hex inputs only, no background control.
  * Blocking Issues: None.
  * Next Subtask: Add background color to config.
  * Known Risks: ReaImGui color button argument mismatch.

* 2026-02-15 00:00 UTC Added background color persistence to config.

* 2026-02-15 00:00 UTC Added window background color styling and color swatches.

* 2026-02-15 00:00 UTC Documented background color setting.

## Decisions

* Use manual draw list swatch instead of ImGui_ColorButton.

## Open Questions

* None.

## Risks

* None.

## Useful Commands and Testing

* Manual: open Settings -> Styling -> Colors and verify swatches + background change.

## Artifacts Changed

* lib/config.lua — added background color persistence.
* luaTab.lua — window background + swatch UI.
* planning/configuration.md — documented background color.

## Final Summary

Added background color control and color swatches for hex inputs without using ImGui_ColorButton.
