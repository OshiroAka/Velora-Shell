import QtQuick
import Velora.Native

Item {
    id: root

    // Kept as a compatibility property for existing callers. Spectrum samples
    // now stay inside the native Qt module and no longer cross JavaScript.
    property var values: []
    property var theme: null
    property bool active: true
    property bool growUpward: false
    property bool growFromCenter: false
    property real minimumLevel: 0
    property real referenceHeight: 46
    property real strength: theme
        ? Math.max(0, Math.min(1, Number(theme.visualizerStrength)))
        : 1

    readonly property bool hasSignal: nativeSpectrum.hasSignal

    clip: true

    VeloraNativeSpectrum {
        id: nativeSpectrum

        anchors.fill: parent
        active: root.active
        growUpward: root.growUpward
        growFromCenter: root.growFromCenter
        minimumLevel: root.minimumLevel
        referenceHeight: root.referenceHeight
        strength: root.strength
        accentStart: root.theme ? root.theme.accentPrimary : "#8b9ee8"
        accentMiddle: root.theme ? root.theme.accentTertiary : "#72c7e7"
        accentEnd: root.theme ? root.theme.accentSecondary : "#e2a4ca"
    }
}
