import QtQuick
import "../platform" as Platform
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../features/topbar" as TopBarFeature
import "../components" as Components

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
    property bool nativeBarMaterial: false
    property var edgeMediaPanels: ({})
    property var edgeFullHeightPanels: ({})
    readonly property real desktopMorphProgress: notificationSource ? notificationSource.infiniteDesktopMorphProgress : 0
    readonly property real desktopTargetReveal: notificationSource ? notificationSource.infiniteDesktopTargetReveal : 0
    readonly property real desktopRailRemaining: notificationSource ? notificationSource.infiniteDesktopRailRemaining : 1
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
        readonly property int stripHeight: 40
        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        // Keep the reference window mapped at a stable size during popovers.
        // The legacy variants keep their original strip and 3 px rail join.
        implicitHeight: modelData.height
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

        function popoverState() {
            return { mounted: popover.mounted, anchor: popover.anchorX,
                x: popover.panelRect.x, y: popover.panelRect.y,
                width: popover.panelRect.width, height: popover.panelRect.height,
                timerAlert: { suppressed: timerAlert.suppressed, visible: timerAlert.visible,
                    reveal: timerAlert.reveal, width: timerAlert.width, height: timerAlert.height },
                charging: { connected: chargingMorph.charging, anchorAvailable: chargingMorph.anchorAvailable,
                    suppressed: chargingMorph.suppressed, bodyDismissed: chargingMorph.bodyDismissed,
                    presenting: chargingMorph.presenting, reveal: chargingMorph.reveal,
                    progress: chargingMorph.gradientProgress, strength: chargingMorph.gradientStrength } }
        }
        function keyboardState() {
            return { mode: WlrLayershell.keyboardFocus, active: popover.Window.active,
                popupFocus: popover.activeFocus }
        }

        // One region mirrors the one continuous strip from the first bar in
        // the supplied video. There are no hidden optical islands underneath.
        BackgroundEffect.blurRegion: Region {
            item: root.config.referenceAppearance && root.config.barBlurEnabled
                && (root.config.barMaterial === "glass" || !Platform.NativeBlur.supports("topbar-connected")) ? connectedSurface : null
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
                item: executionIndicator.notificationMode && executionIndicator.visible
                    ? executionIndicator : null
                radius: executionIndicator.cornerRadius
                intersection: Intersection.Combine
            }
            Region {
                item: timerAlert.visible ? timerAlert : null
                radius: timerAlert.cornerRadius
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
                Platform.NativeBlur.dispatch("velora-blur:topbar-connected " + screen.name + " -1")
                return
            }
            if (popover.mounted && height < modelData.height) return
            const currentRect = popover.mounted ? popover.panelRect : Qt.rect(0, 0, 0, 0)
            const p = currentRect.height > 0.01 ? currentRect : Qt.rect(0, 0, 0, 0)
            // Anchor layout can settle one frame after a reload or screen resize.
            if (p.x < 0 || p.x + p.width > width) return
            const anchor = popover.anchorX
            const neck = popover.neckHalfWidth
            const radius = 18
            const join = 8
            const statusRect = executionIndicator.surfaceRect
            const s = statusRect.height > 0.01 && statusRect.x >= 0
                && statusRect.x + statusRect.width <= width
                && statusRect.y >= 0 && statusRect.y + statusRect.height <= height
                ? statusRect : Qt.rect(0, 0, 0, 0)
            const c = chargingMorph.surfaceRect
            const t = timerAlert.surfaceRect
            const values = [stripHeight / height, p.x / width, p.y / height,
                p.width / width, p.height / height, anchor / width,
                neck / width, radius / width, join / width,
                s.x / width, s.y / height, s.width / width, s.height / height,
                0.5, executionIndicator.neckHalfWidth / width,
                executionIndicator.cornerRadius / width, executionIndicator.joinRadius / width,
                c.x / width, c.y / height, c.width / width, c.height / height,
                chargingMorph.anchorX / width, chargingMorph.neckHalfWidth / width,
                chargingMorph.cornerRadius / width, chargingMorph.joinRadius / width,
                chargingMorph.gradientProgress, chargingMorph.gradientStrength,
                t.x / width, t.y / height, t.width / width, t.height / height,
                timerAlert.anchorX / width, timerAlert.neckHalfWidth / width,
                timerAlert.cornerRadius / width, timerAlert.joinRadius / width,
                timerAlert.anchorX / width, root.timerService.alertPhase, root.timerService.alertStrength]
            Platform.NativeBlur.dispatch("velora-blur:topbar-connected " + screen.name + " "
                + (["liquid", "liquid-glass"].includes(root.config.barMaterial) || root.nativeBarMaterial ? 1 : 0) + " "
                + values.map(value => Number(value).toFixed(8)).join(" "))
        }
        property bool surfaceDirty: true
        onWidthChanged: surfaceDirty = true
        onHeightChanged: surfaceDirty = true
        Component.onDestruction: {
            if (root.controller.owner === topbarWindow) root.controller.close()
            Platform.NativeBlur.dispatch("velora-blur:topbar-connected " + screen.name + " -1")
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
                executionIndicator.mounted ? executionIndicator.y + executionIndicator.height + 12 : 0,
                timerAlert.visible ? timerAlert.y + timerAlert.height + 12 : 0,
                chargingMorph.visible ? chargingMorph.y + chargingMorph.height + 12 : 0)
            barHeight: topbarWindow.stripHeight
            panelRect: popover.panelRect
            anchorX: popover.anchorX
            neckHalfWidth: popover.neckHalfWidth
            executionRect: executionIndicator.surfaceRect
            executionAnchor: topbarWindow.width / 2
            executionNeck: executionIndicator.neckHalfWidth
            executionRadius: executionIndicator.cornerRadius
            executionJoin: executionIndicator.joinRadius
            chargingRect: chargingMorph.surfaceRect
            chargingAnchor: chargingMorph.anchorX
            chargingNeck: chargingMorph.neckHalfWidth
            chargingRadius: chargingMorph.cornerRadius
            chargingJoin: chargingMorph.joinRadius
            chargingProgress: chargingMorph.gradientProgress
            chargingStrength: chargingMorph.gradientStrength
            timerAnchor: timerAlert.anchorX
            timerRect: timerAlert.surfaceRect
            timerNeck: timerAlert.neckHalfWidth
            timerRadius: timerAlert.cornerRadius
            timerJoin: timerAlert.joinRadius
            timerProgress: root.timerService.alertPhase
            timerStrength: root.timerService.alertStrength
            fillColor: root.nativeBarMaterial ? "transparent" : root.theme.barSurface
            lineColor: ["liquid", "liquid-glass"].includes(root.config.barMaterial) || root.nativeBarMaterial ? "transparent" : root.theme.borderSubtle
            onNeckHalfWidthChanged: topbarWindow.surfaceDirty = true
        }
        Components.VeloraMediaBackdrop {
            readonly property var edgePanel: root.edgeMediaPanels[topbarWindow.modelData.name] || null
            x: topbarWindow.width - width - (edgePanel ? edgePanel.railWidth : 0)
            width: edgePanel ? edgePanel.bodyWidth : 0
            height: topbarWindow.stripHeight
            z: 1
            visible: !!edgePanel && edgePanel.page === "media" && width > 0
            opacity: edgePanel ? edgePanel.contentReveal : 0
            source: visible && root.media.hasPlayer ? root.media.artUrl : ""
            artworkHeight: Math.min(650, Math.max(280, (edgePanel ? Math.max(640, edgePanel.targetHeight) : 0) * .64)) + 40
            topInset: 0
            animated: !root.motion.reduced
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
            leftInset: root.barOnRight ? 8 : root.sidebarRailWidth * root.desktopRailRemaining + 8
            rightInset: root.barOnRight ? root.sidebarRailWidth * root.desktopRailRemaining + 8 : 8
            z: 3
            width: topbarWindow.width
            height: topbarWindow.height
            host: topbarWindow
            shell: root.notificationSource
            motionTokens: root.motion
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

        TopBarFeature.TimerAlertMorph {
            id: timerAlert
            z: 5
            theme: root.theme
            service: root.timerService
            reducedMotion: root.config.reducedMotion
            suppressed: popover.mounted || !!root.edgeFullHeightPanels[topbarWindow.modelData.name]
            barHeight: topbarWindow.stripHeight
            availableWidth: topbarWindow.width
            leftInset: popover.leftInset
            rightInset: popover.rightInset
            anchorX: Math.max(leftInset, Math.min(topbarWindow.width - rightInset,
                barLoader.item ? barLoader.item.timerAnchorX : topbarWindow.width / 2))
            onSurfaceRectChanged: topbarWindow.surfaceDirty = true
            onNeckHalfWidthChanged: topbarWindow.surfaceDirty = true
            onAnchorXChanged: topbarWindow.surfaceDirty = true
        }
        Connections {
            target: root.timerService
            function onAlertPhaseChanged() { topbarWindow.surfaceDirty = true }
            function onAlertStrengthChanged() { topbarWindow.surfaceDirty = true }
        }

        TopBarFeature.ChargingMorph {
            id: chargingMorph
            z: 1
            theme: root.theme
            charging: root.config.referenceAppearance && root.status.hasBattery && root.status.batteryCharging
            anchorAvailable: !!barLoader.item && barLoader.item.batteryAnchorVisible
            suppressed: !!root.edgeFullHeightPanels[topbarWindow.modelData.name]
            percentage: root.status.batteryPercent
            reducedMotion: root.config.reducedMotion
            barHeight: topbarWindow.stripHeight
            anchorX: Math.max(leftInset, Math.min(topbarWindow.width - rightInset,
                barLoader.item ? barLoader.item.batteryAnchorX : 0))
            availableWidth: topbarWindow.width
            availableHeight: topbarWindow.height
            leftInset: popover.leftInset
            rightInset: popover.rightInset
            onSurfaceRectChanged: topbarWindow.surfaceDirty = true
            onNeckHalfWidthChanged: topbarWindow.surfaceDirty = true
            onGradientProgressChanged: topbarWindow.surfaceDirty = true
            onGradientStrengthChanged: topbarWindow.surfaceDirty = true
        }

        Rectangle {
            id: sidebarSeamBridge
            z: 2
            x: root.barOnRight ? topbarWindow.width - root.sidebarRailWidth : 0
            y: topbarWindow.stripHeight
            width: root.sidebarRailWidth * root.desktopRailRemaining
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
            sourceComponent: referenceComponent
        }

        Component {
            id: referenceComponent
            TopBarFeature.ReferenceBar {
                shell: root.notificationSource
                desktopMorphProgress: root.desktopMorphProgress
                desktopTargetReveal: root.desktopTargetReveal
                onGeometryChanged: Qt.callLater(popover.refreshAnchor)
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




    }
}
