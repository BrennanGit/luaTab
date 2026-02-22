local util = require("util")
local midi = {}

-- MIDI take discovery moved to lib/source.lua

local function append_note(notes, start_time, end_time, pitch, vel, window_start, window_end, clip_t0, clip_t1)
  if start_time < window_start or start_time >= window_end then
    return
  end
  if clip_t0 ~= nil and start_time < clip_t0 then
    return
  end
  if clip_t1 ~= nil and start_time >= clip_t1 then
    return
  end
  notes[#notes + 1] = {
    tStart = start_time,
    tEnd = end_time,
    pitch = pitch,
    vel = vel,
  }
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

  if len_is_qn then
    return src_len, "qn"
  end

  local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  if not playrate or playrate <= 0 then
    playrate = 1
  end
  return src_len / playrate, "sec"
end

function midi.extract_notes(take, t0, t1, clip_t0, clip_t1, item)
  local window_start = t0
  local window_end = t1
  if clip_t0 ~= nil then
    window_start = math.max(window_start, clip_t0)
  end
  if clip_t1 ~= nil then
    window_end = math.min(window_end, clip_t1)
  end
  if window_end <= window_start then
    util.log(string.format("extract_notes empty clip=%.3f..%.3f", window_start, window_end), "debug")
    return {}
  end

  local notes = {}
  local _, note_count = reaper.MIDI_CountEvts(take)
  local loop_period, loop_domain = get_loop_period(take, item)
  local has_loop = loop_period ~= nil and loop_period > 0

  local window_qn_start = nil
  local window_qn_end = nil
  if has_loop and loop_domain == "qn" then
    window_qn_start = reaper.TimeMap2_timeToQN(0, window_start)
    window_qn_end = reaper.TimeMap2_timeToQN(0, window_end)
  end

  for i = 0, note_count - 1 do
    local _, _, _, startppq, endppq, _, pitch, vel = reaper.MIDI_GetNote(take, i)
    local start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
    local end_time = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)

    if has_loop then
      if loop_domain == "qn" then
        local start_qn = reaper.MIDI_GetProjQNFromPPQPos(take, startppq)
        local end_qn = reaper.MIDI_GetProjQNFromPPQPos(take, endppq)
        local k_start = math.floor((window_qn_start - start_qn) / loop_period) - 1
        local k_end = math.floor((window_qn_end - start_qn) / loop_period) + 1
        for k = k_start, k_end do
          local shifted_start_qn = start_qn + (k * loop_period)
          local shifted_end_qn = end_qn + (k * loop_period)
          local shifted_start_time = reaper.TimeMap2_QNToTime(0, shifted_start_qn)
          local shifted_end_time = reaper.TimeMap2_QNToTime(0, shifted_end_qn)
          append_note(notes, shifted_start_time, shifted_end_time, pitch, vel, window_start, window_end, clip_t0, clip_t1)
        end
      else
        local k_start = math.floor((window_start - start_time) / loop_period) - 1
        local k_end = math.floor((window_end - start_time) / loop_period) + 1
        for k = k_start, k_end do
          local shifted_start_time = start_time + (k * loop_period)
          local shifted_end_time = end_time + (k * loop_period)
          append_note(notes, shifted_start_time, shifted_end_time, pitch, vel, window_start, window_end, clip_t0, clip_t1)
        end
      end
    else
      append_note(notes, start_time, end_time, pitch, vel, window_start, window_end, clip_t0, clip_t1)
    end
  end

  table.sort(notes, function(a, b)
    if a.tStart == b.tStart then
      return a.pitch > b.pitch
    end
    return a.tStart < b.tStart
  end)

  util.log(string.format("extract_notes count=%d window=%.3f..%.3f", #notes, window_start, window_end), "debug")
  return notes
end

function midi.group_events(notes, epsilon_sec)
  local events = {}
  local eps = epsilon_sec or 0
  local current = nil

  for _, note in ipairs(notes) do
    if not current or math.abs(note.tStart - current.t) > eps then
      current = { t = note.tStart, notes = {} }
      events[#events + 1] = current
    end
    current.notes[#current.notes + 1] = note
  end

  util.log(string.format("group_events notes=%d events=%d eps=%.4f", #notes, #events, eps), "debug")
  return events
end

return midi
