import QtQuick

GlassPanel {
    id: root

    required property var status
    required property var theme
    required property var motion
    property var itemStyle: ({})
    property string variantId: "classic"
    readonly property bool editorial: variantId === "editorial"
    readonly property bool minimal: variantId === "minimal"
    readonly property string contentFont: customFont.name.length
        ? customFont.name : String(itemStyle.fontFamily || root.theme.bodyFont)
    readonly property real fontScale: Number(itemStyle.fontScale || 1)
    readonly property color contentColor: String(itemStyle.textColor || "").length
        ? itemStyle.textColor : root.theme.textPrimary

    FontLoader { id: customFont; source: String(root.itemStyle.fontAsset || "") }

    width: 302
    height: 194
    radius: Number(itemStyle.radius === undefined
        ? (editorial ? 24 : (minimal ? 14 : 28)) : itemStyle.radius)
    materialMode: root.theme.resolvedMaterial(itemStyle)
    solidColor: String(itemStyle.solidColor || "#20222a")
    materialOpacity: Number(itemStyle.surfaceOpacity === undefined
        ? root.theme.requestedOpacity : itemStyle.surfaceOpacity)
    surfaceColor: theme.moduleSurface
    flatSurface: Boolean(itemStyle.matchBarSurface)
    borderColor: theme.moduleBorder
    shadowColor: Qt.rgba(theme.shadow.r, theme.shadow.g, theme.shadow.b, 0.16)

    component Metric: Item {
        id: metric
        property string label: ""
        property real value: 0
        property bool available: true
        width: root.width - 36
        height: 48

        Text {
            x: 0
            y: 0
            text: metric.label
            color: root.theme.textSecondary
            font.family: root.contentFont
            font.pixelSize: 11 * root.fontScale
            font.weight: Font.Medium
        }
        Text {
            anchors.right: parent.right
            y: 0
            text: metric.available ? Math.round(metric.value) + "%" : "—"
            color: root.theme.textSecondary
            font.family: root.contentFont
            font.pixelSize: 11 * root.fontScale
        }
        Rectangle {
            x: 0
            y: 28
            width: parent.width
            height: 5
            radius: 2.5
            color: root.theme.surfaceSoft
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, metric.value / 100))
                height: parent.height
                radius: parent.radius
                color: root.theme.accentAlt
                Behavior on width {
                    NumberAnimation { duration: root.motion.selection; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    Text {
        x: 18
        y: 15
        text: "▣  Sistema"
        color: root.contentColor
        font.family: root.contentFont
        font.pixelSize: 16 * root.fontScale
        font.weight: Font.DemiBold
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: 18
        text: root.status.hasBattery
            ? (root.status.batteryCharging ? "⚡ " : "")
                + root.status.batteryPercent + "%" : "AC"
        color: root.theme.textSecondary
        font.family: root.contentFont
        font.pixelSize: 10 * root.fontScale
    }
    Rectangle {
        x: 18
        y: 45
        width: parent.width - 36
        height: 1
        color: root.theme.borderSubtle
    }

    Column {
        x: 18
        y: 60
        spacing: -1
        Metric { label: "CPU"; value: root.status.cpuPercent; available: root.status.performanceAvailable }
        Metric { label: "Memória"; value: root.status.ramPercent; available: root.status.performanceAvailable }
        Metric { label: "Armazenamento"; value: root.status.storagePercent; available: true }
    }

    Item {
        x: 18
        y: 207
        width: parent.width - 36
        height: 50
        visible: root.height >= 285
        Text {
            id: volumeLabel
            text: "Volume"
            color: root.theme.textSecondary
            font.family: root.contentFont
            font.pixelSize: 11 * root.fontScale
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.status.hasAudio
                cursorShape: Qt.PointingHandCursor
                onClicked: root.status.toggleMuted()
            }
        }
        Text {
            anchors.right: parent.right
            text: root.status.hasAudio ? root.status.volumePercent + "%" : "—"
            color: root.theme.textSecondary
            font.family: root.contentFont
            font.pixelSize: 11 * root.fontScale
        }
        Rectangle {
            y: 29
            width: parent.width
            height: 4
            radius: 2
            color: root.theme.surfaceSoft
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.status.volume))
                height: parent.height
                radius: parent.radius
                color: root.theme.accentAlt
            }
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -10
                anchors.bottomMargin: -10
                enabled: root.status.hasAudio
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    const target = Math.max(0, Math.min(1, mouse.x / width))
                    const delta = target - root.status.volume
                    const steps = Math.round(Math.abs(delta) / 0.05)
                    for (let index = 0; index < steps; index += 1) {
                        if (delta >= 0)
                            root.status.adjustVolume(1)
                        else
                            root.status.adjustVolume(-1)
                    }
                }
            }
        }
    }

    Item {
        x: 18
        y: 269
        width: parent.width - 36
        height: parent.height - y - 14
        visible: root.height >= 330
        Text {
            id: networkLabel
            text: "Rede"
            color: root.theme.textSecondary
            font.family: root.contentFont
            font.pixelSize: 11 * root.fontScale
            font.weight: Font.Medium
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.status.toggleWifi()
            }
        }
        Text {
            anchors.right: parent.right
            text: "↓ " + root.status.networkDownKbps.toFixed(0)
                + " KB/s   ↑ " + root.status.networkUpKbps.toFixed(0) + " KB/s"
            color: root.theme.textSecondary
            font.family: root.contentFont
            font.pixelSize: 9 * root.fontScale
        }
        Row {
            id: graph
            y: 29
            width: parent.width
            height: parent.height - y
            spacing: 2
            Repeater {
                model: root.status.networkHistory
                Rectangle {
                    required property real modelData
                    required property int index
                    width: Math.max(2, (graph.width - 58) / 30)
                    height: Math.max(2, graph.height * Math.max(0.04, modelData))
                    anchors.bottom: parent.bottom
                    radius: width / 2
                    color: index % 2 === 0
                        ? root.theme.accentAlt : root.theme.accent
                    opacity: 0.42 + modelData * 0.58
                    Behavior on height { NumberAnimation { duration: root.motion.selection } }
                }
            }
        }
    }
}
