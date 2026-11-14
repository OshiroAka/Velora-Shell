pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects

// This item owns only timing, geometry and foreground. The color wave is
// evaluated inside the same material shader as the rest of the topbar.
Item {
    id: root
    required property var theme
    property bool charging: false
    property bool anchorAvailable: true
    property bool suppressed: false
    property bool reducedMotion: false
    property int percentage: 0
    property int displayDuration: 6000
    property real barHeight: 40
    property real anchorX: 0
    property real availableWidth: parent ? parent.width : 1920
    property real availableHeight: parent ? parent.height : 1080
    property real leftInset: 8
    property real rightInset: 8
    property bool ready: false
    property bool presenting: false
    property bool bodyDismissed: false
    property real reveal: presenting && anchorAvailable && !suppressed && !bodyDismissed ? 1 : 0
    property real pulsePhase: 0
    property real gradientProgress: 1
    readonly property real gradientStrength: presenting && charging && anchorAvailable && !reducedMotion
        ? Math.min(1, gradientProgress * 10) * Math.pow(1 - gradientProgress, 1.4) * 0.62 : 0
    readonly property real cornerRadius: 18
    readonly property real joinRadius: 8
    readonly property real contentReveal: Math.max(0, Math.min(1, (reveal - 0.5) * 2))
    readonly property real targetWidth: Math.min(120, Math.max(0, availableWidth - leftInset - rightInset))
    readonly property real targetHeight: Math.min(42, Math.max(0, availableHeight - barHeight - 26))
    readonly property real neckHalfWidth: Math.max(0, Math.min(28, width / 2 - 18,
        anchorX - leftInset, availableWidth - rightInset - anchorX)) * reveal
    readonly property rect surfaceRect: visible && height > 0.01
        ? Qt.rect(x, y, width, height) : Qt.rect(0, 0, 0, 0)

    function synchronizeCharging() {
        if (!ready) return
        colorSpread.stop()
        if (charging) {
            bodyDismissed = suppressed
            presenting = true
            dismissal.restart()
            gradientProgress = reducedMotion ? 1 : 0
            if (!reducedMotion) colorSpread.start()
        } else {
            presenting = false
            dismissal.stop()
            gradientProgress = 1
        }
    }
    onChargingChanged: synchronizeCharging()
    onSuppressedChanged: if (suppressed) bodyDismissed = true
    onReducedMotionChanged: if (reducedMotion) { colorSpread.stop(); gradientProgress = 1 }
    Component.onCompleted: { ready = true; synchronizeCharging() }

    x: Math.max(leftInset, Math.min(availableWidth - rightInset - width, anchorX - width / 2))
    y: barHeight + 10 * reveal
    width: Math.min(44, targetWidth) + Math.max(0, targetWidth - 44) * reveal
    height: targetHeight * reveal
    visible: !suppressed && !bodyDismissed && (presenting || reveal > 0)

    Timer { id: dismissal; interval: root.displayDuration; onTriggered: root.presenting = false }
    NumberAnimation {
        id: colorSpread
        target: root; property: "gradientProgress"
        from: 0; to: 1; duration: root.displayDuration
    }
    NumberAnimation on pulsePhase {
        running: root.visible && root.presenting && root.anchorAvailable && root.charging && !root.reducedMotion
        from: 0; to: 1; duration: 2200; loops: Animation.Infinite
    }
    Behavior on reveal {
        enabled: !root.reducedMotion && !root.suppressed
        NumberAnimation { duration: 360; easing.type: Easing.InOutCubic }
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: "Bateria: " + Math.max(0, Math.min(100, percentage)) + "%, carregando"

    Item {
        anchors.fill: parent
        clip: true
        opacity: root.contentReveal
        Item {
            objectName: "chargingBattery"
            anchors.centerIn: parent
            anchors.alignWhenCentered: false
            width: 66; height: 23
            Rectangle {
                width: 62; height: 23; radius: 3
                color: "transparent"
                border.width: 2
                border.color: root.theme.textPrimary
                antialiasing: true
            }
            Rectangle {
                x: 62; y: 7; width: 4; height: 9; radius: 1
                color: root.theme.textPrimary
            }
            Item {
                id: segments
                x: 4; y: 4; width: 54; height: 15
                layer.enabled: root.visible && GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.theme.textPrimary
                    shadowBlur: 0.65
                    shadowOpacity: 0.75
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
                Repeater {
                    model: 6
                    Rectangle {
                        required property int index
                        readonly property real level: Math.max(0, Math.min(1, root.percentage * 0.06 - index))
                        x: index * (width + 2)
                        width: (segments.width - 10) / 6
                        height: segments.height
                        radius: 0.6
                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
                        Rectangle {
                            objectName: "chargingSegment" + parent.index
                            width: parent.width * parent.level
                            height: parent.height
                            radius: parent.radius
                            color: root.theme.textPrimary
                            opacity: root.reducedMotion ? 1 : 0.25 + 0.75
                                * (0.5 + 0.5 * Math.cos(root.pulsePhase * Math.PI * 2 - parent.index * 0.48))
                        }
                    }
                }
            }
        }
    }
}
