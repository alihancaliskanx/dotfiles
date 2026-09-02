#!/usr/bin/env bash
#
# fixes/fix-omarchy-workspaces.sh
# ------------------------------------------------------------------------------
# Configures Omarchy Shell bar to display persistent workspaces 1 through 9 and 0
# with clear numeric labels instead of hardcoded 1..5.
# ------------------------------------------------------------------------------

set -euo pipefail

INFO='\033[0;34m[INFO]\033[0m'
SUCCESS='\033[0;32m[OK]\033[0m'

echo -e "${INFO} Setting up persistent workspaces (1-10/0) for Omarchy Shell..."

PLUGIN_DIR="$HOME/.config/omarchy/plugins/sups.workspaces"
mkdir -p "$PLUGIN_DIR"

# 1. Manifest
cat << 'MANIFEST' > "$PLUGIN_DIR/manifest.json"
{
  "schemaVersion": 1,
  "id": "sups.workspaces",
  "name": "My Workspaces",
  "version": "1.0.0",
  "author": "Omarchy",
  "description": "Workspace number indicators",
  "kinds": [
    "bar-widget"
  ],
  "entryPoints": {
    "barWidget": "Workspaces.qml"
  },
  "barWidget": {
    "displayName": "My Workspaces",
    "description": "Workspace number indicators",
    "category": "Compositor",
    "allowMultiple": false
  },
  "omarchy": {
    "clonedFrom": "omarchy.workspaces"
  }
}
MANIFEST

# 2. QML Widget
cat << 'QML' > "$PLUGIN_DIR/Workspaces.qml"
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "sups.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        text: modelData === 10 ? "0" : String(modelData)
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
QML

echo -e "${SUCCESS} sups.workspaces plugin configured."

# 3. Reload Omarchy shell
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins 2>/dev/null || true
  omarchy-shell shell reloadConfig 2>/dev/null || true
fi

if command -v omarchy-restart-shell >/dev/null 2>&1; then
  omarchy-restart-shell 2>/dev/null || true
fi

echo -e "${SUCCESS} Omarchy workspaces bar updated successfully!"
