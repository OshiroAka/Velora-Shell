import QtQuick

Rectangle {
    property var popup: null

    radius: 12
    color: popup ? popup.alpha(popup.winCard, 0.82) : Qt.rgba(0.12, 0.20, 0.29, 0.48)
    border.width: 1
    border.color: popup ? popup.alpha(popup.winAccent, 0.18) : Qt.rgba(1, 1, 1, 0.14)
    antialiasing: true
}
