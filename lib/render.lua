local util = require("util")

local render = {}

local function string_y(staff_bottom, string_index, spacing)
  return staff_bottom - (string_index - 1) * spacing
end

local function draw_time_sig(draw_list, ctx, x, y, num, den, color, font_size, scale)
  local num_text = tostring(num)
  local den_text = tostring(den)
  local scale_val = scale or 1.4
  local bold_offset = 1
  local line_height = font_size * scale_val

  if ctx and reaper.ImGui_SetWindowFontScale then
    reaper.ImGui_SetWindowFontScale(ctx, scale_val)
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

local function add_boundary_time(boundaries, t)
  if t == nil then
    return
  end
  for _, existing in ipairs(boundaries) do
    if math.abs(existing - t) < 1e-6 then
      return
    end
  end
  boundaries[#boundaries + 1] = t
end

local function boundary_x_for_bar(bar, bar_layout, boundary_t, config)
  local eps = 1e-6
  if boundary_t <= bar.t0 + eps then
    return bar_layout.barlineX
  end
  if boundary_t >= bar.t1 - eps then
    return bar_layout.barLeft + config.barPrefixPx + config.barContentPx + config.barGutterPx
  end
  local frac = (boundary_t - bar.t0) / (bar.t1 - bar.t0)
  return bar_layout.content.x + frac * bar_layout.content.w
end

local function color_from_cfg(config, key, fallback)
  if not config or not config.colors then
    return fallback
  end
  local color = config.colors[key]
  if not color then
    return fallback
  end
  return util.color_u32(color[1], color[2], color[3], color[4])
end

local function with_font_scale(ctx, scale, fn)
  if ctx and reaper.ImGui_SetWindowFontScale and scale and scale ~= 1 then
    reaper.ImGui_SetWindowFontScale(ctx, scale)
    fn()
    reaper.ImGui_SetWindowFontScale(ctx, 1)
    return
  end
  fn()
end

function render.draw_systems(draw_list, systems, config, events_by_bar, font_size, ctx, current_bar_idx, item_bounds)
  local col_strings = color_from_cfg(config, "strings", util.color_u32(0.7, 0.7, 0.7, 1))
  local col_barlines = color_from_cfg(config, "barlines", util.color_u32(0.4, 0.4, 0.4, 1))
  local col_item = color_from_cfg(config, "itemBoundary", util.color_u32(0.7, 0.7, 0.7, 1))
  local col_text = color_from_cfg(config, "text", util.color_u32(1, 1, 1, 1))
  local col_dropped = color_from_cfg(config, "dropped", util.color_u32(1, 0.25, 0.25, 1))
  local col_marker = color_from_cfg(config, "marker", util.color_u32(1, 0.2, 0.2, 0.18))
  local col_note_bg = color_from_cfg(config, "noteBg", util.color_u32(0.05, 0.05, 0.05, 0.85))
  local barline_thickness = config.barLineThickness or 1.0
  local item_thickness = config.itemBoundaryThickness or 2.5

  font_size = font_size or 12
  local fret_scale = (config.fonts and config.fonts.fretScale) or 1.0
  local time_sig_scale = (config.fonts and config.fonts.timeSigScale) or 1.4
  local dropped_scale = (config.fonts and config.fonts.droppedScale) or 0.8

  for _, system in ipairs(systems) do
    local staff = system.staffRect
    local left = system.x0
    local right = system.x0 + staff.w

    for s = 1, #config.tuning do
      local y = string_y(staff.bottom, s, config.stringSpacingPx)
      reaper.ImGui_DrawList_AddLine(draw_list, left, y, right, y, col_strings, 1.0)
    end

    local boundary_times = {}
    if item_bounds then
      if item_bounds.current then
        add_boundary_time(boundary_times, item_bounds.current.t0)
        add_boundary_time(boundary_times, item_bounds.current.t1)
      end
      if item_bounds.next then
        add_boundary_time(boundary_times, item_bounds.next.t0)
        add_boundary_time(boundary_times, item_bounds.next.t1)
      end
    end

    for k, bar_layout in ipairs(system.barLayouts) do
      local x = bar_layout.barlineX
      reaper.ImGui_DrawList_AddLine(draw_list, x, staff.y, x, staff.bottom, col_barlines, barline_thickness)

      local bar = system.bars[k]
      if bar then
        if #boundary_times > 0 then
          for _, boundary_t in ipairs(boundary_times) do
            local is_last_bar = (k == #system.barLayouts)
            local in_range = boundary_t >= bar.t0 and boundary_t < bar.t1
            if not in_range and is_last_bar and boundary_t == bar.t1 then
              in_range = true
            end
            if in_range then
              local bx = boundary_x_for_bar(bar, bar_layout, boundary_t, config)
              reaper.ImGui_DrawList_AddLine(draw_list, bx, staff.y, bx, staff.bottom, col_item, item_thickness)
            end
          end
        end
        if current_bar_idx ~= nil and bar.idx == current_bar_idx then
          local bar_right = bar_layout.barLeft + config.barPrefixPx + config.barContentPx
          reaper.ImGui_DrawList_AddRectFilled(draw_list, bar_layout.barLeft, staff.y, bar_right, staff.bottom, col_marker)
        end
        if k == 1 and config.showFirstTimeSigInSystemGutter then
          draw_time_sig(draw_list, ctx, system.x0 + 6, staff.y, bar.num, bar.den, col_text, font_size, time_sig_scale)
        elseif bar.showTimeSigHere then
          draw_time_sig(draw_list, ctx, bar_layout.prefix.x + 2, staff.y, bar.num, bar.den, col_text, font_size, time_sig_scale)
        end
      end

      local events = events_by_bar[bar.idx] or {}
      for _, event in ipairs(events) do
        local frac = (event.t - bar.t0) / (bar.t1 - bar.t0)
        local x_pos = bar_layout.content.x + frac * bar_layout.content.w

        local assignments = event.assignments or {}
        if #assignments > 1 then
          local sorted = {}
          for i = 1, #assignments do
            sorted[i] = assignments[i]
          end
          table.sort(sorted, function(a, b)
            return a.string < b.string
          end)
          assignments = sorted
        end

        with_font_scale(ctx, fret_scale, function()
          local sized_font = font_size * fret_scale
          for _, note in ipairs(assignments) do
            local y = string_y(staff.bottom, note.string, config.stringSpacingPx)
            local text = tostring(note.fret)
            local w, h = calc_text_size(ctx, text, sized_font)
            local text_x = x_pos - (w * 0.5)
            local text_y = y - (h * 0.5)
            draw_text_with_bg(draw_list, ctx, text_x, text_y, text, col_text, col_note_bg, 2, sized_font)
          end
        end)

        with_font_scale(ctx, dropped_scale, function()
          local sized_font = font_size * dropped_scale
          for i, pitch in ipairs(event.dropped) do
            local y = staff.y - sized_font * 0.8
            local offset = (i - 1) * 8
            reaper.ImGui_DrawList_AddText(draw_list, bar_layout.prefix.x + offset, y, col_dropped, tostring(pitch))
          end
        end)
      end
    end

    local end_x = system.x0 + system.gutterW + (#system.barLayouts) * (config.barPrefixPx + config.barContentPx + config.barGutterPx)
    reaper.ImGui_DrawList_AddLine(draw_list, end_x, staff.y, end_x, staff.bottom, col_barlines, barline_thickness)
  end
end

return render
