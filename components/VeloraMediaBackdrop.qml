pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "EdgeMediaContours.js" as Contours

// Artwork remains recognizable. Only a small blur softens it into the surface.
// The topbar renders the first 40 px of this same composition in its own window.
Item {
    id: root
    property string source: ""
    property real artworkHeight: Math.min(650, Math.max(280, height * .64)) + 40
    property real topInset: 40
    property var contourSamples: []
    property bool animated: true
    readonly property bool ready: cover.status === Image.Ready
    clip: true

    function artworkOpacity(y) {
        // Leave the header in the native material. A gradual, flat-ended
        // entrance also hides the hard top margin in letterboxed album art.
        const start = Math.max(112, artworkHeight * .22)
        const end = Math.max(start + 96, artworkHeight * .43)
        const entrance = Math.max(0, Math.min(1, (y - start) / (end - start)))
        const exit = Math.max(0, Math.min(1, (y / artworkHeight - .43) / .57))
        return .88 * entrance * entrance * (3 - 2 * entrance)
            * (1 - exit * exit * (3 - 2 * exit))
    }

    Item {
        anchors.fill: parent
        // Fade the whole composition to transparency, revealing the native
        // liquid material underneath instead of painting a solid dark panel.
        opacity: root.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.animated ? 260 : 0 } }
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: silhouette }
        Item {
            width: parent.width
            height: root.artworkHeight
            y: -root.topInset
            Image {
                id: cover
                objectName: "edgeMediaBackdropImage"
                anchors.fill: parent
                source: root.source.startsWith("spotify:image:")
                    ? "https://i.scdn.co/image/" + root.source.substring(14) : root.source
                sourceSize: Qt.size(Math.min(1024, Math.ceil(root.width * 1.5)),
                    Math.min(1024, Math.ceil(root.artworkHeight * 1.5)))
                asynchronous: true
                retainWhileLoading: true
                fillMode: Image.PreserveAspectCrop
                layer.enabled: root.ready && GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 16
                    blur: .18
                    autoPaddingEnabled: false
                }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "#bf111316" }
                    GradientStop { position: .15; color: "#30111316" }
                    GradientStop { position: .42; color: "#45111316" }
                    GradientStop { position: .66; color: "#70111316" }
                    GradientStop { position: .88; color: "#a0111316" }
                    GradientStop { position: 1; color: "#bf111316" }
                }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#a6111316" }
                    GradientStop { position: .28; color: "#20111316" }
                    GradientStop { position: 1; color: "#00111316" }
                }
            }
        }
    }
    Canvas {
        id: silhouette
        visible: false
        width: root.width; height: root.height
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onContourSamplesChanged() { silhouette.requestPaint() }
            function onArtworkHeightChanged() { silhouette.requestPaint() }
            function onTopInsetChanged() { silhouette.requestPaint() }
        }
        onPaint: {
            const c = getContext("2d")
            c.reset()
            const fade = c.createLinearGradient(0, -root.topInset, 0, root.artworkHeight - root.topInset)
            // Sample one smooth opacity curve in artwork coordinates. Both
            // the topbar slice and body use it, including their 40 px offset.
            for (let i = 0; i <= 96; ++i) {
                const p = i / 96
                fade.addColorStop(p, "rgba(255,255,255," + root.artworkOpacity(p * root.artworkHeight) + ")")
            }
            c.fillStyle = fade
            if (!root.contourSamples.length) { c.fillRect(0, 0, width, height); return }
            c.beginPath(); c.moveTo(width, 0); c.lineTo(width, height)
            for (let i = 160; i >= 0; --i) {
                const t = i / 160
                c.lineTo(Contours.offset(root.contourSamples, t) * width, t * height)
            }
            c.closePath(); c.fill()
        }
    }
}
