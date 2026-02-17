# Task #038: Playback Rhythm Gap + Note Highlighting

- ID: #038-tracking-playback-highlights
- Created: 2026-02-17 00:00 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #015, #024
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add three small playback-tracking improvements: configurable pre-note off gap on the fretboard, optional forced next-note highlight on fretboard, and optional current-note highlight in tab layout.

## Requirements
- Add a configurable pre-note off period before each note on the fretboard to reveal rhythm.
- Gap is measured in milliseconds and defaults to 50ms.
- Gap occurs before the next note so note attack remains on-beat.
- Add a fretboard checkbox: "highlight next note".
- When enabled, next note tint should be 50% of playing note color and should override next-note style dropdown.
- Add a settings/playback checkbox for highlighting the specific currently-playing note on tab layout.

## Acceptance Criteria
- [x] Fretboard visible note rendering includes a configurable pre-note off gap before note starts.
- [x] New gap setting persists via config and defaults to 50ms.
- [x] New fretboard checkbox forces next-note tint at 50% playing-note color regardless of style dropdown.
- [x] New tab-layout current-note highlight can be toggled in settings/playback.
- [x] Documentation updated for new settings.

## Plan
- [x] Locate and update playback timing and note-state logic used by fretboard and tab render paths.
  - Files: luaTab.lua, lib/render.lua
  - Functions: render.draw_fretboard(), render.draw_systems()
  - Verify: Confirm where active/current/next note state is computed and consumed.
- [x] Add and persist new config fields with sane clamps/defaults.
  - Files: lib/config.lua, luaTab.lua
  - Functions: config.load(), config.save(), clamp_config()
  - Verify: New settings survive reload and default values are applied.
- [x] Add settings UI controls (ms gap + two checkboxes) in existing playback/fretboard settings sections.
  - Files: luaTab.lua
  - Functions: draw_settings_panel()
  - Verify: Controls render and update config values live.
- [x] Implement render behavior changes for fretboard and tab layout highlighting.
  - Files: lib/render.lua
  - Functions: render.draw_fretboard(), render.draw_systems()
  - Verify: Rhythm gap appears before notes; forced next-note tint works; current tab note highlight toggles.
- [x] Update docs and tracking metadata, then run targeted validation.
  - Files: planning/configuration.md, .tracking/meta.md, .tracking/038-tracking-playback-highlights.md
  - Verify: No new Lua errors in changed files.

## Execution Log

* 2026-02-17 00:00 UTC Start-of-turn Context Recap:

  * Goal: Implement configurable fretboard pre-note off gap, forced next-note tint option, and tab current-note highlight toggle
  * Current State: No active task; existing fretboard next-note style is dropdown-driven; no pre-note rhythm gap setting
  * Blocking Issues: None
  * Next Subtask: Inspect render + config paths for current/next note drawing and timing logic
  * Known Risks: Timing logic may be shared with multiple visual modes; need to avoid regressions in existing styles

* 2026-02-17 00:08 UTC Added config defaults/load/save/reset for `fretboardPreNoteOffMs`, `fretboardHighlightNextNote`, and `tabHighlightCurrentNote`.

* 2026-02-17 00:12 UTC Updated fretboard panel and playback settings UI; wired pre-note off timing into fretboard current-note collection and render calls.

* 2026-02-17 00:15 UTC Implemented render changes: forced next-note tint override in fretboard and active-note background highlight in tab systems.

* 2026-02-17 00:16 UTC Updated `planning/configuration.md` and verified changed Lua files report no errors via `get_errors`.

* 2026-02-17 00:17 UTC Test attempt blocked: `lua tests/tests.lua` could not run because `lua` executable is not available in terminal PATH.

## Decisions

## Open Questions

## Risks
- Manual REAPER UI verification is required for final visual behavior validation.

## Useful Commands and Testing
- Run targeted Lua tests if available: tests/tests.lua
- Manual: play MIDI and observe fretboard/tab note state transitions.

## Artifacts Changed

- .tracking/038-tracking-playback-highlights.md
- .tracking/meta.md
- lib/config.lua
- lib/render.lua
- luaTab.lua
- planning/configuration.md

## Final Summary
Implemented three playback tracking improvements: configurable fretboard pre-note off gap (default 50ms), optional forced highlight for only the next fretboard note (50% current-note tint overriding style), and optional tab-layout highlight for currently playing assigned notes.
