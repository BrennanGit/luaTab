# Task #032: Style Preset Layout

- ID: #032-style-preset-layout
- Created: 2026-02-16 12:20 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #027
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add panel layout (size/position/visibility) and playback range/update settings into style presets, enabling mode-like presets (sheet music/playalong) that capture layout and update behavior.

## Requirements
- Style presets persist and apply panel layout (size/position) and panel visibility.
- Style presets persist and apply prev/next bars and update settings.
- Existing style presets without layout data continue to load safely.
- Settings export remains valid and reflects current config.

## Acceptance Criteria
- [ ] Saving a style preset captures current panel visibility and layout along with scale.
- [ ] Applying a style preset restores prev/next bars + update settings and panel visibility.
- [ ] Panels honor preset layout on apply (size/position set on next draw).
- [ ] No errors when loading old style presets without layout fields.
- [ ] Documentation updated for new preset payload.

## Plan
- [x] Add layout capture/apply helpers in luaTab.lua (panel rect capture, pending layout apply, preset layout payload) and integrate into apply_style_preset()/save_current_preset().
  - Files: luaTab.lua
  - Functions: apply_style_preset(), capture_style_preset(), draw_ui(), draw_settings_panel(), draw_fretboard_panel(), draw_color_picker_panel()
  - Verify: Save/apply style preset; panels reopen in expected states and update settings change.
- [x] Extend user style preset persistence to include layout data.
  - Files: luaTab.lua
  - Functions: load_user_style_presets(), save_user_style_presets()
  - Verify: Restart script and confirm preset restores layout.
- [x] Update documentation to describe new style preset fields and behavior.
  - Files: planning/configuration.md
  - Verify: Documented keys match implementation.

## Execution Log

* 2026-02-16 12:20 UTC Start-of-turn Context Recap:

  * Goal: Add layout and update settings into style presets
  * Current State: Style presets only store scale values
  * Blocking Issues: None
  * Next Subtask: Add layout capture/apply helpers in luaTab.lua
  * Known Risks: Docked window positions may not fully restore

* 2026-02-16 12:30 UTC Added layout capture/apply helpers and panel rect tracking for presets.

* 2026-02-16 12:35 UTC Extended style preset persistence to include layout settings and panel geometry.

* 2026-02-16 12:38 UTC Documented layout fields in configuration notes.

* 2026-02-16 12:41 UTC Only mark windows initialized when a pending layout applies size/position.

## Decisions

## Open Questions

## Risks
- Docked window positions may not fully restore if ReaImGui ignores SetNextWindowPos while docked.

## Useful Commands and Testing
- Manual: Save a style preset, change panel layout/visibility + prev/next/update, apply preset and confirm restoration.

## Artifacts Changed
- luaTab.lua
- planning/configuration.md
- .tracking/032-style-preset-layout.md

## Final Summary
Style presets now capture/apply panel layout, prev/next/update settings, and persist those fields in ExtState, with docs updated to reflect the new layout keys.
