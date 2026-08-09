-- Read last by caelestia's hyprland.lua, so anything here wins over the whole
-- of its config. For what belongs to this laptop rather than to the rice.

-- No AQ_DRM_DEVICES here on purpose. Pinning the GPUs by /dev/dri/cardN is a
-- trap on this laptop: the kernel numbers them in probe order, i915 and nvidia
-- race for it, and the numbers do move — card0 is simply gone now, the pair is
-- card1 (nvidia) and card2 (i915). A list naming a card that no longer exists
-- costs you the whole session, because the panel is on the i915 (card2-eDP-1
-- is the only connected output; the nvidia card has a disconnected DP-1) and a
-- list without it leaves aquamarine nothing to light up. Unset, it enumerates
-- every card and finds the panel wherever it landed. by-path would be stable
-- but cannot be used: the list is colon-separated and PCI paths are full of
-- colons.

-- Hyprland is started from start-hyprland, not a login shell, so it never
-- sources .zshrc and its PATH has no ~/.local/bin. Anything the launcher runs
-- out of the scripts package would fail with "not found" and no visible error.
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. os.getenv("PATH"))

-- Upstream hard-codes a us layout.
hl.config({ input = { kb_layout = "tr" } })

-- No QT_QPA_PLATFORMTHEME override here: caelestia's env.lua sets it to
-- qtengine and that is now installed, so Qt apps take their palette from
-- ~/.config/qtengine/caelestia.colors and follow the wallpaper with everything
-- else. It is worth knowing how this fails, because it fails quietly: qtengine
-- and darkly-bin come from caelestia's own manifest, which we do not run, and
-- Qt reports nothing when the platform theme it was told to load is missing --
-- it falls back to none at all, which is the default *light* palette. If the
-- Qt apps ever come up white on this desktop, that is the first thing to check:
--   ls /usr/lib/qt6/plugins/platformthemes/   # libqt6engine-plugin.so
--   paru -S qtengine darkly-bin frameworkintegration papirus-folders

-- The internal panel, pinned. caelestia's catch-all rule already says scale 1,
-- so this changes nothing today; it is here as the knob, and so that plugging
-- in an external monitor cannot drag this one along with it. Do NOT leave the
-- scale on "auto": Hyprland reads 1920x1080 on a 14" panel as wanting 1.5, and
-- that is the huge everything you get on a config that never set it.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Hardware cursors, forced on. Both of these default to 2, "decide for me", and
-- on this machine the guess comes out wrong: two GPUs are present, so Hyprland
-- takes the cautious route and draws the cursor into the frame itself. That is
-- the expensive way to move a mouse — a software cursor damages the region it
-- passes over, and damaged regions with blur under them get re-blurred, at
-- 144 Hz, for as long as your hand is moving. The caution is not needed here:
-- the panel and the renderer are both the Intel card, so the cursor buffer
-- never has to cross to the other GPU. Check it took with
--   hyprctl -j monitors | grep hardwareCursorsInUse
-- and if the cursor ever goes invisible or leaves a trail, drop both back to 2.
hl.config({
    cursor = {
        no_hardware_cursors = 0,
        use_cpu_buffer      = 0,
    },
})

-- ─── animations, sped up ─────────────────────────────────────────────────────
-- Hyprland measures animation speed in deciseconds, so upstream's windowsMove
-- at 6 is six tenths of a second of sliding before a window is where you told
-- it to go. Fine on a demo, long once you are actually working — and every one
-- of those frames is a blurred, rounded, shadowed window being recomposited.
--
-- Only the speeds change here. The curves are caelestia's own, registered by
-- its animations.lua before this file runs, so the motion keeps its character
-- and only gets out of the way sooner. Roughly 40% quicker across the board.
--
-- This is half the job: the shell's own animations (bar, launcher, sidebar,
-- notifications) are Qt, not Hyprland, and live behind
-- appearance.anim.durations.scale in shell.json.
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3,   bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,   bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove",enabled = true, speed = 3.5, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3,   bezier = "standard" })

hl.animation({ leaf = "layersIn",   enabled = true, speed = 3,   bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 2.5, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 3,   bezier = "standard" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 3,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 15%",
})

hl.animation({ leaf = "fade",    enabled = true, speed = 3.5, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3.5, bezier = "standard" })
hl.animation({ leaf = "border",  enabled = true, speed = 3,   bezier = "standard" })

-- ─── keybinds these dotfiles keep ────────────────────────────────────────────
-- Bindings from the Rainy-Night config that caelestia has no equivalent for, or
-- moved somewhere the hands here do not go. Everything below lands on a combo
-- caelestia leaves free, so nothing of its own is shadowed.
local vars = require("variables")
local fn   = require("utils.functions")

-- The other half of alt-tab. caelestia already binds ALT+TAB and it cycles
-- windows on the current workspace, which is what a compositor does by itself;
-- what these dotfiles add on top is the cross-workspace picker, and caelestia
-- has no equivalent. SUPER+TAB is where it lived before and is free here.
-- Found on PATH thanks to the ~/.local/bin line above.
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("window-switch"))

-- Terminal and browser on their old keys, in addition to caelestia's SUPER+T
-- and SUPER+Q rather than instead of them. Read out of variables so there is
-- still one place that decides which terminal and which browser: change it in
-- hypr-vars.lua and both keys follow.
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(vars.terminal))
hl.bind("SUPER + B", hl.dsp.exec_cmd(vars.browser))

-- Force kill, for the window that stopped answering. Deliberately the same
-- three-key combo it had here before and not a bare SUPER+ESCAPE: this one
-- takes the process down without asking, so it should be awkward to hit.
hl.bind("SUPER + CTRL + ESCAPE", hl.dsp.window.kill())

-- A second key for the launcher, next to caelestia's bare SUPER tap rather than
-- instead of it. Not `hl.dsp.global("caelestia:launcher")`, which is what the
-- tap uses: that global is handled on *release* (Shortcuts.qml), and on a
-- modifier+key combination the release only reports cleanly if you lift the key
-- before the modifier. Lift ALT first and nothing happens. That is the whole
-- story behind "ALT+SPACE works sometimes".
--
-- The shell's IPC has the same toggle with no release in it — `drawers list`
-- names them: bar, osd, session, launcher, dashboard — so this fires on the
-- press and does not care about finger order.
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("qs -c caelestia ipc call drawers toggle launcher"))

-- The clipboard panel from imperative-dots, running as its own quickshell
-- config out of ~/.config/quickshell/clipboard (this same package). caelestia's
-- own SUPER+V is fuzzel with cliphist piped into it, which cannot show an image
-- it has in its history; this one lays the entries out in a grid and renders
-- the images.
--
-- A toggle out of two exit codes: `qs kill` returns 0 when it killed something
-- and 255 when there was nothing to kill, so the second half only runs when the
-- panel was not already up. The panel closes itself on Escape and on picking an
-- entry, so this is only for pressing SUPER+V twice.
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs kill -c clipboard || qs -c clipboard"))

-- Move the window to a workspace. caelestia puts this on SUPER+ALT+number and
-- leaves SUPER+SHIFT+number free; the hands here go to SHIFT. Built from
-- caelestia's own wsaction so it obeys the same workspace-group arithmetic its
-- SUPER+ALT+number does — on the second block of ten, "3" means workspace 13,
-- not 3.
for i = 1, 10 do
    hl.bind("SUPER + SHIFT + " .. (i % 10), fn.wsaction("move", "", i))
end

hl.on("hyprland.start", function()
    -- caelestia's execs.lua starts polkit-gnome, which is not installed here.
    -- hyprpolkitagent is, and is a systemd user unit like everywhere else in
    -- these dotfiles.
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Nobody else watches the .desktop directories outside a Plasma session,
    -- so ksycoca — the cache every KService lookup reads — drifts out of date
    -- after a package install and Dolphin's "Open With" menu comes back empty.
    hl.exec_cmd("kded6")

    -- logind sets XDG_SESSION_CLASS and the compositor inherits it, but the
    -- systemd --user manager starts before any of that and is only ever handed
    -- WAYLAND_DISPLAY and XDG_CURRENT_DESKTOP. Units gated on it are skipped
    -- forever, and localsearch-3.service is gated on exactly it
    -- (ConditionEnvironment=XDG_SESSION_CLASS=user), so Nautilus asked for the
    -- indexer, systemd logged "unmet condition check" and its Recent and search
    -- came back empty with nothing visible to explain why. Same line as
    -- hypr/hyprland.conf.
    hl.exec_cmd("systemctl --user import-environment XDG_SESSION_CLASS XDG_SESSION_TYPE")
end)
