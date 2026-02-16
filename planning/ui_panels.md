# UI Panels Architecture

This document describes the panel framework used by luaTab to keep ImGui Begin/End pairs balanced while preserving docking and floating behavior.

## Goals

- Every top-level window is created through lib/ui_panels.lua.
- Docking and tabbing are allowed without breaking Begin/End pairing.
- Panels are toggleable via shared state with open references.
- Modals are reserved for atomic, blocking flows only.

## Core Rules

1) In ReaImGui, call End() only when Begin() returns visible=true.
2) This avoids End() overrun when a dock tab is hidden or collapsed.
3) Panels may be turned off by setting open_ref.value = false. When off, Begin is not called.
4) Modals are only for atomic, blocking tasks (confirmation, save-as). Settings and fretboard are panels.

## Panel State Pattern

Store open flags as tables so they can be passed by reference:

```lua
state.panels = {
  main = { value = true },
  fretboard = { value = true },
  settings = { value = false },
}
```

Use Panels.menu_toggle to bind menu items to these flags.

## Main Window + Dockspace

The main window hosts the dockspace and menu bar. Panels dock inside it:

```lua
Panels.window(ctx, state.panels.main, "luaTab", main_flags, function(ctx)
  draw_menu(ctx, state)
  Panels.dockspace(ctx, "luaTabDock")
end)
```

## Creating a New Panel

1) Add an open flag in state.panels.
2) Add a menu toggle to open/close it.
3) Call Panels.window with a draw function.

Example:

```lua
Panels.window(ctx, state.panels.midi, "MIDI", 0, function(ctx)
  -- draw MIDI panel content
end)
```

## Modal Usage

Use popups only for atomic, blocking operations:

- Save preset
- Reset confirmation

Avoid using a modal for settings, fretboard, or any panel that should dock.

## Scope Helpers

Use the Panels wrappers for Begin/End pairs in menus, tabs, children, and tables:

- Panels.menu_bar()
- Panels.menu()
- Panels.tab_bar()
- Panels.tab_item()
- Panels.child()
- Panels.table()

## Debugging

During development, Panels.DEBUG can be enabled and Panels.end_frame_check() called each frame to detect imbalances.
