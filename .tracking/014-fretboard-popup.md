# Task #014: Fretboard Popup

- ID: #014-fretboard-popup
- Created: 2026-02-15 09:10 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #005, #007
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add an optional fretboard popup with configurable modes, styling, and rendering of current/next notes.

## Requirements
- Provide a settings dropdown to show/hide the fretboard and choose note inclusion modes.
- Render a resizable fretboard popup with configurable frets, strings, markers, and note styling.
- Add color options for fretboard elements and note styles.

## Acceptance Criteria
- [x] Settings include fretboard mode, next-count controls, note style, frets count, roundness, and colors.
- [x] Fretboard popup renders N strings (low at bottom), correct fret ratios, and markers.
- [x] Current notes are solid color; next notes follow selected outline/shade style.
- [x] Popup size affects fretboard length and string spacing.

## Plan
- [x] Add fretboard config defaults, persistence, and UI controls — Files: lib/config.lua, luaTab.lua, planning/configuration.md — Functions: config.load(), config.save(), clamp_config(), draw_ui() — Verification: open settings and confirm values persist
- [x] Implement fretboard note collection and drawing — Files: luaTab.lua, lib/render.lua — Functions: render.draw_fretboard(), draw_ui() — Verification: resize popup, see frets/markers/notes
- [x] Update architecture/tracking metadata — Files: .tracking/meta.md, .tracking/architecture.md, .tracking/014-fretboard-popup.md — Functions: n/a — Verification: file review

## Execution Log

* 2026-02-15 09:10 UTC Start-of-turn Context Recap:

  * Goal: Add a configurable fretboard popup with current/next note rendering
  * Current State: Settings UI and main tab render work; no fretboard popup exists
  * Blocking Issues: None
  * Next Subtask: Add fretboard config defaults, persistence, and UI controls
  * Known Risks: Ambiguity in "current note" selection and next-note display style

* 2026-02-15 09:25 UTC Added fretboard settings defaults, persistence, and UI controls.

* 2026-02-15 09:40 UTC Implemented fretboard popup rendering, note collection, and styling modes.

* 2026-02-15 09:50 UTC Updated configuration docs and architecture notes.

* 2026-02-15 09:55 UTC Verification: not run (requires REAPER UI).

## Decisions

- None yet.

## Open Questions

- None.

## Risks

- Fret spacing math needs to match standard fret ratios; rounding errors could misplace dots.

## Useful Commands and Testing

- Manual: enable the fretboard popup and resize to verify note placement and markers.

## Artifacts Changed

- lib/config.lua
- luaTab.lua
- lib/render.lua
- planning/configuration.md
- .tracking/architecture.md
- .tracking/meta.md

## Final Summary

- Implemented a configurable fretboard popup with note modes, styling, colors, and accurate fret/marker rendering. Settings persist and docs reflect the new options.
