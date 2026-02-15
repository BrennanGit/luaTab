local util = require("util")

local source = {}

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

function source.get_take(t)
  local take, item, track = get_selected_track_take_at_time(t)
  if take then
    local current_info = build_item_info(item)
    local next_item = find_next_midi_item(track, current_info.t1, item)
    local next_info = build_item_info(next_item)
    return take, "selected_track", current_info, next_info
  end

  local next_take, next_item, next_track = get_next_track_take_after_time(t)
  if next_take then
    local current_info = build_item_info(next_item)
    local next_after = find_next_midi_item(next_track, current_info.t1, next_item)
    local next_info = build_item_info(next_after)
    return next_take, "selected_track_next", current_info, next_info
  end

  local editor_take = get_active_midi_editor_take()
  if editor_take then
    local editor_item = reaper.GetMediaItemTake_Item(editor_take)
    local editor_track = editor_item and reaper.GetMediaItem_Track(editor_item) or nil
    local current_info = build_item_info(editor_item)
    local next_info = nil
    if current_info and editor_track then
      local next_item = find_next_midi_item(editor_track, current_info.t1, editor_item)
      next_info = build_item_info(next_item)
    end
    return editor_take, "midi_editor", current_info, next_info
  end

  return nil, "none", nil, nil
end

return source
