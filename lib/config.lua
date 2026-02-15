local util = require("util")

local config = {}

config.defaults = {
  followPlay = true,
  followEditWhenStopped = true,

  prevBars = 1,
  nextBars = 2,

  systemGutterPx = 60,
  barPrefixPx = 16,
  barContentPx = 120,
  barGutterPx = 8,
  systemRowGapPx = 16,
  staffPaddingTopPx = 10,
  staffPaddingBottomPx = 10,
  stringSpacingPx = 14,
  barLineThickness = 1.0,
  itemBoundaryThickness = 2.5,

  tuning = {
    { name = "G", open = 55 },
    { name = "D", open = 62 },
    { name = "A", open = 69 },
    { name = "E", open = 76 },
  },

  maxFret = 15,
  maxFrettedSpan = 4,
  maxSimul = 4,

  weights = {
    lowFret = 8,
    stayOnString = 6,
    stringJump = 4,
    fretJump = 4,
    highFret = 2,
  },

  reducePreferHighest = true,
  showFirstTimeSigInSystemGutter = true,
  preloadSeconds = 2.0,

  groupEpsilonMs = 8.0,

  logEnabled = true,
  logVerbose = false,

  updateMode = "bar",
  updateStep = 1,
  antidelayBeats = 0,
}

local function read_number(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = tonumber(reaper.GetExtState(section, key))
    if value ~= nil then
      return value
    end
  end
  return fallback
end

local function read_bool(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = reaper.GetExtState(section, key)
    if value == "true" then return true end
    if value == "false" then return false end
  end
  return fallback
end

local function read_string(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = reaper.GetExtState(section, key)
    if value ~= "" then
      return value
    end
  end
  return fallback
end

local function write_value(section, key, value)
  reaper.SetExtState(section, key, tostring(value), true)
end

function config.load(section)
  local cfg = util.copy_table(config.defaults)
  local ns = section or "luaTab"

  cfg.followPlay = read_bool(ns, "followPlay", cfg.followPlay)
  cfg.followEditWhenStopped = read_bool(ns, "followEditWhenStopped", cfg.followEditWhenStopped)

  cfg.prevBars = read_number(ns, "prevBars", cfg.prevBars)
  cfg.nextBars = read_number(ns, "nextBars", cfg.nextBars)

  cfg.systemGutterPx = read_number(ns, "systemGutterPx", cfg.systemGutterPx)
  cfg.barPrefixPx = read_number(ns, "barPrefixPx", cfg.barPrefixPx)
  cfg.barContentPx = read_number(ns, "barContentPx", cfg.barContentPx)
  cfg.barGutterPx = read_number(ns, "barGutterPx", cfg.barGutterPx)
  cfg.systemRowGapPx = read_number(ns, "systemRowGapPx", cfg.systemRowGapPx)
  cfg.staffPaddingTopPx = read_number(ns, "staffPaddingTopPx", cfg.staffPaddingTopPx)
  cfg.staffPaddingBottomPx = read_number(ns, "staffPaddingBottomPx", cfg.staffPaddingBottomPx)
  cfg.stringSpacingPx = read_number(ns, "stringSpacingPx", cfg.stringSpacingPx)
  cfg.barLineThickness = read_number(ns, "barLineThickness", cfg.barLineThickness)
  cfg.itemBoundaryThickness = read_number(ns, "itemBoundaryThickness", cfg.itemBoundaryThickness)

  cfg.maxFret = read_number(ns, "maxFret", cfg.maxFret)
  cfg.maxFrettedSpan = read_number(ns, "maxFrettedSpan", cfg.maxFrettedSpan)
  cfg.maxSimul = read_number(ns, "maxSimul", cfg.maxSimul)

  cfg.groupEpsilonMs = read_number(ns, "groupEpsilonMs", cfg.groupEpsilonMs)

  cfg.logEnabled = read_bool(ns, "logEnabled", cfg.logEnabled)
  cfg.logVerbose = read_bool(ns, "logVerbose", cfg.logVerbose)

  cfg.updateMode = read_string(ns, "updateMode", cfg.updateMode)
  cfg.updateStep = read_number(ns, "updateStep", cfg.updateStep)
  cfg.antidelayBeats = read_number(ns, "antidelayBeats", cfg.antidelayBeats)

  cfg.weights.lowFret = read_number(ns, "weights.lowFret", cfg.weights.lowFret)
  cfg.weights.stayOnString = read_number(ns, "weights.stayOnString", cfg.weights.stayOnString)
  cfg.weights.stringJump = read_number(ns, "weights.stringJump", cfg.weights.stringJump)
  cfg.weights.fretJump = read_number(ns, "weights.fretJump", cfg.weights.fretJump)
  cfg.weights.highFret = read_number(ns, "weights.highFret", cfg.weights.highFret)

  cfg.reducePreferHighest = read_bool(ns, "reducePreferHighest", cfg.reducePreferHighest)
  cfg.showFirstTimeSigInSystemGutter = read_bool(ns, "showFirstTimeSigInSystemGutter", cfg.showFirstTimeSigInSystemGutter)

  local string_count = read_number(ns, "tuning.count", #cfg.tuning)
  local tuning = {}
  for i = 1, string_count do
    local name = reaper.GetExtState(ns, string.format("tuning.%d.name", i))
    local open = read_number(ns, string.format("tuning.%d.open", i), nil)
    if name ~= "" and open ~= nil then
      tuning[#tuning + 1] = { name = name, open = open }
    end
  end
  if #tuning > 0 then
    cfg.tuning = tuning
  end

  return cfg
end

function config.save(cfg, section)
  local ns = section or "luaTab"

  write_value(ns, "followPlay", cfg.followPlay)
  write_value(ns, "followEditWhenStopped", cfg.followEditWhenStopped)

  write_value(ns, "prevBars", cfg.prevBars)
  write_value(ns, "nextBars", cfg.nextBars)

  write_value(ns, "systemGutterPx", cfg.systemGutterPx)
  write_value(ns, "barPrefixPx", cfg.barPrefixPx)
  write_value(ns, "barContentPx", cfg.barContentPx)
  write_value(ns, "barGutterPx", cfg.barGutterPx)
  write_value(ns, "systemRowGapPx", cfg.systemRowGapPx)
  write_value(ns, "staffPaddingTopPx", cfg.staffPaddingTopPx)
  write_value(ns, "staffPaddingBottomPx", cfg.staffPaddingBottomPx)
  write_value(ns, "stringSpacingPx", cfg.stringSpacingPx)
  write_value(ns, "barLineThickness", cfg.barLineThickness)
  write_value(ns, "itemBoundaryThickness", cfg.itemBoundaryThickness)

  write_value(ns, "maxFret", cfg.maxFret)
  write_value(ns, "maxFrettedSpan", cfg.maxFrettedSpan)
  write_value(ns, "maxSimul", cfg.maxSimul)

  write_value(ns, "groupEpsilonMs", cfg.groupEpsilonMs)

  write_value(ns, "logEnabled", cfg.logEnabled)
  write_value(ns, "logVerbose", cfg.logVerbose)

  write_value(ns, "updateMode", cfg.updateMode)
  write_value(ns, "updateStep", cfg.updateStep)
  write_value(ns, "antidelayBeats", cfg.antidelayBeats)

  write_value(ns, "weights.lowFret", cfg.weights.lowFret)
  write_value(ns, "weights.stayOnString", cfg.weights.stayOnString)
  write_value(ns, "weights.stringJump", cfg.weights.stringJump)
  write_value(ns, "weights.fretJump", cfg.weights.fretJump)
  write_value(ns, "weights.highFret", cfg.weights.highFret)

  write_value(ns, "reducePreferHighest", cfg.reducePreferHighest)
  write_value(ns, "showFirstTimeSigInSystemGutter", cfg.showFirstTimeSigInSystemGutter)

  write_value(ns, "tuning.count", #cfg.tuning)
  for i, string_info in ipairs(cfg.tuning) do
    write_value(ns, string.format("tuning.%d.name", i), string_info.name)
    write_value(ns, string.format("tuning.%d.open", i), string_info.open)
  end
end

return config
