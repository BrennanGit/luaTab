# Configuration

This document lists:
- all user-facing configuration knobs (UI)
- “styling sheet” constants (visual defaults)
- persistence and optional config file formats

Project philosophy:
- Keep stable styling and defaults out of the main logic.
- Store user-adjustable settings in ExtState.
- Optionally support a config file for presets (later).

---

## 1. Configuration Sources and Persistence

### 1.1 Runtime config (UI)
- Stored in memory during session
- Saved to REAPER ExtState on change (or on close)

Recommended:
- `reaper.SetExtState("luaTab", key, value, true)`

### 1.2 Presets (optional)
Later: allow export/import of presets (tuning + weights + layout).
For offline simplicity, a simple key-value format or JSON can be used.

---

## 2. User-Facing Knobs (UI)

### 2.1 Cursor follow
- `followPlay` (bool): follow play cursor when playing
- `followEditWhenStopped` (bool): follow edit cursor when not playing
- `lockToBar` (bool, optional): update only when crossing a barline

### 2.2 Visible range
- `prevBars` (int): number of bars before current to render
- `nextBars` (int): number of bars after current to render

### 2.3 MIDI source selection
MVP:
- `sourceMode = "active_midi_editor"`

V1:
- `sourceMode = "selected_track_under_cursor"`
- `sourceTrackIndex` (int) or “selected track”
- `channelFilter` (int or “all”)

### 2.4 Event grouping
- `groupEpsilonMs` (float): notes starting within this time are considered simultaneous
- `minNoteLenMs` (float, optional): ignore ultra-short notes (ornaments) if needed

### 2.5 Tuning
- `strings[]` list:
  - `name` (string label, e.g., G D A E)
  - `open` (MIDI pitch number, e.g., 55)
- `sortStringsLowToHigh` button/action
- `tuningPreset` (enum): common presets like mandolin GDAE

### 2.6 Playability constraints
- `maxFret` (int)
- `maxSimul` (int): maximum simultaneous notes (usually == string count)
- `maxFrettedSpan` (int): max stretch in frets (span ignores open strings)
- `openStringsFree = true` (fixed choice for this project)

### 2.7 Assignment preferences (weights)
- `weights.lowFret` (0..10): prefer low frets
- `weights.stayOnString` (0..10): hysteresis
- `weights.stringJump` (0..10): penalize string changes
- `weights.fretJump` (0..10): penalize fret jumps
- `weights.highFret` (0..10): penalize high frets

### 2.8 Reduction policy
Fixed choice:
- `reducePreferHighest = true` (keep highest notes when chord unplayable)

UI option (later):
- switch between “prefer highest” and “prefer lowest”

### 2.9 Preloading (V1)
- `preloadSeconds` (float): threshold before item end to preload next item
- `maxCachedItems` (int): LRU cap
- `mergeOverlaps` (bool): how to handle overlapping items (default true)

---

## 3. Styling Sheet (Visual Defaults)

These are mostly stable and should live in a separate module (e.g., `style.lua`).

### 3.1 Layout constants
- `systemGutterPx` (default ~60)
- `barPrefixPx` (default ~16)
- `barContentPx` (default ~120)
- `barGutterPx` (default ~8)
- `systemRowGapPx` (default ~16)
- `staffPaddingTopPx` (default ~10)
- `staffPaddingBottomPx` (default ~10)
- `stringSpacingPx` (default ~14)

### 3.2 Typography
- `fontFretSize` (int)
- `fontTimeSigSize` (int)
- `fontSmallSize` (int)
(Implementation note: ReaImGui font handling can be left default initially.)

### 3.3 Drawing thickness
- `stringLineThickness` (float)
- `barLineThickness` (float)
- `itemBoundaryThickness` (float)
- `beatTickThickness` (float)

### 3.4 Colors
- `colText` (default)
- `colStrings` (subtle)
- `colBarlines` (slightly stronger)
- `colDropped` (red)
- `colDebug` (optional)

Note: Colors should be converted to ImGui U32 once and cached.

### 3.5 Rendering options
- `showBeatTicks` (bool)
- `showBarNumbers` (bool)
- `showFirstTimeSigInSystemGutter` (bool) (chosen: yes)
- `centerFretTextOnLine = true` (chosen)
- `openStringsStyle = normal` (chosen)

---

## 4. Suggested Config File Format (Optional)

If supporting presets outside ExtState, keep it simple:

### 4.1 INI-style
Example:

prevBars=1
nextBars=2
maxFret=15
maxFrettedSpan=4

string0_name=G
string0_open=55
string1_name=D
string1_open=62
...

### 4.2 JSON (optional)
Only if a small JSON encoder/decoder is included.

---

## 5. Recommended Presets

### Mandolin (default)
- strings: G3=55, D4=62, A4=69, E5=76
- maxFret: 15
- maxFrettedSpan: 4
- weights: lowFret=8, stayOnString=6, stringJump=4, fretJump=4, highFret=2
- reducePreferHighest=true
- openStringsFree=true

### Guitar (later preset)
- strings: E2=40, A2=45, D3=50, G3=55, B3=59, E4=64
- maxFret: 22
- maxFrettedSpan: 4
- maxSimul: 6
- weights: lowFret=8, stayOnString=6, stringJump=4, fretJump=4, highFret=2
- reducePreferHighest=true
- openStringsFree=true

