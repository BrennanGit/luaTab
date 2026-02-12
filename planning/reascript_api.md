# 1) Window/UI (ReaImGui)

### Context + main loop

* `reaper.ImGui_CreateContext(name)`
* `reaper.ImGui_Begin(ctx, title, open, flags)`
* `reaper.ImGui_End(ctx)`
* `reaper.ImGui_DestroyContext(ctx)`
* `reaper.defer(func)` (frame loop)

**Gotchas**

* Immediate mode: you recompute layout and redraw every frame.
* Use a stable “open” flag to allow closing.
* Don’t allocate big tables every frame unless cached; Lua GC stutter is real.

### Sizing / content region (for wrapping systems)

* `reaper.ImGui_GetContentRegionAvail(ctx)` → `(w, h)`
* `reaper.ImGui_GetCursorScreenPos(ctx)` → `(x, y)` (useful for DrawList coordinates)
* `reaper.ImGui_GetWindowDrawList(ctx)` → draw list handle

### Draw primitives

* `reaper.ImGui_DrawList_AddLine(draw_list, x1,y1,x2,y2, col, thickness)`
* `reaper.ImGui_DrawList_AddText(draw_list, x,y, col, text)`
* `reaper.ImGui_DrawList_AddRectFilled(draw_list, x1,y1,x2,y2, col, rounding)` (optional backgrounds)

### Widgets you’ll want

* `reaper.ImGui_Checkbox(ctx, label, bool)`
* `reaper.ImGui_SliderInt(ctx, label, v, v_min, v_max)`
* `reaper.ImGui_SliderDouble(ctx, label, v, v_min, v_max, fmt)`
* `reaper.ImGui_Combo(ctx, label, current_idx, items_csv)` (or build your own)
* `reaper.ImGui_Separator(ctx)`

**Gotchas**

* Colors are packed ints. You’ll likely want a helper:

  * `reaper.ImGui_ColorConvertDouble4ToU32(r,g,b,a)` → col
* Use **screen coords** for DrawList.

---

# 2) Cursor / transport (follow play or edit cursor)

### Playback state

* `reaper.GetPlayState()`
  Returns bitmask:

  * 0 = stopped
  * 1 = playing
  * 2 = paused
  * 4 = recording
    (You mostly care about “playing vs not”.)

### Time positions

* `reaper.GetPlayPosition()` → current play cursor time (seconds)
* `reaper.GetCursorPosition()` → edit cursor time (seconds)

**Gotchas**

* When paused, play position may still return the pause location; decide whether to treat paused as “follow play”.

---

# 3) Time map / bars / time signatures (critical)

You need:

* current **measure index** from time
* each measure’s **start/end time**
* **time signature** at a measure
* handle time-sig changes mid-project

### Converting time → musical position

* `reaper.TimeMap2_timeToBeats(proj, time)`
  Returns multiple values; depending on REAPER version you may get:

  * beats position (from project start)
  * measures (or measure index)
  * beats-in-measure
  * etc.

**Gotchas**

* The exact return tuple varies across REAPER versions/languages. In Lua, capture generously:

  ```lua
  local beatpos, measurepos, beat_in_meas = reaper.TimeMap2_timeToBeats(0, t)
  ```

  Then print/debug once to confirm what you’re getting.

### Getting measure boundaries and time signature

* `reaper.TimeMap2_GetMeasureInfo(proj, measure_idx)`
  Returns several values including (commonly):

  * measure start time (seconds)
  * measure end time (seconds) OR length in seconds
  * time sig numerator/denominator
  * tempo / marker info (varies)

**Gotchas**

* Like above: return tuple varies. Strategy:

  * call once, print all returns to console via `reaper.ShowConsoleMsg` during development
  * then lock into positions you need.
* Measure indices are **0-based** in many APIs. Confirm by checking measure 0 start time should be 0.0.

### Fallback: time signature at time

* `reaper.TimeMap_GetTimeSigAtTime(proj, time)`
  Typically returns `num, denom` (and sometimes additional values).

**Gotchas**

* This is simpler if `TimeMap2_GetMeasureInfo` is confusing for your agent.

### Project tempo/time signature markers enumeration (optional)

If you end up wanting to detect changes explicitly:

* `reaper.CountTempoTimeSigMarkers(proj)`
* `reaper.GetTempoTimeSigMarker(proj, idx)`
  Returns marker properties including time, measure, beat, BPM, time sig.

**Gotchas**

* If you rely on measure info calls, you don’t need this, but it’s useful for debugging “why did time sig change here?”

---

# 4) Track/item/take selection + preloading

### Working with tracks

* `reaper.GetSelectedTrack(proj, idx)` (idx 0 = first selected)
* `reaper.GetTrack(proj, idx)` (idx 0 = first track in project)
* `reaper.CountTracks(proj)`

### Iterating items on a track

* `reaper.CountTrackMediaItems(track)`
* `reaper.GetTrackMediaItem(track, i)` → MediaItem*

Item properties:

* `reaper.GetMediaItemInfo_Value(item, "D_POSITION")` (seconds)
* `reaper.GetMediaItemInfo_Value(item, "D_LENGTH")` (seconds)
* `reaper.GetMediaItemInfo_Value(item, "B_MUTE")` (0/1)

Take access:

* `reaper.GetActiveTake(item)` → MediaItem_Take*
* `reaper.CountTakes(item)`
* `reaper.GetTake(item, i)`

MIDI test:

* `reaper.TakeIsMIDI(take)` → bool

GUID (for caching):

* `reaper.BR_GetMediaItemGUID(item)` (SWS)
  If you want to avoid SWS dependency, you can use item pointer identity as key, but GUID is nicer.
  (If SWS isn’t guaranteed, store by `tostring(item)`.)

**Preload pattern**

* Find current item under cursor:

  * iterate items on track and check `pos <= t < pos+len`
* Find next item:

  * smallest `pos` such that `pos >= current_end`
* Preload when `current_end - t <= preloadSeconds`

**Gotchas**

* Items can overlap. Decide rule: “prefer item with latest start that contains t” usually matches “topmost” logic on that track.
* Multiple MIDI takes per item: most cases active take is fine.

---

# 5) MIDI editor integration (if you support “active MIDI editor take”)

* `reaper.MIDIEditor_GetActive()` → editor handle (or nil)
* `reaper.MIDIEditor_GetTake(editor)` → take

**Gotchas**

* If no MIDI editor is open, this returns nil. Provide fallback to selected item/take mode.

---

# 6) MIDI note extraction (the meat)

### Count events

* `reaper.MIDI_CountEvts(take)` → `noteCount, ccCount, textSyxCount`

### Get notes

* `reaper.MIDI_GetNote(take, note_idx)`
  Returns:

  * selected (bool)
  * muted (bool)
  * startppqpos (number)
  * endppqpos (number)
  * chan (int)
  * pitch (int 0–127)
  * vel (int 0–127)

### Convert project time ↔ PPQ

* `reaper.MIDI_GetPPQPosFromProjTime(take, time_sec)` → ppq
* `reaper.MIDI_GetProjTimeFromPPQPos(take, ppq)` → time_sec

**Gotchas**

* PPQ depends on item source length/tempo map; using REAPER conversions is correct.
* Notes might be in arbitrary order; sort by `startppqpos` then pitch.

### Performance tip

Instead of scanning all notes each frame:

* Cache notes per item/take and only rebuild when:

  * take changes
  * MIDI hash changes (no direct hash; use a cheap heuristic: store `noteCount` + maybe the last note’s startppq)
  * cursor enters a new bar (so your visible set changes)

If you do need a full scan, do it only when bar index changes.

### Channel filtering

* from `MIDI_GetNote`, filter by `chan` if user selects.

---

# 7) Text/console logging (for offline debugging)

* `reaper.ShowConsoleMsg("text\n")`
* `reaper.ClearConsole()`

This is how your agent should “discover” unknown return tuples from TimeMap2 functions: print them once.

---

# 8) Persistent settings (your tuning + UI prefs)

* `reaper.SetExtState(section, key, value, persist)`
* `reaper.GetExtState(section, key)`
* `reaper.HasExtState(section, key)`
* `reaper.DeleteExtState(section, key, persist)`

**Gotchas**

* Everything is a string; serialize tables yourself (simple `key=value;` format or JSON if you have a tiny encoder).
* Namespace your section like `"luaTab"`.

---

# 9) Common “situational gotchas” for this project

### A) Time signature changes mid-measure

REAPER time sig markers are measure-based in normal use, but users can do odd things. Safer approach:

* determine bar boundaries via `TimeMap2_GetMeasureInfo`
* determine sig at bar start via `TimeMap_GetTimeSigAtTime(bar.t0)`

### B) Notes crossing barlines

If you want “hold” indicators later:

* include notes where `start < bar_end && end > bar_start`
* but for MVP you can include only start-in-bar to simplify.

### C) Multiple items / gaps

When bar windows fall in gaps between items:

* display empty bars (still draw staff/barlines)
* preloading helps avoid empties at transitions.

### D) Overlapping MIDI items on same track

Pick priority rule:

* item with latest start containing t
* OR item with highest lane (harder; requires UI state)
  Most people don’t overlap for this use-case; pick simple.

### E) Tempo map and PPQ stability

Always convert using `MIDI_GetPPQPosFromProjTime` for the specific take. Don’t assume constant PPQ per second.

### F) “Measure index” off-by-one

Confirm by test:

* at time 0, measure index should be 0
* bar start returned should be 0.0
  If not, adjust.

---

# 10) Minimal call checklist by subsystem

### Follow cursor + bar range

* `GetPlayState`
* `GetPlayPosition` / `GetCursorPosition`
* `TimeMap2_timeToBeats`
* `TimeMap2_GetMeasureInfo` (or `TimeMap_GetTimeSigAtTime`)

### MIDI from active editor

* `MIDIEditor_GetActive`
* `MIDIEditor_GetTake`
* `MIDI_CountEvts`
* `MIDI_GetNote`
* `MIDI_GetPPQPosFromProjTime`
* `MIDI_GetProjTimeFromPPQPos`

### Preloading on track items

* `GetSelectedTrack` / `GetTrack`
* `CountTrackMediaItems`
* `GetTrackMediaItem`
* `GetMediaItemInfo_Value` (pos/len)
* `GetActiveTake`
* `TakeIsMIDI`

### UI drawing

* `ImGui_*` calls listed above

---

If you want to make life easier for your local agent, tell them this dev trick up front:

**When unsure about return values** (TimeMap2 functions especially), log all returns once:

```lua
local a,b,c,d,e,f,g = reaper.TimeMap2_GetMeasureInfo(0, m)
reaper.ShowConsoleMsg(string.format("GetMeasureInfo: %s %s %s %s %s %s %s\n",
  tostring(a),tostring(b),tostring(c),tostring(d),tostring(e),tostring(f),tostring(g)))
```

