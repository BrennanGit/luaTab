-- lib/layout.lua
-- System wrapping and bar geometry

local Layout = {}

function Layout.compute_systems(bars, startX, startY, contentW, stringCount, style)
  local systems = {}
  local barLayoutsByIdx = {}

  if #bars == 0 then
    return systems, barLayoutsByIdx
  end

  local barTotal = style.barPrefixPx + style.barContentPx
  local usableWidth = math.max(1, contentW)
  local barsPerSystem = math.floor((usableWidth - style.systemGutterPx) / (barTotal + style.barGutterPx))
  if barsPerSystem < 1 then
    barsPerSystem = 1
  end

  local staffH = (stringCount - 1) * style.stringSpacingPx
  local rowH = style.staffPadTopPx + staffH + style.staffPadBotPx

  local i = 1
  local systemIdx = 1
  while i <= #bars do
    local count = math.min(barsPerSystem, #bars - i + 1)
    local systemX = startX
    local systemY = startY + (systemIdx - 1) * (rowH + style.systemRowGapPx)

    local systemBars = {}
    local barLayouts = {}
    for k = 1, count do
      local bar = bars[i + k - 1]
      local barLeft = systemX + style.systemGutterPx + (k - 1) * (barTotal + style.barGutterPx)
      local layout = {
        barIdx = bar.idx,
        barLeft = barLeft,
        prefix = { x = barLeft, w = style.barPrefixPx },
        content = { x = barLeft + style.barPrefixPx, w = style.barContentPx },
        barlineX = barLeft,
        barRef = bar,
        systemIndex = systemIdx,
      }
      systemBars[#systemBars + 1] = bar
      barLayouts[#barLayouts + 1] = layout
      barLayoutsByIdx[bar.idx] = layout
    end

    local barAreaW = count * barTotal + math.max(0, count - 1) * style.barGutterPx
    local staffRect = {
      x = systemX + style.systemGutterPx,
      y = systemY + style.staffPadTopPx,
      w = barAreaW,
      h = staffH,
    }

    systems[#systems + 1] = {
      x0 = systemX,
      y = systemY,
      gutterW = style.systemGutterPx,
      bars = systemBars,
      barLayouts = barLayouts,
      staffRect = staffRect,
      barAreaW = barAreaW,
    }

    i = i + count
    systemIdx = systemIdx + 1
  end

  return systems, barLayoutsByIdx
end

return Layout
