-- lib/config.lua
-- ExtState-backed config with defaults

local Config = {}

Config.SECTION = "luaTab"

Config.defaults = {
  followPlay = true,
  followEditWhenStopped = true,

  prevBars = 1,
  nextBars = 2,

  -- (Used later, but keep here now)
  maxFret = 15,
  maxFrettedSpan = 4,
  reducePreferHighest = true, -- chosen

  -- Mandolin GDAE default
  tuning = {
    { name = "G", open = 55 },
    { name = "D", open = 62 },
    { name = "A", open = 69 },
    { name = "E", open = 76 },
  },
}

-- Serialize only simple scalars here; keep tuning in code for now.
-- (Later you can add preset import/export)
local function get_bool(key, default)
  local s = reaper.GetExtState(Config.SECTION, key)
  if s == "" then return default end
  return s == "1"
end

local function get_int(key, default)
  local s = reaper.GetExtState(Config.SECTION, key)
  if s == "" then return default end
  return tonumber(s) or default
end

local function set_bool(key, v)
  reaper.SetExtState(Config.SECTION, key, v and "1" or "0", true)
end

local function set_int(key, v)
  reaper.SetExtState(Config.SECTION, key, tostring(math.floor(v)), true)
end

function Config.load()
  local c = {}
  c.followPlay = get_bool("followPlay", Config.defaults.followPlay)
  c.followEditWhenStopped = get_bool("followEditWhenStopped", Config.defaults.followEditWhenStopped)

  c.prevBars = get_int("prevBars", Config.defaults.prevBars)
  c.nextBars = get_int("nextBars", Config.defaults.nextBars)

  -- Keep tuning as defaults for now (simplest; avoids table serialization)
  c.tuning = Config.defaults.tuning

  return c
end

function Config.save(c)
  set_bool("followPlay", c.followPlay)
  set_bool("followEditWhenStopped", c.followEditWhenStopped)
  set_int("prevBars", c.prevBars)
  set_int("nextBars", c.nextBars)
end

return Config
