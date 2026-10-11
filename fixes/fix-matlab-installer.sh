#!/bin/bash
# Fix for the MATLAB installer crashing on Arch/Omarchy
# The installer segfaults while reading the CPUID vendor string and again in
# GnuTLS. This unpacks the installer archive, preloads a shim for the first
# and libleancrypto for the second, runs the installer, and adds a desktop
# entry for the result.

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path to the MATLAB installer zip>"
    echo "Example: $0 ~/Downloads/matlab_R2026b_Linux.zip"
    exit 1
fi

ZIP_PATH="$(realpath "$1")"
# Release name such as R2026b, taken from the file name
VERSION=$(basename "$ZIP_PATH" | grep -oE 'R[0-9]{4}[ab]' || echo "latest")
INSTALL_DIR="$HOME/MATLAB/$VERSION"
WORK_DIR="${TMPDIR:-/tmp}/matlab_installer"

echo "=> 1. Extracting $ZIP_PATH to $WORK_DIR..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
# Leftovers from an earlier run
rm -rf archives bin sys ui install installer_input.txt license_agreement.txt ./*.pdf ./*.txt VersionInfo.xml resources 2>/dev/null || true
unzip -qo "$ZIP_PATH"

echo "=> 2. Building the shim for the 'GenuineIntel' crash..."
# The installer dereferences the three 4-byte parts of the vendor string as
# pointers. Mapping those addresses and pointing them at the string keeps it
# alive.
cat << 'EOF' > shim.c
#include <sys/mman.h>

char fake_vendor[] = "GenuineIntel";

__attribute__((constructor))
void map_intel_bug() {
    void *target3 = (void *)0x6c657000;
    if (mmap(target3, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != MAP_FAILED) {
        *(char **)0x6c65746e = fake_vendor;
    }
    void *target1 = (void *)0x756e6000;
    if (mmap(target1, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != MAP_FAILED) {
        *(char **)0x756e6547 = fake_vendor;
    }
    void *target2 = (void *)0x49656000;
    if (mmap(target2, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != MAP_FAILED) {
        *(char **)0x49656e69 = fake_vendor;
    }
}
EOF

gcc -shared -fPIC -o shim.so shim.c

echo "=> 3. Starting the MATLAB installer..."
echo "--------------------------------------------------------"
echo " In the installer:"
echo " 1. Sign in with your MathWorks account."
echo " 2. For 'Destination Folder' enter:"
echo "    $INSTALL_DIR"
echo " 3. For 'Create symbolic links' enter:"
echo "    $HOME/.local/bin"
echo "--------------------------------------------------------"
echo "Waiting for the installer..."

LD_PRELOAD="/usr/lib/libleancrypto.so $PWD/shim.so" ./install

echo "=> Installer closed."

if [ ! -f "$INSTALL_DIR/bin/matlab" ]; then
    echo "=> Error: $INSTALL_DIR/bin/matlab not found."
    echo "   The installation was cancelled or failed."
    exit 1
fi

echo "=> 4. Installed. Writing the desktop entry..."
mkdir -p "$HOME/.local/share/applications"

cat << EOF > "$HOME/.local/share/applications/matlab_${VERSION}.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=$INSTALL_DIR/bin/matlab -desktop
Name=MATLAB $VERSION
Icon=$INSTALL_DIR/bin/glnxa64/cef_resources/matlab_icon.png
Categories=Development;Math;Science
Comment=Scientific computing environment
EOF

update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
echo "=> Done! MATLAB $VERSION is ready to use."
