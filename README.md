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
| `desktop`  | waybar (Hyprland + niri variants), fuzzel, mako, swayosd, satty, hyprpaper |
| `terminal` | alacritty, kitty, ghostty                                       |
| `nvim`     | LazyVim-based configuration (`lazy-lock.json` included)          |
| `vscode`   | `~/.config/Code/User/settings.json` (extensions: see below)      |
| `git`      | `~/.config/git/config` — aliases, identity, gh credential helper |
| `xdg`      | `mimeapps.list` — which application opens which file type        |
| `cli`      | btop theme, cava, `~/.proxychains/tor.conf`                     |
| `scripts`  | the shared tools under `~/.local/bin/` (see below)              |
| `services` | `ssh-agent.service`, the Qt theme env, cliamp's D-Bus name      |
| `theme`    | aether, Vencord, vicinae, warp-terminal rainynight themes, `kdeglobals`, the `My Dotfiles` Plasma global theme |
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
./link.sh                      # ask which desktop to use, then link it
./link.sh profile              # list the profiles
./link.sh profile niri         # link the packages of a profile
./link.sh link fish gtk        # link individual packages
./link.sh status               # which package is linked, which is not
./link.sh unlink nvim          # remove a single package
./link.sh rice                 # list the desktops, show which one is on
./link.sh rice imperative-dots # switch desktop
./link.sh -n ...               # dry-run: show what it would do, touch nothing
./link.sh -f ...               # rename a conflicting real file to .bak.<date> and link over it
```

A conflict is an **error** by default, nothing is silently overwritten.
`unlink` only deletes symlinks pointing at this repo, it never touches real files.

To change the default profile: `DOTFILES_PROFILE=niri ./link.sh`

### rices — two desktops, one repo

A **profile** picks the compositor; a **rice** picks the desktop on top of it.
Run `./link.sh` with no arguments on a terminal and it asks which one:

```
Which desktop?  (on now: own)

  1) Own Dotfiles      waybar, fuzzel, mako, satty, hyprpaper
  2) imperative-dots   quickshell: bar, launcher, notifications, lock, wallpaper
```

| rice | where it lives |
|---|---|
| `own` | this repo — the profile packages |
| `imperative-dots` | `~/Documents/Code/imperative-dots`, [a fork](https://github.com/alihancaliskanx/imperative-dots) of ilyamiro's config |

A rice that is not this repo is **linked straight out of its own checkout** —
nothing is vendored in here, no submodule, no copy. Upstream stays a `git pull`
away in a repo of its own, and a fork is what makes local changes committable
(inside a submodule they would sit on a detached HEAD that cannot be cloned
anywhere else).

Each foreign rice carries a `.linkmap` at its root saying where its directories
belong under `$HOME`, because those trees are laid out for their own installer,
not for a symlinker:

```
config/sessions/hyprland     .config/hypr
config/programs/matugen      .config/matugen
```

Switching is always *take one out, put the other in*, never a merge — both want
`~/.config/hypr` and whoever is linked there wins. `RICE_REPLACES` in `link.sh`
lists the packages of this repo that a rice takes over (`hypr desktop cli` for
that one); everything rice-neutral (`scripts`, `git`, `services`, `xdg`,
`shell`, `nvim`, `terminal`…) stays linked throughout.

Symlinks are only half of it, so `RICE_RUNS` names what each rice actually runs
— `waybar hyprpaper` against `quickshell awww-daemon`. Switching stops one set,
reloads the compositor config, and starts the other, because a bar left running
after its config was unlinked keeps drawing from a file that is gone, and
starting the other one on top gives you two bars fighting over the same strip.
No logging out. A dry run says what it would restart and touches nothing, and
with no `WAYLAND_DISPLAY` the whole step is skipped — linking from a tty to set
a machine up is a legitimate thing to do.

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

**One wallpaper, three sessions.** `extras/backgrounds/starrysky.jpg` is the
background everywhere, but only one real copy of it exists, inside the
`StarrySky` wallpaper package — KPackage will not follow a symlink, so the file
has to be real where Plasma reads it, and `extras/` holds the symlink. niri and
Hyprland both run **hyprpaper** against that same path
(`desktop/.config/hypr/hyprpaper.conf`, in `desktop` because the niri profile
does not link `hypr`), Plasma gets it from the `My Dotfiles` global theme, and
the login screen from `sudo plasmalogin-theme`.

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
exist — either create it or delete the PATH line in `00-env`. `hyprlock` still
takes a blurred snapshot of the desktop (`path = screenshot`) rather than the
wallpaper, which is deliberate: it works on a machine with no image at all.
