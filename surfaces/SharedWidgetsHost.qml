import QtQuick
import "../platform" as Platform
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../features/widgets" as Widgets

Variants {
    id: root

    required property var compositor
    required property var preview
    required property var settings
    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var calendarService
    required property var media
    required property var weather
    required property var visualizer
    required property var status
    required property var transition
    required property var editor
    required property var causticsClock
    required property int opticsGeneration
    property bool barOnRight: false
    property var cameraViews: ({})
    property bool infiniteDesktopEnabled: false
    property bool nativeBarMaterial: false
    property bool visualizerSuppressed: false
    property real visualizerDockProgress: 0
    property int visualizerRailInset: 0
    property int visualizerCornerRadius: 0
    property int visualizerBottomInset: 0

    model: compositor.focusedScreen ? [compositor.focusedScreen] : []

    PanelWindow {
        id: widgetWindow
        required property var modelData
        property bool nativeShapeDirty: true
        property int nativeShapeRetries: 0

        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        implicitHeight: modelData.height
        exclusionMode: ExclusionMode.Ignore
        focusable: sharedScene.detailsOpen

        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.layer: root.settings.shown
            && root.settings.mode === "editing" ? WlrLayer.Top
            : (root.preview.occluding ? WlrLayer.Overlay : WlrLayer.Bottom)
        WlrLayershell.namespace: "velora-shell-shared-widgets"
        WlrLayershell.keyboardFocus: sharedScene.detailsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        function nativeShape(item, radius) {
            if (!item || width <= 0 || height <= 0 || !item.visible
                    || item.opacity <= 0.001
                    || String(item.currentMaterial || "liquid") !== "liquid")
                return "0 0 0 0 0 0 0 0"
            const center = item.mapToItem(
                sharedScene, item.width * 0.5, item.height * 0.5)
            const right = item.mapToItem(
                sharedScene, item.width, item.height * 0.5)
            const bottom = item.mapToItem(
                sharedScene, item.width * 0.5, item.height)
            const widthVectorX = right.x - center.x
            const widthVectorY = right.y - center.y
            const heightVectorX = bottom.x - center.x
            const heightVectorY = bottom.y - center.y
            const mappedWidth = Math.max(0.01,
                Math.sqrt(widthVectorX * widthVectorX
                          + widthVectorY * widthVectorY) * 2)
            const mappedHeight = Math.max(0.01,
                Math.sqrt(heightVectorX * heightVectorX
                          + heightVectorY * heightVectorY) * 2)
            const rotation = Math.atan2(widthVectorY, widthVectorX)
                * 180 / Math.PI
            const radiusPixels = Number(radius)
                * mappedWidth / Math.max(1, item.width)
            return "1 "
                + ((center.x - mappedWidth * 0.5) / width).toFixed(6) + " "
                + ((center.y - mappedHeight * 0.5) / height).toFixed(6) + " "
                + (mappedWidth / width).toFixed(6) + " "
                + (mappedHeight / height).toFixed(6) + " "
                + (radiusPixels / width).toFixed(6) + " "
                + rotation.toFixed(4) + " "
                + Math.max(0, Math.min(1, item.opacity)).toFixed(4)
        }

        function queueNativeShapes() { nativeShapeDirty = true }

        function scheduleNativeShapeResync() {
            nativeShapeRetries = 4
            queueNativeShapes()
            nativeShapeRetry.restart()
        }

        function syncNativeShapes() {
            if (width <= 0 || height <= 0)
                return
            const shapes = [
                nativeShape(sharedScene.clockHitItem, sharedScene.clockHitItem.currentRadius),
                nativeShape(sharedScene.weatherHitItem, sharedScene.weatherHitItem.currentRadius),
                nativeShape(sharedScene.mediaHitItem, sharedScene.mediaHitItem.currentRadius),
                nativeShape(sharedScene.galleryHitItem, sharedScene.galleryHitItem.currentRadius),
                nativeShape(sharedScene.systemHitItem, sharedScene.systemHitItem.currentRadius),
                nativeShape(sharedScene.batteryHitItem, sharedScene.batteryHitItem.currentRadius)
            ]
            const caustics = root.preview.shown
                && root.config.waterCausticsEnabled
                && root.config.waterCausticsLines
                && root.config.waterCausticsModules
            Platform.NativeBlur.dispatch("velora-blur:shared-widgets-shape 1 "
                + (caustics ? "1 " : "0 ") + shapes.join(" "))
        }

        onWidthChanged: queueNativeShapes()
        onHeightChanged: queueNativeShapes()
        property int appliedOpticsGeneration: root.opticsGeneration
        onAppliedOpticsGenerationChanged: scheduleNativeShapeResync()

        Timer {
            id: nativeShapeRetry
            interval: 120
            repeat: true
            onTriggered: {
                widgetWindow.queueNativeShapes()
                widgetWindow.nativeShapeRetries -= 1
                if (widgetWindow.nativeShapeRetries <= 0)
                    stop()
            }
        }

        FrameAnimation {
            running: widgetWindow.nativeShapeDirty
            onTriggered: {
                widgetWindow.syncNativeShapes()
                widgetWindow.nativeShapeDirty = false
            }
        }

        Component.onCompleted: scheduleNativeShapeResync()
        Component.onDestruction:
            Platform.NativeBlur.dispatch("velora-blur:shared-widgets-shape 0")

        Region {
            id: individualBlurRegion
            Region { item: sharedScene.translucentWidget(sharedScene.clockHitItem) ? sharedScene.clockHitItem : null; radius: Math.round(sharedScene.clockHitItem.currentRadius * sharedScene.clockHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.weatherHitItem) ? sharedScene.weatherHitItem : null; radius: Math.round(sharedScene.weatherHitItem.currentRadius * sharedScene.weatherHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.mediaHitItem) ? sharedScene.mediaHitItem : null; radius: Math.round(sharedScene.mediaHitItem.currentRadius * sharedScene.mediaHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.galleryHitItem) ? sharedScene.galleryHitItem : null; radius: Math.round(sharedScene.galleryHitItem.currentRadius * sharedScene.galleryHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.systemHitItem) ? sharedScene.systemHitItem : null; radius: Math.round(sharedScene.systemHitItem.currentRadius * sharedScene.systemHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.batteryHitItem) ? sharedScene.batteryHitItem : null; radius: Math.round(sharedScene.batteryHitItem.currentRadius * sharedScene.batteryHitItem.scale); intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 0 ? sharedScene.dynamicBlurItem(0) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 1 ? sharedScene.dynamicBlurItem(1) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 2 ? sharedScene.dynamicBlurItem(2) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 3 ? sharedScene.dynamicBlurItem(3) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 4 ? sharedScene.dynamicBlurItem(4) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 5 ? sharedScene.dynamicBlurItem(5) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 6 ? sharedScene.dynamicBlurItem(6) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 7 ? sharedScene.dynamicBlurItem(7) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 8 ? sharedScene.dynamicBlurItem(8) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 9 ? sharedScene.dynamicBlurItem(9) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 10 ? sharedScene.dynamicBlurItem(10) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 11 ? sharedScene.dynamicBlurItem(11) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 12 ? sharedScene.dynamicBlurItem(12) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 13 ? sharedScene.dynamicBlurItem(13) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 14 ? sharedScene.dynamicBlurItem(14) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 15 ? sharedScene.dynamicBlurItem(15) : null; radius: 28; intersection: Intersection.Combine }
        }
        BackgroundEffect.blurRegion: root.config.widgetBlurEnabled ? individualBlurRegion : noWidgetBlur
        Region { id: noWidgetBlur }

        mask: Region {
            Region { item: sharedScene.detailsHitItem; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 0 ? sharedScene.dynamicHitItem(0) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 1 ? sharedScene.dynamicHitItem(1) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 2 ? sharedScene.dynamicHitItem(2) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 3 ? sharedScene.dynamicHitItem(3) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 4 ? sharedScene.dynamicHitItem(4) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 5 ? sharedScene.dynamicHitItem(5) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 6 ? sharedScene.dynamicHitItem(6) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 7 ? sharedScene.dynamicHitItem(7) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 8 ? sharedScene.dynamicHitItem(8) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 9 ? sharedScene.dynamicHitItem(9) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 10 ? sharedScene.dynamicHitItem(10) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 11 ? sharedScene.dynamicHitItem(11) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 12 ? sharedScene.dynamicHitItem(12) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 13 ? sharedScene.dynamicHitItem(13) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 14 ? sharedScene.dynamicHitItem(14) : null; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 15 ? sharedScene.dynamicHitItem(15) : null; intersection: Intersection.Combine }
            Region { item: sharedScene.clockHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.weatherHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.mediaHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.galleryHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.systemHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.batteryHitItem; intersection: Intersection.Combine }
        }

        // A covered pixel keeps the desktop material host mapped even when
        // all widgets are hidden. It is underneath the fixed sidebar/frame.
        Rectangle {
            x: root.barOnRight ? parent.width - 2 : 1
            y: parent.height - 2
            width: 1; height: 1
            color: "#01000000"
            visible: root.nativeBarMaterial
        }

        Widgets.AudioVisualizer {
            x: parent.width*.092
            width: parent.width*.838
            anchors.bottom: parent.bottom
            height: Math.min(170,parent.height*.14) * (1 - root.visualizerDockProgress)
            referenceHeight: height
            theme: root.theme
            visualizer: root.visualizer
            darkPalette: true
            clipSideInset: 0
            clipCornerRadius: 0
            clipBottomInset: 0
            clipSideOnRight: root.barOnRight
            visible: !root.nativeBarMaterial && (!root.visualizerSuppressed || root.visualizerDockProgress < .999)
                && root.config.desktopVisualizerEnabled && root.visualizer.running && !root.preview.occluding
                && !(root.settings.shown && root.settings.mode === "editing")
            opacity: 0.78
        }

        Widgets.SharedWidgetsScene {
            id: sharedScene
            camera: root.cameraViews[String(widgetWindow.modelData.name || "")] || null
            infiniteDesktopEnabled: root.infiniteDesktopEnabled
            visible: !root.preview.occluding
            barOnRight: root.barOnRight
            anchors.fill: parent
            config: root.config
            theme: root.theme
            motion: root.motion
            clock: root.clock
            calendarService: root.calendarService
            media: root.media
            weather: root.weather
            status: root.status
            transition: root.transition
            editor: root.editor
            causticsClock: root.causticsClock
            lockPresented: false
            editing: root.settings.shown
                && root.settings.mode === "editing"
        }

        component ShapeConnections: Connections {
            required property Item watchedItem
            target: watchedItem
            function onXChanged() { widgetWindow.queueNativeShapes() }
            function onYChanged() { widgetWindow.queueNativeShapes() }
            function onWidthChanged() { widgetWindow.queueNativeShapes() }
            function onHeightChanged() { widgetWindow.queueNativeShapes() }
            function onScaleChanged() { widgetWindow.queueNativeShapes() }
            function onRotationChanged() { widgetWindow.queueNativeShapes() }
            function onOpacityChanged() { widgetWindow.queueNativeShapes() }
            function onVisibleChanged() { widgetWindow.queueNativeShapes() }
            function onCurrentRadiusChanged() { widgetWindow.queueNativeShapes() }
        }

        ShapeConnections { watchedItem: sharedScene.clockHitItem }
        ShapeConnections { watchedItem: sharedScene.weatherHitItem }
        ShapeConnections { watchedItem: sharedScene.mediaHitItem }
        ShapeConnections { watchedItem: sharedScene.galleryHitItem }
        ShapeConnections { watchedItem: sharedScene.systemHitItem }
        ShapeConnections { watchedItem: sharedScene.batteryHitItem }

        Connections {
            target: root.preview
            function onShownChanged() { widgetWindow.queueNativeShapes() }
        }

        Connections {
            target: root.config
            function onConfigurationChanged() { widgetWindow.queueNativeShapes() }
        }
    }
}
