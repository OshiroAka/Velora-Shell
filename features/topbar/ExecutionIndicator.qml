pragma ComponentBehavior: Bound
import QtQuick
import "../../components" as Components

Item {
    id: root
    required property var theme
    required property var service
    property real availableWidth: 500
    property bool ready: false
    property bool mounted: false
    property real reveal: 0
    property real contentReveal: 0
    property var presented: ({ phase: "idle", agent: "", label: "", detail: "", progress: -1 })
    readonly property var incoming: service.current
    readonly property bool desiredOpen: service.shown
    readonly property bool notificationMode: presented.phase === "notification"
    readonly property real pace: notificationMode ? 2.8 : 1
    readonly property color activityColor: presented.phase === "failed" ? theme.danger
        : presented.phase === "completed" ? theme.success : theme.accentSoft
    property real targetWidth: Math.min(Math.max(notificationMode ? 330 : 192, labelMetrics.width + 78), 340, Math.max(80, availableWidth))
    property real targetHeight: presented.progress >= 0 ? 58 : 52
    width: 60 + (targetWidth - 60) * reveal
    height: targetHeight * reveal
    visible: mounted
    readonly property rect surfaceRect: mounted ? Qt.rect(x, y, width, height) : Qt.rect(0, 0, 0, 0)
    property real cornerRadius: 18
    property real joinRadius: 8
    property real connectionDepth: notificationMode ? 14 : 0
    readonly property real connectionGap: connectionDepth * reveal
    readonly property real neckHalfWidth: Math.max(0, notificationMode
        ? Math.min(110, width * 0.34) : Math.min(100, width / 2 - 18)) * reveal
    Behavior on connectionDepth { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
    Behavior on cornerRadius { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
    Behavior on joinRadius { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
    // This status is informational and never takes keyboard or pointer focus.
    Accessible.role: Accessible.StaticText
    Accessible.name: presented.agent + ": " + presented.label
    TextMetrics { id: labelMetrics; font.family: root.theme.bodyFont; font.pixelSize: 13; text: root.presented.label }
    Behavior on targetWidth { enabled: root.mounted; NumberAnimation { duration: Math.round(220 * root.pace); easing.type: Easing.InOutCubic } }
    Behavior on targetHeight { enabled: root.mounted; NumberAnimation { duration: Math.round(220 * root.pace); easing.type: Easing.InOutCubic } }

    function synchronize() {
        if (!ready) return
        if (desiredOpen && mounted && !closing.running && incoming.agent === presented.agent && incoming.label === presented.label
                && incoming.detail === presented.detail && incoming.phase === presented.phase) {
            presented = incoming
            return
        }
        opening.stop(); closing.stop(); swapping.stop(); entering.stop(); contentDelay.stop()
        if (!desiredOpen) {
            if (mounted) closing.start()
        } else if (!mounted) {
            presented = incoming
            mounted = true
            opening.start()
            contentDelay.restart()
        } else swapping.start()
    }
    onIncomingChanged: synchronize()
    onDesiredOpenChanged: Qt.callLater(synchronize)
    Component.onCompleted: { ready = true; synchronize() }
    NumberAnimation { id: opening; target: root; property: "reveal"; to: 1; duration: Math.round(210 * root.pace); easing.type: Easing.OutCubic }
    Timer { id: contentDelay; interval: Math.round(135 * root.pace); onTriggered: entering.start() }
    NumberAnimation { id: entering; target: root; property: "contentReveal"; to: 1; duration: Math.round(150 * root.pace); easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: swapping
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: Math.round(65 * root.pace); easing.type: Easing.InCubic }
        ScriptAction { script: { root.presented = root.incoming; opening.start(); contentDelay.restart() } }
    }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: Math.round(65 * root.pace); easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: Math.round(125 * root.pace); easing.type: Easing.InOutCubic }
        ScriptAction { script: if (!root.desiredOpen) root.mounted = false }
    }
    Item {
        x: 22; y: 7 - (1 - root.contentReveal) * 5
        width: Math.max(0, parent.width - 44); height: Math.max(0, parent.height - 12)
        opacity: root.contentReveal
        clip: true
        Text {
            width: parent.width; height: 16
            text: root.presented.agent + (root.presented.detail ? " · " + root.presented.detail : "")
            textFormat: Text.PlainText; elide: Text.ElideRight
            font.family: root.theme.bodyFont; font.pixelSize: 10
            color: root.theme.textSecondary
        }
        Item {
            id: activity
            visible: !root.notificationMode
            x: 1; y: 22; width: 12; height: 12
            RotationAnimation on rotation {
                from: 0; to: 360; duration: 2400; loops: Animation.Infinite
                running: root.visible && root.enabled && root.presented.phase === "running" && root.contentReveal > 0
            }
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    x: index % 2 * 7; y: Math.floor(index / 2) * 7
                    width: 4; height: 4; radius: 1.5
                    color: root.activityColor
                    opacity: 0.45 + index * 0.15
                }
            }
        }
        Components.VeloraMaterialIcon {
            x: 0; y: 17; width: 20; height: 20
            visible: root.notificationMode
            iconName: root.presented.iconKey === "whatsapp" ? "chat"
                : root.presented.iconKey === "velora" ? "bell" : root.presented.iconKey || "bell"
            iconColor: root.theme.textPrimary
        }
        Text {
            x: 24; y: 17; width: Math.max(0, parent.width - x); height: 22
            text: root.presented.label
            textFormat: Text.PlainText; elide: Text.ElideRight
            color: root.theme.textPrimary
            font.family: root.theme.bodyFont; font.pixelSize: 13
        }
    }
    Rectangle {
        x: 26; y: root.height - 6; width: Math.max(0, root.width - 52); height: 2
        visible: root.presented.progress >= 0
        opacity: root.contentReveal
        color: root.theme.withAlpha(root.theme.textPrimary, 0.10); radius: 1
        Rectangle {
            width: parent.width * Math.max(0, root.presented.progress); height: 2; radius: 1
            color: root.activityColor
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
}
