import QtQuick

Item {
    id: root

    property url source
    property real radius: 22
    property real blurAmount: 0
    property real contentScale: 1
    property real contentOffsetX: 0
    property real contentOffsetY: 0
    property bool mirrored: false
    property bool asynchronous: true
    property int fillMode: Image.PreserveAspectCrop
    property int verticalAlignment: Image.AlignVCenter
    property bool reducedMotion: false
    property int duration: reducedMotion ? 0 : 170

    property int activeLayer: 0
    property url sourceA: ""
    property url sourceB: ""
    property url pendingSource: ""
    property bool initialized: false
    property real contentScaleA: 1
    property real contentScaleB: 1
    property real contentOffsetXA: 0
    property real contentOffsetXB: 0
    property real contentOffsetYA: 0
    property real contentOffsetYB: 0
    property bool mirroredA: false
    property bool mirroredB: false

    function captureAppearance(layer) {
        if (layer === 0) {
            contentScaleA = contentScale
            contentOffsetXA = contentOffsetX
            contentOffsetYA = contentOffsetY
            mirroredA = mirrored
        } else {
            contentScaleB = contentScale
            contentOffsetXB = contentOffsetX
            contentOffsetYB = contentOffsetY
            mirroredB = mirrored
        }
    }

    function refreshAppearance() {
        captureAppearance(pendingSource ? (activeLayer === 0 ? 1 : 0) : activeLayer)
    }

    function requestSwap() {
        const requested = String(source || "")
        if (!initialized) {
            captureAppearance(0)
            sourceA = requested
            imageA.opacity = 1
            imageB.opacity = 0
            initialized = true
            return
        }
        const active = activeLayer === 0 ? imageA : imageB
        if (String(active.source || "") === requested && !pendingSource)
            return
        pendingSource = requested
        const incoming = activeLayer === 0 ? imageB : imageA
        incoming.opacity = 0
        captureAppearance(activeLayer === 0 ? 1 : 0)
        if (activeLayer === 0)
            sourceB = requested
        else
            sourceA = requested
        fallback.restart()
        if (reducedMotion)
            finishSwap()
    }

    function finishSwap() {
        if (!pendingSource && !reducedMotion)
            return
        fallback.stop()
        const old = activeLayer === 0 ? imageA : imageB
        const incoming = activeLayer === 0 ? imageB : imageA
        incoming.opacity = 1
        old.opacity = 0
        activeLayer = activeLayer === 0 ? 1 : 0
        pendingSource = ""
        clearOld.restart()
    }

    RoundedImage {
        id: imageA
        anchors.fill: parent
        source: root.sourceA
        radius: root.radius
        blurAmount: root.blurAmount
        contentScale: root.contentScaleA
        contentOffsetX: root.contentOffsetXA
        contentOffsetY: root.contentOffsetYA
        mirrored: root.mirroredA
        asynchronous: root.asynchronous
        fillMode: root.fillMode
        verticalAlignment: root.verticalAlignment
        animateContentTransform: false
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: root.duration; easing.type: Easing.InOutCubic }
        }
    }

    RoundedImage {
        id: imageB
        anchors.fill: parent
        source: root.sourceB
        radius: root.radius
        blurAmount: root.blurAmount
        contentScale: root.contentScaleB
        contentOffsetX: root.contentOffsetXB
        contentOffsetY: root.contentOffsetYB
        mirrored: root.mirroredB
        asynchronous: root.asynchronous
        fillMode: root.fillMode
        verticalAlignment: root.verticalAlignment
        animateContentTransform: false
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: root.duration; easing.type: Easing.InOutCubic }
        }
    }

    Connections {
        target: imageA
        function onStatusChanged() {
            if (root.activeLayer === 1 && imageA.status === Image.Ready && root.pendingSource)
                root.finishSwap()
        }
    }

    Connections {
        target: imageB
        function onStatusChanged() {
            if (root.activeLayer === 0 && imageB.status === Image.Ready && root.pendingSource)
                root.finishSwap()
        }
    }

    Timer {
        id: fallback
        interval: 620
        repeat: false
        onTriggered: root.finishSwap()
    }

    Timer {
        id: clearOld
        interval: root.duration + 40
        repeat: false
        onTriggered: {
            if (root.activeLayer === 0)
                root.sourceB = ""
            else
                root.sourceA = ""
        }
    }

    Timer {
        id: sourceSync
        interval: 0
        repeat: false
        onTriggered: root.requestSwap()
    }

    Timer {
        id: appearanceSync
        interval: 0
        repeat: false
        onTriggered: root.refreshAppearance()
    }

    onSourceChanged: sourceSync.restart()
    onContentScaleChanged: appearanceSync.restart()
    onContentOffsetXChanged: appearanceSync.restart()
    onContentOffsetYChanged: appearanceSync.restart()
    onMirroredChanged: appearanceSync.restart()
    Component.onCompleted: requestSwap()
}
