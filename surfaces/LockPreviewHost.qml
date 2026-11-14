import QtQuick
import Quickshell
import Quickshell.Wayland
import "../features/lock" as Lock

// Visual preview only. Session-lock/PAM and system actions await review.
Variants {
    id: root
    required property var controller
    required property var compositor
    required property var motion
    required property var clock
    property url wallpaperSource: ""
    model: controller.occluding && compositor.focusedScreen ? [compositor.focusedScreen] : []
    PanelWindow {
        required property var modelData
        screen: modelData; color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: root.controller.shown
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "velora-shell-lockscreen-preview"
        WlrLayershell.keyboardFocus: root.controller.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        Lock.LockScene {
            id: scene; anchors.fill: parent
            presented: root.controller.shown; reducedMotion: root.motion.reduced
            wallpaperSource: root.wallpaperSource
            timeText: root.clock.timeText; dateText: root.clock.dateText
            dayText: String(root.clock.day).padStart(2, "0")
            onCloseRequested: root.controller.hide()
            onExitFinished: if (!root.controller.shown) root.controller.finishClose()
        }
        Connections { target: root.controller; function onOpened() { scene.claimFocus() } }
    }
}
