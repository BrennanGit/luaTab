package.path = table.concat({
  "./lib/?.lua",
  "./?.lua",
  package.path,
}, ";")

local tests = {}

local function test(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message or "assert_eq", tostring(expected), tostring(actual)), 2)
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed", 2)
  end
end

local overrides = require("overrides")
local midi = require("midi")
local frets = require("frets")
local layout = require("layout")

local mandolin = {
  tuning = {
    { name = "G", open = 55 },
    { name = "D", open = 62 },
    { name = "A", open = 69 },
    { name = "E", open = 76 },
  },
  maxFret = 15,
  maxFrettedSpan = 4,
  maxSimul = 4,
  weights = {
    lowFret = 8,
    stayOnString = 6,
    stringJump = 4,
    fretJump = 4,
    highFret = 2,
  },
}

local function copy_table(tbl)
  local copy = {}
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      copy[key] = copy_table(value)
    else
      copy[key] = value
    end
  end
  return copy
end

local function has_pitch(list, pitch)
  for _, value in ipairs(list or {}) do
    if value == pitch then
      return true
    end
  end
  return false
end

test("manual override constrains solver to string and derives fret", function()
  local event = { t = 1.2344, notes = { { pitch = 69 } } }
  local key = overrides.make_key(event, 69)
  local override_result = overrides.apply_event_overrides(event, mandolin, {
    [key] = { string = 2 },
  })
  local result = frets.assign_event(event, mandolin, frets.new_state(#mandolin.tuning))
  assert_eq(#result.assignments, 1, "assignment count")
  assert_eq(result.assignments[1].string, 2, "forced string")
  assert_eq(result.assignments[1].fret, 7, "derived fret")
  assert_eq(#result.dropped, 0, "dropped count")
  assert_eq(event.forcedStringsByPitch[69], 2, "forced string map")
  assert_eq(#override_result.overridesApplied, 1, "applied override count")
end)

test("manual override keeps forced pitch when reduction is needed", function()
  local event = { t = 2.0, notes = { { pitch = 69 }, { pitch = 71 } } }
  local one_note_mandolin = copy_table(mandolin)
  one_note_mandolin.maxSimul = 1
  local key = overrides.make_key(event, 69)
  overrides.apply_event_overrides(event, one_note_mandolin, {
    [key] = { string = 3 },
  })
  local result = frets.assign_event(event, one_note_mandolin, frets.new_state(#one_note_mandolin.tuning))
  assert_eq(#result.assignments, 1, "assignment count after reduction")
  assert_eq(result.assignments[1].pitch, 69, "forced pitch kept")
  assert_eq(result.assignments[1].string, 3, "forced string kept")
  assert_eq(result.assignments[1].fret, 0, "derived fret kept")
  assert_eq(#result.dropped, 1, "dropped count after reduction")
  assert_eq(result.dropped[1], 71, "automatic pitch dropped")
end)

test("invalid manual override string is skipped", function()
  local event = { t = 1.0, notes = { { pitch = 69 } } }
  local key = overrides.make_key(event, 69)
  local override_result = overrides.apply_event_overrides(event, mandolin, {
    [key] = { string = 4 },
  })
  local result = frets.assign_event(event, mandolin, frets.new_state(#mandolin.tuning))
  assert_eq(result.assignments[1].string, 3, "automatic assignment retained")
  assert_eq(#override_result.overridesSkipped, 1, "invalid override skipped")
  assert_true(not event.forcedStringsByPitch[69], "invalid string not passed to solver")
end)

test("midi filters accept all channels when channelFilter is zero", function()
  assert_true(midi.note_passes_filters({ channel = 7, start_time = 0, end_time = 0.01 }, { channelFilter = 0 }), "all channels accepted")
end)

test("midi filters use one-based channel setting", function()
  assert_true(midi.note_passes_filters({ channel = 0, start_time = 0, end_time = 0.01 }, { channelFilter = 1 }), "channel 1 accepted")
  assert_true(not midi.note_passes_filters({ channel = 1, start_time = 0, end_time = 0.01 }, { channelFilter = 1 }), "channel 2 rejected")
end)

test("midi filters reject short notes", function()
  assert_true(not midi.note_passes_filters({ channel = 0, start_time = 0, end_time = 0.004 }, { minNoteLenMs = 5 }), "short note rejected")
  assert_true(midi.note_passes_filters({ channel = 0, start_time = 0, end_time = 0.006 }, { minNoteLenMs = 5 }), "long enough note accepted")
end)

test("midi pitch names use scientific pitch notation", function()
  assert_eq(midi.pitch_name(60), "C4", "middle C")
  assert_eq(midi.pitch_name(69), "A4", "concert A")
  assert_eq(midi.pitch_name(61), "C#4", "sharp pitch")
end)

test("fret solver prefers open A on mandolin", function()
  local result = frets.assign_event({ notes = { { pitch = 69 } } }, mandolin, frets.new_state(#mandolin.tuning))
  assert_eq(#result.assignments, 1, "single pitch assignment count")
  assert_eq(result.assignments[1].string, 3, "A string selected")
  assert_eq(result.assignments[1].fret, 0, "open A selected")
end)

test("fret solver treats open strings as free for span", function()
  local config = copy_table(mandolin)
  config.maxFrettedSpan = 3
  local result = frets.assign_event({ notes = { { pitch = 55 }, { pitch = 64 }, { pitch = 74 } } }, config, frets.new_state(#config.tuning))
  assert_eq(#result.assignments, 3, "open plus fretted chord kept")
  assert_eq(#result.dropped, 0, "no dropped notes")
end)

test("fret solver reduction keeps highest pitches when maxSimul is exceeded", function()
  local config = copy_table(mandolin)
  config.maxSimul = 2
  local result = frets.assign_event({ notes = { { pitch = 55 }, { pitch = 62 }, { pitch = 69 } } }, config, frets.new_state(#config.tuning))
  assert_eq(#result.assignments, 2, "reduced assignment count")
  assert_true(not has_pitch(result.dropped, 69), "highest pitch retained")
  assert_true(has_pitch(result.dropped, 55), "lowest pitch dropped")
end)

test("layout wraps bars by available width", function()
  local config = {
    barPrefixPx = 10,
    barContentPx = 90,
    barGutterPx = 10,
    systemGutterPx = 20,
    staffPaddingTopPx = 5,
    staffPaddingBottomPx = 5,
    stringSpacingPx = 10,
    systemRowGapPx = 8,
    tuning = mandolin.tuning,
  }
  local bars = {}
  for i = 1, 5 do
    bars[i] = { idx = i - 1, t0 = i - 1, t1 = i, num = 4, den = 4 }
  end
  local systems = layout.build_systems(bars, config, 240, 100, 50)
  assert_eq(#systems, 3, "system count")
  assert_eq(#systems[1].bars, 2, "first system bar count")
  assert_eq(#systems[3].bars, 1, "last system bar count")
end)

test("midi grouping uses epsilon to collect staggered chord starts", function()
  local events = midi.group_events({
    { tStart = 0.000, pitch = 69 },
    { tStart = 0.005, pitch = 72 },
    { tStart = 0.020, pitch = 76 },
  }, 0.008)
  assert_eq(#events, 2, "event count")
  assert_eq(#events[1].notes, 2, "first grouped chord size")
  assert_eq(#events[2].notes, 1, "second event size")
end)

local failures = 0
for _, item in ipairs(tests) do
  io.write("test ", item.name, " ... ")
  local ok, err = pcall(item.fn)
  if ok then
    io.write("ok\n")
  else
    failures = failures + 1
    io.write("FAILED\n", err, "\n")
  end
end

if failures > 0 then
  error(string.format("%d test(s) failed", failures))
end

print(string.format("%d tests passed", #tests))