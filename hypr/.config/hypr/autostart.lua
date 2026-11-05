-- Personal autostart processes for Hyprland

hl.on("hyprland.start", function()
  -- User services and environment daemons
  hl.exec_cmd("pam-kwallet-env")
  hl.exec_cmd("kded6")
  hl.exec_cmd("tuxedo-control-center --tray")
end)
