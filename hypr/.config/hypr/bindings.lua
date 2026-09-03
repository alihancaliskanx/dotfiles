-- ═════════════════════════════════════════════════════════════════════════════
-- UNIFIED HYPRLAND BINDINGS (Dotfiles + Omarchy Full Merge)
-- All Omarchy features and personal custom workflows merged with zero conflicts
-- ═════════════════════════════════════════════════════════════════════════════

-- ─── 1. Applications & Launchers ─────────────────────────────────────────────
o.bind("SUPER + RETURN", "Terminal (Alacritty)", "alacritty")
o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle")
o.bind("ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + SHIFT + SPACE", "Toggle top bar", "pkill -SIGUSR1 waybar || omarchy-toggle-bar")

-- Web Browsers
o.bind("SUPER + B", "Web Browser (Default)", "gtk-launch $(xdg-settings get default-web-browser)")
o.bind("SUPER + SHIFT + B", "Web Browser (Default)", { omarchy = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Web Browser (Private)", { omarchy = "browser --private" })

-- File Managers
o.bind("SUPER + E", "File Manager (Dolphin)", "xdg-open ~")
o.bind("SUPER + SHIFT + F", "File Manager (Nautilus)", { omarchy = "nautilus" })
o.bind("SUPER + ALT + SHIFT + F", "File Manager (cwd)", { omarchy = "nautilus-cwd" })

-- Terminal multiplexers & tools
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + SHIFT + N", "Editor (Neovim)", { omarchy = "editor" })
o.bind("CTRL + ALT + SPACE", "Claude Desktop", "claude-desktop")

-- Music & Media Apps
o.bind("SUPER + M", "Spotify", "flatpak run com.spotify.Client")
o.bind("SUPER + SHIFT + M", "Music (Spotify)", { omarchy = "spotify" })
o.bind("SUPER + SHIFT + ALT + M", "Music TUI (cliamp)", { tui = "cliamp", focus = true })

-- ─── 2. Web Apps & Services (Omarchy Ecosystem) ──────────────────────────────
o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
o.bind("SUPER + SHIFT + X", "X (Twitter)", { webapp = "https://x.com/" })
o.bind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })
o.bind("SUPER + SHIFT + SLASH", "1Password", { omarchy = "1password" })
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })
o.bind("SUPER + SHIFT + G", "Signal", { omarchy = "signal" })
o.bind("SUPER + SHIFT + D", "Docker TUI", { tui = "omarchy-launch-docker-tui" })
o.bind("SUPER + SHIFT + E", "Hey Email", { webapp = "https://app.hey.com" })
o.bind("SUPER + SHIFT + ALT + E", "New Email", { webapp = "https://app.hey.com/messages/new?display=standalone&new_window=true" })
o.bind("SUPER + ALT + SHIFT + C", "Hey Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
o.bind("SUPER + ALT + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
o.bind("SUPER + ALT + SHIFT + S", "Google Maps", { webapp = "https://maps.google.com/", focus = true })

-- ─── 3. Window Management & Session ──────────────────────────────────────────
o.bind("SUPER + W", "Close window", hl.dsp.window.close())
o.bind("SUPER + CTRL + ESCAPE", "Force kill window", "hyprctl kill")
o.bind("SUPER + CTRL + ALT + DELETE", "Close all windows", "omarchy-hyprland-window-close-all")
o.bind("SUPER + ALT + W", "Close all windows", "omarchy-hyprland-window-close-all")
o.bind("SUPER + CTRL + SHIFT + W", "Stop Windows VM", "$HOME/.local/bin/windows-vm-stop.sh")

o.bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + X", "Maximize window", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + ALT + F", "Maximize window (Full width)", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + CTRL + F", "Tiled fullscreen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("SUPER + T", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + P", "Pin window", hl.dsp.window.pin())
o.bind("SUPER + ALT + P", "Pseudo window", hl.dsp.window.pseudo())
o.bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")

o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + C", "Center window", hl.dsp.layout("centerwindow"))
o.bind("SUPER + U", "Focus urgent or last", hl.dsp.layout("focusurgentorlast"))
o.bind("SUPER + A", "Bring active window to top", hl.dsp.window.bring_to_top())

o.bind("SUPER + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + CTRL + L", "Lock system", "omarchy-system-lock")
o.bind("SUPER + F1", "Hotkeys cheat sheet", "hotkeys")
o.bind("SUPER + K", "Keybindings cheat sheet", "omarchy-menu-keybindings")
o.bind("SUPER + ALT + K", "Tmux keybindings", "omarchy-menu-tmux-keybindings")
o.bind("SUPER + CTRL + K", "Herdr keybindings", "omarchy-menu-herdr-keybindings")
o.bind("SUPER + SHIFT + P", "Power profile", "power-profile")

local quit_cmd = "sh -c '[ \"$(printf \"No\\nYes\" | fuzzel --dmenu --prompt \"Quit Hyprland? \" --lines 2)\" = Yes ] && hyprctl dispatch exit'"
o.bind("SUPER + SHIFT + H", "Quit Hyprland menu", quit_cmd)
o.bind("CTRL + ALT + DELETE", "Quit Hyprland menu", quit_cmd)

-- Window width presets
o.bind("SUPER + ALT + Home", "Save window width", "omarchy-hyprland-window-width save")
o.bind("SUPER + Home", "Restore window width", "omarchy-hyprland-window-width restore")

-- Appearance toggles
o.bind("SUPER + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")
o.bind("SUPER + SHIFT + BACKSPACE", "Toggle window gaps", "omarchy-hyprland-window-gaps-toggle")
o.bind("SUPER + CTRL + BACKSPACE", "Toggle single-window square aspect", "omarchy-hyprland-window-single-square-aspect-toggle")

-- ─── 4. Window Switching & Navigation ────────────────────────────────────────
o.bind("SUPER + Q", "Window switcher", "window-switch")
o.bind("SUPER + TAB", "Window switcher", "window-switch")

o.bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))

o.bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

-- ─── 5. Scratchpad ───────────────────────────────────────────────────────────
o.bind("SUPER + S", "Toggle Scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + SHIFT + RETURN", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- ─── 6. Groups & Stacking ────────────────────────────────────────────────────
o.bind("SUPER + Z", "Toggle group", hl.dsp.group.toggle())
o.bind("SUPER + G", "Toggle group", hl.dsp.group.toggle())
o.bind("SUPER + SHIFT + Z", "Change group active", hl.dsp.group.next())
o.bind("SUPER + CTRL + Z", "Move out of group", hl.dsp.window.move({ out_of_group = true }))
o.bind("SUPER + ALT + G", "Move out of group", hl.dsp.window.move({ out_of_group = true }))
o.bind("SUPER + ALT + Z", "Move into group", hl.dsp.window.move({ into_group = "r" }))

o.bind("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())
o.bind("SUPER + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())

for index = 1, 5 do
  o.bind("SUPER + ALT + code:" .. tostring(index + 9), "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end

-- ─── 7. Screenshots, Recording & OCR ─────────────────────────────────────────
o.bind("PRINT", "Screenshot full", "sh -c 'grim - | tensaku -f -'")
o.bind("code:107", "Screenshot full", "sh -c 'grim - | tensaku -f -'")
o.bind("SUPER + SHIFT + S", "Screenshot select region", "sh -c 'grim -g \"$(slurp)\" - | tensaku -f -'")
o.bind("SUPER + PRINT", "Screenshot active window", "sh -c 'grim -g \"$(hyprctl activewindow -j | jq -r \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\")\" - | tensaku -f -'")
o.bind("SUPER + code:107", "Screenshot active window", "sh -c 'grim -g \"$(hyprctl activewindow -j | jq -r \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\")\" - | tensaku -f -'")
o.bind("SUPER + ALT + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + SHIFT + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + CTRL + PRINT", "Extract text (OCR)", "omarchy-capture-text")
o.bind("ALT + PRINT", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")

-- ─── 8. Arrow Keys: Focus & Movement ─────────────────────────────────────────
o.bind("SUPER + LEFT", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + RIGHT", "Focus right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + UP", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + DOWN", "Focus down", hl.dsp.focus({ direction = "d" }))

o.bind("SUPER + SHIFT + LEFT", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + RIGHT", "Move window right", hl.dsp.window.move({ direction = "r" }))
o.bind("SUPER + SHIFT + UP", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + DOWN", "Move window down", hl.dsp.window.move({ direction = "d" }))

-- Arrow Keys: Workspaces
o.bind("SUPER + CTRL + LEFT", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + RIGHT", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + CTRL + UP", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + DOWN", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))

o.bind("SUPER + CTRL + SHIFT + LEFT", "Move window to prev workspace", hl.dsp.window.move({ workspace = "e-1" }))
o.bind("SUPER + CTRL + SHIFT + RIGHT", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1" }))
o.bind("SUPER + CTRL + SHIFT + UP", "Move window to prev workspace", hl.dsp.window.move({ workspace = "e-1" }))
o.bind("SUPER + CTRL + SHIFT + DOWN", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1" }))

-- Arrow Keys: Resize & Swap
o.bind("SUPER + ALT + LEFT", "Resize left", hl.dsp.window.resize({ x = -60, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + ALT + RIGHT", "Resize right", hl.dsp.window.resize({ x = 60, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + ALT + UP", "Resize up", hl.dsp.window.resize({ x = 0, y = -60, relative = true }), { repeating = true })
o.bind("SUPER + ALT + DOWN", "Resize down", hl.dsp.window.resize({ x = 0, y = 60, relative = true }), { repeating = true })

o.bind("SUPER + ALT + SHIFT + LEFT", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + ALT + SHIFT + RIGHT", "Swap window right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + ALT + SHIFT + UP", "Move window to prev workspace", hl.dsp.window.move({ workspace = "e-1" }))
o.bind("SUPER + ALT + SHIFT + DOWN", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1" }))

-- Arrow Keys: Move Into Group
o.bind("SUPER + CTRL + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + CTRL + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
o.bind("SUPER + CTRL + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + CTRL + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))

-- Granular resize shortcuts
o.bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- ─── 9. Monitors & Multi-Display ─────────────────────────────────────────────
o.bind("SUPER + COMMA", "Focus left monitor", hl.dsp.focus({ monitor = "l" }))
o.bind("SUPER + PERIOD", "Focus right monitor", hl.dsp.focus({ monitor = "r" }))
o.bind("SUPER + SHIFT + COMMA", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + PERIOD", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
o.bind("SUPER + ALT + COMMA", "Move window to left monitor", hl.dsp.window.move({ monitor = "l" }))
o.bind("SUPER + ALT + PERIOD", "Move window to right monitor", hl.dsp.window.move({ monitor = "r" }))

o.bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
o.bind("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

o.bind("SUPER + SLASH", "Monitor scaling up", "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + SLASH", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")
o.bind("SUPER + CTRL + Delete", "Toggle laptop display", "omarchy-hyprland-monitor-internal toggle")
o.bind("SUPER + CTRL + ALT + Delete", "Toggle laptop display mirroring", "omarchy-hyprland-monitor-internal-mirror toggle")

-- ─── 10. Workspaces (1-10) & Mouse ───────────────────────────────────────────
for ws = 1, 10 do
  local key = tostring(ws % 10)
  o.bind("SUPER + " .. key, "Switch to workspace " .. ws, hl.dsp.focus({ workspace = tostring(ws) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. ws, hl.dsp.window.move({ workspace = tostring(ws) }))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. ws, hl.dsp.window.move({ workspace = tostring(ws), follow = false }))
end

o.bind("SUPER + mouse_down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + mouse_up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- ─── 11. Media, Hardware & Volume Controls ───────────────────────────────────
o.bind("XF86AudioPlay", "Play media", "playerctl play-pause", { locked = true })
o.bind("XF86AudioPause", "Pause media", "playerctl play-pause", { locked = true })
o.bind("XF86AudioNext", "Next track", "playerctl next", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "playerctl previous", { locked = true })

o.bind("XF86AudioRaiseVolume", "Volume up", "swayosd-client --output-volume raise --max-volume 150 || /home/sups/.local/bin/omarchy-audio-output-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "swayosd-client --output-volume lower --max-volume 150 || /home/sups/.local/bin/omarchy-audio-output-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute audio", "swayosd-client --output-volume mute-toggle || /home/sups/.local/bin/omarchy-audio-output-volume mute-toggle", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", "swayosd-client --input-volume mute-toggle || omarchy-audio-input-mute", { locked = true })

o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise (+1%)", "/home/sups/.local/bin/omarchy-audio-output-volume +1", { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise (-1%)", "/home/sups/.local/bin/omarchy-audio-output-volume -1", { locked = true, repeating = true })
o.bind("SHIFT + XF86AudioMute", "Switch audio output", "~/.local/bin/omarchy-audio-output-switch", { locked = true })
o.bind("SHIFT + XF86AudioPause", "Switch media source", "omarchy-audio-source-switch", { locked = true })
o.bind("SHIFT + XF86AudioPlay", "Switch media source", "omarchy-audio-source-switch", { locked = true })

-- Brightness Controls
o.bind("XF86MonBrightnessUp", "Brightness up", "swayosd-client --brightness raise || omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "swayosd-client --brightness lower || omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise (+1%)", "omarchy-brightness-display +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise (-1%)", "omarchy-brightness-display 1%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "omarchy-brightness-display 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "omarchy-brightness-display 1%", { locked = true, repeating = true })

-- Tuxedo RGB Keyboard backlight
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", "TuxedoRGBKeyboard.sh up", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", "TuxedoRGBKeyboard.sh down", { locked = true, repeating = true })
o.bind("XF86KbdLightOnOff", "Keyboard light toggle", "TuxedoRGBKeyboard.sh toggle", { locked = true })

-- Touchpad hardware controls
o.bind_toggle("XF86TouchpadToggle", "Toggle touchpad", "touchpad", { locked = true })
o.bind("XF86TouchpadOn", "Enable touchpad", "omarchy-toggle-touchpad on", { locked = true })
o.bind("XF86TouchpadOff", "Disable touchpad", "omarchy-toggle-touchpad off", { locked = true })

-- Keypad media & volume
o.bind("SUPER + KP_Add", "Volume up", "swayosd-client --output-volume raise --max-volume 150 || /home/sups/.local/bin/omarchy-audio-output-volume raise", { repeating = true })
o.bind("SUPER + KP_Subtract", "Volume down", "swayosd-client --output-volume lower --max-volume 150 || /home/sups/.local/bin/omarchy-audio-output-volume lower", { repeating = true })
o.bind("SUPER + CTRL + KP_Add", "Next track", "playerctl next")
o.bind("SUPER + CTRL + KP_Subtract", "Previous track", "playerctl previous")

-- ─── 12. Omarchy Utilities, Menus & Panels ───────────────────────────────────
o.bind("SUPER + ESCAPE", "System menu", "omarchy-menu toggle system")
o.bind("XF86PowerOff", "Power menu", "omarchy-menu toggle system", { locked = true })
o.bind("SUPER + CTRL + SPACE", "Background switcher", "omarchy-menu toggle background")
o.bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", "omarchy-menu toggle theme")
o.bind("SUPER + CTRL + E", "Emojis", "omarchy-shell shell toggle omarchy.emojis")
o.bind("SUPER + CTRL + Q", "Calculator", "omacalc")
o.bind("XF86Calculator", "Calculator", "omacalc")
o.bind("SUPER + CTRL + S", "Share menu", "omarchy-menu toggle share")
o.bind("SUPER + CTRL + C", "Capture menu", "omarchy-menu toggle capture")
o.bind("SUPER + CTRL + O", "Toggle menu", "omarchy-menu toggle toggle")
o.bind("SUPER + CTRL + H", "Hardware menu", "omarchy-menu toggle hardware")

-- Quick Panels
o.bind("SUPER + CTRL + A", "Audio panel", "omarchy-shell shell toggle omarchy.audio")
o.bind("SUPER + CTRL + B", "Bluetooth panel", "omarchy-shell shell toggle omarchy.bluetooth")
o.bind("SUPER + CTRL + D", "Display panel", "omarchy-shell shell toggle omarchy.monitor")
o.bind("SUPER + CTRL + ALT + D", "Calendar panel", "omarchy-shell shell toggle omarchy.clock")
o.bind("SUPER + CTRL + W", "Network panel", "omarchy-shell shell toggle omarchy.network")
o.bind("SUPER + CTRL + P", "Power panel", "omarchy-shell shell toggle omarchy.power")
o.bind("SUPER + CTRL + T", "Activity (btop)", { tui = "btop" })
o.bind("SUPER + SHIFT + CTRL + A", "AI Agent picker", "omarchy-agent --pick")

-- Right bar panel numbers 1-9
for panel = 1, 9 do
  o.bind(
    "SUPER + CTRL + code:" .. tostring(panel + 9),
    "Bar panel " .. panel,
    "omarchy-shell -q shell togglePanelAt right " .. panel
  )
end

-- Reminders & Notifications
o.bind("SUPER + CTRL + R", "Set reminder", "omarchy-menu toggle reminder-set")
o.bind("SUPER + CTRL + ALT + R", "Show reminders", "omarchy-reminder show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "omarchy-reminder clear")

o.bind("SUPER + CTRL + ALT + T", "Show time notification", "omarchy-notification-time")
o.bind("SUPER + CTRL + ALT + B", "Show battery notification", "omarchy-notification-battery")
o.bind("SUPER + CTRL + ALT + W", "Toggle weather notification", "omarchy-notification-weather")

-- Notification controls
o.bind_toggle("SUPER + CTRL + N", "Toggle nightlight", "nightlight")
o.bind_toggle("SUPER + CTRL + I", "Toggle locking on idle", "idle")
o.bind_toggle("SUPER + CTRL + COMMA", "Toggle silencing notifications", "notification-silencing")
o.bind("SUPER + SHIFT + ALT + COMMA", "Open notification history", "omarchy-shell notifications showHistory")

-- Transcode & Voxtype
o.bind("SUPER + CTRL + PERIOD", "Transcode menu", "omarchy-transcode")
if o.cmd_present("voxtype") then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "voxtype record toggle")
  o.bind("F9", "Start dictation (push-to-talk)", "voxtype record start")
  o.bind("F9", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
end

-- Zoom factor controls
o.bind("SUPER + CTRL + EQUAL", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
o.bind("SUPER + CTRL + MINUS", "Zoom out", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  if zoom > 1 then
    hl.config({ cursor = { zoom_factor = zoom - 1 } })
  end
end)
o.bind("SUPER + CTRL + 0", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Clipboard shortcuts
o.bind("SUPER + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard || sh -c 'cliphist decode \"$(cliphist list | fuzzel --dmenu)\" | wl-copy'")
o.bind("SUPER + CTRL + V", "Clear clipboard", "omarchy-shell shell call omarchy.clipboard confirmClearHistory '' && wl-copy -c && omarchy-shell osd show '{\"icon\":\"󰅍\",\"message\":\"Clipboard Cleared\"}'")

-- Hardware Lid Switch
o.bind("switch:on:Lid Switch", nil, "omarchy-system-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, "omarchy-hyprland-monitor-clamshell", { locked = true })

-- ─── 13. Dynamic Selection Capture Layer ─────────────────────────────────────
local selection_layers = 0
local selection_binds = {}

hl.on("layer.opened", function(layer)
  if layer.namespace == "selection" then
    selection_layers = selection_layers + 1
    if selection_layers == 1 then
      selection_binds = {
        hl.bind("RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-window"), { description = "Capture highlighted window" }),
        hl.bind("CTRL + RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-fullscreen"), { description = "Capture entire screen" }),
        hl.bind("TAB", hl.dsp.exec_cmd("omarchy-capture-region --select-window next"), { description = "Select next window to capture" }),
        hl.bind("CTRL + TAB", hl.dsp.exec_cmd("omarchy-capture-region --select-window prev"), { description = "Select previous window to capture" }),
      }
      for _, direction in ipairs({ "left", "right", "up", "down" }) do
        table.insert(
          selection_binds,
          hl.bind(direction:upper(), hl.dsp.exec_cmd("omarchy-capture-region --select-window " .. direction), { description = "Select window to capture" })
        )
      end
    end
  end
end)

hl.on("layer.closed", function(layer)
  if layer.namespace == "selection" and selection_layers > 0 then
    selection_layers = selection_layers - 1
    if selection_layers == 0 then
      for _, keybind in ipairs(selection_binds) do
        keybind:unbind()
      end
      selection_binds = {}
    end
  end
end)
