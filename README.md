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
| `desktop`  | waybar (Hyprland + niri variants), fuzzel, mako, swayosd        |
| `terminal` | alacritty, kitty, ghostty                                       |
| `nvim`     | LazyVim-based configuration (`lazy-lock.json` included)          |
| `cli`      | btop theme, cava, `~/.proxychains/tor.conf`                     |
| `scripts`  | the shared tools under `~/.local/bin/` (see below)              |
| `services` | `ssh-agent.service` (systemd user unit)                         |
| `theme`    | aether, Vencord, vicinae, warp-terminal rainynight themes       |
| `gtk`      | GTK3/GTK4 css — *not part of a profile*, see the warning below  |

Not linked: `extras/` (manually imported VSCode/Chromium/icon themes,
wallpapers) and the install scripts.

### Profiles

A profile is a named set of packages. `shell terminal nvim cli scripts services theme`
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
link it, `./link.sh -f link gtk`, but know that KDE will overwrite it.

**KDE's own `*rc` files are deliberately not tracked.**
`kdeglobals`, `kwinrc` and `plasmarc` are constantly rewritten by KDE; tracking
them would produce constant conflicts. The `kde` profile only links the common packages.

**`~/.config/git/config` is deliberately not in the repo.**
`git config --global` writes the file with lock+rename, which replaces the
symlink with a real file. Since `net-proxy git on` does exactly that, tracking it
is pointless.

**Do not use `systemctl --user reenable`.**
Because the unit file is a symlink, the `disable` step deletes it. If you need to:
`./link.sh link services && systemctl --user enable ssh-agent`

**The conda/mamba blocks** run if `$HOME/miniforge3` exists, and are skipped otherwise.
Without the guard they tried to run a non-existent binary on every shell startup.

**Leftover dead references** (guarded, not deleted):
the `~/Documents/Code/aurapilot/ardupilot/Tools/autotest` directory does not
exist — either create it or delete the PATH line in `00-env`. `hyprpaper` gets
installed but there is no `hyprpaper.conf`; `extras/backgrounds/4.jpg` is not
used from anywhere (`hyprlock` uses `path = screenshot`).
