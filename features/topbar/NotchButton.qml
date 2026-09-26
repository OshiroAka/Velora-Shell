import QtQuick

Item {
    id: root

    property string glyph: ""
    property real glyphSize: 14
    property color glyphColor: "#f4f4f6"
    property string accessibleName: ""
    readonly property bool hovered: pointer.containsMouse

    signal clicked

    transformOrigin: Item.Center
    scale: pointer.pressed ? 0.91 : 1
    opacity: enabled ? 1 : 0.34
    clip: true

    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(26, parent.width - 2)
        height: Math.min(26, parent.height - 4)
        radius: height / 2
        color: Qt.rgba(1, 1, 1, pointer.containsMouse ? 0.11 : 0.0)
        opacity: pointer.containsMouse ? 1 : 0

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.glyphColor
        font.family: "FontAwesome"
        font.pixelSize: root.glyphSize
        font.weight: Font.Normal
    }

    Rectangle {
        id: ripple
        visible: rippleAnimation.running
        x: rippleAnimation.originX - width / 2
        y: rippleAnimation.originY - height / 2
        width: rippleAnimation.diameter
        height: width
        radius: width / 2
        color: Qt.rgba(1, 1, 1, 0.18)
        opacity: rippleAnimation.opacityValue
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: function(mouse) {
            rippleAnimation.originX = mouse.x
            rippleAnimation.originY = mouse.y
            rippleAnimation.restart()
        }
        onClicked: root.clicked()
    }

    ParallelAnimation {
        id: rippleAnimation
        property real originX: root.width / 2
        property real originY: root.height / 2
        property real diameter: 0
        property real opacityValue: 0

        NumberAnimation {
            target: rippleAnimation
            property: "diameter"
            from: 0
            to: Math.max(root.width, root.height) * 2.4
            duration: 520
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            PropertyAction {
                target: rippleAnimation
                property: "opacityValue"
                value: 0.62
            }
            PauseAnimation { duration: 80 }
            NumberAnimation {
                target: rippleAnimation
                property: "opacityValue"
                to: 0
                duration: 440
                easing.type: Easing.OutCubic
            }
        }
    }
}
