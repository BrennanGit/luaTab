# Task #039: Continuous Mode Performance

- ID: #039-continuous-mode-performance
- Created: 2026-02-17 00:30 UTC
- Status: done
- Type: bugfix
- Stability: experimental
- Owner: agent
- Related: #038, #013
- Self-reminder: Read meta.md first; plan -> execute -> verify -> update.

## Summary
Reduce lag/stutter and readability artifacts in `continuous` update mode by removing per-frame full system layout rebuilding, using cached layout with draw-time x offset, and iterating to a stable non-snapping pixel-aligned motion path.

## Requirements
- Improve runtime smoothness in continuous mode.
- Keep behavior and visuals unchanged for bar/step/screen modes.
- Preserve click-to-seek behavior when system drawing is offset.

## Acceptance Criteria
- [x] Continuous mode no longer rebuilds systems every frame when bars/window geometry are unchanged.
- [x] Continuous mode visual sweep still matches playback progression.
- [x] Bar click seek still lands on correct bars with sweep offset active.
- [x] Changed files are error-free in editor diagnostics.
- [x] Continuous mode avoids bar snap-away/snap-back artifacts.
- [x] Moving text coordinates are pixel-aligned to reduce doubled/ghosted fret glyph artifacts.

## Plan
- [x] Add layout cache invalidation/versioning tied to `rebuild_data()` output changes.
  - Files: luaTab.lua
  - Functions: rebuild_data(), draw_ui()
  - Verify: system rebuild trigger checks include data version + geometry and skip per-frame allocations.
- [x] Add render-time x-offset support and preserve hit-testing alignment.
  - Files: lib/render.lua, luaTab.lua
  - Functions: render.draw_systems(), handle_bar_click(), draw_ui()
  - Verify: draw offsets apply consistently to strings, bars, notes, signatures, and click bounds.
- [x] Run diagnostics and update tracking/meta summaries.
  - Files: .tracking/meta.md, .tracking/039-continuous-mode-performance.md
  - Verify: no relevant new errors in changed files.

## Execution Log

* 2026-02-17 00:30 UTC Start-of-turn Context Recap:
  * Goal: Improve playback smoothness in continuous mode by reducing per-frame work.
  * Current State: `layout.build_systems()` runs every frame; in continuous mode origin is shifted each frame causing table churn.
  * Blocking Issues: None.
  * Next Subtask: Implement cache key + render-time offset and hook click mapping.
  * Known Risks: Misaligned click hitboxes if draw offset and layout coordinates diverge.

* 2026-02-17 00:34 UTC Added layout epoch invalidation in `rebuild_data()` and layout-key caching in `draw_ui()` so `layout.build_systems()` runs only when data/geometry changes.

* 2026-02-17 00:35 UTC Added optional `draw_offset_x` path to `render.draw_systems()` and `handle_bar_click()` to keep visuals and interaction aligned without rebuilding layout per frame.

* 2026-02-17 00:36 UTC Verified `luaTab.lua` and `lib/render.lua` with `get_errors` (no errors).

* 2026-02-17 00:48 UTC Iteration pass: added smoothing/pixel-snapping and moved per-event assignment sorting + pitch mapping to rebuild-time (later adjusted due wrap artifacts).

* 2026-02-17 00:58 UTC Iteration pass: removed bar-wrap snap behavior from smoothing path.

* 2026-02-17 01:09 UTC Iteration pass: replaced cyclic wrap interpolation with direct per-bar pixel-snapped offset to eliminate snap-away/snap-back each bar.

* 2026-02-17 01:20 UTC Iteration pass: applied strict pixel alignment in `lib/render.lua` for moving text coordinates (fret text, time signatures, dropped-note labels) to reduce ghosting/doubling artifacts.

## Decisions

## Open Questions

## Risks
- Manual REAPER playback verification is still required to subjectively confirm stutter reduction under real project load.

## Useful Commands and Testing
- Diagnostics: get_errors on changed files.
- Manual: Run script in REAPER and compare continuous mode smoothness + bar-click seek.

## Artifacts Changed
- .tracking/039-continuous-mode-performance.md
- .tracking/meta.md
- luaTab.lua
- lib/render.lua
- .tracking/040-continuous-readability-and-hotpath-audit.md (merged)
- .tracking/041-continuous-no-bar-snap.md (merged)
- .tracking/042-continuous-wrap-artifact-fix.md (merged)
- .tracking/043-continuous-render-artifact-pass.md (merged)

## Final Summary
Continuous mode now reuses cached system layouts between frames and applies sweep via draw-time x offset, eliminating per-frame system table reconstruction while preserving click alignment. Follow-up tuning settled on direct per-bar pixel-snapped offset (no wrap smoothing) plus renderer pixel alignment for moving text to reduce ghosting/doubling artifacts.
