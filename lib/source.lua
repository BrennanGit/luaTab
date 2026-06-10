local util = require("util")

local source = {}

local function add_repeat_boundary(boundaries, t, min_t, max_t)
  if not t then
    return
  end
  local eps = 1e-6
  if t <= (min_t + eps) or t >= (max_t - eps) then
    return
  end
  for _, existing in ipairs(boundaries) do
    if math.abs(existing - t) < eps then
      return
    end
  end
  boundaries[#boundaries + 1] = t
end

local function get_loop_period(take, item)
  if not take or not item then
    return nil, nil
  end
  if reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") ~= 1 then
    return nil, nil
  end

  local src = reaper.GetMediaItemTake_Source(take)
  if not src then
    return nil, nil
  end

  local src_len, len_is_qn = reaper.GetMediaSourceLength(src)
  if not src_len or src_len <= 0 then
    return nil, nil
  end

  local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  if not playrate or playrate <= 0 then
    playrate = 1
  end

  if len_is_qn then
    return src_len / playrate, "qn"
  end
  return src_len / playrate, "sec"
end

local function get_item_repeat_boundaries(item, take, t0, t1)
  local boundaries = {}
  if not item or not take then
    return boundaries
  end

  local item_t0 = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_t1 = item_t0 + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local min_t = math.max(t0 or item_t0, item_t0)
  local max_t = math.min(t1 or item_t1, item_t1)
  if max_t <= min_t then
    return boundaries
  end

  local loop_period, loop_domain = get_loop_period(take, item)
  if not loop_period or loop_period <= 1e-9 then
    return boundaries
  end

  local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  if not playrate or playrate <= 0 then
    playrate = 1
  end
  local startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") or 0

  if loop_domain == "qn" then
    local item_qn0 = reaper.TimeMap2_timeToQN(0, item_t0)
    local min_qn = reaper.TimeMap2_timeToQN(0, min_t)
    local max_qn = reaper.TimeMap2_timeToQN(0, max_t)
    local src = reaper.GetMediaItemTake_Source(take)
    local src_len = src and select(1, reaper.GetMediaSourceLength(src)) or nil
    if not src_len or src_len <= 0 then
      return boundaries
    end

    local phase = startoffs % src_len
    local rel_src_min = ((min_qn - item_qn0) * playrate) + phase
    local rel_src_max = ((max_qn - item_qn0) * playrate) + phase
    local n_start = math.floor(rel_src_min / src_len) + 1
    local n_end = math.floor(rel_src_max / src_len)

    for n = n_start, n_end do
      local seam_qn = item_qn0 + ((n * src_len - phase) / playrate)
      local seam_t = reaper.TimeMap2_QNToTime(0, seam_qn)
      add_repeat_boundary(boundaries, seam_t, min_t, max_t)
    end
  else
    local src = reaper.GetMediaItemTake_Source(take)
    local src_len = src and select(1, reaper.GetMediaSourceLength(src)) or nil
    if not src_len or src_len <= 0 then
      return boundaries
    end

    local phase = startoffs % src_len
    local rel_src_min = ((min_t - item_t0) * playrate) + phase
    local rel_src_max = ((max_t - item_t0) * playrate) + phase
    local n_start = math.floor(rel_src_min / src_len) + 1
    local n_end = math.floor(rel_src_max / src_len)

    for n = n_start, n_end do
      local seam_t = item_t0 + ((n * src_len - phase) / playrate)
      add_repeat_boundary(boundaries, seam_t, min_t, max_t)
    end
  end

  table.sort(boundaries, function(a, b)
    return a < b
  end)
  return boundaries
end

local function get_selected_track_take_at_time(t)
  local track = reaper.GetSelectedTrack(0, 0)
  if not track then
    util.log_throttle("source_no_track", 2.0, "no selected track", "debug")
    return nil
  end

  local best_take = nil
  local best_pos = nil
  local best_item = nil
  local item_count = reaper.CountTrackMediaItems(track)
  for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local muted = reaper.GetMediaItemInfo_Value(item, "B_MUTE")

    if muted == 0 and t >= pos and t < (pos + len) then
      local take = reaper.GetActiveTake(item)
      if take and reaper.TakeIsMIDI(take) then
        if not best_pos or pos > best_pos then
          best_pos = pos
          best_take = take
          best_item = item
        end
      end
    end
  end

  if best_take then
    util.log_throttle("source_track_found", 2.0, "selected track item take found", "debug")
  else
    util.log_throttle("source_track_none", 2.0, "no MIDI item under cursor on selected track", "debug")
  end

  return best_take, best_item, track
end

local function get_active_midi_editor_take()
  local editor = reaper.MIDIEditor_GetActive()
  if not editor then
    util.log_throttle("midi_editor_nil", 2.0, "MIDIEditor_GetActive returned nil", "debug")
    return nil
  end
  local take = reaper.MIDIEditor_GetTake(editor)
  if not take or not reaper.TakeIsMIDI(take) then
    util.log_throttle("midi_take_nil", 2.0, "MIDIEditor_GetTake returned nil or non-MIDI", "debug")
    return nil
  end
  util.log_throttle("midi_take_found", 2.0, "MIDI editor take found", "debug")
  return take
end

local function find_next_midi_item(track, after_time, current_item)
  if not track then
    return nil
  end

  local next_item = nil
  local next_pos = nil
  local item_count = reaper.CountTrackMediaItems(track)
  for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    if item ~= current_item then
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local muted = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
      if muted == 0 and pos >= after_time then
        local take = reaper.GetActiveTake(item)
        if take and reaper.TakeIsMIDI(take) then
          if not next_pos or pos < next_pos then
            next_pos = pos
            next_item = item
          end
        end
      end
    end
  end

  return next_item
end

local function build_item_info(item)
  if not item then
    return nil
  end
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  return {
    item = item,
    t0 = pos,
    t1 = pos + len,
  }
end

local function collect_midi_items_in_window(track, t0, t1)
  if not track then
    return {}
  end
  local items = {}
  local item_count = reaper.CountTrackMediaItems(track)
  for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local muted = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
    local item_end = pos + len
    if muted == 0 and pos < t1 and item_end > t0 then
      local take = reaper.GetActiveTake(item)
      if take and reaper.TakeIsMIDI(take) then
        local repeat_boundaries = get_item_repeat_boundaries(item, take, t0, t1)
        items[#items + 1] = {
          item = item,
          take = take,
          t0 = pos,
          t1 = item_end,
          repeatBoundaries = repeat_boundaries,
        }
      end
    end
  end
  table.sort(items, function(a, b)
    return a.t0 < b.t0
  end)
  return items
end

local function get_next_track_take_after_time(t)
  local track = reaper.GetSelectedTrack(0, 0)
  if not track then
    return nil
  end
  local next_item = find_next_midi_item(track, t, nil)
  if not next_item then
    return nil
  end
  local take = reaper.GetActiveTake(next_item)
  if take and reaper.TakeIsMIDI(take) then
    return take, next_item, track
  end
  return nil
end

local function get_selected_track_source(t)
  local take, item, track = get_selected_track_take_at_time(t)
  if take then
    local current_info = build_item_info(item)
    local next_item = find_next_midi_item(track, t, item)
    local next_info = build_item_info(next_item)
    return take, "selected_track", current_info, next_info, track
  end

  local next_take, next_item, next_track = get_next_track_take_after_time(t)
  if next_take then
    local current_info = build_item_info(next_item)
    local next_after = find_next_midi_item(next_track, current_info.t1, next_item)
    local next_info = build_item_info(next_after)
    return next_take, "selected_track_next", current_info, next_info, next_track
  end

  return nil, "none", nil, nil, nil
end

local function get_editor_source(t)
  local editor_take = get_active_midi_editor_take()
  if editor_take then
    local editor_item = reaper.GetMediaItemTake_Item(editor_take)
    local editor_track = editor_item and reaper.GetMediaItem_Track(editor_item) or nil
    local current_info = build_item_info(editor_item)
    local next_info = nil
    if current_info and editor_track then
      local next_item = find_next_midi_item(editor_track, t, editor_item)
      next_info = build_item_info(next_item)
    end
    return editor_take, "midi_editor", current_info, next_info, editor_track
  end

  return nil, "none", nil, nil, nil
end

function source.get_take(t, source_mode)
  local mode = source_mode or "auto"
  if mode == "selected_track" then
    return get_selected_track_source(t)
  end
  if mode == "midi_editor" then
    return get_editor_source(t)
  end

  local take, take_source, current_info, next_info, track = get_selected_track_source(t)
  if take then
    return take, take_source, current_info, next_info, track
  end
  return get_editor_source(t)
end

function source.get_items_in_window(track, t0, t1)
  return collect_midi_items_in_window(track, t0, t1)
end

function source.get_item_repeat_boundaries(item, take, t0, t1)
  return get_item_repeat_boundaries(item, take, t0, t1)
end

return source
