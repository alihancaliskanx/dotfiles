# dotfiles

My Arch-based (CachyOS) setup. Theme: **rainynight**.
Three desktop profiles are supported — **Hyprland**, **niri**, **KDE** — and two shells: **zsh**, **fish**.

**This is the branch with the other desktops on it.** Besides the one this repo
builds itself, it carries **caelestia** and **imperative-dots** — each linked
straight out of its own checkout — plus the `link.sh rice` machinery that
switches between them and the `caelestia-local` package this machine answers
caelestia with. `main` has the repo's own desktop alone and none of that.

Everything is symlinked into `$HOME`; the real files live in this repo, so the
moment you edit one it takes effect live. No external tool is needed to install
(not even `stow`).

---

## Install on a clean machine

```bash
git clone git@github.com:alihancaliskanx/dotfiles.git ~/Documents/Code/dotfiles
cd ~/Documents/Code/dotfiles

./install.sh hyprland      # or: niri / kde
```

`install.sh` does the following, in order:

1. Installs the pacman + AUR packages for the profile
2. Installs the flatpak apps in `extras/flatpak-apps.txt` — Zen, the browser
   `mimeapps.list` names, is one of them
3. Clones oh-my-zsh, powerlevel10k and 5 zsh plugins
4. Clones the caelestia rice, because `link.sh` links a rice straight out of its
   own checkout and cannot make one
5. Sets the GTK theme and icon names that live in gsettings and `gtk-*/settings.ini`
   rather than in a file this repo can link
6. Asks, and then links the configs with `./link.sh profile <profile>`

If you are behind a proxy (PdaNet etc.):

```bash
PROXY=192.168.49.1:8000 ./install.sh hyprland
```

If you only want to link the configs and not install packages, `./link.sh` is enough.

---

## Packages

Each top-level directory is a "package"; the tree inside it is mirrored exactly into `$HOME`.
Example: `desktop/.config/waybar/style.css` → `~/.config/waybar/style.css`.

| Package    | Contents                                                        |
|------------|-----------------------------------------------------------------|
| `shell`    | `.zshrc` + `~/.config/zsh/` modules, `.bashrc`, `.p10k.zsh`     |
| `fish`     | `config.fish` + `~/.config/fish/modules/` — *not part of a profile* |
| `hypr`     | `hyprland.conf`, `hypridle.conf`, `hyprlock.conf`               |
| `niri`     | `config.kdl`                                                    |
| `desktop`  | waybar (Hyprland + niri variants), fuzzel, mako, swayosd, satty, hyprpaper |
| `terminal` | alacritty, kitty, ghostty                                       |
| `nvim`     | LazyVim-based configuration (`lazy-lock.json` included)          |
| `vscode`   | `~/.config/Code/User/settings.json` (extensions: see below)      |
| `git`      | `~/.config/git/config` — aliases, identity, gh credential helper |
| `xdg`      | `mimeapps.list` — which application opens which file type        |
| `cli`      | btop theme, cava, `~/.proxychains/tor.conf`                     |
| `scripts`  | the shared tools under `~/.local/bin/` (see below)              |
| `services` | `ssh-agent.service`, the Qt theme env, cliamp's D-Bus name      |
| `theme`    | aether, Vencord, vicinae, warp-terminal rainynight themes, the `My Dotfiles` Plasma global theme |
| `wallpapers` | `~/Pictures/Wallpapers/` — the images themselves, which every rice looks at and none of them owns |
| `kdeglobals` | the palette Qt apps read outside Plasma — its own package because a rice may need to take it over |
| `gtk`      | GTK3/GTK4 css — *not part of a profile*, see the warning below  |

Not linked: `extras/` (manually imported VSCode/Chromium/icon themes, the rice
linkmaps, `vscode-extensions.txt`), `programs/` (install scripts for software no
package manager handles — see below) and the top-level scripts. Nothing in
`extras/` is symlinked, which is exactly why the extension list lives there:
every file inside a package lands in `$HOME` at the same relative path. The
wallpapers moved out of it into a package of their own — what is left in
`extras/backgrounds/` is a symlink to the one real copy.

### Profiles

A profile is a named set of packages. `shell terminal nvim vscode cli scripts services theme wallpapers kdeglobals git xdg`
is common to all of them; the desktop-specific ones are added on top.

| Profile    | Extra packages    |
|------------|-------------------|
| `hyprland` | `hypr` `desktop`  |
| `niri`     | `niri` `desktop`  |
| `kde`      | — (common only)   |

`fish` and `gtk` are deliberately in no profile; they are linked on request.

---

## link.sh

```bash
./link.sh                      # ask which desktop to use, then link it
./link.sh profile              # list the profiles
./link.sh profile niri         # link the packages of a profile
./link.sh link fish gtk        # link individual packages
./link.sh status               # which package is linked, which is not
./link.sh unlink nvim          # remove a single package
./link.sh rice                 # list the desktops, show which one is on
./link.sh rice imperative-dots # switch desktop
./link.sh rice caelestia       # ditto
./link.sh adopt gtk            # pull the real files from $HOME into the repo
./link.sh adopt niri ~/.config/niri/config.kdl   # move one new file into a package
./link.sh -n ...               # dry-run: show what it would do, touch nothing
./link.sh -f ...               # rename a conflicting real file to .bak.<date> and link over it
```

A conflict is an **error** by default, nothing is silently overwritten.
`unlink` only deletes symlinks pointing at this repo, it never touches real files.

To change the default profile: `DOTFILES_PROFILE=niri ./link.sh`

### rices — three desktops, one repo

*This section is why this branch exists; `main` carries none of it.*

A **profile** picks the compositor; a **rice** picks the desktop on top of it.
Run `./link.sh` with no arguments on a terminal and it asks which one:

```
Which desktop?  (on now: own)

  1) own              waybar, fuzzel, mako, satty, hyprpaper
  2) caelestia        quickshell from the AUR + its own lua Hyprland config
  3) imperative-dots  quickshell: bar, launcher, notifications, lock, wallpaper
```

| rice | where it lives |
|---|---|
| `own` | this repo — the profile packages |
| `caelestia` | `caelestia-shell` from the AUR + `~/Documents/Code/caelestia`, upstream's [dots](https://github.com/caelestia-dots/caelestia) |
| `imperative-dots` | `~/Documents/Code/imperative-dots`, [a fork](https://github.com/alihancaliskanx/imperative-dots) of ilyamiro's config |

A rice that is not this repo is **linked straight out of its own checkout** —
nothing is vendored in here, no submodule, no copy. Upstream stays a `git pull`
away in a repo of its own, and a fork is what makes local changes committable
(inside a submodule they would sit on a detached HEAD that cannot be cloned
anywhere else).

Each foreign rice needs a `.linkmap` saying where its directories belong under
`$HOME`, because those trees are laid out for their own installer, not for a
symlinker:

```
config/sessions/hyprland     .config/hypr
config/programs/matugen      .config/matugen
```

A fork keeps that file at its own root and commits it there. An upstream
checkout cannot: a file added to it is untracked noise in someone else's
`git status` and is gone the next time it is cloned. For those the map lives
here instead, as `extras/linkmaps/<rice>.linkmap`, and `link.sh` falls back to
it — which is where caelestia's is.

Switching is always *take one out, put the other in*, never a merge — both want
`~/.config/hypr` and whoever is linked there wins. `RICE_REPLACES` in `link.sh`
lists the packages of this repo that a rice takes over (`hypr desktop cli` for
both of them, plus `kdeglobals` for imperative-dots); everything rice-neutral
(`scripts`, `git`, `services`, `xdg`, `shell`, `nvim`, `terminal`…) stays
linked throughout. Going from one foreign rice to another takes the first one
out too, and has to: imperative-dots writes `hyprland.conf` where caelestia
writes `hyprland.lua`, so leaving them side by side is not even a conflict —
Hyprland prefers lua and would keep running the one you just left. Whatever the
outgoing rice had taken over and the incoming one does not want is linked back
at the same time: `kdeglobals` is replaced by imperative-dots and not by
caelestia, and without that step the switch left it linked to nothing at all —
KDE wrote a stub into the gap and every Qt app, plus everything reading the
portal's `color-scheme`, came up light.

Symlinks are only half of it, so `RICE_RUNS` names what each rice actually runs
— `waybar hyprpaper` against `quickshell awww-daemon` against `qs`. Switching
stops one set, reloads the compositor config, and starts the other, because a
bar left running after its config was unlinked keeps drawing from a file that
is gone, and starting the other one on top gives you two bars fighting over the
same strip. A dry run says what it would restart and touches nothing, and with
no `WAYLAND_DISPLAY` the whole step is skipped — linking from a tty to set a
machine up is a legitimate thing to do.

Usually that means no logging out. The exception is caelestia, and it is worth
knowing about: Hyprland 0.56 chooses between `hyprland.lua` and `hyprland.conf`
**once, at startup**, and `hyprctl reload` only re-reads the file it already
chose. Coming from a rice that writes `.conf`, the reload therefore re-reads a
file that has just been unlinked, Hyprland regenerates a stub in its place, and
the session carries on as bare Hyprland with caelestia's bar drawn on top of
it. Nothing errors; `hyprctl getoption decoration:rounding` just quietly says
`0`. Nothing can fix that short of restarting the compositor, so `link.sh`
compares `hyprctl systeminfo`'s `configProvider` against the config now on disk
and says to log out when they disagree.

#### caelestia — half AUR package, half checkout

Unlike the other two, caelestia is not a config tree you can symlink. Its shell
is a quickshell config compiled against a C++ plugin and installed system wide,
so on Arch **the package is the whole of it**:

```bash
paru -S caelestia-shell caelestia-cli
```

`install.sh` carries both in its AUR list, and `./link.sh rice caelestia`
checks for them with `pacman -Qq` before it touches anything — a rice that
links cleanly and then comes up to an empty screen is the worse failure.

> **Watch which package satisfies `quickshell-git`.** `caelestia-shell` depends
> on it by name, and `cachyos/noctalia-qs` — a custom Quickshell fork — carries
> `provides = quickshell quickshell-git`, so an AUR helper will happily take it
> as the provider and replace the real `quickshell` with it. It is not one:
> caelestia's `shell.qml` dies on `Unrecognized pragma "DefaultEnv ..."` and no
> shell comes up. The repo's own `quickshell` (0.3.0) does have that pragma and
> runs caelestia fine, so the way out is `sudo pacman -Rdd noctalia-qs && sudo
> pacman -S quickshell` — `-Rdd` because `quickshell` does not *provide*
> `quickshell-git` and a plain `-R` refuses on caelestia-shell's behalf. That
> leaves the dependency formally unsatisfied and functionally fine.

What is left over is the Hyprland config, and *that* is the checkout at
`~/Documents/Code/caelestia` (cloned by `install.sh`). Nothing else from those
dots is linked — the fish, foot, btop and vscode configs there are paths this
repo already owns and the desktop changing is no reason for the shell prompt to
change with it. `extras/linkmaps/caelestia.linkmap` says so line by line.

> **Do not run `caelestia install`.** It is the CLI's own installer and it
> *copies* those dots over `~/.config`, which is precisely the job `link.sh` is
> doing — only with no way back and straight over this repo's symlinks.

Upstream's config hard-codes a `us` keyboard and one preferred monitor, and
knows nothing about this laptop. Two files reach all of it: `hypr-vars.lua` is
merged over its variables before anything runs, and `hypr-user.lua` is required
last, so it wins outright. Both are the **`caelestia-local`** package here, and
that is what `RICE_LOCAL` is for — a rice is somebody else's checkout, so there
is nowhere in it to keep what this machine has to say back. It goes in with the
rice and comes out with it, and is in no profile: a config for a shell that is
not running is just clutter.

```lua
-- caelestia-local/.config/caelestia/hypr-vars.lua — a table, merged over theirs
return { terminal = "alacritty", blurPasses = 1, kbCloseWindow = "SUPER + W" }
```

```lua
-- caelestia-local/.config/caelestia/hypr-user.lua — ordinary config, read last
hl.config({ input = { kb_layout = "tr" } })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
```

`shell.json` is the quickshell side of it and rides along in the same package.
Symlinking these three is only safe because nothing generates them: the CLI and
the shell both read them and never write back. Check that again before adding a
fourth — see `RICE_GENERATES` just below for what happens when that is not true.

The same package carries **the clipboard panel**, lifted out of imperative-dots
and run as a quickshell config of its own from
`~/.config/quickshell/clipboard`. caelestia's `SUPER+V` is `cliphist` piped into
fuzzel — one line per entry, and no way to show you an image it is holding. This
one lays the history out in a grid and renders the images.

Upstream it is one page of a stack inside a single monolithic shell that also
draws that rice's bar, notifications and lock, so there was no borrowing the
page without borrowing the bar. What made it liftable is that
`ClipboardManager.qml` is a plain `Item` that builds its own helpers and asks
its parent for nothing — all it needed was a window, which is the `shell.qml`
next to it. Four things changed in the copy: the path to `clip_fetcher.py`, the
two calls into imperative-dots' IPC script that closed the panel (now
`Qt.quit()`), and `MatugenColors.qml`, which read the file matugen writes and
now reads `~/.local/state/caelestia/scheme.json` — caelestia publishes the same
`base`/`surface0`/`mauve` names, so the panel follows `caelestia scheme set`
with no mapping table. The file keeps its upstream name so it can still be
diffed against where it came from.

It is drawn in an 800×700 box in the middle of the screen, out of the same
layout table and the same scale function imperative-dots sizes it with, so it
comes out the size it is over there rather than the size that happens to suit
this laptop. The window behind it is still the whole screen — that is what a
click outside lands on to dismiss it — but filling the window with the panel is
what made the first attempt enormous.

`SUPER+V` toggles it out of two exit codes: `qs kill -c clipboard` returns 0
when it killed something and 255 when there was nothing to kill, so
`qs kill -c clipboard || qs -c clipboard` opens it when it is closed and closes
it when it is open. caelestia's own bind is dropped in `hypr-vars.lua`
(`kbClipboard = {}`) rather than shadowed, since the action is written into its
`keybinds.lua` and only the key is a variable. `SUPER+ALT+V` (delete an entry)
and `CTRL+SHIFT+ALT+V` (paste the newest) are still caelestia's.

**The launcher answers to `SUPER+SPACE` and `ALT+SPACE`, and not to a bare
modifier.** Upstream puts it on the `SUPER` tap; `kbLauncher = {}` in
`hypr-vars.lua` drops that, because a modifier that opens a menu on its own is
one you cannot rest a finger on — every abandoned combo and every `SUPER` held
on the way somewhere else flashes the launcher open.

Both keys go through the shell's IPC —
`qs -c caelestia ipc call drawers toggle launcher` — rather than the
`caelestia:launcher` global, and that is not incidental. `Shortcuts.qml` handles
the global on *release*, which is what makes tapping a bare modifier possible at
all, and there is a second global, `launcherInterrupt`, to cancel it when the tap
turns out to be the start of a combo. Point `kbLauncher` at a modifier+key
combination and that release handling comes along with it: the release only
reports cleanly if you lift the key before the modifier, so the same keypress
opens the launcher or does nothing depending on which finger comes up first.
That is where "it works sometimes" came from. The IPC toggle has no release in
it and fires on the press.

`SUPER+SPACE` used to be play/pause here. That is not lost — caelestia's own
`CTRL+SUPER+SPACE` still toggles it, and so do the `XF86AudioPlay`/`Pause` keys.

#### patching the shell without forking it

Some of caelestia's behaviour is not configurable and lives in QML under
`/etc/xdg/quickshell/caelestia`, which pacman owns. The launcher was one: with
`showOnHover` on it opens when the pointer reaches the bottom of the screen and
then never closes on its own, because `Interactions.qml` only ever assigns it
`true` — the dashboard, three lines below, assigns the hover test itself and so
closes when you leave. Escape, a click outside and picking an entry all closed
it; moving the mouse away did not.

Forking the tree into `~/.config/quickshell/caelestia`, which quickshell prefers
over `/etc/xdg`, means owning 283 files and 12 MB to re-merge on every release
for two changed lines. **`caelestia-shell-overlay`** makes that unnecessary, and
it rests on one fact: quickshell resolves the `qs.` import prefix against the
*config root directory*, not against wherever `shell.qml` really is. A symlinked
`shell.qml` still loads `qs.modules.…` out of the directory the symlink sits in.
So the overlay is a mirror of symlinks with real files punched through it only
where something is patched. The numbers move with the patches: three of them
today (the launcher, the dashboard's lyrics selector, the lock surface's blur)
make it 54 symlinks, five real directories and three real files, and every
other file in the tree keeps tracking the package.

Patches, not patched copies: `caelestia-local/.config/caelestia/shell-patches/`
holds `<relpath>.patch` files. A stored copy of an upstream file goes stale in
silence; a `.patch` either applies or fails, and a failure is how you learn
upstream moved. When one fails the overlay leaves the plain symlink in place and
exits non-zero — a shell that starts and behaves like the package beats a shell
that does not start.

That last part is the thing to remember: **the overlay must be rebuilt after
every caelestia-shell upgrade**, because a release that adds a QML file leaves
the overlay without it and a missing import is a shell that never comes up.
`link.sh` builds it before starting the shell, and `hypr-user.lua` runs
`caelestia-shell-overlay --restart-if-changed` at login — a no-op on an ordinary
login, and on the one after an upgrade it rebuilds and restarts the shell before
you notice.

caelestia-cli renders its colour scheme into a temp file and `os.replace()`s it
into place, so a symlink at the target is destroyed rather than written through
and this repo is never in danger — the opposite of matugen, below. What it
leaves behind is a real file where a package wants its symlink back, so
`RICE_GENERATES` clears `fuzzel.ini`, the cava config, `hypr/scheme/current.lua`
and the two `gtk.css` on the way out. `gtk` is an extra package outside every
profile, so the way back to `own` does not relink it: if you use it, run
`./link.sh -f link gtk` afterwards.

The two `colors.css` are on that list without being caelestia's own work.
caelestia-cli renders `gtk.css` and `thunar.css` and stops there; what recolours
`colors.css` is kde-gtk-config's kded, set off by the `dconf write gtk-theme`
the CLI does on the way past — both files came out at the same minute with the
same palette. The kded writes it again from `kdeglobals` at the next login,
which is why this repo can delete it without owning it.

The menu only appears when stdin is a terminal. In a script or in CI a bare
`./link.sh` still links the default profile, exactly as before, so nothing hangs
on a prompt it cannot answer.

### adopt — pulling a file from $HOME into the repo

The equivalent of `stow --adopt`. For writing a new config under `~/.config/`
first and pulling it into the repo afterwards:

```bash
# move a new file into a package and put a symlink in its place
./link.sh adopt niri ~/.config/niri/config.kdl

# for every file in the package, pull in the real version from $HOME
./link.sh adopt gtk
```

> **Caution:** the second form **overwrites** the content in the repo. Make sure
> it is clean with `git status` first, then look at what changed with `git diff`.
> Running a dry-run with `-n` first is a good idea.

### If you would rather use stow

The directory layout is stow compatible:

```bash
sudo pacman -S stow
stow -t ~ shell terminal nvim cli scripts services theme hypr desktop
```

---

## check.sh

```bash
./check.sh
```

Validates what the repo can validate: `bash -n` and shellcheck (warning level
and up) over every script, `niri validate`, `Hyprland --verify-config`, `jq` on
the tracked JSON, `stylua --check` on the nvim config, and whether every package
directory is actually reachable from a profile.

A check whose tool is missing is **skipped, not failed** — a machine on the niri
profile has no Hyprland, and the GitHub runner (`.github/workflows/check.yml`)
has neither compositor. Locally the full set runs; shellcheck and stylua come
from mason if they are not installed system-wide:

```bash
PATH="$HOME/.local/share/nvim/mason/bin:$PATH" ./check.sh
```

---

## repo.sh

```bash
./repo.sh          # enable whatever is missing, then refresh
./repo.sh -n       # show what it would do, touch nothing
```

`install.sh` says which packages to install and never said where they come from,
which works right up until a repository is not enabled. Five of its AUR entries
are blackarch packages, and on a machine without `[blackarch]` the failure reads
as "no such package" rather than "you never turned that repo on". The CachyOS v4
repositories are the same gap from the other side — they are what makes this a
CachyOS install rather than an Arch one.

The order is not decoration. pacman takes the first repository that holds a
package, and the whole point of `cachyos-v4` is to shadow `core` and `extra` with
x86-64-v4 builds, so the script **refuses** to append a cachyos repo to a
`pacman.conf` that already has `[core]` and tells you where the block belongs
instead. `blackarch` goes last, being the widest and least curated.

| | |
|---|---|
| `cachyos-v4` `cachyos-core-v4` `cachyos-extra-v4` | x86-64-v4 builds, above core/extra so they win |
| `cachyos` | CachyOS's own packages — the kernel, the settings packages |
| `core` `extra` `multilib` | Arch's |
| `blackarch` | last |

It checks before it enables: the v4 repos are gated on the loader's own answer to
whether this CPU has x86-64-v4 (enabling them without AVX-512 does not fail
loudly — pacman installs binaries that then die with `SIGILL`), and missing
mirrorlists and keyrings are named rather than assumed. blackarch's key is the
one thing it will not do for you; that needs `strap.sh`, and a script in this
repo is not going to download and execute a remote installer on your behalf.

Idempotent, and it backs up `pacman.conf` before touching it.

---

## programs/

```bash
./programs/matlab.sh -h        # every script explains itself
./programs/arm-gcc.sh
PROXY=192.168.49.1:8000 ./programs/plotjuggler.sh
```

Install scripts for the software on this machine that **no package manager
handles**: behind a vendor login, pinned to a version the repos do not carry, or
shipped only as a tarball or an AppImage. Anything pacman, the AUR or flatpak can
install belongs in `install.sh` and `extras/pacman-explicit.txt` instead.

Nothing here runs on its own. `install.sh` never calls into this folder and
`link.sh` does not symlink it — you run one when you want that program back.
Every script is safe to run twice, takes `-h`, and reads the same `PROXY`
variable as `install.sh`.

| Script | Installs | Why it cannot be a package |
|---|---|---|
| `matlab.sh` | MATLAB via MathWorks' own `mpm`, into `/opt/MATLAB` or `~/MATLAB` | no MATLAB package exists anywhere |
| `stm32cubeide.sh` | STM32CubeIDE into `~/st` from ST's installer | the download is behind a my.st.com login |
| `arm-gcc.sh` | `gcc-arm-none-eabi` 10-2020-q4-major into `/opt` | ArduPilot pins that release, the repo package tracks the newest |
| `arduino-cli.sh` | `arduino-cli` into `~/.local/bin` | one static binary, taken from the upstream release |
| `mavproxy.sh` | MAVProxy + pymavlink into `~/.local` | PyPI only, and Arch's Python needs `--break-system-packages` |
| `plotjuggler.sh` | PlotJuggler AppImage into `~/Applications` | the AUR build breaks on every Qt/ROS bump |
| `sonarview.sh` | SonarView AppImage into `~/Applications` | Cerulean Sonar ship an AppImage and nothing else |

`matlab.sh` is the one worth reading before running. MATLAB installs fine, and
then its activation window does not open, for two reasons that have nothing to do
with MATLAB: gtk2 has left the Arch repos, and gnutls 3.8.10 and later break
FlexLM's TLS handshake so it segfaults in `lc_new_job`. The script drops the
missing gtk2 and gnutls 3.8.9 into MATLAB's *own* lib directory — its RPATH is
`$ORIGIN`, so it loads those and no other program on the machine ever sees them.
If the window still refuses, `./programs/matlab.sh license file.lic` puts an
offline license in place, and FlexLM then never reaches for the login window at
all.

---

## Shell configuration

Both are modular; there is no single huge file. The same numbering applies to both shells:

| Module            | What's in it                                      |
|-------------------|---------------------------------------------------|
| `00-env`          | definitions: PATH, EDITOR, `PROXY_ADDR`, env      |
| `10-plugins`      | oh-my-zsh, powerlevel10k, fzf *(zsh only)*        |
| `20-aliases`      | aliases                                           |
| `30-proxy`        | proxy + Tor: env functions and shortcuts          |
| `40-functions`    | other custom functions                            |
| `50-local`        | machine specific: conda/mamba, nvm, distrobox     |

- **zsh** → `~/.config/zsh/*.zsh`; `.zshrc` is just a loader that sources them in order.
- **fish** → `~/.config/fish/modules/*.fish`; `config.fish` is the loader.

To add a new module all you need is to drop `<order>-<name>` into the directory, nothing else.

> **Why aren't the fish modules under `conf.d/`?** fish loads `conf.d/*.fish`
> files **before** `config.fish`. Since CachyOS's default config defines the
> `ls`/`ll`/`lt` aliases at the `config.fish` stage, ours would have been
> overridden if the modules lived in `conf.d/`. By sourcing them explicitly from
> `modules/` we give the modules the last word.

### Shared scripts

So that a function does not have to be written twice for zsh and fish,
everything that does **not** modify the current shell's environment is a single
bash script under `scripts/.local/bin/`:

| Command        | What it does                                                   |
|----------------|-----------------------------------------------------------------|
| `net-proxy`    | turn the proxy on/off for `git`/`docker`/`ssh`/`sart` + `status` |
| `net-tunnel`   | transparent tunnel for **all** TCP (glider): `on` / `off` / `status` / `check` |
| `net-auto`     | proxy when the phone answers, direct when it does not — `status` / `watch` |
| `tor-net`      | Tor's upstream proxy: `proxy` / `direct` / `check` / `status`    |
| `tor-control`  | Tor ControlPort + NEWNYM (gum TUI)                              |
| `gclink`       | clone an AUR package and install it with `makepkg -si`          |
| `ros-docker`   | enter / create the ROS Noetic container                         |
| `sha256-check` | verify a file's sha256                                          |
| `window-switch`| pick any window on any workspace through fuzzel (Super+Tab)     |
| `power-profile`| cycle power-saver → balanced → performance (Super+Shift+P)      |
| `code-extensions` | the VS Code extension list: `status` / `save` / `install`   |
| `pkg-snapshot` | what is installed on this machine: `diff` / `save` / `install`  |
| `plasmalogin-theme` | rainynight colours + background for the login screen (root) |
| `hibernate-setup` | a btrfs swapfile big enough to hibernate into, the `resume=` to find it again, and `--fix-nvidia` for the module option that blocks the way back (root, once per machine) |
| `pam-kwallet-env` | hands the session environment to the ksecretd pam started, so the wallet is unlocked at login instead of asking (run first at startup) |
| `weather-location` | pick where caelestia's weather comes from — a city, coordinates, `status`, `clear` |
| `TuxedoRGBKeyboard.sh` | keyboard backlight: `toggle` / `up` / `down` / `set` / `colour` |

What stays in the shell is only the **env-modifying** ones — a subprocess cannot
change its parent's environment, so these cannot be scripts: `proxy_on/off`,
`tor_on/off`, `ardudev`, `ardupilot_dev`.

The old names are kept as aliases: `gitproxy_on`, `docker_proxy_on`,
`ssh_proxy_on`, `sart_proxy_on`, `http_tor`, `normal_tor`, `tor_check`,
`ros_docker`, `sha256_kontrol`. `net-tunnel` has short forms too:
`tunnel_on`, `tunnel_off`, `tunnel_status`, `tunnel_check`.

#### `net-auto` — deciding, instead of remembering

`net-proxy` is the switch; `net-auto` is what decides. It opens a TCP connection
to the proxy and applies the answer to everything that needs no root — `git`,
`ssh`, `sart` — so tethering and plain wifi need no thought:

```bash
net-auto            # probe once and apply
net-auto status     # what is applied, and whether the proxy answers
net-auto on|off     # force it, ignoring the probe
```

`net-auto.service` (a systemd **user** unit, in the `services` package) runs
`net-auto watch`, which blocks on `nmcli monitor` and re-decides whenever
NetworkManager changes anything. Event driven, not polled: an idle laptop does
nothing at all. Applying is idempotent, so the extra events cost one TCP connect
and no writes.

The verdict is cached in `~/.cache/net-auto/state`, and both shell modules read
that file at startup — which is what gives a new terminal the right `http_proxy`.
Probing in the shell instead would put a TCP timeout in front of every prompt on
a network with no proxy. `proxy_off` still wins for the rest of that shell.

**docker is deliberately left out.** Turning it on writes into
`/etc/systemd/system` and restarts the daemon — sudo, and every running
container dies. That is not something to do behind your back, so
`net-proxy docker on|off` stays manual; `net-auto status` points it out when it
disagrees with the rest.

#### `net-tunnel` — for what a proxy cannot be handed to

`net-proxy` sets a proxy per application; `proxy_on` sets it for one shell.
Neither reaches a program that has no idea what a proxy is. Steam is the
textbook case, and `proxychains` does not save it either:

- the Steam client is **32-bit** (`ubuntu12_32/steam`), so the 64-bit
  `libproxychains4.so` is refused — `wrong ELF class: ELFCLASS64: ignored` —
  and the process that does the actual downloading goes out unproxied,
- `steamwebhelper` runs inside a **bubblewrap container** where
  `/etc/proxychains.conf` is not mounted: `couldnt find configuration file`,
- `LD_PRELOAD` hooks `connect()` and nothing else — static binaries and non-TCP
  traffic slip past.

`net-tunnel` works one layer down instead: **glider** (`redir://` listener +
`http://` forwarder) + an **nftables** `nat output` redirect, so every TCP
connection on the machine is pushed into the proxy no matter which process opens
it. In PdaNet WiFi Direct mode UDP/53 does not work at all, so DNS is handed to
systemd-resolved as **DNS-over-TLS** (TCP/853) — which then rides the same
tunnel.

```bash
tunnel_on       # glider + nft + DoT, then plain `steam` just works
tunnel_check    # DNS + Steam CDN + exit IP
tunnel_off      # everything removed, back to the original state
```

> **Why glider and not redsocks.** The obvious tool for this is redsocks, and
> the first version used it — but the blackarch build (`211.19b822e`) cannot
> handle a *successful* CONNECT. An error reply (502) it parses and logs
> correctly; on `200` — every variant, HTTP/1.0 and 1.1, `OK` and `Connection
> established` — it accepts the client, sends the CONNECT and then sits there
> silently until the client times out. It reproduces against a local fake proxy,
> so it is not the phone's fault; the suspect is the `libevent version mismatch`
> it warns about on startup. glider does the same job in one binary and is in
> the repos.

Nothing persistent is written: the transient systemd unit, the nft table and
the resolved settings are all in RAM and gone after a reboot. Docker containers
have their own netns and do not pass through the `output` hook — for those it is
still `net-proxy docker on`.

> The proxy allows CONNECT to 80/443/853 but blocks Steam's own CM ports
> (27015-27050); Steam notices and falls back to CM-over-443, so the first login
> can be slow. UDP is not tunnelled: voice chat and P2P will not work,
> downloads and games will.

The proxy address comes from a single place: **`PROXY_ADDR`** in `00-env`
(default `192.168.49.1:8000`). The scripts read the same variable:

```bash
PROXY_ADDR=10.0.0.1:3128 net-proxy git on
```

---

## Per-application notes

- **nvim** — LazyVim. Plugins install themselves on first launch; if it gets
  stuck, `:Lazy sync`. Versions are pinned by `lazy-lock.json`, don't forget to
  commit it after updating.
- **powerlevel10k** — to change the prompt: `p10k configure` (it rewrites `~/.p10k.zsh`).
- **switching to fish** — `./link.sh link fish` then `chsh -s /usr/bin/fish`.
- **tor-control** — does not work without `gum` (`sudo pacman -S gum`).
- **ssh-agent** — `systemctl --user enable --now ssh-agent`.
- **login screen** — CachyOS/Plasma 6.7 no longer uses SDDM but
  `plasma-login-manager` (the greeter runs as the `plasmalogin` user). There is
  no theme package any more: the background comes from `/etc/plasmalogin.conf`
  (`[Greeter][Wallpaper][org.kde.image][General]`), the colours from
  `/var/lib/plasmalogin/.config/kdeglobals`. Both are written by
  `plasmalogin-theme`; the state lives outside `$HOME`, so it is not a
  package, it has to be run once per machine.
- **waybar** — started by `systemctl --user start waybar` from both compositor
  configs, not by an `exec-once` loop. The unit lives in the `services` package
  and picks the niri bar config from `$XDG_CURRENT_DESKTOP`; `Restart=always`
  brings it back if it dies and the output goes to `journalctl --user -u waybar`.
  `Mod+Shift+Space` still hides it with SIGUSR1, `systemctl --user reload waybar`
  re-reads the config.
- **KDE colours outside Plasma** — two halves in two packages: the scheme itself
  in `theme` (`~/.local/share/color-schemes/RainyNight.colors`) and the
  `kdeglobals` that selects it, which is a package of its own. With
  `QT_QPA_PLATFORMTHEME=kde` set by both compositors, that is what makes
  Dolphin, ark and gwenview follow rainynight under niri/Hyprland. KDE's own
  settings app rewrites `kdeglobals`; if it ever replaces the symlink with a
  real file, `./link.sh status` shows the conflict.

  It is one file in a package of its own because it is the one thing in `theme`
  a rice has to be able to take over. `kdeglobals` is where Qt apps read their
  palette, and it is the *only* place that moves a KF6 app: dolphin ignores
  qt6ct and `KDE_COLOR_SCHEME_PATH` alike. So imperative-dots, which colours the
  desktop from the wallpaper, generates it — `RICE_REPLACES` unlinks the package
  on the way in and `RICE_GENERATES` deletes what matugen wrote on the way out.
  The split is what keeps that safe: matugen writes *through* a symlink, so had
  the file stayed in `theme` (linked under every rice) the first wallpaper
  change would have overwritten the tracked rainynight palette in this repo
  rather than shadowing it.

  caelestia leaves it alone and stays linked: it sets
  `QT_QPA_PLATFORMTHEME=qtengine` and colours Qt apps out of
  `~/.config/qtengine`, a path nothing here owns, so `kdeglobals` is simply not
  read while it is on and there is nothing to take away.

  That holds now, and for a while it did not. `qtengine` is an AUR package out
  of caelestia's own manifest — its `qt` component, with `darkly-bin` and
  `frameworkintegration` — and the shell here comes from the AUR instead of that
  manifest, so for a time the plugin simply was not installed. Qt does not
  complain about a platform theme it cannot find; it falls back to none at all,
  which is the default *light* palette, and the fix was to point
  `QT_QPA_PLATFORMTHEME` at `kde` in `hypr-user.lua` so `kdeglobals` was read
  again. All three packages are installed now and that override is gone —
  `hypr-user.lua` says so where the line used to be.

  So if Qt apps ever come up white under caelestia, that is the first thing to
  check, because it fails silently:

  ```bash
  ls /usr/lib/qt6/plugins/platformthemes/   # want libqt6engine-plugin.so
  paru -S qtengine darkly-bin frameworkintegration papirus-folders
  ```

  Those three are **not** in `install.sh`, so a fresh machine reaches exactly the
  state described above until they are installed by hand.
- **the `My Dotfiles` global theme** — inside a Plasma session there is a second
  route to the same look: `plasma-apply-lookandfeel -a my-dotfiles`, or System
  Settings › Colors & Themes › Global Theme. It lives in the `theme` package at
  `~/.local/share/plasma/look-and-feel/my-dotfiles` and names the palette rather
  than shipping a copy of it, so there is still only one `RainyNight.colors`.
  Everything else it sets is stock Breeze (widgets, decoration, icons, cursors)
  on purpose: a fresh Plasma install has all of it, so the theme applies on a
  machine that has nothing but this repo. It deliberately ships **no**
  `contents/layouts/`, because a layout file would wipe the panels every time the
  theme is applied. Applying it is also how a Plasma session that has reset
  itself to Breeze gets back to rainynight.
- **a KPackage may not contain a symlink** — and this one bites silently.
  KPackage (Plasma's package loader: global themes, wallpapers, plasmoids) drops
  every file whose *canonical* path leaves the package directory. `link.sh`
  symlinks file by file, so each file inside a linked package resolves back into
  the repo, i.e. outside the package — the global theme was selected, its
  `defaults` was never read, and Plasma fell back to stock **light** Breeze with
  no error anywhere. `LINK_AS_DIR` in `link.sh` is the fix: those directories are
  linked with one symlink for the package root, which puts every file back
  inside it. The rule that follows: nothing under
  `.local/share/plasma/look-and-feel/` or `.local/share/wallpapers/` may itself
  be a symlink. That is why `extras/backgrounds/starrysky.jpg` is the symlink and
  the real jpg lives in the wallpaper package — the file has to be real where
  KPackage reads it, and everything else points at that one copy.
- **the global theme's wallpaper needs `--resetLayout`** — `[Wallpaper] Image=`
  in `contents/defaults` is only applied together with the desktop layout, and
  `plasma-apply-lookandfeel -a my-dotfiles` does not touch the layout (that would
  wipe the panels). To set just the wallpaper:
  `plasma-apply-wallpaperimage ~/.local/share/wallpapers/StarrySky`. Under
  niri/Hyprland nothing of the sort is needed — hyprpaper reads the same image
  from its config at startup.
- **Plasma 6 writes theme choices to `~/.config/kdedefaults/`**, not to
  `kdeglobals`. Applying a global theme puts `ColorScheme`, `Icons/Theme` and
  `widgetStyle` there and *removes* the now-redundant keys from `kdeglobals` —
  which is why `ColorScheme=RainyNight` disappears from the tracked file. Nothing
  breaks: the whole `[Colors:*]` palette stays in `kdeglobals`, and that is what
  Qt apps actually read under niri/Hyprland. `kdedefaults/` is not tracked, for
  the same reason `kwinrc` is not.
- **Packages come in two lists.** `install.sh` carries the curated one: what a
  fresh machine *should* have, grouped by what it is for. `extras/pacman-explicit.txt`
  and `extras/flatpak-apps.txt` carry the other one — everything this machine
  actually has, written by `pkg-snapshot save` and put back by
  `pkg-snapshot install`. The first answers "set up a machine like mine", the
  second "bring my machine back". `pkg-snapshot` with no argument diffs them.
- **The browser is a flatpak.** Zen — what `Mod+B` opens and what
  `mimeapps.list` points at — is `app.zen_browser.zen` from flathub, not a
  pacman package. `install.sh` adds the flathub remote and installs the apps in
  `extras/flatpak-apps.txt`; without that step a fresh machine has no browser.
- **VS Code** — only `settings.json` is linked. The extensions themselves are
  downloaded builds under `~/.vscode/extensions`, so what is versioned is the
  list of their ids in `extras/vscode-extensions.txt`:
  `code-extensions status` compares it with what is installed, `save` records
  the current set, `install` pulls the missing ones. Worth a `status` after
  adding an extension — nothing writes the list by itself.
  If VS Code ever replaces the symlink with a real file of its own, `./link.sh
  status` reports it as a conflict and `./link.sh adopt vscode
  ~/.config/Code/User/settings.json` pulls it back into the repo.
- **niri** — validate the config with `niri validate`. The differences from
  Hyprland are marked with `// DIFF:` inside `config.kdl` (column-based focus,
  no blur, `Mod`+click built in).

---

## Things worth knowing

**The wallpapers are in the repo, and one of them twice over would be a bug.**
`wallpapers` carries `~/Pictures/Wallpapers/` — 27 MB of photographs, which is
why it is its own package and not part of `theme`. It is common to every profile
because every rice reads that directory and none of them owns it: caelestia's
picker lists it, matugen is pointed at whatever is in it, and `own` ignores it
entirely and uses hyprpaper.

`starry-sky.jpg` in that package is a **symlink**, not a ninth image. The same
picture is the `StarrySky` KPackage in `theme`, and KPackage drops any file whose
canonical path leaves the package directory — so that copy has to be real where
Plasma reads it, and everything else points at it. `extras/backgrounds/starrysky.jpg`
is the same symlink from the other side. Three references, one file on disk;
adopting it as a real file again would put 2.4 MB of duplicate into the history.

**One wallpaper reaches all three sessions.** niri and Hyprland both run
**hyprpaper** against the `StarrySky` path
(`desktop/.config/hypr/hyprpaper.conf`, in `desktop` because the niri profile
does not link `hypr`), Plasma gets it from the `My Dotfiles` global theme, and
the login screen from `plasmalogin-theme`. caelestia is the exception: it
keeps its own choice in `~/.local/state/caelestia/`, which is state and is not
tracked — the image it points at is, now.

**Hibernation also needs the nvidia driver to agree to be frozen.** Resuming
reads the image and then freezes every device the boot kernel has bound; a driver
that refuses aborts the resume *after* the image is read, and the session is
gone. `NVreg_PreserveVideoMemoryAllocations=1` makes the module refuse, because
it then insists on being suspended through `/proc/driver/nvidia/suspend` by
`nvidia-suspend.service`, and no such service exists inside an initramfs. This
machine had it from `gpu-screen-recorder`'s
`/usr/lib/modprobe.d/gsr-nvidia.conf`, while `nvidia-sleep.conf` set the option
the *open* modules actually want, `NVreg_UseKernelSuspendNotifiers=1` — the two
contradict, and the open driver preserves video memory through the second one
anyway. `hibernate-setup --fix-nvidia` shadows the first file with an `/etc` one
and rebuilds the initramfs. It only bites on the way back up: hibernating always
worked, because `PM_HIBERNATION_PREPARE` reaches the driver and it consents,
while resuming sends `PM_RESTORE_PREPARE`, which it does not.

**Hibernation needs somewhere to go, and zram is not it.** The only swap this
machine had was `/dev/zram0`, which is a compressed block device living *in* RAM
— writing RAM into it and then cutting power leaves nothing to come back to. So
`logind` answered `CanHibernate` with `na`, caelestia's session menu offered a
hibernate button that could not work, and its 600-second idle action
(`suspendThenHibernate`) quietly degraded to a plain suspend. `hibernate-setup`
is the fix: a 32 GiB swapfile in a btrfs subvolume of its own, at priority -2 so
zram stays the swap everything normally pages to, plus the `resume=` and
`resume_offset=` on the kernel command line without which the kernel has no idea
where to look before any filesystem is mounted. The subvolume matters — a btrfs
snapshot is not recursive, so a nested subvolume is invisible to the snapshots
snapper takes of `@`, and a swapfile that gets snapshotted or moved is a swapfile
that cannot be resumed from.

**The weather has a location setting and caelestia has no way to pick one.**
It reads `services.weatherLocation` out of `shell.json`, and with it empty it
geolocates by IP — which on a machine that spends its time behind a phone's
tethering proxy or Tor reports wherever the exit is. Its own settings page says
"Choose your weather location on a map in a future update", so `weather-location`
is that picker until it exists: it asks for a city, geocodes it through
open-meteo, and lets you choose between the matches.

Coordinates are what it writes, even when you type a name, because the shell
would otherwise re-geocode the string on every reload and take the first hit —
and there is more than one Antalya. The shell reloads on the change, so nothing
needs restarting.

Two things it is careful about. `shell.json` is a symlink into this repo, so it
writes *through* the link rather than moving a temp file onto it, which would
replace the symlink with a real file and quietly detach the config. And it passes
`--indent 4` to jq, because jq's default is two and the file would otherwise be
reformatted end to end on every use.

**hyprpaper 0.8 changed its config format.** `preload = <path>` plus
`wallpaper = <monitor>,<path>` — what every guide and every older dotfiles repo
still shows — is gone, replaced by a `wallpaper { monitor = ; path = ; fit_mode
= }` block. The old keys do not fail loudly: hyprpaper starts, sets nothing, and
logs `Monitor eDP-1 has no target: no wp will be created`. `~` in `path` is
expanded by hyprpaper itself, `$HOME` is **not**.

**Why is the `gtk` package in no profile?**
KDE's `kde-gtk-config` tool generates `colors.css`, `window_decorations.css` and
`assets/` under `~/.config/gtk-{3,4}.0/`, and appends its own `@import` to the
end of `gtk.css` — meaning these files are rewritten on every KDE settings
change. The css in the repo is the hand-written rainynight part. If you want to
link it, `./link.sh -f link gtk`, but know that KDE will overwrite it. The
package is therefore kept in sync by hand, not by a symlink.

`colors.css` used to be in it as a snapshot of what kde-gtk-config produced, and
is not any more — for the same reason the two `settings.ini` left: the kded
module rewrites that file from `kdeglobals` at every login and a symlink is not
a wall, so the repo's copy was one login away from being overwritten in place.
The `@import "colors.css"` at the top of `gtk.css` went with it. Nothing was
lost: `gtk.css` defines every colour it uses itself and referenced none of the
`*_breeze` names that file declares, so the import only ever pulled in dead
weight — and now that the package no longer ships the file, an import of it
would be a parse error at the startup of every GTK application each time
`link.sh rice own` cleared caelestia's copy.

`gtk-4.0/gtk.css` is a symlink to the `gtk-3.0` one — one file, two locations,
so the two toolkits cannot drift apart.

**GTK has no `filter` property.** The theme this css came from carried a
`.svg-icon { filter: invert(…) … }` block, which is web CSS. GTK ignored the
rule but printed `Theme parsing error: gtk.css:164: 'filter' is not a valid
property name` on the startup of every single GTK application. It is gone, and
the `@import` now sits at the top of the file where CSS requires it to be.

**Compositor `env` blocks do not reach systemd services.**
`QT_QPA_PLATFORMTHEME=kde` set in `hyprland.conf` / `config.kdl` only reaches
processes the compositor spawns itself. `xdg-desktop-portal-kde` is started by
systemd on demand, so it never saw it and drew its file dialog in Qt's default
light palette — the one dialog in the session that ignored rainynight.
`services/.config/environment.d/10-qt-theme.conf` puts the variable where the
systemd user manager reads it, which covers D-Bus activated services as well.
Applying it to a running session takes
`systemctl --user set-environment QT_QPA_PLATFORMTHEME=kde` plus a restart of the
service; from the next login `environment.d` does it by itself.

**Of KDE's own files only `kdeglobals` is tracked** (in the package of the same
name, because it is what selects the rainynight colour scheme for Qt apps under
niri/Hyprland). `kwinrc`, `plasmarc` and the rest stay out: they are constantly
rewritten by KDE and would produce constant conflicts.

**`~/.config/git/config` is tracked, and `net-proxy git on` writes into it.**
This used to say the opposite, and the reasoning was sound: `git config --global`
writes with lock+rename, which replaces a symlink with a real file, so tracking
it looked pointless. It is tracked anyway — for the aliases, the identity and the
gh credential helper — and the consequence is worth knowing rather than being
surprised by. `net-proxy git on` writes through to the file in this repo, so the
tethering proxy address ends up in `git diff` and, if you are not looking, in a
commit. `net-proxy git off` takes it back out.

Note also that `[https] proxy` is not a thing git reads; only `http.proxy` (and
`http.<url>.proxy`) does anything. The `[https]` section is inert.

**Do not use `systemctl --user reenable`.**
Because the unit file is a symlink, the `disable` step deletes it. If you need to:
`./link.sh link services && systemctl --user enable ssh-agent`

**The compositors set PATH themselves.**
Hyprland is launched by `start-hyprland`, not a login shell, so it never sources
`.zshrc` and its PATH stops at `/usr/bin`. Anything bound to a script from the
`scripts` package would fail to resolve and die silently — no window, no error.
`hyprland.conf` therefore carries `env = PATH,$HOME/.local/bin:$PATH`; niri gets
the same effect by routing the binding through `sh` so `$HOME` expands. Bind a
new script and it will just work; move the scripts elsewhere and it will not.

**The Settings portal backend is pinned per compositor.**
`xdg-desktop-portal-hyprland` does not implement
`org.freedesktop.impl.portal.Settings`, and with kde, gtk and gnome backends all
installed nothing decided which one answers. The portal cached
`org.freedesktop.appearance color-scheme` as "prefer light" at login and never
noticed the desktop was dark, so Firefox-based apps drew white context menus.
`hypr/` and `niri/` each ship a `<desktop>-portals.conf` pinning Settings to the
gtk backend. They are separate files on purpose: one shared
`~/.config/xdg-desktop-portal/portals.conf` would apply to both sessions, and
Hyprland needs `default=hyprland;gtk` for screencasting while niri needs
`gnome;gtk`.

**KDE apps need `XDG_MENU_PREFIX` outside Plasma.**
`plasma-workspace` only ships `/etc/xdg/menus/plasma-applications.menu`, and KDE
apps look for `$XDG_MENU_PREFIX` + `applications.menu`. A Plasma session sets the
variable to `plasma-`; under niri/Hyprland it was unset, so the menu was never
found — `kbuildsycoca6 --menutest` printed 0 entries instead of 138, and every
KIO "Open With → Other Application…" dialog came up empty. Both compositor
configs now set `XDG_MENU_PREFIX=plasma-`.

**`XDG_CURRENT_DESKTOP` carries a `:KDE` suffix.**
Entries with `OnlyShowIn=KDE` (System Settings, Info Center, the emoji picker)
are hidden from every launcher when the variable is plain `niri` / `Hyprland`.
The compositor name stays first in the list — `niri:KDE`, `Hyprland:KDE` — so
xdg-desktop-portal still picks `niri-portals.conf` / `hyprland-portals.conf`, and
`xdg-open` still falls back to the generic handler (its `detectDE` only matches
the exact string `KDE`). Scripts that branch on the variable (`hotkeys`,
`window-switch`) therefore match with globs, not equality.

**Screenshots go through grim + satty.** Spectacle was tried and does not work
here: it drives KWin's own `org.kde.KWin.ScreenShot2` API, and with no KWin
under Hyprland it produces no file and no error at all.

**The conda/mamba blocks** run if `$HOME/miniforge3` exists, and are skipped otherwise.
Without the guard they tried to run a non-existent binary on every shell startup.

**Paths that went stale and have been repointed.** The ardupilot autotest tree
is at `~/Documents/Code/stars/aurapilot/Tools/autotest`, which is what `00-env`
and `ardudev` now put on PATH — the old `~/Documents/Code/aurapilot/ardupilot`
path never existed on this machine. `qgc` runs the packaged `qgroundcontrol`
rather than a local build directory that is gone, and `mavproxy` runs the
`mavproxy.py` that the pip install puts on PATH rather than a virtualenv that no
longer exists. `hyprlock` still takes a blurred snapshot of the desktop
(`path = screenshot`) rather than the wallpaper, which is deliberate and stays:
it works on a machine with no image at all.
