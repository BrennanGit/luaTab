# luaTab

luaTab is a REAPER ReaScript that renders a live tablature HUD for MIDI material around the play or edit cursor.

It is aimed at stringed-instrument workflows such as mandolin and guitar, with configurable tuning, chord reduction, fret assignment, and a play-aware tab display built with ReaImGui.

<img width="1609" height="845" alt="image" src="https://github.com/user-attachments/assets/ef70c643-712d-4e40-9c37-4b7b321d4a52" />
<em>Main luaTab window open in darkmode with fretboard and settings windows docked</em>

## What It Does

- Follows playback in real time, or the edit cursor when stopped.
- Renders a moving tab window across previous and upcoming bars.
- Wraps bars into continuous systems instead of isolated measure boxes.
- Groups simultaneous MIDI notes into chord events.
- Maps pitches onto strings and frets using configurable playability rules.
- Reduces unplayable chords while preferring to keep the highest notes.
- Includes settings, preset, and fretboard UI built on ReaImGui.

This repository contains the script itself, the supporting Lua modules under `lib/`, and planning/reference documentation under `planning/` and `.tracking/`.

## Repository Layout

- `luaTab.lua`: entrypoint script REAPER runs.
- `lib/`: core modules for config, MIDI extraction, fret assignment, layout, rendering, and UI helpers.
- `planning/`: project intent, configuration notes, implementation plan, API notes, and testing guidance.
- `.tracking/`: task history and active-work tracking for contributors and agents.

## Install In REAPER

### Requirements

- REAPER 6 or newer.
- ReaImGui installed via ReaPack.

The script checks for ReaImGui on startup and exits with a message if it is missing.

### Setup Steps

1. Copy or clone this repository into your REAPER scripts directory.
2. Keep the folder structure intact so `luaTab.lua` can load modules from `lib/`.
3. In REAPER, open `Actions -> Show action list`.
4. Use `ReaScript: Load...` and select `luaTab.lua`.
5. Run the action to open the luaTab window.
6. Optional: add the action to a toolbar or assign a shortcut.

Typical Windows location:

```text
%APPDATA%\REAPER\Scripts\luaTab
```

If you keep the repo somewhere else while developing, make sure REAPER is loading the `luaTab.lua` from that working copy.

### First Run Notes

- luaTab is designed as a toggle-style script. Running it again requests the current instance to quit cleanly.
- The script stores settings in REAPER ExtState.

## Usage

Open the GUI using a REAPER action, toolbar button, or shortcut. The script looks for MIDI content on the selected track and renders a tab HUD from the notes around the play or edit cursor.

### GUI Layout

The main window shows the tab HUD which is a simple manuscript-style rendering of strings and frets.

The top strip contains a few key settings and preset dropdowns. On the right side is a button which allows you to toggle the optional windows, which are hidden by default to keep the interface clean and focused on the tab itself.

Optional windows include (at the moment, this is subject to change as the UI evolves):

- Settings: general configuration for GUI, playback, and tab calculation.
- Fretboard: a live playback visualizer showing the current notes on a fretboard diagram.
- Color Picker: a development/debug window for adjusting the colors used by the UI and renderer.
- User Presets: a window for saving and loading presets.

Windowing is managed by ReaImGui, so panels can be arranged, resized, docked, or hidden freely.

You can save a preferred layout by saving a preset, which captures window positions and sizes along with the rest of the selected settings.

> Note: Window positions can currently be saved, but docked vs undocked state is not restored. Saving a preset after docking a panel will preserve its position, but not its docked state.

### Presets

To enable quick switching between different configurations, you can save presets which capture different groups of settings.

#### Tuning

The tuning of the strings, which can be set to any MIDI pitch. This is used for calculating the fret positions for each note.
Name the preset something descriptive of the tuning, like "Standard Guitar" or "Open D".

#### Colors

The color scheme for the GUI elements. Added for development, but also useful for light/dark modes or high-contrast setups.

<img width="1615" height="849" alt="image" src="https://github.com/user-attachments/assets/5b4c7157-67a8-4afe-9640-30454f2638ce" />
<img width="1616" height="847" alt="image" src="https://github.com/user-attachments/assets/aa4f4ef5-cea1-4571-b006-e8109216644f" />
<em>luaTab in standard light mode and in a modified dark mode with the strings set to red</em>

#### Style

Windowing and playback behavior settings grouped together. This includes the number of bars shown in the tab window, how many upcoming notes to show in the fretboard, and whether to follow playback or the edit cursor. It also includes window positions and sizes, so you can set up a preferred layout and save it as a preset.

This is useful for switching between different working modes, such as a full-page manuscript view that "turns" at the end of a section or a long narrow layout that emphasizes continuous playback with the fretboard visible underneath.

<img width="2547" height="1207" alt="image" src="https://github.com/user-attachments/assets/d907a097-e0d5-43e1-99c6-fe1565673fdc" />
<em>This shows a layout with the luaTab window docked into Reaper, set up with a continuous scroll and a fretboard </em>


### Tab Calculation

The script extracts MIDI notes from items on the selected track and then uses a playability-oriented assignment pass to work out how they can be played on the current string set.

The settings under `Settings -> Tab` let you adjust weights for things like avoiding string skips, preferring higher retained notes, or setting the timing distance within which notes should be considered part of the same chord. That makes it possible to tune the behavior for different instruments and material.

Currently there is no way to override the automatic fret assignment with manual input, but that might be something to explore in the future.

## Development Workflow

This project is primarily intended for personal use, but it is open source and contributions are welcome.

As a pure REAPER scripting project, the development workflow is centered around making changes in the code and then validating those changes directly in REAPER. There is no build step or test suite, so the feedback loop is very direct: change code, run in REAPER, see how it behaves.

It is also an experiment in using structured planning and tracking documentation to keep work grounded and reduce context loss across sessions in an AI assisted project. The documentation files under `planning/` and `.tracking/` are intended to be an addressable source of truth for the project intent, architecture, configuration, testing, active work and task history.

If you break the GUI, you can delete all settings and reset the plugin by creating a file name `luaTab.reset` in the script directory and starting the application.

### Recommended Loop

1. Open the repo in your editor.
2. Edit `luaTab.lua` or modules under `lib/`.
3. Run the script from REAPER.
4. Re-run after changes to validate behavior in the host.

Because this is REAPER scripting work, the real integration environment is REAPER itself. Most meaningful checks are interactive: playback follow, bar wrapping, note assignment, settings UI, and fretboard behavior.

### Validation

Validation for this project is centered on REAPER itself.

For development changes, a practical validation pass is:

1. Run the affected workflow in REAPER.
2. Check playback follow, bar wrapping, note assignment, and panel behavior directly in the host.
3. Use `planning/examples_and_testing.md` as the source of regression scenarios for manual checks.

### Useful Planning Docs

- `planning/project_brief.md`: product goal and core behavior.
- `planning/implementation_plan.md`: module layout and data flow.
- `planning/configuration.md`: user-facing settings and defaults.
- `planning/examples_and_testing.md`: regression scenarios and testing ideas.
- `planning/reascript_api.md`: REAPER API notes collected for the project.

## Planning And Tracking System

This repo uses two documentation layers to keep work grounded:

- `planning/` describes the product, architecture direction, configuration, and test expectations. This is targeted by the instruction file in `.github/instructions/project.instructions.md` and should be updated when behavior, architecture, or project expectations change.
- `.tracking/` records active work, execution logs, acceptance criteria, and task history. This is targeted by the instruction file in `.github/instructions/plan.instructions.md` and should be updated for any non-trivial work that changes behavior, structure, or contributor expectations.

If you are changing behavior, structure, or contributor expectations:

1. Check `.tracking/meta.md` first.
2. Create or update the active task file in `.tracking/` for non-trivial work.
3. Keep the plan, execution log, and final summary current while you work.
4. Update `planning/` docs when behavior or architecture changes.

The goal is simple: future contributors and future agents should be able to understand what changed, why it changed, and what still needs attention without reconstructing that context from scratch.

<< IMAGE: example of the README planning/tracking workflow with planning docs and .tracking task files >>

## Contribution Guidance For Agents And Humans

- Prefer small, traceable changes over broad undocumented refactors.
- Use the existing planning docs before making assumptions about intended behavior.
- Treat `.tracking/meta.md` and the active task file as part of the work, not optional paperwork.
- When implementation changes invalidate docs, update the docs in the same pass.
- Use the instruction files in `.github/instructions/` as a guide for what to update and when.

## Current Status

luaTab is in early development. The core architecture is in place, but the script is not yet complete or polished. The planning docs and tracking system are intended to keep the work organized and transparent as it evolves.

There are deeper and more experimental controls currently exposed that may not all survive into a final polished version, but they are useful for testing and exploration right now.

