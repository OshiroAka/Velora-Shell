import QtQuick

Item {
    id: root

    property url source
    property bool playing: visible
    property int fillMode: Image.Stretch
    property bool smooth: true
    property bool mipmap: true
    property bool mirrored: false
    property bool reducedMotion: false
    property int duration: reducedMotion ? 0 : 190

    property int activeLayer: 0
    property url sourceA: ""
    property url sourceB: ""
    property url pendingSource: ""
    property bool initialized: false
    property bool mirroredA: false
    property bool mirroredB: false

    function activeItem() {
        return activeLayer === 0 ? layerA : layerB
    }

    function incomingItem() {
        return activeLayer === 0 ? layerB : layerA
    }

    function requestSwap() {
        const requested = String(source || "")
        if (!initialized) {
            mirroredA = mirrored
            sourceA = requested
            layerA.opacity = 1
            layerB.opacity = 0
            initialized = true
            return
        }
        if (String(activeItem().source || "") === requested && !pendingSource)
            return
        pendingSource = requested
        swapFallback.restart()
        const incoming = incomingItem()
        incoming.opacity = 0
        if (activeLayer === 0) {
            mirroredB = mirrored
            sourceB = requested
        } else {
            mirroredA = mirrored
            sourceA = requested
        }
        if (reducedMotion)
            finishSwap()
    }

    function finishSwap() {
        if (!pendingSource && !reducedMotion)
            return
        swapFallback.stop()
        const old = activeItem()
        const incoming = incomingItem()
        incoming.opacity = 1
        old.opacity = 0
        activeLayer = activeLayer === 0 ? 1 : 0
        pendingSource = ""
        clearOld.restart()
    }

    function refreshMirror() {
        const requested = String(source || "")
        if (!pendingSource && initialized
                && String(activeItem().source || "") !== requested)
            return
        if (pendingSource) {
            if (activeLayer === 0)
                mirroredB = mirrored
            else
                mirroredA = mirrored
        } else if (activeLayer === 0) {
            mirroredA = mirrored
        } else {
            mirroredB = mirrored
        }
    }

    LiveCharacter {
        id: layerA
        anchors.fill: parent
        source: root.sourceA
        playing: root.playing && opacity > 0.001
        fillMode: root.fillMode
        smooth: root.smooth
        mipmap: root.mipmap
        opacity: 0
        transform: Scale {
            origin.x: layerA.width / 2
            origin.y: layerA.height / 2
            xScale: root.mirroredA ? -1 : 1
        }

        Behavior on opacity {
            NumberAnimation { duration: root.duration; easing.type: Easing.InOutCubic }
        }
    }

    LiveCharacter {
        id: layerB
        anchors.fill: parent
        source: root.sourceB
        playing: root.playing && opacity > 0.001
        fillMode: root.fillMode
        smooth: root.smooth
        mipmap: root.mipmap
        opacity: 0
        transform: Scale {
            origin.x: layerB.width / 2
            origin.y: layerB.height / 2
            xScale: root.mirroredB ? -1 : 1
        }

        Behavior on opacity {
            NumberAnimation { duration: root.duration; easing.type: Easing.InOutCubic }
        }
    }

    Connections {
        target: layerA
        function onReadyChanged() {
            if (root.activeLayer === 1 && layerA.ready && root.pendingSource)
                root.finishSwap()
        }
    }

    Connections {
        target: layerB
        function onReadyChanged() {
            if (root.activeLayer === 0 && layerB.ready && root.pendingSource)
                root.finishSwap()
        }
    }

    Timer {
        id: swapFallback
        interval: 760
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

    // A zero-delay owned timer coalesces source/mirror changes in the same
    // config frame without leaving a Qt.callLater callback behind when a
    // hot reload destroys this component.
    Timer {
        id: sourceSync
        interval: 0
        repeat: false
        onTriggered: root.requestSwap()
    }

    Timer {
        id: mirrorSync
        interval: 0
        repeat: false
        onTriggered: root.refreshMirror()
    }

    onSourceChanged: sourceSync.restart()
    onMirroredChanged: mirrorSync.restart()
    Component.onCompleted: requestSwap()
}
