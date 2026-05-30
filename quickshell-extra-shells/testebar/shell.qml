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
            WlrLayershell.keyboardFocus: barRoot.wantsKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            screen: modelData
            color: "transparent"
            focusable: true
            implicitWidth: modelData.width > 0 ? modelData.width : barRoot.desiredShellWidth
            exclusiveZone: 70
            exclusionMode: ExclusionMode.Normal
            mask: inputMask

            Region {
                id: inputMask

                intersection: Intersection.Combine

                Region { item: barRoot.railMaskItem; radius: barRoot.cornerRadius }
                Region { item: barRoot.drawerMaskItem; radius: barRoot.cornerRadius }
                Region { item: barRoot.wallpaperListMaskItem; radius: 10 }
                Region { item: barRoot.appSearchMaskItem; radius: 18 }
            }

            anchors {
                top: true
                bottom: true
                left: true
            }

            TesteBar {
                id: barRoot

                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                anchors.topMargin: 22
                anchors.bottomMargin: 22
            }
        }
    }
}
