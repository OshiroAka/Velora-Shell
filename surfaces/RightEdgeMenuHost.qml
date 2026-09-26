import QtQuick
import Quickshell
import Quickshell.Wayland
import "../features/rightmenu" as RightMenuFeature

Variants {
    id: root

    required property var compositor
    required property var config
    required property var motion
    required property var actions
    required property int opticsGeneration

    model: root.config.topbarEnabled ? root.compositor.screens : []

    PanelWindow {
        id: menuWindow

        required property var modelData
        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        implicitHeight: modelData.height
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        focusable: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "velora-shell-right-menu"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // A monitor-sized backdrop is required by the same native refraction
        // shader used by the lock.  The shader itself clips this coarse union
        // to the continuously morphing rail + bulge SDF.
        BackgroundEffect.blurRegion: Region {}

        mask: Region {
            x: Math.round(menuWindow.width - edgeMenu.width + edgeMenu.inputX)
            y: Math.round(edgeMenu.inputY)
            width: Math.round(edgeMenu.inputWidth)
            height: Math.round(edgeMenu.inputHeight)
        }

        RightMenuFeature.RightEdgeMenu {
            id: edgeMenu
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 126
            motion: root.motion
            actions: root.actions
            nativeSurfaceWidth: modelData.width
            nativeSurfaceHeight: menuWindow.height
            opticsGeneration: root.opticsGeneration
        }
    }
}
