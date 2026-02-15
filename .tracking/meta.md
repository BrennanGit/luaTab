# Tracking Meta Index

- Index created: {YYYY-MM-DD}
- Last updated: 2026-02-15 01:45 UTC

---

## Active Task Stack

- Top (current):
-  - #002-chord-rendering — Status: in-progress — Owner: agent
- Stack:
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

- [in-progress] 002-chord-rendering — Chord rendering cleanup (2026-02-15) — Owner: agent
  Type: feature
  Stability: experimental
  Files: .tracking/002-chord-rendering.md
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
````

