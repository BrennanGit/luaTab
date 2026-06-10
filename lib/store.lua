-- lib/store.lua
-- Typed ExtState primitives shared by config.lua and presets.lua.
-- All values persist (SetExtState persist=true).

local store = {}

function store.read_number(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = tonumber(reaper.GetExtState(section, key))
    if value ~= nil then
      return value
    end
  end
  return fallback
end

function store.read_bool(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = reaper.GetExtState(section, key)
    if value == "true" then return true end
    if value == "false" then return false end
  end
  return fallback
end

function store.read_string(section, key, fallback)
  if reaper.HasExtState(section, key) then
    local value = reaper.GetExtState(section, key)
    if value ~= "" then
      return value
    end
  end
  return fallback
end

function store.read_color(section, key, fallback)
  local r = store.read_number(section, key .. ".r", nil)
  local g = store.read_number(section, key .. ".g", nil)
  local b = store.read_number(section, key .. ".b", nil)
  local a = store.read_number(section, key .. ".a", nil)
  if r == nil and g == nil and b == nil and a == nil then
    return fallback
  end
  fallback = fallback or { 0, 0, 0, 1 }
  return {
    r or fallback[1],
    g or fallback[2],
    b or fallback[3],
    a or fallback[4],
  }
end

function store.write(section, key, value)
  reaper.SetExtState(section, key, tostring(value), true)
end

function store.write_color(section, key, color)
  if not color then return end
  store.write(section, key .. ".r", color[1])
  store.write(section, key .. ".g", color[2])
  store.write(section, key .. ".b", color[3])
  store.write(section, key .. ".a", color[4])
end

function store.delete(section, key)
  reaper.DeleteExtState(section, key, true)
end

function store.delete_color(section, key)
  store.delete(section, key .. ".r")
  store.delete(section, key .. ".g")
  store.delete(section, key .. ".b")
  store.delete(section, key .. ".a")
end

function store.has(section, key)
  return reaper.HasExtState(section, key)
end

return store
