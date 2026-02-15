local util = require("util")

local render = {}

local function string_y(staff_bottom, string_index, spacing)
  return staff_bottom - (string_index - 1) * spacing
end

local function draw_time_sig(draw_list, ctx, x, y, num, den, color, font_size)
  local num_text = tostring(num)
  local den_text = tostring(den)
  local scale = 1.4
  local bold_offset = 1
  local line_height = font_size * scale

  if ctx and reaper.ImGui_SetWindowFontScale then
    reaper.ImGui_SetWindowFontScale(ctx, scale)
  end

  reaper.ImGui_DrawList_AddText(draw_list, x, y, color, num_text)
  reaper.ImGui_DrawList_AddText(draw_list, x + bold_offset, y, color, num_text)
  reaper.ImGui_DrawList_AddText(draw_list, x, y + line_height, color, den_text)
  reaper.ImGui_DrawList_AddText(draw_list, x + bold_offset, y + line_height, color, den_text)

  if ctx and reaper.ImGui_SetWindowFontScale then
    reaper.ImGui_SetWindowFontScale(ctx, 1)
  end
end

local function calc_text_size(ctx, text, font_size)
  if ctx and reaper.ImGui_CalcTextSize then
    local w, h = reaper.ImGui_CalcTextSize(ctx, text)
    return w, h
  end
  local w = #text * font_size * 0.6
  return w, font_size
end

local function draw_text_with_bg(draw_list, ctx, x, y, text, color, bg_color, padding, font_size)
  local w, h = calc_text_size(ctx, text, font_size)
  local px = padding or 2
  reaper.ImGui_DrawList_AddRectFilled(draw_list, x - px, y - px, x + w + px, y + h + px, bg_color)
  reaper.ImGui_DrawList_AddText(draw_list, x, y, color, text)
end

function render.draw_systems(draw_list, systems, config, events_by_bar, font_size, ctx, current_bar_idx)
  local col_strings = util.color_u32(0.7, 0.7, 0.7, 1)
  local col_barlines = util.color_u32(0.4, 0.4, 0.4, 1)
  local col_text = util.color_u32(1, 1, 1, 1)
  local col_dropped = util.color_u32(1, 0.25, 0.25, 1)
  local col_marker = util.color_u32(1, 0.2, 0.2, 0.18)
  local col_note_bg = util.color_u32(0.05, 0.05, 0.05, 0.85)

  font_size = font_size or 12

  for _, system in ipairs(systems) do
    local staff = system.staffRect
    local left = system.x0
    local right = system.x0 + staff.w

    for s = 1, #config.tuning do
      local y = string_y(staff.bottom, s, config.stringSpacingPx)
      reaper.ImGui_DrawList_AddLine(draw_list, left, y, right, y, col_strings, 1.0)
    end

    for k, bar_layout in ipairs(system.barLayouts) do
      local x = bar_layout.barlineX
      reaper.ImGui_DrawList_AddLine(draw_list, x, staff.y, x, staff.bottom, col_barlines, 1.0)

      local bar = system.bars[k]
      if bar then
        if current_bar_idx ~= nil and bar.idx == current_bar_idx then
          local bar_right = bar_layout.barLeft + config.barPrefixPx + config.barContentPx
          reaper.ImGui_DrawList_AddRectFilled(draw_list, bar_layout.barLeft, staff.y, bar_right, staff.bottom, col_marker)
        end
        if k == 1 and config.showFirstTimeSigInSystemGutter then
          draw_time_sig(draw_list, ctx, system.x0 + 6, staff.y, bar.num, bar.den, col_text, font_size)
        elseif bar.showTimeSigHere then
          draw_time_sig(draw_list, ctx, bar_layout.prefix.x + 2, staff.y, bar.num, bar.den, col_text, font_size)
        end
      end

      local events = events_by_bar[bar.idx] or {}
      for _, event in ipairs(events) do
        local frac = (event.t - bar.t0) / (bar.t1 - bar.t0)
        local x_pos = bar_layout.content.x + frac * bar_layout.content.w

        for i, note in ipairs(event.assignments) do
          local y = string_y(staff.bottom, note.string, config.stringSpacingPx)
          local offset = (i - 1) * 3
          local text = tostring(note.fret)
          local w, h = calc_text_size(ctx, text, font_size)
          local text_x = (x_pos + offset) - (w * 0.5)
          local text_y = y - (h * 0.5)
          draw_text_with_bg(draw_list, ctx, text_x, text_y, text, col_text, col_note_bg, 2, font_size)
        end

        for i, pitch in ipairs(event.dropped) do
          local y = staff.y - font_size * 0.8
          local offset = (i - 1) * 8
          reaper.ImGui_DrawList_AddText(draw_list, bar_layout.prefix.x + offset, y, col_dropped, tostring(pitch))
        end
      end
    end

    local end_x = system.x0 + system.gutterW + (#system.barLayouts) * (config.barPrefixPx + config.barContentPx + config.barGutterPx)
    reaper.ImGui_DrawList_AddLine(draw_list, end_x, staff.y, end_x, staff.bottom, col_barlines, 1.0)
  end
end

return render
