import QtQuick

Item {
    id: root

    required property var theme
    required property var motion
    property string label: ""
    property string suffix: ""
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / (to - from)))

    signal valueEdited(real value)

    width: 452
    height: 68

    function quantizedValue(position) {
        const raw = root.from + Math.max(0, Math.min(1, position)) * (root.to - root.from)
        return Math.max(root.from, Math.min(root.to,
            Math.round(raw / root.stepSize) * root.stepSize))
    }

    Text {
        x: 2
        y: 0
        text: root.label
        color: "white"
        font.family: root.theme.bodyFont
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    Text {
        anchors.right: parent.right
        y: 0
        text: Number(root.value).toFixed(root.stepSize < 1 ? 2 : 0) + root.suffix
        color: Qt.rgba(1, 1, 1, 0.72)
        font.family: root.theme.bodyFont
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Rectangle {
        id: track
        x: 2
        y: 36
        width: parent.width - 4
        height: 7
        radius: 3.5
        color: Qt.rgba(0.04, 0.08, 0.18, 0.30)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)

        Rectangle {
            width: Math.max(7, parent.width * root.ratio)
            height: parent.height
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#8bbcff" }
                GradientStop { position: 1; color: root.theme.accent }
            }
        }

        Rectangle {
            id: thumb
            x: Math.max(-2, Math.min(parent.width - width + 2,
                                     parent.width * root.ratio - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: sliderMouse.pressed ? 20 : (sliderMouse.containsMouse ? 18 : 16)
            height: width
            radius: width / 2
            color: "white"
            border.width: 3
            border.color: sliderMouse.pressed ? root.theme.accent : "#cddcff"
            scale: sliderMouse.pressed ? 0.94 : 1

            Behavior on width {
                NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic }
            }
            Behavior on border.color { ColorAnimation { duration: root.motion.micro } }
        }

        MouseArea {
            id: sliderMouse
            x: -8
            y: -15
            width: parent.width + 16
            height: 38
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function edit(mouseX) {
                root.valueEdited(root.quantizedValue((mouseX - 8) / track.width))
            }

            onPressed: function(mouse) { edit(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    edit(mouse.x)
            }
            onWheel: function(wheel) {
                const direction = wheel.angleDelta.y >= 0 ? 1 : -1
                root.valueEdited(root.quantizedValue(root.ratio
                    + direction * root.stepSize / (root.to - root.from)))
                wheel.accepted = true
            }
        }
    }
}
