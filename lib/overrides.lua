local overrides = {}

local function event_time_ms(event)
  return math.floor(((event and event.t) or 0) * 1000 + 0.5)
end

function overrides.make_key(event, pitch)
  return tostring(event_time_ms(event)) .. ":" .. tostring(pitch)
end

local function forced_assignment(entry, pitch, config)
  if not entry or not config or not config.tuning then
    return false
  end
  local string_index = tonumber(entry.string)
  if not string_index then
    return false
  end
  string_index = math.floor(string_index + 0.5)
  local string_info = config.tuning[string_index]
  if not string_info then
    return false
  end
  local fret = pitch - string_info.open
  if fret < 0 or fret > (config.maxFret or fret) then
    return false
  end
  return true, string_index, fret
end

function overrides.apply_event_overrides(event, config, override_map)
  event.forcedStringsByPitch = nil
  if not override_map or not next(override_map) then
    return { forcedStringsByPitch = {}, overridesApplied = {}, overridesSkipped = {} }
  end

  local applied = {}
  local skipped = {}
  local forced = {}

  for _, note in ipairs(event.notes or {}) do
    local key = overrides.make_key(event, note.pitch)
    local entry = override_map[key]
    if entry then
      local ok, string_index = forced_assignment(entry, note.pitch, config)
      if ok then
        forced[note.pitch] = string_index
        applied[#applied + 1] = key
      else
        skipped[#skipped + 1] = { key = key, pitch = note.pitch, reason = "invalid" }
      end
    end
  end

  event.forcedStringsByPitch = forced
  return {
    forcedStringsByPitch = forced,
    overridesApplied = applied,
    overridesSkipped = skipped,
  }
end

return overrides