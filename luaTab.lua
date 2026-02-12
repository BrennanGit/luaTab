-- luaTab.lua
-- MVP main loop

local basePath = reaper.GetResourcePath() .. "/Scripts/luaTab"
local Util = dofile(basePath .. "/lib/util.lua")
local Style = dofile(basePath .. "/lib/style.lua")
local Config = dofile(basePath .. "/lib/config.lua")
local Timeline = dofile(basePath .. "/lib/timeline.lua")
local Layout = dofile(basePath .. "/lib/layout.lua")
local Midi = dofile(basePath .. "/lib/midi.lua")
local Frets = dofile(basePath .. "/lib/frets.lua")
local Render = dofile(basePath .. "/lib/render.lua")

if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox(
    "ReaImGui is not available.\n\nInstall/enable ReaImGui (via ReaPack or REAPER package manager) and restart REAPER.",
    "luaTab",
    0
  )
  return
end

local ctx = reaper.ImGui_CreateContext("luaTab")
local col = Style.BuildColors(ctx)
local cfg = Config.load()

local cache = {
  take = nil,
  barIndex = nil,
  rangeStart = nil,
  rangeEnd = nil,
  eventsByBar = {},
}

local function build_events_by_bar(take, bars, epsilonSec)
  local eventsByBar = {}
  if not take or #bars == 0 then
    return eventsByBar
  end

  local rangeStart = bars[1].t0
  local rangeEnd = bars[#bars].t1
  local notes = Midi.extract_notes(take, rangeStart, rangeEnd)
  local events = Midi.group_events(notes, epsilonSec)

  local barIdx = 1
  for _, event in ipairs(events) do
    while barIdx <= #bars and event.t >= bars[barIdx].t1 do
      barIdx = barIdx + 1
    end
    local bar = bars[barIdx]
    if bar and event.t >= bar.t0 and event.t < bar.t1 then
      eventsByBar[bar.idx] = eventsByBar[bar.idx] or {}
      eventsByBar[bar.idx][#eventsByBar[bar.idx] + 1] = event
    end
  end

  return eventsByBar, rangeStart, rangeEnd
end

local function get_cached_events(take, bars, currentBarIdx, epsilonSec)
  local rangeStart = bars[1] and bars[1].t0 or nil
  local rangeEnd = bars[#bars] and bars[#bars].t1 or nil
  if cache.take == take
    and cache.barIndex == currentBarIdx
    and cache.rangeStart == rangeStart
    and cache.rangeEnd == rangeEnd then
    return cache.eventsByBar
  end

  local eventsByBar, newStart, newEnd = build_events_by_bar(take, bars, epsilonSec)
  cache.take = take
  cache.barIndex = currentBarIdx
  cache.rangeStart = newStart
  cache.rangeEnd = newEnd
  cache.eventsByBar = eventsByBar
  return eventsByBar
end

local function loop()
  local visible, open = reaper.ImGui_Begin(ctx, "luaTab", true)
  if visible then
    local changed
    changed, cfg.followPlay = reaper.ImGui_Checkbox(ctx, "Follow play cursor", cfg.followPlay)
    if changed then Config.save(cfg) end

    changed, cfg.followEditWhenStopped = reaper.ImGui_Checkbox(ctx, "When stopped, follow edit cursor", cfg.followEditWhenStopped)
    if changed then Config.save(cfg) end

    changed, cfg.prevBars = reaper.ImGui_SliderInt(ctx, "Prev bars", cfg.prevBars, 0, 16)
    if changed then Config.save(cfg) end

    changed, cfg.nextBars = reaper.ImGui_SliderInt(ctx, "Next bars", cfg.nextBars, 0, 16)
    if changed then Config.save(cfg) end

    reaper.ImGui_Separator(ctx)

    local t = Timeline.get_cursor_time(cfg)
    local bars, currentBarIdx = Timeline.build_bars(t, cfg.prevBars, cfg.nextBars, cfg.showFirstTimeSigInSystemGutter)
    reaper.ImGui_Text(ctx, string.format("Cursor: %.3f s", t))
    if currentBarIdx then
      reaper.ImGui_Text(ctx, string.format("Bar index: %d", currentBarIdx + 1))
    end

    reaper.ImGui_Separator(ctx)

    local contentW, _ = reaper.ImGui_GetContentRegionAvail(ctx)
    local startX, startY = reaper.ImGui_GetCursorScreenPos(ctx)

    local systems = Layout.compute_systems(bars, startX, startY, contentW, #cfg.tuning, Style)
    local drawList = reaper.ImGui_GetWindowDrawList(ctx)

    local take = Midi.get_active_take()
    if not take then
      reaper.ImGui_Text(ctx, "No active MIDI editor take.")
    end

    local eventsByBar = {}
    if take and #bars > 0 then
      local epsSec = (cfg.groupEpsilonMs or 5.0) / 1000.0
      eventsByBar = get_cached_events(take, bars, currentBarIdx, epsSec)

      local context = { lastFretForString = {}, lastStringForTop = nil }
      for _, bar in ipairs(bars) do
        local events = eventsByBar[bar.idx]
        if events then
          for _, event in ipairs(events) do
            local assigned, dropped = Frets.solve_event(event, cfg, context)
            event.assigned = assigned
            event.dropped = dropped
          end
        end
      end
    end

    Render.draw_systems(drawList, systems, eventsByBar, cfg, Style, col)

    reaper.ImGui_End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

loop()
