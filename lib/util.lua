-- lib/util.lua
-- Small helpers: logging, clamp, etc.

local Util = {}

Util.DEBUG = false

function Util.log(msg)
  if Util.DEBUG then
    reaper.ShowConsoleMsg(tostring(msg) .. "\n")
  end
end

function Util.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- Handy for discovering unknown return tuples (time map APIs, etc.)
function Util.dump_returns(prefix, ...)
  local parts = {}
  local n = select("#", ...)
  for i = 1, n do
    parts[#parts+1] = tostring(select(i, ...))
  end
  Util.log(prefix .. ": " .. table.concat(parts, " | "))
end

return Util
