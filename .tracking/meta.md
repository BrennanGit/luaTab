# Tracking Meta Index

- Index created: {YYYY-MM-DD}
- Last updated: {YYYY-MM-DD HH:MM UTC}

---

## Active Task Stack

- Top (current):
  - none

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

### Example

- [done] 000-demo — Demo task (2026-02-12) — Owner: agent
  Type: docs
  Stability: stable
  Files: .tracking/000-demo.md
  Functions: n/a
  Related: none

- [in-progress] 012-layout-refactor — Joined tab layout (2026-02-13) — Owner: agent
  Type: feature
  Stability: experimental
  Files: TabHUD.lua, lib/layout.lua
  Functions: computeSystems(), renderSystem()
  Related: #010-initial-layout

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

