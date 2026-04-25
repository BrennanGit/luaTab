local frets = {}

local function build_candidates(pitch, tuning, max_fret, forced_string)
  local candidates = {}
  for s = 1, #tuning do
    if not forced_string or forced_string == s then
      local open = tuning[s].open
      if pitch >= open then
        local fret = pitch - open
        if fret <= max_fret then
          candidates[#candidates + 1] = { string = s, fret = fret }
        end
      end
    end
  end

  table.sort(candidates, function(a, b)
    if a.fret == b.fret then
      return a.string < b.string
    end
    return a.fret < b.fret
  end)

  return candidates
end

local function fretted_span(assignments)
  local min_fret = nil
  local max_fret = nil
  for _, a in ipairs(assignments) do
    if a.fret > 0 then
      min_fret = min_fret and math.min(min_fret, a.fret) or a.fret
      max_fret = max_fret and math.max(max_fret, a.fret) or a.fret
    end
  end
  if not min_fret then return 0 end
  return max_fret - min_fret
end

local function score_assignment(assignments, weights, state)
  local low_fret = 0
  local high_fret = 0
  local fret_jump = 0

  for _, a in ipairs(assignments) do
    low_fret = low_fret + a.fret
    if a.fret > 7 then
      high_fret = high_fret + (a.fret - 7)
    end
    if state.lastFretForString[a.string] then
      fret_jump = fret_jump + math.abs(a.fret - state.lastFretForString[a.string])
    end
  end

  local string_jump = 0
  local stay_on_string = 0
  if state.lastTopString and assignments[1] then
    string_jump = math.abs(assignments[1].string - state.lastTopString)
    if assignments[1].string == state.lastTopString then
      stay_on_string = 1
    end
  end

  local cost = 0
  cost = cost + low_fret * weights.lowFret
  cost = cost + high_fret * weights.highFret
  cost = cost + fret_jump * weights.fretJump
  cost = cost + string_jump * weights.stringJump
  cost = cost - stay_on_string * weights.stayOnString

  return cost
end

local function dfs_assign(pitches, candidates, idx, used_strings, current, best, config, state)
  if idx > #pitches then
    local span = fretted_span(current)
    if span > config.maxFrettedSpan then
      return best
    end

    local cost = score_assignment(current, config.weights, state)
    if not best or cost < best.cost then
      best = { cost = cost, assignments = {} }
      for _, a in ipairs(current) do
        best.assignments[#best.assignments + 1] = { string = a.string, fret = a.fret, pitch = a.pitch }
      end
    end
    return best
  end

  for _, cand in ipairs(candidates[idx]) do
    if not used_strings[cand.string] then
      current[#current + 1] = { string = cand.string, fret = cand.fret, pitch = pitches[idx] }
      used_strings[cand.string] = true

      local span = fretted_span(current)
      if span <= config.maxFrettedSpan then
        best = dfs_assign(pitches, candidates, idx + 1, used_strings, current, best, config, state)
      end

      used_strings[cand.string] = nil
      current[#current] = nil
    end
  end

  return best
end

local function solve_assignment(pitches, config, state, forced_strings_by_pitch)
  local candidates = {}
  for i, pitch in ipairs(pitches) do
    local forced_string = forced_strings_by_pitch and forced_strings_by_pitch[pitch] or nil
    candidates[i] = build_candidates(pitch, config.tuning, config.maxFret, forced_string)
    if #candidates[i] == 0 then
      return nil
    end
  end

  local best = dfs_assign(pitches, candidates, 1, {}, {}, nil, config, state)
  return best
end

local function generate_subsets(pitches, size)
  local results = {}
  local current = {}

  local function rec(start, needed)
    if needed == 0 then
      local subset = {}
      for i = 1, #current do
        subset[#subset + 1] = current[i]
      end
      results[#results + 1] = subset
      return
    end

    for i = start, #pitches - needed + 1 do
      current[#current + 1] = pitches[i]
      rec(i + 1, needed - 1)
      current[#current] = nil
    end
  end

  rec(1, size)
  return results
end

local function subset_contains_forced_pitches(subset, forced_strings_by_pitch)
  if not forced_strings_by_pitch then
    return true
  end

  local keep = {}
  for _, pitch in ipairs(subset) do
    keep[pitch] = true
  end

  for pitch in pairs(forced_strings_by_pitch) do
    if not keep[pitch] then
      return false
    end
  end

  return true
end

function frets.assign_event(event, config, state)
  local pitches = {}
  for _, note in ipairs(event.notes) do
    pitches[#pitches + 1] = note.pitch
  end
  table.sort(pitches, function(a, b) return a > b end)

  if #pitches == 0 then
    return { assignments = {}, dropped = {}, cost = 0 }
  end

  local best = nil
  local forced_strings_by_pitch = event.forcedStringsByPitch
  if #pitches <= config.maxSimul then
    best = solve_assignment(pitches, config, state, forced_strings_by_pitch)
  end

  if not best then
    for size = math.min(#pitches - 1, config.maxSimul), 1, -1 do
      local subsets = generate_subsets(pitches, size)
      local chosen = nil

      for _, subset in ipairs(subsets) do
        local candidate = nil
        if subset_contains_forced_pitches(subset, forced_strings_by_pitch) then
          candidate = solve_assignment(subset, config, state, forced_strings_by_pitch)
        end
        if candidate then
          local top_pitch = subset[1]
          local sum_pitch = 0
          for _, p in ipairs(subset) do sum_pitch = sum_pitch + p end

          if not chosen then
            chosen = { subset = subset, result = candidate, top = top_pitch, sum = sum_pitch }
          else
            local better = false
            if top_pitch > chosen.top then
              better = true
            elseif top_pitch == chosen.top and sum_pitch > chosen.sum then
              better = true
            elseif top_pitch == chosen.top and sum_pitch == chosen.sum and candidate.cost < chosen.result.cost then
              better = true
            end

            if better then
              chosen = { subset = subset, result = candidate, top = top_pitch, sum = sum_pitch }
            end
          end
        end
      end

      if chosen then
        best = chosen.result
        local dropped = {}
        local keep = {}
        for _, p in ipairs(chosen.subset) do keep[p] = true end
        for _, p in ipairs(pitches) do
          if not keep[p] then
            dropped[#dropped + 1] = p
          end
        end
        return { assignments = best.assignments, dropped = dropped, cost = best.cost }
      end
    end
  end

  if not best then
    return { assignments = {}, dropped = pitches, cost = 0 }
  end

  return { assignments = best.assignments, dropped = {}, cost = best.cost }
end

function frets.advance_state(assignments, state)
  if assignments[1] then
    state.lastTopString = assignments[1].string
  end
  for _, a in ipairs(assignments) do
    state.lastFretForString[a.string] = a.fret
  end
end

function frets.new_state(string_count)
  return {
    lastTopString = nil,
    lastFretForString = {},
  }
end

return frets
