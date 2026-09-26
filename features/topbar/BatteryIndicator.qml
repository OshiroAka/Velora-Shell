import QtQuick

Item {
    id: root

    property real level: 1
    property bool charging: false
    property color color: "white"

    width: 30
    height: 18

    Rectangle {
        id: body
        x: 1
        y: 3
        width: 24
        height: 13
        radius: 3
        color: "transparent"
        border.width: 2
        border.color: root.color

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: Math.max(2, (parent.width - 6) * Math.max(0, Math.min(1, root.level)))
            radius: 1.5
            color: root.level < 0.18 ? "#ffcfda" : root.color

            Behavior on width {
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        x: 26
        y: 7
        width: 3
        height: 6
        radius: 1.5
        color: root.color
    }

    Text {
        visible: root.charging
        anchors.centerIn: body
        text: "\uf0e7"
        color: "#89ffc7"
        font.family: "FontAwesome"
        font.pixelSize: 9
    }
}
