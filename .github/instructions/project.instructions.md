---
applyTo: "**"
---

# Project Documentation Map

This repository uses structured planning and reference documents to reduce context loss across sessions.

Before implementing non-trivial changes, consult the relevant documents below.

---

## Core Planning System

Located in `.tracking/`:

- `.tracking/meta.md`  
  → Task index and Active Task pointer.

- `.tracking/NNN-*.md`  
  → Individual task files (plan → execute → verify → summary).

- `.tracking/architecture.md` (if present)  
  → High-level system structure, invariants, data flow, performance notes.

These files are the source of truth for ongoing work.

---

## Project-Specific Documentation

Examples (may vary by project):

- `project_brief.md`  
  → Functional goals and design intent.

- `implementation_plan.md`  
  → Planned module layout, data flow, algorithms.

- `reascript_api.md`  
  → Relevant API references and usage notes.

- `examples_and_testing.md`  
  → Test cases and validation framework.

- `configuration.md`  
  → User-facing knobs and styling/config defaults.

Always prefer these documents over assumptions.

---

## When To Update Documentation

If you:

- Change architecture
- Add or remove modules
- Modify invariants
- Alter configuration structure
- Add new API usage patterns
- Change expected behavior

You MUST:

1. Update the relevant documentation file.
2. Log the change in the active task.
3. Update `.tracking/meta.md` if file/function mappings change.

---

## Documentation Drift Rule

If documentation appears:
- Out of date
- Incomplete
- Inconsistent with code
- Missing critical information

You should:

- Inform the user.
- Offer to update or expand the documentation.
- Create a task if structural changes are needed.

Never silently ignore documentation drift.

---

## Quick Reference

When unsure:

- System behavior? → `architecture.md`
- Current work? → `meta.md` + active task file
- API usage? → `reascript_api_ref.md`
- Testing expectations? → `examples_and_testing.md`
- Configuration knobs? → `configuration.md`
- Design intent? → `project_brief.md`

---

Documentation exists to preserve intent.
If intent changes, documentation must change with it.
