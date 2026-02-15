# Task #007: Settings UI Refinement

- ID: #007-settings-ui-refine
- Created: 2026-02-15 00:00 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #005
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Move prev/next bars into Playback, add configurable log path with reset, improve color editing with hex input and descriptive names, and add font sizing controls for fret/time-sig text.

## Requirements
- Place prev/next bars under Playback settings.
- Allow editing log file location with a reset-to-default action.
- Replace raw RGBA sliders with named hex input fields.
- Add configurable font sizes (frets/time signatures/dropped notes).

## Acceptance Criteria
- [x] Prev/next bars appear in Playback section, not General.
- [x] Log path can be edited and reset to default path.
- [x] Colors are edited via named hex fields, mapping to their render usage.
- [x] Font size controls exist and affect rendering.

## Plan
- [x] Update config for logPath + font scale settings — Files: lib/config.lua — Functions: config.load(), config.save() — Verification: reload persistence.
- [x] Update util logging to accept explicit path — Files: lib/util.lua — Functions: log_init() — Verification: log file created at configured path.
- [x] Revise Settings UI sections + add hex color inputs — Files: luaTab.lua — Functions: draw_ui() — Verification: UI layout and color parsing.
- [x] Apply font sizes in renderer — Files: lib/render.lua — Functions: render.draw_systems() — Verification: visible size change.
- [x] Update docs/tracking — Files: planning/configuration.md, .tracking/meta.md, .tracking/007-settings-ui-refine.md — Functions: n/a — Verification: file review.

## Execution Log

* 2026-02-15 00:00 UTC Start-of-turn Context Recap:

  * Goal: Refine Settings UI layout and configuration options.
  * Current State: Prev/next bars in General, log path fixed, colors via RGBA sliders, no font size controls.
  * Blocking Issues: None.
  * Next Subtask: Update config for logPath and font scales.
  * Known Risks: Font customization depends on ReaImGui support.

* 2026-02-15 00:00 UTC Added logPath + font scales to config and persisted them.

* 2026-02-15 00:00 UTC Updated logging init to accept explicit log path.

* 2026-02-15 00:00 UTC Moved prev/next bars into Playback, added hex color inputs with descriptive labels, and log path edit/reset.

* 2026-02-15 00:00 UTC Wired font scales into renderer for frets/time signatures/dropped notes.

* 2026-02-15 00:00 UTC Documented new settings in configuration.md.

## Decisions

* None yet.

## Open Questions

* None.

## Risks

* Font size scaling relies on ReaImGui font scaling behavior.

## Useful Commands and Testing

* Manual: open Settings -> Playback/Styling to verify layout and rendering.

## Artifacts Changed

* lib/config.lua — added logPath and font scales.
* lib/util.lua — log_init accepts explicit path.
* luaTab.lua — settings UI refinements, hex colors, log path control.
* lib/render.lua — font scale usage.
* planning/configuration.md — documented new settings.

## Final Summary

Refined the Settings UI with Playback placement, named hex color inputs, log path configuration, and font scaling controls.
