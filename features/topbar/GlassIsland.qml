import QtQuick

Item {
    id: root

    required property var theme
    property real radius: 14
    property bool hovered: false
    default property alias content: contentLayer.data

    Rectangle {
        anchors.fill: surface
        anchors.topMargin: 5
        radius: surface.radius
        color: Qt.rgba(0.03, 0.12, 0.27, root.hovered ? 0.15 : 0.10)
        opacity: 0.64
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.radius
        color: root.hovered
            ? Qt.rgba(0.80, 0.90, 1.0, 0.14)
            : Qt.rgba(0.72, 0.84, 1.0, 0.075)
        border.width: 1
        border.color: root.hovered
            ? Qt.rgba(1.0, 1.0, 1.0, 0.30)
            : Qt.rgba(1.0, 1.0, 1.0, 0.115)

        Behavior on color { ColorAnimation { duration: 190 } }
        Behavior on border.color { ColorAnimation { duration: 190 } }
    }

    Item {
        id: contentLayer
        anchors.fill: parent
    }
}
