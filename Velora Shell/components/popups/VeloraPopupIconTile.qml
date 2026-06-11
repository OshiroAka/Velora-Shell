import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile

    property var popup: null
    property string iconName: "box"
    property string label: ""
    property bool active: false
    property bool hovered: false
    signal clicked()

    radius: 10
    color: popup
        ? (active ? popup.alpha(popup.winAccent, hovered ? 0.32 : 0.24) : popup.alpha(popup.winCardHover, hovered ? 0.72 : 0.52))
        : Qt.rgba(0.16, 0.26, 0.36, 0.48)
    border.width: 1
    border.color: popup
        ? (active ? popup.alpha(popup.winAccent, 0.54) : popup.alpha(popup.winAccent, hovered ? 0.32 : 0.16))
        : Qt.rgba(1, 1, 1, 0.12)

    Behavior on color {
        ColorAnimation { duration: tile.popup ? tile.popup.motionHover : 120; easing.type: tile.popup ? tile.popup.motionEaseHover : Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        VeloraPopupIcon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            popup: tile.popup
            iconName: tile.iconName
            lineColor: tile.popup ? (tile.active ? tile.popup.winAccent2 : tile.popup.inkSoft) : "white"
        }

        Text {
            Layout.fillWidth: true
            text: tile.label
            color: tile.popup ? (tile.active ? tile.popup.winAccent2 : tile.popup.ink) : "white"
            horizontalAlignment: Text.AlignHCenter
            font.family: tile.popup ? tile.popup.uiFont : "sans"
            font.pixelSize: 10
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.hovered = true
        onExited: tile.hovered = false
        onClicked: tile.clicked()
    }
}
