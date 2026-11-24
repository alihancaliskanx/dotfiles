-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable Omarchy default bindings to prevent conflicts with dotfiles shortcuts
_G.omarchy_default_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Load personal overrides from modular lua files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Runs after default.hypr.toggles so window-glassy.lua does not reset blur values.
local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local glassy_toggle = io.open(state_home .. "/omarchy/toggles/hypr/window-glassy.lua", "r")
if glassy_toggle then
  glassy_toggle:close()
  hl.config({
    decoration = {
      blur = {
        size = 6,
        passes = 3,
      },
    },
  })
  hl.layer_rule({
    match = { namespace = "^omarchy-dock-apps$" },
    blur = true,
    ignore_alpha = 0.3,
  })
  o.window("^discord$", { opacity = "0.85 0.80" })
  o.window("^org\\.kde\\.dolphin$", { opacity = "0.85 0.80" })
  o.window("^Spotify$", { opacity = "0.85 0.80" })
end

-- [key-visualizer] capture hook (managed by the plugin; safe to remove)
local kc_path = os.getenv("HOME") .. "/.config/omarchy/plugins/felixzsh.key-visualizer/key-visualizer.lua"
local kc_file = io.open(kc_path, "r")
if kc_file then kc_file:close(); dofile(kc_path) end
