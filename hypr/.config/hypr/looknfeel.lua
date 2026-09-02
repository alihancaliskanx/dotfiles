-- Personal look and feel overrides for Hyprland

-- Qt / KDE application theming (Dolphin, Kate, Ark, etc.)
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland:KDE")
hl.env("XDG_MENU_PREFIX", "plasma-")

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 1,
  },

  dwindle = {
    preserve_split = true,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    background_color = "rgb(101010)",
  },
})

-- ─── Window Rules ────────────────────────────────────────────────────────────
o.window("pavucontrol", { float = true })
o.window("nm-connection-editor", { float = true })
o.window("blueman-manager", { float = true })
o.window("org.kde.polkit-kde-authentication-agent-1", { float = true })
o.window("xfreerdp", { tile = true })
o.window({ title = "^(Open File|Save File|Save As|Open Folder)$" }, { float = true })
o.window({ title = "^(Picture-in-Picture)$" }, { float = true, pin = true, size = "480 270" })
