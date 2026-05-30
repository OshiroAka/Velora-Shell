import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "testebar"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            screen: modelData
            color: "transparent"
            implicitWidth: 70
            exclusionMode: ExclusionMode.Auto

            anchors {
                top: true
                bottom: true
                left: true
            }

            TesteBar {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                anchors.topMargin: 22
                anchors.bottomMargin: 22
            }
        }
    }
}
