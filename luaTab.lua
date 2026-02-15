-- @description luaTab: Tab HUD (Toggle)


local SECTION = "luaTab"
local KEY_RUNNING = "running"
local KEY_QUIT = "quit"

local _, _, section_id, cmd_id = reaper.get_action_context()

local function set_toggle(on)
  if section_id and cmd_id then
    reaper.SetToggleCommandState(section_id, cmd_id, on and 1 or 0)
    reaper.RefreshToolbar2(section_id, cmd_id)
  end
end

if reaper.GetExtState(SECTION, KEY_RUNNING) == "1" then
  reaper.SetExtState(SECTION, KEY_QUIT, "1", false)
  return
end

reaper.SetExtState(SECTION, KEY_RUNNING, "1", false)
reaper.SetExtState(SECTION, KEY_QUIT, "0", false)
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
util.log_init(script_dir, cfg.logEnabled, cfg.logVerbose)
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
}

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
  state.bars = bars
  state.lastBarIdx = current

  if #bars == 0 then
    state.eventsByBar = {}
    state.hasMidiTake = false
    state.statusMessage = "No bars in window"
    util.log_throttle("no_bars", 1.0, "no bars in window", "debug")
    return
  end

  local take, take_source, current_item, next_item = source.get_take(t)
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

  local clip_t0 = nil
  local clip_t1 = nil
  if state.itemBounds and state.itemBounds.current then
    clip_t0 = state.itemBounds.current.t0
    clip_t1 = state.itemBounds.current.t1
  end

  local notes = midi.extract_notes(take, bars[1].t0, bars[#bars].t1, clip_t0, clip_t1)
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

  local ok, visible, open = pcall(reaper.ImGui_Begin, ctx, "luaTab", true, reaper.ImGui_WindowFlags_MenuBar())
  local began = ok and (visible ~= nil)
  if not began then
    reaper.defer(draw_ui)
    return
  end

  if open == nil then
    open = true
  end

  if visible then
    local t = get_cursor_time()
    local current_bar = timeline.get_measure_index(t)
    local take = select(1, source.get_take(t))
    local take_id = take and tostring(take) or nil

    local changed = false
    local rv

    rv, cfg.followPlay = reaper.ImGui_Checkbox(ctx, "Follow play cursor", cfg.followPlay)
    changed = changed or rv
    reaper.ImGui_SameLine(ctx)
    rv, cfg.followEditWhenStopped = reaper.ImGui_Checkbox(ctx, "Follow edit cursor", cfg.followEditWhenStopped)
    changed = changed or rv
    reaper.ImGui_SameLine(ctx)
    rv, cfg.logEnabled = reaper.ImGui_Checkbox(ctx, "Logging", cfg.logEnabled)
    changed = changed or rv
    reaper.ImGui_SameLine(ctx)
    rv, cfg.logVerbose = reaper.ImGui_Checkbox(ctx, "Verbose", cfg.logVerbose)
    changed = changed or rv
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 80)
    rv, cfg.prevBars = reaper.ImGui_InputInt(ctx, "Prev bars", cfg.prevBars)
    changed = changed or rv
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 80)
    rv, cfg.nextBars = reaper.ImGui_InputInt(ctx, "Next bars", cfg.nextBars)
    changed = changed or rv

    local update_modes = { "bar", "step", "screen", "continuous" }
    local update_labels = "Every bar\0Every N bars\0Bars on screen width\0Continuous\0"
    local mode_index = 0
    for i, name in ipairs(update_modes) do
      if name == cfg.updateMode then
        mode_index = i - 1
        break
      end
    end

    reaper.ImGui_SetNextItemWidth(ctx, 180)
    rv, mode_index = reaper.ImGui_Combo(ctx, "Update mode", mode_index, update_labels)
    if rv then
      cfg.updateMode = update_modes[mode_index + 1] or "bar"
      changed = true
    end

    if cfg.updateMode == "step" then
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 60)
      rv, cfg.updateStep = reaper.ImGui_InputInt(ctx, "Step", cfg.updateStep)
      changed = changed or rv
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 80)
    rv, cfg.antidelayBeats = reaper.ImGui_InputInt(ctx, "Antidelay beats", cfg.antidelayBeats)
    changed = changed or rv

    if changed then
      cfg.prevBars = util.clamp(cfg.prevBars, 0, 64)
      cfg.nextBars = util.clamp(cfg.nextBars, 0, 64)
      cfg.updateStep = util.clamp(cfg.updateStep, 1, 64)
      cfg.antidelayBeats = util.clamp(cfg.antidelayBeats, 0, 64)
      config_mod.save(cfg, "luaTab")
      util.log_init(script_dir, cfg.logEnabled, cfg.logVerbose)
      util.log("settings changed", "info")
      rebuild_data(get_cursor_time())
    end

    if state.statusMessage then
      reaper.ImGui_TextWrapped(ctx, state.statusMessage)
    elseif state.lastBarIdx ~= nil then
      reaper.ImGui_Text(ctx, string.format("Bar %d", state.lastBarIdx + 1))
    end

    if cfg.logEnabled then
      reaper.ImGui_Text(ctx, string.format("Log: %s", util.log_path() or "(none)"))
    end

    if state.takeSource then
      reaper.ImGui_Text(ctx, string.format("Source: %s", state.takeSource))
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
    end

    if reaper.ImGui_SetNextFrameWantCaptureKeyboard and reaper.ImGui_IsAnyItemActive then
      local wants_keyboard = reaper.ImGui_IsAnyItemActive(ctx)
      reaper.ImGui_SetNextFrameWantCaptureKeyboard(ctx, wants_keyboard)
    end
  end

  if visible then
    reaper.ImGui_End(ctx)
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
