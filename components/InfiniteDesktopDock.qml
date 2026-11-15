pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../core/InfiniteDockGeometry.js" as Geometry

Item {
    id: root
    required property var config
    required property var theme
    required property var screen
    required property var shell
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
    }
    // The window mask contains only interactive content, leaving the canvas
    // behind clients and empty regions available to the desktop pan gesture.
    property alias dockInput: appsViewport
    Flickable {
        id: workspacesViewport
        objectName: "infiniteDeskWorkspaces"
        x: 0; y: root.height - height
        width: 164 * root.unit
        height: 164 * root.unit
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
                width: 28 * root.unit; height: width
                opacity: Math.max(0, Math.min(1, (positionIndex + .75) / .75, (4.75 - positionIndex) / .75))
                visible: workspaceId > 0 && opacity > .001
                objectName: "infiniteDeskWorkspace" + workspaceId
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Área de trabalho " + workspaceId
                Accessible.onPressAction: root.switchWorkspace(workspaceId)
                Keys.onReturnPressed: root.switchWorkspace(workspaceId)
                Keys.onSpacePressed: root.switchWorkspace(workspaceId)
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: workspace.workspaceId === root.activeWorkspace ? root.theme.accent
                        : root.theme.withAlpha(root.theme.textPrimary, pointer.hovered || workspace.activeFocus ? .12 : 0)
                    Behavior on color { ColorAnimation { duration: root.config.reducedMotion ? 0 : 180 } }
                }
                Text {
                    anchors.centerIn: parent
                    text: workspace.workspaceId
                    color: root.theme.textPrimary
                    rotation: Math.min(50, workspace.position.angle)
                    font.family: root.theme.bodyFont; font.pixelSize: 12 * root.unit; font.weight: Font.Medium
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
                    Image {
                        anchors.centerIn: parent
                        width: 28 * root.unit; height: width
                        source: pinned.desktopEntry ? Quickshell.iconPath(pinned.desktopEntry.icon, "application-x-executable") : ""
                        sourceSize: Qt.size(64, 64)
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
