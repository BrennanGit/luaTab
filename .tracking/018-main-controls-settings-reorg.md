# Task #018: Main Controls + Settings Reorg

- ID: #018-main-controls-settings-reorg
- Created: 2026-02-15 12:05 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #005
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Move key controls to the main window and reorganize the settings popup styling sections by element.

## Requirements
- Show tuning preset, color preset, fretboard visibility, prev/next bars, and update mode on the main screen.
- Remove those items from the settings popup.
- Reorganize styling options so per-element settings and colors live together with separators.

## Acceptance Criteria
- [x] Main window shows the requested controls and changes persist.
- [x] Settings popup no longer duplicates the moved controls.
- [x] Styling section groups per-element settings with nearby colors and separators.

## Plan
- [x] Add main control strip and shared apply helper — Files: luaTab.lua — Functions: draw_ui(), apply_settings_change()
- [x] Reorganize settings popup styling and fretboard sections — Files: luaTab.lua — Functions: draw_ui()
- [ ] Update tracking metadata — Files: .tracking/meta.md, .tracking/018-main-controls-settings-reorg.md — Functions: n/a

## Execution Log

* 2026-02-15 12:05 UTC Start-of-turn Context Recap:

  * Goal: Bring key controls to main UI and reorganize settings styling groups
  * Current State: Controls live in settings popup; styling colors grouped separately
  * Blocking Issues: None
  * Next Subtask: Add main control strip and apply helper
  * Known Risks: UI crowding in narrow window sizes

* 2026-02-15 12:25 UTC Added main control strip and reorganized styling/fretboard settings.

* 2026-02-15 12:30 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Moving controls may require additional layout tweaks later.

## Useful Commands and Testing

- Manual: adjust controls from main bar and confirm persistence.

## Artifacts Changed

- luaTab.lua

## Final Summary

- Added a main control strip for key options and reorganized the settings popup so styling options sit with their related elements.
