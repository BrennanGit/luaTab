# Tracking Meta Index

- Index created: {YYYY-MM-DD}
- Last updated: 2026-02-16 15:41 UTC

---

## Active Task Stack

- Top (current):
  - (none)
- Stack:
  - (empty)

> Rules:
> - First entry is current active task.
> - Most recent tasks at top.
> - Only top task may be edited.
> - PUSH for prerequisite tasks.
> - POP when completed or blocked.
> - Do not pause at push/pop boundaries.

---

## Tasks

<!--
Format:

- [status] NNN-short-slug — Title (YYYY-MM-DD) — Owner
  Type: feature | refactor | bugfix | research | docs | infra
  Stability: experimental | beta | stable
  Files: path1, path2
  Functions: f1(), f2()
  Related: #MMM
-->

---

- [done] 037-user-presets-panel-fixes — User presets panel fixes (2026-02-16) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: luaTab.lua, .tracking/037-user-presets-panel-fixes.md
  Functions: draw_user_presets_panel(), draw_preset_delete_modal()
  Related: #036

- [done] 036-user-presets-panel — User presets panel (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, planning/ui_panels.md, .tracking/036-user-presets-panel.md
  Functions: draw_ui(), draw_user_presets_panel(), draw_preset_delete_modal(), delete_user_preset(), open_preset_delete(), apply_layout_preset(), capture_layout_preset()
  Related: #032, #033, #034, #035

- [done] 030-gear-panels-menu — Gear panels menu (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/030-gear-panels-menu.md
  Functions: draw_ui()
  Related: #028

- [done] 035-center-main-autofocus — Center main window + autofocus save modal (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/035-center-main-autofocus.md
  Functions: draw_ui(), draw_preset_save_modal(), apply_pending_layout()
  Related: #034

- [done] 034-preset-modal-enter-safe-layout — Preset modal Enter + safe layout apply (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/034-preset-modal-enter-safe-layout.md
  Functions: draw_preset_save_modal(), apply_pending_layout()
  Related: #032

- [done] 033-preset-dropdown-save — Preset dropdown save option (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/033-preset-dropdown-save.md
  Functions: draw_ui()
  Related: #027

- [done] 032-style-preset-layout — Style preset layout (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, planning/configuration.md, .tracking/032-style-preset-layout.md
  Functions: apply_style_preset(), capture_style_preset(), load_user_style_presets(), save_user_style_presets(), draw_ui()
  Related: #027

- [done] 031-color-picker-panel — Color Picker panel (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/031-color-picker-panel.md
  Functions: draw_ui(), draw_settings_panel(), draw_color_picker_panel()
  Related: #028

- [done] 029-panels-debug-logging — Panel debug logging (2026-02-16) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: luaTab.lua, lib/ui_panels.lua, lib/util.lua, .tracking/029-panels-debug-logging.md
  Functions: draw_ui(), Panels.window(), log_init()
  Related: #028

- [done] 028-panels-framework — Panel framework refactor (2026-02-16) — Owner: agent
  Type: refactor
  Stability: experimental
  Files: luaTab.lua, lib/ui_panels.lua, planning/ui_panels.md, .tracking/architecture.md, .tracking/028-panels-framework.md
  Functions: draw_ui(), draw_fretboard_panel(), draw_settings_panel()
  Related: #026

- [done] 023-gear-overlay — Gear overlay button (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: luaTab.lua, .tracking/023-gear-overlay.md
  Functions: draw_ui()
  Related: #022

- [done] 024-status-bar — Status bar overlay (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/024-status-bar.md
  Functions: draw_ui()
  Related: #023

- [done] 027-presets-export — Preset save + export (2026-02-16) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, planning/configuration.md, .tracking/027-presets-export.md
  Functions: draw_ui(), config.reset()
  Related: #024

- [done] 025-reset-settings — Reset settings emergency fix (2026-02-16) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: lib/config.lua, luaTab.lua, planning/configuration.md, .tracking/025-reset-settings.md
  Functions: config.reset(), draw_ui()
  Related: #024

- [done] 026-fretboard-dock-flicker — Fretboard dock flicker fix (2026-02-16) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: luaTab.lua, .tracking/026-fretboard-dock-flicker.md
  Functions: draw_fretboard_popup()
  Related: #025

- [done] 022-time-sig-gear-size — Time sig offset + gear size (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: lib/render.lua, luaTab.lua, .tracking/022-time-sig-gear-size.md
  Functions: time_sig_y(), draw_ui()
  Related: #021

- [done] 021-time-sig-center — Center time signatures (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: lib/render.lua, .tracking/021-time-sig-center.md
  Functions: render.draw_systems(), draw_time_sig()
  Related: #009

- [done] 020-ui-dropdown-bg-gear-row — UI dropdown background + gear row (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, planning/configuration.md, .tracking/020-ui-dropdown-bg-gear-row.md
  Functions: draw_ui(), config.load(), config.save(), apply_color_preset()
  Related: #019

- [done] 019-ui-text-gear — UI text color + gear button (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, planning/configuration.md, .tracking/019-ui-text-gear.md
  Functions: draw_ui(), config.load(), config.save(), apply_color_preset()
  Related: #018

- [done] 018-main-controls-settings-reorg — Main controls + settings reorg (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/018-main-controls-settings-reorg.md
  Functions: draw_ui(), apply_settings_change()
  Related: #005

- [done] 017-fretboard-close-focus — Fretboard close + focus (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: luaTab.lua, .tracking/017-fretboard-close-focus.md
  Functions: draw_fretboard_popup(), draw_ui()
  Related: #014, #016

- [done] 016-fretboard-popup-align — Fretboard popup alignment (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: lib/render.lua, .tracking/016-fretboard-popup-align.md
  Functions: render.draw_fretboard()
  Related: #015

- [done] 015-fretboard-popup-refine — Fretboard popup refinements (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, lib/render.lua, planning/configuration.md, .tracking/015-fretboard-popup-refine.md
  Functions: render.draw_fretboard(), config.load(), config.save(), clamp_config(), draw_ui()
  Related: #014

- [done] 014-fretboard-popup — Fretboard popup (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, lib/render.lua, planning/configuration.md, .tracking/014-fretboard-popup.md, .tracking/architecture.md
  Functions: config.load(), config.save(), clamp_config(), draw_ui(), render.draw_fretboard()
  Related: #005, #007

- [done] 013-bar-layout-resize — Bar layout resize fit (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: lib/layout.lua, lib/render.lua, luaTab.lua, .tracking/013-bar-layout-resize.md
  Functions: layout.calc_bars_per_system(), layout.build_systems(), render.draw_systems(), handle_bar_click()
  Related: #007, #012

 - [done] 012-bar-click-seek — Bar click seek (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/012-bar-click-seek.md
  Functions: handle_bar_click()
  Related: #004

- [done] 005-settings-ui-overhaul — Settings UI overhaul (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, lib/render.lua, planning/configuration.md, .tracking/005-settings-ui-overhaul.md
  Functions: config.load(), config.save(), render.draw_systems(), draw_ui()
  Related: #001

- [done] 006-settings-popup-stability — Settings popup stability (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: luaTab.lua, .tracking/006-settings-popup-stability.md
  Functions: draw_ui(), edit_color(), cleanup()
  Related: #005

- [done] 007-settings-ui-refine — Settings UI refinement (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, lib/render.lua, lib/util.lua, planning/configuration.md, .tracking/007-settings-ui-refine.md
  Functions: config.load(), config.save(), render.draw_systems(), log_init(), draw_ui()
  Related: #005

- [done] 008-color-swatch-bg — Color swatches + background (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, planning/configuration.md, .tracking/008-color-swatch-bg.md
  Functions: config.load(), config.save(), draw_ui()
  Related: #007

- [done] 009-font-scale-render — Font scale rendering (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: lib/render.lua, .tracking/009-font-scale-render.md
  Functions: draw_time_sig(), draw_text_with_bg(), render.draw_systems()
  Related: #007

- [done] 010-color-presets — Color presets (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, planning/configuration.md, .tracking/010-color-presets.md
  Functions: config.load(), config.save(), draw_ui()
  Related: #008

- [done] 011-transport-passthrough — Transport passthrough (2026-02-15) — Owner: agent
  Type: bugfix
  Stability: experimental
  Files: luaTab.lua, .tracking/011-transport-passthrough.md
  Functions: draw_ui()
  Related: #004

- [done] 004-next-item-preview — Next item preview + item barlines (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: lib/source.lua, luaTab.lua, lib/render.lua, lib/config.lua, lib/midi.lua, .tracking/004-next-item-preview.md, .tracking/architecture.md, planning/configuration.md, planning/examples_and_testing.md
  Functions: source.get_take(), rebuild_data(), render.draw_systems(), midi.extract_notes()
  Related: #001

- [done] 003-toggle-action — Toggle toolbar action (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, .tracking/003-toggle-action.md
  Functions: cleanup(), should_quit(), set_toggle()
  Related: #001

- [done] 002-chord-rendering — Chord rendering cleanup (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: lib/render.lua, .tracking/002-chord-rendering.md
  Functions: render.draw_systems()
  Related: #001

- [done] 001-mvp-implementation — MVP implementation plan (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: luaTab.lua, lib/config.lua, lib/timeline.lua, lib/layout.lua, lib/midi.lua, lib/source.lua, lib/frets.lua, lib/render.lua, lib/util.lua, tests/tests.lua, .tracking/architecture.md, .tracking/001-mvp-implementation.md, planning/project_brief.md, planning/implementation_plan.md, planning/examples_and_testing.md
  Functions: config.load(), config.save(), timeline.build_bars(), timeline.get_measure_index(), layout.build_systems(), layout.calc_bars_per_system(), midi.extract_notes(), midi.group_events(), source.get_take(), frets.assign_event(), render.draw_systems(), compute_virtual_bar(), compute_sweep_offset_px()
  Related: none

### Example

- [done] 000-demo — Demo task (2026-02-12) — Owner: agent
  Type: docs
  Stability: stable
  Files: .tracking/000-demo.md
  Functions: n/a
  Related: none

---

## Status Legend

- planned — task defined but not started
- in-progress — currently executing (may be on stack)
- blocked — awaiting clarification/input
- done — fully implemented and verified

---

## Maintenance Checklist (Agent Reminder)

Before working:
- Read this file.
- Identify top of stack.
- Confirm status matches reality.

After working:
- Update Last updated timestamp.
- Update Files/Functions map.
- POP if complete.
- Ensure stack reflects reality.
