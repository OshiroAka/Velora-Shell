import QtQuick

Item {
    id: root

    required property var motion
    property string glyph: ""
    property string accessibleName: ""
    property real iconSize: 24
    property bool standalone: false
    property bool selected: false
    property real proximity: 0
    readonly property bool hovered: pointer.containsMouse
    property real pressWave: 0

    signal clicked
    signal wheeled(real delta)

    transformOrigin: Item.Center
    scale: pointer.pressed ? 0.94 : (hovered ? 1.085 : 1 + 0.035 * proximity)
    transform: Translate {
        y: !pointer.pressed ? -2.2 * (root.hovered ? 1 : root.proximity) : 0
        Behavior on y {
            NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: pointer.pressed ? root.motion.micro : root.motion.hover
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: hoverLens
        anchors.centerIn: parent
        width: root.standalone
            ? parent.width
            : (root.hovered || root.selected ? Math.min(parent.width - 6, 34)
                : (root.proximity > 0 ? 25 : 14))
        height: root.standalone
            ? parent.height
            : (root.hovered || root.selected ? 30 : (root.proximity > 0 ? 23 : 14))
        radius: Math.min(width, height) / 2
        opacity: root.standalone || root.hovered || root.selected
            ? 1
            : (root.proximity > 0 ? 0.52 : 0)
        color: root.standalone
            ? (root.hovered ? Qt.rgba(0.86, 0.93, 1.0, 0.15)
                : Qt.rgba(0.74, 0.86, 1.0, 0.075))
            : Qt.rgba(1.0, 1.0, 1.0, root.hovered || root.selected ? 0.13 : 0.075)
        border.width: root.standalone ? 1 : 0
        border.color: root.hovered
            ? Qt.rgba(1.0, 1.0, 1.0, 0.30)
            : Qt.rgba(1.0, 1.0, 1.0, 0.11)

        Behavior on color { ColorAnimation { duration: root.motion.hover } }
        Behavior on border.color { ColorAnimation { duration: root.motion.hover } }
        Behavior on width {
            NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
        }
        Behavior on height {
            NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
        }
        Behavior on opacity { NumberAnimation { duration: root.motion.micro } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 8 + 34 * root.pressWave
        height: width
        radius: width / 2
        color: Qt.rgba(1, 1, 1, 0.18)
        opacity: (1 - root.pressWave) * 0.72
        visible: root.pressWave > 0
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.enabled ? "white" : Qt.rgba(1, 1, 1, 0.45)
        font.family: "FontAwesome"
        font.pixelSize: root.iconSize
        font.weight: Font.Normal
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: pressAnimation.restart()
        onClicked: root.clicked()
        onWheel: function(wheel) {
            root.wheeled(wheel.angleDelta.y)
            wheel.accepted = true
        }
    }

    SequentialAnimation {
        id: pressAnimation

        NumberAnimation {
            target: root
            property: "pressWave"
            from: 0
            to: 1
            duration: root.motion.micro
            easing.type: Easing.OutCubic
        }
        PropertyAction { target: root; property: "pressWave"; value: 0 }
    }
}
