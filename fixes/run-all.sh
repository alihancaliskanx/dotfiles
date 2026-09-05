#!/usr/bin/env bash
#
# fixes/run-all.sh
# ------------------------------------------------------------------------------
# Applies all known system, browser, and compositor fixes in sequence.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Running all system and environment fixes ==="
echo ""

"$SCRIPT_DIR/fix-chromium-nvidia-glitches.sh"
echo ""

"$SCRIPT_DIR/fix-omarchy-workspaces.sh"
echo ""

"$SCRIPT_DIR/fix-windows-vm.sh"
echo ""

"$SCRIPT_DIR/fix-key-visualizer-turkish.sh"
echo ""

"$SCRIPT_DIR/fix-debtap-grep.sh"
echo ""

echo "=== All fixes applied successfully! ==="
