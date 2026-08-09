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

        // Dim, and a click anywhere outside the panel closes. The panel draws
        // its own surfaces on top of this.
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.35
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        ClipboardManager {
            anchors.fill: parent
            focus: true
        }
    }
}
