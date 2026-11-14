import QtQuick
import Velora.Visualizer 1.0

Item {
    id: root

    required property var theme
    required property var visualizer

    property real strength: 0.46
    property real referenceHeight: height
    property bool darkPalette: false
    property real clipSideInset: 0
    property real clipCornerRadius: 0
    property real clipBottomInset: 0
    property bool clipSideOnRight: false
    clip: true

    Spectrum {
        anchors.fill: parent
        analyzer: root.visualizer
        active: root.visible && root.visualizer.running
        referenceHeight: root.referenceHeight
        strength: root.strength
        clipSideInset: root.clipSideInset
        clipCornerRadius: root.clipCornerRadius
        clipBottomInset: root.clipBottomInset
        clipSideOnRight: root.clipSideOnRight
        accentStart: root.darkPalette
            ? Qt.darker(root.theme.visualizerStart, 1.65)
            : root.theme.visualizerStart
        accentMiddle: root.darkPalette
            ? Qt.darker(root.theme.visualizerMiddle, 1.65)
            : root.theme.visualizerMiddle
        accentEnd: root.darkPalette
            ? Qt.darker(root.theme.visualizerEnd, 1.65)
            : root.theme.visualizerEnd
        outlineColor: root.darkPalette
            ? Qt.darker(root.theme.visualizerStart, 2.1)
            : Qt.rgba(1, 1, 1, 0.54)
    }
}
