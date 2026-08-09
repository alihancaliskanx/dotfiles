// Colours for the clipboard panel.
//
// Upstream this file is what its name says: it reads /tmp/qs_colors.json, which
// matugen writes, because imperative-dots colours itself from the wallpaper with
// matugen. Nothing runs matugen under the caelestia rice, so that file is never
// written and the panel would sit on the hard-coded Catppuccin fallbacks below
// while the rest of the desktop moved with the wallpaper.
//
// caelestia colours itself the same way by a different road, and — luckily —
// publishes the same names. ~/.local/state/caelestia/scheme.json carries base,
// mantle, crust, text, subtext0/1, surface0-2, overlay0-2 and the accent names
// alongside its own Material 3 ones, so the panel follows `caelestia scheme set`
// with no mapping table. Two differences from matugen's file: the colours are
// nested under "colours", and the values have no leading #.
//
// The name is kept as upstream has it. This is a copied file, and a copied file
// that has been renamed is a copied file nobody will ever diff against its
// source again.

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Explicitly typed as 'color' for strict QML binding
    property color base: "#1e1e2e"
    property color mantle: "#181825"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color subtext0: "#a6adc8"
    property color subtext1: "#bac2de"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color overlay0: "#6c7086"
    property color overlay1: "#7f849c"
    property color overlay2: "#9399b2"
    property color blue: "#89b4fa"
    property color sapphire: "#74c7ec"
    property color peach: "#fab387"
    property color green: "#a6e3a1"
    property color red: "#f38ba8"
    property color mauve: "#cba6f7"
    property color pink: "#f5c2e7"
    property color yellow: "#f9e2af"
    property color maroon: "#eba0ac"
    property color teal: "#94e2d5"

    property string rawJson: ""

    // "0a0f0f" -> "#0a0f0f", and anything already prefixed is left alone, so the
    // same code reads matugen's file if this is ever pointed back at it.
    function hex(v) {
        if (!v)
            return "";
        return v.charAt(0) === "#" ? v : "#" + v;
    }

    function applyColors(raw) {
        let txt = (raw || "").trim();
        if (txt === "" || txt === root.rawJson)
            return;

        root.rawJson = txt;
        try {
            let parsed = JSON.parse(txt);
            let c = parsed.colours || parsed.colors || parsed;
            const names = ["base", "mantle", "crust", "text", "subtext0", "subtext1", "surface0", "surface1", "surface2", "overlay0", "overlay1", "overlay2", "blue", "sapphire", "peach", "green", "red", "mauve", "pink", "yellow", "maroon", "teal"];
            for (const n of names)
                if (c[n])
                    root[n] = root.hex(c[n]);
        } catch (e) {}
    }

    // FileView reads it inside quickshell and watches it after that, rather than
    // forking `cat` on a timer — the scheme only moves when the wallpaper does.
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        preload: true
        printErrors: false

        onLoaded: root.applyColors(text())
        onFileChanged: reload()
    }
}
