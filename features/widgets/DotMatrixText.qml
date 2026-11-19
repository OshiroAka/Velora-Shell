import QtQuick

Item {
    id: root

    property string text: ""
    property color color: "white"
    property real dotSize: 3
    property int duration: 0
    property bool pulseColon: false
    readonly property real advance: dotSize * 7
    readonly property bool breathing: pulseColon && duration > 0 && visible
    property string previousText: ""
    property string shownText: ""
    property real changeProgress: 1

    implicitWidth: Math.max(0, text.length * advance - dotSize * 2)
    implicitHeight: dotSize * 9

    onTextChanged: {
        fade.stop()
        previousText = shownText
        shownText = text
        if (visible && duration > 0 && previousText !== "") {
            changeProgress = 0
            fade.start()
        } else {
            changeProgress = 1
        }
    }
    function finishWhenIdle() {
        if (duration > 0 && visible)
            return
        fade.stop()
        changeProgress = 1
    }
    onDurationChanged: finishWhenIdle()
    onVisibleChanged: finishWhenIdle()

    NumberAnimation {
        id: fade
        target: root
        property: "changeProgress"
        to: 1
        duration: root.duration
        easing.type: Easing.OutCubic
    }

    DotMatrixGlyphLayer {
        tint: root.color
        separateColon: root.breathing
        value: root.previousText
        comparison: root.shownText
        dots: "changed"
        visible: opacity > 0
        opacity: 1 - root.changeProgress
    }
    DotMatrixGlyphLayer {
        tint: root.color
        separateColon: root.breathing
        value: root.shownText
        comparison: root.previousText
        dots: "shared"
    }
    DotMatrixGlyphLayer {
        tint: root.color
        separateColon: root.breathing
        value: root.shownText
        comparison: root.previousText
        dots: "changed"
        opacity: root.changeProgress
    }
    DotMatrixGlyphLayer {
        tint: root.color
        separateColon: root.breathing
        value: root.shownText
        colonOnly: true
        visible: root.breathing
        SequentialAnimation on opacity {
            running: root.breathing
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: .36; duration: 950; easing.type: Easing.InOutSine }
            NumberAnimation { from: .36; to: 1; duration: 950; easing.type: Easing.InOutSine }
        }
    }
}
