# 🛠️ Dotfiles Fixes & Workarounds

This directory contains scripts that resolve hardware and software incompatibilities encountered in the Omarchy / Hyprland / NVIDIA hybrid graphics environment.

---

## 📁 Scripts and Descriptions

### 1. `fix-chromium-nvidia-glitches.sh`
* **Issue:** Screen tearing, flickering, and KDE Wallet password prompt pop-ups under NVIDIA + Wayland in Grok, ChatGPT, and Chromium-based web applications.
* **Solution:**
  - Adds `--disable-gpu-compositing` and `--disable-features=WaylandFractionalScaleV1` flags to `~/.config/chromium-flags.conf` and `chrome-flags.conf`.
  - Disables KDE Wallet warnings by setting `--password-store=basic` and `Enabled=false` in `~/.config/kwalletrc`.
  - Clears corrupted `GPUCache` caches.

### 2. `fix-omarchy-workspaces.sh`
* **Issue:** Workspaces on the Omarchy top panel are limited to 1..5, and the active desktop icon hides the number.
* **Solution:**
  - Creates the `sups.workspaces` plugin to make the `1 2 3 4 5 6 7 8 9 0` buttons persistent and refreshes the panel instantly.

### 3. `fix-windows-vm.sh`
* **Issue:** 
  - When the Windows VM window is closed with `Super+W`, the virtual machine starts shutting down in the background, resulting in a *"Failed to start"* error if reopened immediately.
  - The Windows VM window opens in a floating state.
* **Solution:**
  - Installs the smart scripts `windows-vm-smart-launch.sh` and `windows-vm-stop.sh`; focuses the window if it's open, starts it in the background if closed, and never shuts it down abruptly.
  - Adds the `o.window("xfreerdp", { tile = true })` window rule to Hyprland's `looknfeel.lua`.

### 4. `fix-key-visualizer-turkish.sh`
* **Issue:** The `omarchy-key-visualizer` plugin assumes an English (US) layout without querying the actual keyboard layout; causing Turkish characters and Shift combinations to display incorrectly or produce UTF-8 capitalization errors.
* **Solution:**
  - Dynamically queries the active keyboard layout via Hyprland.
  - Integrates Turkish Q and Turkish F keymaps, as well as a UTF-8 Turkish uppercase conversion table into `key-visualizer.lua`.

### 5. `fix-tuxedo-control-center.sh`
* **Issue:** Missing hardware control, power profiles, and keyboard backlight support for Tuxedo laptops.
* **Solution:**
  - Installs `tuxedo-control-center-bin` and `tuxedo-drivers-nocompatcheck-dkms` via AUR.
  - Enables and starts the `tccd.service`.
  - Configures Tuxedo Control Center to run automatically on startup via `~/.config/autostart`.

### 6. `fix-debtap-grep.sh`
* **Issue:** `debtap` uses a regex that grep 3.8+ rejects, so it concludes its package database is empty.
* **Solution:**
  - Patches the regex in `/usr/bin/debtap` in place. Uses `sudo`, and has to be run again after `debtap` is upgraded.

### 7. `fix-volume-150.sh`
* **Issue:** Omarchy caps the output volume at 100%, both on the volume keys and on the panel slider.
* **Solution:**
  - Copies `omarchy-audio-output-volume` to `~/.local/bin/` with the limit raised to 150.
  - Rewrites the volume bindings in `~/.config/hypr/bindings.lua` to call that copy by path, because Omarchy's own `bin` directory is ahead of `~/.local/bin` on the compositor's `PATH`.
  - Clones the `omarchy.audio` shell plugin and raises the slider maximum to 1.5.
* **Note:** the bindings file is a symlink into this repository, so the script edits a tracked file. It writes the path as `~/.local/bin/...`, the way the tracked bindings spell it, so running it on an up-to-date checkout leaves `git diff` empty.

### 8. `fix-tmux_up.sh`
* **Issue:** No single key brings up the usual set of tmux sessions.
* **Solution:**
  - Writes `~/.local/bin/tmux_up.sh`, which creates the `HOME`, `AURA`, `CODE` and `HACK` sessions if they are missing and attaches to `HOME`.
  - Writes the `omarchy-launch-terminal-tmux_up` wrapper that `SUPER + CTRL + RETURN` is bound to.

### 9. `fix-davinci-resolve.sh`
* **Issue:** DaVinci Resolve fails with *"Unable to Initialize GPU"* on a hybrid-GPU laptop when the display is driven by the iGPU.
* **Solution:**
  - Copies `DaVinciResolve.desktop` to `~/.local/share/applications/` and rewrites its `Exec` line to run on the NVIDIA GPU through XWayland.

### 10. `fix-antigravity-agent.sh`
* **Issue:** Antigravity is not among the agents Omarchy's menu offers as the default.
* **Solution:**
  - Adds the entry to `~/.config/omarchy/extensions/omarchy-menu.jsonc` and installs an `omarchy-default-agent` wrapper in `~/.local/bin/` that knows about it.

### 11. `remove-old-gemini.sh`
* Uninstalls the `gemini` CLI that was installed through `mise` and removes its wrapper from `~/.local/bin/`.

### 12. `fix-qt612-color.sh`
* **Issue:** The Omarchy shell's `Color` singleton collides with a name in Qt 6.12's QML namespace.
* **Solution:**
  - Renames the singleton to `ThemeColor` in `Commons/qmldir` and rewrites every `Color.` reference in the shell's QML and JS files.
  - Clears the quickshell QML cache and restarts the shell with `omarchy-restart-shell`.
* **Note:** uses `sudo` to patch `/usr/share/omarchy/shell`, so an Omarchy update undoes it and the script has to be run again.

### 13. `fix-matlab-installer.sh`
* **Issue:** The MATLAB installer segfaults on Arch-based systems, once while reading the CPUID vendor string (a fault at `0x6c65746e`) and once in GnuTLS.
* **Solution:**
  - Extracts the installer zip given as its argument to `/tmp/matlab_installer`.
  - Compiles a small shim that maps the faulting addresses, and runs the installer with the shim and `libleancrypto.so` preloaded.
  - Writes `~/.local/share/applications/matlab_<release>.desktop` once the installer has finished.
* **Note:** needs `gcc` and `unzip`. The installer is interactive: enter the destination folder and the symbolic link folder the script prints (`~/MATLAB/<release>` and `~/.local/bin`, as absolute paths) so that nothing needs root.

### 14. `fix-robodk-browser.sh`
* **Issue:** The **Open** button of the RoboDK online library does nothing, because a RoboDK installed by hand registers no handler for `robodk://` links.
* **Solution:**
  - Copies `RoboDK.desktop` from `~/Desktop` to `~/.local/share/applications/` if it is not there yet.
  - Appends `%U` to its `Exec` line and adds a `MimeType` line for the scheme and RoboDK's file types.
  - Sets it as the default handler with `xdg-mime`.
* **Note:** `xdg-mime` writes `~/.config/mimeapps.list`, which is a symlink into this repository, so the script edits a tracked file. Restart the browser afterwards.

### 15. `run-all.sh`
* Runs scripts 1 to 6 in sequence. Scripts 7 to 14 are not part of it and are run one at a time.

---

## 🚀 Usage

```bash
# To apply all fixes at once:
./fixes/run-all.sh

# Or to run a single fix:
./fixes/fix-chromium-nvidia-glitches.sh
./fixes/fix-omarchy-workspaces.sh
./fixes/fix-windows-vm.sh
./fixes/fix-key-visualizer-turkish.sh
./fixes/fix-tuxedo-control-center.sh
./fixes/fix-debtap-grep.sh
./fixes/fix-volume-150.sh
./fixes/fix-tmux_up.sh
./fixes/fix-davinci-resolve.sh
./fixes/fix-antigravity-agent.sh
./fixes/remove-old-gemini.sh
./fixes/fix-qt612-color.sh
./fixes/fix-matlab-installer.sh ~/Downloads/matlab_R2026b_Linux.zip
./fixes/fix-robodk-browser.sh
```
