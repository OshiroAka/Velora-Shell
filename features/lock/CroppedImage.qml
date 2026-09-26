import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source
    property var crop: ({ x: 0, y: 0, width: 1, height: 1 })
    property real radius: 0
    property bool mirrored: false
    // Animated sources pause with the surface instead of decoding off-screen.
    property bool playing: true
    readonly property string normalizedSource: String(source || "").toLowerCase()
        .split("?")[0].split("#")[0]
    readonly property bool animatedSource: [".gif", ".webp", ".apng", ".mng"].some(
        function(extension) { return normalizedSource.endsWith(extension) })

    Item {
        id: imageComposition
        anchors.fill: parent
        visible: false

        Item {
            id: croppedContent
            readonly property real cropX: Math.max(0, Math.min(0.99,
                Number(root.crop.x || 0)))
            readonly property real cropY: Math.max(0, Math.min(0.99,
                Number(root.crop.y || 0)))
            readonly property real cropWidth: Math.max(0.01, Math.min(1 - cropX,
                Number(root.crop.width === undefined ? 1 : root.crop.width)))
            readonly property real cropHeight: Math.max(0.01, Math.min(1 - cropY,
                Number(root.crop.height === undefined ? 1 : root.crop.height)))

            x: -cropX * parent.width / cropWidth
            y: -cropY * parent.height / cropHeight
            width: parent.width / cropWidth
            height: parent.height / cropHeight

            transform: Scale {
                origin.x: croppedContent.width / 2
                origin.y: croppedContent.height / 2
                xScale: root.mirrored ? -1 : 1
            }

            Image {
                id: staticImage
                anchors.fill: parent
                source: root.animatedSource ? "" : root.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                visible: !root.animatedSource && status === Image.Ready
            }

            AnimatedImage {
                id: animatedImage
                anchors.fill: parent
                source: root.animatedSource ? root.source : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
                playing: root.playing && root.visible
                visible: root.animatedSource && status === Image.Ready
            }
        }
    }

    Rectangle {
        id: imageMask
        anchors.fill: parent
        radius: Math.min(root.radius, width / 2, height / 2)
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: imageComposition
        visible: root.animatedSource
            ? animatedImage.status === Image.Ready
            : staticImage.status === Image.Ready
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: imageMask
        maskThresholdMin: 0.45
        maskSpreadAtMin: 1.0
    }
}
