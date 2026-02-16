# Task #035: Center Main Window + Autofocus Save Modal

- ID: #035-center-main-autofocus
- Created: 2026-02-16 13:10 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #034
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Center the main window in the REAPER viewport when it appears and autofocus the preset save modal name field.

## Requirements
- Main window initial position and preset layout apply should center in the REAPER viewport.
- Preset save modal should autofocus the name input for mouse-free entry.

## Acceptance Criteria
- [ ] Main window opens centered on the REAPER viewport (including after applying presets).
- [ ] Preset save modal opens with the name field focused.

## Plan
- [x] Add viewport centering helper and apply it for main window init and layout apply.
  - Files: luaTab.lua
  - Functions: apply_pending_layout(), draw_ui()
  - Verify: Switch presets across monitors; window opens centered on REAPER viewport.
- [x] Add focus flag to preset save modal and set keyboard focus on open.
  - Files: luaTab.lua
  - Functions: open_preset_save(), draw_preset_save_modal()
  - Verify: Open save modal and type immediately without clicking.

## Execution Log

* 2026-02-16 13:10 UTC Start-of-turn Context Recap:

  * Goal: Center main window on viewport and autofocus save modal
  * Current State: Main window uses saved pos; modal requires click to focus
  * Blocking Issues: None
  * Next Subtask: Add viewport centering helper and apply for main window
  * Known Risks: Centering may override user expectations

* 2026-02-16 13:14 UTC Centered main window for initial show and preset layout apply.

* 2026-02-16 13:16 UTC Added autofocus for preset save modal name input.

## Decisions

## Open Questions

## Risks
- Centering may be surprising for users who expect saved positions to persist.

## Useful Commands and Testing
- Manual: Apply a preset saved on another monitor and confirm main window appears centered. Open save modal and type immediately.

## Artifacts Changed
- luaTab.lua
- .tracking/035-center-main-autofocus.md

## Final Summary
Main window now centers in the REAPER viewport on first show and preset apply, and the preset save modal autofocuses the name input.
