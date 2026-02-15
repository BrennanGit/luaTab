local util = require("util")
local midi = {}

-- MIDI take discovery moved to lib/source.lua

function midi.extract_notes(take, t0, t1)
  local notes = {}
  local _, note_count = reaper.MIDI_CountEvts(take)
  for i = 0, note_count - 1 do
    local _, _, _, startppq, endppq, _, pitch, vel = reaper.MIDI_GetNote(take, i)
    local start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
    if start_time >= t0 and start_time < t1 then
      local end_time = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)
      notes[#notes + 1] = {
        tStart = start_time,
        tEnd = end_time,
        pitch = pitch,
        vel = vel,
      }
    end
  end

  table.sort(notes, function(a, b)
    if a.tStart == b.tStart then
      return a.pitch > b.pitch
    end
    return a.tStart < b.tStart
  end)

  util.log(string.format("extract_notes count=%d window=%.3f..%.3f", #notes, t0, t1), "debug")
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
