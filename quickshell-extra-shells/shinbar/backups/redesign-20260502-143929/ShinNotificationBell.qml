import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
    visible: true
    id: win

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: ShinConfig.namespace + "-notification-bell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
    }

    implicitWidth: 260
    implicitHeight: ShinConfig.barH + ShinConfig.barMarginT * 2
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // MUDE AQUI SE QUISER MAIS PARA DIREITA/ESQUERDA
    property int bellX: ShinConfig.barMarginH + 150
    property int bellY: ShinConfig.barMarginT

    Item {
        id: bell

        x: win.bellX
        y: win.bellY

        width: 42
        height: ShinConfig.barH

        property bool active: ShinPopup.notificationsOpen

        ShinPill {
            anchors.fill: parent
            anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
            anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
            active: bell.active
            clickable: false
        }

        Text {
            anchors.centerIn: parent
            text: "󰂚"
            color: bell.active ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
            font.pixelSize: ShinConfig.fontSize + 1
            font.bold: bell.active
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: ShinPopup.toggleNotifications()
        }
    }
}
