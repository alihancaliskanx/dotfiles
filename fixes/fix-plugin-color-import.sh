#!/bin/bash
# Fix for Omarchy shell plugins that lose their theme colours under Qt 6.12
# An unqualified Color.<x> no longer reaches the shell's Color singleton, so
# every colour binding comes out undefined and cards fall back to white. The
# stock shell imports qs.Commons as Commons and reads Commons.Color.<x>; this
# does the same in every plugin under ~/.config/omarchy/plugins, including the
# ThemeColor.<x> spelling left behind by the old Qt 6.12 shell patch.

set -euo pipefail

PLUGINS_DIR="$HOME/.config/omarchy/plugins"
COLOR_REF='(^|[^A-Za-z0-9_.])(Theme)?Color\.'

echo "=> Qualifying Color references in Omarchy shell plugins..."

if [ ! -d "$PLUGINS_DIR" ]; then
    echo "=> No plugins in $PLUGINS_DIR, nothing to do."
    exit 0
fi

changed=0
while IFS= read -r file; do
    # Without this import, Color in the file is not the shell's; leave it alone
    grep -qx 'import qs.Commons' "$file" || continue
    sed -i --follow-symlinks -E "s/$COLOR_REF/\1Commons.Color./g" "$file"
    if ! grep -qx 'import qs.Commons as Commons' "$file"; then
        sed -i --follow-symlinks '0,/^import qs\.Commons$/s//import qs.Commons\nimport qs.Commons as Commons/' "$file"
    fi
    echo "=> Patched ${file#"$PLUGINS_DIR"/}"
    changed=1
done < <(grep -rlE --include='*.qml' "$COLOR_REF" "$PLUGINS_DIR" || true)

if [ "$changed" -eq 0 ]; then
    echo "=> Every plugin already reads Commons.Color, skipping."
    exit 0
fi

# The shell runs with its file watcher off, so the change needs a restart. The
# launcher treats a clean exit as a deliberate stop and does not relaunch, so a
# plain kill can leave the session without a bar.
"${OMARCHY_PATH:-/usr/share/omarchy}/bin/omarchy-restart-shell"

echo "------------------------------------------------------"
echo "=> Done!"
echo "Run this again after installing, cloning or updating a plugin."
