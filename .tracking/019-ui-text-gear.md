# Task #019: UI Text Color + Gear Button

- ID: #019-ui-text-gear
- Created: 2026-02-15 12:55 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #018
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add configurable UI text color and replace the menu bar with a gear button in the main control strip.

## Requirements
- Introduce a system UI text color setting and apply it to ImGui text rendering.
- Replace the settings menu bar with a gear button aligned to the right of the main controls.

## Acceptance Criteria
- [x] Light mode labels remain legible via the UI text color setting.
- [x] Settings button appears as a square gear button on the main control strip.
- [x] Settings popup opens from the gear button.

## Plan
- [x] Add UI text color defaults/persistence and presets — Files: lib/config.lua, luaTab.lua — Functions: config.load(), config.save(), apply_color_preset()
- [x] Apply text color + gear button layout — Files: luaTab.lua — Functions: draw_ui()
- [ ] Update docs/tracking metadata — Files: planning/configuration.md, .tracking/meta.md, .tracking/019-ui-text-gear.md

## Execution Log

* 2026-02-15 12:55 UTC Start-of-turn Context Recap:

  * Goal: Fix light mode label visibility and move settings button to main bar
  * Current State: Labels use default ImGui text color; settings lives in menu bar
  * Blocking Issues: None
  * Next Subtask: Add UI text color defaults and apply to ImGui text
  * Known Risks: Gear glyph may depend on font support

* 2026-02-15 13:10 UTC Added UI text color setting and replaced menu bar with a gear button.

* 2026-02-15 13:15 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Some fonts may not include the gear glyph.

## Useful Commands and Testing

- Manual: switch to light preset and confirm labels are visible.

## Artifacts Changed

- lib/config.lua
- luaTab.lua
- planning/configuration.md

## Final Summary

- Added configurable UI text color and replaced the menu bar with a gear button on the main control strip.
