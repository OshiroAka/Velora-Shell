import QtQuick
import Quickshell.Io
import "."

Item {
    id: root
    implicitWidth:  lbl.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    Process {
        id: launchProc; running: false
        command: ["bash", "-c", "pkill wofi 2>/dev/null; wofi --show drun &"]
        onExited: running = false
    }

    ShinPill {
        anchors.fill: parent; anchors.topMargin: (parent.height - ShinConfig.pillH)/2; anchors.bottomMargin: (parent.height - ShinConfig.pillH)/2
        clickable: true
        onClicked: launchProc.running = true
    }

    Text {
        id: lbl
        anchors.centerIn: parent
        text:  ""
        font.family:   ShinConfig.fontFamily
        font.pixelSize: 15
        color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
        verticalAlignment: Text.AlignVCenter
    }
}
