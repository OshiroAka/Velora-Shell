import QtQuick
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth:  vRow.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    property int  vol:   70
    property bool muted: false

    Process {
        id: vQuery
        running: false
        command: [
            "bash",
            "-lc",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.70'"
        ]

        stdout: SplitParser {
            onRead: function(data) {
                var s = data.trim()

                root.muted = s.indexOf("MUTED") >= 0

                var m = s.match(/[0-9]+\.?[0-9]*/)
                if (m) {
                    root.vol = Math.round(parseFloat(m[0]) * 100)
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: vMute
        running: false
        command: [
            "bash",
            "-lc",
            "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ]

        onExited: {
            running = false
            vPoll.triggered()
        }
    }

    Process {
        id: vChange
        running: false
        command: ["bash", "-lc", ""]

        onExited: {
            running = false
            vPoll.triggered()
        }
    }

    Timer {
        id: vPoll
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (!vQuery.running)
                vQuery.running = true
        }
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin:    (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2

        clickable: true
        active: root.muted

        onClicked: {
            if (!vMute.running)
                vMute.running = true
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: function(w) {
            var d = w.angleDelta.y > 0 ? "+5%" : "-5%"
            vChange.command = [
                "bash",
                "-lc",
                "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + d
            ]

            if (!vChange.running)
                vChange.running = true
        }
    }

    Row {
        id: vRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: root.muted ? "M" : "V"
            color: root.muted ? (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff") : (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
            font.pixelSize: 13
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: root.vol + "%"
            color: root.muted ? (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
            font.pixelSize: ShinConfig.fontSizeSm
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
        }
    }
}
