import QtQuick
import Quickshell.Io
import "."

Item {
    id: root
    implicitWidth:  wfRow.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    property string ssid: ""
    property int    sig:  0
    property bool   conn: false

    Process {
        id: wfProc; running: false
        command: ["bash","-c","nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2,3 || echo ':'"]
        stdout: SplitParser { onRead: function(data) { var p=data.trim().split(":"); root.ssid=p[0]||""; root.sig=parseInt(p[1]||"0"); root.conn=root.ssid.length>0 } }
        onExited: running=false
    }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: wfProc.running=true }

    ShinPill { anchors.fill: parent; anchors.topMargin: (parent.height-ShinConfig.pillH)/2; anchors.bottomMargin: (parent.height-ShinConfig.pillH)/2 }

    Row {
        id: wfRow; anchors.centerIn: parent; spacing: 5
        Text {
            text: !root.conn ? "" : root.sig>=75 ? "" : root.sig>=50 ? "" : root.sig>=25 ? "" : ""
            color: root.conn ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
            font.pixelSize: 13; font.family: ShinConfig.fontFamily; verticalAlignment: Text.AlignVCenter
        }
        Text {
            visible: root.ssid.length > 0; text: root.ssid
            color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff"); font.pixelSize: ShinConfig.fontSizeSm; font.family: ShinConfig.fontFamily; verticalAlignment: Text.AlignVCenter
        }
    }
}
