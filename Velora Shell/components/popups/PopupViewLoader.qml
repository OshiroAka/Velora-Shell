import QtQuick

Loader {
    id: root

    property var popup: null
    property string viewType: ""
    property int viewMargins: 0
    property real viewIntroProgress: 0
    readonly property int viewIntroDuration: popup ? Math.max(260, popup.motionPanelIn + 70) : 290
    readonly property int viewIntroOffset: popup && popup.lineReveal ? 16 : 10

    anchors.fill: parent
    anchors.margins: viewMargins
    active: popup && popup.popupType === viewType
    visible: active || viewIntroProgress > 0.001
    asynchronous: false
    opacity: viewIntroProgress
    scale: 0.965 + viewIntroProgress * 0.035
    transformOrigin: Item.Center

    transform: Translate {
        x: Math.round((1 - root.viewIntroProgress) * (root.popup && root.popup.attachedRight ? root.viewIntroOffset : -root.viewIntroOffset))
        y: Math.round((1 - root.viewIntroProgress) * 8)
    }

    onActiveChanged: {
        viewIntroAnimation.stop()
        if (active) {
            viewIntroProgress = 0
            viewIntroAnimation.to = 1
            viewIntroAnimation.duration = viewIntroDuration
            viewIntroAnimation.restart()
        } else {
            viewIntroProgress = 0
        }
    }

    Component.onCompleted: {
        if (active) {
            viewIntroProgress = 0
            viewIntroAnimation.to = 1
            viewIntroAnimation.duration = viewIntroDuration
            viewIntroAnimation.restart()
        }
    }

    NumberAnimation {
        id: viewIntroAnimation

        target: root
        property: "viewIntroProgress"
        from: root.viewIntroProgress
        to: 1
        duration: root.viewIntroDuration
        easing.type: root.popup ? root.popup.motionEaseEmphasized : Easing.OutCubic
        easing.bezierCurve: root.popup ? root.popup.motionEmphasizedCurve : []
    }
}
