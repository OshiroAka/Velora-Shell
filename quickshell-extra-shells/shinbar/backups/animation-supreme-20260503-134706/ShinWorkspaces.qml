import QtQuick
import Quickshell.Hyprland
import "."

Item {
    id: root
    implicitWidth:  wsRow.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    ShinPill {
        anchors.fill: parent
        anchors.topMargin:    (parent.height - ShinConfig.pillH)/2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH)/2
    }

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: Hyprland.workspaces
            delegate: Item {
                required property HyprlandWorkspace modelData
                property bool isActive: Hyprland.focusedMonitor !== null &&
                    Hyprland.focusedMonitor.activeWorkspace !== null &&
                    Hyprland.focusedMonitor.activeWorkspace.id === modelData.id
                property bool hasWin: modelData.windowCount > 0

                implicitWidth:  dot.width + 6
                implicitHeight: ShinConfig.barH

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width:  isActive ? 18 : (hasWin ? 7 : 5)
                    height: isActive ? 5  : (hasWin ? 7 : 5)
                    radius: height / 2
                    color:  isActive ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") :
                             hasWin  ? Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.45) :
                                       Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.18)
                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 160 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }
    }
}
