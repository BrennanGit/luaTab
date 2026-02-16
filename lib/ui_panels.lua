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
    dlog(("window skip title=%s open=false"):format(tostring(title)))
    return false
  end

  dlog(("window begin title=%s open_ref=%s"):format(
    tostring(title), tostring(open_ref and open_ref.value)))

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


-- Helper for a "panel toggle" menu item
function Panels.menu_toggle(ctx, label, open_ref)
  local changed, v = reaper.ImGui_MenuItem(ctx, label, nil, open_ref.value)
  if changed then open_ref.value = v end
  return changed
end

function Panels.menu_bar(ctx, draw_fn)
  if not reaper.ImGui_BeginMenuBar then
    return false
  end
  if reaper.ImGui_BeginMenuBar(ctx) then
    push("menubar:root")
    if draw_fn then
      draw_fn(ctx)
    end
    reaper.ImGui_EndMenuBar(ctx)
    pop("menubar:root")
    return true
  end
  return false
end

function Panels.menu(ctx, label, draw_fn)
  if not reaper.ImGui_BeginMenu then
    return false
  end
  if reaper.ImGui_BeginMenu(ctx, label) then
    push("menu:" .. tostring(label))
    if draw_fn then
      draw_fn(ctx)
    end
    reaper.ImGui_EndMenu(ctx)
    pop("menu:" .. tostring(label))
    return true
  end
  return false
end

function Panels.tab_bar(ctx, id, flags, draw_fn)
  if not reaper.ImGui_BeginTabBar then
    return false
  end
  if reaper.ImGui_BeginTabBar(ctx, id, flags or 0) then
    push("tabbar:" .. tostring(id))
    if draw_fn then
      draw_fn(ctx)
    end
    reaper.ImGui_EndTabBar(ctx)
    pop("tabbar:" .. tostring(id))
    return true
  end
  return false
end

function Panels.tab_item(ctx, label, open_ref, flags, draw_fn)
  if not reaper.ImGui_BeginTabItem then
    return false
  end
  local open = open_ref and open_ref.value or true
  local visible = reaper.ImGui_BeginTabItem(ctx, label, open, flags or 0)
  if open_ref then
    open_ref.value = open
  end
  if visible then
    push("tabitem:" .. tostring(label))
    if draw_fn then
      draw_fn(ctx)
    end
    reaper.ImGui_EndTabItem(ctx)
    pop("tabitem:" .. tostring(label))
    return true
  end
  return false
end

function Panels.child(ctx, id, w, h, border, flags, draw_fn)
  if not reaper.ImGui_BeginChild then
    return false
  end
  local visible = reaper.ImGui_BeginChild(ctx, id, w or 0, h or 0, border or false, flags or 0)
  if visible then
    push("child:" .. tostring(id))
    if draw_fn then
      draw_fn(ctx)
    end
    reaper.ImGui_EndChild(ctx)
    pop("child:" .. tostring(id))
    return true
  end
  return false
end

function Panels.table(ctx, id, columns, flags, outer_w, outer_h, inner_w, draw_fn)
  if not reaper.ImGui_BeginTable then
    return false
  end
  if reaper.ImGui_BeginTable(ctx, id, columns or 1, flags or 0, outer_w or 0, outer_h or 0, inner_w or 0) then
    push("table:" .. tostring(id))
    if draw_fn then
      draw_fn(ctx)
    end
    reaper.ImGui_EndTable(ctx)
    pop("table:" .. tostring(id))
    return true
  end
  return false
end

-- Safe wrapper for docking enablement (if you want)
function Panels.enable_docking(ctx)
  -- In upstream ImGui you need io.ConfigFlags |= DockingEnable.
  -- ReaImGui exposes some docking functions depending on version.
  -- Many setups work out-of-box; keep this optional and feature-detected.
  if api_exists("ImGui_GetIO") and api_exists("ImGui_ConfigFlags_DockingEnable") then
    local io = reaper.ImGui_GetIO(ctx)
    -- Some ReaImGui builds expose setters; others not. So treat as optional.
    -- If you can't set flags, docking still may work via default config.
    dlog("Docking config flags present (implementation dependent).")
  end
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
