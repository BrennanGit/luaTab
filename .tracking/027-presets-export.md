# Task #027: Preset Save + Export

- ID: #027-presets-export
- Created: 2026-02-16 03:10 UTC
- Status: done
- Type: feature
- Stability: experimental
- Owner: agent
- Related: #024
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Add user preset saving for tuning and color presets with overwrite warnings, separate default vs user presets, and export current settings to the REAPER console.

## Requirements
- Add "Save current as preset" for tuning and color presets with a name modal.
- Warn before overwriting an existing preset name.
- Default presets remain separate from user presets and return on reset.
- Add "Export settings" button to show a complete settings string in the console.

## Acceptance Criteria
- [x] Tuning preset save flow writes user presets and shows warning on overwrite.
- [x] Color preset save flow writes user presets and shows warning on overwrite.
- [x] Reset defaults restores default presets and clears user presets.
- [x] Export settings outputs all current settings to the REAPER console.
- [x] Configuration docs updated for presets/export behavior.

## Plan
- [x] Add user preset load/save helpers and export string generator — Files: luaTab.lua — Functions: draw_ui(), new preset helpers
- [x] Persist/clear user presets on reset — Files: lib/config.lua — Functions: config.reset()
- [x] Update settings UI for save/export actions — Files: luaTab.lua — Functions: draw_ui()
- [x] Update documentation and tracking metadata — Files: planning/configuration.md, .tracking/meta.md, .tracking/027-presets-export.md

## Execution Log

* 2026-02-16 08:30 UTC Start-of-turn Context Recap:

	* Goal: Review open tasks and close the presets/export work if complete
	* Current State: Preset save/export and reset behavior are implemented; docs updated
	* Blocking Issues: None
	* Next Subtask: Close task and update tracking metadata
	* Known Risks: Manual verification not run in REAPER UI

* 2026-02-16 07:05 UTC Start-of-turn Context Recap:

	* Goal: Restore collapsible settings headers and align fretboard header labels
	* Current State: Fretboard header labels are left-aligned; settings headers are static
	* Blocking Issues: None
	* Next Subtask: Reintroduce collapsible headers without close buttons
	* Known Risks: Header layout regressions in the settings modal

* 2026-02-16 06:45 UTC Start-of-turn Context Recap:

	* Goal: Restore collapsible settings headers without close buttons and adjust fretboard header labels
	* Current State: Settings sections are static and fretboard header labels are right-aligned
	* Blocking Issues: None
	* Next Subtask: Reintroduce CollapsingHeader sections and update fretboard header controls
	* Known Risks: Large settings block change could introduce layout regressions

* 2026-02-16 06:20 UTC Start-of-turn Context Recap:

	* Goal: Rename scale presets to style and reorganize settings/fretboard UI
	* Current State: Scale preset naming still present; settings use collapsible sections
	* Blocking Issues: None
	* Next Subtask: Update preset naming, move fretboard settings to window header, reorder settings sections
	* Known Risks: Ensure new style preset keys persist correctly

* 2026-02-16 05:55 UTC Start-of-turn Context Recap:

	* Goal: Include fretboard roundness in style presets and clarify naming
	* Current State: Scale presets omit note roundness; UI labels use "Scale"
	* Blocking Issues: None
	* Next Subtask: Expand scale keys and adjust labels
	* Known Risks: None

* 2026-02-16 05:30 UTC Start-of-turn Context Recap:

	* Goal: Fold fretboard controls into Styling and expand scale presets
	* Current State: Fretboard section owns most controls; scale presets exclude fretboard scaling
	* Blocking Issues: None
	* Next Subtask: Add fretboard scaling keys to scale presets and move UI blocks
	* Known Risks: Ensure scaleChanged triggers on moved controls

* 2026-02-16 04:40 UTC Start-of-turn Context Recap:

	* Goal: Split styling preset buttons and add scale presets/dropdown
	* Current State: Styling has a single ambiguous save button and no scale presets
	* Blocking Issues: None
	* Next Subtask: Add scale preset persistence and UI controls
	* Known Risks: Must persist scalePreset and user scale presets correctly

* 2026-02-16 04:22 UTC Start-of-turn Context Recap:

	* Goal: Remove confusing Custom preset entry and flip tuning UI order
	* Current State: Tuning dropdown shows a Custom option that does nothing; tuning inputs show low-to-high
	* Blocking Issues: None
	* Next Subtask: Adjust preset list build and tuning UI loop
	* Known Risks: Preset list rebuild must stay in sync with cfg.tuningPreset

* 2026-02-16 04:05 UTC Start-of-turn Context Recap:

	* Goal: Fix preset save crash and keep presets working in-session
	* Current State: Saving preset errors with nil apply_settings_change
	* Blocking Issues: None
	* Next Subtask: Add forward declaration for apply_settings_change
	* Known Risks: None

* 2026-02-16 03:10 UTC Start-of-turn Context Recap:

	* Goal: Implement preset saving and settings export
	* Current State: Preset handling is default-only; no export
	* Blocking Issues: None
	* Next Subtask: Add user preset load/save helpers in luaTab.lua
	* Known Risks: ExtState key cleanup needs to be consistent

* 2026-02-16 03:40 UTC Added user preset load/save helpers, modal flow, and export string formatter.

* 2026-02-16 03:44 UTC Cleared user preset keys on reset in config.reset().

* 2026-02-16 03:48 UTC Wired settings UI buttons and updated configuration documentation.

* 2026-02-16 03:50 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 04:08 UTC Fixed preset save crash by forward-declaring apply_settings_change.

* 2026-02-16 04:09 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 04:24 UTC Hid the Custom preset unless active and flipped the tuning editor order.

* 2026-02-16 04:25 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 05:10 UTC Added scale presets (default + user) with dropdown and save button, plus clarified styling save buttons.

* 2026-02-16 05:12 UTC Updated config persistence and documentation for scale presets.

* 2026-02-16 05:13 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 05:42 UTC Moved fretboard controls into Styling and expanded scale preset scope.

* 2026-02-16 05:44 UTC Increased preset save modal size and renamed display labels.

* 2026-02-16 05:45 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 05:58 UTC Added fretboard roundness/frets to style presets and relabeled scale UI to style.

* 2026-02-16 05:59 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 06:28 UTC Renamed scale presets to style presets (keys + UI) and reorganized settings sections.

* 2026-02-16 06:30 UTC Moved fretboard display controls into the fretboard window header and removed the settings fretboard section.

* 2026-02-16 06:31 UTC Verification: not run (requires REAPER UI).

* 2026-02-16 07:07 UTC Restored collapsible headers for settings sections without close buttons.

* 2026-02-16 07:07 UTC Verification: not run (requires REAPER UI).

## Decisions

- Default-name collisions warn and require confirmation; saving still creates a user preset with that name.

## Open Questions

- None.

## Risks

- Preset key cleanup could leave stale ExtState entries if not fully cleared.

## Useful Commands and Testing

- Manual: Save tuning/color presets, verify warning, reload, reset defaults, export settings.

## Artifacts Changed

- luaTab.lua
- lib/config.lua
- planning/configuration.md
- .tracking/meta.md
- .tracking/027-presets-export.md

## Final Summary

- Added user preset save flows with overwrite confirmation, reset cleanup, and export-to-console output.
- Updated configuration docs and preset list rebuilding to keep defaults and user presets separate.
- Verification not run (requires REAPER UI).
