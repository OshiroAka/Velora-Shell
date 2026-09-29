import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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
    required property var controller
    required property var timerService
    required property var notificationSource
    required property var executionStatus
    required property var system
    required property var fanPlus
    required property var calendar
    required property int opticsGeneration
    required property bool lockOccluding
    property real barWavePhase: 0
    property bool barOnRight: false
    readonly property int sidebarRailWidth: 64
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
        readonly property bool editingBar: root.editorController.shown
            && root.editorController.mode === "editing" && root.editorController.editSpace === "desktop"
        readonly property int stripHeight: root.config.topbarVariant === "end4-first"
            ? 40 : (root.config.referenceAppearance ? 40
                : Math.round(root.config.topbarHeight * root.config.topbarScale))
        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        // Keep the reference window mapped at a stable size during popovers.
        // The legacy variants keep their original strip and 3 px rail join.
        implicitHeight: root.config.referenceAppearance ? modelData.height : stripHeight + 3
        exclusiveZone: stripHeight
        exclusionMode: ExclusionMode.Normal

        anchors {
            top: true
            left: true
            right: true
        }

        // The reference is a conventional 40 px top panel. Fullscreen clients
        // remove the variant and the visual lock unmounts it, so Top is enough.
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "velora-shell-topbar"
        WlrLayershell.keyboardFocus: popover.mounted ? WlrKeyboardFocus.Exclusive
            : editingBar ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        function keyboardState() {
            return { mode: WlrLayershell.keyboardFocus, active: popover.Window.active,
                popupFocus: popover.activeFocus }
        }

        // One region mirrors the one continuous strip from the first bar in
        // the supplied video. There are no hidden optical islands underneath.
        BackgroundEffect.blurRegion: Region {
            item: root.config.referenceAppearance && root.config.barBlurEnabled
                && root.config.barMaterial === "glass" ? connectedSurface : null
        }

        // The reference panel owns its complete 40 px strip.
        mask: Region {
            Region { item: outsideInput; intersection: Intersection.Combine }
            Region {
                item: barLoader.item ? barLoader.item.barSurfaceItem : null
                radius: 0
                intersection: Intersection.Combine
            }

            Region {
                item: executionIndicator.notificationMode && executionIndicator.mounted
                    ? executionIndicator : null
                radius: executionIndicator.cornerRadius
                intersection: Intersection.Combine
            }

            // Cover only the physical seam above the 64 px rail.
            // The rest of the topbar remains exactly 40 px tall.
            Region {
                item: sidebarSeamBridge
                radius: 0
                intersection: Intersection.Combine
            }
        }

        function syncConnectedSurface() {
            if (width <= 0 || height <= 0) return
            if (!root.config.referenceAppearance) {
                Hyprland.dispatch("velora-blur:topbar-connected " + screen.name + " -1")
                return
            }
            if (popover.mounted && height < modelData.height) return
            const currentRect = popover.mounted ? popover.panelRect : executionIndicator.surfaceRect
            const p = currentRect.height > 0.01 ? currentRect : Qt.rect(0, 0, 0, 0)
            // Anchor layout can settle one frame after a reload or screen resize.
            if (p.x < 0 || p.x + p.width > width) return
            const anchor = popover.mounted ? popover.anchorX : width / 2
            const neck = popover.mounted ? popover.neckHalfWidth : executionIndicator.neckHalfWidth
            const radius = popover.mounted ? 18 : executionIndicator.cornerRadius
            const join = popover.mounted ? 8 : executionIndicator.joinRadius
            const values = [stripHeight / height, p.x / width, p.y / height,
                p.width / width, p.height / height, anchor / width,
                neck / width, radius / width, join / width]
            Hyprland.dispatch("velora-blur:topbar-connected " + screen.name + " "
                + (root.config.barMaterial === "liquid" ? 1 : 0) + " "
                + values.map(value => Number(value).toFixed(8)).join(" "))
        }
        property bool surfaceDirty: true
        onWidthChanged: surfaceDirty = true
        onHeightChanged: surfaceDirty = true
        Component.onDestruction: {
            if (root.controller.owner === topbarWindow) root.controller.close()
            Hyprland.dispatch("velora-blur:topbar-connected " + screen.name + " -1")
        }
        FrameAnimation {
            running: topbarWindow.surfaceDirty
            onTriggered: { topbarWindow.syncConnectedSurface(); topbarWindow.surfaceDirty = false }
        }
        Connections {
            target: root.config
            function onBarMaterialChanged() { topbarWindow.surfaceDirty = true }
            function onTopbarLayoutChanged() { root.controller.close() }
            function onReferenceAppearanceChanged() { root.controller.close(); topbarWindow.surfaceDirty = true }
        }
        Connections {
            target: root
            function onOpticsGenerationChanged() { topbarWindow.surfaceDirty = true }
        }
        TopBarFeature.ConnectedSurface {
            id: connectedSurface
            visible: root.config.referenceAppearance
            width: topbarWindow.width
            height: Math.max(topbarWindow.stripHeight, popover.panelRect.y + popover.panelRect.height + 12,
                executionIndicator.mounted ? executionIndicator.y + executionIndicator.height + 12 : 0)
            barHeight: topbarWindow.stripHeight
            panelRect: popover.panelRect
            anchorX: popover.anchorX
            neckHalfWidth: popover.neckHalfWidth
            executionRect: executionIndicator.surfaceRect
            executionAnchor: topbarWindow.width / 2
            executionNeck: executionIndicator.neckHalfWidth
            executionRadius: executionIndicator.cornerRadius
            executionJoin: executionIndicator.joinRadius
            fillColor: root.theme.barSurface
            lineColor: root.config.barMaterial === "liquid" ? "transparent" : root.theme.borderSubtle
            onNeckHalfWidthChanged: topbarWindow.surfaceDirty = true
        }
        MouseArea {
            id: outsideInput
            width: topbarWindow.width
            height: popover.mounted ? topbarWindow.height : 0
            acceptedButtons: Qt.AllButtons
            onPressed: root.controller.close()
            onWheel: wheel => { wheel.accepted = true }
        }
        TopBarFeature.ConnectedPopover {
            id: popover
            z: 3
            width: topbarWindow.width
            height: topbarWindow.modelData.height
            host: topbarWindow
            controller: root.controller; config: root.config; theme: root.theme
            status: root.status; system: root.system; timerService: root.timerService
            fanPlus: root.fanPlus
            clock: root.clock; calendar: root.calendar; media: root.media; weather: root.weather
            actions: root.actions
            barHeight: topbarWindow.stripHeight
            onPanelRectChanged: topbarWindow.surfaceDirty = true
            onAnchorXChanged: topbarWindow.surfaceDirty = true
        }

        IdleInhibitor { window: topbarWindow; enabled: root.system.caffeineActive }

        QtObject {
            id: centralStatus
            readonly property bool notificationShown: !!root.notificationSource
                && root.notificationSource.notificationToastVisible
            readonly property bool shown: notificationShown || root.executionStatus.shown
            readonly property var current: notificationShown ? ({
                id: "notification-" + root.notificationSource.notificationToastSerial,
                phase: "notification", agent: root.notificationSource.notificationToastApp || "Notificação",
                label: root.notificationSource.notificationToastTitle, detail: "", progress: -1,
                iconKey: root.notificationSource.notificationToastIconKey
            }) : root.executionStatus.current
        }
        TopBarFeature.ExecutionIndicator {
            id: executionIndicator
            anchors.horizontalCenter: parent.horizontalCenter
            y: topbarWindow.stripHeight + executionIndicator.connectionGap
            onSurfaceRectChanged: topbarWindow.surfaceDirty = true
            onNeckHalfWidthChanged: topbarWindow.surfaceDirty = true
            onCornerRadiusChanged: topbarWindow.surfaceDirty = true
            onJoinRadiusChanged: topbarWindow.surfaceDirty = true
            z: 1
            availableWidth: topbarWindow.width - 32
            enabled: root.config.referenceAppearance
            opacity: enabled ? 1 : 0
            theme: root.theme
            service: centralStatus
            MouseArea {
                anchors.fill: parent
                enabled: executionIndicator.notificationMode && executionIndicator.mounted
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.notificationSource.hideNotificationToast()
            }
        }

        Rectangle {
            id: sidebarSeamBridge
            z: 2
            x: root.barOnRight ? topbarWindow.width - root.sidebarRailWidth : 0
            y: topbarWindow.stripHeight
            width: root.sidebarRailWidth
            height: 3
            color: root.config.referenceAppearance ? "transparent" : root.theme.barSurface
        }

        // Black only in the physical corner cutouts: the straight screen
        // edges keep the bar's own material.
        Canvas {
            id: topScreenCorners
            z: 20
            width: topbarWindow.width
            height: topbarWindow.stripHeight + 3
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
            z: 4
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
                controller: root.controller; host: topbarWindow
                system: root.system; timerService: root.timerService
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
