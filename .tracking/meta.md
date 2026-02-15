# Tracking Meta Index

- Index created: {YYYY-MM-DD}
 - Last updated: 2026-02-15 08:20 UTC

---

## Active Task Stack

## Active Task Stack

- Top (current):
  - (empty)
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
