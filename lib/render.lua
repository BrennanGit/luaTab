local util = require("util")

local render = {}

local function string_y(staff_bottom, string_index, spacing)
  return staff_bottom - (string_index - 1) * spacing
end

local function font_base_size(ctx, fallback)
  if ctx and reaper.ImGui_GetFontSize then
    return reaper.ImGui_GetFontSize(ctx)
  end
  return fallback or 12
end

local function calc_text_size(ctx, text, font_size)
  local base = font_base_size(ctx, font_size)
  local scale = (base > 0) and (font_size / base) or 1
  if ctx and reaper.ImGui_CalcTextSize then
    local w, h = reaper.ImGui_CalcTextSize(ctx, text)
    return w * scale, h * scale
  end
  local w = #text * base * 0.6
  return w * scale, base * scale
end

local function draw_text_ex(draw_list, ctx, x, y, color, text, font_size)
  if reaper.ImGui_DrawList_AddTextEx and reaper.ImGui_GetFont then
    local font = reaper.ImGui_GetFont(ctx)
    reaper.ImGui_DrawList_AddTextEx(draw_list, font, font_size, x, y, color, text)
  else
    reaper.ImGui_DrawList_AddText(draw_list, x, y, color, text)
  end
end

local function draw_text_with_bg(draw_list, ctx, x, y, text, color, bg_color, padding, font_size)
  local w, h = calc_text_size(ctx, text, font_size)
  local px = padding or 2
  reaper.ImGui_DrawList_AddRectFilled(draw_list, x - px, y - px, x + w + px, y + h + px, bg_color)
  draw_text_ex(draw_list, ctx, x, y, color, text, font_size)
end

local function draw_time_sig(draw_list, ctx, x, y, num, den, color, font_size, scale)
  local num_text = tostring(num)
  local den_text = tostring(den)
  local scale_val = scale or 1.4
  local bold_offset = 1
  local sized_font = font_size * scale_val
  local line_height = sized_font

  draw_text_ex(draw_list, ctx, x, y, color, num_text, sized_font)
  draw_text_ex(draw_list, ctx, x + bold_offset, y, color, num_text, sized_font)
  draw_text_ex(draw_list, ctx, x, y + line_height, color, den_text, sized_font)
  draw_text_ex(draw_list, ctx, x + bold_offset, y + line_height, color, den_text, sized_font)
end

local function time_sig_y(staff, font_size, scale)
  local scale_val = scale or 1.4
  local total_h = (font_size * scale_val) * 2
  if not staff or not staff.h then
    return staff and staff.y or 0
  end
  local y = staff.y + (staff.h - total_h) * 0.5
  y = y - (total_h * 0.08)
  return math.max(staff.y, y)
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
    return bar_layout.barLeft + config.barPrefixPx + config.barContentPx
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

local function color_table_from_cfg(config, key, fallback)
  if not config or not config.colors then
    return fallback
  end
  local color = config.colors[key]
  if not color then
    return fallback
  end
  return color
end

local function color_with_alpha(color, alpha)
  local a = util.clamp((color[4] or 1) * alpha, 0, 1)
  return util.color_u32(color[1], color[2], color[3], a)
end

local function build_fret_positions(count, length)
  local positions = { [0] = 0 }
  local denom = 1 - (2 ^ (-count / 12))
  local scale = (denom > 0) and (length / denom) or length
  for i = 1, count do
    positions[i] = scale - (scale / (2 ^ (i / 12)))
  end
  return positions
end

local function fret_center(positions, fret, length)
  local start = positions[fret] or length
  local finish = positions[fret + 1] or length
  return (start + finish) * 0.5
end

local function draw_fretboard_note(draw_list, x, y, size, fill_color, outline_color, roundness, outline_thickness)
  local half = size * 0.5
  local x1 = x - half
  local y1 = y - half
  local x2 = x + half
  local y2 = y + half
  if fill_color then
    reaper.ImGui_DrawList_AddRectFilled(draw_list, x1, y1, x2, y2, fill_color, roundness)
  end
  if outline_color then
    reaper.ImGui_DrawList_AddRect(draw_list, x1, y1, x2, y2, outline_color, roundness, 0, outline_thickness or 1.2)
  end
end

local function draw_fretboard_dot(draw_list, x, y, radius, color)
  if reaper.ImGui_DrawList_AddCircleFilled then
    reaper.ImGui_DrawList_AddCircleFilled(draw_list, x, y, radius, color)
  else
    reaper.ImGui_DrawList_AddRectFilled(draw_list, x - radius, y - radius, x + radius, y + radius, color, radius)
  end
end

function render.draw_fretboard(draw_list, ctx, rect, config, current_notes, next_notes, next_style)
  if not rect or rect.w <= 0 or rect.h <= 0 then
    return
  end

  local padding = 10
  local x0 = rect.x + padding
  local y0 = rect.y + padding
  local x1 = rect.x + rect.w - padding
  local y1 = rect.y + rect.h - padding
  if x1 <= x0 or y1 <= y0 then
    return
  end

  local col_bg = color_table_from_cfg(config, "fretboardBg", { 0.06, 0.06, 0.06, 1.0 })
  local col_strings = color_table_from_cfg(config, "fretboardStrings", { 0.55, 0.55, 0.55, 1.0 })
  local col_frets = color_table_from_cfg(config, "fretboardFrets", { 0.35, 0.35, 0.35, 1.0 })
  local col_current = color_table_from_cfg(config, "fretboardCurrent", { 0.2, 0.8, 0.3, 1.0 })
  local col_next = color_table_from_cfg(config, "fretboardNext", { 0.9, 0.7, 0.2, 1.0 })

  reaper.ImGui_DrawList_AddRectFilled(draw_list, rect.x, rect.y, rect.x + rect.w, rect.y + rect.h, color_with_alpha(col_bg, 1.0))

  local string_count = math.max(1, #config.tuning)
  local string_pad = math.min(12, (y1 - y0) * 0.12)
  local y0_strings = y0 + string_pad
  local y1_strings = y1 - string_pad
  if y1_strings <= y0_strings then
    y0_strings = y0
    y1_strings = y1
  end
  local spacing = (string_count > 1) and ((y1_strings - y0_strings) / (string_count - 1)) or 0
  local string_thickness = util.clamp(config.fretboardStringThickness or 1.0, 0.5, 6.0)
  local fret_thickness = util.clamp(config.fretboardFretThickness or 1.0, 0.5, 6.0)
  local boundary_pad = math.min(string_pad, math.max(2.0, spacing * 0.5))
  local y0_frets = util.clamp(y0_strings - boundary_pad, y0, y0_strings)
  local y1_frets = util.clamp(y1_strings + boundary_pad, y1_strings, y1)

  if y0_frets < y0_strings then
    reaper.ImGui_DrawList_AddLine(draw_list, x0, y0_frets, x1, y0_frets, color_with_alpha(col_strings, 0.7), string_thickness)
  end
  if y1_frets > y1_strings then
    reaper.ImGui_DrawList_AddLine(draw_list, x0, y1_frets, x1, y1_frets, color_with_alpha(col_strings, 0.7), string_thickness)
  end

  for s = 1, string_count do
    local y = string_y(y1_strings, s, spacing)
    reaper.ImGui_DrawList_AddLine(draw_list, x0, y, x1, y, color_with_alpha(col_strings, 1.0), string_thickness)
  end

  local fret_count = math.max(1, config.fretboardFrets or 12)
  local length = x1 - x0
  local positions = build_fret_positions(fret_count, length)

  local min_gap = length
  for i = 1, fret_count do
    local gap = positions[i] - positions[i - 1]
    if gap > 0 then
      min_gap = math.min(min_gap, gap)
    end
  end

  local nut_gap = 0
  if fret_count >= 1 then
    nut_gap = math.min(positions[1] * 0.6, math.max(4.0, fret_thickness * 2.4))
  end
  reaper.ImGui_DrawList_AddLine(draw_list, x0, y0_frets, x0, y1_frets, color_with_alpha(col_frets, 1.0), fret_thickness * 1.1)
  if nut_gap > 0 then
    reaper.ImGui_DrawList_AddLine(draw_list, x0 + nut_gap, y0_frets, x0 + nut_gap, y1_frets, color_with_alpha(col_frets, 1.0), fret_thickness * 0.9)
  end

  for i = 1, fret_count do
    local x = x0 + (positions[i] or 0)
    reaper.ImGui_DrawList_AddLine(draw_list, x, y0_frets, x, y1_frets, color_with_alpha(col_frets, 1.0), fret_thickness)
  end
  reaper.ImGui_DrawList_AddLine(draw_list, x1, y0_frets, x1, y1_frets, color_with_alpha(col_frets, 1.0), fret_thickness)

  local dot_frets = { 3, 5, 7, 12, 15, 17, 19 }
  local dot_scale = util.clamp(config.fretboardDotSize or 1.0, 0.2, 3.0)
  local dot_radius = math.max(2, spacing * 0.18) * dot_scale
  local dot_col = color_with_alpha(col_frets, 0.6)
  local mid_y = (y0_strings + y1_strings) * 0.5
  for _, fret in ipairs(dot_frets) do
    if fret <= fret_count and fret > 0 then
      local start = positions[fret - 1] or 0
      local finish = positions[fret] or length
      local x = x0 + (start + finish) * 0.5
      if fret == 12 and string_count > 1 then
        local offset = math.max(spacing * 0.6, dot_radius * 1.6)
        draw_fretboard_dot(draw_list, x, mid_y - offset, dot_radius, dot_col)
        draw_fretboard_dot(draw_list, x, mid_y + offset, dot_radius, dot_col)
      else
        draw_fretboard_dot(draw_list, x, mid_y, dot_radius, dot_col)
      end
    end
  end

  local note_scale = util.clamp(config.fretboardNoteSize or 1.0, 0.3, 2.5)
  local note_size = util.clamp(math.min(spacing * 0.8, min_gap * 0.7) * note_scale, 3, 40)
  local roundness = util.clamp((config.fretboardNoteRoundness or 0.3), 0, 1) * note_size * 0.5

  local function note_center(assign)
    if not assign or assign.fret == nil then
      return nil
    end
    if assign.fret < 0 or assign.fret > fret_count then
      return nil
    end
    local x
    if assign.fret == 0 then
      x = x0 + (nut_gap * 0.5)
    else
      local start = positions[assign.fret - 1] or 0
      local finish = positions[assign.fret] or length
      x = x0 + (start + finish) * 0.5
    end
    local y = string_y(y1_strings, assign.string, spacing)
    return x, y
  end

  local count_next = #next_notes
  for i, note in ipairs(next_notes) do
    local x, y = note_center(note)
    if x and y then
      local fill = nil
      local outline = color_with_alpha(col_next, 1.0)
      if next_style == "outline_shade" then
        fill = color_with_alpha(col_next, 0.3)
      elseif next_style == "outline_ramp" then
        local alpha
        if count_next <= 1 then
          alpha = 0.75
        else
          local t = (count_next - i) / (count_next - 1)
          alpha = 0 + t * 0.75
        end
        fill = color_with_alpha(col_next, alpha)
      end
      draw_fretboard_note(draw_list, x, y, note_size, fill, outline, roundness, 1.2)
    end
  end

  local col_current_u32 = color_with_alpha(col_current, 1.0)
  for _, note in ipairs(current_notes) do
    local x, y = note_center(note)
    if x and y then
      draw_fretboard_note(draw_list, x, y, note_size, col_current_u32, col_current_u32, roundness, 1.4)
    end
  end
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
  local bar_body = config.barPrefixPx + config.barContentPx

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
          local ts_y = time_sig_y(staff, font_size, time_sig_scale)
          draw_time_sig(draw_list, ctx, system.x0 + 6, ts_y, bar.num, bar.den, col_text, font_size, time_sig_scale)
        elseif bar.showTimeSigHere then
          local ts_y = time_sig_y(staff, font_size, time_sig_scale)
          draw_time_sig(draw_list, ctx, bar_layout.prefix.x + 2, ts_y, bar.num, bar.den, col_text, font_size, time_sig_scale)
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

        local sized_font = font_size * fret_scale
        for _, note in ipairs(assignments) do
          local y = string_y(staff.bottom, note.string, config.stringSpacingPx)
          local text = tostring(note.fret)
          local w, h = calc_text_size(ctx, text, sized_font)
          local text_x = x_pos - (w * 0.5)
          local text_y = y - (h * 0.5)
          draw_text_with_bg(draw_list, ctx, text_x, text_y, text, col_text, col_note_bg, 2, sized_font)
        end

        local dropped_font = font_size * dropped_scale
        for i, pitch in ipairs(event.dropped) do
          local y = staff.y - dropped_font * 0.8
          local offset = (i - 1) * 8
          draw_text_ex(draw_list, ctx, bar_layout.prefix.x + offset, y, col_dropped, tostring(pitch), dropped_font)
        end
      end
    end

    local bar_count = #system.barLayouts
    local end_x = system.x0 + system.gutterW + (bar_count * bar_body) + (math.max(0, bar_count - 1) * config.barGutterPx)
    reaper.ImGui_DrawList_AddLine(draw_list, end_x, staff.y, end_x, staff.bottom, col_barlines, barline_thickness)
  end
end

return render
