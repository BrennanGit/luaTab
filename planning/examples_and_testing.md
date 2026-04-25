# Examples and Testing

This project has three “risk areas” that need deliberate testing:
1) REAPER time map + bar boundary correctness (time sig / tempo changes, cursor follow)
2) MIDI extraction + event grouping (chords, overlaps, ornaments)
3) Fret assignment (constraints + reduction + stability across runs)

To reduce debugging pain, we use three layers of tests:
- **Pure function tests** (no REAPER dependency): solver, layout, event grouping
- **Synthetic MIDI in REAPER** (controlled items): end-to-end extraction → render
- **Real-world tune sessions** (agent + user): confirm musical usefulness and ergonomics

---

## 1. Testing Goals and “Definition of Done”

A build is acceptable when:
- The display follows cursor correctly and updates by bar.
- Bars wrap into new systems cleanly when resizing the window.
- Time signature changes appear at the correct barline using the per-bar prefix gutter.
- Double stops and chords are mapped to distinct strings when possible.
- The chord span constraint is enforced with **open strings treated as free**.
- When a chord is not playable, the tool keeps the **highest notes** and marks dropped notes in red.
- The tool remains responsive (no full MIDI scan every frame).

---

## 2. Core Test Cases (Recommended)

### A) Layout / Wrapping / Rendering

**L01: Wide window (single system row)**
- Setup: show Prev=1, Next=4, set bar width large enough so all bars fit in one row
- Expected:
  - One continuous set of string lines across the row
  - Barlines drawn between measures
  - No tile outlines

**L02: Narrow window (wrap into multiple systems)**
- Setup: shrink window until only 2–3 bars fit per row
- Expected:
  - Bars cascade into multiple systems
  - Each system has continuous string lines
  - Barlines align and do not “reset” visual style

**L03: Resize stress test**
- Setup: continuously drag window wider/narrower
- Expected:
  - No flicker/jitter from layout math
  - No overlapping text explosions (minor overlap acceptable early, but should not become unreadable)

**L04: Item boundary markers**
- Setup: place two adjacent MIDI items on a selected track; position cursor in the first item
- Expected:
  - Thicker vertical line at the current item start/end
  - Upcoming item start line visible before reaching the boundary

**L05: Looped item repeat boundary markers**
- Setup: enable item looping on a MIDI item, extend to multiple repeats, and keep the repeat seams within visible bars
- Expected:
  - Item boundary bars appear at repeat seam times inside the item
  - Existing item start/end boundary bars still render as before

**U01: Update mode step**
- Setup: set update mode to every 2 bars and play through 4 bars
- Expected:
  - Window advances every 2 bars

**U02: Update mode screen**
- Setup: set update mode to bars-on-screen width and resize window
- Expected:
  - Window advances when the current bar enters the next screen chunk

**U03: Antidelay beats**
- Setup: set antidelay to 2 beats, play through a bar
- Expected:
  - Window advances 2 beats before the bar ends

### B) Timeline / Time Signature Display

**T01: No time signature changes**
- Setup: 6/8 whole project
- Expected:
  - Time sig shown in system gutter for first bar of system (if enabled)
  - No extra time sig markers mid-system

**T02: Mid-system time signature change**
- Setup: 6/8 for bars 1–4, then 9/8 at bar 5 (so it can land mid-system)
- Expected:
  - At bar 5, time signature appears in the **prefix gutter** for bar 5
  - Not forced to create a new system
  - Measure boundaries remain correct

### C) MIDI Extraction / Event Grouping

**M01: Monophonic melody**
- Notes start exactly on grid, no overlaps
- Expected:
  - Events contain a single pitch each
  - Notes appear in correct bars and positions

  **M01a: Selected track source**
  - Setup: select a track with a MIDI item under cursor
  - Expected:
    - Notes render without opening the MIDI editor

  **M00: No active MIDI take**
  - Setup: close MIDI editor or ensure no active take
  - Expected:
    - Window stays open
    - Message appears in the tab area indicating no MIDI is detected

**M02: Double stops**
- Two notes starting at same time
- Expected:
  - Event groups both notes
  - Both render aligned in time
  - Solver assigns to distinct strings

**M03: Chord with staggered starts (ornament-like)**
- Notes begin within a tiny timing tolerance (e.g., 5–10 ms)
- Expected:
  - Configurable behavior:
    - Either grouped into one event (if epsilon set higher)
    - Or shown as separate close events (if epsilon low)
  - Provide a debug option to inspect grouping

**M04: Notes crossing barline**
- One note starts near end of bar and sustains into next bar
- Expected (MVP):
  - Note displayed only in bar where it starts
- Expected (later enhancement):
  - Optional “hold/tie” marker in next bar

**M05: Item trim / gap handling**
- Setup: trim a MIDI item to create a leading gap; place cursor before the item start
- Expected:
  - Empty bars rendered before item start
  - Notes outside the trimmed item range are not shown

**M06: Looped MIDI item repeat handling**
- Setup: create a MIDI item, enable item looping, extend item to at least 2 repeats, place cursor in repeat 1 then repeat 2
- Expected:
  - Notes/events render in both repeats
  - No regression to "first repeat only" extraction

### D) Fret Assignment / Constraints / Reduction

**F01: Single pitch mapping uses lowest feasible fret**
- Setup: tuning GDAE, pitch A4 (69)
- Expected:
  - String A open (fret 0) chosen if allowed and consistent with rules

**F02: “Open strings are free” span test**
- Chord frets are {0, 2, 5} on different strings
- With maxFrettedSpan = 3
- Expected:
  - Pass (span computed from {2,5} = 3)

**F03: Playable chord within span**
- 3-note chord that fits
- Expected:
  - All notes assigned, no dropped notes

**F04: Unplayable chord due to span**
- 4-note chord requires fretted span > maxFrettedSpan
- Expected:
  - Reduced subset chosen
  - Subset keeps highest notes (melody-preserving)
  - Dropped pitches rendered red and listed in debug output

**F05: Unplayable due to string collisions**
- Two notes both only playable on same string (given max fret and tuning)
- Expected:
  - Reduction occurs
  - Highest notes preserved

**F06: Stability / hysteresis check**
- Scalar run that could alternate between two strings at equal frets
- Expected:
  - Mapping should not “ping-pong” excessively if stay-on-string weight > 0
  - Debug should reveal “stay on string” contribution

---

## 3. Suggested Testing Framework (Offline-Friendly)

### 3.1 Pure Function Tests (No REAPER)

Goal: validate `frets.lua`, `layout.lua`, and `event grouping` as pure functions.

Approach:
- Add a `tests/` folder with Lua scripts runnable inside REAPER’s ReaScript console or via `dofile()`.
- Implement a tiny assertion helper:
  - `assert_eq(actual, expected, message)`
  - `assert_true(cond, message)`

Suggested tests:
- Candidate generation correctness
- Span calculation ignoring open strings
- Chord solver returns best mapping
- Reduction chooses highest-note subset
- Layout wraps correctly for given widths

Why:
- Pure tests debug faster than interactive REAPER sessions.
- Eliminates “is this a REAPER API bug or our logic?”

Current local fallback:
- Run `.\\lua53\\lua53.exe tests\\run.lua` from the repository root for pure Lua coverage of fret assignment, layout wrapping, MIDI grouping/filtering, and manual override behavior.
- If a Lua interpreter is not available on PATH, run static delimiter/duplicate-function checks plus focused diff review before REAPER validation.
- Still treat REAPER as required validation for config persistence, looped MIDI extraction, ImGui docking, and rendering behavior.

### 3.2 Synthetic MIDI in REAPER (Controlled Items)

Goal: validate `midi extraction` and end-to-end behavior.

Two ways:

#### Option A: Programmatically generate a MIDI item (preferred)
Create a helper script:
- Creates a new track
- Inserts a MIDI item of known length
- Inserts note-ons/offs at exact PPQ positions

API hints (agent to implement):
- `reaper.CreateNewMIDIItemInProj(track, start_time, end_time, qn_in)`
- `reaper.MIDI_InsertNote(take, selected, muted, startppq, endppq, chan, pitch, vel, noSort)`
- `reaper.MIDI_Sort(take)`

Then generate specific items:
- monophonic melody
- chord stress items
- mid-project time sig change item

#### Option B: Manual MIDI item + included “fixtures”
If programmatic generation is slow to implement:
- Create a handful of small “fixture” projects by hand.
- Use them for quick regression checks.

### 3.3 Agent + User Collaboration Session

Goal: confirm this is musically useful.

Process:
- User provides 2–3 real tunes with known tricky spots:
  - dense ornaments
  - chords/double stops
  - time sig change (if relevant)
- Agent runs tool in REAPER, toggles debug overlay as needed.
- Record issues:
  - unreadable overlaps
  - wrong bar boundaries
  - fret choices feel un-musical
- Adjust weights + epsilon and rerun.

Deliverable after session:
- a short “tuning + weights preset” that feels right for trad tunes.

---

## 4. Debugging Tools That Help Testing

### Debug overlay toggle
When enabled, show:
- current cursor time and measure index
- visible bar indices and bars-per-system
- for hovered event:
  - pitches
  - chosen string/fret
  - dropped pitches + reason
  - cost breakdown (weights)

### Console logging mode
A lightweight `log()` helper that can be turned on/off.
Use only during dev to avoid performance problems.

---

## 5. Minimal Regression Suite (Recommended)

Keep a short list of “run these before shipping”:
1) L02 (wrap)
2) T02 (mid-system time sig change)
3) M02 (double stops)
4) F02 (open is free span)
5) F04 (unplayable chord reduction keeps highest notes)
