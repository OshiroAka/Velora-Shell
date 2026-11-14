import QtQuick

Item {
    id: root

    required property var theme
    required property var motion
    property bool armed: false
    property bool confirming: false
    signal confirmed

    width: armed ? 196 : 42
    height: 42

    function arm() {
        if (!armed) {
            armed = true
            return
        }
        confirming = true
        confirmTimer.restart()
    }

    function cancel() {
        confirming = false
        armed = false
    }

    Behavior on width {
        NumberAnimation {
            duration: root.motion.reduced ? 0 : (root.armed ? 260 : 220)
            easing.type: Easing.InOutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: pointer.containsMouse
            ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                      root.theme.accent.b, 0.36)
            : Qt.rgba(0.10, 0.11, 0.16, 0.78)
        border.width: 1
        border.color: pointer.containsMouse
            ? Qt.rgba(1, 1, 1, 0.72) : Qt.rgba(1, 1, 1, 0.30)
        scale: root.confirming ? 0.82 : (pointer.pressed ? 0.94 : 1)

        Behavior on color { ColorAnimation { duration: root.motion.reduced ? 0 : 190 } }
        Behavior on border.color { ColorAnimation { duration: root.motion.reduced ? 0 : 190 } }
        Behavior on scale {
            NumberAnimation {
                duration: root.motion.reduced ? 0 : (root.confirming ? 180 : 190)
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.armed
            text: "⌫"
            color: "white"
            font.pixelSize: 18
        }

        Row {
            anchors.centerIn: parent
            visible: root.armed
            opacity: root.armed ? 1 : 0
            spacing: 12

            Text {
                text: "Excluir?"
                color: "white"
                font.family: root.theme.bodyFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: 52; height: 28; radius: 14
                color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22)
                    : Qt.rgba(1, 1, 1, 0.10)
                Text { anchors.centerIn: parent; text: "Não"; color: "white"; font.pixelSize: 11 }
                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.cancel()
                }
            }

            Rectangle {
                width: 46; height: 28; radius: 14
                color: yesMouse.containsMouse ? Qt.rgba(1, 0.34, 0.38, 0.78)
                    : Qt.rgba(1, 0.28, 0.33, 0.58)
                Text { anchors.centerIn: parent; text: "Sim"; color: "white"; font.pixelSize: 11 }
                MouseArea {
                    id: yesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.arm()
                }
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            enabled: !root.armed
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.arm()
        }
    }

    Timer {
        id: confirmTimer
        interval: root.motion.reduced ? 0 : 180
        repeat: false
        onTriggered: {
            root.confirmed()
            root.confirming = false
            root.armed = false
        }
    }
}
