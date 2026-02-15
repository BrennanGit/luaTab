# Task #005: Settings UI Overhaul

- ID: #005-settings-ui-overhaul
- Created: 2026-02-15 00:00 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #001
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Move most runtime settings into a settings popup with grouped sections (tuning, styling, playback, general) to keep the play area clean.

## Requirements
- Provide a settings popup/panel accessible from the main window.
- Group settings into tuning, styling, playback, and general sections.
- Include tuning presets for guitar, mandolin, and bass.
- Keep the main play area visually clean and focused on tab rendering.

## Acceptance Criteria
- [x] Settings UI opens from the main window and does not clutter the play area.
- [x] Settings are grouped into tuning, styling, playback, and general sections.
- [x] Tuning presets (guitar/mandolin/bass) apply correctly.
- [x] Settings changes persist via ExtState and apply without restart where feasible.

## Plan
- [x] Add config fields for colors and preset tracking and persist them — Files: lib/config.lua — Functions: config.load(), config.save() — Verification: reload script and confirm values persist.
- [x] Update renderer to consume configurable colors/thickness — Files: lib/render.lua — Functions: render.draw_systems() — Verification: tweak color values and confirm visual change.
- [x] Replace inline controls with a settings popup grouped by category — Files: luaTab.lua — Functions: draw_ui() — Verification: UI opens popup, main area stays clean.
- [x] Document new settings groups and fields — Files: planning/configuration.md, .tracking/meta.md, .tracking/005-settings-ui-overhaul.md — Functions: n/a — Verification: doc review.

## Execution Log

* 2026-02-15 00:00 UTC Start-of-turn Context Recap:

  * Goal: Move runtime settings into a grouped settings popup and clean the main tab area.
  * Current State: Inline controls clutter the main window header.
  * Blocking Issues: None.
  * Next Subtask: Add config fields for colors and preset tracking.
  * Known Risks: ReaImGui control availability for color editing.

* 2026-02-15 00:00 UTC Added color defaults + tuning preset persistence in config.

* 2026-02-15 00:00 UTC Switched renderer to configurable color palette from config.

* 2026-02-15 00:00 UTC Replaced inline controls with grouped Settings popup and moved log/source info into General section.

* 2026-02-15 00:00 UTC Documented settings groups and color fields.

## Decisions

* None yet.

## Open Questions

* None.

## Risks

* Color editor availability across ReaImGui versions; fallback may be needed.

## Useful Commands and Testing

* Manual: open Settings, adjust values, confirm changes persist on reopen.

## Artifacts Changed
- lib/config.lua — added color defaults and tuning preset persistence.
- lib/render.lua — read configurable colors for rendering.
- luaTab.lua — added settings popup UI and moved controls from main view.
- planning/configuration.md — documented settings grouping and color fields.

## Final Summary
Implemented a settings popup with tuning/styling/playback/general groups, added tuning presets, and wired configurable colors and layout knobs into config and rendering.
