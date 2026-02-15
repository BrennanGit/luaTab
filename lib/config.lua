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

  colors = {
    background = { 0.08, 0.08, 0.08, 1.0 },
    strings = { 0.7, 0.7, 0.7, 1.0 },
    barlines = { 0.4, 0.4, 0.4, 1.0 },
    itemBoundary = { 0.7, 0.7, 0.7, 1.0 },
    text = { 1.0, 1.0, 1.0, 1.0 },
    dropped = { 1.0, 0.25, 0.25, 1.0 },
    marker = { 1.0, 0.2, 0.2, 0.18 },
    noteBg = { 0.05, 0.05, 0.05, 0.85 },
  },

  colorPreset = "dark",

  tuning = {
    { name = "G", open = 55 },
    { name = "D", open = 62 },
    { name = "A", open = 69 },
    { name = "E", open = 76 },
  },

  tuningPreset = "mandolin",

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
  logPath = "",

  fonts = {
    fretScale = 1.0,
    timeSigScale = 1.4,
    droppedScale = 0.8,
  },

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

local function read_color(section, key, fallback)
  local r = read_number(section, key .. ".r", nil)
  local g = read_number(section, key .. ".g", nil)
  local b = read_number(section, key .. ".b", nil)
  local a = read_number(section, key .. ".a", nil)
  if r == nil and g == nil and b == nil and a == nil then
    return fallback
  end
  return {
    r or fallback[1],
    g or fallback[2],
    b or fallback[3],
    a or fallback[4],
  }
end

local function write_value(section, key, value)
  reaper.SetExtState(section, key, tostring(value), true)
end

local function write_color(section, key, color)
  if not color then return end
  write_value(section, key .. ".r", color[1])
  write_value(section, key .. ".g", color[2])
  write_value(section, key .. ".b", color[3])
  write_value(section, key .. ".a", color[4])
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

  cfg.colors.strings = read_color(ns, "colors.strings", cfg.colors.strings)
  cfg.colors.barlines = read_color(ns, "colors.barlines", cfg.colors.barlines)
  cfg.colors.itemBoundary = read_color(ns, "colors.itemBoundary", cfg.colors.itemBoundary)
  cfg.colors.text = read_color(ns, "colors.text", cfg.colors.text)
  cfg.colors.background = read_color(ns, "colors.background", cfg.colors.background)
  cfg.colors.dropped = read_color(ns, "colors.dropped", cfg.colors.dropped)
  cfg.colors.marker = read_color(ns, "colors.marker", cfg.colors.marker)
  cfg.colors.noteBg = read_color(ns, "colors.noteBg", cfg.colors.noteBg)

  cfg.maxFret = read_number(ns, "maxFret", cfg.maxFret)
  cfg.maxFrettedSpan = read_number(ns, "maxFrettedSpan", cfg.maxFrettedSpan)
  cfg.maxSimul = read_number(ns, "maxSimul", cfg.maxSimul)

  cfg.groupEpsilonMs = read_number(ns, "groupEpsilonMs", cfg.groupEpsilonMs)

  cfg.logEnabled = read_bool(ns, "logEnabled", cfg.logEnabled)
  cfg.logVerbose = read_bool(ns, "logVerbose", cfg.logVerbose)
  cfg.logPath = read_string(ns, "logPath", cfg.logPath)

  cfg.colorPreset = read_string(ns, "colorPreset", cfg.colorPreset)

  cfg.updateMode = read_string(ns, "updateMode", cfg.updateMode)
  cfg.updateStep = read_number(ns, "updateStep", cfg.updateStep)
  cfg.antidelayBeats = read_number(ns, "antidelayBeats", cfg.antidelayBeats)

  cfg.tuningPreset = read_string(ns, "tuningPreset", cfg.tuningPreset)

  cfg.fonts.fretScale = read_number(ns, "fonts.fretScale", cfg.fonts.fretScale)
  cfg.fonts.timeSigScale = read_number(ns, "fonts.timeSigScale", cfg.fonts.timeSigScale)
  cfg.fonts.droppedScale = read_number(ns, "fonts.droppedScale", cfg.fonts.droppedScale)

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

  write_color(ns, "colors.strings", cfg.colors and cfg.colors.strings)
  write_color(ns, "colors.barlines", cfg.colors and cfg.colors.barlines)
  write_color(ns, "colors.itemBoundary", cfg.colors and cfg.colors.itemBoundary)
  write_color(ns, "colors.text", cfg.colors and cfg.colors.text)
  write_color(ns, "colors.background", cfg.colors and cfg.colors.background)
  write_color(ns, "colors.dropped", cfg.colors and cfg.colors.dropped)
  write_color(ns, "colors.marker", cfg.colors and cfg.colors.marker)
  write_color(ns, "colors.noteBg", cfg.colors and cfg.colors.noteBg)

  write_value(ns, "maxFret", cfg.maxFret)
  write_value(ns, "maxFrettedSpan", cfg.maxFrettedSpan)
  write_value(ns, "maxSimul", cfg.maxSimul)

  write_value(ns, "groupEpsilonMs", cfg.groupEpsilonMs)

  write_value(ns, "logEnabled", cfg.logEnabled)
  write_value(ns, "logVerbose", cfg.logVerbose)
  write_value(ns, "logPath", cfg.logPath or "")

  write_value(ns, "colorPreset", cfg.colorPreset or "dark")

  write_value(ns, "updateMode", cfg.updateMode)
  write_value(ns, "updateStep", cfg.updateStep)
  write_value(ns, "antidelayBeats", cfg.antidelayBeats)

  write_value(ns, "tuningPreset", cfg.tuningPreset or "custom")

  write_value(ns, "fonts.fretScale", cfg.fonts and cfg.fonts.fretScale or 1.0)
  write_value(ns, "fonts.timeSigScale", cfg.fonts and cfg.fonts.timeSigScale or 1.4)
  write_value(ns, "fonts.droppedScale", cfg.fonts and cfg.fonts.droppedScale or 0.8)

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
