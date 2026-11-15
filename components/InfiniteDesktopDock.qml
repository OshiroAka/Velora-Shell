pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../core/InfiniteDockGeometry.js" as Geometry
import "../features/topbar" as TopBar

Item {
    id: root
    required property var config
    required property var theme
    required property var screen
    required property var shell
    property var edgePanel: null
    property var controlStatus: null
    property var controlTimer: null
    property var controlsParent: null
    property var visualizer: null
    property bool waveformEnabled: true
    property alias waveform: dockWaveform
    signal controlActivated(string type, var item)
    property alias controlsInput: controlsLoader
    readonly property var controls: controlsLoader.item
    property real progress: 0
    property real reveal: 0
    property bool nativeMaterial: false
    property color surface: theme.barSurface
    readonly property real unit: Geometry.unit(width, height)
    readonly property real dockWidth: Geometry.dockWidth(width, unit, entries.length)
    readonly property real dockHeight: 54 * unit
    readonly property var monitor: Hyprland.monitorFor(screen)
    property int activeWorkspace: monitor && monitor.activeWorkspace ? Math.max(1, monitor.activeWorkspace.id) : 1
    property real displayStart: 1
    property bool ready: false
    function syncRoulette() {
        if (!ready) { displayStart = activeWorkspace; return }
        roulette.stop()
        if (config.reducedMotion || !visible) displayStart = activeWorkspace
        else { roulette.to = activeWorkspace; roulette.start() }
    }
    NumberAnimation { id: roulette; target: root; property: "displayStart"; duration: 300; easing.type: Easing.OutCubic }
    Component.onCompleted: { displayStart = activeWorkspace; ready = true }
    onVisibleChanged: syncRoulette()
    Connections { target: root.config; function onReducedMotionChanged() { root.syncRoulette() } }
    readonly property var entries: config.infiniteDeskPinnedItems
    readonly property var applications: DesktopEntries.applications.values
    property int pendingWorkspace: 0
    visible: progress > .001

    function app(identifier) { return applications.find(entry => entry.id === identifier) || null }
    function workspaceItem(index) {
        const item = workspaceRepeater.itemAt(index)
        return item && item.visible && item.opacity > .2 ? item : null
    }
    function title(identifier) {
        if (identifier === "shell:settings") return "Configurações"
        if (identifier === "shell:search") return "Aplicativos"
        const entry = app(identifier)
        return entry ? entry.name : identifier
    }
    function activate(identifier) {
        if (identifier === "shell:settings") shell.openUnifiedSettings()
        else if (identifier === "shell:search") shell.toggleTopSearch()
        else { const entry = app(identifier); if (entry) entry.execute() }
    }
    function switchWorkspace(identifier) {
        if (identifier === activeWorkspace || identifier === pendingWorkspace) return
        pendingWorkspace = identifier
        acknowledgement.restart()
        Hyprland.dispatch("workspace " + identifier)
    }
    onActiveWorkspaceChanged: {
        if (activeWorkspace === pendingWorkspace) { pendingWorkspace = 0; acknowledgement.stop() }
        syncRoulette()
    }
    Timer { id: acknowledgement; interval: 1200; onTriggered: root.pendingWorkspace = 0 }

    Canvas {
        id: surfaceCanvas
        anchors.fill: parent
        visible: !root.nativeMaterial && root.config.barBackgroundEnabled
        opacity: Math.max(0, Math.min(1, (root.progress - .65) / .35))
        antialiasing: true
        onPaint: {
            const c = getContext("2d")
            c.clearRect(0, 0, width, height)
            Geometry.path(c, width, height, root.entries.length)
            if (root.edgePanel && root.edgePanel.mounted && root.edgePanel.bodyWidth > .01)
                root.appendEdgePanel(c)
            c.fillStyle = root.surface
            c.fill()
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        Connections {
            target: root
            function onSurfaceChanged() { surfaceCanvas.requestPaint() }
            function onDockWidthChanged() { surfaceCanvas.requestPaint() }
        }
        Connections {
            target: root.edgePanel
            ignoreUnknownSignals: true
            function onShapeChanged() { if (surfaceCanvas.visible) surfaceCanvas.requestPaint() }
            function onContourSamplesChanged() { if (surfaceCanvas.visible) surfaceCanvas.requestPaint() }
        }
    }
    function appendEdgePanel(c) {
        const panel = edgePanel, edge = width - 4*unit
        const reach = panel.bodyWidth, by = panel.bodyY, bh = panel.bodyHeight
        const join = Math.min(24, reach*.5), nose = edge - reach
        c.moveTo(width, by + bh + join)
        c.lineTo(edge, by + bh + join)
        c.bezierCurveTo(edge, by + bh - join, nose, by + bh + join, nose, by + bh - join)
        if (panel.contour > .01) {
            for (let index = 160; index >= 0; index--) {
                const t = index / 160
                c.lineTo(nose + panel.contourOffset(t), by + bh*t)
            }
        }
        c.lineTo(nose, by + join)
        c.bezierCurveTo(nose, by - join, edge, by + join, edge, by - join)
        c.lineTo(width, by - join)
        c.closePath()
        if (panel.contour <= .01 && panel.extension && panel.extension.width > .01) {
            const x = nose - panel.extension.width, y = panel.extension.y
            const w = panel.extension.width + Math.min(12, reach), h = panel.extension.height
            const r = Math.min(10, w/2, h/2)
            // One fill unions this rounded extension with the menu. Tracing
            // it through the menu shoulder crossed the contour near Lyrics.
            c.moveTo(x+r,y); c.lineTo(x+w-r,y)
            c.arcTo(x+w,y,x+w,y+r,r); c.lineTo(x+w,y+h-r)
            c.arcTo(x+w,y+h,x+w-r,y+h,r); c.lineTo(x+r,y+h)
            c.arcTo(x,y+h,x,y+h-r,r); c.lineTo(x,y+r)
            c.arcTo(x,y,x+r,y,r); c.closePath()
        }
    }
    // The window mask contains only interactive content, leaving the canvas
    // behind clients and empty regions available to the desktop pan gesture.
    property alias dockInput: appsViewport
    InfiniteDockWaveform {
        id: dockWaveform
        objectName: "infiniteDeskDockWaveform"
        x: (root.width-width)/2
        y: root.height-root.dockHeight-height
        width: root.dockWidth
        height: 64*root.unit
        unit: root.unit
        analyzer: root.visualizer
        ink: root.surface
        reducedMotion: root.config.reducedMotion
        visible: root.visible && root.waveformEnabled && root.entries.length > 0 && root.reveal > .99
        opacity: root.reveal
        z: 3
    }
    Loader {
        id: controlsLoader
        parent: root.controlsParent || root
        z: 13
        active: !!root.controlStatus && !!root.controlTimer
        visible: active && root.reveal > .001
        x: root.width - width; y: root.height - height
        width: 128 * root.unit; height: width
        opacity: root.reveal
        sourceComponent: TopBar.InfiniteDesktopControls {
            config: root.config; theme: root.theme
            status: root.controlStatus; timerService: root.controlTimer
            monitorName: root.screen.name
            unit: root.unit
            interactive: root.reveal > .99
            onActivated: (type, item) => root.controlActivated(type, item)
        }
    }
    Flickable {
        id: workspacesViewport
        objectName: "infiniteDeskWorkspaces"
        x: 0; y: root.height - height
        width: 128 * root.unit
        height: 128 * root.unit
        contentWidth: width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height && root.reveal > .99
        opacity: root.reveal
        enabled: root.reveal > .99
        Repeater {
            id: workspaceRepeater
            model: 7
            Item {
                id: workspace
                required property int index
                readonly property int workspaceId: Math.floor(root.displayStart) + index - 1
                readonly property real positionIndex: index - 1 - (root.displayStart - Math.floor(root.displayStart))
                readonly property var position: Geometry.workspacePosition(positionIndex, 5, root.unit)
                x: position.x - width / 2
                y: workspacesViewport.contentHeight + position.y - height / 2
                width: 24 * root.unit; height: width
                opacity: Math.max(0, Math.min(1, (positionIndex + .75) / .75, (4.75 - positionIndex) / .75))
                visible: workspaceId > 0 && opacity > .001
                objectName: "infiniteDeskWorkspace" + workspaceId
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Área de trabalho " + workspaceId
                Accessible.onPressAction: root.switchWorkspace(workspaceId)
                Keys.onReturnPressed: root.switchWorkspace(workspaceId)
                Keys.onSpacePressed: root.switchWorkspace(workspaceId)
                Text {
                    anchors.centerIn: parent
                    text: workspace.workspaceId
                    color: workspace.workspaceId === root.activeWorkspace ? root.theme.accent : root.theme.textPrimary
                    rotation: Math.min(50, workspace.position.angle)
                    font.family: root.theme.bodyFont; font.pixelSize: 12 * root.unit; font.weight: workspace.workspaceId === root.activeWorkspace ? Font.DemiBold : Font.Medium
                }
                HoverHandler { id: pointer; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.switchWorkspace(workspace.workspaceId) }
            }
        }
        WheelHandler {
            onWheel: event => {
                root.switchWorkspace(Math.max(1, root.activeWorkspace + (event.angleDelta.y < 0 ? 1 : -1)))
                event.accepted = true
            }
        }
    }
    Flickable {
        id: appsViewport
        z: 4
        objectName: "infiniteDeskPinnedDock"
        x: (root.width - width) / 2; y: root.height - root.dockHeight
        width: root.dockWidth; height: root.dockHeight
        visible: root.entries.length > 0
        contentWidth: Math.max(width, appsRow.width + 24 * root.unit)
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        interactive: contentWidth > width && root.reveal > .99
        enabled: root.reveal > .99
        opacity: root.reveal
        Row {
            id: appsRow
            x: Math.max(12 * root.unit, (appsViewport.width - width) / 2)
            height: appsViewport.height
            spacing: 6 * root.unit
            Repeater {
                model: root.entries
                Item {
                    id: pinned
                    required property string modelData
                    readonly property var desktopEntry: root.app(modelData)
                    width: 44 * root.unit; height: appsViewport.height
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: root.title(modelData)
                    Accessible.onPressAction: root.activate(modelData)
                    Keys.onReturnPressed: root.activate(modelData)
                    Keys.onSpacePressed: root.activate(modelData)
                    VeloraIconMotion { id: iconMotion; highlighted: hover.hovered || pinned.activeFocus; reducedMotion: root.config.reducedMotion }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width; height: width; radius: 12 * root.unit
                        color: root.theme.withAlpha(root.theme.textPrimary, .08 * iconMotion.emphasis)
                    }
                    VeloraDockAppIcon {
                        objectName: "infiniteDeskAppIcon-" + pinned.modelData
                        anchors.centerIn: parent
                        width: 28 * root.unit; height: width
                        source: pinned.desktopEntry ? Quickshell.iconPath(pinned.desktopEntry.icon, "application-x-executable") : ""
                        iconName: pinned.desktopEntry ? pinned.desktopEntry.icon : ""
                        identifier: pinned.modelData
                        outline: root.config.infiniteDeskOutlineIcons
                        ink: root.theme.textPrimary
                        visible: !!pinned.desktopEntry
                        scale: iconMotion.zoom
                        transform: Translate { y: iconMotion.lift }
                        smooth: true
                    }
                    VeloraMaterialIcon {
                        anchors.centerIn: parent
                        width: 26 * root.unit; height: width
                        visible: !pinned.desktopEntry
                        iconName: pinned.modelData === "shell:settings" ? "settings" : pinned.modelData === "shell:search" ? "search" : "apps"
                        iconColor: root.theme.textPrimary
                        scale: iconMotion.zoom
                        transform: Translate { y: iconMotion.lift }
                    }
                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.activate(pinned.modelData) }
                }
            }
        }
    }
}
