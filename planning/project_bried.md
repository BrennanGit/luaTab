# Project Brief: REAPER “Tab HUD” (Polyphonic, Play-Aware)

## Goal

Build a **ReaScript (Lua + ReaImGui)** tool that displays a dynamic, resizable tablature view of MIDI content around the play/edit cursor.

The tool should:

* Follow playback (or edit cursor when stopped)
* Display configurable numbers of bars before and after the current bar
* Render tab in a joined, sheet-like layout (not tile blocks)
* Support chords and double stops
* Solve fret assignments intelligently
* Gracefully reduce unplayable chords
* Preload upcoming MIDI items to avoid visual dropouts

Target instruments: **Mandolin (GDAE)** **Guitar (EADGBe)**
System must support configurable N-string tunings.

---

# Core Behavior Specification

## Cursor Following

* If playing: follow `GetPlayPosition()`
* If stopped:

  * If config `followEditWhenStopped == true`: use `GetCursorPosition()`
* Bar range should update only when entering a new bar (optional smoothing optimization)

---

# Display Model

## Bars Shown

Configurable:

* `prevBars = Np`
* `nextBars = Nn`

Displayed bars:
`currentBar - Np` through `currentBar + Nn`

---

# Layout Model

## Overall Philosophy

The tab should look like continuous sheet music:

* String lines are continuous across each row (system)
* Bars are divided by vertical barlines
* No visible tiling/boxing
* Systems wrap automatically based on window width

---

## System Layout

Each system row consists of:

* Left system gutter (`systemGutterPx`)
* A sequence of bars
* Bars wrap to new row when width exceeded

### Bar Geometry

Each bar has fixed width:

```
barTotalWidth = barPrefixPx + barContentPx
```

* `barPrefixPx` = reserved symbol area (time sig changes etc.)
* `barContentPx` = area where notes are drawn

Within a system:

```
barLeft = systemGutter + k * (barTotalWidth + barGutterPx)
```

---

## Time Signature Rendering Rules

* Time signature appears:

  * At the first bar in a system (if enabled)
  * Whenever it changes mid-system
* Time signature drawn:

  * In left system gutter if it is first bar in system AND config says so
  * Otherwise in that bar’s prefix region
* All bars always reserve prefix space (even if empty)

---

# Tab Rendering

## Strings

* N strings
* Horizontal lines drawn across entire system
* String order: low → high vertically (bottom = lowest pitch string)

## Note Placement

For each event in bar:

```
frac = (eventTime - barStart) / barDuration
x = contentLeft + frac * barContentWidth
```

Fret number drawn at:

* x coordinate
* y coordinate corresponding to string index

Chords:

* Notes vertically aligned
* Slight x-offset per note to avoid text overlap

---

# MIDI Extraction

## Source Modes

Initial MVP:

* Active MIDI editor take

Later extension:

* Selected track item under cursor
* Preloading next item

---

## Event Grouping

* Notes grouped by start time (within small epsilon)
* Each group forms one Event
* Event may contain 1..N pitches

---

# Fret Mapping System

## Tuning

Configurable list of strings:

Example default:

```
[
 {name="G", open=55},
 {name="D", open=62},
 {name="A", open=69},
 {name="E", open=76}
]
```

Strings sorted low → high pitch.

---

## Candidate Generation

For pitch p and string open o:

Valid if:

* p >= o
* p - o <= maxFret

Candidate:

```
{stringIndex, fret = p - o}
```

---

## Stretch Constraint

Parameter:
`maxFrettedSpan`

Rule:

* Only fretted notes (fret > 0) count toward span
* Span = max(fretted) - min(fretted)
* Reject if span > maxFrettedSpan
* Open strings do NOT increase span

---

## Assignment Constraints

Hard:

* One note per string
* fret <= maxFret
* span constraint satisfied
* maxSimul <= number of strings

Soft (weighted scoring):

* Prefer lower frets
* Prefer staying on same string
* Penalize string jumps
* Penalize large fret jumps
* Slight penalty for high frets

---

## Chord Reduction Logic

If full chord not playable:

1. Try subsets of size n-1 down to 1
2. Prefer subsets:

   * With highest top pitch
   * With highest total pitch sum
   * With lowest cost
3. Return best subset
4. Mark dropped pitches visually in red

Policy chosen:

* Prefer highest notes (melody preservation)

---

# Rendering of Dropped Notes

If chord reduced:

* Assigned notes rendered normally
* Dropped notes rendered:

  * In red
  * Above staff or in prefix region
  * With small visual warning marker

---

# Preloading Behavior (V1 Extension)

When playing and:

```
(currentItemEnd - playPosition) <= preloadSeconds
```

Then:

* Identify next MIDI item on same track
* Extract and cache its notes
* When bar window crosses into next item, display seamlessly

Cache by item GUID or pointer identity.

---

# Configuration Parameters (Finalized)

* prevBars
* nextBars
* systemGutterPx
* barPrefixPx
* barContentPx
* barGutterPx
* stringSpacingPx
* maxFret
* maxFrettedSpan
* maxSimul
* weights (lowFret, stayOnString, stringJump, fretJump, highFret)
* reducePreferHighest = true
* showFirstTimeSigInSystemGutter = true
* preloadSeconds

---

# Performance Requirements

* Do not rescan entire MIDI every frame
* Recompute only when:

  * Bar index changes
  * Take changes
  * Preloaded item becomes active
* Use caching for item-level note lists

---

# Visual Style Goals

* Clean, continuous tab
* No tile borders
* Subtle barlines
* Legible fret numbers
* Red only for errors/reductions
* Minimal clutter

---

# MVP Completion Criteria

The tool is considered working when:

1. It follows playback.
2. It displays joined tab across wrapped systems.
3. It handles double stops.
4. It reduces impossible chords correctly.
5. It respects fretted span (open = free).
6. Time signature changes render correctly mid-system.

---

# Optional Enhancements (Post-MVP)

* Alternate fingering suggestions
* Position-lock mode (hand position continuity)
* Grace note filtering
* Quantization grid overlay
* Click-to-audition note/chord
* Export tab as text

---

# Final Clarifying Questions

Before implementation begins, confirm:

1. Should string 1 (lowest pitch) render at bottom of staff?
   (Recommended: yes — natural tab orientation.)

2. Should fret numbers be centered on string line or slightly above?
   (Standard tab centers on line.)

3. Should open strings (0) render as plain “0” or highlighted slightly?
   (Most tab uses plain 0.)

If you confirm those, the specification is complete and ready for coding.
