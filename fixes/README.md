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

### 5. `run-all.sh`
* Runs all fix scripts sequentially at once.

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
```
