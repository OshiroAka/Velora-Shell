import QtQuick
import QtQuick.Layouts

Rectangle {
    id: row

    property var popup: null
    property string iconName: "box"
    property string title: ""
    property string subtitle: ""
    property bool accent: false
    property bool hovered: false
    property bool showArrow: true
    signal clicked()

    implicitHeight: 44
    radius: 8
    color: popup
        ? (hovered ? popup.winCardHover : (accent ? popup.alpha(popup.winAccent, 0.18) : popup.alpha(popup.winCardHover, 0.40)))
        : Qt.rgba(0.16, 0.26, 0.36, 0.42)
    border.width: 1
    border.color: popup ? (accent ? popup.alpha(popup.winAccent, 0.48) : popup.alpha(popup.winAccent, 0.12)) : Qt.rgba(1, 1, 1, 0.12)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10

        VeloraPopupIcon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            popup: row.popup
            iconName: row.iconName
            lineColor: row.popup ? (row.accent ? row.popup.winAccent2 : row.popup.inkSoft) : Qt.rgba(1, 1, 1, 0.7)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.title
                color: row.popup ? row.popup.ink : "white"
                font.family: row.popup ? row.popup.uiFont : "sans"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: row.subtitle.length > 0
                text: row.subtitle
                color: row.popup ? row.popup.inkSoft : Qt.rgba(1, 1, 1, 0.6)
                font.family: row.popup ? row.popup.uiFont : "sans"
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        Text {
            visible: row.showArrow
            text: ">"
            color: row.popup ? row.popup.inkSoft : Qt.rgba(1, 1, 1, 0.6)
            font.family: row.popup ? row.popup.uiFont : "sans"
            font.pixelSize: 17
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.hovered = true
        onExited: row.hovered = false
        onClicked: row.clicked()
    }
}
