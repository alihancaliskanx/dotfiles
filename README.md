# dotfiles

My Arch-based (CachyOS) setup. Theme: **rainynight**.
Three desktop profiles are supported — **Hyprland**, **niri**, **KDE** — and two shells: **zsh**, **fish**.

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
2. Clones oh-my-zsh, powerlevel10k and 5 zsh plugins
3. Links the configs with `./link.sh profile <profile>`

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
| `desktop`  | waybar (Hyprland + niri variants), fuzzel, mako, swayosd, satty |
| `terminal` | alacritty, kitty, ghostty                                       |
| `nvim`     | LazyVim-based configuration (`lazy-lock.json` included)          |
| `vscode`   | `~/.config/Code/User/settings.json` (extensions: see below)      |
| `git`      | `~/.config/git/config` — aliases, identity, gh credential helper |
| `xdg`      | `mimeapps.list` — which application opens which file type        |
| `cli`      | btop theme, cava, `~/.proxychains/tor.conf`                     |
| `scripts`  | the shared tools under `~/.local/bin/` (see below)              |
| `services` | `ssh-agent.service` (systemd user unit)                         |
| `theme`    | aether, Vencord, vicinae, warp-terminal rainynight themes + `kdeglobals` |
| `gtk`      | GTK3/GTK4 css — *not part of a profile*, see the warning below  |

Not linked: `extras/` (manually imported VSCode/Chromium/icon themes,
wallpapers, `vscode-extensions.txt`) and the install scripts. Nothing in
`extras/` is symlinked, which is exactly why the extension list lives there:
every file inside a package lands in `$HOME` at the same relative path.

### Profiles

A profile is a named set of packages. `shell terminal nvim vscode cli scripts services theme git xdg`
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
./link.sh                      # link the default profile (hyprland)
./link.sh profile              # list the profiles
./link.sh profile niri         # link the packages of a profile
./link.sh link fish gtk        # link individual packages
./link.sh status               # which package is linked, which is not
./link.sh unlink nvim          # remove a single package
./link.sh -n ...               # dry-run: show what it would do, touch nothing
./link.sh -f ...               # rename a conflicting real file to .bak.<date> and link over it
```

A conflict is an **error** by default, nothing is silently overwritten.
`unlink` only deletes symlinks pointing at this repo, it never touches real files.

To change the default profile: `DOTFILES_PROFILE=niri ./link.sh`

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

What stays in the shell is only the **env-modifying** ones — a subprocess cannot
change its parent's environment, so these cannot be scripts: `proxy_on/off`,
`tor_on/off`, `ardudev`, `ardupilot_dev`.

The old names are kept as aliases: `gitproxy_on`, `docker_proxy_on`,
`ssh_proxy_on`, `sart_proxy_on`, `http_tor`, `normal_tor`, `tor_check`,
`ros_docker`, `sha256_kontrol`.

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
  `sudo plasmalogin-theme`; the state lives outside `$HOME`, so it is not a
  package, it has to be run once per machine.
- **waybar** — started by `systemctl --user start waybar` from both compositor
  configs, not by an `exec-once` loop. The unit lives in the `services` package
  and picks the niri bar config from `$XDG_CURRENT_DESKTOP`; `Restart=always`
  brings it back if it dies and the output goes to `journalctl --user -u waybar`.
  `Mod+Shift+Space` still hides it with SIGUSR1, `systemctl --user reload waybar`
  re-reads the config.
- **KDE colours outside Plasma** — the `theme` package carries both halves: the
  scheme itself in `~/.local/share/color-schemes/RainyNight.colors` and the
  `kdeglobals` that selects it. With `QT_QPA_PLATFORMTHEME=kde` set by both
  compositors, that is what makes Dolphin, ark and gwenview follow rainynight
  under niri/Hyprland. KDE's own settings app rewrites `kdeglobals`; if it ever
  replaces the symlink with a real file, `./link.sh status` shows the conflict.
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

**Why is the `gtk` package in no profile?**
KDE's `kde-gtk-config` tool generates `colors.css`, `window_decorations.css` and
`assets/` under `~/.config/gtk-{3,4}.0/`, and appends its own `@import` to the
end of `gtk.css` — meaning these files are rewritten on every KDE settings
change. The css in the repo is the hand-written rainynight part. If you want to
link it, `./link.sh -f link gtk`, but know that KDE will overwrite it. The
package is therefore kept in sync by hand, not by a symlink; `colors.css` in it
is a snapshot of what kde-gtk-config produced.

`gtk-4.0/gtk.css` and `gtk-4.0/colors.css` are symlinks to the `gtk-3.0` ones —
one file, two locations, so the two toolkits cannot drift apart.

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

**Of KDE's own files only `kdeglobals` is tracked** (in the `theme` package,
because it is what selects the rainynight colour scheme for Qt apps under
niri/Hyprland). `kwinrc`, `plasmarc` and the rest stay out: they are constantly
rewritten by KDE and would produce constant conflicts.

**`~/.config/git/config` is deliberately not in the repo.**
`git config --global` writes the file with lock+rename, which replaces the
symlink with a real file. Since `net-proxy git on` does exactly that, tracking it
is pointless.

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

**Leftover dead references** (guarded, not deleted):
the `~/Documents/Code/aurapilot/ardupilot/Tools/autotest` directory does not
exist — either create it or delete the PATH line in `00-env`. `hyprpaper` gets
installed but there is no `hyprpaper.conf`; `extras/backgrounds/4.jpg` is not
used from anywhere (`hyprlock` uses `path = screenshot`).
