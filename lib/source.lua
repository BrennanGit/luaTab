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
        end
      end
    end
  end

  if best_take then
    util.log_throttle("source_track_found", 2.0, "selected track item take found", "debug")
  else
    util.log_throttle("source_track_none", 2.0, "no MIDI item under cursor on selected track", "debug")
  end

  return best_take
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

function source.get_take(t)
  local take = get_selected_track_take_at_time(t)
  if take then
    return take, "selected_track"
  end
  local editor_take = get_active_midi_editor_take()
  if editor_take then
    return editor_take, "midi_editor"
  end
  return nil, "none"
end

return source
