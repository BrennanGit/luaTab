# ReaScript API reference (for luaTab / tab-renderer project)

This file is a **curated index** of the REAPER API calls the project is likely to use.
It is **not** a copy of REAPER’s documentation.

## Source of truth (use these)

1) **Local (REAPER 6.83-generated) docs in this repo**
- `planning/reascripthelp.html`
- Jump to functions via anchors like: `planning/reascripthelp.html#TimeMap2_timeToBeats`

2) **Upstream / “latest” docs (often effectively REAPER 7+)**
- Official: https://www.reaper.fm/sdk/reascript/reascripthelp.html

3) **ReaImGui (if used)**
- ReaImGui repo: https://github.com/cfillion/reaimgui
- Forum thread: https://forum.cockos.com/showthread.php?t=250419

---

## Compatibility strategy (REAPER 6.83 ↔ 7)

### 1) Always feature-detect optional APIs
Use `reaper.APIExists("FunctionName")` before calling anything that may be:
- extension-provided (ReaImGui, SWS, etc.)
- added in newer REAPER releases

Example:
```lua
local has_imgui = reaper.APIExists and reaper.APIExists("ImGui_CreateContext")
if not has_imgui then
  reaper.MB("ReaImGui not available. Install ReaImGui (ReaPack) or disable UI mode.", "luaTab", 0)
  return
end
```

### 2) Treat multi-return functions as “shape-checked”
Many functions return multiple values. In Lua, **capture the full tuple** you need and confirm positions once.
For uncertain return layouts, log once with `reaper.ShowConsoleMsg`.

### 3) Prefer stable, older calls where possible
When two calls can solve the same problem, prefer the one that has existed longer and has stable signatures.

For this project:
- Prefer `TimeMap_GetTimeSigAtTime` for “what’s the sig here?”
- Prefer `TimeMap_GetMeasureInfo` if you need QN start/end + tempo at measure start
- Use `TimeMap2_timeToBeats` as the general “time → (measure, beats)” workhorse

### 4) Extensions: treat as optional
- **ReaImGui**: third-party extension (ReaPack). Not guaranteed installed.
- **SWS (BR_*)**: optional; avoid hard dependency if you can.

---

## A) UI / windowing (ReaImGui)

**Doc anchor hints (local):**
- `#ImGui_CreateContext`, `#ImGui_Begin`, `#ImGui_End`, `#ImGui_DestroyContext`
- `#ImGui_GetContentRegionAvail`, `#ImGui_GetCursorScreenPos`, `#ImGui_GetWindowDrawList`
- `#ImGui_DrawList_AddLine`, `#ImGui_DrawList_AddText`, `#ImGui_DrawList_AddRectFilled`
- `#ImGui_Checkbox`, `#ImGui_SliderInt`, `#ImGui_SliderDouble`, `#ImGui_Combo`, `#ImGui_Separator`
- `#ImGui_ColorConvertDouble4ToU32`

**Compatibility notes**
- Many ReaImGui functions state minimum REAPER versions in the docs (e.g. “requires REAPER 6.24 or later”).
- Even if REAPER version is new enough, **the ReaImGui extension still must be installed**.

**Project-specific gotchas**
- Use screen coordinates for DrawList primitives.
- Avoid per-frame table churn (Lua GC stutter).

---

## B) Cursor / transport

**Docs**
- `#GetPlayState`
- `#GetPlayPosition`
- `#GetCursorPosition`

**Notes**
- Decide follow behavior when paused: `GetPlayState()` includes paused bit.

---

## C) Time map / measures / time signatures

### Convert time → beats/measure (primary)
**Docs**
- `#TimeMap2_timeToBeats`

**What it gives you (Lua)**
- returns `retval` plus optional outputs:
  - `measures` (measure count)
  - `cml` (current measure length in beats, i.e. numerator)
  - `fullbeats` (full beat count)
  - `cdenom` (denominator)

**Compatibility**
- Signature/behavior is stable across 6.x/7.x, but always capture in a way that tolerates nils:
```lua
local beats_since_meas, meas, cml, fullbeats, denom = reaper.TimeMap2_timeToBeats(0, t)
```

### Measure info at measure index (QN start/end + sig + tempo)
**Docs**
- `#TimeMap_GetMeasureInfo`

**Returns (Lua)**
- `retval` (seconds of measure start), `qn_start`, `qn_end`, `timesig_num`, `timesig_denom`, `tempo`

### Time signature + tempo at time
**Docs**
- `#TimeMap_GetTimeSigAtTime`

**Returns (Lua)**
- `timesig_num`, `timesig_denom`, `tempo`

### Detect “next change time” (optional but useful for caching)
**Docs**
- `#TimeMap2_GetNextChangeTime`

**Use**
- Cache invalidation for bar window if tempo/time-sig changes are rare.

---

## D) Track/item/take selection (and preloading items)

**Docs**
- Tracks: `#CountTracks`, `#GetTrack`, `#GetSelectedTrack`
- Items: `#CountTrackMediaItems`, `#GetTrackMediaItem`
- Item props: `#GetMediaItemInfo_Value` (use `"D_POSITION"`, `"D_LENGTH"`, `"B_MUTE"`)
- Takes: `#GetActiveTake`, `#CountTakes`, `#GetTake`, `#TakeIsMIDI`

**Preload helper**
- Use item start+len to find current item under cursor and next item.
- Decide overlap policy: “latest start that contains time” is usually sane.

**Optional (SWS)**
- `BR_GetMediaItemGUID` is in SWS, not core. Prefer `tostring(item)` as a cache key if avoiding SWS.

---

## E) MIDI editor integration

**Docs**
- `#MIDIEditor_GetActive`
- `#MIDIEditor_GetTake`
- Optional: `#MIDIEditor_EnumTakes` (if you want multi-take editor support later)

**Notes**
- If no MIDI editor open, `MIDIEditor_GetActive()` returns nil.

---

## F) MIDI extraction + time conversion

**Docs**
- `#MIDI_CountEvts`
- `#MIDI_GetNote`
- `#MIDI_GetPPQPosFromProjTime`
- `#MIDI_GetProjTimeFromPPQPos`
- Optional but handy:
  - `#MIDI_GetHash` (if available) for change detection
  - `#MIDI_Sort` (if you ever write notes/CCs)

**Performance pattern**
- Cache per-take extraction and only rebuild when:
  - active take changes, OR
  - MIDI hash / event count changes, OR
  - bar window changes

---

## G) Logging / debugging

**Docs**
- `#ShowConsoleMsg`
- `#ClearConsole`

**Use this to verify multi-return tuples once during dev.**

---

## H) Persistent settings

**Docs**
- `#SetExtState`, `#GetExtState`, `#HasExtState`, `#DeleteExtState`
- Project-specific variant if you need per-project:
  - `#GetProjExtState`, `#SetProjExtState` (check docs; prefer if settings should travel with the project)

**Notes**
- Values are strings; serialize simple tables yourself.

---

## Appendix: “minimum viable” API checklist for this project

### Cursor-follow + bar range
- `GetPlayState`, `GetPlayPosition`, `GetCursorPosition`
- `TimeMap2_timeToBeats`
- `TimeMap_GetTimeSigAtTime` (and/or `TimeMap_GetMeasureInfo`)

### Active MIDI editor take mode
- `MIDIEditor_GetActive`, `MIDIEditor_GetTake`

### MIDI extraction
- `MIDI_CountEvts`, `MIDI_GetNote`
- `MIDI_GetPPQPosFromProjTime`, `MIDI_GetProjTimeFromPPQPos`

### Items mode + preloading
- `GetSelectedTrack` / `GetTrack`, `CountTrackMediaItems`, `GetTrackMediaItem`
- `GetMediaItemInfo_Value`, `GetActiveTake`, `TakeIsMIDI`

### UI (if ReaImGui installed)
- `ImGui_CreateContext`, `ImGui_Begin`, `ImGui_End`, `ImGui_DestroyContext`
- `ImGui_GetContentRegionAvail`, `ImGui_GetCursorScreenPos`, `ImGui_GetWindowDrawList`
- DrawList add primitives, a couple widgets, and `defer`
