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

-- Example placeholder test (replace with solver/layout tests later)
local function run()
  assert_true(true, "sanity")
  assert_eq(1 + 1, 2, "math")
  reaper.ShowMessageBox("tests ok", "luaTab", 0)
end

run()
