pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import "../../components" as Components
import "BarGeometry.js" as BarGeometry

Item {
    id: root
    required property var config
    required property var theme
    required property var clock
    required property var media
    required property var weather
    required property var status
    required property var actions
    required property var compositor
    required property var editorController
    required property var controller
    required property var host
    required property var system
    required property var timerService
    required property real wavePhase
    property var shell: null
    property real desktopMorphProgress: 0
    property real desktopTargetReveal: 0
    property int opticsGeneration: 0
    property alias barSurfaceItem: background
    property real leftInset: 0
    property real rightInset: 20
    signal geometryChanged()
    function sectionWidth(section) {
        return config.topbarItemsForSection(section, false).reduce((sum, item) => sum + layoutItemWidth(item.type), 0)
    }
    function layoutItemWidth(type) { return type === "workspaces" ? legacyItemWidth(type) * (1 - desktopMorphProgress) : legacyItemWidth(type) }
    readonly property var sectionBounds: BarGeometry.sections(width,
        sectionWidth("left"), sectionWidth("center"), toolRow.width, leftInset + leftDesktopTools.width, rightInset + rightDesktopTools.width)
    onSectionBoundsChanged: geometryChanged()
    readonly property var hyprMonitor: Hyprland.monitorFor(host.screen)
    readonly property var workspaceIds: {
        const ids = [1, 2, 3, 4, 5]
        for (const workspace of Hyprland.workspaces.values)
            if (workspace.id > 0 && !ids.includes(workspace.id)) ids.push(workspace.id)
        const active = hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : 0
        if (active > 0 && !ids.includes(active)) ids.push(active)
        return ids.sort((a, b) => a - b)
    }
    readonly property var barTheme: shell ? shell.unifiedTheme : null
    readonly property real unit: barTheme ? Math.max(.67, Math.min(1.17, barTheme.barIconSize / 48)) : 1
    readonly property real iconOpacity: barTheme ? barTheme.barIconOpacity : 1
    readonly property real itemGap: barTheme ? barTheme.barIconSpacing / 4 : 1
    readonly property bool compact: width < 1280
    readonly property real density: width < 760 ? 0.8 : 1
    readonly property bool editing: editorController.shown && editorController.mode === "editing"
        && editorController.editSpace === "desktop"
    readonly property var visibleTools: config.topbarToolsOrder.filter(type =>
        (type !== "thing" || config.topbarOneThingEnabled)
        && (type !== "notes" || config.topbarNotesEnabled))
    function controlBubbleRuns() {
        const runs = []
        for (let index = 0; index < visibleTools.length; index += 1) {
            if (!["battery", "paint", "monitor", "controls"].includes(visibleTools[index])) continue
            const previous = runs.length ? runs[runs.length - 1] : null
            if (previous && previous.last === index - 1) previous.last = index
            else runs.push({first: index, last: index})
        }
        return runs
    }
    readonly property var batteryAnchorItem: toolRepeater.count > 0 && visibleTools.includes("battery")
        ? toolRepeater.itemAt(visibleTools.indexOf("battery")) : null
    readonly property real batteryAnchorX: batteryAnchorItem
        ? rightTools.x + toolRow.x + batteryAnchorItem.x - rightTools.contentX + batteryAnchorItem.width / 2 : 0
    readonly property bool batteryAnchorVisible: !!batteryAnchorItem
        && batteryAnchorX >= rightTools.x && batteryAnchorX <= rightTools.x + rightTools.width
    readonly property var timerAnchorItem: toolRepeater.count > 0
        ? toolRepeater.itemAt(visibleTools.indexOf("timer")) : null
    readonly property real timerAnchorX: timerAnchorItem
        ? rightTools.x + toolRow.x + timerAnchorItem.x - rightTools.contentX + timerAnchorItem.width / 2
        : width / 2
    property string dragType: ""
    property int dragFrom: -1
    property int dragTo: -1
    property real dragOrigin: 0
    property real dragPosition: 0
    property real dragWidth: 0
    property real dragScrollOrigin: 0
    property int toolItemsRevision: 0
    property string layoutDragId: ""
    property real layoutDragOrigin: 0
    property real layoutDragPosition: 0
    property string layoutDropSection: "left"
    property string layoutBeforeId: ""
    readonly property string layoutDragSourceSection: {
        const item = config.topbarLayout.find(item => item.id === layoutDragId)
        return item ? item.section : ""
    }
    onEditingChanged: { cancelDrag(); root.controller.close() }
    function cancelDrag() {
        dragType = ""; dragFrom = -1; dragTo = -1; layoutDragId = ""
    }
    function beginLayoutDrag(identifier, point) {
        cancelDrag()
        layoutDragId = identifier; layoutDragOrigin = point
        updateLayoutDrag(point)
    }
    function updateLayoutDrag(point) {
        layoutDragPosition = point
        const leftCenter = sectionBounds.left.x + sectionBounds.left.width / 2
        const centerCenter = sectionBounds.center.x + sectionBounds.center.width / 2
        layoutDropSection = Math.abs(point - leftCenter) < Math.abs(point - centerCenter) ? "left" : "center"
        const section = layoutDropSection === "left" ? leftSection : centerSection
        layoutBeforeId = ""
        for (let index = 0; index < section.entries.count; index += 1) {
            const item = section.entries.itemAt(index)
            if (item.modelData.id === layoutDragId) continue
            // Ignore the visual translation of the dragged entry when locating
            // the insertion slot; all other entries retain their current pose.
            if (point < section.mapToItem(root, item.x + item.width / 2, 0).x) {
                layoutBeforeId = item.modelData.id
                break
            }
        }
    }
    function finishLayoutDrag() {
        const identifier = layoutDragId, section = layoutDropSection, before = layoutBeforeId
        cancelDrag()
        if (identifier) config.placeTopbarItem(identifier, section, before)
    }
    function layoutDisplacement(identifier, section) {
        if (!layoutDragId || identifier === layoutDragId) return 0
        const original = config.topbarItemsForSection(section, false)
        const dragged = config.topbarLayout.find(item => item.id === layoutDragId)
        if (!dragged) return 0
        const reordered = original.filter(item => item.id !== layoutDragId)
        if (layoutDropSection === section) {
            const index = layoutBeforeId ? reordered.findIndex(item => item.id === layoutBeforeId) : reordered.length
            reordered.splice(Math.max(0, index), 0, dragged)
        }
        function offset(items) {
            let x = 0
            for (const item of items) {
                if (item.id === identifier) break
                x += layoutItemWidth(item.type)
            }
            return x
        }
        return offset(reordered) - offset(original)
    }
    function beginDrag(type, item, point) {
        dragType = type; dragFrom = visibleTools.indexOf(type); dragTo = dragFrom
        dragOrigin = point; dragPosition = point; dragWidth = item.width
        dragScrollOrigin = rightTools.contentX
    }
    function updateDrag(point) {
        dragPosition = point
        let target = 0
        for (let i = 0; i < toolRepeater.count; ++i) {
            const item = toolRepeater.itemAt(i)
            const center = rightTools.x + toolRow.x + item.x - rightTools.contentX + item.width / 2
            if (point > center) target = i + 1
        }
        dragTo = Math.max(0, Math.min(visibleTools.length - 1, target > dragFrom ? target - 1 : target))
    }
    function finishDrag() {
        const type = dragType, target = visibleTools[dragTo]
        cancelDrag()
        if (target && type !== target) config.moveTopbarTool(type, target)
    }
    function displacement(index, type) {
        if (!dragType) return 0
        if (type === dragType) return dragPosition - dragOrigin + rightTools.contentX - dragScrollOrigin
        if (dragFrom < dragTo && index > dragFrom && index <= dragTo) return -dragWidth - toolRow.spacing
        if (dragTo < dragFrom && index >= dragTo && index < dragFrom) return dragWidth + toolRow.spacing
        return 0
    }
    Timer {
        interval: 16; repeat: true
        running: root.dragType.length > 0 && rightTools.contentWidth > rightTools.width
            && ((root.dragPosition < rightTools.x + 28 && rightTools.contentX > 0)
                || (root.dragPosition > rightTools.x + rightTools.width - 28
                    && rightTools.contentX < rightTools.contentWidth - rightTools.width))
        onTriggered: {
            const direction = root.dragPosition < rightTools.x + 28 ? -1 : 1
            rightTools.contentX = Math.max(0, Math.min(rightTools.contentWidth - rightTools.width,
                rightTools.contentX + direction * 8))
            root.updateDrag(root.dragPosition)
        }
    }
    function label(type) {
        return ({timer: "Timer",
            thing: "One Thing", notes: "Notas · arraste para baixo para criar", battery: "Bateria", monitor: "Monitores", paint: "Misturar cores do wallpaper", wifi: "Wi-Fi",
            search: "Busca", controls: "Configurações", weather: "Previsão do tempo", clock: "Data e calendário"})[type] || type
    }
    function legacyItemWidth(type) {
        const widths = { workspaces: 208, context: compact ? 130 : 250,
            clock: compact ? 210 : 330, media: compact ? 100 : 140,
            wifi: 54, volume: 54, battery: 86, settings: 48, avatar: 48,
            search: 48, weather: 124, brand: 90 }
        return (widths[type] || 48) * unit
    }
    function legacyGlyph(type) {
        if (type === "media") return media.playing ? "pause" : "play"
        if (type === "volume") return status.muted ? "volume-muted" : "volume"
        if (type === "battery") return "battery"
        return type === "avatar" ? "person" : type
    }
    function legacyLabel(type) {
        if (type === "clock") return clock.locale().toString(clock.now,
            compact ? "ddd, dd MMM — HH:mm" : "ddd, dd 'de' MMMM — HH:mm").replace(/\./g, "")
        if (type === "media") return media.hasPlayer ? media.title : "Sem mídia"
        if (type === "battery") return status.hasBattery ? status.batteryPercent + "%" : ""
        if (type === "weather") return weather.available
            ? weather.temperature + "°" : "—"
        if (type === "brand") return "Velora"
        return ""
    }
    function activateLegacy(type, item) {
        if (type === "weather") controller.toggle("weather", item, host)
        else if (type === "media") media.hasPlayer ? media.togglePlaying() : actions.openMusic()
        else if (type === "wifi") actions.openNetworkSettings()
        else if (type === "volume") status.toggleMuted()
        else if (type === "clock") editorController.show("desktop")
        else actions.openSettings()
    }

    Item { id: background; anchors.fill: parent }
    Loader {
        id: leftDesktopTools
        active: !!root.shell && root.desktopMorphProgress > .0001
        width: 228 * root.desktopMorphProgress
        height: root.height
        z: 5
        sourceComponent: InfiniteDesktopTools {
            shell: root.shell; theme: root.theme; config: root.config
            controller: root.controller; host: root.host; actions: root.actions; status: root.status
            progress: root.desktopMorphProgress; reveal: root.desktopTargetReveal
        }
    }
    Item {
        id: rightDesktopTools
        width: 0
        height: root.height
    }
    component Section: Row {
        id: section
        required property string sectionName
        property alias entries: sectionRepeater
        height: root.height
        Repeater {
            id: sectionRepeater
            model: root.config.topbarItemsForSection(section.sectionName, false)
            Item {
                id: entry
                required property var modelData
                readonly property string type: modelData.type
                readonly property string panelType: type === "weather" ? "weather" : ""
                readonly property bool panelSelected: panelType.length > 0
                    && root.controller.owner === root.host && root.controller.activeType === panelType
                readonly property bool wallpaperDropHovered: wallpaperDrop.containsDrag
                width: root.layoutItemWidth(type)
                visible: type !== "workspaces" || root.desktopMorphProgress < .999
                opacity: type === "workspaces" ? 1 - root.desktopMorphProgress : 1
                height: root.height
                z: root.layoutDragId === modelData.id ? 10 : 0
                transform: Translate {
                    x: root.layoutDragId === entry.modelData.id
                        ? root.layoutDragPosition - root.layoutDragOrigin
                        : root.layoutDisplacement(entry.modelData.id, section.sectionName)
                    Behavior on x {
                        enabled: root.layoutDragId !== entry.modelData.id
                        NumberAnimation { duration: root.config.reducedMotion ? 0 : 120 }
                    }
                }
                objectName: type === "weather" ? "topbarWeatherTrigger" : "topbarItem-" + modelData.id
                activeFocusOnTab: root.editing || panelType.length > 0
                Accessible.role: root.editing || panelType ? Accessible.Button : Accessible.NoRole
                Accessible.name: root.editing ? root.config.topbarItemLabel(type)
                    : wallpaperDropHovered ? "Adicionar wallpaper à biblioteca" : type === "weather" ? root.label(type) : ""
                Accessible.onPressAction: if (panelType && !root.editing) root.activateLegacy(type, entry)
                Keys.onReturnPressed: if (panelType && !root.editing) root.activateLegacy(type, entry)
                Keys.onSpacePressed: if (panelType && !root.editing) root.activateLegacy(type, entry)
                Keys.onLeftPressed: event => {
                    if (root.editing) root.config.moveTopbarItem(modelData.id, -1)
                    else event.accepted = false
                }
                Keys.onRightPressed: event => {
                    if (root.editing) root.config.moveTopbarItem(modelData.id, 1)
                    else event.accepted = false
                }
                Keys.onEscapePressed: if (root.layoutDragId) root.cancelDrag()
                Component.onCompleted: if (panelType) root.controller.registerItem(panelType, entry, root.host)
                Component.onDestruction: if (panelType) root.controller.unregisterItem(entry)
                Components.VeloraBarItemBubble {
                    tint: root.theme.barBubbleTint || root.theme.accent
                    exactColor: !!root.theme.manualPalette
                    monitorName: root.host.screen.name
                    surfaceTint: root.theme.barSurface
                    solid: root.config.barItemBubblesSolid
                    liquid: root.config.barItemBubblesEnabled && root.config.barItemBubblesLiquid
                    objectName: "barItemBubble"
                    anchors.fill: parent; anchors.margins: 6
                    shown: root.config.barItemBubblesEnabled
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6 * root.unit
                    radius: 16 * root.unit
                    color: root.theme.accentMuted
                    visible: entry.type !== "context" && (entry.panelSelected || entry.activeFocus || entry.wallpaperDropHovered
                        || (pointer.containsMouse && entry.type !== "workspaces"))
                }
                Components.VeloraIconMotion {
                    id: legacyIconMotion
                    highlighted: pointer.containsMouse || entry.activeFocus || entry.panelSelected || entry.wallpaperDropHovered
                    reducedMotion: root.config.reducedMotion
                }
                Row {
                    id: entryVisual
                    opacity: root.iconOpacity
                    anchors.centerIn: parent
                    spacing: 8 * root.unit
                    visible: !["workspaces", "context"].includes(entry.type)
                    Components.VeloraMaterialIcon {
                        scale: legacyIconMotion.zoom
                        transform: Translate { y: legacyIconMotion.lift }
                        opacity: legacyIconMotion.inkOpacity
                        anchors.verticalCenter: parent.verticalCenter
                        width: 23 * root.unit; height: width
                        visible: !["clock", "brand", "weather"].includes(entry.type)
                        iconName: root.legacyGlyph(entry.type)
                        iconColor: root.theme.accentSoft
                    }
                    Item {
                        visible: entry.type === "weather"
                        anchors.verticalCenter: parent.verticalCenter
                        width: 23 * root.unit; height: width
                        scale: legacyIconMotion.zoom
                        transform: Translate { y: legacyIconMotion.lift }
                        opacity: legacyIconMotion.inkOpacity
                        Components.VeloraWeatherIcon {
                            anchors.fill: parent
                            name: root.weather.iconName || "partly"
                            ink: root.theme.textPrimary
                            opacity: entry.wallpaperDropHovered ? 0 : 1
                            Behavior on opacity { NumberAnimation { duration: root.config.reducedMotion ? 0 : 140 } }
                        }
                        Components.VeloraMaterialIcon {
                            objectName: "weatherWallpaperDropIcon"
                            anchors.fill: parent
                            iconName: "image"
                            iconColor: root.theme.accentSoft
                            opacity: entry.wallpaperDropHovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: root.config.reducedMotion ? 0 : 140 } }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: text.length > 0
                        text: root.legacyLabel(entry.type)
                        width: entry.type === "media" ? entry.width - 46 * root.unit : implicitWidth
                        elide: Text.ElideRight
                        color: root.theme.textPrimary
                        font.family: "Poppins"
                        font.pixelSize: (entry.type === "clock" ? 15 : 12) * root.unit
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 27 * root.unit
                    color: root.theme.borderSubtle
                    visible: ["workspaces", "media", "battery"].includes(entry.type)
                }
                Column {
                    x: 14 * root.unit
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 * root.unit
                    visible: entry.type === "context"
                    opacity: root.iconOpacity
                    spacing: -1 * root.unit
                    Text {
                        width: parent.width
                        text: root.editorController.mounted ? "Velora"
                            : String(root.compositor.activeToplevel
                                ? (root.compositor.activeToplevel.appId || "Desktop") : "Desktop")
                        color: root.theme.textMuted
                        font.family: "Poppins"; font.pixelSize: 11 * root.unit
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.editorController.mounted ? "Configurações"
                            : String(root.compositor.activeToplevel
                                ? root.compositor.activeToplevel.title : "Área de trabalho")
                        color: root.theme.textPrimary
                        font.family: "Poppins"; font.pixelSize: 12 * root.unit
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    enabled: entry.type !== "workspaces"
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activateLegacy(entry.type, entry)
                    onEntered: if (entry.type === "weather" && !entry.wallpaperDropHovered && !weatherDropCooldown.running)
                        root.controller.enter("weather", entry, root.host)
                    onExited: if (entry.type === "weather") root.controller.leave(entry)
                    onWheel: function(event) {
                        if (entry.type === "volume") root.status.adjustVolume(event.angleDelta.y > 0 ? 1 : -1)
                    }
                }
                WallpaperDropArea {
                    id: wallpaperDrop
                    objectName: "weatherWallpaperDropArea"
                    anchors.fill: parent
                    enabled: entry.type === "weather" && !root.editing && !!root.shell
                    onDragStarted: {
                        root.controller.leave(entry)
                        root.controller.close()
                    }
                    onFilesDropped: urls => {
                        root.shell.importTopWallpaperUrls(urls)
                        // The pointer is still over weather when a drag ends.
                        // Give the imported wallpaper five seconds before
                        // offering the weather hover menu again.
                        root.controller.blockedItem = entry
                        weatherDropCooldown.restart()
                    }
                }
                Timer {
                    id: weatherDropCooldown
                    objectName: "weatherWallpaperDropCooldown"
                    interval: 5000
                    onTriggered: {
                        if (root.controller.blockedItem === entry) root.controller.blockedItem = null
                        if (pointer.containsMouse && !root.editing && !entry.wallpaperDropHovered)
                            root.controller.enter("weather", entry, root.host)
                    }
                }
                Loader {
                    anchors.centerIn: parent
                    active: entry.type === "workspaces"
                    width: Math.min(176, entry.width - 32); height: 32
                    sourceComponent: WorkspaceSwitcher {
                        opacity: root.iconOpacity
                        theme: root.theme
                        reducedMotion: root.config.reducedMotion
                        workspaceIds: root.workspaceIds
                        activeWorkspaceId: root.hyprMonitor && root.hyprMonitor.activeWorkspace
                            ? root.hyprMonitor.activeWorkspace.id : 0
                        onWorkspaceRequested: workspaceId => Hyprland.dispatch("workspace " + workspaceId)
                    }
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: 3
                    visible: root.editing; radius: 7; color: "transparent"
                    border.width: 1; border.color: root.theme.withAlpha(root.theme.accentSoft,
                        root.layoutDragId === entry.modelData.id ? 1 : .35)
                }
                MouseArea {
                    anchors.fill: parent; enabled: root.editing
                    preventStealing: true; cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: mouse => {
                        entry.forceActiveFocus()
                        root.beginLayoutDrag(entry.modelData.id, mapToItem(root, mouse.x, mouse.y).x)
                    }
                    onPositionChanged: mouse => {
                        if (pressed && root.layoutDragId === entry.modelData.id)
                            root.updateLayoutDrag(mapToItem(root, mouse.x, mouse.y).x)
                    }
                    onReleased: if (root.layoutDragId === entry.modelData.id) root.finishLayoutDrag()
                    onCanceled: root.cancelDrag()
                }
            }
        }
    }
    Flickable {
        x: root.sectionBounds.left.x; width: root.sectionBounds.left.width; height: root.height
        contentWidth: leftSection.width; contentHeight: height
        clip: !root.layoutDragId; z: root.layoutDragId && root.layoutDragSourceSection === "left" ? 10 : 0
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        onContentXChanged: root.geometryChanged()
        Section { id: leftSection; sectionName: "left" }
    }
    Flickable {
        x: root.sectionBounds.center.x; width: root.sectionBounds.center.width; height: root.height
        contentWidth: centerSection.width; contentHeight: height
        clip: !root.layoutDragId; z: root.layoutDragId && root.layoutDragSourceSection === "center" ? 10 : 0
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        onContentXChanged: root.geometryChanged()
        Section { id: centerSection; sectionName: "center" }
    }



    Flickable {
        id: rightTools
        objectName: "topbarRightToolsViewport"
        x: root.sectionBounds.right.x; width: root.sectionBounds.right.width; height: root.height
        contentWidth: toolRow.width; contentHeight: height
        clip: true; boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        onContentXChanged: root.geometryChanged()
        Repeater {
            model: root.config.barItemBubblesEnabled ? root.controlBubbleRuns() : []
            Components.VeloraBarItemBubble {
                tint: root.theme.barBubbleTint || root.theme.accent
                exactColor: !!root.theme.manualPalette
                monitorName: root.host.screen.name
                surfaceTint: root.theme.barSurface
                solid: root.config.barItemBubblesSolid
                liquid: root.config.barItemBubblesEnabled && root.config.barItemBubblesLiquid
                required property var modelData
                objectName: "barGroupBubble-controls"
                readonly property var firstItem: {
                    root.toolItemsRevision
                    return toolRepeater.count > modelData.first ? toolRepeater.itemAt(modelData.first) : null
                }
                readonly property var lastItem: {
                    root.toolItemsRevision
                    return toolRepeater.count > modelData.last ? toolRepeater.itemAt(modelData.last) : null
                }
                x: firstItem ? toolRow.x + firstItem.x + 4 : 0
                y: 6; height: Math.max(0, root.height - 12)
                width: firstItem && lastItem ? lastItem.x + lastItem.width - firstItem.x - 8 : 0
                shown: !!firstItem && !!lastItem && width > 0
            }
        }
    Row {
        id: toolRow
        height: root.height
        spacing: root.itemGap
        Repeater {
            id: toolRepeater
            onItemAdded: root.toolItemsRevision += 1
            onItemRemoved: root.toolItemsRevision += 1
            model: root.visibleTools
            BarItem {
                id: item
                required property string modelData
                required property int index
                readonly property string type: modelData
                readonly property bool panelTool: type !== "controls"
                objectName: "topbarTool-" + type
                readonly property bool timerAlertActive: type === "timer" && root.timerService.finished
                onTimerAlertActiveChanged: {
                    if (timerAlertActive) {
                        root.controller.leave(item)
                        if (root.controller.owner === root.host && root.controller.activeType === "timer")
                            root.controller.close()
                    }
                }
                theme: root.theme
                bubblesEnabled: root.config.barItemBubblesEnabled
                    && !["timer", "thing", "battery", "paint", "monitor", "controls"].includes(type)
                bubbleMonitor: root.host.screen.name
                bubblesSolid: root.config.barItemBubblesSolid
                bubblesLiquid: root.config.barItemBubblesLiquid
                reducedMotion: root.config.reducedMotion
                width: (type === "clock" ? 178 : type === "thing" ? (root.width < 1000 ? 90 : 160)
                    : type === "timer" ? 74 : type === "battery" ? 44 : 36) * root.density
                height: root.height
                label: root.label(type)
                Rectangle {
                    // A trailing divider for message, timer and search; avoid
                    // doubling it when the calendar follows one of them.
                    visible: ["thing", "timer"].includes(item.type)
                        || (item.type === "clock" && item.index > 0
                            && !["thing", "timer"].includes(root.visibleTools[item.index - 1]))
                    x: item.type === "clock" ? 0 : parent.width - 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 16; radius: 0.5
                    color: root.theme.withAlpha(root.theme.textPrimary, 0.32)
                }
                selected: panelTool && root.controller.owner === root.host && root.controller.activeType === type
                dragToCreate: type === "notes" && !root.editing
                onHoveredChanged: {
                    if (hovered && panelTool && !root.editing && !timerAlertActive) root.controller.enter(type, item, root.host)
                    else root.controller.leave(item)
                }
                z: root.dragType === type ? 10 : 0
                transform: Translate {
                    x: root.displacement(item.index, item.type)
                    Behavior on x { enabled: root.dragType !== item.type; NumberAnimation { duration: root.config.reducedMotion ? 0 : 120 } }
                }
                onDraggedDown: {
                    root.system.newNote()
                    if (!selected) root.controller.toggle(type, item, root.host)
                }
                onActivated: if (!root.editing) {
                    if (type === "controls") { root.controller.close(); root.actions.openSettings() }
                    else if (timerAlertActive) root.controller.close()
                    else root.controller.toggle(type, item, root.host)
                }
                onSecondaryActivated: activated()
                Keys.onLeftPressed: event => {
                    if (root.editing) root.config.stepTopbarTool(type, -1)
                    else event.accepted = false
                }
                Keys.onRightPressed: event => {
                    if (root.editing) root.config.stepTopbarTool(type, 1)
                    else event.accepted = false
                }
                Keys.onEscapePressed: if (root.dragType) root.cancelDrag()
                Rectangle {
                    anchors.fill: parent; anchors.margins: 3
                    visible: root.editing
                    radius: 7; color: "transparent"
                    border.width: 1
                    border.color: root.theme.withAlpha(root.theme.accentSoft, root.dragType === item.type ? 1 : 0.35)
                }
                MouseArea {
                    anchors.fill: parent; z: 30
                    enabled: root.editing
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    preventStealing: true
                    onPressed: mouse => {
                        item.forceActiveFocus()
                        root.beginDrag(item.type, item, mapToItem(root, mouse.x, mouse.y).x)
                    }
                    onPositionChanged: mouse => {
                        if (pressed && root.dragType === item.type)
                            root.updateDrag(mapToItem(root, mouse.x, mouse.y).x)
                    }
                    onReleased: if (root.dragType === item.type) root.finishDrag()
                    onCanceled: root.cancelDrag()
                }
                Component.onCompleted: if (panelTool) root.controller.registerItem(type, item, root.host)
                Component.onDestruction: if (panelTool) root.controller.unregisterItem(item)
                Components.VeloraIconMotion {
                    id: iconMotion
                    highlighted: item.hovered || item.activeFocus
                    reducedMotion: root.config.reducedMotion
                }
                BatteryIndicator {
                    scale: iconMotion.zoom * root.unit
                    transform: Translate { y: iconMotion.lift }
                    opacity: root.iconOpacity * iconMotion.inkOpacity
                    anchors.centerIn: parent
                    visible: item.type === "battery"
                    available: root.status.hasBattery; level: root.status.batteryLevel; charging: root.status.batteryCharging
                    color: root.theme.textPrimary; warningColor: root.theme.warning; criticalColor: root.theme.danger
                }
                BarIcon {
                    scale: iconMotion.zoom
                    transform: Translate { y: iconMotion.lift }
                    opacity: root.iconOpacity * iconMotion.inkOpacity
                    anchors.centerIn: parent
                    width: 20 * root.unit
                    height: 22 * root.unit
                    visible: !["timer", "thing", "clock", "battery"].includes(item.type)
                    name: item.type
                    color: root.theme.textPrimary
                    level: root.system.wifiStrength
                    muted: item.type === "wifi" && !root.status.wifiEnabled
                    connected: root.status.wifiConnected
                }
                Components.VeloraBarItemBubble {
                    tint: root.theme.barBubbleTint || root.theme.accent
                    exactColor: !!root.theme.manualPalette
                    monitorName: root.host.screen.name
                    surfaceTint: root.theme.barSurface
                    solid: root.config.barItemBubblesSolid
                    liquid: root.config.barItemBubblesEnabled && root.config.barItemBubblesLiquid
                    id: timerSurface
                    objectName: "barExistingBubble-timer"
                    anchors.centerIn: parent
                    shown: item.type === "timer"
                    opacity: root.theme.manualPalette ? 1 : root.iconOpacity
                    width: parent.width - (root.config.barItemBubblesEnabled ? 14 : 10)
                    height: root.config.barItemBubblesEnabled ? 28 : 25
                    radius: 7
                    color: nativeLiquid ? "transparent" : root.timerService.countdown.running || root.timerService.finished
                        ? root.theme.textPrimary : root.config.barItemBubblesEnabled
                            ? bubbleColor : root.theme.withAlpha(root.theme.textPrimary, 0.07)
                    border.width: 1
                    border.color: root.theme.withAlpha(root.theme.textPrimary, 0.18)
                    Rectangle {
                        visible: !root.config.barItemBubblesEnabled
                        anchors.fill: parent; anchors.margins: 3
                        radius: 4; color: "transparent"
                        border.width: 1; border.color: root.theme.withAlpha(root.theme.textPrimary, 0.09)
                    }
                    Behavior on color { ColorAnimation { duration: 160 } }
                    TimerLabel {
                        anchors.centerIn: parent; text: root.timerService.barText || root.timerService.timerText
                        transitionKey: root.timerService.duration + ":" + root.timerService.engaged
                        color: root.timerService.countdown.running || root.timerService.finished ? root.theme.profileDark : root.theme.textPrimary
                        family: root.theme.bodyFont; pixelSize: 14; tabular: true
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }
                Components.VeloraBarItemBubble {
                    tint: root.theme.barBubbleTint || root.theme.accent
                    exactColor: !!root.theme.manualPalette
                    monitorName: root.host.screen.name
                    surfaceTint: root.theme.barSurface
                    solid: root.config.barItemBubblesSolid
                    liquid: root.config.barItemBubblesEnabled && root.config.barItemBubblesLiquid
                    objectName: "barExistingBubble-message"
                    anchors.centerIn: parent
                    shown: item.type === "thing"
                    width: parent.width - (root.config.barItemBubblesEnabled ? 12 : 16)
                    height: root.config.barItemBubblesEnabled ? 28 : 25
                    radius: 7
                    color: nativeLiquid ? "transparent" : root.config.barItemBubblesEnabled ? bubbleColor : root.theme.withAlpha(root.theme.textPrimary, 0.07)
                    border.width: 1
                    border.color: root.theme.withAlpha(root.theme.textPrimary, 0.18)
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 28
                    visible: item.type === "thing"
                    opacity: root.iconOpacity
                    text: item.type === "thing" ? root.system.oneThing || "What is the one thing?"
                        : root.clock.locale().toString(root.clock.now, "ddd d MMM  HH:mm").replace(/\./g, "")
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: root.theme.textPrimary
                    font.family: root.theme.bodyFont; font.pixelSize: 12
                }
                TimerLabel {
                    anchors.centerIn: parent
                    visible: item.type === "clock"
                    opacity: root.iconOpacity
                    text: root.clock.locale().toString(root.clock.now, "ddd d MMM  HH:mm").replace(/\./g, "")
                    transitionKey: "clock"
                    color: root.theme.textPrimary
                    family: root.theme.bodyFont; pixelSize: 12
                }
            }
        }
    }
    }

}
