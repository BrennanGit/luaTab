# Task #031: Color Picker Panel

- ID: #031-color-picker-panel
- Created: 2026-02-16 11:35 UTC
- Status: in-progress
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #028
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add a dockable Color Picker panel with an ImGui ColorPicker4, a color target dropdown, and a duplicate "Save colors as preset" action. Make color swatches in Settings open/select the panel target when clicked.

## Requirements
- Add a new dockable Color Picker panel using ImGui ColorPicker4 (non-modal).
- Provide a dropdown to select which color variable to edit; selecting updates the picker.
- Duplicate the "Save colors as preset" button in the panel.
- Keep existing settings color controls; clicking the swatch selects/opens the picker.

## Acceptance Criteria
- [x] Color Picker panel is toggleable and docks like existing panels.
- [x] Dropdown selection updates the picker to the correct color.
- [x] Picker edits update the selected color and persist via existing save flow.
- [x] "Save colors as preset" is available in the panel.
- [x] Clicking a Settings swatch opens/selects the picker for that color.

## Plan
- [x] Add color picker state + panel flag in luaTab.lua; expose it in the panel menu.
- [x] Implement draw_color_picker_panel() using ImGui_ColorPicker4 and a dropdown for color keys.
- [x] Update settings swatches to be clickable and open/select the Color Picker panel.
- [x] Verify persistence and preset save modal still works.

## Execution Log

* 2026-02-16 12:00 UTC Start-of-turn Context Recap:

	* Goal: Adjust Color Picker panel sizing to avoid cutoff
	* Current State: Panel renders correctly but initial height is slightly short
	* Blocking Issues: None
	* Next Subtask: Increase initial/minimum panel height
	* Known Risks: None

* 2026-02-16 11:35 UTC Start-of-turn Context Recap:

	* Goal: Add a color picker panel with dropdown selection and swatch click routing
	* Current State: Colors are edited via hex inputs in Settings only
	* Blocking Issues: None
	* Next Subtask: Add state + panel flag and panel menu toggle
	* Known Risks: Color picker API uses U32 colors; must sync with float arrays

* 2026-02-16 11:45 UTC Added color picker panel state, dropdown metadata, and menu toggle.

* 2026-02-16 11:48 UTC Implemented the Color Picker panel with ImGui_ColorPicker4 and preset save access.

* 2026-02-16 11:52 UTC Swatch clicks now open/select the Color Picker target in Settings.

* 2026-02-16 12:02 UTC Increased Color Picker panel initial/minimum height to avoid clipping.

## Decisions

## Open Questions

## Risks
- ReaImGui ColorPicker4 expects U32 color values; need safe conversion to/from float RGBA.

## Useful Commands and Testing
- Manual: open Settings, click a swatch, verify Color Picker opens on that color and changes persist.

## Artifacts Changed
- luaTab.lua
- .tracking/031-color-picker-panel.md

## Final Summary
Raised the Color Picker panel's initial and minimum height so the UI is fully visible without manual resizing.
