---
applyTo: "**"
---

# Workspace Task Tracking Protocol (Agent Mode)

## Purpose

Maintain durable, navigable task memory across sessions using `.tracking/`.

This protocol ensures:
- Work is structured and reproducible.
- Context limits are managed safely.
- Architectural intent is preserved.
- Refactors do not silently break invariants.

This system is project-agnostic and may be reused across repositories.

---

# Core Principles

1. Plan before editing.
2. Log every meaningful change. If the request would change how a future agent understands the system, it requires a task entry.
3. Verify before ticking.
4. Keep recaps short and structured.
5. Never rely on memory — rely on `.tracking/`.
6. One active task at a time unless explicitly stated.

---

# Folder Conventions

- Tracking folder: `.tracking/` (create if missing)
- Task file: `.tracking/NNN-short-slug.md`
- Meta index: `.tracking/meta.md`
- Optional system-level documentation: `.tracking/architecture.md`

If `.tracking/architecture.md` exists, read it before making structural changes.

---

# Active Task Rule

`.tracking/meta.md` must contain:

```md
## Active Task

Current: #NNN-short-slug
```


Rules:
- Only one task may be marked as Current.
- If a task is in-progress, it must be listed as Current.
- Switching tasks requires updating `meta.md`.

---

# When To Create A Task

On any non-trivial request (multi-file changes, logic changes, API changes, structural refactors):

You MUST:
1. Create a new task file before editing code.
2. Add it to `meta.md`.
3. Set status = planned.
4. Set it as Active Task.

Exceptions:
- Pure documentation edits.
- Minor typo fixes.
- Small isolated formatting changes.

If unsure → create a task.

---

# Task File Requirements

Each task file MUST include:

- ID
- Created timestamp (UTC)
- Status: planned | in-progress | blocked | done
- Type: feature | refactor | bugfix | research | docs | infra
- Stability: experimental | beta | stable
- Owner
- Related task IDs
- Summary
- Requirements
- Acceptance Criteria
- Out of Scope
- Plan (with checkboxes)
- Execution Log
- Decisions
- Open Questions
- Risks
- Artifacts Changed
- Final Summary

Optional but recommended:
- Design Contracts (system invariants)
- Regression Checklist
- Snippet Cache (≤100 lines total)

---

# Execution Workflow

## 1. Create Task

- Determine next NNN (zero-padded).
- Create `.tracking/NNN-short-slug.md` from template.
- Add entry to `.tracking/meta.md`.
- Set status = planned.
- Set as Active Task.

---

## 2. Plan

Break work into checklist subtasks:

Each subtask must:
- Reference expected files.
- Reference expected functions.
- Include verification steps.

Do not begin editing code until Plan exists.

---

## 3. Execute

For each subtask:

- Make change.
- Log timestamped entry in Execution Log:
  - What changed
  - Files touched
  - Why
- Verify via tests/manual check.
- Only then tick checkbox.

If plan changes:
- Update Plan section.
- Update meta.md if scope shifts.

---

## 4. Context Discipline (Every Turn)

At start of each session:

1. Read:
   - `.tracking/meta.md`
   - Active task file
   - `.tracking/architecture.md` (if exists)

2. Append to Execution Log:

```md
Start-of-turn Context Recap:
Goal:
Current State:
Blocking Issues:
Next Subtask:
Known Risks:
```


3. In chat, include a 3–5 bullet recap.

Keep recaps concise. No rambling.

---

## 5. Refactoring Safeguards

Before deleting or replacing code:

- Confirm it is not referenced in:
  - Active task Snippet Cache
  - Any unfinished task in meta.md
- If replacing logic, document the reason in Decisions.

If architectural intent changes:
- Create a new task (do not silently expand scope).

---

## 6. Blocked State

If blocked for more than two turns:

- Set Status = blocked.
- Add explicit Open Questions.
- Do not guess requirements.
- Wait for clarification.

---

## 7. Cleanup

Before marking task complete:

- Remove obsolete code and references.
- Move test files to correct location.
- Remove temporary scaffolding.
- Update README.md if behavior changed.
- Update `meta.md`:
  - Status
  - Files affected
  - Function map
  - Cross-references

---

## 8. Completion

When finished:

- Set Status = done.
- Clear Active Task pointer.
- Add Final Summary.
- Note follow-up tasks explicitly.

---

# Meta Index Requirements (`meta.md`)

Each task entry must include:

```md
[status] NNN-short-slug — Title (YYYY-MM-DD) — Owner
Type: feature | refactor | bugfix | research | docs | infra
Stability: experimental | beta | stable
Files: path1, path2
Functions: f1(), f2()
Related: #MMM
```

And:

```md
## Active Task
Current: #NNN-short-slug
```


---

# Optional: architecture.md

If present, `architecture.md` should describe:

- System modules
- Data flow
- Key invariants
- Performance constraints

It is advisory, not mandatory.
If missing, do not create unless architectural complexity justifies it.

---

# Safeguards

- If numbering collision occurs → choose next available.
- If required file missing → create minimal stub.
- If user edited files between sessions → re-read before modifying.
- Snippet Cache must not exceed 100 lines.

---

# Trigger Phrase

If a prompt contains `#plan`, the full protocol MUST be followed.

---

# Self-Reminder

At the top of every task file:

- Read meta.md first; update it last.
- Plan before editing; verify before ticking.
- Log every change; keep recaps short.
- Reference prior tasks; avoid duplicate work.
- Remove obsolete code.
