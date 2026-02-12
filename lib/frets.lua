-- lib/frets.lua
-- Candidate generation + solver + reduction

local Frets = {}

function Frets.build_candidates(pitch, tuning, maxFret)
  local out = {}
  for s = 1, #tuning do
    local open = tuning[s].open
    local fret = pitch - open
    if fret >= 0 and fret <= maxFret then
      out[#out + 1] = { stringIndex = s, fret = fret, pitch = pitch }
    end
  end
  return out
end

local function update_span(minF, maxF, fret)
  if fret <= 0 then
    return minF, maxF
  end
  if not minF or fret < minF then
    minF = fret
  end
  if not maxF or fret > maxF then
    maxF = fret
  end
  return minF, maxF
end

local function span_value(minF, maxF)
  if not minF then
    return 0
  end
  return maxF - minF
end

function Frets.score_assignment(assign, config, context, topString)
  local weights = config.weights or {}
  local cost = 0

  for _, a in ipairs(assign) do
    cost = cost + (weights.lowFret or 0) * a.fret
    cost = cost + (weights.highFret or 0) * math.max(0, a.fret - 7)
    if context and context.lastFretForString and context.lastFretForString[a.stringIndex] then
      cost = cost + (weights.fretJump or 0) * math.abs(a.fret - context.lastFretForString[a.stringIndex])
    end
  end

  if context and context.lastStringForTop and topString then
    local jump = math.abs(topString - context.lastStringForTop)
    if jump > 0 then
      cost = cost + (weights.stayOnString or 0)
    end
    cost = cost + (weights.stringJump or 0) * jump
  end

  return cost
end

local function solve_chord(pitches, config, context)
  local tuning = config.tuning
  local maxFret = config.maxFret
  local maxSpan = config.maxFrettedSpan
  local maxSimul = config.maxSimul or #tuning

  if #pitches > maxSimul then
    return nil
  end

  local candidates = {}
  for i = 1, #pitches do
    candidates[i] = Frets.build_candidates(pitches[i], tuning, maxFret)
    if #candidates[i] == 0 then
      return nil
    end
  end

  local bestCost = math.huge
  local bestAssign = nil
  local bestTopString = nil
  local usedStrings = {}

  local function dfs(i, assign, minF, maxF, topString)
    if i > #pitches then
      local cost = Frets.score_assignment(assign, config, context, topString)
      if cost < bestCost then
        bestCost = cost
        bestAssign = assign
        bestTopString = topString
      end
      return
    end

    for _, cand in ipairs(candidates[i]) do
      if not usedStrings[cand.stringIndex] then
        local newMin, newMax = update_span(minF, maxF, cand.fret)
        if span_value(newMin, newMax) <= maxSpan then
          usedStrings[cand.stringIndex] = true
          local newAssign = { table.unpack(assign) }
          newAssign[#newAssign + 1] = {
            pitch = pitches[i],
            stringIndex = cand.stringIndex,
            fret = cand.fret,
          }
          local newTopString = topString
          if i == 1 then
            newTopString = cand.stringIndex
          end
          dfs(i + 1, newAssign, newMin, newMax, newTopString)
          usedStrings[cand.stringIndex] = nil
        end
      end
    end
  end

  dfs(1, {}, nil, nil, nil)
  if bestAssign then
    return bestAssign, bestCost, bestTopString
  end
  return nil
end

local function build_dropped(original, subset)
  local counts = {}
  for _, p in ipairs(subset) do
    counts[p] = (counts[p] or 0) + 1
  end
  local dropped = {}
  for _, p in ipairs(original) do
    if counts[p] and counts[p] > 0 then
      counts[p] = counts[p] - 1
    else
      dropped[#dropped + 1] = p
    end
  end
  return dropped
end

local function reduce_chord(pitches, config, context)
  local ordered = { table.unpack(pitches) }
  table.sort(ordered, function(a, b) return a > b end)

  local preferHighest = config.reducePreferHighest ~= false
  local best = nil

  for size = #ordered - 1, 1, -1 do
    local function consider_subset(subset)
      local assign, cost, topString = solve_chord(subset, config, context)
      if assign then
        local sum = 0
        for _, p in ipairs(subset) do
          sum = sum + p
        end
        local topPitch = subset[1]
        local score = {
          size = #subset,
          top = topPitch,
          sum = sum,
          cost = cost,
          assign = assign,
          topString = topString,
          dropped = build_dropped(ordered, subset),
        }
        if not best then
          best = score
        else
          if score.size > best.size
            or (score.size == best.size and score.top > best.top)
            or (score.size == best.size and score.top == best.top and score.sum > best.sum)
            or (score.size == best.size and score.top == best.top and score.sum == best.sum and score.cost < best.cost) then
            best = score
          end
        end
      end
    end

    local subset = {}
    if preferHighest then
      subset[1] = ordered[1]
      local function rec(idx)
        if #subset == size then
          consider_subset(subset)
          return
        end
        for i = idx, #ordered do
          subset[#subset + 1] = ordered[i]
          rec(i + 1)
          subset[#subset] = nil
        end
      end
      if size >= 1 then
        rec(2)
      end
    else
      local function rec(idx)
        if #subset == size then
          consider_subset(subset)
          return
        end
        for i = idx, #ordered do
          subset[#subset + 1] = ordered[i]
          rec(i + 1)
          subset[#subset] = nil
        end
      end
      rec(1)
    end

    if best then
      break
    end
  end

  if best then
    return best.assign, best.dropped, best.topString
  end
  return nil
end

function Frets.solve_event(event, config, context)
  local pitches = {}
  for _, note in ipairs(event.notes) do
    pitches[#pitches + 1] = note.pitch
  end
  table.sort(pitches, function(a, b) return a > b end)

  local assign, _, topString = solve_chord(pitches, config, context)
  if not assign then
    assign, dropped, topString = reduce_chord(pitches, config, context)
    if not assign then
      return {}, pitches
    end
    event.dropped = dropped
  else
    event.dropped = {}
  end

  if context then
    context.lastFretForString = context.lastFretForString or {}
    for _, a in ipairs(assign) do
      context.lastFretForString[a.stringIndex] = a.fret
    end
    if topString then
      context.lastStringForTop = topString
    end
  end

  return assign, event.dropped
end

return Frets
