import QtQuick

Item {
    id: root
    property bool active: false
    property bool transformBars: true
    readonly property bool effectiveActive: active && transformBars
    property bool reducedMotion: false
    property real pace: 1
    property real progress: 0
    property real frameFold: 0
    property real sourceReveal: 1
    property real targetReveal: 0
    readonly property bool moving: opening.running || closing.running
    readonly property real remaining: 1 - frameFold
    readonly property real railRemaining: Math.min(1, (1 - frameFold) / .22)
    function settle() {
        progress = effectiveActive ? 1 : 0
        frameFold = progress
        sourceReveal = effectiveActive ? 0 : 1
        targetReveal = effectiveActive ? 1 : 0
    }
    function retarget() {
        opening.stop(); closing.stop()
        if (reducedMotion) settle()
        else if (effectiveActive) opening.start()
        else closing.start()
    }
    onEffectiveActiveChanged: retarget()
    onReducedMotionChanged: if (reducedMotion) retarget()
    Component.onCompleted: settle()
    SequentialAnimation {
        id: opening
        NumberAnimation { target: root; property: "sourceReveal"; to: 0; duration: 160 * root.pace; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "progress"; to: 1; duration: 240 * root.pace; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "frameFold"; to: 1; duration: 430 * root.pace; easing.type: Easing.InOutCubic }
        }
        NumberAnimation { target: root; property: "targetReveal"; to: 1; duration: 180 * root.pace; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "targetReveal"; to: 0; duration: 140 * root.pace; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "progress"; to: 0; duration: 240 * root.pace; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "frameFold"; to: 0; duration: 430 * root.pace; easing.type: Easing.InOutCubic }
        }
        NumberAnimation { target: root; property: "sourceReveal"; to: 1; duration: 180 * root.pace; easing.type: Easing.OutCubic }
    }
}
