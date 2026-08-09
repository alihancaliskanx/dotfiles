// The clipboard panel, as its own quickshell config: `qs -c clipboard`.
//
// The panel itself is imperative-dots' ClipboardManager.qml, copied next to this
// file. Upstream it is one page of a stack inside a single monolithic shell that
// also draws that rice's bar, notifications and lock — so there was no way to
// borrow the page without borrowing the bar and having two of them fight over
// the same strip of screen. What made it liftable is that ClipboardManager is a
// plain Item that builds its own Caching, Scaler and MatugenColors and asks its
// parent for nothing. All it was missing was a window to sit in. This is it.
//
// Started per press rather than left resident: one panel is a fraction of a
// shell to load, and a second always-on quickshell process is a second
// always-on quickshell process. Escape and picking an item both call Qt.quit(),
// which is the whole lifecycle.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "WindowRegistry.js" as Layout

ShellRoot {
    PanelWindow {
        id: root

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        // Over the bar, not beside it: this is a modal picker for as long as it
        // is up, so it does not reserve space and does not push anything around.
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "clipboard"

        // Exclusive, or the search field never sees a keystroke — the keyboard
        // stays with whatever was focused underneath.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // No dim. caelestia does not dim behind its panels, and with the layer
        // blur underneath (hypr-user.lua's layer_rule) a black wash on top only
        // turns the blur to mud. The click-to-dismiss area stays.
        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        // The window is the whole screen so there is something to click on to
        // dismiss, but the panel is not — filling the screen with it is what
        // made the first version enormous. 800x700 centred is the box
        // imperative-dots gives it, out of the same table and the same scale
        // function, so it comes out the size it is over there rather than the
        // size that happens to look right on this laptop. getScale is 1.0 at
        // 1920x1080 and shrinks below it, so this stays sane on a smaller panel.
        Item {
            anchors.centerIn: parent

            readonly property real scale: Layout.getScale(root.screen.width, root.screen.height, 1.0)

            width: Layout.s(800, scale)
            height: Layout.s(700, scale)

            ClipboardManager {
                anchors.fill: parent
                focus: true
            }
        }
    }
}
