-- Personal keybinding overrides for Hyprland (Lua)
-- Mirrors dotfiles/hypr/.config/hypr/hyprland.conf keybindings

-- Applications & Menus
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

-- Window Management
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", "killactive")

o.bind("SUPER + CTRL + ESCAPE", "Force kill window", "forcekillactive")

hl.unbind("SUPER + F")
o.bind("SUPER + F", "Fullscreen", "fullscreen")

o.bind("SUPER + X", "Maximize window", "fullscreen 1")

hl.unbind("SUPER + T")
o.bind("SUPER + T", "Toggle floating", "togglefloating")

hl.unbind("SUPER + L")
o.bind("SUPER + L", "Lock screen", "hyprlock")

o.bind("SUPER + F1", "Hotkeys cheat sheet", "hotkeys")
o.bind("SUPER + SHIFT + P", "Power profile", "power-profile")
o.bind("SUPER + SHIFT + H", "Quit Hyprland menu", "sh -c '[ \"$(printf \"No\\nYes\" | fuzzel --dmenu --prompt \"Quit Hyprland? \" --lines 2)\" = Yes ] && hyprctl dispatch exit'")

-- Window Switching
o.bind("SUPER + Q", "Window switcher", "window-switch")
o.bind("SUPER + TAB", "Window switcher", "window-switch")

-- Scratchpad
hl.unbind("SUPER + S")
o.bind("SUPER + S", "Toggle Scratchpad", "togglespecialworkspace scratch")
o.bind("SUPER + SHIFT + RETURN", "Move to Scratchpad", "movetoworkspacesilent special:scratch")

-- Floating & Group Controls
o.bind("SUPER + P", "Pin window", "pin")
o.bind("SUPER + SHIFT + C", "Center window", "centerwindow")
o.bind("SUPER + U", "Focus urgent or last", "focusurgentorlast")
o.bind("SUPER + Z", "Toggle group", "togglegroup")
o.bind("SUPER + SHIFT + Z", "Change group active", "changegroupactive f")
o.bind("SUPER + CTRL + Z", "Move out of group", "moveoutofgroup")
o.bind("SUPER + ALT + Z", "Move into group", "moveintogroup r")
o.bind("SUPER + A", "Bring active window to top", "bringactivetotop")

-- Screenshots
o.bind("PRINT", "Screenshot full", "sh -c 'grim - | satty -f -'")
o.bind("SUPER + SHIFT + S", "Screenshot select region", "sh -c 'grim -g \"$(slurp)\" - | satty -f -'")
o.bind("SUPER + PRINT", "Screenshot active window", "sh -c 'grim -g \"$(hyprctl activewindow -j | jq -r \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\")\" - | satty -f -'")

-- Arrow Keys: Focus & Window Movement
o.bind("SUPER + LEFT", "Focus left", "movefocus l")
o.bind("SUPER + RIGHT", "Focus right", "movefocus r")
o.bind("SUPER + UP", "Focus up", "movefocus u")
o.bind("SUPER + DOWN", "Focus down", "movefocus d")

o.bind("SUPER + SHIFT + LEFT", "Move window left", "movewindow l")
o.bind("SUPER + SHIFT + RIGHT", "Move window right", "movewindow r")
o.bind("SUPER + SHIFT + UP", "Move window up", "movewindow u")
o.bind("SUPER + SHIFT + DOWN", "Move window down", "movewindow d")

-- Arrow Keys: Workspaces
o.bind("SUPER + CTRL + LEFT", "Previous workspace", "workspace e-1")
o.bind("SUPER + CTRL + RIGHT", "Next workspace", "workspace e+1")
o.bind("SUPER + CTRL + UP", "Previous workspace", "workspace e-1")
o.bind("SUPER + CTRL + DOWN", "Next workspace", "workspace e+1")

o.bind("SUPER + CTRL + SHIFT + LEFT", "Move window to prev workspace", "movetoworkspace e-1")
o.bind("SUPER + CTRL + SHIFT + RIGHT", "Move window to next workspace", "movetoworkspace e+1")
o.bind("SUPER + CTRL + SHIFT + UP", "Move window to prev workspace", "movetoworkspace e-1")
o.bind("SUPER + CTRL + SHIFT + DOWN", "Move window to next workspace", "movetoworkspace e+1")

-- Arrow Keys: Resize & Swap
o.bind("SUPER + ALT + LEFT", "Resize left", "resizeactive -60 0")
o.bind("SUPER + ALT + RIGHT", "Resize right", "resizeactive 60 0")
o.bind("SUPER + ALT + UP", "Resize up", "resizeactive 0 -60")
o.bind("SUPER + ALT + DOWN", "Resize down", "resizeactive 0 60")

o.bind("SUPER + ALT + SHIFT + LEFT", "Swap window left", "swapwindow l")
o.bind("SUPER + ALT + SHIFT + RIGHT", "Swap window right", "swapwindow r")
o.bind("SUPER + ALT + SHIFT + UP", "Move to workspace above", "movetoworkspace e-1")
o.bind("SUPER + ALT + SHIFT + DOWN", "Move to workspace below", "movetoworkspace e+1")

-- Monitors
o.bind("SUPER + COMMA", "Focus left monitor", "focusmonitor l")
o.bind("SUPER + PERIOD", "Focus right monitor", "focusmonitor r")
o.bind("SUPER + SHIFT + COMMA", "Move workspace to left monitor", "movecurrentworkspacetomonitor l")
o.bind("SUPER + SHIFT + PERIOD", "Move workspace to right monitor", "movecurrentworkspacetomonitor r")
o.bind("SUPER + ALT + COMMA", "Move window to left monitor", "movewindow mon:l")
o.bind("SUPER + ALT + PERIOD", "Move window to right monitor", "movewindow mon:r")

-- Media & Audio
o.bind("SUPER + SPACE", "Play / Pause media", "playerctl play-pause")
