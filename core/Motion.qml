import QtQuick

QtObject {
    required property var config

    readonly property bool reduced: config.reducedMotion
    readonly property real pace: config.motionPreset === "calm" ? 1.18
        : (config.motionPreset === "snappy" ? 0.82 : 1)
    readonly property int micro: reduced ? 70 : Math.round(140 * pace)
    readonly property int hover: reduced ? 80 : Math.round(190 * pace)
    readonly property int selection: reduced ? 80 : Math.round(240 * pace)
    readonly property int morph: reduced ? 90 : Math.round(300 * pace)
    readonly property int depth: reduced ? 100 : Math.round(420 * pace)
    readonly property int scene: reduced ? 110 : Math.round(520 * pace)
    readonly property int stagger: reduced ? 0 : 45
    readonly property int exit: reduced ? 90 : Math.round(220 * pace)
    readonly property int widgetOpen: reduced ? 140 : Math.round(800 * pace)
    readonly property int widgetExit: reduced ? 130 : Math.round(650 * pace)
    readonly property int widgetStagger: reduced ? 0 : 45
    readonly property int widgetSettle: reduced ? 0 : 90
}
