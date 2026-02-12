# Tracking Meta Index

- Index created: {YYYY-MM-DD}
- Last updated: {YYYY-MM-DD HH:MM UTC}

---

## Active Task

- Current: #NNN-short-slug
  - Status: planned | in-progress | blocked
  - Owner: {agent/user}

> Rules:
> - Only one active task at a time.
> - If no task is active, set Current: none.
> - Must be updated when switching tasks.

---

## Tasks

<!--
Format:

- [status] NNN-short-slug — Title (YYYY-MM-DD) — Owner
  Type: feature | refactor | bugfix | research | docs | infra
  Stability: experimental | beta | stable
  Files: path1, path2
  Functions: f1(), f2()
  Related: #MMM, #PPP
-->

---

### Example

- [done] 000-demo — Demo task (2026-02-12) — Owner: agent
  Type: docs
  Stability: stable
  Files: .tracking/000-demo.md
  Functions: n/a
  Related: none

- [in-progress] 012-tab-layout — Joined tab system layout (2026-02-13) — Owner: agent
  Type: feature
  Stability: experimental
  Files: TabHUD.lua, lib/layout.lua, lib/render.lua
  Functions: computeSystems(), renderSystem()
  Related: #011-solver-refactor

---

## Status Legend

- planned — task defined but not started
- in-progress — active implementation
- blocked — waiting for clarification or dependency
- done — fully implemented and verified

---

## Conventions

- Update "Last updated" timestamp whenever meta.md changes.
- Keep entries chronological (do not reorder old tasks).
- Do not remove completed tasks.
- Cross-reference related tasks by ID.
- If a task replaces functionality from another task, note it explicitly.

---

## Maintenance Checklist (Agent Reminder)

Before starting work:
- Read this file.
- Identify Active Task.
- Confirm task status matches reality.
- If switching tasks, update Active Task section.

After completing work:
- Update task status.
- Update Files/Functions list if needed.
- Clear Active Task (or switch to next).
- Update Last updated timestamp.
