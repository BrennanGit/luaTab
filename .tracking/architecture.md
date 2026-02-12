# Architecture Notes

This document is an advisory, project-agnostic place to capture:
- the shape of the system
- key invariants
- module responsibilities
- performance expectations
- integration boundaries

It is intentionally lightweight. Keep it accurate and useful; avoid over-documenting.

Last updated: {YYYY-MM-DD}

---

## 1) System Overview

### Purpose
{What the system does in one paragraph.}

### Non-Goals
- {What the system explicitly does not do.}

### Key User Flows
- {Flow 1: e.g., user triggers X → system does Y}
- {Flow 2}

---

## 2) High-Level Design

### Major Components / Modules
- **{Module A}** — {responsibility}
- **{Module B}** — {responsibility}
- **{Module C}** — {responsibility}

### Data Flow (Narrative)
{Describe how data moves through the system in 5–10 bullets.}

### External Dependencies / Integrations
- {Dependency} — {why it exists, version constraints if any}
- {API/service} — {how it’s used}

---

## 3) Interfaces and Contracts

### Public Interfaces (Stable)
- {API/function/config file} — {expected behavior}

### Internal Interfaces (Flexible)
- {Module boundary} — {what’s passed across and why}

### Data Models (If helpful)
- `{TypeName}` — fields and meaning (brief)

---

## 4) Invariants (Do Not Break)

List system truths that must remain correct. Examples:
- {Invariant about correctness}
- {Invariant about performance}
- {Invariant about ordering / consistency}
- {Invariant about safety / security}

---

## 5) Performance and Scaling Notes

### Expected Constraints
- {Latency/CPU constraints}
- {Memory constraints}
- {Typical input sizes}

### Caching Strategy (If any)
- {What is cached, keys, invalidation triggers}

---

## 6) Failure Modes and Recovery

- {Common failure mode} — {how to detect} — {recovery path}
- {Another failure mode}

---

## 7) Testing Strategy

### Unit / Pure Tests
- {What is tested without external dependencies}

### Integration / End-to-End
- {What needs real environment integration}

### Regression Checks
- {Short list of must-run checks before release}

---

## 8) Change Log (Optional)

- {YYYY-MM-DD} — {High-level architecture change} — {linked task #NNN}
