-- lib/render.lua
-- Draw systems, barlines, frets, and dropped notes

local Render = {}

function Render.draw_systems(drawList, systems, eventsByBar, cfg, style, col)
  local stringCount = #cfg.tuning

  for _, system in ipairs(systems) do
    local staff = system.staffRect

    -- String lines
    for s = 1, stringCount do
      local y = staff.y + (s - 1) * style.stringSpacingPx
      reaper.ImGui_DrawList_AddLine(drawList, staff.x, y, staff.x + staff.w, y, col.strings, style.stringLineThickness)
    end

    -- Barlines and content
    for barIdx, layout in ipairs(system.barLayouts) do
      local bar = layout.barRef
      local x = layout.barlineX
      reaper.ImGui_DrawList_AddLine(drawList, x, staff.y, x, staff.y + staff.h, col.bars, style.barLineThickness)

      if bar.showTimeSigHere then
        local tsText = tostring(bar.num) .. "/" .. tostring(bar.den)
        local tx
        local ty = staff.y
        if barIdx == 1 and cfg.showFirstTimeSigInSystemGutter then
          tx = system.x0 + 4
        else
          tx = layout.prefix.x + 2
        end
        reaper.ImGui_DrawList_AddText(drawList, tx, ty, col.text, tsText)
      end

      local events = eventsByBar[bar.idx]
      if events then
        for _, event in ipairs(events) do
          local frac = 0
          if bar.t1 > bar.t0 then
            frac = (event.t - bar.t0) / (bar.t1 - bar.t0)
          end
          local baseX = layout.content.x + frac * layout.content.w

          local assigned = event.assigned or {}
          local count = #assigned
          for i, a in ipairs(assigned) do
            local offset = (i - (count + 1) / 2) * 4
            local y = staff.y + (a.stringIndex - 1) * style.stringSpacingPx - 6
            reaper.ImGui_DrawList_AddText(drawList, baseX + offset, y, col.text, tostring(a.fret))
          end

          local dropped = event.dropped or {}
          if #dropped > 0 then
            local dx = layout.prefix.x + 2
            local dy = staff.y - 12
            reaper.ImGui_DrawList_AddText(drawList, dx, dy, col.dropped, "x" .. tostring(#dropped))
          end
        end
      end
    end

    -- End barline
    local endX = staff.x + staff.w
    reaper.ImGui_DrawList_AddLine(drawList, endX, staff.y, endX, staff.y + staff.h, col.bars, style.barLineThickness)
  end
end

return Render
