-- tests/tests.lua
-- Minimal assertion helpers; run from within REAPER (Actions -> Run script)

local function assert_true(cond, msg)
  if not cond then error("assert_true failed: " .. (msg or "")) end
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error(string.format("assert_eq failed: %s != %s. %s", tostring(a), tostring(b), msg or ""))
  end
end

local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then
  source = source:sub(2)
end
local script_dir = source:match("^(.*)[/\\].-$") or "."
package.path = package.path .. ";" .. script_dir .. "/../lib/?.lua"

local layout = require("layout")
local frets = require("frets")

local function run()
  assert_true(true, "sanity")
  assert_eq(1 + 1, 2, "math")

  local cfg = {
    systemGutterPx = 60,
    barPrefixPx = 16,
    barContentPx = 120,
    barGutterPx = 8,
    systemRowGapPx = 16,
    staffPaddingTopPx = 10,
    staffPaddingBottomPx = 10,
    stringSpacingPx = 14,
    tuning = {
      { name = "G", open = 55 },
      { name = "D", open = 62 },
      { name = "A", open = 69 },
      { name = "E", open = 76 },
    },
    maxFret = 15,
    maxFrettedSpan = 3,
    maxSimul = 4,
    weights = { lowFret = 8, stayOnString = 6, stringJump = 4, fretJump = 4, highFret = 2 },
  }

  local bars = {}
  for i = 1, 5 do
    bars[#bars + 1] = { idx = i - 1, t0 = i - 1, t1 = i, num = 4, den = 4, showTimeSigHere = false }
  end
  local systems = layout.build_systems(bars, cfg, 260, 0, 0)
  assert_true(#systems >= 2, "layout wraps into multiple systems")

  local state = frets.new_state(#cfg.tuning)
  local event = { notes = { { pitch = 57 }, { pitch = 67 }, { pitch = 69 } } }
  local result = frets.assign_event(event, cfg, state)
  assert_eq(#result.assignments, 3, "span allows open strings as free")

  cfg.maxFrettedSpan = 1
  local reduced = frets.assign_event(event, cfg, state)
  assert_true(#reduced.assignments < 3, "reduction when span too small")

  local kept = {}
  for _, a in ipairs(reduced.assignments) do
    kept[a.pitch] = true
  end
  assert_true(kept[69] == true, "keeps highest pitch when reduced")

  reaper.ShowMessageBox("tests ok", "luaTab", 0)
end

run()
