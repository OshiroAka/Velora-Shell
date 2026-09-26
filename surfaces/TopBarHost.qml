import QtQuick
import Quickshell
import Quickshell.Wayland
import "../features/topbar" as TopBarFeature

Variants {
    id: root

    required property var compositor
    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var media
    required property var weather
    required property var status
    required property var actions
    required property var settings
    required property var editorController
    required property int opticsGeneration
    required property bool lockOccluding
    property real barWavePhase: 0
    property bool barOnRight: false
    readonly property int sidebarRailWidth: 66
    readonly property int screenCornerRadius: 24

    // A LayerShell window remains mapped even when Window.visible is false on
    // some compositors. Remove the variant entirely so no Overlay frame can
    // survive above the lock or a focused fullscreen client.
    model: root.config.topbarEnabled && !root.lockOccluding
        && !root.compositor.activeToplevelFullscreen
        ? root.compositor.screens : []

    PanelWindow {
        id: topbarWindow

        required property var modelData
        readonly property int stripHeight: root.config.topbarVariant === "end4-first"
            ? 40 : (root.config.referenceAppearance ? 40
                : Math.round(root.config.topbarHeight * root.config.topbarScale))
        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        // The lateral window starts directly below this exclusive zone and
        // owns the entire curved join, including the background of the clock.
        // Overlap the unified surface slightly so the horizontal seam
        // between the topbar and sidebar is never exposed.
        implicitHeight: stripHeight + 3
        exclusiveZone: stripHeight
        exclusionMode: ExclusionMode.Normal
        focusable: false

        anchors {
            top: true
            left: true
            right: true
        }

        // The reference is a conventional 40 px top panel. Fullscreen clients
        // remove the variant and the visual lock unmounts it, so Top is enough.
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "velora-shell-topbar"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // One region mirrors the one continuous strip from the first bar in
        // the supplied video. There are no hidden optical islands underneath.
        BackgroundEffect.blurRegion: Region {}

        // The reference panel owns its complete 40 px strip.
        mask: Region {
            Region {
                item: barLoader.item ? barLoader.item.barSurfaceItem : null
                radius: 0
                intersection: Intersection.Combine
            }

            // Cover only the physical seam above the 66 px left rail.
            // The rest of the topbar remains exactly 40 px tall.
            Region {
                item: sidebarSeamBridge
                radius: 0
                intersection: Intersection.Combine
            }
        }

        Rectangle {
            id: sidebarSeamBridge
            z: 2
            x: root.barOnRight ? topbarWindow.width - root.sidebarRailWidth : 0
            y: topbarWindow.stripHeight
            width: root.sidebarRailWidth
            height: 3
            color: root.theme.barSurface
        }

        // Black only in the physical corner cutouts: the straight screen
        // edges keep the bar's own material.
        Canvas {
            id: topScreenCorners
            z: 20
            anchors.fill: parent
            opacity: 1
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d")
                const radius = Math.min(root.screenCornerRadius,
                    width / 2, height)
                ctx.clearRect(0, 0, width, height)
                ctx.globalAlpha = 1
                ctx.fillStyle = "#000000"

                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(radius, 0)
                ctx.arc(radius, radius, radius,
                    -Math.PI / 2, -Math.PI, true)
                ctx.closePath()
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(width, 0)
                ctx.lineTo(width - radius, 0)
                ctx.arc(width - radius, radius, radius,
                    -Math.PI / 2, 0, false)
                ctx.closePath()
                ctx.fill()
            }
            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        Loader {
            id: barLoader
            z: 1
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: topbarWindow.stripHeight
            sourceComponent: root.config.referenceAppearance ? referenceComponent
                : root.config.topbarVariant === "end4-first"
                ? end4FirstComponent : veloraComponent
        }

        Component {
            id: referenceComponent
            TopBarFeature.ReferenceBar {
                width: topbarWindow.width; height: topbarWindow.stripHeight
                config: root.config; theme: root.theme; clock: root.clock
                media: root.media; weather: root.weather
                status: root.status; actions: root.actions
                compositor: root.compositor; editorController: root.editorController
                wavePhase: root.barWavePhase
                opticsGeneration: root.opticsGeneration
            }
        }

        Component {
            id: veloraComponent
            TopBarFeature.TopBar {
                width: topbarWindow.width
                height: topbarWindow.stripHeight
                nativeSurfaceHeight: topbarWindow.stripHeight
                config: root.config
                theme: root.theme
                motion: root.motion
                clock: root.clock
                media: root.media
                weather: root.weather
                status: root.status
                actions: root.actions
                compositor: root.compositor
                settings: root.settings
                editorController: root.editorController
                opticsGeneration: root.opticsGeneration
            }
        }

        Component {
            id: end4FirstComponent
            TopBarFeature.End4FirstBar {
                width: topbarWindow.width
                height: topbarWindow.stripHeight
                nativeSurfaceHeight: topbarWindow.stripHeight
                config: root.config
                theme: root.theme
                motion: root.motion
                clock: root.clock
                media: root.media
                weather: root.weather
                status: root.status
                actions: root.actions
                compositor: root.compositor
                settings: root.settings
                editorController: root.editorController
                opticsGeneration: root.opticsGeneration
            }
        }
    }
}
