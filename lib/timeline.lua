-- lib/timeline.lua
-- Cursor follow + bar window + time signature info

local Util = dofile(reaper.GetResourcePath() .. "/Scripts/luaTab/lib/util.lua")

local Timeline = {}

function Timeline.get_cursor_time(cfg)
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

local function measure_index_at_time(t)
  local a, b = reaper.TimeMap2_timeToBeats(0, t)
  local measpos = nil
  if type(b) == "number" then
    measpos = b
  elseif type(a) == "number" then
    measpos = a
  end
  if type(measpos) ~= "number" then
    return nil
  end
  return math.floor(measpos)
end

local function get_measure_bounds(idx)
  local r1, r2, r3, r4 = reaper.TimeMap2_GetMeasureInfo(0, idx)
  if type(r1) ~= "number" or type(r2) ~= "number" then
    return nil
  end
  local t0 = r1
  local t1 = r2
  if t1 < t0 then
    t1 = t0 + r2
  end
  local num = r3
  local den = r4
  if type(num) ~= "number" or type(den) ~= "number" then
    num, den = reaper.TimeMap_GetTimeSigAtTime(0, t0)
  end
  return t0, t1, num, den
end

function Timeline.build_bars(t, prevBars, nextBars, showFirstTimeSigInSystemGutter)
  local m = measure_index_at_time(t)
  if not m then
    return {}, nil
  end

  local startIdx = m - prevBars
  local endIdx = m + nextBars
  local bars = {}
  local prevNum, prevDen

  for i = startIdx, endIdx do
    local t0, t1, num, den = get_measure_bounds(i)
    if t0 and t1 then
      local show = false
      if i == startIdx and showFirstTimeSigInSystemGutter then
        show = true
      elseif prevNum and prevDen and (num ~= prevNum or den ~= prevDen) then
        show = true
      elseif not prevNum then
        show = true
      end
      bars[#bars + 1] = {
        idx = i,
        t0 = t0,
        t1 = t1,
        num = num,
        den = den,
        showTimeSigHere = show,
      }
      prevNum, prevDen = num, den
    else
      Util.log("Timeline: failed to get measure bounds for index " .. tostring(i))
    end
  end

  return bars, m
end

return Timeline
