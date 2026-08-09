-- Overrides for caelestia's hypr/variables.lua, merged over it by
-- hyprland.lua before any of the config runs. Everything not named here keeps
-- upstream's value.
--
-- These are not taste, they are what this machine actually has. Upstream picks
-- the apps its own manifest installs (foot, thunar, vscodium, pwvucontrol) and
-- none of the four are on here; left alone, SUPER+T and SUPER+E would be dead
-- keys. See ~/Documents/Code/dotfiles/README.md, the caelestia rice.

return {
    terminal      = "alacritty",
    editor        = "code",
    fileExplorer  = "nautilus",
    audioSettings = "pavucontrol",

    -- The default browser is Zen, and Zen is a flatpak, so there is no binary
    -- to name. This is the same indirection the dotfiles' own SUPER+B uses:
    -- ask xdg for the default and launch its .desktop file, which works for a
    -- flatpak and a package alike and follows the default if it ever changes.
    browser       = "gtk-launch $(xdg-settings get default-web-browser)",

    -- sweet-cursors is not installed and is not in the repos; Adwaita is what
    -- the rest of this machine is already set to.
    cursorTheme   = "Adwaita",
    cursorSize    = 24,

    -- ─── what this GPU can actually afford ───────────────────────────────────
    -- Upstream's defaults (2 passes at size 8, shadow render_power 4) are sized
    -- for a desktop card. The iGPU here is a TigerLake-H *GT1* — 32 EUs, the
    -- cut-down variant — and it is driving 1920x1080 at 144 Hz, so every one of
    -- those blur passes is 2.5x the pixels per second a 60 Hz screen would ask
    -- for. The dGPU cannot help: the panel hangs off the Intel, and compositing
    -- on the nvidia would mean copying every frame back across the bus.
    --
    -- One pass at 7 instead of two at 8 is roughly half the fill rate for a
    -- blur you have to look for the difference in — dual-kawase widens the
    -- kernel per pass, so size buys most of the visible radius and passes buy
    -- smoothness. Raise passes back to 2 first if it ever looks banded.
    blurPasses        = 1,
    blurSize          = 7,

    -- Floating windows blur the wallpaper rather than re-blurring whatever is
    -- tiled underneath them. That skips a full re-blur every time anything
    -- moves behind a floating window, which on a dwindle layout is most of the
    -- time. The catch is honest: a floating window over a bright tiled window
    -- no longer picks up its colour.
    blurXray          = true,

    -- Menus are small, on screen briefly, and blur the same region repeatedly
    -- while they animate. Not worth a pass.
    blurPopups        = false,

    -- The exponent on the shadow falloff, not its size. 4 is the expensive one
    -- and the difference against 2 is a slightly harder edge on a shadow that
    -- is already at 10% alpha.
    shadowRenderPower = 2,

    -- Upstream closes on SUPER+Q and opens the browser on SUPER+W. The muscle
    -- memory here is the other way round, and of the two mistakes "I meant to
    -- close that" is the one that costs work, so close takes SUPER+W.
    --
    -- The browser does not get SUPER+Q in exchange: it lives on SUPER+B in
    -- hypr-user.lua, where it always did, and a second key for the same thing
    -- is just a key that cannot be used for anything else. SUPER+Q is left
    -- unbound. The `browser` string above is untouched — this drops the key,
    -- not the command, and SUPER+B still reads it.
    kbCloseWindow = "SUPER + W",
    kbBrowser     = {},

    -- Clipboard unbound here so hypr-user.lua can put the panel on SUPER+V
    -- instead. The key is not what changes — the action is, and the action is
    -- written into keybinds.lua rather than read from a variable, so the only
    -- way to replace it is to drop caelestia's bind and add our own. Leaving
    -- both would bind SUPER+V twice.
    --
    -- What it drops is `pkill fuzzel || caelestia clipboard`: cliphist piped
    -- into fuzzel, one line per entry, no thumbnails. SUPER+ALT+V (delete an
    -- entry) and CTRL+SHIFT+ALT+V (paste the newest) still use it and are left
    -- alone.
    kbClipboard   = {},

    -- Launcher off the bare SUPER tap and onto ALT+SPACE. Upstream's default is
    -- "SUPER + SUPER_L", which keybinds.lua special-cases: it is the only bind
    -- in the whole config that fires on key *release*, because a modifier has
    -- no press event of its own to hang off. The cost of that is every SUPER
    -- you press and think better of — every combo you start and abandon — ends
    -- in a launcher. ALT+SPACE is an ordinary press bind, so the special-casing
    -- (`normalise_keybind(key) == launcher_default`) simply stops applying.
    --
    -- Free here: plain ALT+SPACE was unbound, and the two Space binds that do
    -- exist are CTRL+SUPER+Space (media) and SUPER+ALT+Space (float). Note it
    -- is the traditional window menu in Xwayland apps, which the compositor
    -- bind now swallows.
    --
    -- Want both? This takes a list, and the release flag is decided per key:
    --   kbLauncher = { "ALT + SPACE", "SUPER + SUPER_L" },
    kbLauncher    = "ALT + SPACE",

    -- Window groups off. They are a niri habit, not one used here, and the
    -- four keys they cost are all keys that mean something else in these
    -- dotfiles. An empty table is how you say "no key": create_bind flattens
    -- it to nothing and never calls hl.bind, so the combos are left unbound
    -- rather than bound to a dispatcher that does nothing.
    --
    -- SUPER+, SUPER+SHIFT+, and SUPER+U are free again as a result. Left that
    -- way deliberately — this laptop has one monitor, so the focusmonitor
    -- binds they used to carry have nothing to move between.
    --
    -- Not touched: the *workspace* group binds (CTRL+SUPER+0-9 and friends).
    -- Different feature, same word — those move between blocks of ten
    -- workspaces and collide with nothing.
    kbToggleGroup          = {},
    kbGroupLockActive      = {},
    kbUngroup              = {},
    kbWindowGroupCycleNext = {},
    kbWindowGroupCyclePrev = {},
}
