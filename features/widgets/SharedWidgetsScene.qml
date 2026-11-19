import QtQuick
import QtQuick.Effects
import "../../core" as Core
import "../../components" as Components
import "../../core/SurfaceGeometry.js" as Geometry
import "../../core/WidgetCatalog.js" as WidgetCatalog

Item {
    id: root

    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var calendarService
    required property var media
    required property var weather
    required property var status
    required property var transition
    required property var editor
    required property var causticsClock
    required property bool lockPresented
    property bool editing: false
    property bool barOnRight: false
    property var camera: null
    property bool infiniteDesktopEnabled: false
    readonly property real parallaxX: parallax.x
    readonly property real parallaxY: parallax.y
    readonly property real parallaxScale: parallax.scale
    Core.WidgetParallax {
        id: parallax
        camera: root.camera
        active: root.infiniteDesktopEnabled
        snapToRest: root.motion.reduced || root.editing || root.lockPresented
            || root.transition.running || root.transition.progress > .001
        pace: root.motion.pace
        viewportWidth: root.width
        viewportHeight: root.height
    }
    readonly property var sceneBounds: Geometry.designBounds(width, height,
        lockPresented || !config.topbarEnabled ? 0 : 64, barOnRight,
        lockPresented || !config.topbarEnabled ? 0 : 40, lockPresented ? 0 : 18)

    readonly property real designScale: Math.min(width / 1600, height / 900)
    readonly property real designOriginX: (width - 1600 * designScale) / 2
    readonly property real designOriginY: (height - 900 * designScale) / 2
    readonly property bool interactionEnabled: !transition.running && !editing
    readonly property bool detailsEnabled: interactionEnabled && !lockPresented && visible
    readonly property int contentMotionDuration: detailsEnabled && !motion.reduced
        ? Math.round(340 * motion.pace) : 0
    readonly property string detailsContext: camera ? String(camera.workspace ?? "") : ""
    property Item expandedWidget: null
    property bool detailsOpen: false
    readonly property Item detailsHitItem: detailsOpen && detailPanel.visible ? detailPanel : null
    onDetailsEnabledChanged: if (!detailsEnabled) detailsOpen = false
    onDetailsContextChanged: detailsOpen = false
    onInfiniteDesktopEnabledChanged: detailsOpen = false
    readonly property bool layoutMorphing: editor.layoutTransitioning
    readonly property int layoutMorphDuration: motion.reduced ? 0 : 680
    readonly property bool moduleCaustics: lockPresented
        && config.waterCausticsEnabled && config.waterCausticsLines
        && config.waterCausticsModules

    property alias clockHitItem: sharedClock
    property alias weatherHitItem: sharedWeather
    property alias mediaHitItem: sharedMedia
    property alias galleryHitItem: sharedGallery
    property alias systemHitItem: sharedSystem
    property alias batteryHitItem: sharedBattery

    function widget(kind) {
        return config.sharedWidgetByKind(kind)
    }

    function toggleDetails(item) {
        if (!detailsEnabled || !item.visible)
            return
        if (detailsOpen && expandedWidget === item) {
            detailsOpen = false
        } else {
            expandedWidget = item
            detailsOpen = true
        }
    }

    function dynamicBlurItem(index) {
        const item = dynamicHitItem(index)
        if (!item
                || !["liquid", "liquid-glass"].includes(item.materialMode))
            return null
        return item
    }

    function dynamicHitItem(index) {
        const item = desktopLayerRepeater.itemAt(index)
        return item && item.visible && item.opacity > 0.001 ? item : null
    }

    function translucentWidget(item) {
        return item && item.visible && item.opacity > 0.001
            && String(item.currentMaterial || "solid") !== "solid"
            && String(item.currentMaterial || "solid") !== "none"
    }

    function mix(first, second, amount) {
        return Number(first) + (Number(second) - Number(first)) * Number(amount)
    }

    function transformFor(widgetData, stagger) {
        const fallback = { x: 0, y: 0, scale: 1, rotation: 0,
                           opacity: 1, flipX: false }
        if (!widgetData)
            return Object.assign({}, fallback, { opacity: 0, activity: 0 })
        const desktopBase = widgetData.desktop || fallback
        const lockBase = widgetData.lock || fallback
        const desktop = editor.editSpace === "desktop"
            ? editor.effectiveTransform(widgetData.id, desktopBase) : desktopBase
        const locked = editor.editSpace === "lock"
            ? editor.effectiveTransform(widgetData.id, lockBase) : lockBase
        const movement = transition.motionProgress(stagger)
        const opacityProgress = transition.staggeredProgress(stagger)
        const activity = transition.activity(stagger)
        const pulse = motion.reduced ? 1
            : 1 + Math.sin(Math.PI * opacityProgress) * 0.012
        const desktopOpacity = root.config.desktopWidgetsEnabled && widgetData.desktopEnabled
            ? Number(desktop.opacity === undefined ? 1 : desktop.opacity) : 0
        const lockOpacity = widgetData.lockEnabled
            ? Number(locked.opacity === undefined ? 1 : locked.opacity) : 0
        const candidate = {
            x: mix(desktop.x, locked.x, movement),
            y: mix(desktop.y, locked.y, movement),
            scale: mix(desktop.scale, locked.scale, movement) * pulse,
            rotation: mix(desktop.rotation, locked.rotation, movement),
            opacity: mix(desktopOpacity, lockOpacity, opacityProgress),
            flipX: opacityProgress < 0.5
                ? Boolean(desktop.flipX) : Boolean(locked.flipX),
            activity: activity
        }
        const constrained = config.constrainWidgetTransform(widgetData, candidate)
        constrained.activity = activity
        return constrained
    }

    function sizeFor(widgetData, stagger) {
        if (!widgetData)
            return { width: 8, height: 8 }
        const desktop = widgetData.desktopSize || {
            width: widgetData.baseWidth, height: widgetData.baseHeight }
        const locked = widgetData.lockSize || {
            width: widgetData.baseWidth, height: widgetData.baseHeight }
        const movement = transition.motionProgress(stagger)
        return {
            width: mix(desktop.width, locked.width, movement),
            height: mix(desktop.height, locked.height, movement)
        }
    }

    component SharedWidget: Item {
        id: widgetItem
        required property string kind
        readonly property bool hasDetails: ["clock", "weather", "system", "battery"].includes(kind)
        readonly property bool detailsSelected: root.detailsOpen && root.expandedWidget === widgetItem
        onVisibleChanged: if (!visible && detailsSelected) root.detailsOpen = false
        readonly property var widgetData: root.widget(kind)
        readonly property int stagger: widgetData
            ? Number(widgetData.stagger) : 0
        readonly property var currentStyle: {
            if (!widgetData)
                return ({})
            const baseStyle = root.transition.progress < 0.5
                ? Object.assign({material: "solid", solidColor: "#202634", surfaceOpacity: 0.88}, widgetData.desktopStyle || ({}))
                : (widgetData.lockStyle || ({}))
            if (root.config.widgetSurfaceMode === "bar") {
                return Object.assign({}, baseStyle, {
                    material: root.config.barMaterial,
                    surfaceOpacity: root.config.barMaterial === "solid"
                        ? 1 : root.config.barOpacity,
                    solidColor: root.theme.widgetSolidSurface,
                    matchBarSurface: true
                })
            }
            return Object.assign({}, baseStyle, {
                material: "solid",
                surfaceOpacity: 1,
                solidColor: root.theme.widgetSolidSurface,
                matchBarSurface: false
            })
        }
        readonly property real currentRadius: Number(currentStyle.radius === undefined ? 28 : currentStyle.radius)
        readonly property string currentMaterial: root.theme.resolvedMaterial(
            currentStyle)
        readonly property string configuredVariant: widgetData
            ? String(widgetData.variantId || "inherit") : "inherit"
        readonly property string currentVariant:
            root.transition.progress < 0.5
                ? WidgetCatalog.resolve(kind, configuredVariant).id : "classic"
        readonly property var stateTransform: root.transformFor(widgetData, stagger)
        readonly property var stateSize: root.sizeFor(widgetData, stagger)
        property real configuredX: Number(stateTransform.x || 0)
        property real configuredY: Number(stateTransform.y || 0)
        property real configuredScale: Number(
            stateTransform.scale === undefined ? 1 : stateTransform.scale)
        property real configuredRotation: Number(stateTransform.rotation || 0)
        property real configuredOpacity: Number(
            stateTransform.opacity === undefined ? 0 : stateTransform.opacity)
        property real configuredWidth: Number(stateSize.width || 8)
        property real configuredHeight: Number(stateSize.height || 8)
        property real hoverLift: widgetHover.hovered && root.interactionEnabled
            && !root.lockPresented && !root.motion.reduced ? 1 : 0

        readonly property var displayPose: Geometry.pose({x: configuredX, y: configuredY,
            scale: configuredScale * (1 + hoverLift * 0.014), rotation: configuredRotation}, configuredWidth, configuredHeight, root.sceneBounds)
        x: root.parallaxX + (root.designOriginX + displayPose.x * root.designScale) * root.parallaxScale
        y: root.parallaxY + (root.designOriginY + displayPose.y * root.designScale) * root.parallaxScale
        // Keep the card and all of its fixed design-space children in the
        // same 1600x900 coordinate system, then scale the whole module once.
        // Scaling only the host rectangle enlarged the glass background while
        // tile/text coordinates stayed unscaled, leaving the empty strip seen
        // below every module on 1920x1200 displays.
        width: configuredWidth
        height: configuredHeight
        scale: displayPose.scale * root.designScale * root.parallaxScale
        rotation: configuredRotation
        opacity: configuredOpacity
        visible: Boolean(widgetData) && opacity > 0.001
        enabled: root.interactionEnabled
        transformOrigin: Item.TopLeft
        z: 3 + stagger
        layer.enabled: !root.motion.reduced && root.transition.running
        layer.smooth: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 24
            blur: Number(widgetItem.stateTransform.activity || 0) * 0.10
            // Keep the transition layer color-neutral; 0.0 means no change.
            saturation: 0.0
        }

        HoverHandler { id: widgetHover; enabled: root.interactionEnabled }

        Behavior on hoverLift {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on configuredX {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredY {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredScale {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredRotation {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredOpacity {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredWidth {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredHeight {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }

        Loader {
            anchors.fill: parent
            active: widgetItem.visible
            property real causticsX: widgetItem.configuredX
            property real causticsY: widgetItem.configuredY
            property real causticsScale: widgetItem.configuredScale
            property real causticsRotation: widgetItem.configuredRotation
            property var itemStyle: widgetItem.currentStyle
            property string itemVariant: widgetItem.currentVariant
            sourceComponent: root.componentForKind(widgetItem.kind)
        }

        Item {
            id: detailsButton
            objectName: "widgetDetailsButton." + widgetItem.kind
            anchors.right: parent.right; anchors.rightMargin: 8
            y: widgetItem.kind === "weather" ? parent.height - height - 7 : 7
            width: 32; height: 32
            visible: widgetItem.hasDetails && root.detailsEnabled
            enabled: visible
            activeFocusOnTab: enabled
            Accessible.role: Accessible.Button
            Accessible.name: (widgetItem.detailsSelected ? "Fechar detalhes · " : "Abrir detalhes · ")
                + (({clock: "Relógio", weather: "Clima", system: "Sistema", battery: "Bateria"})[widgetItem.kind] || "")
            Accessible.onPressAction: root.toggleDetails(widgetItem)
            Keys.onSpacePressed: root.toggleDetails(widgetItem)
            Keys.onReturnPressed: root.toggleDetails(widgetItem)
            Keys.onEscapePressed: root.detailsOpen = false
            Components.VeloraMaterialIcon {
                anchors.centerIn: parent; width: 18; height: 18
                iconName: "expand_more"
                iconColor: root.theme.moduleInk
                opacity: widgetItem.detailsSelected || detailsButton.activeFocus ? .95 : .5
                rotation: widgetItem.detailsSelected ? 180 : 0
                Behavior on rotation {
                    NumberAnimation { duration: root.contentMotionDuration; easing.type: Easing.OutCubic }
                }
            }
        }
        MouseArea {
            // The system panel's volume control keeps its own click area.
            anchors.fill: widgetItem.kind === "system" && widgetItem.currentVariant !== "metrics"
                && widgetItem.currentVariant !== "minimal" ? detailsButton : parent
            enabled: detailsButton.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleDetails(widgetItem)
        }
    }

    function componentForKind(kind) {
        if (kind === "clock") return clockComponent
        if (kind === "weather") return weatherComponent
        if (kind === "media") return mediaComponent
        if (kind === "gallery") return galleryComponent
        if (kind === "system") return systemComponent
        if (kind === "battery") return batteryComponent
        return null
    }

    Component {
        id: clockComponent
        ClockCard {
            anchors.fill: parent
            theme: root.theme
            clock: root.clock
            motionDuration: root.contentMotionDuration
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }



    Component {
        id: weatherComponent
        WeatherCard {
            anchors.fill: parent
            theme: root.theme
            motion: root.motion
            motionDuration: root.contentMotionDuration
            clock: root.clock
            weather: root.weather
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    Component {
        id: mediaComponent
        MediaCard {
            anchors.fill: parent
            media: root.media
            theme: root.theme
            motion: root.motion
            motionDuration: root.contentMotionDuration
            fallbackArt: root.config.avatarPath
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    Component {
        id: galleryComponent
        GalleryPanel {
            anchors.fill: parent
            config: root.config
            theme: root.theme
            motion: root.motion
            profileTransitioning: root.editor.layoutTransitioning
            profileTransitionDuration: root.layoutMorphDuration
            interactionsEnabled: root.interactionEnabled
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
        }
    }

    Component {
        id: systemComponent
        SystemPanel {
            anchors.fill: parent
            status: root.status
            theme: root.theme
            motion: root.motion
            motionDuration: root.contentMotionDuration
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    Component {
        id: batteryComponent
        BatteryCard {
            anchors.fill: parent
            status: root.status
            motionDuration: root.contentMotionDuration
            theme: root.theme
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
        }
    }

    // Desktop composition stays mounted while editing. The independent new
    // lockscreen does not consume these layers or their legacy lock transforms.
    Item {
        id: desktopScene
        x: root.parallaxX + root.designOriginX * root.parallaxScale
        y: root.parallaxY + root.designOriginY * root.parallaxScale
        width: 1600
        height: 900
        scale: root.designScale * root.parallaxScale
        transformOrigin: Item.TopLeft
        opacity: 1 - root.transition.progress
        visible: opacity > 0.001
        z: 2

        Repeater {
            id: desktopLayerRepeater
            model: root.config.sceneLayers.filter(layer => layer.type !== "calendar")

            SceneLayerItem {
                required property var modelData
                layerData: modelData
                config: root.config
                theme: root.theme
                motion: root.motion
                clock: root.clock
                calendarService: root.calendarService
                media: root.media
                weather: root.weather
                presented: !root.lockPresented
                space: "desktop"
                nativeOptics: true
                surfaceBounds: root.sceneBounds
                transientTransform: root.editor.editSpace === "desktop"
                    ? root.editor.effectiveTransform(modelData.id,
                        modelData.desktop || ({})) : null
                profileTransitioning: root.editor.layoutTransitioning
                profileTransitionDuration: root.layoutMorphDuration
                suppressed: !root.config.desktopWidgetsEnabled || !Boolean(modelData.desktopEnabled)
            }
        }
    }

    SharedWidget { id: sharedClock; kind: "clock" }
    SharedWidget { id: sharedWeather; kind: "weather" }
    SharedWidget { id: sharedMedia; kind: "media" }
    SharedWidget { id: sharedGallery; kind: "gallery" }
    SharedWidget { id: sharedSystem; kind: "system" }
    SharedWidget { id: sharedBattery; kind: "battery" }

    Loader {
        id: detailPanel
        z: 30
        objectName: "widgetDetailsPanel"
        property real reveal: root.detailsOpen ? 1 : 0
        readonly property real inset: 12
        readonly property real leftEdge: root.config.topbarEnabled && !root.barOnRight ? 64 + inset : inset
        readonly property real rightEdge: root.width - inset - (root.config.topbarEnabled && root.barOnRight ? 64 : 0)
        readonly property real topEdge: root.config.topbarEnabled ? 40 + inset : inset
        readonly property rect anchorBox: {
            const anchor = root.expandedWidget
            if (!anchor || !Number.isFinite(anchor.x + anchor.y + anchor.scale + anchor.rotation))
                return Qt.rect(0, 0, 0, 0)
            return anchor.mapToItem(root, Qt.rect(0, 0, anchor.width, anchor.height))
        }
        readonly property bool nearBottom: anchorBox.y + anchorBox.height / 2 > root.height * .60
        readonly property real anchorRight: anchorBox.x + anchorBox.width
        readonly property real anchorBottom: anchorBox.y + anchorBox.height
        readonly property bool openBeside: nearBottom && anchorRight + 8 + width <= rightEdge
        readonly property real anchorX: openBeside ? anchorRight + 8
            : anchorBox.x > root.width / 2 ? anchorRight - width : anchorBox.x
        readonly property real anchorY: openBeside ? anchorBottom - height
            : nearBottom ? anchorBox.y - height - 8 : anchorBottom + 8
        width: Math.max(0, Math.min(306, rightEdge - leftEdge))
        height: item ? item.implicitHeight : 0
        x: Math.max(leftEdge, Math.min(rightEdge - width, anchorX))
        y: Math.max(topEdge, Math.min(root.height - inset - height, anchorY)) + 6 * (1 - reveal)
        opacity: reveal
        visible: reveal > 0
        active: root.detailsOpen || visible
        enabled: root.detailsOpen && root.detailsEnabled
        Behavior on reveal {
            NumberAnimation { duration: Math.round(root.contentMotionDuration * .65); easing.type: Easing.OutCubic }
        }
        sourceComponent: WidgetDetails {
            kind: root.expandedWidget ? root.expandedWidget.kind : ""
            theme: root.theme
            clock: root.clock
            weather: root.weather
            status: root.status
            onCloseRequested: root.detailsOpen = false
        }
        Keys.onEscapePressed: root.detailsOpen = false
    }
}
