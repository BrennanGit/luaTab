-- lib/config.lua
-- ExtState-backed config with defaults

local Config = {}

Config.SECTION = "luaTab"

Config.defaults = {
  followPlay = true,
  followEditWhenStopped = true,

  prevBars = 1,
  nextBars = 2,

  groupEpsilonMs = 5.0,

  -- Playability constraints
  maxFret = 15,
  maxFrettedSpan = 4,
  maxSimul = 4,
  reducePreferHighest = true, -- chosen

  showFirstTimeSigInSystemGutter = true,

  weights = {
    lowFret = 8,
    stayOnString = 6,
    stringJump = 4,
    fretJump = 4,
    highFret = 2,
  },

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

local function get_float(key, default)
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

local function set_float(key, v)
  reaper.SetExtState(Config.SECTION, key, tostring(v), true)
end

function Config.load()
  local c = {}
  c.followPlay = get_bool("followPlay", Config.defaults.followPlay)
  c.followEditWhenStopped = get_bool("followEditWhenStopped", Config.defaults.followEditWhenStopped)

  c.prevBars = get_int("prevBars", Config.defaults.prevBars)
  c.nextBars = get_int("nextBars", Config.defaults.nextBars)
  c.groupEpsilonMs = get_float("groupEpsilonMs", Config.defaults.groupEpsilonMs)

  c.maxFret = get_int("maxFret", Config.defaults.maxFret)
  c.maxFrettedSpan = get_int("maxFrettedSpan", Config.defaults.maxFrettedSpan)
  c.maxSimul = get_int("maxSimul", Config.defaults.maxSimul)
  c.reducePreferHighest = get_bool("reducePreferHighest", Config.defaults.reducePreferHighest)
  c.showFirstTimeSigInSystemGutter = get_bool(
    "showFirstTimeSigInSystemGutter",
    Config.defaults.showFirstTimeSigInSystemGutter
  )

  c.weights = Config.defaults.weights

  -- Keep tuning as defaults for now (simplest; avoids table serialization)
  c.tuning = Config.defaults.tuning

  return c
end

function Config.save(c)
  set_bool("followPlay", c.followPlay)
  set_bool("followEditWhenStopped", c.followEditWhenStopped)
  set_int("prevBars", c.prevBars)
  set_int("nextBars", c.nextBars)
  set_float("groupEpsilonMs", c.groupEpsilonMs)
  set_int("maxFret", c.maxFret)
  set_int("maxFrettedSpan", c.maxFrettedSpan)
  set_int("maxSimul", c.maxSimul)
  set_bool("reducePreferHighest", c.reducePreferHighest)
  set_bool("showFirstTimeSigInSystemGutter", c.showFirstTimeSigInSystemGutter)
end

return Config
