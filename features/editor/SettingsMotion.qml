import QtQuick

// Surface and delayed content overlap like the sidebar popovers. There is no
// recurring timer; interruption always retargets from the current geometry.
QtObject {
    id: root
    required property var motion
    property bool sidePanel: false
    readonly property int openDuration: motion.geometryDuration
    readonly property int exitDuration: motion.closeDuration
    property bool presented: false
    property string desiredPage: "wallpapers"
    property string presentedPage: desiredPage
    property real reveal: 0
    property real contentReveal: 0
    property real chromeReveal: 0
    readonly property bool animating: opening.running || entering.running || closing.running || swapping.running
    readonly property bool interactive: presented && !animating && contentReveal > .99
    signal closed()

    function synchronize() {
        opening.stop(); entering.stop(); closing.stop(); swapping.stop()
        if (motion.reduced) {
            presentedPage = desiredPage
            reveal = presented ? 1 : 0
            contentReveal = reveal
            chromeReveal = reveal
            if (!presented) closed()
        } else if (!presented) closing.start()
        else if (reveal < .999) {
            presentedPage = desiredPage
            opening.start()
        } else if (presentedPage !== desiredPage) swapping.start()
        else entering.start()
    }
    onPresentedChanged: synchronize()
    onDesiredPageChanged: synchronize()
    property bool reduced: motion.reduced
    onReducedChanged: synchronize()
    Component.onCompleted: synchronize()
    property ParallelAnimation opening: ParallelAnimation {
        NumberAnimation { target: root; property: "reveal"; to: 1; duration: root.openDuration; easing.type: root.motion.easeGeometry }
        SequentialAnimation {
            // Keep the launcher's existing geometry-first entrance.
            PauseAnimation { duration: root.sidePanel ? root.motion.contentDelay : root.openDuration }
            ScriptAction { script: if (root.presented) root.entering.start() }
        }
    }
    property NumberAnimation entering: NumberAnimation {
        target: root; properties: "contentReveal,chromeReveal"; to: 1
        duration: root.motion.contentDuration; easing.type: root.motion.easeContent
    }
    property SequentialAnimation swapping: SequentialAnimation {
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.motion.contentExit; easing.type: Easing.InCubic }
        ScriptAction { script: root.presentedPage = root.desiredPage }
        PauseAnimation { duration: root.sidePanel ? 0 : root.motion.geometryDuration }
        NumberAnimation { target: root; property: "contentReveal"; to: 1; duration: root.motion.contentDuration; easing.type: root.motion.easeContent }
    }
    property SequentialAnimation closing: SequentialAnimation {
        NumberAnimation { target: root; properties: "contentReveal,chromeReveal"; to: 0; duration: root.motion.contentExit; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.exitDuration; easing.type: root.motion.easeHandoff }
        ScriptAction { script: if (!root.presented) root.closed() }
    }
}
