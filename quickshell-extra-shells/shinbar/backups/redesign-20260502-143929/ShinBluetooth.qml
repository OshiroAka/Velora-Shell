import QtQuick
import Quickshell.Io
import "."

Item {
    id: root
    implicitWidth:  btTxt.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    property bool btOn:   false
    property bool btConn: false

    Process {
        id: btQuery; running: false; property int ln: 0
        command: ["bash","-c","bluetoothctl show 2>/dev/null | grep Powered | awk '{print $2}'; bluetoothctl info 2>/dev/null | grep Connected | awk '{print $2}' || echo no"]
        stdout: SplitParser { onRead: function(data) { var s=data.trim(); if(btQuery.ln===0)root.btOn=(s==="yes"); else root.btConn=(s==="yes"); btQuery.ln++ } }
        onStarted: btQuery.ln=0; onExited: running=false
    }
    Process { id: btToggle; running: false; command: ["bash","-c",root.btOn?"bluetoothctl power off":"bluetoothctl power on"]; onExited: {running=false; btPoll.triggered()} }
    Timer { id: btPoll; interval: 8000; running: true; repeat: true; triggeredOnStart: true; onTriggered: btQuery.running=true }

    ShinPill {
        anchors.fill: parent; anchors.topMargin: (parent.height-ShinConfig.pillH)/2; anchors.bottomMargin: (parent.height-ShinConfig.pillH)/2
        clickable: true; active: root.btConn
        onClicked: btToggle.running=true
    }

    Text {
        id: btTxt; anchors.centerIn: parent
        text:  root.btOn ? (root.btConn ? "" : "") : ""
        color: root.btConn ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : root.btOn ? (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff") : (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
        font.pixelSize: 14; font.family: ShinConfig.fontFamily; verticalAlignment: Text.AlignVCenter
    }
}
