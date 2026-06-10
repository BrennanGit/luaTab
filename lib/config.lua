local util = require("util")
local store = require("store")

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

  showFirstTimeSigInSystemGutter = true,

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

config.number_keys = {
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

config.bool_keys = {
  "followPlay",
  "followEditWhenStopped",
  "logEnabled",
  "logVerbose",
  "fretboardHighlightNextNote",
  "tabHighlightCurrentNote",
  "showFirstTimeSigInSystemGutter",
}

config.string_keys = {
  "logPath",
  "colorPreset",
  "stylePreset",
  "updateMode",
  "sourceMode",
  "fretboardMode",
  "fretboardNextStyle",
  "tuningPreset",
}

config.color_keys = {
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

config.weight_keys = {
  "lowFret",
  "stayOnString",
  "stringJump",
  "fretJump",
  "highFret",
}

config.font_keys = {
  "fretScale",
  "timeSigScale",
  "droppedScale",
}

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
    store.write(section, key, value)
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
    store.write(section, table_key .. "." .. key, value)
  end
end

function config.load(section)
  local cfg = util.copy_table(config.defaults)
  local ns = section or "luaTab"

  read_values(ns, cfg, config.number_keys, store.read_number)
  read_values(ns, cfg, config.bool_keys, store.read_bool)
  read_values(ns, cfg, config.string_keys, store.read_string)
  read_nested_values(ns, cfg, "colors", config.color_keys, store.read_color)
  read_nested_values(ns, cfg, "fonts", config.font_keys, store.read_number)
  read_nested_values(ns, cfg, "weights", config.weight_keys, store.read_number)

  local string_count = store.read_number(ns, "tuning.count", #cfg.tuning)
  local tuning = {}
  for i = 1, string_count do
    local name = store.read_string(ns, string.format("tuning.%d.name", i), "")
    local open = store.read_number(ns, string.format("tuning.%d.open", i), nil)
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

  write_values(ns, cfg, config.number_keys, config.defaults)
  write_values(ns, cfg, config.bool_keys, config.defaults)
  write_values(ns, cfg, config.string_keys, config.defaults)
  for _, key in ipairs(config.color_keys) do
    store.write_color(ns, "colors." .. key, (cfg.colors and cfg.colors[key]) or config.defaults.colors[key])
  end
  write_nested_values(ns, cfg, "fonts", config.font_keys, config.defaults)
  write_nested_values(ns, cfg, "weights", config.weight_keys, config.defaults)

  store.write(ns, "tuning.count", #cfg.tuning)
  for i, string_info in ipairs(cfg.tuning) do
    store.write(ns, string.format("tuning.%d.name", i), string_info.name)
    store.write(ns, string.format("tuning.%d.open", i), string_info.open)
  end
end

-- Deletes persisted config values. User presets and manual overrides are owned
-- by lib/presets.lua (presets.clear_all).
function config.reset(section)
  local ns = section or "luaTab"
  for _, keys in ipairs({ config.number_keys, config.bool_keys, config.string_keys }) do
    for _, key in ipairs(keys) do
      store.delete(ns, key)
    end
  end
  for _, key in ipairs(config.color_keys) do
    store.delete_color(ns, "colors." .. key)
  end
  for _, key in ipairs(config.weight_keys) do
    store.delete(ns, "weights." .. key)
  end
  for _, key in ipairs(config.font_keys) do
    store.delete(ns, "fonts." .. key)
  end

  store.delete(ns, "tuning.count")
  local i = 1
  while store.has(ns, string.format("tuning.%d.name", i))
    or store.has(ns, string.format("tuning.%d.open", i)) do
    store.delete(ns, string.format("tuning.%d.name", i))
    store.delete(ns, string.format("tuning.%d.open", i))
    i = i + 1
    if i > 64 then
      break
    end
  end
end

-- Renders the current settings as a Lua snippet, driven by the same key
-- metadata used for persistence so it cannot drift from the schema.
function config.export_lua(cfg)
  local function fmt(value)
    local t = type(value)
    if t == "string" then
      return string.format("%q", value)
    elseif t == "boolean" then
      return value and "true" or "false"
    elseif t == "number" then
      return tostring(value)
    end
    return "nil"
  end

  local lines = { "luaTab_settings = {" }
  for _, key in ipairs(config.bool_keys) do
    lines[#lines + 1] = string.format("  %s = %s,", key, fmt(cfg[key]))
  end
  for _, key in ipairs(config.number_keys) do
    lines[#lines + 1] = string.format("  %s = %s,", key, fmt(cfg[key]))
  end
  for _, key in ipairs(config.string_keys) do
    lines[#lines + 1] = string.format("  %s = %s,", key, fmt(cfg[key]))
  end
  lines[#lines + 1] = "  colors = {"
  for _, key in ipairs(config.color_keys) do
    local color = cfg.colors and cfg.colors[key]
    if color then
      lines[#lines + 1] = string.format(
        "    %s = { %.4f, %.4f, %.4f, %.4f },",
        key, color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1
      )
    end
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  tuning = {"
  for _, string_info in ipairs(cfg.tuning or {}) do
    lines[#lines + 1] = string.format("    { name = %q, open = %d },", string_info.name, string_info.open)
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  weights = {"
  for _, key in ipairs(config.weight_keys) do
    lines[#lines + 1] = string.format("    %s = %s,", key, fmt(cfg.weights and cfg.weights[key]))
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  fonts = {"
  for _, key in ipairs(config.font_keys) do
    lines[#lines + 1] = string.format("    %s = %s,", key, fmt(cfg.fonts and cfg.fonts[key]))
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

return config
