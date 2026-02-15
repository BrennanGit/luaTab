# Architecture Notes

This document is an advisory, project-agnostic place to capture:
- the shape of the system
- key invariants
- module responsibilities
- performance expectations
- integration boundaries

It is intentionally lightweight. Keep it accurate and useful; avoid over-documenting.

Last updated: 2026-02-15

---

## 1) System Overview

### Purpose
Render a live, play-aware tablature HUD for MIDI content around the play/edit cursor in REAPER using ReaImGui.

### Non-Goals
- Preloading next items (v1 extension)
- Tie/hold markers
- Export or alternate fingerings

### Key User Flows
- User runs luaTab -> UI appears -> tool follows cursor and renders tab
- User edits MIDI -> tab updates on bar change

---

## 2) High-Level Design

### Major Components / Modules
- **luaTab.lua** — main loop, UI, caching, orchestration
- **lib/config.lua** — defaults, ExtState load/save
- **lib/timeline.lua** — bar window + time signature data
- **lib/layout.lua** — system wrapping and bar layout
- **lib/midi.lua** — active take selection, note extraction, event grouping
- **lib/source.lua** — take resolution from selected track or MIDI editor
- **lib/frets.lua** — candidate generation, solver, reduction
- **lib/render.lua** — draw strings, barlines, notes, time signatures
- **lib/util.lua** — helpers

### Data Flow (Narrative)
- Get cursor time (play or edit)
- Build bar window for prev/next range
- Build systems layout based on window width
- Extract MIDI notes in bar window and group into events
- Solve fret assignments per event with span constraints
- Render strings, barlines, time signatures, and frets

### External Dependencies / Integrations
- REAPER ReaScript API — time map, MIDI access, cursor position
- ReaImGui (ReaPack) — UI and draw list rendering

---

## 3) Interfaces and Contracts

### Public Interfaces (Stable)
- config.load()/config.save() — persistent settings via ExtState
- timeline.build_bars() — bar window with time signatures
- layout.build_systems() — wrapped system layout

### Internal Interfaces (Flexible)
- midi.extract_notes()/midi.group_events() — notes to events for render
- frets.assign_event() — event pitches to string/fret assignments

### Data Models (If helpful)
- `Bar` — idx, t0, t1, num, den, showTimeSigHere
- `Event` — t, notes[], assignments[], dropped[]

---

## 4) Invariants (Do Not Break)

- Open strings do not contribute to fretted span
- One note per string in an assignment
- Rebuild MIDI/event cache only on bar/take change

---

## 5) Performance and Scaling Notes

### Expected Constraints
- Avoid scanning all MIDI every frame
- Typical bar window is small (few measures)

### Caching Strategy (If any)
- Cache bar window and event assignments; rebuild on bar change or take change

---

## 6) Failure Modes and Recovery

- ReaImGui missing — show message and exit
- No active MIDI take — render empty staff

---

## 7) Testing Strategy

### Unit / Pure Tests
- frets and layout tests in tests/tests.lua

### Integration / End-to-End
- REAPER session with active MIDI editor take

### Regression Checks
- L02 (wrap), T02 (time signature), M02 (double stops), F02/F04 (span/reduction)

---

## 8) Change Log (Optional)

- {YYYY-MM-DD} — {High-level architecture change} — {linked task #NNN}
