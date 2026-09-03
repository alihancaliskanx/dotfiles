#!/bin/bash
# Fix for DaVinci Resolve on Optimus/Hybrid GPU systems (NVIDIA + Wayland)
# This forces Resolve to use the NVIDIA GPU and XWayland to avoid the 
# "Unable to Initialize GPU" error when the display is connected to the iGPU.

echo "Applying DaVinci Resolve Hybrid GPU fix..."

mkdir -p ~/.local/share/applications/

if [ -f /usr/share/applications/DaVinciResolve.desktop ]; then
    cp /usr/share/applications/DaVinciResolve.desktop ~/.local/share/applications/
    
    # Update the Exec line with the required environment variables
    sed -i 's|^Exec=.*|Exec=env OCL_ICD_VENDORS=/etc/OpenCL/vendors/nvidia.icd QT_QPA_PLATFORM=xcb __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia /opt/resolve/bin/resolve %u|' ~/.local/share/applications/DaVinciResolve.desktop
    
    echo "DaVinciResolve.desktop has been updated in ~/.local/share/applications/"
else
    echo "Error: DaVinci Resolve system desktop file not found in /usr/share/applications/"
    exit 1
fi
