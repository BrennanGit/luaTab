-- lib/ui_panels.lua
-- Robust panel helpers for ReaImGui docking/floating + correct Begin/End pairing.

local Panels = {}

Panels._stack = {}   -- runtime guard: tracks Begin calls for debugging

local function api_exists(name)
  return reaper.APIExists and reaper.APIExists(name)
end

-- Optional: on-screen / file logging hooks
Panels.DEBUG = false
Panels.log = function(_) end

local function dlog(msg)
  if Panels.DEBUG then Panels.log(msg) end
end

-- Utility: push/pop a name on the panel stack to catch mismatches
local function push(name)
  Panels._stack[#Panels._stack+1] = name
end

local function pop(expected_name)
  local n = #Panels._stack
  if n == 0 then
    dlog("Panels.pop: stack underflow (unexpected End)")
    return
  end
  local got = Panels._stack[n]
  Panels._stack[n] = nil
  if got ~= expected_name then
    dlog(("Panels.pop mismatch: expected '%s' got '%s'"):format(expected_name, got))
  end
end

-- Call once per frame near top of your UI loop if you want strict checking.
-- If any Begin happened without End, stack won't be empty at end-of-frame.
function Panels.end_frame_check()
  if #Panels._stack ~= 0 then
    dlog("Panels.end_frame_check: Begin/End imbalance. Unclosed panels:")
    for i = #Panels._stack, 1, -1 do
      dlog("  - " .. tostring(Panels._stack[i]))
    end
    -- Don't auto-clear; better to catch the bug early.
  end
end

-- Canonical Begin/End wrapper.
-- Ensures:
--   - End is called only when Begin returns visible=true (ReaImGui behavior)
--   - Visible gating controls drawing and End pairing
--   - Optional: auto-handle close button toggling via `open_ref`
--
-- Usage:
--   Panels.window(ctx, state.panels.debug, "Debug", flags, function(ctx) ... end)
--
-- where open_ref is a table like: { value = true }
function Panels.window(ctx, open_ref, title, flags, draw_fn)
  if open_ref and open_ref.value == false then
    -- dlog(("window skip title=%s open=false"):format(tostring(title)))
    return false
  end

  -- dlog(("window begin title=%s open_ref=%s"):format(
  --   tostring(title), tostring(open_ref and open_ref.value)))

  local visible, open = reaper.ImGui_Begin(ctx, title, open_ref and open_ref.value or true, flags or 0)

  -- If Begin fails in some catastrophic way, bail
  if visible == nil then
    dlog(("window begin returned nil title=%s"):format(tostring(title)))
    return false
  end

  if open_ref then open_ref.value = open end

  -- REAIMGUI QUIRK WORKAROUND:
  -- Empirically (docking/tab hidden), calling End() when visible=false can crash.
  -- So only treat visible=true as a valid opened scope.
  local scope_opened = (visible == true)

  if scope_opened then
    push("window:" .. tostring(title))
    if draw_fn then draw_fn(ctx) end
    reaper.ImGui_End(ctx)
    pop("window:" .. tostring(title))
  else
    dlog(("window hidden/no-scope title=%s open=%s"):format(tostring(title), tostring(open)))
  end

  return visible
end


-- A safe dockspace wrapper. Use inside your main window.
function Panels.dockspace(ctx, id_str)
  if api_exists("ImGui_DockSpace") then
    -- full-window dockspace, typical pattern
    local id = reaper.ImGui_GetID(ctx, id_str or "MainDockSpace")
    reaper.ImGui_DockSpace(ctx, id)
  end
end

return Panels
