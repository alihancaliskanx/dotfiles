# dotfiles

My [Omarchy](https://omarchy.org) setup. Theme: **rainynight**.
This is the `omarchy` branch: the machine runs Omarchy 4, and these files are
what it says on top of Omarchy's defaults rather than a desktop of their own.
Two desktop profiles are supported — **Hyprland** and **KDE**. The shell is **zsh**.

Everything is symlinked into `$HOME`; the real files live in this repo, so the
moment you edit one it takes effect live. No external tool is needed to install
(not even `stow`).

---

## What this branch runs

| | |
|---|---|
| system | Omarchy (`ID=omarchy`), Hyprland 0.56 on its Lua config provider |
| bar, launcher, notifications, lock | Omarchy's shell — `quickshell -n -p /usr/share/omarchy/shell`, started by `omarchy-launch-shell` |
| Hyprland config | `hypr/.config/hypr/hyprland.lua` and the five modules it requires |
| not here | waybar, hyprpaper, mako, fuzzel, swayosd — not installed, and this branch carries no config for them |

### the Hyprland config is a layer, not a config

`hyprland.lua` does four things in order, and the order is the design:

```lua
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
_G.omarchy_default_bindings = false
require("default.hypr.omarchy")
require("hypr.monitors"); require("hypr.input"); require("hypr.bindings")
require("hypr.looknfeel"); require("hypr.autostart")
```

The bootstrap puts `~/.local/state`, `~/.config` and `$OMARCHY_PATH` on Lua's
module path, which is what makes `require("hypr.bindings")` find
`~/.config/hypr/bindings.lua` and `require("default.hypr.omarchy")` find
Omarchy's own tree. `default.hypr.omarchy` then loads Omarchy's autostart,
environment, look and feel, input and window rules — and its bindings, unless
`omarchy_default_bindings` was set to `false` first. It is, so **every key on
this machine is in `bindings.lua`** and an Omarchy update cannot move one.
The cost is the other side of the same coin: a binding Omarchy adds later does
not arrive by itself.

The modules here run after Omarchy's, so they win: `input.lua` is the `tr`
keyboard and the touchpad, `looknfeel.lua` the gaps, the Qt environment and the
window rules, `monitors.lua` the scale, `autostart.lua` what this machine starts
besides the shell (the wallet handoff, kded, hypridle, cliphist, the Tuxedo
tray).

Bindings are written with Omarchy's helper, not `hl.bind` directly:

```lua
o.bind("SUPER + RETURN", "Terminal (Alacritty)", "alacritty")
o.bind("SUPER + SHIFT + B", "Web Browser (Default)", { omarchy = "browser" })
o.bind("SUPER + W", "Close window", hl.dsp.window.close())
```

The second argument is the description `SUPER+K` shows; a bind without one is a
bind nobody can look up.

There is no `hyprland.conf` on this branch. Hyprland 0.56 prefers
`hyprland.lua` when both exist and chooses once, at startup, so a `.conf` beside
it was a file nothing read; `hyprctl systeminfo | grep configProvider` says
which one a session is on.

### fuzzel is gone

The fuzzel menus this repo used to bind — a hotkey list on `SUPER+F1`, a window
picker on `SUPER+Q` and `SUPER+TAB` — are not on this branch: the scripts and
the three keys were removed, and `SUPER+K` is Omarchy's own list of bindings.
No binding calls fuzzel any more. The "Quit Hyprland?" prompt it drew on
`SUPER+SHIFT+H` and `CTRL+ALT+DELETE` is replaced by Omarchy's system menu, and
`SUPER+V` opens the shell's clipboard panel with no fallback.

### `desktop/.config/omarchy`

Omarchy's user directory: `shell.toml` and `shell.json` for the shell,
`extensions/omarchy-menu.jsonc` for entries added to its menu, `hooks/` for the
scripts it runs on update, boot and theme change (the `.sample` files are
Omarchy's own examples, inert until renamed), and `branding/`. Its `.gitignore`
keeps `themes/` and `plugins/` out — both are installed by Omarchy and are not
this repo's to version.

`shell.json` is written by the shell's settings pages. When it shows up as a
conflict in `./link.sh status`, there is a real file where the symlink should
be and the two copies have drifted; diff them first, then
`./link.sh adopt desktop ~/.config/omarchy/shell.json` pulls the live one in
over the repo's.

### `fixes/` and `themes/`

Neither is a package. `fixes/` is a set of scripts run by hand, once per
machine, each for one thing Omarchy or this laptop's hardware gets wrong —
Chromium on NVIDIA, the workspace buttons stopping at five, the key visualizer
assuming a US layout, the Windows VM dying when its window closes. They write
into `$HOME` and some of them patch files Omarchy owns, so an Omarchy update can
undo one and it has to be run again. `fixes/README.md` has the list;
`fixes/run-all.sh` runs six of them, and the rest (`fix-tmux_up.sh`,
`fix-volume-150.sh`, `fix-davinci-resolve.sh`, `fix-antigravity-agent.sh`,
`remove-old-gemini.sh`, `fix-nvidia-hibernate.sh`) are run one at a time.
`fix-debtap-grep.sh`, `fix-tuxedo-control-center.sh` and
`fix-nvidia-hibernate.sh` use sudo.

`themes/install-rainynight.sh` hands the theme submodule's repository to
`omarchy theme install`; `omarchy theme set omarchy-rainynight-theme` applies it.

---

## Install on a clean machine

On this branch the machine is installed by Omarchy's own installer first; what
this repo adds is the links.

```bash
git clone --recurse-submodules git@github.com:alihancaliskanx/dotfiles.git ~/Documents/Code/dotfiles
cd ~/Documents/Code/dotfiles

./link.sh profile hyprland
```

That is enough for the configs. `install.sh` is for everything else the machine
is expected to have:

```bash
./install.sh hyprland      # or: kde
```

`install.sh` does the following, in order:

1. Installs the pacman + AUR packages for the profile
2. Installs the flatpak apps in `extras/flatpak-apps.txt`
3. Clones oh-my-zsh, powerlevel10k and 5 zsh plugins
4. Links the configs with `./link.sh profile <profile>`

It reads `ID=` from `/etc/os-release`, and on Omarchy it installs **no desktop**:
Hyprland, the bar, the launcher and the notification daemon already came with
the system, and a second set beside them is two of everything. What goes in is
the rest of the list — terminals, editors, the network tools the scripts shell
out to, fonts, applications.

If you are behind a proxy (PdaNet etc.):

```bash
PROXY=192.168.49.1:8000 ./install.sh hyprland
```

If you only want to link the configs and not install packages, `./link.sh` is enough.

---

## Packages

Each top-level directory is a "package"; the tree inside it is mirrored exactly into `$HOME`.
Example: `desktop/.config/omarchy/shell.toml` → `~/.config/omarchy/shell.toml`.

| Package    | Contents                                                        |
|------------|-----------------------------------------------------------------|
| `shell`    | `.zshrc` + `~/.config/zsh/` modules, `.bashrc`, `.p10k.zsh`, `starship.toml` |
| `hypr`     | `hyprland.lua` + its five modules, `hypridle.conf`, `hyprlock.conf`, the portal pins |
| `desktop`  | `~/.config/omarchy/`, the Windows VM launchers, chromium flags  |
| `terminal` | alacritty, kitty, ghostty                                       |
| `nvim`     | LazyVim-based configuration (`lazy-lock.json` included)          |
| `vscode`   | `~/.config/Code/User/settings.json` (extensions: see below)      |
| `git`      | `~/.config/git/config` — aliases, identity, gh credential helper; includes the untracked `config.local` |
| `xdg`      | `mimeapps.list` — which application opens which file type        |
| `cli`      | btop theme, cava, tmux, `~/.proxychains/tor.conf`               |
| `scripts`  | the shared tools under `~/.local/bin/` (see below)              |
| `services` | `ssh-agent.service`, the Qt theme env, cliamp's D-Bus name      |
| `theme`    | aether, Vencord, vicinae, warp-terminal rainynight themes, the `RainyNight` Qt colour scheme |
| `wallpapers` | `~/Pictures/Wallpapers/` — the images themselves              |
| `kdeglobals` | the palette Qt apps read — Dolphin, Ark, Gwenview              |
| `gtk`      | GTK3/GTK4 css — *not part of a profile*, see the warning below  |

Not linked: `extras/` (manually imported VSCode/Chromium/icon themes, the
package snapshots, `vscode-extensions.txt`, the theme submodule), `fixes/`,
`themes/` and the top-level scripts. Nothing in `extras/` is symlinked, which is
exactly why the extension list lives there: every file inside a package lands in
`$HOME` at the same relative path.

### Profiles

A profile is a named set of packages. `shell terminal nvim vscode cli scripts services theme wallpapers kdeglobals git xdg`
is common to all of them; the desktop-specific ones are added on top.

| Profile    | Extra packages    |
|------------|-------------------|
| `hyprland` | `hypr` `desktop`  |
| `kde`      | — (common only)   |

`gtk` is deliberately in no profile; it is linked on request.

---

## link.sh

```bash
./link.sh                      # link the default profile
./link.sh profile              # list the profiles
./link.sh profile hyprland     # link the packages of a profile
./link.sh link gtk             # link individual packages
./link.sh status               # which package is linked, which is not
./link.sh unlink nvim          # remove a single package
./link.sh adopt gtk            # pull the real files from $HOME into the repo
./link.sh adopt cli ~/.config/btop/btop.conf     # move one new file into a package
./link.sh clean                # remove links left pointing at files the repo no longer has
./link.sh -n ...               # dry-run: show what it would do, touch nothing
./link.sh -f ...               # rename a conflicting real file to .bak.<date> and link over it
```

A conflict is an **error** by default, nothing is silently overwritten.
`unlink` only deletes symlinks pointing at this repo, it never touches real files.

To change the default profile: `DOTFILES_PROFILE=kde ./link.sh`

### adopt — pulling a file from $HOME into the repo

The equivalent of `stow --adopt`. For writing a new config under `~/.config/`
first and pulling it into the repo afterwards:

```bash
# move a new file into a package and put a symlink in its place
./link.sh adopt cli ~/.config/btop/btop.conf

# for every file in the package, pull in the real version from $HOME
./link.sh adopt gtk
```

> **Caution:** the second form **overwrites** the content in the repo. Make sure
> it is clean with `git status` first, then look at what changed with `git diff`.
> Running a dry-run with `-n` first is a good idea.

### clean — after something is deleted from the repo

`unlink` walks the files a package has. A file that was deleted from the repo is
not one of them, so its symlink in `$HOME` is left dangling and nothing ever
visits it again. `clean` finds those — symlinks that point into this repo at a
path that is no longer there — and removes them:

```bash
./link.sh -n clean
./link.sh clean
```

It looks in `$HOME` one level deep and in every directory a package links into,
`.config` and `.local` always. A dangling symlink that points anywhere else is
not this repo's and is left alone.

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
and up) over every script, the Hyprland config, `test.sh`, `jq` on the tracked
JSON, `stylua --check` on the nvim config, and whether every package directory
is actually reachable from a profile.

The Hyprland config is checked two ways. The Lua modules get `luac -p`, which
is syntax and nothing more but runs anywhere `luac` does. And `hyprland.lua` is
loaded for real, by `Hyprland --verify-config`, which is the one that notices a
call to a function that does not exist.

That last one needs Omarchy's tree under `$OMARCHY_PATH`, and it needs to be
told which files to read: the bootstrap resolves `require("hypr.bindings")`
against `$HOME/.config`, which is whatever happens to be linked. So the check
runs under a throwaway `HOME` whose `.config/hypr` is this repo's directory —
and with `XDG_STATE_HOME` and `XDG_CONFIG_HOME` unset, because Omarchy lists its
state directory through one and requires what it found through the other, and
with the two pointing at different homes it finds modules it cannot load.

A check whose tool is missing is **skipped, not failed** — the GitHub runner
(`.github/workflows/check.yml`, on pushes to `main` and `omarchy`) has no
compositor and no Omarchy to ask. Locally the full set runs; shellcheck and stylua come
from mason if they are not installed system-wide:

```bash
PATH="$HOME/.local/share/nvim/mason/bin:$PATH" ./check.sh
```

---

## test.sh

```bash
./test.sh
```

`link.sh` decides everything that lands in `$HOME`, and for a long time the only
way it was checked was by running it on the machine it was written for.
`test.sh` copies it next to a handful of fixture packages in a temporary
directory, points `TARGET` at an empty one, and asserts what each command leaves
behind: that a dry run creates nothing, that a second run changes nothing, that
a real file in the way is an error and survives it, that `-f` keeps a backup,
that `unlink` and `clean` remove only what is this repo's, that `adopt` moves
the file and leaves the link.

Nothing outside the temporary directory is read or written, so it runs in CI as
part of `check.sh`. The first thing it found was that a package name that does
not exist was reported as linked.

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
repositories are the same gap from the other side — this machine takes its
x86-64-v4 builds from them, and nothing else here says so.

The order is not decoration. pacman takes the first repository that holds a
package, and the whole point of `cachyos-v4` is to shadow `core` and `extra` with
x86-64-v4 builds. So a missing repository is not appended, where it would shadow
nothing: it is **inserted above whichever of the repositories listed after it
comes first in the file**. Earliest in the file rather than next in the list,
because a `pacman.conf` somebody has already edited need not be in this order —
this machine's has `[core]` above the cachyos repos — and "above the next one"
can then still be below one that should lose. Only a repository with nothing
after it present is appended. `blackarch` goes last, being the widest and least
curated.

| | |
|---|---|
| `omarchy` | first; `pkgs.omarchy.org/stable`, signed — needs `omarchy-keyring` |
| `cachyos-v4` `cachyos-core-v4` `cachyos-extra-v4` | x86-64-v4 builds, above core/extra so they win |
| `cachyos` | CachyOS's own packages — the kernel, the settings packages |
| `core` `extra` `multilib` | Arch's |
| `chaotic-aur` | prebuilt AUR packages; needs `chaotic-keyring` and `chaotic-mirrorlist` |
| `blackarch` | last |

A repository already in `pacman.conf` is never moved, so the script does not
repair an order that is already wrong — on this machine `[omarchy]` is the last
section and stays there.

It checks before it enables: the v4 repos are gated on the loader's own answer to
whether this CPU has x86-64-v4 (enabling them without AVX-512 does not fail
loudly — pacman installs binaries that then die with `SIGILL`), and missing
mirrorlists and keyrings are named rather than assumed. blackarch's key is the
one thing it will not do for you; that needs `strap.sh`, and a script in this
repo is not going to download and execute a remote installer on your behalf.

Idempotent, and it backs up `pacman.conf` before touching it.

---

## the omarchy theme, as a submodule

This machine runs [Omarchy](https://omarchy.org), and its theme is
`omarchy-rainynight-theme`. That theme is a repository of its own —

```bash
git clone --recurse-submodules git@github.com:alihancaliskanx/dotfiles.git
git submodule update --init          # if you cloned without --recurse-submodules
```

| | |
|---|---|
| where | `extras/omarchy-rainynight-theme` |
| remote | `git@github.com:alihancaliskanx/omarchy-rainynight-theme.git` |
| was | a fork of [`atif-1402/omarchy-rainynight-theme`](https://github.com/atif-1402/omarchy-rainynight-theme) |

**It is not a fork any more.** GitHub has no way to detach one in place, so the
fork was renamed to `omarchy-rainynight-theme-fork` and a repository of the same
name created fresh; the merged history was pushed there. The old one is left
alone rather than deleted. It still keeps `upstream` pointing at atif-1402, so
`git fetch upstream && git merge upstream/main` is how it catches up — it was
eleven commits behind when this was done.

**A submodule rather than a copy**: it is a repo with its own life, and this only records which commit of it belongs
with this branch.

**Under `extras/` on purpose.** That is the one directory here that is never
symlinked — `link.sh`'s `all_packages` skips it and `check.sh`'s orphan check
skips it too — so a whole theme tree can sit there without any of it reaching
`$HOME` or being mistaken for a package. Both were checked: `./link.sh status`
does not list it, and `./check.sh` stays green.

### what is actually in it

Worth knowing before taking colours out of it: **it is not one palette.**

| file | palette |
|---|---|
| `alacritty.toml`, `warp.yaml` | Catppuccin Mocha — and `warp.yaml` is named *Aether* |
| `colors.toml` | Catppuccin too (came from upstream) |
| `neovim.lua` | a third set again — `#0d0f1a`, `#1e2030` |
| `hyprland.conf` | the group block is rainynight, `rgb(303463)` |

None of those is the rainynight `main` actually runs, which is `#101010` with
`#5de4c7` as the accent and `#303463` for selection. **The dotfiles palette is
the authority**; this submodule is a source to take colour *from*, not a thing to
sync colour *to*. Nothing in it is wired into anything here yet.

Its `backgrounds/` carries the wallpapers this machine uses, which is what makes
the theme installable on its own — `starry-sky.jpg` is deliberately absent from
that set, being byte-identical to the `4.jpg` already there.

The submodule is a record, not the install path. Omarchy reads themes from its
own directory, so what puts this one on the machine is
`themes/install-rainynight.sh`, which gives the same repository to
`omarchy theme install` over https. A checkout without the submodule
initialised (`git submodule status` prints a leading `-`) loses nothing that
runs.

---

## Shell configuration

zsh is modular; there is no single huge file:

| Module            | What's in it                                      |
|-------------------|---------------------------------------------------|
| `00-env`          | definitions: PATH, EDITOR, `PROXY_ADDR`, env      |
| `05-omarchy`      | mise, zoxide, `open` — what Omarchy's bash rc sets up, for zsh |
| `10-plugins`      | oh-my-zsh, powerlevel10k, fzf                     |
| `20-aliases`      | aliases                                           |
| `30-proxy`        | proxy + Tor: env functions and shortcuts          |
| `40-functions`    | other custom functions                            |
| `50-local`        | machine specific: conda/mamba, nvm, distrobox     |

The modules live in `~/.config/zsh/*.zsh`; `.zshrc` is just a loader that sources them in order.

To add a new module all you need is to drop `<order>-<name>` into the directory, nothing else.

**bash** is Omarchy's, not this repo's: `.bashrc` sources
`/usr/share/omarchy/default/bash/env-bootstrap` and then
`$OMARCHY_PATH/default/bash/rc`, and adds a few lines after. `starship.toml` is
the prompt that rc starts; zsh skips starship and keeps powerlevel10k, and
`05-omarchy` exists so that zsh still gets the mise and zoxide setup bash gets
from that rc for free.

### Shared scripts

So that a function is not tied to one shell,
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
| `power-profile`| cycle power-saver → balanced → performance (Super+Shift+P)      |
| `omarchy-media` | play/pause, next, previous sent to every MPRIS player on the bus (the media keys) |
| `omarchy-smart-focus` | directional focus that cycles windows instead when the active one is maximized (Super+arrows) |
| `omarchy-window-full-width-toggle` | widen the active window to the monitor and back (Super+Alt+F) |
| `windows-vm-smart-launch.sh` `windows-vm-stop.sh` | focus the Windows VM if it is open, start it if not; stop it on purpose (Super+Ctrl+Shift+W) |
| `code-extensions` | the VS Code extension list: `status` / `save` / `install`   |
| `pkg-snapshot` | what is installed on this machine: `diff` / `save` / `install`  |
| `pam-kwallet-env` | hands the session environment to the ksecretd pam started, so the wallet is unlocked at login instead of asking (run first at startup) |
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
- **tor-control** — does not work without `gum` (`sudo pacman -S gum`).
- **ssh-agent** — `systemctl --user enable --now ssh-agent`.
- **Packages come in two lists.** `install.sh` carries the curated one: what a
  fresh machine *should* have, grouped by what it is for. `extras/pacman-explicit.txt`
  and `extras/flatpak-apps.txt` carry the other one — everything this machine
  actually has, written by `pkg-snapshot save` and put back by
  `pkg-snapshot install`. The first answers "set up a machine like mine", the
  second "bring my machine back". `pkg-snapshot` with no argument diffs them.
- **The browser** — Zen, from the `zen-browser-bin` package. `SUPER+B` opens
  whatever `xdg-settings get default-web-browser` answers, which is
  `zen.desktop`, and `mimeapps.list` in the `xdg` package is what makes that the
  answer.
- **Qt apps** — Omarchy sets `QT_QPA_PLATFORMTHEME=gtk3`; `looknfeel.lua`
  changes it to `kde`, so Dolphin, Ark and Gwenview take their palette from
  `~/.config/kdeglobals`, which is the `kdeglobals` package and names the
  `RainyNight` scheme in `theme`. KDE's own settings app rewrites that file; if
  it ever replaces the symlink with a real one, `./link.sh status` shows the
  conflict.
- **VS Code** — only `settings.json` is linked. The extensions themselves are
  downloaded builds under `~/.vscode/extensions`, so what is versioned is the
  list of their ids in `extras/vscode-extensions.txt`:
  `code-extensions status` compares it with what is installed, `save` records
  the current set, `install` pulls the missing ones. Worth a `status` after
  adding an extension — nothing writes the list by itself.
  If VS Code ever replaces the symlink with a real file of its own, `./link.sh
  status` reports it as a conflict and `./link.sh adopt vscode
  ~/.config/Code/User/settings.json` pulls it back into the repo.

---

## Things worth knowing

**The wallpapers are in the repo, and one of them twice over would be a bug.**
`wallpapers` carries `~/Pictures/Wallpapers/` — 27 MB of photographs, which is
why it is its own package and not part of `theme`.

`starry-sky.jpg` in that package is a **symlink**, not a ninth image. The real
file is `theme/.local/share/wallpapers/StarrySky/contents/images/1920x1080.jpg`,
and `extras/backgrounds/starrysky.jpg` is the same symlink from the other side.
Three references, one file on disk; adopting it as a real file again would put
2.4 MB of duplicate into the history. `link.sh` links that `StarrySky` directory
as one symlink rather than file by file (`LINK_AS_DIR`), and nothing inside it
may be a symlink itself.

**Hibernation is Omarchy's, and NVIDIA in the initramfs breaks it.** Omarchy's
`omarchy-hibernation-setup` set it up at install: a RAM-sized swapfile at
`/swap/swapfile`, in a btrfs subvolume of its own so snapper's snapshots of `@`
never catch it, the `resume` hook in mkinitcpio, and `resume=` and
`resume_offset=` through `/etc/limine-entry-tool.d/resume.conf`. zram stays the
swap everything pages to; it lives in RAM and cannot hold an image. The system
menu shows Hibernate only while `omarchy-hibernation-available` succeeds.

What broke it here was NVIDIA. Omarchy's NVIDIA setup loads the nvidia modules
in the initramfs for early KMS (`/etc/mkinitcpio.conf.d/nvidia.conf`), and
gpu-screen-recorder sets `NVreg_PreserveVideoMemoryAllocations=1`. The boot
kernel then reads the whole image, the driver refuses to freeze, and the session
is thrown away: `PM: hibernation: resume failed (-5)`. The panel on this laptop
is wired to the Intel iGPU, so early NVIDIA KMS buys nothing;
`fixes/fix-nvidia-hibernate.sh` moves the drop-in aside and rebuilds the
initramfs. An Omarchy reinstall writes the drop-in again.

After any resume, from suspend or hibernate, the lock screen ignores the
keyboard until the touchpad moves or the lock is clicked. The kernel switches VT
on the way down and back, and Hyprland 0.56 does not give the session-lock
surface its keyboard focus back; locking and then pressing Ctrl+Alt+F3 and
Ctrl+Alt+F1 does the same without sleeping. Neither a warp
(`hl.dsp.cursor.move`) nor a short-lived uinput mouse brought it back in
testing.

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
weight.

`gtk-4.0/gtk.css` is a symlink to the `gtk-3.0` one — one file, two locations,
so the two toolkits cannot drift apart.

**GTK has no `filter` property.** The theme this css came from carried a
`.svg-icon { filter: invert(…) … }` block, which is web CSS. GTK ignored the
rule but printed `Theme parsing error: gtk.css:164: 'filter' is not a valid
property name` on the startup of every single GTK application. It is gone, and
the `@import` now sits at the top of the file where CSS requires it to be.

**Compositor `env` blocks do not reach systemd services.**
`QT_QPA_PLATFORMTHEME=kde` set from the compositor config — `hl.env` in
`looknfeel.lua` here, where it overrides the `gtk3` Omarchy sets — only reaches
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
Hyprland). `kwinrc`, `plasmarc` and the rest stay out: they are constantly
rewritten by KDE and would produce constant conflicts.

**`~/.config/git/config` is tracked, and what belongs to one machine is not in it.**
The file is a symlink into this repo, and `git config --global` writes through
it — so anything set that way shows up in `git diff` and, if you are not
looking, in a commit. `net-proxy git on` used to put the tethering proxy there.

The tracked file now ends with

```ini
[include]
	path = ~/.config/git/config.local
```

and `net-proxy` writes to that file instead. It is not in the repo and git does
not mind when it is missing, so a fresh machine needs nothing. It is also the
place for anything else that should not be shared: set it with

```bash
git config --file ~/.config/git/config.local <key> <value>
```

`--global` still means the tracked file. `net-proxy git off` clears the proxy
from both, for the copy an older version left behind.

Note also that `[https] proxy` is not a thing git reads; only `http.proxy` (and
`http.<url>.proxy`) does anything. The `[https]` section is inert.

**Do not use `systemctl --user reenable`.**
Because the unit file is a symlink, the `disable` step deletes it. If you need to:
`./link.sh link services && systemctl --user enable ssh-agent`

**The compositor's PATH is not the shell's, and the order in it matters.**
Hyprland never sources `.zshrc`, so the `~/.local/bin` that `00-env` prepends is
not where a keybinding gets it from. The session's PATH has it anyway, further
back, and Omarchy's `envs.lua` then puts its own `bin` directory in front of
everything. Two consequences for `bindings.lua`:

- a script from the `scripts` package can be bound by bare name
  (`power-profile`, `TuxedoRGBKeyboard.sh`) and is found;
- a script in `~/.local/bin` that **replaces** one of Omarchy's — the
  `omarchy-audio-output-volume` that `fixes/fix-volume-150.sh` installs — is
  not, because Omarchy's copy is ahead of it. Those are bound as
  `~/.local/bin/<name>`, spelled with `~` and never with a home directory
  written out.

To see what a keybinding will actually run:

```bash
tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ | grep '^PATH='
```

**The Settings portal backend is pinned per compositor.**
`xdg-desktop-portal-hyprland` does not implement
`org.freedesktop.impl.portal.Settings`, and with kde, gtk and gnome backends all
installed nothing decided which one answers. The portal cached
`org.freedesktop.appearance color-scheme` as "prefer light" at login and never
noticed the desktop was dark, so Firefox-based apps drew white context menus.
`hypr/` ships a `hyprland-portals.conf` pinning Settings to the gtk backend,
while keeping `default=hyprland;gtk` so screencasting still goes to Hyprland's
own backend.

**KDE apps need `XDG_MENU_PREFIX` outside Plasma.**
`plasma-workspace` only ships `/etc/xdg/menus/plasma-applications.menu`, and KDE
apps look for `$XDG_MENU_PREFIX` + `applications.menu`. A Plasma session sets the
variable to `plasma-`; under Hyprland it was unset, so the menu was never
found — `kbuildsycoca6 --menutest` printed 0 entries instead of 138, and every
KIO "Open With → Other Application…" dialog came up empty. `looknfeel.lua` sets
`XDG_MENU_PREFIX=plasma-`.

**`XDG_CURRENT_DESKTOP` is plain `Hyprland`.**
It used to be `Hyprland:KDE`, because entries with `OnlyShowIn=KDE` (System
Settings, Info Center, the emoji picker) are hidden from every launcher when the
variable is plain `Hyprland`. That suffix produced portal warnings under Omarchy
and was taken back off in `looknfeel.lua`, so those entries are hidden again —
the trade was made knowingly, and this is where to look when System Settings is
missing from the menu.

**Screenshots go through grim, piped into tensaku.** Spectacle was tried and does not work
here: it drives KWin's own `org.kde.KWin.ScreenShot2` API, and with no KWin
under Hyprland it produces no file and no error at all.

**The conda/mamba blocks** run if `$HOME/miniforge3` exists, and are skipped otherwise.
Without the guard they tried to run a non-existent binary on every shell startup.

**Leftover dead references** (guarded, not deleted):
the `~/Documents/Code/aurapilot/ardupilot/Tools/autotest` directory does not
exist — either create it or delete the PATH line in `00-env`. `hyprlock` still
takes a blurred snapshot of the desktop (`path = screenshot`) rather than the
wallpaper, which is deliberate: it works on a machine with no image at all.
