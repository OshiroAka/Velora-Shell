import QtQuick
import Quickshell.Io

Item {
    id: root

    required property url source
    required property real directionX
    required property real directionY
    required property real wavePhase
    required property string transitionType
    required property string readyPath
    required property real transitionProgress

    property bool readyPublished: false

    readonly property bool sourceReady: oldFrame.status === Image.Ready

    function publishReady() {
        if (!sourceReady || readyPublished || !readyPath || readyPublisher.running)
            return

        readyPublished = true
        readyPublisher.command = ["touch", readyPath]
        readyPublisher.running = true
    }

    Process {
        id: readyPublisher

        running: false
        command: ["true"]
        onExited: running = false
    }

    Item {
        id: sourceLayer
        anchors.fill: parent

        layer.enabled: true
        layer.smooth: true
        layer.mipmap: false
        layer.effect: ShaderEffect {
            property var source
            property real progress: Math.max(0, Math.min(1, root.transitionProgress))
            property real waveAmplitude: 0.052
            property real waveFrequency: 5.5
            property real edgeSoftness: 0.018
            property real directionX: root.directionX
            property real directionY: root.directionY
            property real wavePhase: root.wavePhase
            property real transitionMode: root.transitionType === "grow" ? 1 : (root.transitionType === "outer" ? 2 : 0)

            blending: true
            fragmentShader: Qt.resolvedUrl("../shaders/wallpaper-wave.frag.qsb")
        }

        Image {
            id: oldFrame

            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: false
            smooth: true
            mipmap: false
            onStatusChanged: {
                if (status === Image.Ready)
                    root.publishReady()
            }
        }
    }

    Component.onCompleted: publishReady()
}
