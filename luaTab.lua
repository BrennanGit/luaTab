-- luaTab.lua
-- Minimal GUI scaffold: shows current measure number (bar index)

local Util   = dofile(reaper.GetResourcePath() .. "/Scripts/luaTab/lib/util.lua")
local Style  = dofile(reaper.GetResourcePath() .. "/Scripts/luaTab/lib/style.lua")
local Config = dofile(reaper.GetResourcePath() .. "/Scripts/luaTab/lib/config.lua")

-- ---- Safety check: ReaImGui available?
if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox(
    "ReaImGui is not available.\n\nInstall/enable ReaImGui (via ReaPack or REAPER package manager) and restart REAPER.",
    "luaTab",
    0
  )
  return
end

local ctx = reaper.ImGui_CreateContext("luaTab")
local col = Style.BuildColors(ctx)

local cfg = Config.load()

-- Cached “tuple discovery”
local last_time_map_dump = ""

-- Decide which cursor to follow
local function get_follow_time()
  local playState = reaper.GetPlayState()
  local isPlaying = (playState & 1) == 1
  if isPlaying and cfg.followPlay then
    return reaper.GetPlayPosition()
  end
  if cfg.followEditWhenStopped then
    return reaper.GetCursorPosition()
  end
  return reaper.GetPlayPosition()
end

-- Extract measure index from REAPER time map.
-- IMPORTANT: TimeMap2_timeToBeats return tuple can vary.
-- Strategy:
--   - call it
--   - treat the *second* return as "measure position" if present
--   - measure index = floor(measurepos)
-- If this is wrong on your build, use the "Dump returns" button and adjust.
local function get_measure_index_at_time(t)
  local a,b,c,d,e,f,g = reaper.TimeMap2_timeToBeats(0, t)
  -- Common case: b is measure position (0-based measure index as float)
  local measpos = b
  if type(measpos) ~= "number" then
    return nil, a,b,c,d,e,f,g
  end
  return math.floor(measpos), a,b,c,d,e,f,g
end

-- Optional: get time signature at time
local function get_timesig_at_time(t)
  local num, denom = reaper.TimeMap_GetTimeSigAtTime(0, t)
  return num, denom
end

local function loop()
  local visible, open = reaper.ImGui_Begin(ctx, "luaTab (Scaffold)", true,
    reaper.ImGui_WindowFlags_AlwaysAutoResize() -- remove later; keeps MVP tidy
  )
  if visible then
    -- Controls
    local changed
    changed, cfg.followPlay = reaper.ImGui_Checkbox(ctx, "Follow play cursor", cfg.followPlay)
    if changed then Config.save(cfg) end

    changed, cfg.followEditWhenStopped = reaper.ImGui_Checkbox(ctx, "When stopped, follow edit cursor", cfg.followEditWhenStopped)
    if changed then Config.save(cfg) end

    changed, cfg.prevBars = reaper.ImGui_SliderInt(ctx, "Prev bars", cfg.prevBars, 0, 16)
    if changed then Config.save(cfg) end

    changed, cfg.nextBars = reaper.ImGui_SliderInt(ctx, "Next bars", cfg.nextBars, 0, 16)
    if changed then Config.save(cfg) end

    reaper.ImGui_Separator(ctx)

    -- Read cursor time + measure
    local t = get_follow_time()
    local measIdx, a,b,c,d,e,f,g = get_measure_index_at_time(t)
    local num, denom = get_timesig_at_time(t)

    reaper.ImGui_Text(ctx, string.format("Time: %.3f s", t))
    reaper.ImGui_Text(ctx, string.format("Time sig at cursor: %s/%s", tostring(num), tostring(denom)))

    if measIdx ~= nil then
      -- Display measure index as 1-based for humans
      reaper.ImGui_Text(ctx, string.format("Measure index: %d (display %d)", measIdx, measIdx + 1))
    else
      reaper.ImGui_Text(ctx, "Measure index: (could not parse TimeMap2_timeToBeats return tuple)")
    end

    reaper.ImGui_Separator(ctx)

    -- Tuple discovery helper
    if reaper.ImGui_Button(ctx, "Dump TimeMap2_timeToBeats returns to console") then
      Util.DEBUG = true
      Util.dump_returns("TimeMap2_timeToBeats", a,b,c,d,e,f,g)
      Util.DEBUG = false
      last_time_map_dump = string.format("%s | %s | %s | %s | %s | %s | %s",
        tostring(a),tostring(b),tostring(c),tostring(d),tostring(e),tostring(f),tostring(g))
    end

    if last_time_map_dump ~= "" then
      reaper.ImGui_Text(ctx, "Last dump (also in console):")
      reaper.ImGui_TextWrapped(ctx, last_time_map_dump)
    end

    reaper.ImGui_End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

loop()
