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

  sourceMode = "auto",
  channelFilter = 0,
  groupEpsilonMs = 8.0,
  minNoteLenMs = 0,

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

local number_keys = {
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
  "channelFilter",
  "groupEpsilonMs",
  "minNoteLenMs",
  "updateStep",
  "antidelayBeats",
  "fretboardPreNoteOffMs",
  "fretboardNextCount",
  "fretboardNextBars",
  "fretboardFrets",
  "fretboardNoteRoundness",
  "fretboardNoteSize",
  "fretboardDotSize",
  "fretboardFretThickness",
  "fretboardStringThickness",
}

local bool_keys = {
  "followPlay",
  "followEditWhenStopped",
  "logEnabled",
  "logVerbose",
  "fretboardHighlightNextNote",
  "tabHighlightCurrentNote",
  "reducePreferHighest",
  "showFirstTimeSigInSystemGutter",
}

local string_keys = {
  "logPath",
  "colorPreset",
  "stylePreset",
  "updateMode",
  "sourceMode",
  "fretboardMode",
  "fretboardNextStyle",
  "tuningPreset",
}

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

local weight_keys = {
  "lowFret",
  "stayOnString",
  "stringJump",
  "fretJump",
  "highFret",
}

local font_keys = {
  "fretScale",
  "timeSigScale",
  "droppedScale",
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

local function read_values(section, cfg, keys, reader)
  for _, key in ipairs(keys) do
    cfg[key] = reader(section, key, cfg[key])
  end
end

local function read_nested_values(section, cfg, table_key, keys, reader)
  cfg[table_key] = cfg[table_key] or {}
  for _, key in ipairs(keys) do
    cfg[table_key][key] = reader(section, table_key .. "." .. key, cfg[table_key][key])
  end
end

local function write_values(section, cfg, keys, defaults)
  for _, key in ipairs(keys) do
    local value = cfg[key]
    if value == nil and defaults then
      value = defaults[key]
    end
    write_value(section, key, value)
  end
end

local function write_nested_values(section, cfg, table_key, keys, defaults)
  local values = cfg[table_key] or {}
  local fallback = defaults and defaults[table_key] or {}
  for _, key in ipairs(keys) do
    local value = values[key]
    if value == nil then
      value = fallback[key]
    end
    write_value(section, table_key .. "." .. key, value)
  end
end

local function delete_values(section, keys)
  for _, key in ipairs(keys) do
    delete_value(section, key)
  end
end

local function delete_nested_values(section, prefix, keys)
  for _, key in ipairs(keys) do
    delete_value(section, prefix .. "." .. key)
  end
end

function config.load(section)
  local cfg = util.copy_table(config.defaults)
  local ns = section or "luaTab"

  read_values(ns, cfg, number_keys, read_number)
  read_values(ns, cfg, bool_keys, read_bool)
  read_values(ns, cfg, string_keys, read_string)
  read_nested_values(ns, cfg, "colors", color_keys, read_color)
  read_nested_values(ns, cfg, "fonts", font_keys, read_number)
  read_nested_values(ns, cfg, "weights", weight_keys, read_number)

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

  write_values(ns, cfg, number_keys, config.defaults)
  write_values(ns, cfg, bool_keys, config.defaults)
  write_values(ns, cfg, string_keys, config.defaults)
  for _, key in ipairs(color_keys) do
    write_color(ns, "colors." .. key, (cfg.colors and cfg.colors[key]) or config.defaults.colors[key])
  end
  write_nested_values(ns, cfg, "fonts", font_keys, config.defaults)
  write_nested_values(ns, cfg, "weights", weight_keys, config.defaults)

  write_value(ns, "tuning.count", #cfg.tuning)
  for i, string_info in ipairs(cfg.tuning) do
    write_value(ns, string.format("tuning.%d.name", i), string_info.name)
    write_value(ns, string.format("tuning.%d.open", i), string_info.open)
  end
end

function config.reset(section)
  local ns = section or "luaTab"
  delete_values(ns, number_keys)
  delete_values(ns, bool_keys)
  delete_values(ns, string_keys)
  delete_value(ns, "tuning.count")
  for _, key in ipairs(color_keys) do
    delete_color(ns, "colors." .. key)
  end
  delete_nested_values(ns, "weights", weight_keys)
  delete_nested_values(ns, "fonts", font_keys)

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
    for _, key in ipairs(color_keys) do
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

  local manual_override_count = read_number(ns, "manualOverrides.count", 0)
  for i = 1, manual_override_count do
    delete_value(ns, string.format("manualOverrides.%d.key", i))
    delete_value(ns, string.format("manualOverrides.%d.string", i))
    delete_value(ns, string.format("manualOverrides.%d.fret", i))
  end
  delete_value(ns, "manualOverrides.count")
end

return config
