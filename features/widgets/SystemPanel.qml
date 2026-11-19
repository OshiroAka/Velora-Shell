import QtQuick

WidgetSurface {
    id: root
    required property var status
    required property var motion
    readonly property bool metrics: variantId === "metrics"
    readonly property bool minimal: variantId === "minimal"
    readonly property var readings: [
        {name: "CPU", value: status.cpuPercent, available: status.performanceAvailable},
        {name: "Memória", value: status.ramPercent, available: status.performanceAvailable},
        {name: "Disco", value: status.storagePercent, available: status.performanceAvailable}].concat(metrics ? [
        {name: "Rede ↓", value: status.networkDownKbps, available: status.performanceAvailable, unit: "KB/s"}] : [])
    width: 302; height: 210
    Text {
        x: 20; y: 17; text: "SISTEMA"; color: root.mutedColor
        font.family: root.contentFont; font.pixelSize: 10; font.letterSpacing: 2
    }
    Grid {
        id: metricsGrid
        x: 20; y: 47; width: parent.width - 40
        columns: root.metrics ? 2 : root.minimal ? 3 : 1
        columnSpacing: 12; rowSpacing: 12
        Repeater {
            model: root.metrics ? 4 : 3
            Item {
                id: readout
                required property int index
                readonly property var reading: root.readings[index] || ({name: "", value: 0, available: false})
                width: root.metrics ? (root.width - 52) / 2 : root.minimal ? (root.width - 64) / 3 : root.width - 40
                height: root.metrics ? 78 : root.minimal ? 54 : 47
                Rectangle {
                    anchors.fill: parent; radius: 15; visible: root.metrics
                    color: root.quietColor; opacity: .48
                }
                Text {
                    x: root.metrics ? 12 : 0; y: root.metrics ? 8 : 0
                    text: readout.reading.name; color: root.mutedColor
                    font.family: root.contentFont; font.pixelSize: 10
                }
                DotMatrixText {
                    visible: root.metrics; x: 12; y: 26; width: parent.width - 44; height: 32
                    text: readout.reading.available ? String(Math.round(readout.reading.value)) : "—"
                    color: root.contentColor
                    duration: root.motionDuration
                }
                Text {
                    visible: !root.metrics
                    anchors.right: root.minimal ? undefined : parent.right
                    y: root.minimal ? 20 : 0
                    text: readout.reading.available ? Math.round(readout.reading.value) + "%" : "—"
                    color: root.contentColor; font.family: root.contentFont
                    font.pixelSize: root.minimal ? 22 : 12
                }
                Text {
                    visible: root.metrics; anchors.right: parent.right; anchors.rightMargin: 10; y: 40
                    text: readout.reading.unit || "%"; color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 10
                }
                Row {
                    visible: !root.minimal && !readout.reading.unit; x: root.metrics ? 12 : 0; width: parent.width - 2*x; y: root.metrics ? 66 : 28; spacing: 3
                    Repeater {
                        model: 20
                        Rectangle {
                            required property int index
                            width: Math.max(1, (parent.width - 57) / 20)
                            height: root.metrics ? 4 : 5; radius: 1
                            color: root.contentColor
                            opacity: readout.reading.available && index < Math.round(readout.reading.value / 5) ? .88 : .12
                            Behavior on opacity {
                                NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
                Loader {
                    active: root.metrics && readout.index === 3
                    x: 12; y: 58; width: parent.width - 24; height: 13
                    sourceComponent: WidgetNetworkTrace {
                        samples: root.status.networkHistory || []
                        ink: root.mutedColor
                    }
                }
            }
        }
    }
    Item {
        x: 20; y: 218; width: parent.width - 40; height: 48
        visible: !root.metrics && !root.minimal && root.height >= 290
        Text {
            text: "Volume"; color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 10
            activeFocusOnTab: root.status.hasAudio
            Accessible.role: Accessible.Button; Accessible.name: "Ativar ou silenciar áudio"
            Accessible.onPressAction: if (root.status.hasAudio) root.status.toggleMuted()
            Keys.onSpacePressed: if (root.status.hasAudio) root.status.toggleMuted()
            Keys.onReturnPressed: if (root.status.hasAudio) root.status.toggleMuted()
            MouseArea { anchors.fill: parent; anchors.margins: -5; enabled: root.status.hasAudio; cursorShape: Qt.PointingHandCursor; onClicked: root.status.toggleMuted() }
        }
        Text { anchors.right: parent.right; text: root.status.hasAudio ? root.status.volumePercent + "%" : "—"; color: root.contentColor; font.pixelSize: 10 }
        Rectangle {
            y: 25; width: parent.width; height: 5; radius: 3; color: root.quietColor
            Rectangle { width: parent.width * Math.max(0, Math.min(1, root.status.volume)); height: 5; radius: 3; color: root.contentColor }
            MouseArea {
                anchors.fill: parent; anchors.topMargin: -8; anchors.bottomMargin: -8
                enabled: root.status.hasAudio; cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const delta = Math.max(0, Math.min(1, mouse.x / width)) - root.status.volume
                    for (let step = 0; step < Math.round(Math.abs(delta) / .05); step++) root.status.adjustVolume(delta >= 0 ? 1 : -1)
                }
            }
        }
    }
    Text {
        x: 20; y: 280; width: parent.width - 40
        visible: !root.metrics && !root.minimal && root.height >= 330
        text: "REDE    ↓ " + Number(root.status.networkDownKbps).toFixed(0) + " KB/s    ↑ " + Number(root.status.networkUpKbps).toFixed(0) + " KB/s"
        color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 10; elide: Text.ElideRight
    }
}
