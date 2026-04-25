# Task #048: Source and MIDI Filter Controls

- ID: #048-source-filter-controls
- Created: 2026-04-25 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #047
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add explicit MIDI source and filtering controls so luaTab behaves predictably in real REAPER sessions with multiple tracks, channels, ornaments, and editor states.

## Requirements
- Add source mode configuration for automatic, selected-track, and MIDI-editor selection.
- Add channel filter configuration with all/1-16 modes.
- Add minimum note length filtering for ornament cleanup.
- Preserve existing automatic behavior as the default.
- Keep filtering testable outside REAPER where possible.

## Acceptance Criteria
- [x] Config load/save/reset includes source mode, channel filter, and minimum note length.
- [x] Source resolution respects configured source mode.
- [x] MIDI extraction can filter by channel and minimum note length.
- [x] Settings UI exposes the new controls.
- [x] Lua 5.3 tests cover pure filter behavior.

## Plan
- [x] Extend config defaults and persistence metadata.
  - Files: lib/config.lua, planning/configuration.md
  - Functions: config.load(), config.save(), config.reset()
  - Verify: Lua 5.3 config tests or syntax check.
- [x] Add source-mode-aware take resolution.
  - Files: lib/source.lua, luaTab.lua
  - Functions: source.get_take(), rebuild_data(), draw_ui()
  - Verify: code review plus REAPER validation scenario.
- [x] Add channel and minimum-length filters in MIDI extraction.
  - Files: lib/midi.lua, luaTab.lua
  - Functions: extract_notes(), collect_window_notes()
  - Verify: Lua 5.3 tests for pure filter predicate; syntax check.
- [x] Update docs and tracking metadata.
  - Files: README.md, planning/configuration.md, .tracking/meta.md
  - Verify: docs match UI/config names.

## Execution Log

* 2026-04-25 UTC Start-of-turn Context Recap:
  * Goal: implement explicit source selection, channel filtering, and minimum note length filtering after completing manual overrides.
  * Current State: `source.get_take()` uses automatic selected-track then editor fallback; `midi.extract_notes()` extracts every note in the visible window; config docs mention source/filter knobs but code does not yet persist them.
  * Blocking Issues: source-mode behavior requires REAPER validation; pure filter behavior can be tested locally.
  * Next Subtask: extend config persistence and add pure MIDI filter helpers.
  * Known Risks: preserving current automatic behavior while adding explicit modes.

* 2026-04-25 UTC Added `sourceMode`, `channelFilter`, and `minNoteLenMs` defaults plus config persistence/reset coverage.

* 2026-04-25 UTC Split source resolution so `source.get_take(t, mode)` supports `auto`, `selected_track`, and `midi_editor` while preserving the original automatic behavior as default.

* 2026-04-25 UTC Added `midi.note_passes_filters()` and threaded channel/min-length filters through `midi.extract_notes()` and the rebuild collection path.

* 2026-04-25 UTC Added Settings -> Tab controls for source mode, channel filter, and minimum note length, and documented the behavior in README/configuration docs.

* 2026-04-25 UTC Verification:
  * `.\\lua53\\lua53.exe tests\\run.lua` passed with 6 tests, including channel and minimum-length filter coverage.
  * Editor diagnostics reported no errors in `luaTab.lua`, `lib/config.lua`, `lib/midi.lua`, `lib/source.lua`, or `tests/run.lua`.
  * REAPER validation remains required for actual source resolution against selected tracks and active MIDI editor state.

## Decisions
- Keep `sourceMode = "auto"` as the default to preserve existing selected-track-then-editor behavior.

## Open Questions

## Risks
- Selected-track-only and editor-only modes need REAPER validation because source discovery is API-bound.

## Useful Commands and Testing
- `.\\lua53\\lua53.exe tests\\run.lua`

## Artifacts Changed
- lib/config.lua
- lib/source.lua
- lib/midi.lua
- luaTab.lua
- tests/run.lua
- README.md
- planning/configuration.md
- .tracking/048-source-filter-controls.md

## Final Summary
Source and MIDI filter controls are implemented. The default `auto` mode preserves existing selected-track/editor fallback, explicit modes can force selected-track or MIDI-editor source resolution, and extraction now supports one-based channel filtering plus minimum note length cleanup. Pure filter behavior is covered by Lua 5.3 tests; source-mode API behavior still needs REAPER validation.
