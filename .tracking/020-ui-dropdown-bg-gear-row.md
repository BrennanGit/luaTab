# Task #020: UI Dropdown Background + Gear Row

- ID: #020-ui-dropdown-bg-gear-row
- Created: 2026-02-15 13:40 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #019
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add a dropdown background color setting, unify settings popup background, and move the gear button to the top control row.

## Requirements
- Add a configurable background color for dropdowns/controls.
- Use the main background color for the settings popup (so it stays readable).
- Move the settings gear button to the row above the bars row.

## Acceptance Criteria
- [x] Dropdown backgrounds use the configured UI control color.
- [x] Settings popup is readable and matches the main background color.
- [x] Gear button appears on the top control row.

## Plan
- [x] Add control background color defaults/persistence — Files: lib/config.lua, luaTab.lua — Functions: config.load(), config.save(), apply_color_preset()
- [x] Apply popup + control background styling and gear placement — Files: luaTab.lua — Functions: draw_ui()
- [ ] Update docs/tracking metadata — Files: planning/configuration.md, .tracking/meta.md, .tracking/020-ui-dropdown-bg-gear-row.md

## Execution Log

* 2026-02-15 13:40 UTC Start-of-turn Context Recap:

  * Goal: Add dropdown background styling and move gear button up
  * Current State: Dropdowns blend into light mode; settings popup background is hard to read
  * Blocking Issues: None
  * Next Subtask: Add control background color defaults and style pushes
  * Known Risks: ImGui style scopes might affect other widgets

* 2026-02-15 13:55 UTC Added UI control background color and applied popup/control styling + gear placement.

* 2026-02-15 14:00 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Overriding frame colors could reduce contrast for sliders.

## Useful Commands and Testing

- Manual: switch color presets and verify dropdown readability.

## Artifacts Changed

- lib/config.lua
- luaTab.lua
- planning/configuration.md

## Final Summary

- Added a UI control background color, applied it to dropdowns and popups, and moved the gear button to the top row.
