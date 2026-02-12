-- lib/style.lua
-- Styling constants + color helpers (ReaImGui)

local Style = {}

-- Layout constants (stable defaults)
Style.systemGutterPx   = 60
Style.barPrefixPx      = 16
Style.barContentPx     = 120
Style.barGutterPx      = 8
Style.systemRowGapPx   = 16
Style.staffPadTopPx    = 10
Style.staffPadBotPx    = 10
Style.stringSpacingPx  = 14

-- Line thickness
Style.stringLineThickness = 1.0
Style.barLineThickness    = 2.0
Style.beatTickThickness   = 1.0

-- Colors (as doubles 0..1; convert to U32 once via BuildColors)
Style.colors = {
  text    = {1.0, 1.0, 1.0, 1.0},
  strings = {1.0, 1.0, 1.0, 0.25},
  bars    = {1.0, 1.0, 1.0, 0.55},
  dropped = {1.0, 0.25, 0.25, 1.0},
  debug   = {0.25, 0.90, 0.90, 1.0},
}

function Style.BuildColors(ctx)
  -- Convert to packed U32 once (fast for rendering)
  local col = {}
  for k, rgba in pairs(Style.colors) do
    col[k] = reaper.ImGui_ColorConvertDouble4ToU32(rgba[1], rgba[2], rgba[3], rgba[4])
  end
  return col
end

return Style
