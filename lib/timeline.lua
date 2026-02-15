local util = require("util")
local timeline = {}

local function get_measure_index(t)
  local _, meas = reaper.TimeMap2_timeToBeats(0, t)
  if meas == nil then
    return 0
  end
  return math.max(0, meas)
end

function timeline.get_measure_index(t)
  return get_measure_index(t)
end

function timeline.build_bars(t, prev_bars, next_bars, show_first_in_gutter)
  local current = get_measure_index(t)
  local start_idx = math.max(0, current - prev_bars)
  local end_idx = math.max(start_idx, current + next_bars)
  local bars = {}

  local prev_num = nil
  local prev_den = nil

  for idx = start_idx, end_idx do
    local t0, qn_start, qn_end, num, den = reaper.TimeMap_GetMeasureInfo(0, idx)
    local t1 = reaper.TimeMap_GetMeasureInfo(0, idx + 1)

    if t0 ~= nil and t1 ~= nil then
      local show_sig = false
      if idx == start_idx and show_first_in_gutter then
        show_sig = true
      elseif prev_num ~= nil and prev_den ~= nil then
        if num ~= prev_num or den ~= prev_den then
          show_sig = true
        end
      end

      bars[#bars + 1] = {
        idx = idx,
        t0 = t0,
        t1 = t1,
        num = num,
        den = den,
        showTimeSigHere = show_sig,
      }
    end

    prev_num = num
    prev_den = den
  end

  util.log(string.format("build_bars current=%d range=%d..%d count=%d", current, start_idx, end_idx, #bars), "debug")
  return bars, current
end

return timeline
