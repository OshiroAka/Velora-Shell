pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../../core" as Core
import "../../core/WallpaperPickerGeometry.js" as Geometry
import "../../core/WallpaperList.js" as Library

// Content only. TopBarHost draws this body as part of its one native material.
FocusScope {
    id: root
    property bool open: false
    property var entries: []
    property string activeKey: ""
    property string errorMessage: ""
    property bool applying: false
    property bool loading: false
    property var theme: null
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion }
    property bool reducedMotion: motion.reduced
    property real barHeight: 40
    property real leftInset: 72
    property real rightInset: 8
    property bool mounted: false
    property real reveal: 0
    property real contentReveal: 0
    property int selectedIndex: -1
    property var renderedEntries: []
    property double recentNow: Date.now()/1000
    readonly property bool hasRecentEntries: entries.some(entry=>Number(entry.addedAt || 0)>recentNow-1800)
    readonly property var metrics: Geometry.layout(width, height, barHeight,
        leftInset, rightInset, Math.max(16,entries.length))
    readonly property real bodyWidth: Math.min(metrics.width, 96 + (metrics.width - 96) * reveal)
    readonly property rect panelRect: Qt.rect(metrics.x + (metrics.width - bodyWidth) / 2,
        barHeight, bodyWidth, metrics.height * reveal)
    readonly property real anchorX: panelRect.x + panelRect.width / 2
    readonly property real neckHalfWidth: 0
    readonly property real cornerRadius: 18
    readonly property real joinRadius: Math.max(0.01, metrics.shoulder * reveal)
    readonly property bool interactive: open && reveal > .98 && contentReveal > .9
    readonly property bool animating: opening.running || closing.running || entering.running || contentDelay.running
    readonly property int pictureFadeDuration: reducedMotion ? 0 : Math.round(1100 * motion.pace)
    readonly property int pictureExitDuration: reducedMotion ? 0 : Math.round(260 * motion.pace)
    signal closeRequested()
    signal applyRequested(var entry)
    signal refreshRequested()
    visible: mounted
    ListModel { id: thumbnails }
    Timer {
        interval: 30000; repeat: true; running: root.mounted && root.hasRecentEntries
        onTriggered: root.recentNow=Date.now()/1000
    }

    function key(entry) {
        return Library.key(entry)
    }
    function reconcileEntries() {
        if (!mounted) return
        recentNow=Date.now()/1000
        const selected=key(renderedEntries[selectedIndex])
        const row=Math.max(0,Math.floor(grid.contentY/Math.max(1,grid.cellHeight)))
        const anchor=key(renderedEntries[row*metrics.columns])
        const offset=grid.contentY-row*grid.cellHeight
        Library.reconcile(thumbnails,renderedEntries,entries,Date.now())
        renderedEntries=entries.slice()
        if (!selected) {
            selectedIndex=entries.findIndex(entry=>key(entry)===activeKey)
            if (selectedIndex<0 && entries.length) selectedIndex=0
        } else {
            selectedIndex=entries.findIndex(entry=>key(entry)===selected)
            if (selectedIndex<0) selectedIndex=entries.length ? 0 : -1
        }
        grid.forceLayout()
        if (anchor) {
            const index=entries.findIndex(entry=>key(entry)===anchor)
            if (index>=0) grid.contentY=Math.max(0,Math.min(Math.floor(index/metrics.columns)*grid.cellHeight+offset,
                grid.contentHeight-grid.height))
        }
    }
    function diagnostics() {
        return { mode: "grid", open: open, mounted: mounted, reveal: reveal,
            contentReveal: contentReveal, animating: animating, entries: entries.length,
            columns: metrics.columns, selectedIndex: selectedIndex,
            panel: { x: panelRect.x, y: panelRect.y, width: panelRect.width, height: panelRect.height },
            shoulder: joinRadius, applying: applying }
    }
    function selectActive() {
        const found = entries.findIndex(entry => key(entry) === activeKey)
        selectedIndex = found >= 0 ? found : (entries.length ? 0 : -1)
        Qt.callLater(function() {
            if (root.selectedIndex >= 0) grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
        })
    }
    function apply(index) {
        if (!interactive || applying || index < 0 || index >= entries.length) return
        selectedIndex = index
        applyRequested(entries[index])
    }
    function navigate(direction) {
        selectedIndex = Geometry.step(selectedIndex, direction, metrics.columns, entries.length)
        if (selectedIndex >= 0) grid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }
    function synchronize() {
        opening.stop(); closing.stop(); entering.stop(); contentDelay.stop()
        if (reducedMotion) {
            reveal = open ? 1 : 0
            contentReveal = reveal
            mounted = open
        } else if (open) {
            mounted = true
            opening.start()
            contentDelay.start()
        } else if (mounted) closing.start()
        if (open) { selectActive(); forceActiveFocus() }
    }
    onOpenChanged: synchronize()
    onReducedMotionChanged: synchronize()
    onEntriesChanged: reconcileEntries()
    onMountedChanged: {
        if (mounted) reconcileEntries()
        else { thumbnails.clear();renderedEntries=[] }
    }
    onActiveKeyChanged: if (open) selectActive()
    Component.onCompleted: if (open) synchronize()
    Keys.onEscapePressed: closeRequested()
    Keys.onLeftPressed: navigate("left")
    Keys.onRightPressed: navigate("right")
    Keys.onUpPressed: navigate("up")
    Keys.onDownPressed: navigate("down")
    Keys.onReturnPressed: apply(selectedIndex)
    Keys.onEnterPressed: apply(selectedIndex)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) {
            selectedIndex = entries.length ? 0 : -1
            grid.positionViewAtBeginning()
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            selectedIndex = entries.length - 1
            grid.positionViewAtEnd()
            event.accepted = true
        } else if (event.key === Qt.Key_F5) { refreshRequested(); event.accepted = true }
    }
    NumberAnimation {
        id: opening; target: root; property: "reveal"; to: 1
        duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry
    }
    Timer {
        id: contentDelay; interval: root.motion.contentDelay
        onTriggered: if (root.open) entering.start()
    }
    NumberAnimation {
        id: entering; target: root; property: "contentReveal"; to: 1
        duration: root.pictureFadeDuration; easing.type: Easing.InOutSine
    }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.pictureExitDuration; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.motion.closeDuration; easing.type: root.motion.easeHandoff }
        ScriptAction { script: if (!root.open) root.mounted = false }
    }

    Item {
        // Keep the transparent area beside the body available to outside-close.
        x: root.panelRect.x
        y: root.barHeight
        width: root.panelRect.width
        height: root.panelRect.height + 2
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
    }
    Item {
        id: contentClip
        x: root.panelRect.x + root.metrics.padding - 8
        y: root.barHeight + root.metrics.top - 8
        width: Math.max(0, root.panelRect.width - root.metrics.padding * 2 + 16)
        height: Math.max(0, root.panelRect.height - root.metrics.top - root.metrics.padding + 16)
        clip: true
        opacity: root.reducedMotion ? root.contentReveal : 1
        enabled: root.interactive
        GridView {
            id: grid
            objectName: "primaryWallpaperGrid"
            x: root.metrics.x+root.metrics.padding-contentClip.x
            y: 8
            // Cells include their trailing gap; keep the fourth column inside
            // the clipped viewport instead of silently wrapping it to row two.
            width: root.metrics.width-root.metrics.padding*2+root.metrics.gap
            height: root.metrics.height-root.metrics.top-root.metrics.padding-(root.errorMessage ? 28 : 0)
            clip: false
            model: thumbnails
            cellWidth: root.metrics.cellWidth
            cellHeight: root.metrics.tileHeight + root.metrics.gap
            cacheBuffer: cellHeight
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 1800
            maximumFlickVelocity: 1400
            // One mask for the visible grid, instead of one timer per picture.
            // Release the extra render target once the fade has completed.
            layer.enabled: root.mounted && !root.reducedMotion && root.contentReveal < .9999
            layer.effect: ShaderEffect {
                property var source
                property real progress: root.contentReveal
                property vector2d viewSize: Qt.vector2d(grid.width, grid.height)
                fragmentShader: Qt.resolvedUrl("../../shaders/wallpaper-grid-reveal.frag.qsb")
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3 }
            delegate: Item {
                id: tile
                required property int index
                required property var entryData
                required property double arrivedAt
                readonly property var modelData: entryData
                objectName: "primaryWallpaperTile" + index
                width: grid.cellWidth
                height: grid.cellHeight
                readonly property bool current: root.key(modelData) === root.activeKey
                readonly property bool selected: index === root.selectedIndex
                readonly property bool recent: Number(modelData.addedAt || 0)>0
                    && Number(modelData.addedAt)>root.recentNow-1800
                property real introduction: 1
                Component.onCompleted: {
                    if (!root.reducedMotion && root.contentReveal>.99 && Date.now()-arrivedAt<1000) {
                        introduction=0;arrival.start()
                    }
                }
                NumberAnimation { id: arrival; target: tile; property: "introduction"; to: 1
                    duration: 240; easing.type: Easing.OutCubic }
                opacity: introduction
                Rectangle {
                    anchors.fill: card; radius: card.radius; color: "transparent"
                    border.width: 1.5; border.color: root.theme ? root.theme.accent : "#a9c4ff"
                    visible: tile.recent
                    opacity: .85
                    layer.enabled: visible && GraphicsInfo.api !== GraphicsInfo.Software
                    layer.effect: MultiEffect {
                        shadowEnabled: true; shadowColor: root.theme ? root.theme.accent : "#a9c4ff"
                        shadowOpacity: .7; shadowBlur: .7; blurMax: 16
                        shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                        autoPaddingEnabled: true
                    }
                }
                Rectangle {
                    id: card
                    width: Math.max(1, tile.width - root.metrics.gap)
                    height: root.metrics.tileHeight
                    radius: 16
                    color: root.theme ? root.theme.surfaceSoft : "#202024"
                    scale: pointer.pressed ? .975 : pointer.containsMouse ? 1.015 : 1
                    Behavior on scale { NumberAnimation { duration: root.motion.surfaceHover; easing.type: Easing.OutCubic } }
                    Image {
                        id: preview
                        anchors.fill: parent
                        // The scanner supplies still thumbnails for videos/GIFs.
                        source: String(tile.modelData.preview || (tile.modelData.kind === "static" ? tile.modelData.path : ""))
                        asynchronous: true
                        cache: true
                        retainWhileLoading: true
                        sourceSize.width: 440
                        sourceSize.height: 248
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: roundedMask; autoPaddingEnabled: false }
                    }
                    Rectangle { id: roundedMask; width: card.width; height: card.height; radius: card.radius; visible: false; layer.enabled: true }
                    Rectangle {
                        anchors.fill: parent
                        radius: card.radius
                        color: "transparent"
                        border.width: tile.current || tile.selected ? 1.5 : 1
                        border.color: tile.current || tile.selected ? "#e9e9ee"
                            : pointer.containsMouse ? "#70ffffff" : "#24ffffff"
                        Behavior on border.color { ColorAnimation { duration: root.motion.surfaceHover } }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: preview.status === Image.Error
                        text: "Prévia indisponível"
                        color: root.theme ? root.theme.textSecondary : "#bdbdc5"
                        font.pixelSize: 11
                    }
                    Accessible.role: Accessible.Button
                    Accessible.name: String(tile.modelData.title || "Wallpaper")
                    Accessible.description: tile.current ? "Wallpaper atual" : "Aplicar wallpaper"
                    Accessible.onPressAction: root.apply(tile.index)
                    MouseArea {
                        id: pointer
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.interactive && !root.applying
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(tile.index)
                    }
                }
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: !root.entries.length
            opacity: root.contentReveal
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.loading ? "Carregando wallpapers…" : "Nenhum wallpaper encontrado"
                color: root.theme ? root.theme.textSecondary : "#bdbdc5"
                font.family: root.theme ? root.theme.bodyFont : "Sans Serif"
                font.pixelSize: 13
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.loading
                text: "Atualizar"
                onClicked: root.refreshRequested()
            }
        }
        Text {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            text: root.errorMessage
            visible: text.length > 0
            opacity: root.contentReveal
            elide: Text.ElideRight
            color: root.theme ? root.theme.danger : "#ff9292"
            font.pixelSize: 11
        }
    }
}
