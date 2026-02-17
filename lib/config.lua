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
    uiText = { 1.0, 1.0, 1.0, 1.0 },
    uiControlBg = { 0.18, 0.18, 0.18, 1.0 },
    strings = { 0.7, 0.7, 0.7, 1.0 },
    barlines = { 0.4, 0.4, 0.4, 1.0 },
    itemBoundary = { 0.7, 0.7, 0.7, 1.0 },
    text = { 1.0, 1.0, 1.0, 1.0 },
    dropped = { 1.0, 0.25, 0.25, 1.0 },
    marker = { 1.0, 0.2, 0.2, 0.18 },
    noteBg = { 0.05, 0.05, 0.05, 0.85 },
    fretboardBg = { 0.06, 0.06, 0.06, 1.0 },
    fretboardStrings = { 0.55, 0.55, 0.55, 1.0 },
    fretboardFrets = { 0.35, 0.35, 0.35, 1.0 },
    fretboardCurrent = { 0.2, 0.8, 0.3, 1.0 },
    fretboardNext = { 0.9, 0.7, 0.2, 1.0 },
  },

  colorPreset = "dark",
  stylePreset = "default",

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
  fretboardPreNoteOffMs = 50,
  fretboardHighlightNextNote = false,
  tabHighlightCurrentNote = false,

  fretboardMode = "hidden",
  fretboardNextCount = 6,
  fretboardNextBars = 2,
  fretboardNextStyle = "outline",
  fretboardFrets = 12,
  fretboardNoteRoundness = 0.3,
  fretboardNoteSize = 1.0,
  fretboardDotSize = 1.0,
  fretboardFretThickness = 1.0,
  fretboardStringThickness = 1.0,
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

local function delete_value(section, key)
  if reaper.DeleteExtState then
    reaper.DeleteExtState(section, key, true)
  else
    reaper.SetExtState(section, key, "", true)
  end
end

local function delete_color(section, key)
  delete_value(section, key .. ".r")
  delete_value(section, key .. ".g")
  delete_value(section, key .. ".b")
  delete_value(section, key .. ".a")
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
  cfg.colors.uiText = read_color(ns, "colors.uiText", cfg.colors.uiText)
  cfg.colors.uiControlBg = read_color(ns, "colors.uiControlBg", cfg.colors.uiControlBg)
  cfg.colors.text = read_color(ns, "colors.text", cfg.colors.text)
  cfg.colors.background = read_color(ns, "colors.background", cfg.colors.background)
  cfg.colors.dropped = read_color(ns, "colors.dropped", cfg.colors.dropped)
  cfg.colors.marker = read_color(ns, "colors.marker", cfg.colors.marker)
  cfg.colors.noteBg = read_color(ns, "colors.noteBg", cfg.colors.noteBg)
  cfg.colors.fretboardBg = read_color(ns, "colors.fretboardBg", cfg.colors.fretboardBg)
  cfg.colors.fretboardStrings = read_color(ns, "colors.fretboardStrings", cfg.colors.fretboardStrings)
  cfg.colors.fretboardFrets = read_color(ns, "colors.fretboardFrets", cfg.colors.fretboardFrets)
  cfg.colors.fretboardCurrent = read_color(ns, "colors.fretboardCurrent", cfg.colors.fretboardCurrent)
  cfg.colors.fretboardNext = read_color(ns, "colors.fretboardNext", cfg.colors.fretboardNext)

  cfg.maxFret = read_number(ns, "maxFret", cfg.maxFret)
  cfg.maxFrettedSpan = read_number(ns, "maxFrettedSpan", cfg.maxFrettedSpan)
  cfg.maxSimul = read_number(ns, "maxSimul", cfg.maxSimul)

  cfg.groupEpsilonMs = read_number(ns, "groupEpsilonMs", cfg.groupEpsilonMs)

  cfg.logEnabled = read_bool(ns, "logEnabled", cfg.logEnabled)
  cfg.logVerbose = read_bool(ns, "logVerbose", cfg.logVerbose)
  cfg.logPath = read_string(ns, "logPath", cfg.logPath)

  cfg.colorPreset = read_string(ns, "colorPreset", cfg.colorPreset)
  cfg.stylePreset = read_string(ns, "stylePreset", cfg.stylePreset)

  cfg.updateMode = read_string(ns, "updateMode", cfg.updateMode)
  cfg.updateStep = read_number(ns, "updateStep", cfg.updateStep)
  cfg.antidelayBeats = read_number(ns, "antidelayBeats", cfg.antidelayBeats)
  cfg.fretboardPreNoteOffMs = read_number(ns, "fretboardPreNoteOffMs", cfg.fretboardPreNoteOffMs)
  cfg.fretboardHighlightNextNote = read_bool(ns, "fretboardHighlightNextNote", cfg.fretboardHighlightNextNote)
  cfg.tabHighlightCurrentNote = read_bool(ns, "tabHighlightCurrentNote", cfg.tabHighlightCurrentNote)

  cfg.fretboardMode = read_string(ns, "fretboardMode", cfg.fretboardMode)
  cfg.fretboardNextCount = read_number(ns, "fretboardNextCount", cfg.fretboardNextCount)
  cfg.fretboardNextBars = read_number(ns, "fretboardNextBars", cfg.fretboardNextBars)
  cfg.fretboardNextStyle = read_string(ns, "fretboardNextStyle", cfg.fretboardNextStyle)
  cfg.fretboardFrets = read_number(ns, "fretboardFrets", cfg.fretboardFrets)
  cfg.fretboardNoteRoundness = read_number(ns, "fretboardNoteRoundness", cfg.fretboardNoteRoundness)
  cfg.fretboardNoteSize = read_number(ns, "fretboardNoteSize", cfg.fretboardNoteSize)
  cfg.fretboardDotSize = read_number(ns, "fretboardDotSize", cfg.fretboardDotSize)
  cfg.fretboardFretThickness = read_number(ns, "fretboardFretThickness", cfg.fretboardFretThickness)
  cfg.fretboardStringThickness = read_number(ns, "fretboardStringThickness", cfg.fretboardStringThickness)

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
  write_color(ns, "colors.uiText", cfg.colors and cfg.colors.uiText)
  write_color(ns, "colors.uiControlBg", cfg.colors and cfg.colors.uiControlBg)
  write_color(ns, "colors.text", cfg.colors and cfg.colors.text)
  write_color(ns, "colors.background", cfg.colors and cfg.colors.background)
  write_color(ns, "colors.dropped", cfg.colors and cfg.colors.dropped)
  write_color(ns, "colors.marker", cfg.colors and cfg.colors.marker)
  write_color(ns, "colors.noteBg", cfg.colors and cfg.colors.noteBg)
  write_color(ns, "colors.fretboardBg", cfg.colors and cfg.colors.fretboardBg)
  write_color(ns, "colors.fretboardStrings", cfg.colors and cfg.colors.fretboardStrings)
  write_color(ns, "colors.fretboardFrets", cfg.colors and cfg.colors.fretboardFrets)
  write_color(ns, "colors.fretboardCurrent", cfg.colors and cfg.colors.fretboardCurrent)
  write_color(ns, "colors.fretboardNext", cfg.colors and cfg.colors.fretboardNext)

  write_value(ns, "maxFret", cfg.maxFret)
  write_value(ns, "maxFrettedSpan", cfg.maxFrettedSpan)
  write_value(ns, "maxSimul", cfg.maxSimul)

  write_value(ns, "groupEpsilonMs", cfg.groupEpsilonMs)

  write_value(ns, "logEnabled", cfg.logEnabled)
  write_value(ns, "logVerbose", cfg.logVerbose)
  write_value(ns, "logPath", cfg.logPath or "")

  write_value(ns, "colorPreset", cfg.colorPreset or "dark")
  write_value(ns, "stylePreset", cfg.stylePreset or "default")

  write_value(ns, "updateMode", cfg.updateMode)
  write_value(ns, "updateStep", cfg.updateStep)
  write_value(ns, "antidelayBeats", cfg.antidelayBeats)
  write_value(ns, "fretboardPreNoteOffMs", cfg.fretboardPreNoteOffMs)
  write_value(ns, "fretboardHighlightNextNote", cfg.fretboardHighlightNextNote)
  write_value(ns, "tabHighlightCurrentNote", cfg.tabHighlightCurrentNote)

  write_value(ns, "fretboardMode", cfg.fretboardMode)
  write_value(ns, "fretboardNextCount", cfg.fretboardNextCount)
  write_value(ns, "fretboardNextBars", cfg.fretboardNextBars)
  write_value(ns, "fretboardNextStyle", cfg.fretboardNextStyle)
  write_value(ns, "fretboardFrets", cfg.fretboardFrets)
  write_value(ns, "fretboardNoteRoundness", cfg.fretboardNoteRoundness)
  write_value(ns, "fretboardNoteSize", cfg.fretboardNoteSize)
  write_value(ns, "fretboardDotSize", cfg.fretboardDotSize)
  write_value(ns, "fretboardFretThickness", cfg.fretboardFretThickness)
  write_value(ns, "fretboardStringThickness", cfg.fretboardStringThickness)

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

function config.reset(section)
  local ns = section or "luaTab"
  local keys = {
    "followPlay",
    "followEditWhenStopped",
    "prevBars",
    "nextBars",
    "systemGutterPx",
    "barPrefixPx",
    "barContentPx",
    "barGutterPx",
    "systemRowGapPx",
    "staffPaddingTopPx",
    "staffPaddingBottomPx",
    "stringSpacingPx",
    "barLineThickness",
    "itemBoundaryThickness",
    "maxFret",
    "maxFrettedSpan",
    "maxSimul",
    "groupEpsilonMs",
    "logEnabled",
    "logVerbose",
    "logPath",
    "colorPreset",
    "stylePreset",
    "updateMode",
    "updateStep",
    "antidelayBeats",
    "fretboardPreNoteOffMs",
    "fretboardHighlightNextNote",
    "tabHighlightCurrentNote",
    "fretboardMode",
    "fretboardNextCount",
    "fretboardNextBars",
    "fretboardNextStyle",
    "fretboardFrets",
    "fretboardNoteRoundness",
    "fretboardNoteSize",
    "fretboardDotSize",
    "fretboardFretThickness",
    "fretboardStringThickness",
    "tuningPreset",
    "reducePreferHighest",
    "showFirstTimeSigInSystemGutter",
    "tuning.count",
  }
  for _, key in ipairs(keys) do
    delete_value(ns, key)
  end

  local color_keys = {
    "background",
    "uiText",
    "uiControlBg",
    "strings",
    "barlines",
    "itemBoundary",
    "text",
    "dropped",
    "marker",
    "noteBg",
    "fretboardBg",
    "fretboardStrings",
    "fretboardFrets",
    "fretboardCurrent",
    "fretboardNext",
  }
  for _, key in ipairs(color_keys) do
    delete_color(ns, "colors." .. key)
  end

  local weight_keys = {
    "lowFret",
    "stayOnString",
    "stringJump",
    "fretJump",
    "highFret",
  }
  for _, key in ipairs(weight_keys) do
    delete_value(ns, "weights." .. key)
  end

  local font_keys = {
    "fretScale",
    "timeSigScale",
    "droppedScale",
  }
  for _, key in ipairs(font_keys) do
    delete_value(ns, "fonts." .. key)
  end

  if reaper.HasExtState then
    local i = 1
    while reaper.HasExtState(ns, string.format("tuning.%d.name", i))
      or reaper.HasExtState(ns, string.format("tuning.%d.open", i)) do
      delete_value(ns, string.format("tuning.%d.name", i))
      delete_value(ns, string.format("tuning.%d.open", i))
      i = i + 1
      if i > 64 then
        break
      end
    end
  end

  local user_color_keys = {
    "background",
    "uiText",
    "uiControlBg",
    "strings",
    "barlines",
    "itemBoundary",
    "text",
    "dropped",
    "marker",
    "noteBg",
    "fretboardBg",
    "fretboardStrings",
    "fretboardFrets",
    "fretboardCurrent",
    "fretboardNext",
  }

  local user_tuning_count = read_number(ns, "userPresets.tuning.count", 0)
  local max_tuning = math.max(user_tuning_count, 64)
  for i = 1, max_tuning do
    local base = string.format("userPresets.tuning.%d", i)
    local has_entry = reaper.HasExtState(ns, base .. ".name") or reaper.HasExtState(ns, base .. ".count")
    if not has_entry and i > user_tuning_count then
      break
    end
    local string_count = read_number(ns, base .. ".count", 0)
    delete_value(ns, base .. ".name")
    delete_value(ns, base .. ".count")
    for j = 1, string_count do
      delete_value(ns, string.format("%s.string.%d.name", base, j))
      delete_value(ns, string.format("%s.string.%d.open", base, j))
    end
  end
  delete_value(ns, "userPresets.tuning.count")

  local user_color_count = read_number(ns, "userPresets.colors.count", 0)
  local max_colors = math.max(user_color_count, 64)
  for i = 1, max_colors do
    local base = string.format("userPresets.colors.%d", i)
    local has_entry = reaper.HasExtState(ns, base .. ".name")
    if not has_entry and i > user_color_count then
      break
    end
    delete_value(ns, base .. ".name")
    for _, key in ipairs(user_color_keys) do
      delete_color(ns, string.format("%s.colors.%s", base, key))
    end
  end
  delete_value(ns, "userPresets.colors.count")

  local user_scale_count = read_number(ns, "userPresets.style.count", 0)
  local max_scales = math.max(user_scale_count, 64)
  for i = 1, max_scales do
    local base = string.format("userPresets.style.%d", i)
    local has_entry = reaper.HasExtState(ns, base .. ".name")
    if not has_entry and i > user_scale_count then
      break
    end
    delete_value(ns, base .. ".name")
    local scale_keys = {
      "systemGutterPx",
      "barPrefixPx",
      "barContentPx",
      "barGutterPx",
      "systemRowGapPx",
      "staffPaddingTopPx",
      "staffPaddingBottomPx",
      "stringSpacingPx",
      "barLineThickness",
      "itemBoundaryThickness",
    }
    for _, key in ipairs(scale_keys) do
      delete_value(ns, string.format("%s.%s", base, key))
    end
    local font_keys = {
      "fretScale",
      "timeSigScale",
      "droppedScale",
    }
    for _, key in ipairs(font_keys) do
      delete_value(ns, string.format("%s.fonts.%s", base, key))
    end
  end
  delete_value(ns, "userPresets.style.count")
end

return config
