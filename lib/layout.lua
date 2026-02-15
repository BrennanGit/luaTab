local layout = {}

function layout.calc_bars_per_system(config, content_width)
  local bar_body = config.barPrefixPx + config.barContentPx
  local bar_pitch = bar_body + config.barGutterPx
  local usable = math.max(0, content_width - config.systemGutterPx)
  return math.max(1, math.floor((usable + config.barGutterPx) / bar_pitch))
end

function layout.build_systems(bars, config, content_width, origin_x, origin_y)
  local bar_body = config.barPrefixPx + config.barContentPx
  local bar_pitch = bar_body + config.barGutterPx
  local bars_per_system = layout.calc_bars_per_system(config, content_width)

  local systems = {}
  local string_count = #config.tuning
  local staff_height = (string_count - 1) * config.stringSpacingPx
  local system_height = config.staffPaddingTopPx + staff_height + config.staffPaddingBottomPx

  local row = 0
  local i = 1
  while i <= #bars do
    local system_bars = {}
    local bar_layouts = {}

    local x0 = origin_x
    local y0 = origin_y + row * (system_height + config.systemRowGapPx)
    local staff_top = y0 + config.staffPaddingTopPx
    local staff_bottom = staff_top + staff_height

    for k = 1, bars_per_system do
      local bar = bars[i]
      if not bar then break end

      local bar_left = x0 + config.systemGutterPx + (k - 1) * bar_pitch

      system_bars[#system_bars + 1] = bar
      bar_layouts[#bar_layouts + 1] = {
        barIdx = bar.idx,
        barLeft = bar_left,
        prefix = { x = bar_left, w = config.barPrefixPx },
        content = { x = bar_left + config.barPrefixPx, w = config.barContentPx },
        barlineX = bar_left,
      }

      i = i + 1
    end

    systems[#systems + 1] = {
      y = y0,
      x0 = x0,
      gutterW = config.systemGutterPx,
      bars = system_bars,
      barLayouts = bar_layouts,
      staffRect = {
        x = x0,
        y = staff_top,
        w = content_width,
        h = staff_height,
        bottom = staff_bottom,
      },
    }

    row = row + 1
  end

  return systems
end

return layout
