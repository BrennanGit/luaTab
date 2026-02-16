-- @description ReaImGui Begin/End docking test

if not reaper.APIExists("ImGui_CreateContext") then
  return
end

local ctx = reaper.ImGui_CreateContext("DockTest")
local openA = true
local openB = true

local function loop()
  local visA
  visA, openA = reaper.ImGui_Begin(ctx, "Panel A", openA)
  if visA then
    reaper.ImGui_Text(ctx, "A")
    reaper.ImGui_End(ctx)
  end

  local visB
  visB, openB = reaper.ImGui_Begin(ctx, "Panel B", openB)
  if visB then
    reaper.ImGui_Text(ctx, "B")
    reaper.ImGui_End(ctx)
  end

  if openA or openB then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)
