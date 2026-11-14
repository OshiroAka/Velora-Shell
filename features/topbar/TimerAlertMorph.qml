pragma ComponentBehavior: Bound
import QtQuick

// Only geometry and controls. The host joins this into the bar's material.
Item {
    id: root
    required property var theme
    required property var service
    property bool reducedMotion: false
    property bool suppressed: false
    property real anchorX: 0
    property real barHeight: 40
    property real availableWidth: parent ? parent.width : 1920
    property real leftInset: 8
    property real rightInset: 8
    property real reveal: service.finished && !suppressed ? 1 : 0
    readonly property real cornerRadius: 18
    readonly property real joinRadius: 14
    readonly property real neckHalfWidth: Math.max(0, Math.min(48, width / 2 - 18,
        anchorX - leftInset, availableWidth - rightInset - anchorX)) * reveal
    readonly property rect surfaceRect: visible ? Qt.rect(x, y, width, height) : Qt.rect(0, 0, 0, 0)
    readonly property real targetWidth: Math.min(124, Math.max(0, availableWidth - leftInset - rightInset))
    width: Math.min(48, targetWidth) + Math.max(0, targetWidth - 48) * reveal
    height: 52 * reveal
    x: Math.max(leftInset, Math.min(availableWidth - rightInset - width, anchorX - width / 2))
    y: barHeight + 10 * reveal
    visible: !suppressed && (service.finished || reveal > 0.001)
    enabled: service.finished && !suppressed && reveal > 0.9
    Accessible.role: Accessible.Grouping
    Accessible.name: "Temporizador concluído"
    Behavior on reveal {
        enabled: !root.reducedMotion && !root.suppressed
        NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
    }
    Row {
        anchors.centerIn: parent
        spacing: 12
        opacity: Math.max(0, (root.reveal - 0.55) / 0.45)
        visible: opacity > 0
        TimerAlertButton {
            objectName: "timerAlertSnooze"
            theme: root.theme
            tint: "#6ed3a1"
            reducedMotion: root.reducedMotion
            width: 36; height: 36
            text: "+10"
            Accessible.name: "Adiar temporizador por dez minutos"
            onConfirmed: root.service.snoozeAlert()
        }
        TimerAlertButton {
            objectName: "timerAlertDismiss"
            theme: root.theme
            tint: "#ef6675"
            reducedMotion: root.reducedMotion
            width: 36; height: 36
            iconName: "stop"
            Accessible.name: "Parar temporizador"
            onConfirmed: root.service.dismissAlert()
        }
    }
}
