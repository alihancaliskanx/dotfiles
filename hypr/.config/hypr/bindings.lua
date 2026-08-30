-- Personal keybinding overrides for Hyprland (Lua)
-- Correct Omarchy Lua dispatchers and personal shortcuts

-- ─── Applications & Launchers ───────────────────────────────────────────────
hl.unbind("SUPER + RETURN")
o.bind("SUPER + RETURN", "Terminal (Alacritty)", "alacritty")

hl.unbind("ALT + SPACE")
o.bind("ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")

hl.unbind("SUPER + ALT + SPACE")
o.bind("SUPER + ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")

hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle top bar", "pkill -SIGUSR1 waybar")

hl.unbind("SUPER + V")
o.bind("SUPER + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

o.bind("SUPER + B", "Web Browser", "gtk-launch $(xdg-settings get default-web-browser)")
o.bind("SUPER + E", "File Manager (Dolphin)", "xdg-open ~")
o.bind("SUPER + M", "Spotify", "flatpak run com.spotify.Client")
o.bind("CTRL + ALT + SPACE", "Claude Desktop", "claude-desktop")

-- ─── Window Management ──────────────────────────────────────────────────────
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", hl.dsp.window.close())

o.bind("SUPER + CTRL + ESCAPE", "Force kill window", function() hl.dispatch("forcekillactive") end)

hl.unbind("SUPER + F")
o.bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

o.bind("SUPER + X", "Maximize window", hl.dsp.window.fullscreen({ mode = "maximized" }))

hl.unbind("SUPER + T")
o.bind("SUPER + T", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))

hl.unbind("SUPER + L")
o.bind("SUPER + L", "Lock screen", "hyprlock")

o.bind("SUPER + F1", "Hotkeys cheat sheet", "hotkeys")
o.bind("SUPER + SHIFT + P", "Power profile", "power-profile")
o.bind("SUPER + SHIFT + H", "Quit Hyprland menu", "sh -c '[ \"$(printf \"No\\nYes\" | fuzzel --dmenu --prompt \"Quit Hyprland? \" --lines 2)\" = Yes ] && hyprctl dispatch exit'")

-- ─── Window Switching ───────────────────────────────────────────────────────
o.bind("SUPER + Q", "Window switcher", "window-switch")
o.bind("SUPER + TAB", "Window switcher", "window-switch")

-- ─── Scratchpad ─────────────────────────────────────────────────────────────
hl.unbind("SUPER + S")
o.bind("SUPER + S", "Toggle Scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + RETURN", "Move to Scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- ─── Floating, Pin & Groups ─────────────────────────────────────────────────
o.bind("SUPER + P", "Pin window", hl.dsp.window.pin())
o.bind("SUPER + SHIFT + C", "Center window", function() hl.dispatch("centerwindow") end)
o.bind("SUPER + U", "Focus urgent or last", function() hl.dispatch("focusurgentorlast") end)
o.bind("SUPER + Z", "Toggle group", hl.dsp.group.toggle())
o.bind("SUPER + SHIFT + Z", "Change group active", hl.dsp.group.next())
o.bind("SUPER + CTRL + Z", "Move out of group", hl.dsp.window.move({ out_of_group = true }))
o.bind("SUPER + ALT + Z", "Move into group", hl.dsp.window.move({ into_group = "r" }))
o.bind("SUPER + A", "Bring active window to top", hl.dsp.window.bring_to_top())

-- ─── Screenshots ────────────────────────────────────────────────────────────
o.bind("PRINT", "Screenshot full", "sh -c 'grim - | satty -f -'")
o.bind("SUPER + SHIFT + S", "Screenshot select region", "sh -c 'grim -g \"$(slurp)\" - | satty -f -'")
o.bind("SUPER + PRINT", "Screenshot active window", "sh -c 'grim -g \"$(hyprctl activewindow -j | jq -r \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\")\" - | satty -f -'")

-- ─── Arrow Keys: Focus & Movement ───────────────────────────────────────────
o.bind("SUPER + LEFT", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + RIGHT", "Focus right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + UP", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + DOWN", "Focus down", hl.dsp.focus({ direction = "d" }))

o.bind("SUPER + SHIFT + LEFT", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + RIGHT", "Move window right", hl.dsp.window.move({ direction = "r" }))
o.bind("SUPER + SHIFT + UP", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + DOWN", "Move window down", hl.dsp.window.move({ direction = "d" }))

-- ─── Arrow Keys: Workspaces ─────────────────────────────────────────────────
o.bind("SUPER + CTRL + LEFT", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + RIGHT", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + CTRL + UP", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + DOWN", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))

o.bind("SUPER + CTRL + SHIFT + LEFT", "Move window to prev workspace", hl.dsp.window.move({ workspace = "e-1" }))
o.bind("SUPER + CTRL + SHIFT + RIGHT", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1" }))
o.bind("SUPER + CTRL + SHIFT + UP", "Move window to prev workspace", hl.dsp.window.move({ workspace = "e-1" }))
o.bind("SUPER + CTRL + SHIFT + DOWN", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1" }))

-- ─── Arrow Keys: Resize & Swap ──────────────────────────────────────────────
o.bind("SUPER + ALT + LEFT", "Resize left", hl.dsp.window.resize({ x = -60, y = 0, relative = true }))
o.bind("SUPER + ALT + RIGHT", "Resize right", hl.dsp.window.resize({ x = 60, y = 0, relative = true }))
o.bind("SUPER + ALT + UP", "Resize up", hl.dsp.window.resize({ x = 0, y = -60, relative = true }))
o.bind("SUPER + ALT + DOWN", "Resize down", hl.dsp.window.resize({ x = 0, y = 60, relative = true }))

o.bind("SUPER + ALT + SHIFT + LEFT", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + ALT + SHIFT + RIGHT", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- ─── Monitors ───────────────────────────────────────────────────────────────
o.bind("SUPER + COMMA", "Focus left monitor", hl.dsp.focus({ monitor = "l" }))
o.bind("SUPER + PERIOD", "Focus right monitor", hl.dsp.focus({ monitor = "r" }))
o.bind("SUPER + SHIFT + COMMA", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + PERIOD", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))

-- ─── Media & Audio ──────────────────────────────────────────────────────────
o.bind("SUPER + SPACE", "Play / Pause media", "playerctl play-pause")
