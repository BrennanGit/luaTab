# 0) Repo / file layout

**Single script folder** (ReaPack-friendly later):

* `luaTab.lua` (entry point, main loop)
* `lib/config.lua`
* `lib/source.lua` (take/track/item resolution + preloading)
* `lib/timeline.lua` (bars, time sig changes, range window)
* `lib/midi.lua` (extract notes, group events)
* `lib/frets.lua` (candidate generation + solver + reduction)
* `lib/layout.lua` (systems/rows, rects, wrap)
* `lib/render.lua` (draw strings/barlines/notes/warnings)
* `lib/util.lua` (helpers, LRU cache, math)

Keep modules pure where possible: pass data in/out, avoid globals.

---

# 1) MVP scope (first runnable)

## MVP features

* Window follows play cursor; if stopped follow edit cursor
* Window stays open and shows a message when no MIDI is detected
* Configurable `PrevBars`, `NextBars`
* Constant bar width with **bar prefix gutter** + **content width**
* Systems wrap based on window width (joined tab look)
* Pull MIDI notes from:

  * Preferred: selected track item under cursor
  * Fallback: active MIDI editor take
* Group notes into events (chords allowed)
* Map to string/fret with:

  * lowest-fret bias
  * chord solver with **max fretted span** (open=free)
  * if unplayable → best subset, **prefer highest notes**, dropped shown red

## Defer until v1

* multi-item preloading
* tie/hold markers
* fancy quantize grid
* alternative fingerings display

---

# 2) Config model (persisted)

`config.lua`

```lua
Config = {
  followPlay = true,
  followEditWhenStopped = true,

  prevBars = 1,
  nextBars = 2,

  systemGutterPx = 60,
  barPrefixPx = 16,
  barContentPx = 120,
  barGutterPx = 8,
  systemRowGapPx = 16,

  tuning = { -- low→high
    {name="G", open=55},
    {name="D", open=62},
    {name="A", open=69},
    {name="E", open=76},
  },
  maxFret = 15,
  maxFrettedSpan = 4,     -- open strings ignored
  maxSimul = 4,           -- usually = #strings

  weights = {
    lowFret = 8,
    stayOnString = 6,
    stringJump = 4,
    fretJump = 4,
    highFret = 2,
  },

  reducePreferHighest = true,
  showFirstTimeSigInSystemGutter = true,
  preloadSeconds = 2.0,   -- v1
  updateMode = "bar",
  updateStep = 1,
  antidelayBeats = 0,
}
```

Persist via `reaper.SetExtState("luaTab", key, value, true)`.

---

# 3) Timeline: bar windows + time signature changes

`timeline.lua`

### Inputs

* cursor time `t`
* prevBars/nextBars

### Outputs

* `bars[]` for indices `m-prev .. m+next`
  Each bar:

```lua
Bar = {
  idx = 123,                 -- measure index
  t0 = <proj time>,
  t1 = <proj time>,
  num = 6, den = 8,          -- time sig
  showTimeSigHere = bool,    -- change marker for prefix
}
```

### Logic

1. Determine current measure index `m` at time `t`.
2. For each bar index in range:

   * get `t0, t1, num, den` from TimeMap2 APIs
3. `showTimeSigHere = (i==rangeStart AND showFirst...) OR (sig changed vs previous bar in range OR global previous bar if you query it)`

Implementation detail:

* If it’s the first bar of a system and `showFirstTimeSigInSystemGutter`, you’ll render it in gutter; otherwise in that bar’s prefix. The timeline can just mark “sig change”, layout/render decide placement.

---

# 4) Layout: systems that wrap, joined look

`layout.lua`

### Inputs

* `bars[]` (from timeline)
* window content width
* px constants: `systemGutterPx`, `barPrefixPx`, `barContentPx`, `barGutterPx`

### Derived constants

* `barTotalPx = barPrefixPx + barContentPx`
* `usableWidth = contentWidth`
* `barsPerSystem = max(1, floor((usableWidth - systemGutterPx) / (barTotalPx + barGutterPx)))`

### Outputs

A list of `System` rows:

```lua
System = {
  y = <top>,
  x0 = <left>,
  gutterW = systemGutterPx,
  bars = { BarRef... },         -- slice of bars
  barLayouts = {
    [k] = {
      barIdx = Bar.idx,
      barLeft = x0 + gutterW + (k-1)*(barTotalPx + barGutterPx),
      prefix = {x=..., w=barPrefixPx},
      content = {x=..., w=barContentPx},
      barlineX = barLeft,        -- for drawing
    }
  },
  staffRect = {x=..., y=..., w=..., h=...}, -- for strings
}
```

### Row height

Depends on string count and font size:

* `stringSpacingPx` (e.g. 14)
* `staffH = (N-1)*stringSpacingPx`
* plus top/bottom padding

This guarantees resizing works and looks continuous.

---

# 5) MIDI extraction + event grouping (polyphony-aware)

`midi.lua`

### Extract notes for a time range

Input:

* take
* time window `[t0,t1)`

Output raw notes:

```lua
Note = { tStart=projTime, tEnd=projTime, pitch=69, vel=96 }
```

Steps:

* convert times → PPQ with `MIDI_GetPPQPosFromProjTime`
* iterate notes, include those with start in window (MVP)
* sort by `tStart, pitch`

### Group into events

Group by start time within tolerance:

* `eps = 0.001s` or PPQ epsilon
* `Event = { t=projTime, notes={...} }`

For chords/double stops, events will have multiple notes.

---

# 6) Fret mapping: candidates + solver + reduction

`frets.lua`

## 6.1 Candidate generation

For pitch `p` and string `s` (open pitch `o`):

* if `p < o` → no
* `f = p - o`
* if `f > maxFret` → no
* candidate `{string=s, fret=f}`

## 6.2 Fretted-span with open=free

Given chosen frets:

* collect only `f > 0`
* if none → span = 0
* else `span = max(f) - min(f)`
  Reject if `span > maxFrettedSpan`.

## 6.3 Chord assignment

Given event pitches `P` (size n):

* If `n > maxSimul` → must reduce.
* Generate candidate lists per pitch.
* Solve assignment with:

  * hard: unique string, span, max fret
  * soft cost:

    * `lowFret`: sum(fret)
    * `highFret`: sum(max(0,fret-7)) etc
    * `stayOnString`: if pitch mapped to same string as previous event (tracked per “voice” or simple per-top-note)
    * `stringJump`: distance from last used string for that “voice”
    * `fretJump`: abs(fret-lastFretForString[s]) (simple works)

### Combination search (pruned DFS)

* sort pitches high→low (helps “prefer highest” later and prunes)
* recursively pick a candidate for each pitch
* prune on duplicate strings and span
* track best cost

## 6.4 Reduction (unplayable chord)

If no full assignment:

* enumerate subsets by size (n-1 down to 1)
* BUT: since you want “prefer highest notes”, do subsets biased to include top pitches first:

  * sort pitches descending
  * for subset size k, test subsets that include highest pitch, then next, etc.
* choose:

  1. largest k
  2. highest top pitch
  3. highest sum of pitches
  4. lowest cost

Return:

* `assigned[]` and `dropped[]` (dropped rendered red)

---

# 7) Rendering plan (draw order matters)

`render.lua`

### Inputs per frame

* systems + bar layouts (layout)
* per-bar events (midi)
* per-event assignments (frets)

### Draw order per system

1. **String lines** across whole system staff width
2. **Barlines** at each barLeft (and system start/end)
3. **Beat ticks** (optional, light)
4. **Time signature markers**

   * if first bar in system and “gutter mode” → draw in gutter
   * else if bar.showTimeSigHere → draw in that bar’s prefix rect
5. **Fret numbers** (normal)
6. **Dropped notes** (red) + small warning icon/counter

   * place in bar prefix top or just above top string line near barline

### Note placement

For each bar:

* for each event in bar:

  * `frac = (event.t - bar.t0) / (bar.t1 - bar.t0)`
  * `x = content.x + frac * content.w`
* for each assigned pitch in event:

  * y = staffTop + (stringIndex-1)*stringSpacing
  * draw fret number text centered at (x,y)

Chords:

* if multiple frets on adjacent strings at same x, offset x by ±2–4px per note to avoid text overlap.

---

# 8) Main loop + state

`luaTab.lua`

State:

* current config
* cached timeline bars
* cached per-bar events
* cached per-bar assignments
* previous assignment context (last frets per string, last used string for top note, etc.)
* (v1) item cache + preload queue

Loop:

1. Begin ImGui window (resizable)
2. Draw control strip (Prev/Next, widths, tuning preset)
3. Determine cursor time (play vs edit)
4. Build bar list via timeline
5. Build systems via layout
6. Extract MIDI events for each bar window (batched)
7. Solve assignments per event (bar-by-bar, in time order)
8. Render systems
9. End window, defer next frame

---

# 9) V1 extension: Preload next item

Once MVP works:

* `source.lua` adds track+item mode
* maintain `ItemCache` keyed by GUID
* when cursor in last `preloadSeconds` of current item:

  * identify next MIDI item
  * extract + cache events for bars that will be needed soon
* during extraction, if a bar window overlaps item boundary:

  * merge events from both items

This drops in without changing layout/render at all (nice separation).

---

# 10) Implementation checkpoints (so you don’t stall)

1. Window + config UI + cursor time
2. Timeline bars computed + displayed as text
3. Layout systems drawn (string lines + barlines only)
4. MIDI extraction: show pitch names at x positions
5. Single-note fret mapping renders numbers on strings
6. Chords + solver + span constraint
7. Reduction + red dropped pitches
8. (v1) preloading

