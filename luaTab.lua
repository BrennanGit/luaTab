-- @description luaTab: Tab HUD (Toggle)


local SECTION = "luaTab"
local KEY_RUNNING = "running"
local KEY_QUIT = "quit"
local KEY_HEARTBEAT = "heartbeat"
local HEARTBEAT_STALE_SEC = 3.0

local _, _, section_id, cmd_id = reaper.get_action_context()

local function set_toggle(on)
  if section_id and cmd_id then
    reaper.SetToggleCommandState(section_id, cmd_id, on and 1 or 0)
    reaper.RefreshToolbar2(section_id, cmd_id)
  end
end

local function now_time()
  return reaper.time_precise and reaper.time_precise() or os.clock()
end

local function heartbeat_time()
  return tonumber(reaper.GetExtState(SECTION, KEY_HEARTBEAT))
end

if reaper.GetExtState(SECTION, KEY_RUNNING) == "1" then
  local hb = heartbeat_time()
  local now = now_time()
  if hb and (now - hb) < HEARTBEAT_STALE_SEC then
    reaper.SetExtState(SECTION, KEY_QUIT, "1", false)
    return
  end
  reaper.SetExtState(SECTION, KEY_RUNNING, "0", false)
  reaper.SetExtState(SECTION, KEY_QUIT, "0", false)
  reaper.SetExtState(SECTION, KEY_HEARTBEAT, "0", false)
  set_toggle(false)
end

reaper.SetExtState(SECTION, KEY_RUNNING, "1", false)
reaper.SetExtState(SECTION, KEY_QUIT, "0", false)
reaper.SetExtState(SECTION, KEY_HEARTBEAT, tostring(now_time()), false)
set_toggle(true)

local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then
  source = source:sub(2)
end
local script_dir = source:match("^(.*)[/\\].-$") or "."
package.path = package.path .. ";" .. script_dir .. "/lib/?.lua"

local util = require("util")
local Panels = require("ui_panels")
local config_mod = require("config")
local timeline = require("timeline")
local layout = require("layout")
local midi = require("midi")
local source = require("source")
local frets = require("frets")
local render = require("render")

local ctx
local cleaned = false

local RESET_MARKER = script_dir .. "/luaTab.reset"

local function reset_imgui_ini()
  if not ctx or not reaper.ImGui_GetIniFilename then
    return false 
  end
  local ini_path = reaper.ImGui_GetIniFilename(ctx)
  if ini_path and ini_path ~= "" then
    os.remove(ini_path)
    return true
  end
  return false
end

local function reset_config_from_marker()
  local file = io.open(RESET_MARKER, "r")
  if not file then
    return false
  end
  file:close()
  os.remove(RESET_MARKER)
  if config_mod.reset then
    config_mod.reset(SECTION)
  end
  reset_imgui_ini()
  return true
end

local function cleanup()
  if cleaned then return end
  cleaned = true
  reaper.SetExtState(SECTION, KEY_RUNNING, "0", false)
  reaper.SetExtState(SECTION, KEY_QUIT, "0", false)
  reaper.SetExtState(SECTION, KEY_HEARTBEAT, "0", false)
  set_toggle(false)
  if ctx and reaper.ImGui_DestroyContext then
    reaper.ImGui_DestroyContext(ctx)
    ctx = nil
  end
end

reaper.atexit(cleanup)

if not reaper.APIExists or not reaper.APIExists("ImGui_CreateContext") then
  reaper.MB("ReaImGui not available. Install ReaImGui (ReaPack).", "luaTab", 0)
  cleanup()
  return
end

ctx = reaper.ImGui_CreateContext("luaTab")
local reset_requested = reset_config_from_marker()
local cfg = config_mod.load("luaTab")
if not cfg.logPath or cfg.logPath == "" then
  cfg.logPath = script_dir .. "/luaTab.log"
end
local force_verbose_logs = false
local log_enabled = cfg.logEnabled or force_verbose_logs
local log_verbose = cfg.logVerbose or force_verbose_logs
util.log_init(script_dir, log_enabled, log_verbose, cfg.logPath)
Panels.DEBUG = log_verbose
Panels.log = function(msg)
  util.log("panels: " .. tostring(msg), "debug")
end
util.log("luaTab started", "info")
if reset_requested then
  util.log("settings reset via marker file", "info")
end

local state = {
  lastBarIdx = nil,
  bars = {},
  systems = {},
  eventsByBar = {},
  takeId = nil,
  assignmentState = frets.new_state(#cfg.tuning),
  hasMidiTake = false,
  statusMessage = nil,
  windowInitialized = false,
  takeSource = nil,
  lastUpdateKey = nil,
  itemBounds = nil,
  panels = {
    main = { value = true },
    fretboard = { value = cfg.fretboardMode ~= "hidden" },
    settings = { value = false },
    colorPicker = { value = false },
  },
  fretboardPanelOpen = cfg.fretboardMode ~= "hidden",
  lastHeartbeat = 0,
  colorHex = {},
  colorPickerKey = "background",
  logPathBuf = nil,
  prevBarsBuf = nil,
  nextBarsBuf = nil,
  settingsWindowInitialized = false,
  fretboardWindowInitialized = false,
  colorPickerWindowInitialized = false,
  fretboardFocused = false,
  panelLayout = {
    main = {},
    settings = {},
    fretboard = {},
    colorPicker = {},
  },
  pendingLayout = nil,
  presetSave = {
    open = false,
    kind = nil,
    name = "",
    confirmOverwrite = false,
    confirmName = nil,
    confirmType = nil,
    error = nil,
    focusName = false,
  },
  fretboardLastMode = "current",
}

local default_tuning_presets = {
  {
    id = "mandolin",
    label = "Mandolin (GDAE)",
    name = "Mandolin (GDAE)",
    tuning = {
      { name = "G", open = 55 },
      { name = "D", open = 62 },
      { name = "A", open = 69 },
      { name = "E", open = 76 },
    },
  },
  {
    id = "guitar",
    label = "Guitar (EADGBe)",
    name = "Guitar (EADGBe)",
    tuning = {
      { name = "E", open = 40 },
      { name = "A", open = 45 },
      { name = "D", open = 50 },
      { name = "G", open = 55 },
      { name = "B", open = 59 },
      { name = "E", open = 64 },
    },
  },
  {
    id = "bass",
    label = "Bass (EADG)",
    name = "Bass (EADG)",
    tuning = {
      { name = "E", open = 28 },
      { name = "A", open = 33 },
      { name = "D", open = 38 },
      { name = "G", open = 43 },
    },
  },
}

local custom_tuning_preset = {
  id = "custom",
  label = "Current (custom)",
  name = "Current (custom)",
}

local default_color_presets = {
  {
    id = "dark",
    label = "Dark",
    name = "Dark",
    colors = {
      background = { 0.08, 0.08, 0.08, 1.0 },
      uiText = { 0.92, 0.92, 0.92, 1.0 },
      uiControlBg = { 0.18, 0.18, 0.18, 1.0 },
      text = { 1.0, 1.0, 1.0, 1.0 },
      strings = { 0.7, 0.7, 0.7, 1.0 },
      barlines = { 0.4, 0.4, 0.4, 1.0 },
      itemBoundary = { 0.7, 0.7, 0.7, 1.0 },
      dropped = { 1.0, 0.25, 0.25, 1.0 },
      marker = { 1.0, 0.2, 0.2, 0.18 },
      noteBg = { 0.05, 0.05, 0.05, 0.85 },
      fretboardBg = { 0.06, 0.06, 0.06, 1.0 },
      fretboardStrings = { 0.55, 0.55, 0.55, 1.0 },
      fretboardFrets = { 0.35, 0.35, 0.35, 1.0 },
      fretboardCurrent = { 0.2, 0.8, 0.3, 1.0 },
      fretboardNext = { 0.9, 0.7, 0.2, 1.0 },
    },
  },
  {
    id = "light",
    label = "Light",
    name = "Light",
    colors = {
      background = { 0.96, 0.96, 0.96, 1.0 },
      uiText = { 0.1, 0.1, 0.1, 1.0 },
      uiControlBg = { 0.82, 0.82, 0.82, 1.0 },
      text = { 0.08, 0.08, 0.08, 1.0 },
      strings = { 0.35, 0.35, 0.35, 1.0 },
      barlines = { 0.2, 0.2, 0.2, 1.0 },
      itemBoundary = { 0.2, 0.2, 0.2, 1.0 },
      dropped = { 0.75, 0.1, 0.1, 1.0 },
      marker = { 0.2, 0.4, 0.9, 0.18 },
      noteBg = { 1.0, 1.0, 1.0, 0.85 },
      fretboardBg = { 0.98, 0.98, 0.98, 1.0 },
      fretboardStrings = { 0.35, 0.35, 0.35, 1.0 },
      fretboardFrets = { 0.25, 0.25, 0.25, 1.0 },
      fretboardCurrent = { 0.1, 0.6, 0.2, 1.0 },
      fretboardNext = { 0.9, 0.6, 0.1, 1.0 },
    },
  },
}

local scale_value_keys = {
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
  "fretboardFrets",
  "fretboardNoteRoundness",
  "fretboardNoteSize",
  "fretboardDotSize",
  "fretboardFretThickness",
  "fretboardStringThickness",
}

local scale_font_keys = {
  "fretScale",
  "timeSigScale",
  "droppedScale",
}

local layout_value_keys = {
  "prevBars",
  "nextBars",
  "updateStep",
  "antidelayBeats",
}

local layout_string_keys = {
  "updateMode",
}

local layout_panel_keys = {
  "main",
  "settings",
  "fretboard",
  "colorPicker",
}

local function build_default_layout_preset()
  return {
    prevBars = config_mod.defaults.prevBars,
    nextBars = config_mod.defaults.nextBars,
    updateMode = config_mod.defaults.updateMode,
    updateStep = config_mod.defaults.updateStep,
    antidelayBeats = config_mod.defaults.antidelayBeats,
    panels = {
      main = { open = true, pos = { 100, 100 }, size = { 900, 360 } },
      settings = { open = false, pos = { 120, 120 }, size = { 560, 520 } },
      fretboard = { open = config_mod.defaults.fretboardMode ~= "hidden", pos = { 140, 180 }, size = { 520, 220 } },
      colorPicker = { open = false, pos = { 160, 200 }, size = { 520, 420 } },
    },
  }
end

local function capture_scale_values(source)
  local scale = {}
  for _, key in ipairs(scale_value_keys) do
    scale[key] = source[key]
  end
  scale.fonts = {}
  for _, key in ipairs(scale_font_keys) do
    scale.fonts[key] = source.fonts and source.fonts[key] or nil
  end
  return scale
end

local default_style_presets = {
  {
    id = "default",
    label = "Default",
    name = "Default",
    scale = capture_scale_values(config_mod.defaults),
    layout = build_default_layout_preset(),
  },
}

local custom_style_preset = {
  id = "custom",
  label = "Current (custom)",
  name = "Current (custom)",
}

local user_color_items = {
  { key = "background", label = "Background" },
  { key = "uiText", label = "UI text" },
  { key = "uiControlBg", label = "UI controls" },
  { key = "strings", label = "Strings (staff lines)" },
  { key = "barlines", label = "Barlines" },
  { key = "itemBoundary", label = "Item boundaries" },
  { key = "marker", label = "Current bar highlight" },
  { key = "text", label = "Text (frets + labels)" },
  { key = "noteBg", label = "Fret background" },
  { key = "dropped", label = "Dropped notes" },
  { key = "fretboardBg", label = "Fretboard bg" },
  { key = "fretboardStrings", label = "Fretboard strings" },
  { key = "fretboardFrets", label = "Fretboard frets/dots" },
  { key = "fretboardCurrent", label = "Fretboard current note" },
  { key = "fretboardNext", label = "Fretboard next notes" },
}

local user_color_keys = {}
for i, item in ipairs(user_color_items) do
  user_color_keys[i] = item.key
end

local color_picker_labels = nil
local function build_color_picker_labels()
  if color_picker_labels then
    return color_picker_labels
  end
  local labels = {}
  for _, item in ipairs(user_color_items) do
    labels[#labels + 1] = item.label
  end
  color_picker_labels = table.concat(labels, "\0") .. "\0"
  return color_picker_labels
end

local function color_picker_index_for_key(key)
  for i, item in ipairs(user_color_items) do
    if item.key == key then
      return i
    end
  end
  return 1
end

local function read_number_ext(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = tonumber(reaper.GetExtState(section, key))
    if value ~= nil then
      return value
    end
  end
  return fallback
end

local function read_bool_ext(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = reaper.GetExtState(section, key)
    if value == "true" then
      return true
    end
    if value == "false" then
      return false
    end
  end
  return fallback
end

local function read_string_ext(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = reaper.GetExtState(section, key)
    if value ~= "" then
      return value
    end
  end
  return fallback
end

local function read_color_ext(section, key, fallback)
  local r = read_number_ext(section, key .. ".r", nil)
  local g = read_number_ext(section, key .. ".g", nil)
  local b = read_number_ext(section, key .. ".b", nil)
  local a = read_number_ext(section, key .. ".a", nil)
  if r == nil and g == nil and b == nil and a == nil then
    return fallback
  end
  if not fallback then
    fallback = { 0, 0, 0, 1 }
  end
  return {
    r or fallback[1],
    g or fallback[2],
    b or fallback[3],
    a or fallback[4],
  }
end

local function write_value_ext(section, key, value)
  reaper.SetExtState(section, key, tostring(value), true)
end

local function write_color_ext(section, key, color)
  if not color then return end
  write_value_ext(section, key .. ".r", color[1])
  write_value_ext(section, key .. ".g", color[2])
  write_value_ext(section, key .. ".b", color[3])
  write_value_ext(section, key .. ".a", color[4])
end

local function delete_value_ext(section, key)
  if reaper.DeleteExtState then
    reaper.DeleteExtState(section, key, true)
  else
    reaper.SetExtState(section, key, "", true)
  end
end

local function delete_color_ext(section, key)
  delete_value_ext(section, key .. ".r")
  delete_value_ext(section, key .. ".g")
  delete_value_ext(section, key .. ".b")
  delete_value_ext(section, key .. ".a")
end

local function normalize_preset_name(name)
  if not name then return "" end
  return name:match("^%s*(.-)%s*$")
end

local function load_user_tuning_presets(section)
  local presets = {}
  local count = read_number_ext(section, "userPresets.tuning.count", 0)
  for i = 1, count do
    local name = read_string_ext(section, string.format("userPresets.tuning.%d.name", i), "")
    local string_count = read_number_ext(section, string.format("userPresets.tuning.%d.count", i), 0)
    local tuning = {}
    for j = 1, string_count do
      local string_name = read_string_ext(section, string.format("userPresets.tuning.%d.string.%d.name", i, j), "")
      local open = read_number_ext(section, string.format("userPresets.tuning.%d.string.%d.open", i, j), nil)
      if string_name ~= "" and open ~= nil then
        tuning[#tuning + 1] = { name = string_name, open = open }
      end
    end
    if name ~= "" and #tuning > 0 then
      presets[#presets + 1] = { name = name, tuning = tuning }
    end
  end
  return presets
end

local function load_user_color_presets(section)
  local presets = {}
  local count = read_number_ext(section, "userPresets.colors.count", 0)
  for i = 1, count do
    local name = read_string_ext(section, string.format("userPresets.colors.%d.name", i), "")
    if name ~= "" then
      local colors = {}
      for _, key in ipairs(user_color_keys) do
        local color = read_color_ext(section, string.format("userPresets.colors.%d.colors.%s", i, key), nil)
        if color then
          colors[key] = color
        end
      end
      if next(colors) then
        presets[#presets + 1] = { name = name, colors = colors }
      end
    end
  end
  return presets
end

local function load_user_style_presets(section)
  local presets = {}
  local count = read_number_ext(section, "userPresets.style.count", 0)
  for i = 1, count do
    local name = read_string_ext(section, string.format("userPresets.style.%d.name", i), "")
    if name ~= "" then
      local scale = {}
      local has_values = false
      for _, key in ipairs(scale_value_keys) do
        local value = read_number_ext(section, string.format("userPresets.style.%d.%s", i, key), nil)
        if value ~= nil then
          scale[key] = value
          has_values = true
        end
      end
      scale.fonts = {}
      for _, key in ipairs(scale_font_keys) do
        local value = read_number_ext(section, string.format("userPresets.style.%d.fonts.%s", i, key), nil)
        if value ~= nil then
          scale.fonts[key] = value
          has_values = true
        end
      end
      local layout = {}
      local has_layout = false
      for _, key in ipairs(layout_value_keys) do
        local value = read_number_ext(section, string.format("userPresets.style.%d.layout.%s", i, key), nil)
        if value ~= nil then
          layout[key] = value
          has_layout = true
        end
      end
      for _, key in ipairs(layout_string_keys) do
        local value = read_string_ext(section, string.format("userPresets.style.%d.layout.%s", i, key), "")
        if value ~= "" then
          layout[key] = value
          has_layout = true
        end
      end
      local panels = {}
      for _, panel_key in ipairs(layout_panel_keys) do
        local panel_base = string.format("userPresets.style.%d.layout.panels.%s", i, panel_key)
        local open = read_bool_ext(section, panel_base .. ".open", nil)
        local pos_x = read_number_ext(section, panel_base .. ".pos.x", nil)
        local pos_y = read_number_ext(section, panel_base .. ".pos.y", nil)
        local size_w = read_number_ext(section, panel_base .. ".size.w", nil)
        local size_h = read_number_ext(section, panel_base .. ".size.h", nil)
        if open ~= nil or pos_x ~= nil or pos_y ~= nil or size_w ~= nil or size_h ~= nil then
          local panel = {}
          if open ~= nil then
            panel.open = open
          end
          if pos_x ~= nil and pos_y ~= nil then
            panel.pos = { pos_x, pos_y }
          end
          if size_w ~= nil and size_h ~= nil then
            panel.size = { size_w, size_h }
          end
          panels[panel_key] = panel
          has_layout = true
        end
      end
      if next(panels) then
        layout.panels = panels
      end
      if has_values or has_layout then
        local preset = { name = name, scale = scale }
        if has_layout then
          preset.layout = layout
        end
        presets[#presets + 1] = preset
      end
    end
  end
  return presets
end

local function clear_user_tuning_presets(section)
  local count = read_number_ext(section, "userPresets.tuning.count", 0)
  local max_scan = math.max(count, 64)
  for i = 1, max_scan do
    local base = string.format("userPresets.tuning.%d", i)
    local has_entry = reaper.HasExtState(section, base .. ".name") or reaper.HasExtState(section, base .. ".count")
    if not has_entry and i > count then
      break
    end
    local string_count = read_number_ext(section, base .. ".count", 0)
    delete_value_ext(section, base .. ".name")
    delete_value_ext(section, base .. ".count")
    for j = 1, string_count do
      delete_value_ext(section, string.format("%s.string.%d.name", base, j))
      delete_value_ext(section, string.format("%s.string.%d.open", base, j))
    end
  end
  delete_value_ext(section, "userPresets.tuning.count")
end

local function clear_user_color_presets(section)
  local count = read_number_ext(section, "userPresets.colors.count", 0)
  local max_scan = math.max(count, 64)
  for i = 1, max_scan do
    local base = string.format("userPresets.colors.%d", i)
    local has_entry = reaper.HasExtState(section, base .. ".name")
    if not has_entry and i > count then
      break
    end
    delete_value_ext(section, base .. ".name")
    for _, key in ipairs(user_color_keys) do
      delete_color_ext(section, string.format("%s.colors.%s", base, key))
    end
  end
  delete_value_ext(section, "userPresets.colors.count")
end

local function clear_user_style_presets(section)
  local count = read_number_ext(section, "userPresets.style.count", 0)
  local max_scan = math.max(count, 64)
  for i = 1, max_scan do
    local base = string.format("userPresets.style.%d", i)
    local has_entry = reaper.HasExtState(section, base .. ".name")
    if not has_entry and i > count then
      break
    end
    delete_value_ext(section, base .. ".name")
    for _, key in ipairs(scale_value_keys) do
      delete_value_ext(section, string.format("%s.%s", base, key))
    end
    for _, key in ipairs(scale_font_keys) do
      delete_value_ext(section, string.format("%s.fonts.%s", base, key))
    end
    for _, key in ipairs(layout_value_keys) do
      delete_value_ext(section, string.format("%s.layout.%s", base, key))
    end
    for _, key in ipairs(layout_string_keys) do
      delete_value_ext(section, string.format("%s.layout.%s", base, key))
    end
    for _, panel_key in ipairs(layout_panel_keys) do
      local panel_base = string.format("%s.layout.panels.%s", base, panel_key)
      delete_value_ext(section, panel_base .. ".open")
      delete_value_ext(section, panel_base .. ".pos.x")
      delete_value_ext(section, panel_base .. ".pos.y")
      delete_value_ext(section, panel_base .. ".size.w")
      delete_value_ext(section, panel_base .. ".size.h")
    end
  end
  delete_value_ext(section, "userPresets.style.count")
end

local function save_user_tuning_presets(section, presets)
  clear_user_tuning_presets(section)
  write_value_ext(section, "userPresets.tuning.count", #presets)
  for i, preset in ipairs(presets) do
    write_value_ext(section, string.format("userPresets.tuning.%d.name", i), preset.name)
    write_value_ext(section, string.format("userPresets.tuning.%d.count", i), #preset.tuning)
    for j, string_info in ipairs(preset.tuning) do
      write_value_ext(section, string.format("userPresets.tuning.%d.string.%d.name", i, j), string_info.name)
      write_value_ext(section, string.format("userPresets.tuning.%d.string.%d.open", i, j), string_info.open)
    end
  end
end

local function save_user_color_presets(section, presets)
  clear_user_color_presets(section)
  write_value_ext(section, "userPresets.colors.count", #presets)
  for i, preset in ipairs(presets) do
    write_value_ext(section, string.format("userPresets.colors.%d.name", i), preset.name)
    for _, key in ipairs(user_color_keys) do
      local color = preset.colors and preset.colors[key] or nil
      if color then
        write_color_ext(section, string.format("userPresets.colors.%d.colors.%s", i, key), color)
      end
    end
  end
end

local function save_user_style_presets(section, presets)
  clear_user_style_presets(section)
  write_value_ext(section, "userPresets.style.count", #presets)
  for i, preset in ipairs(presets) do
    write_value_ext(section, string.format("userPresets.style.%d.name", i), preset.name)
    local scale = preset.scale or {}
    for _, key in ipairs(scale_value_keys) do
      local value = scale[key]
      if value ~= nil then
        write_value_ext(section, string.format("userPresets.style.%d.%s", i, key), value)
      end
    end
    local fonts = scale.fonts or {}
    for _, key in ipairs(scale_font_keys) do
      local value = fonts[key]
      if value ~= nil then
        write_value_ext(section, string.format("userPresets.style.%d.fonts.%s", i, key), value)
      end
    end
    local layout = preset.layout or {}
    for _, key in ipairs(layout_value_keys) do
      local value = layout[key]
      if value ~= nil then
        write_value_ext(section, string.format("userPresets.style.%d.layout.%s", i, key), value)
      end
    end
    for _, key in ipairs(layout_string_keys) do
      local value = layout[key]
      if value ~= nil then
        write_value_ext(section, string.format("userPresets.style.%d.layout.%s", i, key), value)
      end
    end
    local panels = layout.panels or {}
    for _, panel_key in ipairs(layout_panel_keys) do
      local panel = panels[panel_key]
      if panel then
        local panel_base = string.format("userPresets.style.%d.layout.panels.%s", i, panel_key)
        if panel.open ~= nil then
          write_value_ext(section, panel_base .. ".open", panel.open)
        end
        if panel.pos and panel.pos[1] and panel.pos[2] then
          write_value_ext(section, panel_base .. ".pos.x", panel.pos[1])
          write_value_ext(section, panel_base .. ".pos.y", panel.pos[2])
        end
        if panel.size and panel.size[1] and panel.size[2] then
          write_value_ext(section, panel_base .. ".size.w", panel.size[1])
          write_value_ext(section, panel_base .. ".size.h", panel.size[2])
        end
      end
    end
  end
end

local function build_preset_labels(presets)
  local labels = {}
  for _, preset in ipairs(presets) do
    labels[#labels + 1] = preset.label or preset.name or preset.id
  end
  return table.concat(labels, "\0") .. "\0"
end

local user_tuning_presets = load_user_tuning_presets(SECTION)
local user_color_presets = load_user_color_presets(SECTION)
local user_style_presets = load_user_style_presets(SECTION)
local tuning_presets = {}
local color_presets = {}
local style_presets = {}
local tuning_labels = ""
local color_labels = ""
local style_labels = ""

local function rebuild_preset_lists()
  tuning_presets = {}
  for _, preset in ipairs(default_tuning_presets) do
    tuning_presets[#tuning_presets + 1] = preset
  end
  for _, preset in ipairs(user_tuning_presets) do
    tuning_presets[#tuning_presets + 1] = {
      id = "user:" .. preset.name,
      label = "User: " .. preset.name,
      name = preset.name,
      tuning = util.copy_table(preset.tuning),
    }
  end
  if cfg.tuningPreset == "custom" then
    tuning_presets[#tuning_presets + 1] = custom_tuning_preset
  end
  tuning_labels = build_preset_labels(tuning_presets)

  color_presets = {}
  for _, preset in ipairs(default_color_presets) do
    color_presets[#color_presets + 1] = preset
  end
  for _, preset in ipairs(user_color_presets) do
    color_presets[#color_presets + 1] = {
      id = "user:" .. preset.name,
      label = "User: " .. preset.name,
      name = preset.name,
      colors = util.copy_table(preset.colors),
    }
  end
  color_labels = build_preset_labels(color_presets)

  style_presets = {}
  for _, preset in ipairs(default_style_presets) do
    style_presets[#style_presets + 1] = preset
  end
  for _, preset in ipairs(user_style_presets) do
    style_presets[#style_presets + 1] = {
      id = "user:" .. preset.name,
      label = "User: " .. preset.name,
      name = preset.name,
      scale = util.copy_table(preset.scale),
      layout = preset.layout and util.copy_table(preset.layout) or nil,
    }
  end
  if cfg.stylePreset == "custom" then
    style_presets[#style_presets + 1] = custom_style_preset
  end
  style_labels = build_preset_labels(style_presets)
end

rebuild_preset_lists()

local function find_user_preset_index(presets, name)
  local target = name:lower()
  for i, preset in ipairs(presets) do
    if preset.name and preset.name:lower() == target then
      return i
    end
  end
  return nil
end

local function preset_name_conflict(kind, name)
  local target = name:lower()
  if kind == "tuning" then
    for _, preset in ipairs(default_tuning_presets) do
      if preset.name and preset.name:lower() == target then
        return { type = "default", label = preset.label }
      end
    end
    if custom_tuning_preset.name and custom_tuning_preset.name:lower() == target then
      return { type = "default", label = custom_tuning_preset.label }
    end
    for i, preset in ipairs(user_tuning_presets) do
      if preset.name and preset.name:lower() == target then
        return { type = "user", index = i, label = preset.name }
      end
    end
  elseif kind == "color" then
    for _, preset in ipairs(default_color_presets) do
      if preset.name and preset.name:lower() == target then
        return { type = "default", label = preset.label }
      end
    end
    for i, preset in ipairs(user_color_presets) do
      if preset.name and preset.name:lower() == target then
        return { type = "user", index = i, label = preset.name }
      end
    end
  elseif kind == "style" then
    for _, preset in ipairs(default_style_presets) do
      if preset.name and preset.name:lower() == target then
        return { type = "default", label = preset.label }
      end
    end
    if custom_style_preset.name and custom_style_preset.name:lower() == target then
      return { type = "default", label = custom_style_preset.label }
    end
    for i, preset in ipairs(user_style_presets) do
      if preset.name and preset.name:lower() == target then
        return { type = "user", index = i, label = preset.name }
      end
    end
  end
  return nil
end


local function capture_color_preset(colors)
  local snapshot = {}
  for _, key in ipairs(user_color_keys) do
    if colors and colors[key] then
      snapshot[key] = util.copy_table(colors[key])
    end
  end
  return snapshot
end

local function update_panel_layout(name)
  if not (reaper.ImGui_GetWindowPos and reaper.ImGui_GetWindowSize) then
    return
  end
  local x, y = reaper.ImGui_GetWindowPos(ctx)
  local w, h = reaper.ImGui_GetWindowSize(ctx)
  if not state.panelLayout then
    state.panelLayout = {}
  end
  state.panelLayout[name] = {
    pos = { x, y },
    size = { w, h },
  }
end

local function capture_layout_preset()
  local layout = {
    prevBars = cfg.prevBars,
    nextBars = cfg.nextBars,
    updateMode = cfg.updateMode,
    updateStep = cfg.updateStep,
    antidelayBeats = cfg.antidelayBeats,
    panels = {},
  }
  for _, panel_key in ipairs(layout_panel_keys) do
    local panel = {}
    local open_ref = state.panels[panel_key]
    if open_ref ~= nil then
      panel.open = open_ref.value
    end
    local rect = state.panelLayout and state.panelLayout[panel_key] or nil
    if rect then
      if rect.pos then
        panel.pos = { rect.pos[1], rect.pos[2] }
      end
      if rect.size then
        panel.size = { rect.size[1], rect.size[2] }
      end
    end
    layout.panels[panel_key] = panel
  end
  return layout
end

local sync_fretboard_panel_state

local function apply_layout_preset(layout)
  if not layout then
    return
  end
  for _, key in ipairs(layout_value_keys) do
    local value = layout[key]
    if value ~= nil then
      cfg[key] = value
    end
  end
  for _, key in ipairs(layout_string_keys) do
    local value = layout[key]
    if value ~= nil and value ~= "" then
      cfg[key] = value
    end
  end
  local panels = layout.panels
  if panels then
    for _, panel_key in ipairs(layout_panel_keys) do
      local panel = panels[panel_key]
      if panel and state.panels[panel_key] then
        if panel.open ~= nil then
          state.panels[panel_key].value = panel.open
        end
      end
    end
    if next(panels) then
      state.pendingLayout = util.copy_table(panels)
    end
    if panels.fretboard and panels.fretboard.open ~= nil then
      sync_fretboard_panel_state()
    end
  end
end

local function capture_style_preset(source)
  return {
    scale = capture_scale_values(source),
    layout = capture_layout_preset(),
  }
end

local preset_index_for_id

local apply_settings_change

local function save_current_preset(kind, name)
  if kind == "tuning" then
    local preset = { name = name, tuning = util.copy_table(cfg.tuning) }
    local index = find_user_preset_index(user_tuning_presets, name)
    if index then
      user_tuning_presets[index] = preset
    else
      user_tuning_presets[#user_tuning_presets + 1] = preset
    end
    save_user_tuning_presets(SECTION, user_tuning_presets)
    cfg.tuningPreset = "user:" .. name
  elseif kind == "color" then
    local preset = { name = name, colors = capture_color_preset(cfg.colors) }
    local index = find_user_preset_index(user_color_presets, name)
    if index then
      user_color_presets[index] = preset
    else
      user_color_presets[#user_color_presets + 1] = preset
    end
    save_user_color_presets(SECTION, user_color_presets)
    cfg.colorPreset = "user:" .. name
  elseif kind == "style" then
    local preset = capture_style_preset(cfg)
    preset.name = name
    local index = find_user_preset_index(user_style_presets, name)
    if index then
      user_style_presets[index] = preset
    else
      user_style_presets[#user_style_presets + 1] = preset
    end
    save_user_style_presets(SECTION, user_style_presets)
    cfg.stylePreset = "user:" .. name
  end
  rebuild_preset_lists()
  apply_settings_change()
end

local function open_preset_save(kind)
  state.presetSave.kind = kind
  state.presetSave.name = ""
  state.presetSave.confirmOverwrite = false
  state.presetSave.confirmName = nil
  state.presetSave.confirmType = nil
  state.presetSave.error = nil
  state.presetSave.focusName = true
  state.presetSave.open = true
end


local function draw_preset_save_modal(ctx)
  if state.presetSave.open then
    if reaper.ImGui_SetNextWindowSize and reaper.ImGui_Cond_Appearing then
      reaper.ImGui_SetNextWindowSize(ctx, 720, 360, reaper.ImGui_Cond_Appearing())
    end
    reaper.ImGui_OpenPopup(ctx, "Save preset")
    state.presetSave.open = false
  end

  if not reaper.ImGui_BeginPopupModal(ctx, "Save preset", true, 0) then
    return
  end

  local kind_label = "color"
  if state.presetSave.kind == "tuning" then
    kind_label = "tuning"
  elseif state.presetSave.kind == "style" then
    kind_label = "style"
  end
  reaper.ImGui_Text(ctx, string.format("Save current %s as a preset.", kind_label))

  local rv
  if state.presetSave.focusName and reaper.ImGui_SetKeyboardFocusHere then
    reaper.ImGui_SetKeyboardFocusHere(ctx)
    state.presetSave.focusName = false
  end
  rv, state.presetSave.name = reaper.ImGui_InputText(ctx, "Name", state.presetSave.name or "")
  if rv then
    state.presetSave.confirmOverwrite = false
    state.presetSave.confirmName = nil
    state.presetSave.confirmType = nil
    state.presetSave.error = nil
  end

  local trimmed = normalize_preset_name(state.presetSave.name)
  local conflict = trimmed ~= "" and preset_name_conflict(state.presetSave.kind, trimmed) or nil
  if conflict then
    if conflict.type == "user" then
      reaper.ImGui_Text(ctx, "A user preset with this name already exists.")
    else
      reaper.ImGui_Text(ctx, "A default preset uses this name.")
    end
  end

  if state.presetSave.confirmOverwrite and state.presetSave.confirmName then
    if state.presetSave.confirmType == "user" then
      reaper.ImGui_Text(ctx, "Click Save again to overwrite it.")
    else
      reaper.ImGui_Text(ctx, "Click Save again to store a user preset with this name.")
    end
  end

  if state.presetSave.error then
    reaper.ImGui_Text(ctx, state.presetSave.error)
  end

  local save_requested = false
  if reaper.ImGui_Button(ctx, "Save") then
    save_requested = true
  end
  if reaper.ImGui_IsKeyPressed and reaper.ImGui_Key_Enter then
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter(), false) then
      save_requested = true
    end
  end
  if reaper.ImGui_IsKeyPressed and reaper.ImGui_Key_KeypadEnter then
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_KeypadEnter(), false) then
      save_requested = true
    end
  end

  if save_requested then
    if trimmed == "" then
      state.presetSave.error = "Enter a preset name."
    else
      if conflict and (not state.presetSave.confirmOverwrite or state.presetSave.confirmName ~= trimmed) then
        state.presetSave.confirmOverwrite = true
        state.presetSave.confirmName = trimmed
        state.presetSave.confirmType = conflict.type
      else
        save_current_preset(state.presetSave.kind, trimmed)
        state.presetSave.confirmOverwrite = false
        state.presetSave.confirmName = nil
        state.presetSave.confirmType = nil
        state.presetSave.error = nil
        reaper.ImGui_CloseCurrentPopup(ctx)
      end
    end
  end
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "Cancel") then
    reaper.ImGui_CloseCurrentPopup(ctx)
  end

  reaper.ImGui_EndPopup(ctx)
end

preset_index_for_id = function(presets, preset_id, fallback_id)
  for i, preset in ipairs(presets) do
    if preset.id == preset_id then
      return i
    end
  end
  if fallback_id then
    for i, preset in ipairs(presets) do
      if preset.id == fallback_id then
        return i
      end
    end
  end
  return 1
end

local function apply_tuning_preset(cfg, preset)
  if not preset or not preset.tuning then
    return false
  end
  cfg.tuning = util.copy_table(preset.tuning)
  cfg.maxSimul = #cfg.tuning
  cfg.tuningPreset = preset.id
  return true
end

local function color_preset_index(preset_id)
  return preset_index_for_id(color_presets, preset_id, "dark")
end

local function apply_color_preset(cfg, preset)
  if not preset or not preset.colors then
    return false
  end
  for key, value in pairs(preset.colors) do
    cfg.colors[key] = util.copy_table(value)
  end
  cfg.colorPreset = preset.id
  state.colorHex = {}
  return true
end

local function style_preset_index(preset_id)
  return preset_index_for_id(style_presets, preset_id, "default")
end

local function apply_style_preset(cfg, preset)
  if not preset or (not preset.scale and not preset.layout) then
    return false
  end
  if preset.scale then
    for _, key in ipairs(scale_value_keys) do
      local value = preset.scale[key]
      if value ~= nil then
        cfg[key] = value
      end
    end
    if not cfg.fonts then
      cfg.fonts = {}
    end
    local fonts = preset.scale.fonts or {}
    for _, key in ipairs(scale_font_keys) do
      local value = fonts[key]
      if value ~= nil then
        cfg.fonts[key] = value
      end
    end
  end
  if preset.layout then
    apply_layout_preset(preset.layout)
  end
  cfg.stylePreset = preset.id
  return true
end

local function cond_always()
  if reaper.ImGui_Cond_Always then
    return reaper.ImGui_Cond_Always()
  end
  return 0
end

local function normalize_pending_layout(name, pending)
  if name ~= "main" then
    return pending
  end
  if not (pending and (pending.size or pending.pos)) then
    return pending
  end
  if not (reaper.ImGui_GetMainViewport and reaper.ImGui_Viewport_GetWorkPos and reaper.ImGui_Viewport_GetWorkSize) then
    return pending
  end
  local viewport = reaper.ImGui_GetMainViewport(ctx)
  if not viewport then
    return pending
  end
  local work_x, work_y = reaper.ImGui_Viewport_GetWorkPos(viewport)
  local work_w, work_h = reaper.ImGui_Viewport_GetWorkSize(viewport)
  local size_w = pending.size and pending.size[1] or 900
  local size_h = pending.size and pending.size[2] or 360
  if pending.size then
    local min_w = 320
    local min_h = 200
    pending.size[1] = util.clamp(pending.size[1], min_w, work_w)
    pending.size[2] = util.clamp(pending.size[2], min_h, work_h)
    size_w = pending.size[1]
    size_h = pending.size[2]
  end
  pending.pos = {
    work_x + (work_w - size_w) * 0.5,
    work_y + (work_h - size_h) * 0.5,
  }
  return pending
end

local function apply_pending_layout(name, init_flag)
  if not state.pendingLayout then
    return false
  end
  local pending = state.pendingLayout[name]
  if not pending then
    return false
  end
  pending = normalize_pending_layout(name, pending)
  local cond = cond_always()
  local applied = false
  if pending.size and reaper.ImGui_SetNextWindowSize then
    reaper.ImGui_SetNextWindowSize(ctx, pending.size[1], pending.size[2], cond)
    applied = true
  end
  if pending.pos and reaper.ImGui_SetNextWindowPos then
    reaper.ImGui_SetNextWindowPos(ctx, pending.pos[1], pending.pos[2], cond)
    applied = true
  end
  state.pendingLayout[name] = nil
  if applied and init_flag then
    state[init_flag] = true
  end
  return applied
end

local function clamp_config(cfg)
  cfg.prevBars = util.clamp(cfg.prevBars, 0, 64)
  cfg.nextBars = util.clamp(cfg.nextBars, 0, 64)
  cfg.updateStep = util.clamp(cfg.updateStep, 1, 64)
  cfg.antidelayBeats = util.clamp(cfg.antidelayBeats, 0, 64)
  cfg.maxFret = util.clamp(cfg.maxFret, 1, 48)
  cfg.maxFrettedSpan = util.clamp(cfg.maxFrettedSpan, 0, 24)
  cfg.maxSimul = util.clamp(cfg.maxSimul, 1, #cfg.tuning)
  cfg.groupEpsilonMs = util.clamp(cfg.groupEpsilonMs, 0, 100)
  cfg.systemGutterPx = util.clamp(cfg.systemGutterPx, 0, 300)
  cfg.barPrefixPx = util.clamp(cfg.barPrefixPx, 0, 300)
  cfg.barContentPx = util.clamp(cfg.barContentPx, 10, 600)
  cfg.barGutterPx = util.clamp(cfg.barGutterPx, 0, 120)
  cfg.systemRowGapPx = util.clamp(cfg.systemRowGapPx, 0, 120)
  cfg.staffPaddingTopPx = util.clamp(cfg.staffPaddingTopPx, 0, 80)
  cfg.staffPaddingBottomPx = util.clamp(cfg.staffPaddingBottomPx, 0, 80)
  cfg.stringSpacingPx = util.clamp(cfg.stringSpacingPx, 6, 40)
  cfg.barLineThickness = util.clamp(cfg.barLineThickness, 0.5, 6)
  cfg.itemBoundaryThickness = util.clamp(cfg.itemBoundaryThickness, 0.5, 6)
  cfg.fretboardNextCount = util.clamp(cfg.fretboardNextCount, 0, 128)
  cfg.fretboardNextBars = util.clamp(cfg.fretboardNextBars, 0, 32)
  cfg.fretboardFrets = util.clamp(cfg.fretboardFrets, 1, 36)
  cfg.fretboardNoteRoundness = util.clamp(cfg.fretboardNoteRoundness, 0, 1)
  cfg.fretboardNoteSize = util.clamp(cfg.fretboardNoteSize, 0.3, 2.5)
  cfg.fretboardDotSize = util.clamp(cfg.fretboardDotSize, 0.2, 3.0)
  cfg.fretboardFretThickness = util.clamp(cfg.fretboardFretThickness, 0.5, 6.0)
  cfg.fretboardStringThickness = util.clamp(cfg.fretboardStringThickness, 0.5, 6.0)
  local fb_modes = { hidden = true, current = true, next_notes = true, next_bars = true }
  if not fb_modes[cfg.fretboardMode] then
    cfg.fretboardMode = "hidden"
  end
  local fb_styles = { outline = true, outline_shade = true, outline_ramp = true }
  if not fb_styles[cfg.fretboardNextStyle] then
    cfg.fretboardNextStyle = "outline"
  end
  if cfg.fonts then
    cfg.fonts.fretScale = util.clamp(cfg.fonts.fretScale or 1.0, 0.6, 2.5)
    cfg.fonts.timeSigScale = util.clamp(cfg.fonts.timeSigScale or 1.4, 0.6, 3.0)
    cfg.fonts.droppedScale = util.clamp(cfg.fonts.droppedScale or 0.8, 0.5, 2.0)
  end
end

local function get_cursor_time()
  local play_state = reaper.GetPlayState()
  local is_playing = (play_state & 1) == 1
  if is_playing and cfg.followPlay then
    return reaper.GetPlayPosition()
  end
  if cfg.followEditWhenStopped then
    return reaper.GetCursorPosition()
  end
  return reaper.GetCursorPosition()
end

local function rebuild_data(t)
  util.log_throttle("rebuild", 1.0, string.format("rebuild_data t=%.3f", t), "debug")
  local bars, current = timeline.build_bars(t, cfg.prevBars, cfg.nextBars, cfg.showFirstTimeSigInSystemGutter)

  if #bars == 0 then
    state.eventsByBar = {}
    state.hasMidiTake = false
    state.statusMessage = "No bars in window"
    util.log_throttle("no_bars", 1.0, "no bars in window", "debug")
    state.bars = bars
    state.lastBarIdx = current
    return
  end

  local take, take_source, current_item, next_item, track = source.get_take(t)
  local take_id = take and tostring(take) or nil
  if take_id ~= state.takeId then
    state.takeId = take_id
    state.takeSource = take_source
    util.log(string.format("active take id=%s source=%s", tostring(take_id), tostring(take_source)), "info")
  end

  state.itemBounds = {
    current = current_item,
    next = next_item,
  }

  if next_item and next_item.t0 then
    local last_bar = bars[#bars]
    if last_bar and next_item.t0 > last_bar.t1 then
      local next_bar_idx = timeline.get_measure_index(next_item.t0)
      if next_bar_idx and next_bar_idx > current then
        local needed_next = math.max(cfg.nextBars, next_bar_idx - current)
        if needed_next ~= cfg.nextBars then
          bars, current = timeline.build_bars(t, cfg.prevBars, needed_next, cfg.showFirstTimeSigInSystemGutter)
        end
      end
    end
  end

  state.bars = bars
  state.lastBarIdx = current

  if not take then
      state.eventsByBar = {}
      state.hasMidiTake = false
      state.statusMessage = "No MIDI detected. Select a track with a MIDI item under the cursor."
      state.itemBounds = nil
    util.log_throttle("no_take", 1.5, "no active MIDI take", "info")
    return
  end

  state.hasMidiTake = true
  state.statusMessage = nil

  local window_t0 = bars[1].t0
  local window_t1 = bars[#bars].t1
  local items_in_window = {}
  if track and window_t0 and window_t1 then
    items_in_window = source.get_items_in_window(track, window_t0, window_t1)
  end
  if #items_in_window == 0 and take and state.itemBounds and state.itemBounds.current then
    items_in_window = {
      {
        item = state.itemBounds.current.item,
        take = take,
        t0 = state.itemBounds.current.t0,
        t1 = state.itemBounds.current.t1,
      },
    }
  end

  local notes = {}
  for _, item_info in ipairs(items_in_window) do
    local item_notes = midi.extract_notes(item_info.take, window_t0, window_t1, item_info.t0, item_info.t1)
    for _, note in ipairs(item_notes) do
      notes[#notes + 1] = note
    end
  end
  table.sort(notes, function(a, b)
    if a.tStart == b.tStart then
      return a.pitch > b.pitch
    end
    return a.tStart < b.tStart
  end)
  local events = midi.group_events(notes, cfg.groupEpsilonMs / 1000)

  local events_by_bar = {}
  local assignment_state = frets.new_state(#cfg.tuning)
  local bar_idx = 1

  for _, event in ipairs(events) do
    while bar_idx <= #bars and event.t >= bars[bar_idx].t1 do
      bar_idx = bar_idx + 1
    end
    local bar = bars[bar_idx]
    if bar and event.t >= bar.t0 and event.t < bar.t1 then
      local result = frets.assign_event(event, cfg, assignment_state)
      event.assignments = result.assignments
      event.dropped = result.dropped
      events_by_bar[bar.idx] = events_by_bar[bar.idx] or {}
      events_by_bar[bar.idx][#events_by_bar[bar.idx] + 1] = event
      frets.advance_state(result.assignments, assignment_state)
    end
  end

  state.eventsByBar = events_by_bar
  util.log_throttle("assigned", 1.0, string.format("assigned events=%d bars=%d", #events, #bars), "debug")
end

local function compute_update_key(mode, current_bar, bars_per_system, step)
  local step_val = math.max(1, step or 1)
  if mode == "continuous" then
    return current_bar
  end
  if mode == "screen" then
    local denom = math.max(1, bars_per_system or 1)
    return math.floor(current_bar / denom)
  end
  if mode == "step" then
    return math.floor(current_bar / step_val)
  end
  return current_bar
end

local function compute_virtual_bar(t, current_bar, antidelay_beats)
  local beats_since_meas, _, cml = reaper.TimeMap2_timeToBeats(0, t)
  if beats_since_meas and cml and antidelay_beats and antidelay_beats > 0 then
    if beats_since_meas >= (cml - antidelay_beats) then
      return current_bar + 1
    end
  end
  return current_bar
end

local function compute_sweep_offset_px(t, config)
  local beats_since_meas, _, cml = reaper.TimeMap2_timeToBeats(0, t)
  if not beats_since_meas or not cml or cml == 0 then
    return 0
  end
  local frac = util.clamp(beats_since_meas / cml, 0, 1)
  local bar_total = config.barPrefixPx + config.barContentPx + config.barGutterPx
  return frac * bar_total
end

local function handle_bar_click(ctx, systems, config)
  if not (reaper.ImGui_IsMouseClicked and reaper.ImGui_GetMousePos and reaper.ImGui_IsWindowHovered) then
    return
  end
  local hovered = reaper.ImGui_IsWindowHovered(ctx, reaper.ImGui_HoveredFlags_RootAndChildWindows and reaper.ImGui_HoveredFlags_RootAndChildWindows() or 0)
  if not hovered or not reaper.ImGui_IsMouseClicked(ctx, 0) then
    return
  end
  if reaper.ImGui_IsAnyItemActive and reaper.ImGui_IsAnyItemActive(ctx) then
    return
  end
  if reaper.ImGui_IsAnyItemFocused and reaper.ImGui_IsAnyItemFocused(ctx) then
    return
  end

  local mx, my = reaper.ImGui_GetMousePos(ctx)
  local bar_w = config.barPrefixPx + config.barContentPx
  for _, system in ipairs(systems) do
    local y0 = system.y
    local y1 = system.staffRect.bottom + config.staffPaddingBottomPx
    if my >= y0 and my <= y1 then
      for k, bar_layout in ipairs(system.barLayouts) do
        local bar = system.bars[k]
        if bar then
          local x0 = bar_layout.barLeft
          local x1 = x0 + bar_w
          if mx >= x0 and mx <= x1 then
            reaper.SetEditCurPos(bar.t0, true, true)
            return
          end
        end
      end
    end
  end
end

local function color_to_hex(color, include_alpha)
  local function to_byte(value)
    return util.clamp(math.floor((value or 0) * 255 + 0.5), 0, 255)
  end
  local r = to_byte(color[1])
  local g = to_byte(color[2])
  local b = to_byte(color[3])
  local a = to_byte(color[4])
  if include_alpha then
    return string.format("%02X%02X%02X%02X", r, g, b, a)
  end
  return string.format("%02X%02X%02X", r, g, b)
end

local function parse_hex_color(text)
  if not text then return nil end
  local hex = text:gsub("%s", "")
  if hex:sub(1, 1) == "#" then
    hex = hex:sub(2)
  end
  if #hex ~= 6 and #hex ~= 8 then
    return nil
  end
  local function byte_at(offset)
    return tonumber(hex:sub(offset, offset + 1), 16)
  end
  local r = byte_at(1)
  local g = byte_at(3)
  local b = byte_at(5)
  local a = (#hex == 8) and byte_at(7) or 255
  if not (r and g and b and a) then
    return nil
  end
  return { r / 255, g / 255, b / 255, a / 255 }
end

local function edit_color_hex(ctx, label, key, color, include_alpha)
  if not color or not reaper.ImGui_InputText then
    return false
  end
  if not state.colorHex[key] then
    state.colorHex[key] = color_to_hex(color, include_alpha)
  end
  local rv
  reaper.ImGui_PushID(ctx, key)
  rv, state.colorHex[key] = reaper.ImGui_InputText(ctx, label, state.colorHex[key])
  reaper.ImGui_PopID(ctx)
  if rv then
    local parsed = parse_hex_color(state.colorHex[key])
    if parsed then
      color[1], color[2], color[3], color[4] = parsed[1], parsed[2], parsed[3], parsed[4]
      state.colorHex[key] = color_to_hex(color, include_alpha)
      return true
    end
  end
  return false
end

local function draw_color_swatch(ctx, color, size, id)
  if not color or not reaper.ImGui_GetCursorScreenPos or not reaper.ImGui_GetWindowDrawList then
    return false
  end
  local x, y = reaper.ImGui_GetCursorScreenPos(ctx)
  local clicked = false
  if reaper.ImGui_InvisibleButton then
    local label = "##ColorSwatch"
    if id then
      label = label .. tostring(id)
    end
    clicked = reaper.ImGui_InvisibleButton(ctx, label, size, size)
  else
    reaper.ImGui_Dummy(ctx, size, size)
  end
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local col = util.color_u32(color[1], color[2], color[3], color[4])
  local border = util.color_u32(0, 0, 0, 0.6)
  reaper.ImGui_DrawList_AddRectFilled(draw_list, x, y, x + size, y + size, col)
  reaper.ImGui_DrawList_AddRect(draw_list, x, y, x + size, y + size, border)
  if not reaper.ImGui_InvisibleButton then
    reaper.ImGui_Dummy(ctx, size, size)
  end
  return clicked
end

local function open_color_picker(key)
  if key then
    state.colorPickerKey = key
  end
  state.panels.colorPicker.value = true
end

local function edit_int(ctx, label, value, min_value, max_value)
  local rv
  if reaper.ImGui_SliderInt then
    rv, value = reaper.ImGui_SliderInt(ctx, label, value, min_value, max_value)
  else
    rv, value = reaper.ImGui_InputInt(ctx, label, value)
  end
  if rv and min_value and max_value then
    value = util.clamp(value, min_value, max_value)
  end
  return rv, value
end

local function edit_float(ctx, label, value, min_value, max_value)
  local rv
  if reaper.ImGui_SliderDouble then
    rv, value = reaper.ImGui_SliderDouble(ctx, label, value, min_value, max_value)
  elseif reaper.ImGui_InputDouble then
    rv, value = reaper.ImGui_InputDouble(ctx, label, value)
  else
    rv, value = reaper.ImGui_InputInt(ctx, label, math.floor(value + 0.5))
  end
  if rv and min_value and max_value then
    value = util.clamp(value, min_value, max_value)
  end
  return rv, value
end

local function collect_fretboard_current_notes(t)
  local current_notes = {}
  local current_map = {}
  if not state.bars or #state.bars == 0 then
    return current_notes, current_map
  end

  for _, bar in ipairs(state.bars) do
    local events = state.eventsByBar[bar.idx] or {}
    for _, event in ipairs(events) do
      local assign_by_pitch = {}
      for _, assign in ipairs(event.assignments or {}) do
        assign_by_pitch[assign.pitch] = assign
      end
      for _, note in ipairs(event.notes or {}) do
        if note.tStart <= t and t < note.tEnd then
          local assign = assign_by_pitch[note.pitch]
          if assign then
            local key = tostring(assign.string) .. ":" .. tostring(assign.fret)
            if not current_map[key] then
              current_map[key] = true
              current_notes[#current_notes + 1] = {
                string = assign.string,
                fret = assign.fret,
                pitch = assign.pitch,
              }
            end
          end
        end
      end
    end
  end

  return current_notes, current_map
end

local function collect_fretboard_next_notes(t, current_bar, current_map)
  local next_notes = {}
  if cfg.fretboardMode == "next_notes" then
    local remaining = cfg.fretboardNextCount or 0
    if remaining <= 0 then
      return next_notes
    end
    for _, bar in ipairs(state.bars) do
      local events = state.eventsByBar[bar.idx] or {}
      for _, event in ipairs(events) do
        if event.t > t then
          for _, assign in ipairs(event.assignments or {}) do
            local key = tostring(assign.string) .. ":" .. tostring(assign.fret)
            if not current_map[key] then
              next_notes[#next_notes + 1] = {
                string = assign.string,
                fret = assign.fret,
                pitch = assign.pitch,
              }
              remaining = remaining - 1
              if remaining <= 0 then
                return next_notes
              end
            end
          end
        end
      end
    end
  elseif cfg.fretboardMode == "next_bars" then
    local last_bar = current_bar + (cfg.fretboardNextBars or 0)
    for _, bar in ipairs(state.bars) do
      if bar.idx == current_bar or (bar.idx > current_bar and bar.idx <= last_bar) then
        local events = state.eventsByBar[bar.idx] or {}
        for _, event in ipairs(events) do
          if bar.idx > current_bar or event.t >= t then
            for _, assign in ipairs(event.assignments or {}) do
              local key = tostring(assign.string) .. ":" .. tostring(assign.fret)
              if not current_map[key] then
                next_notes[#next_notes + 1] = {
                  string = assign.string,
                  fret = assign.fret,
                  pitch = assign.pitch,
                }
              end
            end
          end
        end
      end
    end
  end

  return next_notes
end

sync_fretboard_panel_state = function()
  local open = state.panels.fretboard.value
  if open ~= state.fretboardPanelOpen then
    state.fretboardPanelOpen = open
    if open then
      cfg.fretboardMode = state.fretboardLastMode or "current"
    else
      state.fretboardLastMode = cfg.fretboardMode
      cfg.fretboardMode = "hidden"
    end
    return true
  end
  return false
end

local function draw_fretboard_panel(t, current_bar)
  state.fretboardFocused = false

  if state.panels.fretboard.value then
    apply_pending_layout("fretboard", "fretboardWindowInitialized")
    if not state.fretboardWindowInitialized then
      reaper.ImGui_SetNextWindowSize(ctx, 520, 220, reaper.ImGui_Cond_FirstUseEver())
      if reaper.ImGui_SetNextWindowDockID and reaper.ImGui_Cond_FirstUseEver then
        reaper.ImGui_SetNextWindowDockID(ctx, 0, reaper.ImGui_Cond_FirstUseEver())
      end
      if reaper.ImGui_SetNextWindowPos and reaper.ImGui_Cond_FirstUseEver then
        reaper.ImGui_SetNextWindowPos(ctx, 140, 180, reaper.ImGui_Cond_FirstUseEver())
      end
      state.fretboardWindowInitialized = true
    end
  end

  local flags = reaper.ImGui_WindowFlags_NoCollapse and reaper.ImGui_WindowFlags_NoCollapse() or 0
  Panels.window(ctx, state.panels.fretboard, "Fretboard", flags, function(ctx)
    update_panel_layout("fretboard")
    if reaper.ImGui_IsWindowFocused and reaper.ImGui_FocusedFlags_RootAndChildWindows then
      state.fretboardFocused = reaper.ImGui_IsWindowFocused(ctx, reaper.ImGui_FocusedFlags_RootAndChildWindows())
    end

    local header_changed = false
    local mode_labels = "Only current note\0Current note + next N notes\0Current note + current bar + next N bars\0"
    local mode_values = { "current", "next_notes", "next_bars" }
    local mode_index = 0
    for i, mode in ipairs(mode_values) do
      if mode == cfg.fretboardMode then
        mode_index = i - 1
        break
      end
    end
    local rv
    reaper.ImGui_Text(ctx, "Mode")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 240)
    rv, mode_index = reaper.ImGui_Combo(ctx, "##FretboardMode", mode_index, mode_labels)
    if rv then
      cfg.fretboardMode = mode_values[mode_index + 1] or "current"
      state.fretboardLastMode = cfg.fretboardMode
      header_changed = true
    end

    if cfg.fretboardMode == "next_notes" then
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_Text(ctx, "Display next notes")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.fretboardNextCount = edit_int(ctx, "##FretboardNextNotes", cfg.fretboardNextCount, 0, 128)
      header_changed = header_changed or rv
    elseif cfg.fretboardMode == "next_bars" then
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_Text(ctx, "Display next bars")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.fretboardNextBars = edit_int(ctx, "##FretboardNextBars", cfg.fretboardNextBars, 0, 32)
      header_changed = header_changed or rv
    end

    if cfg.fretboardMode == "next_notes" or cfg.fretboardMode == "next_bars" then
      local style_labels = "Outline only\0Outline + shade\0Outline + ramp\0"
      local style_values = { "outline", "outline_shade", "outline_ramp" }
      local style_index = 0
      for i, style in ipairs(style_values) do
        if style == cfg.fretboardNextStyle then
          style_index = i - 1
          break
        end
      end
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_Text(ctx, "Next notes style")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 200)
      rv, style_index = reaper.ImGui_Combo(ctx, "##FretboardNextStyle", style_index, style_labels)
      if rv then
        cfg.fretboardNextStyle = style_values[style_index + 1] or "outline"
        header_changed = true
      end
    end

    if header_changed then
      apply_settings_change()
    end

    reaper.ImGui_Separator(ctx)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local x, y = reaper.ImGui_GetCursorScreenPos(ctx)
    local w, h = reaper.ImGui_GetContentRegionAvail(ctx)
    if w > 10 and h > 10 then
      local current_notes, current_map = collect_fretboard_current_notes(t)
      local next_notes = collect_fretboard_next_notes(t, current_bar, current_map)
      render.draw_fretboard(draw_list, ctx, { x = x, y = y, w = w, h = h }, cfg, current_notes, next_notes, cfg.fretboardNextStyle)
      reaper.ImGui_Dummy(ctx, w, h)
    end
  end)

  return sync_fretboard_panel_state()
end

local function draw_color_picker_panel()
  if state.panels.colorPicker.value then
    apply_pending_layout("colorPicker", "colorPickerWindowInitialized")
    if not state.colorPickerWindowInitialized then
      reaper.ImGui_SetNextWindowSize(ctx, 520, 420, reaper.ImGui_Cond_FirstUseEver())
      if reaper.ImGui_SetNextWindowDockID and reaper.ImGui_Cond_FirstUseEver then
        reaper.ImGui_SetNextWindowDockID(ctx, 0, reaper.ImGui_Cond_FirstUseEver())
      end
      if reaper.ImGui_SetNextWindowPos and reaper.ImGui_Cond_FirstUseEver then
        reaper.ImGui_SetNextWindowPos(ctx, 160, 200, reaper.ImGui_Cond_FirstUseEver())
      end
      state.colorPickerWindowInitialized = true
    end
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, 360, 360, 1000, 1000)
  end

  Panels.window(ctx, state.panels.colorPicker, "Color Picker", 0, function(ctx)
    update_panel_layout("colorPicker")
    local settings_changed = false
    local rv
    local key = state.colorPickerKey or "background"
    local picker_labels = build_color_picker_labels()
    local index = color_picker_index_for_key(key) - 1

    reaper.ImGui_Text(ctx, "Target")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 240)
    rv, index = reaper.ImGui_Combo(ctx, "##ColorPickerTarget", index, picker_labels)
    if rv then
      local item = user_color_items[index + 1]
      if item then
        state.colorPickerKey = item.key
        key = item.key
      end
    end

    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Save colors as preset") then
      open_preset_save("color")
    end

    local color = cfg.colors and key and cfg.colors[key]
    if color then
      reaper.ImGui_Separator(ctx)
      local col_u32 = util.color_u32(color[1], color[2], color[3], color[4])
      local flags = 0
      if reaper.ImGui_ColorEditFlags_AlphaBar then
        flags = flags + reaper.ImGui_ColorEditFlags_AlphaBar()
      end
      local changed, new_u32 = reaper.ImGui_ColorPicker4(ctx, "##ColorPicker", col_u32, flags)
      if changed then
        local r, g, b, a = reaper.ImGui_ColorConvertU32ToDouble4(new_u32)
        color[1], color[2], color[3], color[4] = r, g, b, a
        state.colorHex[key] = color_to_hex(color, true)
        settings_changed = true
      end
    else
      reaper.ImGui_Text(ctx, "No color selected.")
    end

    if settings_changed then
      apply_settings_change()
    end
  end)
end

local function format_settings_export(cfg)
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

  local lines = {}
  lines[#lines + 1] = "luaTab_settings = {"
  lines[#lines + 1] = string.format("  followPlay = %s,", fmt(cfg.followPlay))
  lines[#lines + 1] = string.format("  followEditWhenStopped = %s,", fmt(cfg.followEditWhenStopped))
  lines[#lines + 1] = string.format("  prevBars = %s,", fmt(cfg.prevBars))
  lines[#lines + 1] = string.format("  nextBars = %s,", fmt(cfg.nextBars))
  lines[#lines + 1] = string.format("  systemGutterPx = %s,", fmt(cfg.systemGutterPx))
  lines[#lines + 1] = string.format("  barPrefixPx = %s,", fmt(cfg.barPrefixPx))
  lines[#lines + 1] = string.format("  barContentPx = %s,", fmt(cfg.barContentPx))
  lines[#lines + 1] = string.format("  barGutterPx = %s,", fmt(cfg.barGutterPx))
  lines[#lines + 1] = string.format("  systemRowGapPx = %s,", fmt(cfg.systemRowGapPx))
  lines[#lines + 1] = string.format("  staffPaddingTopPx = %s,", fmt(cfg.staffPaddingTopPx))
  lines[#lines + 1] = string.format("  staffPaddingBottomPx = %s,", fmt(cfg.staffPaddingBottomPx))
  lines[#lines + 1] = string.format("  stringSpacingPx = %s,", fmt(cfg.stringSpacingPx))
  lines[#lines + 1] = string.format("  barLineThickness = %s,", fmt(cfg.barLineThickness))
  lines[#lines + 1] = string.format("  itemBoundaryThickness = %s,", fmt(cfg.itemBoundaryThickness))
  lines[#lines + 1] = "  colors = {"
  for _, key in ipairs(user_color_keys) do
    local color = cfg.colors and cfg.colors[key]
    if color then
      lines[#lines + 1] = string.format(
        "    %s = { %.4f, %.4f, %.4f, %.4f },",
        key,
        color[1] or 0,
        color[2] or 0,
        color[3] or 0,
        color[4] or 1
      )
    end
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = string.format("  colorPreset = %s,", fmt(cfg.colorPreset))
  lines[#lines + 1] = string.format("  stylePreset = %s,", fmt(cfg.stylePreset))
  lines[#lines + 1] = "  tuning = {"
  for _, string_info in ipairs(cfg.tuning or {}) do
    lines[#lines + 1] = string.format("    { name = %q, open = %d },", string_info.name, string_info.open)
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = string.format("  tuningPreset = %s,", fmt(cfg.tuningPreset))
  lines[#lines + 1] = string.format("  maxFret = %s,", fmt(cfg.maxFret))
  lines[#lines + 1] = string.format("  maxFrettedSpan = %s,", fmt(cfg.maxFrettedSpan))
  lines[#lines + 1] = string.format("  maxSimul = %s,", fmt(cfg.maxSimul))
  lines[#lines + 1] = "  weights = {"
  lines[#lines + 1] = string.format("    lowFret = %s,", fmt(cfg.weights.lowFret))
  lines[#lines + 1] = string.format("    stayOnString = %s,", fmt(cfg.weights.stayOnString))
  lines[#lines + 1] = string.format("    stringJump = %s,", fmt(cfg.weights.stringJump))
  lines[#lines + 1] = string.format("    fretJump = %s,", fmt(cfg.weights.fretJump))
  lines[#lines + 1] = string.format("    highFret = %s,", fmt(cfg.weights.highFret))
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = string.format("  reducePreferHighest = %s,", fmt(cfg.reducePreferHighest))
  lines[#lines + 1] = string.format("  showFirstTimeSigInSystemGutter = %s,", fmt(cfg.showFirstTimeSigInSystemGutter))
  lines[#lines + 1] = string.format("  preloadSeconds = %s,", fmt(cfg.preloadSeconds))
  lines[#lines + 1] = string.format("  groupEpsilonMs = %s,", fmt(cfg.groupEpsilonMs))
  lines[#lines + 1] = string.format("  logEnabled = %s,", fmt(cfg.logEnabled))
  lines[#lines + 1] = string.format("  logVerbose = %s,", fmt(cfg.logVerbose))
  lines[#lines + 1] = string.format("  logPath = %s,", fmt(cfg.logPath or ""))
  lines[#lines + 1] = "  fonts = {"
  lines[#lines + 1] = string.format("    fretScale = %s,", fmt(cfg.fonts.fretScale))
  lines[#lines + 1] = string.format("    timeSigScale = %s,", fmt(cfg.fonts.timeSigScale))
  lines[#lines + 1] = string.format("    droppedScale = %s,", fmt(cfg.fonts.droppedScale))
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = string.format("  updateMode = %s,", fmt(cfg.updateMode))
  lines[#lines + 1] = string.format("  updateStep = %s,", fmt(cfg.updateStep))
  lines[#lines + 1] = string.format("  antidelayBeats = %s,", fmt(cfg.antidelayBeats))
  lines[#lines + 1] = string.format("  fretboardMode = %s,", fmt(cfg.fretboardMode))
  lines[#lines + 1] = string.format("  fretboardNextCount = %s,", fmt(cfg.fretboardNextCount))
  lines[#lines + 1] = string.format("  fretboardNextBars = %s,", fmt(cfg.fretboardNextBars))
  lines[#lines + 1] = string.format("  fretboardNextStyle = %s,", fmt(cfg.fretboardNextStyle))
  lines[#lines + 1] = string.format("  fretboardFrets = %s,", fmt(cfg.fretboardFrets))
  lines[#lines + 1] = string.format("  fretboardNoteRoundness = %s,", fmt(cfg.fretboardNoteRoundness))
  lines[#lines + 1] = string.format("  fretboardNoteSize = %s,", fmt(cfg.fretboardNoteSize))
  lines[#lines + 1] = string.format("  fretboardDotSize = %s,", fmt(cfg.fretboardDotSize))
  lines[#lines + 1] = string.format("  fretboardFretThickness = %s,", fmt(cfg.fretboardFretThickness))
  lines[#lines + 1] = string.format("  fretboardStringThickness = %s,", fmt(cfg.fretboardStringThickness))
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

apply_settings_change = function()
  clamp_config(cfg)
  config_mod.save(cfg, "luaTab")
  rebuild_preset_lists()
  util.log_init(script_dir, cfg.logEnabled, cfg.logVerbose, cfg.logPath)
  util.log("settings changed", "info")
  state.prevBarsBuf = tostring(cfg.prevBars or 0)
  state.nextBarsBuf = tostring(cfg.nextBars or 0)
  rebuild_data(get_cursor_time())
end

local function reset_config_to_defaults()
  if config_mod.reset then
    config_mod.reset(SECTION)
  end
  cfg = config_mod.load("luaTab")
  if not cfg.logPath or cfg.logPath == "" then
    cfg.logPath = script_dir .. "/luaTab.log"
  end
  user_tuning_presets = load_user_tuning_presets(SECTION)
  user_color_presets = load_user_color_presets(SECTION)
  user_style_presets = load_user_style_presets(SECTION)
  rebuild_preset_lists()
  state.colorHex = {}
  state.logPathBuf = nil
  state.prevBarsBuf = nil
  state.nextBarsBuf = nil
  state.windowInitialized = false
  state.settingsWindowInitialized = false
  state.fretboardWindowInitialized = false
  state.colorPickerWindowInitialized = false
  state.fretboardFocused = false
  state.panels.fretboard.value = cfg.fretboardMode ~= "hidden"
  state.fretboardPanelOpen = state.panels.fretboard.value
  state.panels.settings.value = false
  state.panels.colorPicker.value = false
  state.colorPickerKey = "background"
  apply_settings_change()
end

local function should_quit()
  return reaper.GetExtState(SECTION, KEY_QUIT) == "1"
end

local function draw_settings_panel()
  if state.panels.settings.value then
    apply_pending_layout("settings", "settingsWindowInitialized")
    if not state.settingsWindowInitialized then
      reaper.ImGui_SetNextWindowSize(ctx, 560, 520, reaper.ImGui_Cond_FirstUseEver())
      if reaper.ImGui_SetNextWindowDockID and reaper.ImGui_Cond_FirstUseEver then
        reaper.ImGui_SetNextWindowDockID(ctx, 0, reaper.ImGui_Cond_FirstUseEver())
      end
      if reaper.ImGui_SetNextWindowPos and reaper.ImGui_Cond_FirstUseEver then
        reaper.ImGui_SetNextWindowPos(ctx, 120, 120, reaper.ImGui_Cond_FirstUseEver())
      end
      state.settingsWindowInitialized = true
    end
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, 480, 420, 1200, 1000)
  end

  Panels.window(ctx, state.panels.settings, "Settings", 0, function(ctx)
    update_panel_layout("settings")
    local settings_changed = false
    local settings_reset = false
    local rv
    local header_flags = reaper.ImGui_TreeNodeFlags_DefaultOpen and reaper.ImGui_TreeNodeFlags_DefaultOpen() or 0

    if reaper.ImGui_CollapsingHeader(ctx, "General", header_flags) then
      rv, cfg.logEnabled = reaper.ImGui_Checkbox(ctx, "Logging", cfg.logEnabled)
      settings_changed = settings_changed or rv
      rv, cfg.logVerbose = reaper.ImGui_Checkbox(ctx, "Verbose logging", cfg.logVerbose)
      settings_changed = settings_changed or rv

      if not state.logPathBuf then
        state.logPathBuf = cfg.logPath
      end
      reaper.ImGui_SetNextItemWidth(ctx, 320)
      rv, state.logPathBuf = reaper.ImGui_InputText(ctx, "Log file", state.logPathBuf)
      if rv then
        cfg.logPath = state.logPathBuf
        settings_changed = true
      end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "Reset default") then
        cfg.logPath = script_dir .. "/luaTab.log"
        state.logPathBuf = cfg.logPath
        settings_changed = true
      end

      if cfg.logEnabled then
        reaper.ImGui_Text(ctx, string.format("Log: %s", util.log_path() or "(none)"))
      end
      if state.takeSource then
        reaper.ImGui_Text(ctx, string.format("Source: %s", state.takeSource))
      end

      if reaper.ImGui_Button(ctx, "Export settings") then
        local export = format_settings_export(cfg)
        if reaper.ShowConsoleMsg then
          reaper.ShowConsoleMsg("\n-- luaTab settings export --\n")
          reaper.ShowConsoleMsg(export .. "\n")
        end
      end

      if reaper.ImGui_Button(ctx, "Reset all settings") then
        reaper.ImGui_OpenPopup(ctx, "Reset settings")
      end
      if reaper.ImGui_BeginPopupModal(ctx, "Reset settings", true, 0) then
        reaper.ImGui_Text(ctx, "Reset all settings to defaults?")
        reaper.ImGui_Text(ctx, "This cannot be undone.")
        if reaper.ImGui_Button(ctx, "Reset now") then
          reset_config_to_defaults()
          settings_changed = false
          settings_reset = true
          reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Cancel") then
          reaper.ImGui_CloseCurrentPopup(ctx)
        end
        reaper.ImGui_EndPopup(ctx)
      end
    end

    if reaper.ImGui_CollapsingHeader(ctx, "Tab", header_flags) then
      local tuning_changed = false
      for i = #cfg.tuning, 1, -1 do
        local string_info = cfg.tuning[i]
        reaper.ImGui_PushID(ctx, i)
        reaper.ImGui_SetNextItemWidth(ctx, 80)
        rv, string_info.name = reaper.ImGui_InputText(ctx, "Name", string_info.name)
        tuning_changed = tuning_changed or rv
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_SetNextItemWidth(ctx, 80)
        rv, string_info.open = reaper.ImGui_InputInt(ctx, "Open", string_info.open)
        tuning_changed = tuning_changed or rv
        reaper.ImGui_PopID(ctx)
      end

      if reaper.ImGui_Button(ctx, "Add string") then
        local last = cfg.tuning[#cfg.tuning]
        local open = (last and last.open or 60) + 5
        cfg.tuning[#cfg.tuning + 1] = { name = "X", open = open }
        tuning_changed = true
      end
      reaper.ImGui_SameLine(ctx)
      if #cfg.tuning > 1 and reaper.ImGui_Button(ctx, "Remove string") then
        table.remove(cfg.tuning, #cfg.tuning)
        tuning_changed = true
      end

      if tuning_changed then
        cfg.tuningPreset = "custom"
        settings_changed = true
      end

      if reaper.ImGui_Button(ctx, "Save current as preset") then
        open_preset_save("tuning")
      end

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Grouping")
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.groupEpsilonMs = edit_float(ctx, "Group epsilon (ms)", cfg.groupEpsilonMs, 0, 100)
      settings_changed = settings_changed or rv

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Playability")
      reaper.ImGui_SetNextItemWidth(ctx, 120)
      rv, cfg.maxFret = edit_int(ctx, "Max fret", cfg.maxFret, 1, 48)
      settings_changed = settings_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 120)
      rv, cfg.maxFrettedSpan = edit_int(ctx, "Max span", cfg.maxFrettedSpan, 0, 24)
      settings_changed = settings_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 120)
      rv, cfg.maxSimul = edit_int(ctx, "Max simult", cfg.maxSimul, 1, #cfg.tuning)
      settings_changed = settings_changed or rv

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Assignment weights")
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.weights.lowFret = edit_int(ctx, "Low fret", cfg.weights.lowFret, 0, 10)
      settings_changed = settings_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.weights.stayOnString = edit_int(ctx, "Stay on string", cfg.weights.stayOnString, 0, 10)
      settings_changed = settings_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.weights.stringJump = edit_int(ctx, "String jump", cfg.weights.stringJump, 0, 10)
      settings_changed = settings_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.weights.fretJump = edit_int(ctx, "Fret jump", cfg.weights.fretJump, 0, 10)
      settings_changed = settings_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 160)
      rv, cfg.weights.highFret = edit_int(ctx, "High fret", cfg.weights.highFret, 0, 10)
      settings_changed = settings_changed or rv
    end

    if reaper.ImGui_CollapsingHeader(ctx, "Playback", header_flags) then
      rv, cfg.followPlay = reaper.ImGui_Checkbox(ctx, "Follow play cursor", cfg.followPlay)
      settings_changed = settings_changed or rv
      rv, cfg.followEditWhenStopped = reaper.ImGui_Checkbox(ctx, "Follow edit cursor", cfg.followEditWhenStopped)
      settings_changed = settings_changed or rv

      if cfg.updateMode == "step" then
        reaper.ImGui_SetNextItemWidth(ctx, 120)
        rv, cfg.updateStep = edit_int(ctx, "Step", cfg.updateStep, 1, 64)
        settings_changed = settings_changed or rv
      end

      reaper.ImGui_SetNextItemWidth(ctx, 120)
      rv, cfg.antidelayBeats = edit_int(ctx, "Antidelay beats", cfg.antidelayBeats, 0, 64)
      settings_changed = settings_changed or rv
    end

    if reaper.ImGui_CollapsingHeader(ctx, "Styling", header_flags) then
      local scale_changed = false

      if reaper.ImGui_Button(ctx, "Save colors as preset") then
        open_preset_save("color")
      end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "Save style as preset") then
        open_preset_save("style")
      end

      reaper.ImGui_Text(ctx, "Layout")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.systemGutterPx = edit_int(ctx, "System gutter", cfg.systemGutterPx, 0, 300)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.barPrefixPx = edit_int(ctx, "Bar prefix", cfg.barPrefixPx, 0, 300)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.barContentPx = edit_int(ctx, "Bar content", cfg.barContentPx, 10, 600)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.barGutterPx = edit_int(ctx, "Bar gutter", cfg.barGutterPx, 0, 120)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.systemRowGapPx = edit_int(ctx, "Row gap", cfg.systemRowGapPx, 0, 120)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.staffPaddingTopPx = edit_int(ctx, "Staff pad top", cfg.staffPaddingTopPx, 0, 80)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.staffPaddingBottomPx = edit_int(ctx, "Staff pad bottom", cfg.staffPaddingBottomPx, 0, 80)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Background")
      if draw_color_swatch(ctx, cfg.colors.background, 14, "background") then
        open_color_picker("background")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Background", "background", cfg.colors.background, true) or settings_changed

      if draw_color_swatch(ctx, cfg.colors.uiText, 14, "uiText") then
        open_color_picker("uiText")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "UI text", "uiText", cfg.colors.uiText, true) or settings_changed

      if draw_color_swatch(ctx, cfg.colors.uiControlBg, 14, "uiControlBg") then
        open_color_picker("uiControlBg")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "UI controls", "uiControlBg", cfg.colors.uiControlBg, true) or settings_changed

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Strings")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.stringSpacingPx = edit_int(ctx, "String spacing", cfg.stringSpacingPx, 6, 40)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      if draw_color_swatch(ctx, cfg.colors.strings, 14, "strings") then
        open_color_picker("strings")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Strings (staff lines)", "strings", cfg.colors.strings, true) or settings_changed

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Barlines")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.barLineThickness = edit_float(ctx, "Barline thickness", cfg.barLineThickness, 0.5, 6)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      if draw_color_swatch(ctx, cfg.colors.barlines, 14, "barlines") then
        open_color_picker("barlines")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Barlines", "barlines", cfg.colors.barlines, true) or settings_changed

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Item boundaries")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.itemBoundaryThickness = edit_float(ctx, "Item boundary thickness", cfg.itemBoundaryThickness, 0.5, 6)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      if draw_color_swatch(ctx, cfg.colors.itemBoundary, 14, "itemBoundary") then
        open_color_picker("itemBoundary")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Item boundaries", "itemBoundary", cfg.colors.itemBoundary, true) or settings_changed

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Current bar highlight")
      if draw_color_swatch(ctx, cfg.colors.marker, 14, "marker") then
        open_color_picker("marker")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Current bar highlight", "marker", cfg.colors.marker, true) or settings_changed

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Fret text")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fonts.fretScale = edit_float(ctx, "Fret scale", cfg.fonts.fretScale, 0.6, 2.5)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      if draw_color_swatch(ctx, cfg.colors.text, 14, "text") then
        open_color_picker("text")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Text (frets + labels)", "text", cfg.colors.text, true) or settings_changed
      if draw_color_swatch(ctx, cfg.colors.noteBg, 14, "noteBg") then
        open_color_picker("noteBg")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Fret background", "noteBg", cfg.colors.noteBg, true) or settings_changed

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Dropped notes")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fonts.droppedScale = edit_float(ctx, "Dropped scale", cfg.fonts.droppedScale, 0.5, 2.0)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      if draw_color_swatch(ctx, cfg.colors.dropped, 14, "dropped") then
        open_color_picker("dropped")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Dropped notes", "dropped", cfg.colors.dropped, true) or settings_changed

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Time signatures")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fonts.timeSigScale = edit_float(ctx, "Time sig scale", cfg.fonts.timeSigScale, 0.6, 3.0)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv
      rv, cfg.showFirstTimeSigInSystemGutter = reaper.ImGui_Checkbox(ctx, "Time signature in gutter", cfg.showFirstTimeSigInSystemGutter)
      settings_changed = settings_changed or rv

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Fretboard")
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fretboardFrets = edit_int(ctx, "Fret count", cfg.fretboardFrets, 1, 36)
      settings_changed = settings_changed or rv

      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fretboardNoteRoundness = edit_float(ctx, "Note roundness", cfg.fretboardNoteRoundness, 0, 1)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv

      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fretboardNoteSize = edit_float(ctx, "Note size", cfg.fretboardNoteSize, 0.3, 2.5)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv

      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fretboardDotSize = edit_float(ctx, "Dot size", cfg.fretboardDotSize, 0.2, 3.0)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv

      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fretboardFretThickness = edit_float(ctx, "Fret thickness", cfg.fretboardFretThickness, 0.5, 6.0)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv

      reaper.ImGui_SetNextItemWidth(ctx, 140)
      rv, cfg.fretboardStringThickness = edit_float(ctx, "String thickness", cfg.fretboardStringThickness, 0.5, 6.0)
      settings_changed = settings_changed or rv
      scale_changed = scale_changed or rv

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Fretboard colors")
      if draw_color_swatch(ctx, cfg.colors.fretboardBg, 14, "fretboardBg") then
        open_color_picker("fretboardBg")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Fretboard bg", "fretboardBg", cfg.colors.fretboardBg, true) or settings_changed

      if draw_color_swatch(ctx, cfg.colors.fretboardStrings, 14, "fretboardStrings") then
        open_color_picker("fretboardStrings")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Fretboard strings", "fretboardStrings", cfg.colors.fretboardStrings, true) or settings_changed

      if draw_color_swatch(ctx, cfg.colors.fretboardFrets, 14, "fretboardFrets") then
        open_color_picker("fretboardFrets")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Fretboard frets/dots", "fretboardFrets", cfg.colors.fretboardFrets, true) or settings_changed

      if draw_color_swatch(ctx, cfg.colors.fretboardCurrent, 14, "fretboardCurrent") then
        open_color_picker("fretboardCurrent")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Fretboard current note", "fretboardCurrent", cfg.colors.fretboardCurrent, true) or settings_changed

      if draw_color_swatch(ctx, cfg.colors.fretboardNext, 14, "fretboardNext") then
        open_color_picker("fretboardNext")
      end
      reaper.ImGui_SameLine(ctx)
      settings_changed = edit_color_hex(ctx, "Fretboard next notes", "fretboardNext", cfg.colors.fretboardNext, true) or settings_changed

      if scale_changed then
        cfg.stylePreset = "custom"
        settings_changed = true
      end
    end

    if settings_changed and not settings_reset then
      apply_settings_change()
    end

    if reaper.ImGui_Button(ctx, "Close") then
      state.panels.settings.value = false
    end
  end)
end

local function draw_ui()
  if should_quit() then
    cleanup()
    return
  end
  apply_pending_layout("main", "windowInitialized")
  if not state.windowInitialized then
    local default_w, default_h = 900, 360
    reaper.ImGui_SetNextWindowSize(ctx, default_w, default_h, reaper.ImGui_Cond_FirstUseEver())
    if reaper.ImGui_GetMainViewport and reaper.ImGui_Viewport_GetWorkPos and reaper.ImGui_Viewport_GetWorkSize then
      local viewport = reaper.ImGui_GetMainViewport(ctx)
      if viewport then
        local work_x, work_y = reaper.ImGui_Viewport_GetWorkPos(viewport)
        local work_w, work_h = reaper.ImGui_Viewport_GetWorkSize(viewport)
        reaper.ImGui_SetNextWindowPos(
          ctx,
          work_x + (work_w - default_w) * 0.5,
          work_y + (work_h - default_h) * 0.5,
          reaper.ImGui_Cond_FirstUseEver()
        )
      else
        reaper.ImGui_SetNextWindowPos(ctx, 100, 100, reaper.ImGui_Cond_FirstUseEver())
      end
    else
      reaper.ImGui_SetNextWindowPos(ctx, 100, 100, reaper.ImGui_Cond_FirstUseEver())
    end
    if reaper.ImGui_SetNextWindowDockID and reaper.ImGui_Cond_FirstUseEver then
      reaper.ImGui_SetNextWindowDockID(ctx, 0, reaper.ImGui_Cond_FirstUseEver())
    end
    state.windowInitialized = true
  end

  reaper.ImGui_SetNextWindowSizeConstraints(ctx, 640, 240, 4096, 4096)

  local pushed_bg = false
  local pushed_text = false
  local pushed_popup = false
  local pushed_controls = false
  local pushed_buttons = false
  local function lighten_color(color, amount)
    return {
      util.clamp(color[1] + amount, 0, 1),
      util.clamp(color[2] + amount, 0, 1),
      util.clamp(color[3] + amount, 0, 1),
      1.0,
    }
  end
  if cfg.colors and cfg.colors.background and reaper.ImGui_PushStyleColor and reaper.ImGui_Col_WindowBg then
    local bg_col = util.color_u32(cfg.colors.background[1], cfg.colors.background[2], cfg.colors.background[3], cfg.colors.background[4])
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), bg_col)
    pushed_bg = true
  end
  if cfg.colors and cfg.colors.uiText and reaper.ImGui_PushStyleColor and reaper.ImGui_Col_Text then
    local text_col = util.color_u32(cfg.colors.uiText[1], cfg.colors.uiText[2], cfg.colors.uiText[3], cfg.colors.uiText[4])
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), text_col)
    pushed_text = true
  end
  if cfg.colors and cfg.colors.background and reaper.ImGui_PushStyleColor and reaper.ImGui_Col_PopupBg then
    local popup_col = util.color_u32(cfg.colors.background[1], cfg.colors.background[2], cfg.colors.background[3], cfg.colors.background[4])
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(), popup_col)
    pushed_popup = true
  end
  if cfg.colors and cfg.colors.uiControlBg and reaper.ImGui_PushStyleColor and reaper.ImGui_Col_FrameBg then
    local control_col = util.color_u32(cfg.colors.uiControlBg[1], cfg.colors.uiControlBg[2], cfg.colors.uiControlBg[3], cfg.colors.uiControlBg[4])
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), control_col)
    if reaper.ImGui_Col_FrameBgHovered then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), control_col)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), control_col)
      pushed_controls = true
    end
  end
  if cfg.colors and cfg.colors.uiControlBg and reaper.ImGui_PushStyleColor and reaper.ImGui_Col_Button then
    local base = cfg.colors.uiControlBg
    local hover = lighten_color(base, 0.12)
    local active = lighten_color(base, 0.18)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), util.color_u32(base[1], base[2], base[3], 1.0))
    if reaper.ImGui_Col_ButtonHovered then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), util.color_u32(hover[1], hover[2], hover[3], hover[4]))
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), util.color_u32(active[1], active[2], active[3], active[4]))
      pushed_buttons = true
    end
  end

  local now = now_time()
  local t = get_cursor_time()
  local current_bar = timeline.get_measure_index(t)
  local take = select(1, source.get_take(t))
  local take_id = take and tostring(take) or nil

  local main_flags = 0
  Panels.window(ctx, state.panels.main, "luaTab", main_flags, function(ctx)
    update_panel_layout("main")
    Panels.dockspace(ctx, "luaTabDock")

    if now - state.lastHeartbeat >= 1.0 then
      reaper.SetExtState(SECTION, KEY_HEARTBEAT, tostring(now), false)
      state.lastHeartbeat = now
    end

    local quick_changed = false
    local rv
    local controls_x, controls_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local controls_w, _ = reaper.ImGui_GetContentRegionAvail(ctx)

    reaper.ImGui_Text(ctx, "Tuning")
    reaper.ImGui_SameLine(ctx)
    local tuning_current_index = preset_index_for_id(tuning_presets, cfg.tuningPreset or "custom", "custom")
    local tuning_current = tuning_presets[tuning_current_index]
    local tuning_label = tuning_current and (tuning_current.label or tuning_current.name or tuning_current.id) or ""
    reaper.ImGui_SetNextItemWidth(ctx, 190)
    if reaper.ImGui_BeginCombo and reaper.ImGui_BeginCombo(ctx, "##TuningPreset", tuning_label) then
      for i, preset in ipairs(tuning_presets) do
        if reaper.ImGui_PushID then
          reaper.ImGui_PushID(ctx, i)
        end
        local selected = preset.id == cfg.tuningPreset
        if reaper.ImGui_Selectable(ctx, preset.label or preset.name or preset.id, selected) then
          if preset.id == "custom" then
            cfg.tuningPreset = "custom"
            quick_changed = true
          elseif apply_tuning_preset(cfg, preset) then
            quick_changed = true
          end
        end
        if reaper.ImGui_PopID then
          reaper.ImGui_PopID(ctx)
        end
      end
      if reaper.ImGui_EndCombo then
        reaper.ImGui_EndCombo(ctx)
      end
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, "Colors")
    reaper.ImGui_SameLine(ctx)
    local color_current_index = color_preset_index(cfg.colorPreset or "dark")
    local color_current = color_presets[color_current_index]
    local color_label = color_current and (color_current.label or color_current.name or color_current.id) or ""
    reaper.ImGui_SetNextItemWidth(ctx, 120)
    if reaper.ImGui_BeginCombo and reaper.ImGui_BeginCombo(ctx, "##ColorPreset", color_label) then
      for i, preset in ipairs(color_presets) do
        if reaper.ImGui_PushID then
          reaper.ImGui_PushID(ctx, i)
        end
        local selected = preset.id == cfg.colorPreset
        if reaper.ImGui_Selectable(ctx, preset.label or preset.name or preset.id, selected) then
          if apply_color_preset(cfg, preset) then
            quick_changed = true
          end
        end
        if reaper.ImGui_PopID then
          reaper.ImGui_PopID(ctx)
        end
      end
      if reaper.ImGui_Selectable then
        if reaper.ImGui_Selectable(ctx, "Save current as preset...", false) then
          open_preset_save("color")
        end
      end
      if reaper.ImGui_EndCombo then
        reaper.ImGui_EndCombo(ctx)
      end
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, "Style")
    reaper.ImGui_SameLine(ctx)
    local style_current_index = style_preset_index(cfg.stylePreset or "default")
    local style_current = style_presets[style_current_index]
    local style_label = style_current and (style_current.label or style_current.name or style_current.id) or ""
    reaper.ImGui_SetNextItemWidth(ctx, 140)
    if reaper.ImGui_BeginCombo and reaper.ImGui_BeginCombo(ctx, "##StylePreset", style_label) then
      for i, preset in ipairs(style_presets) do
        if reaper.ImGui_PushID then
          reaper.ImGui_PushID(ctx, i)
        end
        local selected = preset.id == cfg.stylePreset
        if reaper.ImGui_Selectable(ctx, preset.label or preset.name or preset.id, selected) then
          if apply_style_preset(cfg, preset) then
            quick_changed = true
          end
        end
        if reaper.ImGui_PopID then
          reaper.ImGui_PopID(ctx)
        end
      end
      if reaper.ImGui_Selectable then
        if reaper.ImGui_Selectable(ctx, "Save current as preset...", false) then
          open_preset_save("style")
        end
      end
      if reaper.ImGui_EndCombo then
        reaper.ImGui_EndCombo(ctx)
      end
    end

    reaper.ImGui_Text(ctx, "Prev")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 50)
    if not state.prevBarsBuf then
      state.prevBarsBuf = tostring(cfg.prevBars or 0)
    end
    rv, state.prevBarsBuf = reaper.ImGui_InputText(ctx, "##PrevBars", state.prevBarsBuf)
    if rv then
      local parsed = tonumber(state.prevBarsBuf)
      if parsed then
        cfg.prevBars = util.clamp(math.floor(parsed + 0.5), 0, 8)
        quick_changed = true
      end
    end
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, "Next")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 50)
    if not state.nextBarsBuf then
      state.nextBarsBuf = tostring(cfg.nextBars or 0)
    end
    rv, state.nextBarsBuf = reaper.ImGui_InputText(ctx, "##NextBars", state.nextBarsBuf)
    if rv then
      local parsed = tonumber(state.nextBarsBuf)
      if parsed then
        cfg.nextBars = util.clamp(math.floor(parsed + 0.5), 0, 64)
        quick_changed = true
      end
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, "Update")
    reaper.ImGui_SameLine(ctx)
    local update_modes = { "bar", "step", "screen", "continuous" }
    local update_labels = "Every bar\0Every N bars\0Bars on screen width\0Continuous\0"
    local update_index = 0
    for i, name in ipairs(update_modes) do
      if name == cfg.updateMode then
        update_index = i - 1
        break
      end
    end
    reaper.ImGui_SetNextItemWidth(ctx, 180)
    rv, update_index = reaper.ImGui_Combo(ctx, "##UpdateMode", update_index, update_labels)
    if rv then
      cfg.updateMode = update_modes[update_index + 1] or "bar"
      quick_changed = true
    end

    if cfg.updateMode == "step" then
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 80)
      rv, cfg.updateStep = edit_int(ctx, "##UpdateStep", cfg.updateStep, 1, 64)
      quick_changed = quick_changed or rv
    end

    if quick_changed then
      apply_settings_change()
    end

    draw_preset_save_modal(ctx)

    local avail_x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
    local bars_per_system = layout.calc_bars_per_system(cfg, avail_x)
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local origin_x, origin_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local font_size = reaper.ImGui_GetFontSize(ctx)

    local virtual_bar = compute_virtual_bar(t, current_bar, cfg.antidelayBeats)
    local update_key = compute_update_key(cfg.updateMode, virtual_bar, bars_per_system, cfg.updateStep)
    if state.lastUpdateKey == nil or update_key ~= state.lastUpdateKey or take_id ~= state.takeId then
      rebuild_data(t)
      state.lastUpdateKey = update_key
    end

    if cfg.updateMode == "continuous" then
      origin_x = origin_x - compute_sweep_offset_px(t, cfg)
    end

    if state.hasMidiTake then
      state.systems = layout.build_systems(state.bars, cfg, avail_x, origin_x, origin_y)
      render.draw_systems(draw_list, state.systems, cfg, state.eventsByBar, font_size, ctx, current_bar, state.itemBounds)
      handle_bar_click(ctx, state.systems, cfg)
    end

    do
      local has_overlay = reaper.ImGui_GetWindowPos and reaper.ImGui_GetWindowSize
      if has_overlay then
        local overlay_list = draw_list
        if reaper.ImGui_GetForegroundDrawList then
          local ok_fg, fg = pcall(reaper.ImGui_GetForegroundDrawList, ctx)
          if ok_fg and fg then
            overlay_list = fg
          else
            local ok_fg2, fg2 = pcall(reaper.ImGui_GetForegroundDrawList)
            if ok_fg2 and fg2 then
              overlay_list = fg2
            end
          end
        end
        local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)
        local win_w, win_h = reaper.ImGui_GetWindowSize(ctx)
        local content_x0 = win_x
        local content_y0 = win_y
        local content_x1 = win_x + win_w
        local content_y1 = win_y + win_h
        if reaper.ImGui_GetWindowContentRegionMin and reaper.ImGui_GetWindowContentRegionMax then
          local min_x, min_y = reaper.ImGui_GetWindowContentRegionMin(ctx)
          local max_x, max_y = reaper.ImGui_GetWindowContentRegionMax(ctx)
          content_x0 = win_x + min_x
          content_y0 = win_y + min_y
          content_x1 = win_x + max_x
          content_y1 = win_y + max_y
        end

        local frame_h = reaper.ImGui_GetFrameHeight and reaper.ImGui_GetFrameHeight(ctx) or 22
        local button_size = frame_h * 2 + 6
        local gear_pad = 10
        local gear_offset_y = 20
        local gear_x = util.clamp(content_x1 - button_size - gear_pad, content_x0, math.max(content_x0, content_x1 - button_size))
        local gear_y = util.clamp(content_y0 + gear_pad + gear_offset_y, content_y0, math.max(content_y0, content_y1 - button_size))
        local restore_x, restore_y = reaper.ImGui_GetCursorScreenPos(ctx)
        if reaper.ImGui_SetCursorScreenPos then
          reaper.ImGui_SetCursorScreenPos(ctx, gear_x, gear_y)
          local clicked = false
          if reaper.ImGui_InvisibleButton then
            clicked = reaper.ImGui_InvisibleButton(ctx, "##PanelsButton", button_size, button_size)
          elseif reaper.ImGui_Button then
            clicked = reaper.ImGui_Button(ctx, "", button_size, button_size)
          end

          local hovered = reaper.ImGui_IsItemHovered and reaper.ImGui_IsItemHovered(ctx) or false
          local active = reaper.ImGui_IsItemActive and reaper.ImGui_IsItemActive(ctx) or false
          if clicked then
            if reaper.ImGui_OpenPopup then
              reaper.ImGui_OpenPopup(ctx, "PanelsMenu")
            end
          end

          local base = (cfg.colors and cfg.colors.uiControlBg) or { 0.2, 0.2, 0.2, 1.0 }
          local hover = lighten_color(base, 0.12)
          local active_col = lighten_color(base, 0.18)
          local use_col = base
          if active then
            use_col = active_col
          elseif hovered then
            use_col = hover
          end
          local bg_col = util.color_u32(use_col[1], use_col[2], use_col[3], 1.0)
          local icon = (cfg.colors and cfg.colors.uiText) or { 1, 1, 1, 1 }
          local icon_col = util.color_u32(icon[1], icon[2], icon[3], icon[4])
          local icon_pad = math.max(6, math.floor(button_size * 0.18))
          local icon_w = button_size - icon_pad * 2
          local icon_h = icon_w * 0.75
          local icon_x0 = gear_x + (button_size - icon_w) * 0.5
          local icon_y0 = gear_y + (button_size - icon_h) * 0.5
          local icon_x1 = icon_x0 + icon_w
          local icon_y1 = icon_y0 + icon_h
          local bar_h = math.max(2, math.floor(icon_h * 0.22))

          reaper.ImGui_DrawList_AddRectFilled(overlay_list, gear_x, gear_y, gear_x + button_size, gear_y + button_size, bg_col, 4)
          reaper.ImGui_DrawList_AddRect(overlay_list, icon_x0, icon_y0, icon_x1, icon_y1, icon_col, 2)
          reaper.ImGui_DrawList_AddRectFilled(overlay_list, icon_x0, icon_y0, icon_x1, icon_y0 + bar_h, icon_col, 2)
          reaper.ImGui_SetCursorScreenPos(ctx, restore_x, restore_y)
          if reaper.ImGui_Dummy then
            reaper.ImGui_Dummy(ctx, 0, 0)
          end
        end

        if reaper.ImGui_SetNextWindowPos then
          reaper.ImGui_SetNextWindowPos(ctx, gear_x, gear_y + button_size + 6)
        end
        if reaper.ImGui_BeginPopup then
          if reaper.ImGui_BeginPopup(ctx, "PanelsMenu") then
            local changed, v
            changed, v = reaper.ImGui_MenuItem(ctx, "Fretboard", nil, state.panels.fretboard.value)
            if changed then
              state.panels.fretboard.value = v
              if sync_fretboard_panel_state() then
                apply_settings_change()
              end
            end

            changed, v = reaper.ImGui_MenuItem(ctx, "Settings", nil, state.panels.settings.value)
            if changed then
              state.panels.settings.value = v
            end

            changed, v = reaper.ImGui_MenuItem(ctx, "Color Picker", nil, state.panels.colorPicker.value)
            if changed then
              state.panels.colorPicker.value = v
            end

            reaper.ImGui_EndPopup(ctx)
          end
        end

        local status_text = nil
        if state.statusMessage then
          status_text = state.statusMessage
        elseif state.lastBarIdx ~= nil then
          status_text = string.format("Bar %d", state.lastBarIdx + 1)
        end

        if status_text then
          local pad_x = 8
          local pad_y = 4
          local text_size = reaper.ImGui_GetFontSize(ctx) or 14
          local bar_h = text_size + pad_y * 2
          local bar_y0 = math.max(content_y0, content_y1 - bar_h)
          local bar_y1 = bar_y0 + bar_h
          local bg = (cfg.colors and cfg.colors.uiControlBg) or (cfg.colors and cfg.colors.background) or { 0, 0, 0, 0.85 }
          local bg_a = (bg[4] or 1.0) * 0.92
          local bg_col = util.color_u32(bg[1] or 0, bg[2] or 0, bg[3] or 0, bg_a)
          local text = (cfg.colors and cfg.colors.uiText) or { 1, 1, 1, 1 }
          local text_col = util.color_u32(text[1] or 1, text[2] or 1, text[3] or 1, text[4] or 1)

          reaper.ImGui_DrawList_AddRectFilled(overlay_list, content_x0, bar_y0, content_x1, bar_y1, bg_col)
          reaper.ImGui_DrawList_AddText(overlay_list, content_x0 + pad_x, bar_y0 + pad_y, text_col, status_text)
        end
      end
    end

    if reaper.ImGui_SetNextFrameWantCaptureKeyboard then
      local wants_keyboard = false
      if reaper.ImGui_IsAnyItemActive and reaper.ImGui_IsAnyItemActive(ctx) then
        wants_keyboard = true
      elseif reaper.ImGui_IsAnyItemFocused and reaper.ImGui_IsAnyItemFocused(ctx) then
        wants_keyboard = true
      end
      reaper.ImGui_SetNextFrameWantCaptureKeyboard(ctx, wants_keyboard)
    end

    if reaper.ImGui_IsKeyPressed and reaper.ImGui_Key_Space then
      local window_focused = true
      if reaper.ImGui_IsWindowFocused and reaper.ImGui_FocusedFlags_RootAndChildWindows then
        window_focused = reaper.ImGui_IsWindowFocused(ctx, reaper.ImGui_FocusedFlags_RootAndChildWindows()) or state.fretboardFocused
      else
        window_focused = window_focused or state.fretboardFocused
      end
      if window_focused then
        local wants_keyboard = false
        if reaper.ImGui_IsAnyItemActive and reaper.ImGui_IsAnyItemActive(ctx) then
          wants_keyboard = true
        elseif reaper.ImGui_IsAnyItemFocused and reaper.ImGui_IsAnyItemFocused(ctx) then
          wants_keyboard = true
        end
        if not wants_keyboard and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Space(), false) then
          reaper.Main_OnCommand(40044, 0)
        end
      end
    end
  end)

  draw_settings_panel()
  draw_color_picker_panel()

  local fretboard_panel_changed = draw_fretboard_panel(t, current_bar)
  if fretboard_panel_changed then
    apply_settings_change()
  end

  Panels.end_frame_check()
  if (pushed_bg or pushed_text or pushed_popup or pushed_controls or pushed_buttons) and reaper.ImGui_PopStyleColor then
    reaper.ImGui_PopStyleColor(ctx, (pushed_bg and 1 or 0) + (pushed_text and 1 or 0) + (pushed_popup and 1 or 0) + (pushed_controls and 3 or 0) + (pushed_buttons and 3 or 0))
  end

  if state.panels.main.value then
    reaper.defer(draw_ui)
  else
    util.log("luaTab closed", "info")
    cleanup()
  end
end

rebuild_data(get_cursor_time())
reaper.defer(draw_ui)
