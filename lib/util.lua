local util = {}

util._log = {
  enabled = false,
  verbose = false,
  path = nil,
  last = {},
}

function util.script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end
  return source:match("^(.*)[/\\].-$") or "."
end

function util.clamp(value, min_value, max_value)
  if value < min_value then return min_value end
  if value > max_value then return max_value end
  return value
end

function util.round(value)
  return math.floor(value + 0.5)
end

function util.copy_table(tbl)
  local copy = {}
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      copy[key] = util.copy_table(value)
    else
      copy[key] = value
    end
  end
  return copy
end

function util.color_u32(r, g, b, a)
  if reaper and reaper.ImGui_ColorConvertDouble4ToU32 then
    return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a)
  end
  return 0
end

local function log_write(path, line)
  local file = io.open(path, "a")
  if not file then return end
  file:write(line)
  file:close()
end

function util.log_init(base_dir, enabled, verbose)
  util._log.enabled = enabled and true or false
  util._log.verbose = verbose and true or false
  util._log.path = (base_dir or ".") .. "/luaTab.log"

  if util._log.enabled then
    local header = string.format("[%s] log start\n", os.date("%Y-%m-%d %H:%M:%S"))
    log_write(util._log.path, header)
  end
end

function util.log(message, level)
  if not util._log.enabled then return end
  local lvl = level or "info"
  if lvl == "debug" and not util._log.verbose then
    return
  end
  local line = string.format("[%s] [%s] %s\n", os.date("%H:%M:%S"), lvl, tostring(message))
  log_write(util._log.path, line)
end

function util.log_throttle(key, interval_sec, message, level)
  if not util._log.enabled then return end
  local now = reaper.time_precise and reaper.time_precise() or os.clock()
  local last = util._log.last[key] or 0
  if now - last >= interval_sec then
    util._log.last[key] = now
    util.log(message, level)
  end
end

function util.log_path()
  return util._log.path
end

return util
