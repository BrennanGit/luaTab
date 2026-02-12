-- lib/midi.lua
-- MIDI extraction + event grouping

local Midi = {}

function Midi.get_active_take()
  local editor = reaper.MIDIEditor_GetActive()
  if not editor then
    return nil
  end
  local take = reaper.MIDIEditor_GetTake(editor)
  if not take or not reaper.TakeIsMIDI(take) then
    return nil
  end
  return take
end

function Midi.extract_notes(take, t0, t1)
  local notes = {}
  if not take or t0 == nil or t1 == nil then
    return notes
  end

  local noteCount = select(1, reaper.MIDI_CountEvts(take))
  for i = 0, noteCount - 1 do
    local ok, _, _, startppq, endppq, _, pitch, vel = reaper.MIDI_GetNote(take, i)
    if ok then
      local startTime = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
      if startTime >= t0 and startTime < t1 then
        local endTime = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)
        notes[#notes + 1] = {
          tStart = startTime,
          tEnd = endTime,
          pitch = pitch,
          vel = vel,
        }
      end
    end
  end

  table.sort(notes, function(a, b)
    if a.tStart == b.tStart then
      return a.pitch < b.pitch
    end
    return a.tStart < b.tStart
  end)

  return notes
end

function Midi.group_events(notes, epsilonSec)
  local events = {}
  if not notes or #notes == 0 then
    return events
  end

  local eps = epsilonSec or 0.005
  for i = 1, #notes do
    local note = notes[i]
    local last = events[#events]
    if last and math.abs(note.tStart - last.t) <= eps then
      last.notes[#last.notes + 1] = note
    else
      events[#events + 1] = { t = note.tStart, notes = { note } }
    end
  end

  return events
end

return Midi
