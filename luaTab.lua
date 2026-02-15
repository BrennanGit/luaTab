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
local config_mod = require("config")
local timeline = require("timeline")
local layout = require("layout")
local midi = require("midi")
local source = require("source")
local frets = require("frets")
local render = require("render")

local ctx
local cleaned = false

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
local cfg = config_mod.load("luaTab")
if not cfg.logPath or cfg.logPath == "" then
  cfg.logPath = script_dir .. "/luaTab.log"
end
util.log_init(script_dir, cfg.logEnabled, cfg.logVerbose, cfg.logPath)
util.log("luaTab started", "info")

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
  settingsOpen = false,
  lastHeartbeat = 0,
  colorHex = {},
  logPathBuf = nil,
}

local tuning_presets = {
  {
    id = "mandolin",
    label = "Mandolin (GDAE)",
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
    tuning = {
      { name = "E", open = 28 },
      { name = "A", open = 33 },
      { name = "D", open = 38 },
      { name = "G", open = 43 },
    },
  },
  {
    id = "custom",
    label = "Custom",
  },
}

local color_presets = {
  {
    id = "dark",
    label = "Dark",
    colors = {
      background = { 0.08, 0.08, 0.08, 1.0 },
      text = { 1.0, 1.0, 1.0, 1.0 },
      strings = { 0.7, 0.7, 0.7, 1.0 },
      barlines = { 0.4, 0.4, 0.4, 1.0 },
      itemBoundary = { 0.7, 0.7, 0.7, 1.0 },
      dropped = { 1.0, 0.25, 0.25, 1.0 },
      marker = { 1.0, 0.2, 0.2, 0.18 },
      noteBg = { 0.05, 0.05, 0.05, 0.85 },
    },
  },
  {
    id = "light",
    label = "Light",
    colors = {
      background = { 0.96, 0.96, 0.96, 1.0 },
      text = { 0.08, 0.08, 0.08, 1.0 },
      strings = { 0.35, 0.35, 0.35, 1.0 },
      barlines = { 0.2, 0.2, 0.2, 1.0 },
      itemBoundary = { 0.2, 0.2, 0.2, 1.0 },
      dropped = { 0.75, 0.1, 0.1, 1.0 },
      marker = { 0.2, 0.4, 0.9, 0.18 },
      noteBg = { 1.0, 1.0, 1.0, 0.85 },
    },
  },
}

local function preset_index_for_id(preset_id)
  for i, preset in ipairs(tuning_presets) do
    if preset.id == preset_id then
      return i
    end
  end
  return #tuning_presets
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
  for i, preset in ipairs(color_presets) do
    if preset.id == preset_id then
      return i
    end
  end
  return 1
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

local function draw_color_swatch(ctx, color, size)
  if not color or not reaper.ImGui_GetCursorScreenPos or not reaper.ImGui_GetWindowDrawList then
    return
  end
  local x, y = reaper.ImGui_GetCursorScreenPos(ctx)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local col = util.color_u32(color[1], color[2], color[3], color[4])
  local border = util.color_u32(0, 0, 0, 0.6)
  reaper.ImGui_DrawList_AddRectFilled(draw_list, x, y, x + size, y + size, col)
  reaper.ImGui_DrawList_AddRect(draw_list, x, y, x + size, y + size, border)
  reaper.ImGui_Dummy(ctx, size, size)
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

local function should_quit()
  return reaper.GetExtState(SECTION, KEY_QUIT) == "1"
end

local function draw_ui()
  if should_quit() then
    cleanup()
    return
  end
  if not state.windowInitialized then
    reaper.ImGui_SetNextWindowSize(ctx, 900, 360, reaper.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowPos(ctx, 100, 100, reaper.ImGui_Cond_FirstUseEver())
    state.windowInitialized = true
  end

  reaper.ImGui_SetNextWindowSizeConstraints(ctx, 640, 240, 4096, 4096)

  local pushed_bg = false
  if cfg.colors and cfg.colors.background and reaper.ImGui_PushStyleColor and reaper.ImGui_Col_WindowBg then
    local bg_col = util.color_u32(cfg.colors.background[1], cfg.colors.background[2], cfg.colors.background[3], cfg.colors.background[4])
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), bg_col)
    pushed_bg = true
  end

  local ok, visible, open = pcall(reaper.ImGui_Begin, ctx, "luaTab", true, reaper.ImGui_WindowFlags_MenuBar())
  local began = ok and (visible ~= nil)
  if not began then
    if pushed_bg and reaper.ImGui_PopStyleColor then
      reaper.ImGui_PopStyleColor(ctx)
    end
    reaper.defer(draw_ui)
    return
  end

  if open == nil then
    open = true
  end

  if visible then
    local now = now_time()
    if now - state.lastHeartbeat >= 1.0 then
      reaper.SetExtState(SECTION, KEY_HEARTBEAT, tostring(now), false)
      state.lastHeartbeat = now
    end

    local t = get_cursor_time()
    local current_bar = timeline.get_measure_index(t)
    local take = select(1, source.get_take(t))
    local take_id = take and tostring(take) or nil

    if reaper.ImGui_BeginMenuBar(ctx) then
      if reaper.ImGui_MenuItem(ctx, "Settings") then
        state.settingsOpen = true
      end
      reaper.ImGui_EndMenuBar(ctx)
    end

    if state.settingsOpen then
      reaper.ImGui_OpenPopup(ctx, "Settings")
      state.settingsOpen = false
    end

    reaper.ImGui_SetNextWindowSize(ctx, 560, 520, reaper.ImGui_Cond_Appearing())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, 480, 420, 1200, 1000)
    local settings_visible = reaper.ImGui_BeginPopupModal(ctx, "Settings", true, 0)
    if settings_visible then
      local settings_changed = false
      local rv

      if reaper.ImGui_CollapsingHeader(ctx, "Tuning", reaper.ImGui_TreeNodeFlags_DefaultOpen()) then
        local preset_labels = "Mandolin (GDAE)\0Guitar (EADGBe)\0Bass (EADG)\0Custom\0"
        local preset_index = preset_index_for_id(cfg.tuningPreset or "custom") - 1
        reaper.ImGui_SetNextItemWidth(ctx, 220)
        rv, preset_index = reaper.ImGui_Combo(ctx, "Preset", preset_index, preset_labels)
        if rv then
          local preset = tuning_presets[preset_index + 1]
          if preset and preset.id == "custom" then
            cfg.tuningPreset = "custom"
            settings_changed = true
          elseif apply_tuning_preset(cfg, preset) then
            settings_changed = true
          end
        end

        local tuning_changed = false
        for i, string_info in ipairs(cfg.tuning) do
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

      if reaper.ImGui_CollapsingHeader(ctx, "Styling", reaper.ImGui_TreeNodeFlags_DefaultOpen()) then
        local preset_labels = "Dark\0Light\0"
        local preset_index = color_preset_index(cfg.colorPreset or "dark") - 1
        reaper.ImGui_SetNextItemWidth(ctx, 160)
        rv, preset_index = reaper.ImGui_Combo(ctx, "Color preset", preset_index, preset_labels)
        if rv then
          local preset = color_presets[preset_index + 1]
          if apply_color_preset(cfg, preset) then
            settings_changed = true
          end
        end

        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.systemGutterPx = edit_int(ctx, "System gutter", cfg.systemGutterPx, 0, 300)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.barPrefixPx = edit_int(ctx, "Bar prefix", cfg.barPrefixPx, 0, 300)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.barContentPx = edit_int(ctx, "Bar content", cfg.barContentPx, 10, 600)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.barGutterPx = edit_int(ctx, "Bar gutter", cfg.barGutterPx, 0, 120)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.systemRowGapPx = edit_int(ctx, "Row gap", cfg.systemRowGapPx, 0, 120)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.staffPaddingTopPx = edit_int(ctx, "Staff pad top", cfg.staffPaddingTopPx, 0, 80)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.staffPaddingBottomPx = edit_int(ctx, "Staff pad bottom", cfg.staffPaddingBottomPx, 0, 80)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.stringSpacingPx = edit_int(ctx, "String spacing", cfg.stringSpacingPx, 6, 40)
        settings_changed = settings_changed or rv

        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.barLineThickness = edit_float(ctx, "Barline thickness", cfg.barLineThickness, 0.5, 6)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.itemBoundaryThickness = edit_float(ctx, "Item boundary thickness", cfg.itemBoundaryThickness, 0.5, 6)
        settings_changed = settings_changed or rv

        rv, cfg.showFirstTimeSigInSystemGutter = reaper.ImGui_Checkbox(ctx, "Time signature in gutter", cfg.showFirstTimeSigInSystemGutter)
        settings_changed = settings_changed or rv

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Fonts")
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.fonts.fretScale = edit_float(ctx, "Fret scale", cfg.fonts.fretScale, 0.6, 2.5)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.fonts.timeSigScale = edit_float(ctx, "Time sig scale", cfg.fonts.timeSigScale, 0.6, 3.0)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 140)
        rv, cfg.fonts.droppedScale = edit_float(ctx, "Dropped scale", cfg.fonts.droppedScale, 0.5, 2.0)
        settings_changed = settings_changed or rv

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Colors (hex)")
        draw_color_swatch(ctx, cfg.colors.background, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Background", "background", cfg.colors.background, true) or settings_changed

        draw_color_swatch(ctx, cfg.colors.text, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Text (frets + labels)", "text", cfg.colors.text, true) or settings_changed

        draw_color_swatch(ctx, cfg.colors.strings, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Strings (staff lines)", "strings", cfg.colors.strings, true) or settings_changed

        draw_color_swatch(ctx, cfg.colors.barlines, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Barlines", "barlines", cfg.colors.barlines, true) or settings_changed

        draw_color_swatch(ctx, cfg.colors.itemBoundary, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Item boundaries", "itemBoundary", cfg.colors.itemBoundary, true) or settings_changed

        draw_color_swatch(ctx, cfg.colors.dropped, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Dropped notes", "dropped", cfg.colors.dropped, true) or settings_changed

        draw_color_swatch(ctx, cfg.colors.marker, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Current bar highlight", "marker", cfg.colors.marker, true) or settings_changed

        draw_color_swatch(ctx, cfg.colors.noteBg, 14)
        reaper.ImGui_SameLine(ctx)
        settings_changed = edit_color_hex(ctx, "Fret background", "noteBg", cfg.colors.noteBg, true) or settings_changed
      end

      if reaper.ImGui_CollapsingHeader(ctx, "Playback", reaper.ImGui_TreeNodeFlags_DefaultOpen()) then
        reaper.ImGui_SetNextItemWidth(ctx, 120)
        rv, cfg.prevBars = edit_int(ctx, "Prev bars", cfg.prevBars, 0, 64)
        settings_changed = settings_changed or rv
        reaper.ImGui_SetNextItemWidth(ctx, 120)
        rv, cfg.nextBars = edit_int(ctx, "Next bars", cfg.nextBars, 0, 64)
        settings_changed = settings_changed or rv

        rv, cfg.followPlay = reaper.ImGui_Checkbox(ctx, "Follow play cursor", cfg.followPlay)
        settings_changed = settings_changed or rv
        rv, cfg.followEditWhenStopped = reaper.ImGui_Checkbox(ctx, "Follow edit cursor", cfg.followEditWhenStopped)
        settings_changed = settings_changed or rv

        local update_modes = { "bar", "step", "screen", "continuous" }
        local update_labels = "Every bar\0Every N bars\0Bars on screen width\0Continuous\0"
        local mode_index = 0
        for i, name in ipairs(update_modes) do
          if name == cfg.updateMode then
            mode_index = i - 1
            break
          end
        end

        reaper.ImGui_SetNextItemWidth(ctx, 200)
        rv, mode_index = reaper.ImGui_Combo(ctx, "Update mode", mode_index, update_labels)
        if rv then
          cfg.updateMode = update_modes[mode_index + 1] or "bar"
          settings_changed = true
        end

        if cfg.updateMode == "step" then
          reaper.ImGui_SetNextItemWidth(ctx, 120)
          rv, cfg.updateStep = edit_int(ctx, "Step", cfg.updateStep, 1, 64)
          settings_changed = settings_changed or rv
        end

        reaper.ImGui_SetNextItemWidth(ctx, 120)
        rv, cfg.antidelayBeats = edit_int(ctx, "Antidelay beats", cfg.antidelayBeats, 0, 64)
        settings_changed = settings_changed or rv
      end

      if reaper.ImGui_CollapsingHeader(ctx, "General", reaper.ImGui_TreeNodeFlags_DefaultOpen()) then
        reaper.ImGui_SetNextItemWidth(ctx, 160)
        rv, cfg.groupEpsilonMs = edit_float(ctx, "Group epsilon (ms)", cfg.groupEpsilonMs, 0, 100)
        settings_changed = settings_changed or rv

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
      end

      if settings_changed then
        clamp_config(cfg)
        config_mod.save(cfg, "luaTab")
        util.log_init(script_dir, cfg.logEnabled, cfg.logVerbose, cfg.logPath)
        util.log("settings changed", "info")
        rebuild_data(get_cursor_time())
      end

      if reaper.ImGui_Button(ctx, "Close") then
        reaper.ImGui_CloseCurrentPopup(ctx)
      end

      reaper.ImGui_EndPopup(ctx)
    end

    if state.statusMessage then
      reaper.ImGui_TextWrapped(ctx, state.statusMessage)
    elseif state.lastBarIdx ~= nil then
      reaper.ImGui_Text(ctx, string.format("Bar %d", state.lastBarIdx + 1))
    end

    reaper.ImGui_Separator(ctx)

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
        window_focused = reaper.ImGui_IsWindowFocused(ctx, reaper.ImGui_FocusedFlags_RootAndChildWindows())
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
  end

  if visible then
    reaper.ImGui_End(ctx)
  end
  if pushed_bg and reaper.ImGui_PopStyleColor then
    reaper.ImGui_PopStyleColor(ctx)
  end

  if open then
    reaper.defer(draw_ui)
  else
    util.log("luaTab closed", "info")
    cleanup()
  end
end

rebuild_data(get_cursor_time())
reaper.defer(draw_ui)
