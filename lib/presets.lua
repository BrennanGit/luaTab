-- lib/presets.lua
-- Built-in presets plus ExtState persistence for user presets (tuning, color,
-- style) and manual string overrides. Pure data/persistence: applying presets
-- to live config/UI state stays in luaTab.lua.

local util = require("util")
local store = require("store")
local config = require("config")

local presets = {}

-- Keys captured by a style preset.
presets.scale_value_keys = {
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

presets.scale_font_keys = {
  "fretScale",
  "timeSigScale",
  "droppedScale",
}

-- Keys captured by a style preset's layout block.
presets.layout_value_keys = {
  "prevBars",
  "nextBars",
  "updateStep",
  "antidelayBeats",
  "fretboardPreNoteOffMs",
}

presets.layout_string_keys = {
  "updateMode",
}

presets.layout_panel_keys = {
  "main",
  "settings",
  "fretboard",
  "colorPicker",
  "userPresets",
  "diagnostics",
}

presets.default_tunings = {
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

presets.custom_tuning = {
  id = "custom",
  label = "Current (custom)",
  name = "Current (custom)",
}

presets.default_colors = {
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

function presets.capture_scale(source)
  local scale = {}
  for _, key in ipairs(presets.scale_value_keys) do
    scale[key] = source[key]
  end
  scale.fonts = {}
  for _, key in ipairs(presets.scale_font_keys) do
    scale.fonts[key] = source.fonts and source.fonts[key] or nil
  end
  return scale
end

local function default_layout()
  local d = config.defaults
  return {
    prevBars = d.prevBars,
    nextBars = d.nextBars,
    updateMode = d.updateMode,
    updateStep = d.updateStep,
    antidelayBeats = d.antidelayBeats,
    fretboardPreNoteOffMs = d.fretboardPreNoteOffMs,
    panels = {
      main = { open = true, pos = { 100, 100 }, size = { 900, 360 } },
      settings = { open = false, pos = { 120, 120 }, size = { 560, 520 } },
      fretboard = { open = d.fretboardMode ~= "hidden", pos = { 140, 180 }, size = { 520, 220 } },
      colorPicker = { open = false, pos = { 160, 200 }, size = { 520, 420 } },
      userPresets = { open = false, pos = { 180, 220 }, size = { 520, 480 } },
    },
  }
end

presets.default_styles = {
  {
    id = "default",
    label = "Default",
    name = "Default",
    scale = presets.capture_scale(config.defaults),
    layout = default_layout(),
  },
}

presets.custom_style = {
  id = "custom",
  label = "Current (custom)",
  name = "Current (custom)",
}

-- ---------------------------------------------------------------------------
-- Name helpers

function presets.normalize_name(name)
  if not name then return "" end
  return name:match("^%s*(.-)%s*$")
end

function presets.find_user_index(list, name)
  local target = name:lower()
  for i, preset in ipairs(list) do
    if preset.name and preset.name:lower() == target then
      return i
    end
  end
  return nil
end

local conflict_sources = {
  tuning = { defaults = presets.default_tunings, custom = presets.custom_tuning },
  color = { defaults = presets.default_colors },
  style = { defaults = presets.default_styles, custom = presets.custom_style },
}

-- Returns { type = "default"|"user", index?, label } when `name` collides with
-- an existing preset of `kind`, otherwise nil.
function presets.name_conflict(kind, name, user_list)
  local sources = conflict_sources[kind]
  if not sources then
    return nil
  end
  local target = name:lower()
  for _, preset in ipairs(sources.defaults) do
    if preset.name and preset.name:lower() == target then
      return { type = "default", label = preset.label }
    end
  end
  if sources.custom and sources.custom.name and sources.custom.name:lower() == target then
    return { type = "default", label = sources.custom.label }
  end
  for i, preset in ipairs(user_list or {}) do
    if preset.name and preset.name:lower() == target then
      return { type = "user", index = i, label = preset.name }
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Manual string overrides

function presets.load_overrides(section)
  local entries = {}
  local count = store.read_number(section, "manualOverrides.count", 0)
  for i = 1, count do
    local key = store.read_string(section, string.format("manualOverrides.%d.key", i), "")
    local string_index = store.read_number(section, string.format("manualOverrides.%d.string", i), nil)
    if key ~= "" and string_index ~= nil then
      entries[key] = { string = string_index }
    end
  end
  return entries
end

function presets.save_overrides(section, entries)
  local old_count = store.read_number(section, "manualOverrides.count", 0)
  local keys = {}
  for key in pairs(entries or {}) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  store.write(section, "manualOverrides.count", #keys)
  for i, key in ipairs(keys) do
    store.write(section, string.format("manualOverrides.%d.key", i), key)
    store.write(section, string.format("manualOverrides.%d.string", i), entries[key].string)
  end
  for i = #keys + 1, old_count do
    store.delete(section, string.format("manualOverrides.%d.key", i))
    store.delete(section, string.format("manualOverrides.%d.string", i))
  end
end

local function clear_overrides(section)
  local count = store.read_number(section, "manualOverrides.count", 0)
  for i = 1, count do
    store.delete(section, string.format("manualOverrides.%d.key", i))
    store.delete(section, string.format("manualOverrides.%d.string", i))
  end
  store.delete(section, "manualOverrides.count")
end

-- ---------------------------------------------------------------------------
-- User tuning presets

function presets.load_user_tunings(section)
  local list = {}
  local count = store.read_number(section, "userPresets.tuning.count", 0)
  for i = 1, count do
    local name = store.read_string(section, string.format("userPresets.tuning.%d.name", i), "")
    local string_count = store.read_number(section, string.format("userPresets.tuning.%d.count", i), 0)
    local tuning = {}
    for j = 1, string_count do
      local string_name = store.read_string(section, string.format("userPresets.tuning.%d.string.%d.name", i, j), "")
      local open = store.read_number(section, string.format("userPresets.tuning.%d.string.%d.open", i, j), nil)
      if string_name ~= "" and open ~= nil then
        tuning[#tuning + 1] = { name = string_name, open = open }
      end
    end
    if name ~= "" and #tuning > 0 then
      list[#list + 1] = { name = name, tuning = tuning }
    end
  end
  return list
end

local function clear_user_tunings(section)
  local count = store.read_number(section, "userPresets.tuning.count", 0)
  for i = 1, math.max(count, 64) do
    local base = string.format("userPresets.tuning.%d", i)
    local has_entry = store.has(section, base .. ".name") or store.has(section, base .. ".count")
    if not has_entry and i > count then
      break
    end
    local string_count = store.read_number(section, base .. ".count", 0)
    store.delete(section, base .. ".name")
    store.delete(section, base .. ".count")
    for j = 1, string_count do
      store.delete(section, string.format("%s.string.%d.name", base, j))
      store.delete(section, string.format("%s.string.%d.open", base, j))
    end
  end
  store.delete(section, "userPresets.tuning.count")
end

function presets.save_user_tunings(section, list)
  clear_user_tunings(section)
  store.write(section, "userPresets.tuning.count", #list)
  for i, preset in ipairs(list) do
    store.write(section, string.format("userPresets.tuning.%d.name", i), preset.name)
    store.write(section, string.format("userPresets.tuning.%d.count", i), #preset.tuning)
    for j, string_info in ipairs(preset.tuning) do
      store.write(section, string.format("userPresets.tuning.%d.string.%d.name", i, j), string_info.name)
      store.write(section, string.format("userPresets.tuning.%d.string.%d.open", i, j), string_info.open)
    end
  end
end

-- ---------------------------------------------------------------------------
-- User color presets

function presets.load_user_colors(section)
  local list = {}
  local count = store.read_number(section, "userPresets.colors.count", 0)
  for i = 1, count do
    local name = store.read_string(section, string.format("userPresets.colors.%d.name", i), "")
    if name ~= "" then
      local colors = {}
      for _, key in ipairs(config.color_keys) do
        local color = store.read_color(section, string.format("userPresets.colors.%d.colors.%s", i, key), nil)
        if color then
          colors[key] = color
        end
      end
      if next(colors) then
        list[#list + 1] = { name = name, colors = colors }
      end
    end
  end
  return list
end

local function clear_user_colors(section)
  local count = store.read_number(section, "userPresets.colors.count", 0)
  for i = 1, math.max(count, 64) do
    local base = string.format("userPresets.colors.%d", i)
    if not store.has(section, base .. ".name") and i > count then
      break
    end
    store.delete(section, base .. ".name")
    for _, key in ipairs(config.color_keys) do
      store.delete_color(section, string.format("%s.colors.%s", base, key))
    end
  end
  store.delete(section, "userPresets.colors.count")
end

function presets.save_user_colors(section, list)
  clear_user_colors(section)
  store.write(section, "userPresets.colors.count", #list)
  for i, preset in ipairs(list) do
    store.write(section, string.format("userPresets.colors.%d.name", i), preset.name)
    for _, key in ipairs(config.color_keys) do
      local color = preset.colors and preset.colors[key] or nil
      if color then
        store.write_color(section, string.format("userPresets.colors.%d.colors.%s", i, key), color)
      end
    end
  end
end

function presets.capture_colors(colors)
  local snapshot = {}
  for _, key in ipairs(config.color_keys) do
    if colors and colors[key] then
      snapshot[key] = util.copy_table(colors[key])
    end
  end
  return snapshot
end

-- ---------------------------------------------------------------------------
-- User style presets (scale + fonts + optional layout/panels)

function presets.load_user_styles(section)
  local list = {}
  local count = store.read_number(section, "userPresets.style.count", 0)
  for i = 1, count do
    local name = store.read_string(section, string.format("userPresets.style.%d.name", i), "")
    if name ~= "" then
      local scale = {}
      local has_values = false
      for _, key in ipairs(presets.scale_value_keys) do
        local value = store.read_number(section, string.format("userPresets.style.%d.%s", i, key), nil)
        if value ~= nil then
          scale[key] = value
          has_values = true
        end
      end
      scale.fonts = {}
      for _, key in ipairs(presets.scale_font_keys) do
        local value = store.read_number(section, string.format("userPresets.style.%d.fonts.%s", i, key), nil)
        if value ~= nil then
          scale.fonts[key] = value
          has_values = true
        end
      end
      local layout = {}
      local has_layout = false
      for _, key in ipairs(presets.layout_value_keys) do
        local value = store.read_number(section, string.format("userPresets.style.%d.layout.%s", i, key), nil)
        if value ~= nil then
          layout[key] = value
          has_layout = true
        end
      end
      for _, key in ipairs(presets.layout_string_keys) do
        local value = store.read_string(section, string.format("userPresets.style.%d.layout.%s", i, key), "")
        if value ~= "" then
          layout[key] = value
          has_layout = true
        end
      end
      local panels = {}
      for _, panel_key in ipairs(presets.layout_panel_keys) do
        local base = string.format("userPresets.style.%d.layout.panels.%s", i, panel_key)
        local open = store.read_bool(section, base .. ".open", nil)
        local pos_x = store.read_number(section, base .. ".pos.x", nil)
        local pos_y = store.read_number(section, base .. ".pos.y", nil)
        local size_w = store.read_number(section, base .. ".size.w", nil)
        local size_h = store.read_number(section, base .. ".size.h", nil)
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
        list[#list + 1] = preset
      end
    end
  end
  return list
end

local function clear_user_styles(section)
  local count = store.read_number(section, "userPresets.style.count", 0)
  for i = 1, math.max(count, 64) do
    local base = string.format("userPresets.style.%d", i)
    if not store.has(section, base .. ".name") and i > count then
      break
    end
    store.delete(section, base .. ".name")
    for _, key in ipairs(presets.scale_value_keys) do
      store.delete(section, string.format("%s.%s", base, key))
    end
    for _, key in ipairs(presets.scale_font_keys) do
      store.delete(section, string.format("%s.fonts.%s", base, key))
    end
    for _, key in ipairs(presets.layout_value_keys) do
      store.delete(section, string.format("%s.layout.%s", base, key))
    end
    for _, key in ipairs(presets.layout_string_keys) do
      store.delete(section, string.format("%s.layout.%s", base, key))
    end
    for _, panel_key in ipairs(presets.layout_panel_keys) do
      local panel_base = string.format("%s.layout.panels.%s", base, panel_key)
      store.delete(section, panel_base .. ".open")
      store.delete(section, panel_base .. ".pos.x")
      store.delete(section, panel_base .. ".pos.y")
      store.delete(section, panel_base .. ".size.w")
      store.delete(section, panel_base .. ".size.h")
    end
  end
  store.delete(section, "userPresets.style.count")
end

function presets.save_user_styles(section, list)
  clear_user_styles(section)
  store.write(section, "userPresets.style.count", #list)
  for i, preset in ipairs(list) do
    store.write(section, string.format("userPresets.style.%d.name", i), preset.name)
    local scale = preset.scale or {}
    for _, key in ipairs(presets.scale_value_keys) do
      if scale[key] ~= nil then
        store.write(section, string.format("userPresets.style.%d.%s", i, key), scale[key])
      end
    end
    local fonts = scale.fonts or {}
    for _, key in ipairs(presets.scale_font_keys) do
      if fonts[key] ~= nil then
        store.write(section, string.format("userPresets.style.%d.fonts.%s", i, key), fonts[key])
      end
    end
    local layout = preset.layout or {}
    for _, key in ipairs(presets.layout_value_keys) do
      if layout[key] ~= nil then
        store.write(section, string.format("userPresets.style.%d.layout.%s", i, key), layout[key])
      end
    end
    for _, key in ipairs(presets.layout_string_keys) do
      if layout[key] ~= nil then
        store.write(section, string.format("userPresets.style.%d.layout.%s", i, key), layout[key])
      end
    end
    local panels = layout.panels or {}
    for _, panel_key in ipairs(presets.layout_panel_keys) do
      local panel = panels[panel_key]
      if panel then
        local panel_base = string.format("userPresets.style.%d.layout.panels.%s", i, panel_key)
        if panel.open ~= nil then
          store.write(section, panel_base .. ".open", panel.open)
        end
        if panel.pos and panel.pos[1] and panel.pos[2] then
          store.write(section, panel_base .. ".pos.x", panel.pos[1])
          store.write(section, panel_base .. ".pos.y", panel.pos[2])
        end
        if panel.size and panel.size[1] and panel.size[2] then
          store.write(section, panel_base .. ".size.w", panel.size[1])
          store.write(section, panel_base .. ".size.h", panel.size[2])
        end
      end
    end
  end
end

-- Remove all user presets and manual overrides (used by config reset).
function presets.clear_all(section)
  clear_user_tunings(section)
  clear_user_colors(section)
  clear_user_styles(section)
  clear_overrides(section)
end

return presets
