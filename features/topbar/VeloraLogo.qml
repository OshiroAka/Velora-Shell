import QtQuick

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#050611" }
            GradientStop { position: 0.48; color: "#6f16c9" }
            GradientStop { position: 1.00; color: "#e86fff" }
        }
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.44)
        clip: true

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: "V"
            color: "white"
            font.family: "Poppins"
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
    }
}
