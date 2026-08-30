-- Personal input overrides for Hyprland
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout = "tr",
    follow_mouse = 1,
    repeat_delay = 250,
    repeat_rate = 40,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },

  binds = {
    workspace_back_and_forth = true,
  },

  cursor = {
    no_hardware_cursors = false,
  },
})

-- 4-finger horizontal swipe for workspace navigation
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
