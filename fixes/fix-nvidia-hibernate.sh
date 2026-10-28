#!/bin/bash
# Fix for hibernation that never comes back on a hybrid NVIDIA laptop
# Omarchy's NVIDIA setup loads the nvidia modules in the initramfs for early
# KMS, and gpu-screen-recorder ships NVreg_PreserveVideoMemoryAllocations=1.
# Together they throw every hibernation image away: the boot kernel loads
# nvidia, reads the whole image, then the driver refuses to freeze because no
# nvidia-suspend service exists inside an initramfs:
#   NVRM: ... PreserveVideoMemoryAllocations module parameter is set. System
#         Power Management attempted without driver procfs suspend interface.
#   PM: hibernation: resume failed (-5)
# When the panel is wired to the iGPU, early NVIDIA KMS buys nothing, so this
# moves Omarchy's drop-in aside and rebuilds the initramfs without it.

set -euo pipefail

CONF_DIR="${MKINITCPIO_CONF_DIR:-/etc/mkinitcpio.conf.d}"
MAIN_CONF="${MKINITCPIO_CONF:-/etc/mkinitcpio.conf}"
DROP_IN="$CONF_DIR/nvidia.conf"

echo "=> Keeping the nvidia modules out of the initramfs..."

if [ ! -f "$DROP_IN" ]; then
    echo "=> No $DROP_IN, skipping."
    exit 0
fi

for cmd in omarchy-hw-nvidia-display limine-mkinitcpio; do
    command -v "$cmd" >/dev/null || { echo "Error: $cmd not found. Is this Omarchy with Limine?"; exit 1; }
done

if omarchy-hw-nvidia-display; then
    echo "=> NVIDIA drives the display here and needs early KMS, leaving it alone."
    exit 0
fi

sudo mv -f "$DROP_IN" "$DROP_IN.disabled"
echo "=> Moved $DROP_IN to nvidia.conf.disabled"

others=$(grep -lE '^[[:space:]]*MODULES\+?=\(.*nvidia' "$MAIN_CONF" "$CONF_DIR"/*.conf 2>/dev/null || true)
if [ -n "$others" ]; then
    echo "Warning: nvidia is still in MODULES in:"
    echo "$others"
fi

sudo limine-mkinitcpio

echo "------------------------------------------------------"
echo "=> Done!"
echo "Reboot, then hibernate once to check that the session comes back."
echo "An Omarchy reinstall writes $DROP_IN again; run this again after one."
