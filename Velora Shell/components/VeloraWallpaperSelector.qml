import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: null
    property alias surfaceItem: panelSurface
    property bool externalSurface: false
    property string attachSide: "left"
    readonly property int cornerRadius: 28
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.90, 0.88, 0.92, 0.94)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.78, 0.74, 0.82, 0.70)
    readonly property color pink: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.43, 0.66, 0.92)
    readonly property color lilac: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.48, 0.73, 0.78)
    readonly property color glass: theme ? theme.surfacePopup : Qt.rgba(0.10, 0.09, 0.11, 0.82)
    readonly property color card: theme ? theme.surfaceCard : Qt.rgba(1, 1, 1, 0.62)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.38)
    readonly property string uiFont: "Noto Sans CJK JP"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string applyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string visibilityScript: Quickshell.shellDir + "/scripts/velora-wallpaper-visibility"
    readonly property var filterKeys: ["all", "static", "live", "engine"]
    readonly property var modeFilterIndexes: [1, 2, 3]
    readonly property var fallbackWallpapers: [
        { kind: "static", label: "夢見る白羽", title: "白い朝", category: "静止画", path: wallpaperDir + "/static/wp15708544.jpg", preview: wallpaperDir + "/static/wp15708544.jpg" },
        { kind: "static", label: "青い記憶", title: "青い記憶", category: "静止画", path: wallpaperDir + "/static/WPP_blue.png", preview: wallpaperDir + "/static/WPP_blue.png" },
        { kind: "static", label: "白い少女", title: "白い少女", category: "静止画", path: wallpaperDir + "/static/anime-anime-devushki-anime-anime-girls-belye-volosy-golub-zh.jpg", preview: wallpaperDir + "/static/anime-anime-devushki-anime-anime-girls-belye-volosy-golub-zh.jpg" },
        { kind: "static", label: "東京の夜", title: "東京の夜", category: "静止画", path: wallpaperDir + "/static/wp12419427-tokyo-night-4k-wallpapers.jpg", preview: wallpaperDir + "/static/wp12419427-tokyo-night-4k-wallpapers.jpg" },
        { kind: "static", label: "東京の朝", title: "東京の朝", category: "静止画", path: wallpaperDir + "/static/wp6570018-tokyo-aesthetic-wallpapers.jpg", preview: wallpaperDir + "/static/wp6570018-tokyo-aesthetic-wallpapers.jpg" }
    ]

    property int activeFilter: 1
    property int selectedIndex: 2
    property int deckLastIndex: selectedIndex
    property int deckDirection: 1
    property bool suppressDeckAnimation: false
    property bool rouletteSpinning: false
    property int rouletteTargetIndex: selectedIndex
    property int rouletteSpinStepsRemaining: 0
    property int rouletteSpinTotalSteps: 0
    property bool loadedOnce: false
    property bool scanComplete: false
    property bool open: visible
    property bool preload: false
    property bool visibilitySaveQueued: false
    property var allWallpapers: fallbackWallpapers
    property var wallpapers: fallbackWallpapers
    property var lowerWallpapers: []
    property var hiddenWallpapers: []
    property real revealProgress: 0
    property real wheelProgress: 1
    property real rouletteRotation: 0
    property real modeSwapProgress: 1
    property real applyPulse: 0
    readonly property bool contentActive: visible || open || revealProgress > 0.01
    readonly property int preloadThumbLimit: 96
    readonly property int preloadHeroLimit: 10
    readonly property int motionFast: theme ? theme.motionFast : 120
    readonly property int motionSlow: theme ? theme.motionSlow : 320
    readonly property int motionPanelIn: theme ? theme.motionPanelIn : 220
    readonly property int motionPanelOut: theme ? theme.motionPanelOut : 140
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionPanelOffset: theme ? theme.motionPanelOffset : 28
    readonly property int motionEaseEnter: theme ? theme.motionEaseEnter : Easing.OutCubic
    readonly property int motionEaseExit: theme ? theme.motionEaseExit : Easing.InCubic
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic

    signal closeRequested()
    signal visibilityRequested()

    opacity: revealProgress
    scale: 0.985 + revealProgress * 0.015
    transformOrigin: Item.Bottom
    focus: visible
    activeFocusOnTab: true

    transform: Translate {
        y: Math.round((1 - root.revealProgress) * 34)
    }

    onOpenChanged: {
        animateReveal()
        if (open)
            ensureLoaded()
    }

    onPreloadChanged: {
        if (preload)
            ensureLoaded()
    }

    onVisibleChanged: {
        if (visible && open && revealProgress <= 0.001)
            animateReveal()
        if (visible && open)
            ensureLoaded()
    }

    onActiveFilterChanged: {
        refreshWallpapers()
        syncModeFromFilter()
    }

    onAllWallpapersChanged: refreshWallpapers()
    onHiddenWallpapersChanged: refreshWallpapers()
    onSelectedIndexChanged: startWheelTransition()

    Component.onCompleted: {
        syncWheelState()
        if (open || preload)
            ensureLoaded()
    }

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function cssColor(colorValue, opacity) {
        const c = root.alpha(colorValue, opacity)
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a + ")"
    }

    function animateReveal() {
        revealAnimation.stop()
        revealAnimation.from = revealProgress
        revealAnimation.to = open ? 1 : 0
        revealAnimation.duration = open ? motionPanelIn : motionPanelOut
        revealAnimation.restart()
    }

    function basename(path) {
        var name = String(path || "").split("/").pop()
        var dot = name.lastIndexOf(".")
        if (dot > 0)
            name = name.slice(0, dot)
        return name.replace(/[-_]+/g, " ")
    }

    function kindCategory(kind) {
        if (kind === "live")
            return "MPV"
        if (kind === "engine")
            return "Engine"
        return "静止画"
    }

    function modeLabelFromFilter(index) {
        const key = filterKeys[Math.max(0, Math.min(index, filterKeys.length - 1))]
        if (key === "live")
            return "MPV"
        if (key === "engine")
            return "ENGINE"
        if (key === "static")
            return "STATIC"
        return "ALL"
    }

    function syncModeFromFilter() {
        if (modeFilterIndexes.indexOf(activeFilter) >= 0)
            return
    }

    function displaySource(entry) {
        if (!entry)
            return ""
        if (entry.preview && String(entry.preview).length > 0)
            return entry.preview
        if ((entry.kind || "static") !== "engine")
            return entry.path || ""
        return ""
    }

    function wallpaperKey(entry) {
        if (!entry)
            return ""
        return String(entry.path || "")
    }

    function isWallpaperHidden(entry) {
        const key = root.wallpaperKey(entry)
        return key.length > 0 && root.hiddenWallpapers.indexOf(key) >= 0
    }

    function visibleAllWallpapers() {
        var next = []
        for (var i = 0; i < root.allWallpapers.length; i++) {
            if (!root.isWallpaperHidden(root.allWallpapers[i]))
                next.push(root.allWallpapers[i])
        }
        return next
    }

    function visibleWallpapersByKinds(kinds) {
        var next = []
        for (var i = 0; i < root.allWallpapers.length; i++) {
            const entry = root.allWallpapers[i]
            if (!entry || root.isWallpaperHidden(entry))
                continue
            if (kinds.indexOf(entry.kind || "static") >= 0)
                next.push(entry)
        }
        return next
    }

    function activeWallpaperKinds() {
        const key = filterKeys[Math.max(0, Math.min(root.activeFilter, filterKeys.length - 1))]
        if (key === "all")
            return ["static", "live", "engine"]
        return [key]
    }

    function bottomWallpapers() {
        return root.lowerWallpapers
    }

    function filterMatches(entry) {
        if (!entry || root.isWallpaperHidden(entry))
            return false

        const key = root.filterKeys[Math.max(0, Math.min(root.activeFilter, root.filterKeys.length - 1))]
        if (key === "all")
            return true
        return (entry.kind || "static") === key
    }

    function refreshWallpapers() {
        const next = root.visibleWallpapersByKinds(root.activeWallpaperKinds())

        root.suppressDeckAnimation = true
        root.wallpapers = next.length > 0 ? next : root.fallbackWallpapers
        root.lowerWallpapers = []
        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, Math.max(0, root.wallpapers.length - 1)))
        root.syncWheelState()
        root.suppressDeckAnimation = false
    }

    function ensureLoaded() {
        if (!loadedOnce) {
            loadedOnce = true
            reload()
        }
        loadVisibility()
    }

    function reload() {
        if (!scanWallpapers.running) {
            scanComplete = false
            scanWallpapers.running = true
        }
    }

    function loadVisibility() {
        if (!loadVisibilityProcess.running)
            loadVisibilityProcess.running = true
    }

    function queueVisibilitySave() {
        root.visibilitySaveQueued = true
        visibilitySaveDebounce.restart()
    }

    function flushVisibilitySave() {
        if (visibilitySaveProcess.running)
            return

        root.visibilitySaveQueued = false
        visibilitySaveProcess.command = [root.visibilityScript, "set", JSON.stringify(root.hiddenWallpapers)]
        visibilitySaveProcess.running = true
    }

    function normalizedIndex() {
        return Math.max(0, Math.min(root.selectedIndex, Math.max(0, root.wallpapers.length - 1)))
    }

    function currentWallpaper() {
        if (root.wallpapers.length > 0)
            return root.wallpapers[root.normalizedIndex()]
        return root.fallbackWallpapers[0]
    }

    function currentWallpaperPath() {
        return root.currentWallpaper().path
    }

    function currentWallpaperPreview() {
        return root.displaySource(root.currentWallpaper())
    }

    function currentWallpaperKind() {
        return root.currentWallpaper().kind || "static"
    }

    function currentWallpaperTitle() {
        return root.currentWallpaper().title || root.currentWallpaper().label || root.basename(root.currentWallpaper().path)
    }

    function currentWallpaperCategory() {
        return root.currentWallpaper().category || root.kindCategory(root.currentWallpaperKind())
    }

    function preloadWallpaper(index) {
        const list = root.allWallpapers.length > 0 ? root.allWallpapers : root.fallbackWallpapers
        if (list.length <= 0)
            return null
        return list[Math.max(0, Math.min(index, list.length - 1))]
    }

    function selectionDirection(fromIndex, toIndex) {
        const count = root.wallpapers.length
        if (count <= 1 || fromIndex === toIndex)
            return root.deckDirection
        if (fromIndex === count - 1 && toIndex === 0)
            return 1
        if (fromIndex === 0 && toIndex === count - 1)
            return -1
        return toIndex > fromIndex ? 1 : -1
    }

    function rouletteStep() {
        const count = Math.max(1, root.wheelSlotCount())
        return 180 / count
    }

    function rouletteBaseRotation(index) {
        const count = Math.max(1, root.wheelSlotCount())
        return 90 - (Math.max(0, index) + 0.5) * (180 / count)
    }

    function nearestRouletteRotation(index) {
        const base = root.rouletteBaseRotation(index)
        const turns = Math.round((root.rouletteRotation - base) / 360)
        return base + turns * 360
    }

    function syncRouletteRotation() {
        rouletteSettleAnimation.stop()
        rouletteSpinAnimation.stop()
        root.rouletteRotation = 0
    }

    function syncWheelState() {
        wheelAnimation.stop()
        root.deckLastIndex = root.normalizedIndex()
        root.wheelProgress = 1
        root.syncRouletteRotation()
    }

    function startWheelTransition() {
        if (root.suppressDeckAnimation) {
            root.syncWheelState()
            return
        }

        const count = root.wallpapers.length
        if (count <= 0)
            return

        const nextIndex = root.normalizedIndex()
        const prevIndex = Math.max(0, Math.min(root.deckLastIndex, count - 1))
        if (prevIndex === nextIndex)
            return

        wheelAnimation.stop()
        rouletteSettleAnimation.stop()
        root.deckDirection = root.selectionDirection(prevIndex, nextIndex)
        root.deckLastIndex = nextIndex
        root.wheelProgress = 0
        wheelAnimation.restart()
    }

    function moveSelection(dir) {
        const count = root.wallpapers.length
        if (count <= 0)
            return
        root.selectedIndex = (root.selectedIndex + dir + count) % count
    }

    function wheelSlotCount() {
        if (root.wallpapers.length <= 0)
            return 1
        if (root.wallpapers.length <= 4)
            return root.wallpapers.length

        const visible = Math.min(13, root.wallpapers.length)
        return visible % 2 === 0 ? visible - 1 : visible
    }

    function wheelIndex(slot) {
        const count = root.wallpapers.length
        if (count <= 0)
            return 0
        const visibleCount = root.wheelSlotCount()
        const center = Math.floor(visibleCount / 2)
        return (root.selectedIndex - center + slot + count) % count
    }

    function wheelWallpaper(slot) {
        if (root.wallpapers.length <= 0)
            return root.fallbackWallpapers[0]
        return root.wallpapers[root.wheelIndex(slot)]
    }

    function wheelBoundaryAngle(offset, slotCount) {
        const centerSlot = Math.floor(slotCount / 2)
        const leftSpan = Math.max(1, centerSlot + 0.5)
        const rightSpan = Math.max(1, slotCount - centerSlot - 0.5)
        const span = offset < 0 ? leftSpan : rightSpan
        const sign = offset < 0 ? -1 : 1
        const distance = Math.min(Math.abs(offset), span)

        if (distance <= 0.001)
            return 0

        const centerHalf = slotCount <= 3 ? 42 : (slotCount <= 5 ? 37 : 38)
        const maxAngle = 88
        if (distance <= 0.5)
            return sign * centerHalf * (distance / 0.5)

        const sideT = Math.min(1, (distance - 0.5) / Math.max(0.001, span - 0.5))
        const compressed = Math.pow(sideT, 0.90)
        return sign * (centerHalf + (maxAngle - centerHalf) * compressed)
    }

    function bottomWheelSlotCount() {
        return root.lowerWallpapers.length > 0 ? 7 : 0
    }

    function bottomWheelWallpaper(slot) {
        const list = root.lowerWallpapers
        if (list.length <= 0)
            return null
        const center = Math.floor(root.bottomWheelSlotCount() / 2)
        return list[(slot - center + list.length) % list.length]
    }

    function setModeFilter(index) {
        if (root.activeFilter === index)
            return
        modeSwapAnimation.stop()
        root.modeSwapProgress = 0
        root.activeFilter = index
        modeSwapAnimation.restart()
    }

    function cycleWallpaperMode(dir) {
        var current = root.modeFilterIndexes.indexOf(root.activeFilter)
        if (current < 0)
            current = 0
        const next = (current + dir + root.modeFilterIndexes.length) % root.modeFilterIndexes.length
        root.setModeFilter(root.modeFilterIndexes[next])
    }

    function spinRoulette() {
        const count = root.wallpapers.length
        if (count <= 0 || root.rouletteSpinning)
            return

        var target = Math.floor(Math.random() * count)
        if (count > 1 && target === root.normalizedIndex())
            target = (target + 1 + Math.floor(Math.random() * (count - 1))) % count

        root.rouletteTargetIndex = target
        root.rouletteSpinning = true
        rouletteSettleAnimation.stop()
        rouletteSpinAnimation.stop()

        const currentIndex = root.normalizedIndex()
        var forward = (target - currentIndex + count) % count
        if (forward === 0)
            forward = count
        const turns = 4 + Math.floor(Math.random() * 3)
        root.rouletteSpinStepsRemaining = turns * count + forward
        root.rouletteSpinTotalSteps = root.rouletteSpinStepsRemaining
        rouletteStepTimer.interval = 58
        rouletteStepTimer.restart()
    }

    function applySelected() {
        if (applyWallpaper.running)
            return
        const item = root.currentWallpaper()
        applyPulseAnimation.restart()
        applyWallpaper.command = [root.applyScript, item.kind || "static", item.path, root.displaySource(item)]
        applyWallpaper.running = true
    }

    Keys.onEscapePressed: root.closeRequested()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
            root.moveSelection(-1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
            root.moveSelection(1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
            root.cycleWallpaperMode(1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
            root.cycleWallpaperMode(-1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelected()
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Space) {
            root.spinRoulette()
            event.accepted = true
        }
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        from: root.revealProgress
        to: root.open ? 1 : 0
        duration: root.open ? root.motionPanelIn : root.motionPanelOut
        easing.type: root.open ? root.motionEaseEnter : root.motionEaseExit
    }

    NumberAnimation {
        id: wheelAnimation

        target: root
        property: "wheelProgress"
        from: 0
        to: 1
        duration: Math.max(300, root.motionSlow + 80)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: rouletteSettleAnimation

        target: root
        property: "rouletteRotation"
        from: root.rouletteRotation
        to: root.nearestRouletteRotation(root.normalizedIndex())
        duration: Math.max(360, root.motionSlow + 120)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: rouletteSpinAnimation

        target: root
        property: "rouletteRotation"
        from: root.rouletteRotation
        to: root.rouletteRotation
        duration: 2600
        easing.type: Easing.OutCubic

        onRunningChanged: {
            if (!running && root.rouletteSpinning) {
                root.suppressDeckAnimation = true
                root.selectedIndex = Math.max(0, Math.min(root.rouletteTargetIndex, Math.max(0, root.wallpapers.length - 1)))
                root.deckLastIndex = root.selectedIndex
                root.wheelProgress = 1
                root.suppressDeckAnimation = false
                root.rouletteSpinning = false
            }
        }
    }

    Timer {
        id: rouletteStepTimer

        interval: 70
        repeat: false
        onTriggered: {
            if (root.rouletteSpinStepsRemaining <= 0) {
                root.rouletteSpinning = false
                return
            }

            root.moveSelection(1)
            root.rouletteSpinStepsRemaining--

            if (root.rouletteSpinStepsRemaining > 0) {
                const done = root.rouletteSpinTotalSteps - root.rouletteSpinStepsRemaining
                interval = Math.min(190, 58 + done * 5)
                restart()
            } else {
                root.rouletteSpinning = false
            }
        }
    }

    NumberAnimation {
        id: modeSwapAnimation

        target: root
        property: "modeSwapProgress"
        from: 0
        to: 1
        duration: Math.max(300, root.motionSlow)
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: applyPulseAnimation

        NumberAnimation {
            target: root
            property: "applyPulse"
            from: 0
            to: 1
            duration: root.motionFast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "applyPulse"
            from: 1
            to: 0
            duration: root.motionFast
            easing.type: Easing.InOutSine
        }
    }

    Process {
        id: applyWallpaper

        running: false
        command: [root.applyScript, root.currentWallpaperKind(), root.currentWallpaperPath(), root.currentWallpaperPreview()]
        onExited: {
            running = false
            if (root.theme && root.theme.themeId === "pywal16")
                root.theme.reloadPywal16()
        }
    }

    Process {
        id: scanWallpapers

        running: false
        property var tmp: []
        command: [root.scanScript]

        onStarted: tmp = []

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data).trim()
                if (!line || line === "BEGIN")
                    return

                if (line === "END") {
                    if (scanWallpapers.tmp.length > 0)
                        root.allWallpapers = scanWallpapers.tmp.slice()
                    root.scanComplete = true
                    return
                }

                const parts = line.split("|")
                if (parts.length < 3)
                    return

                const kind = parts[0].toLowerCase()
                const path = parts[1]
                const preview = parts[2]
                const title = parts.length > 3 && parts.slice(3).join("|").length > 0
                    ? parts.slice(3).join("|")
                    : (kind === "engine" ? "Workshop " + path : root.basename(path))
                const category = root.kindCategory(kind)

                scanWallpapers.tmp.push({
                    kind: kind,
                    path: path,
                    preview: preview,
                    title: title,
                    label: title,
                    category: category
                })
            }
        }

        onExited: {
            running = false
            if (tmp.length > 0) {
                root.allWallpapers = tmp.slice()
                root.scanComplete = true
            }
        }
    }

    Process {
        id: loadVisibilityProcess

        running: false
        command: [root.visibilityScript, "list"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const parsed = JSON.parse(String(data).trim() || "[]")
                    root.hiddenWallpapers = Array.isArray(parsed) ? parsed : []
                } catch(e) {
                    root.hiddenWallpapers = []
                }
            }
        }

        onExited: running = false
    }

    Timer {
        id: visibilitySaveDebounce

        interval: 180
        repeat: false
        onTriggered: root.flushVisibilitySave()
    }

    Process {
        id: visibilitySaveProcess

        running: false
        command: [root.visibilityScript, "set", "[]"]
        onExited: {
            running = false
            if (root.visibilitySaveQueued)
                visibilitySaveDebounce.restart()
        }
    }

    Item {
        id: ramPreloadCache

        width: 1
        height: 1
        opacity: 0
        visible: root.preload
        z: -1000

        Repeater {
            model: root.preload && root.scanComplete ? Math.min(root.allWallpapers.length, root.preloadThumbLimit) : 0

            Image {
                required property int index

                width: 1
                height: 1
                source: root.displaySource(root.preloadWallpaper(index))
                sourceSize.width: 320
                sourceSize.height: 192
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: false
                mipmap: false
            }
        }

        Repeater {
            model: root.preload && root.scanComplete ? Math.min(root.allWallpapers.length, root.preloadHeroLimit) : 0

            Image {
                required property int index

                width: 1
                height: 1
                source: root.displaySource(root.preloadWallpaper(index))
                sourceSize.width: 1000
                sourceSize.height: 560
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: false
                mipmap: false
            }
        }
    }

    Rectangle {
        id: panelSurface

        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.width: 0
        clip: true
        antialiasing: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: mouse.accepted = true
        }

        Image {
            id: heroBackdrop

            anchors.fill: parent
            source: root.contentActive ? root.currentWallpaperPreview() : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1600
            sourceSize.height: 900
            asynchronous: true
            cache: true
            smooth: true
            visible: false
        }

        FastBlur {
            anchors.fill: parent
            source: heroBackdrop
            radius: 54
            opacity: root.pywalStyle && root.theme.themeMode === "dark" ? 0.24 : 0.34
            visible: false
        }

        Rectangle {
            anchors.fill: parent
            color: root.alpha(root.glass, root.pywalStyle && root.theme.themeMode === "dark" ? 0.72 : 0.82)
            visible: false
        }

        Rectangle {
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.alpha(root.lilac, root.neon ? 0.12 : 0.18) }
                GradientStop { position: 0.48; color: Qt.rgba(1, 1, 1, root.neon ? 0.02 : 0.14) }
                GradientStop { position: 1.0; color: root.alpha(root.pink, root.neon ? 0.10 : 0.20) }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: "transparent"
            visible: false
            border.width: 0
            border.color: root.alpha(root.borderSoft, 0.62)
        }

        Item {
            id: wheelStage

            x: 0
            y: 0
            width: parent.width
            height: parent.height
            clip: true
            z: 20
            readonly property real centerX: width * 0.50
            readonly property real centerY: height + 8
            readonly property real outerRadiusX: width * 0.485
            readonly property real outerRadiusY: outerRadiusX
            readonly property real innerRadiusX: width * 0.185
            readonly property real innerRadiusY: innerRadiusX

            WheelHandler {
                onWheel: function(event) {
                    if (!root.rouletteSpinning) {
                        const dx = Number(event.angleDelta.x)
                        const dy = Number(event.angleDelta.y)
                        const delta = Math.abs(dx) > Math.abs(dy) ? dx : dy
                        if (delta !== 0)
                            root.moveSelection(delta < 0 ? 1 : -1)
                    }
                    event.accepted = true
                }
            }

            Rectangle {
                x: wheelStage.centerX - wheelStage.outerRadiusX - 10
                y: wheelStage.centerY - wheelStage.outerRadiusY - 10
                width: wheelStage.outerRadiusX * 2 + 20
                height: width
                radius: width / 2
                color: root.alpha(root.card, root.neon ? 0.18 : 0.30)
                border.width: 1
                border.color: root.alpha(root.borderSoft, root.neon ? 0.62 : 0.56)
                antialiasing: true
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 34
                    samples: 69
                    horizontalOffset: 0
                    verticalOffset: 18
                    color: root.alpha(root.neon ? root.lilac : root.pink, root.neon ? 0.20 : 0.16)
                }
            }

            Item {
                id: rouletteWheel

                anchors.fill: parent
                transform: Rotation {
                    origin.x: wheelStage.centerX
                    origin.y: wheelStage.centerY
                    angle: 0
                }

                Repeater {
                    model: root.wheelSlotCount()

                    WheelTile {
                        required property int index

                        readonly property int slotCount: Math.max(1, root.wheelSlotCount())
                        readonly property int centerSlot: Math.floor(slotCount / 2)
                        readonly property int slotOffset: index - centerSlot
                        readonly property real offsetPhase: slotOffset + root.deckDirection * (1 - root.wheelProgress)
                        readonly property real startDegrees: root.wheelBoundaryAngle(offsetPhase - 0.5, slotCount)
                        readonly property real endDegrees: root.wheelBoundaryAngle(offsetPhase + 0.5, slotCount)
                        readonly property real focusAmount: Math.max(0, 1 - Math.min(1, Math.abs(offsetPhase)))
                        readonly property int wallpaperIndex: root.wheelIndex(index)

                        entry: root.wheelWallpaper(index)
                        selected: focusAmount > 0.48
                        width: wheelStage.width
                        height: wheelStage.height
                        centerX: wheelStage.centerX
                        centerY: wheelStage.centerY
                        outerRadiusX: wheelStage.outerRadiusX
                        outerRadiusY: wheelStage.outerRadiusY
                        innerRadiusX: wheelStage.innerRadiusX * (1 - focusAmount * 0.120)
                        innerRadiusY: wheelStage.innerRadiusY * (1 - focusAmount * 0.120)
                        startAngle: (-90 + startDegrees) * Math.PI / 180
                        endAngle: (-90 + endDegrees) * Math.PI / 180
                        z: Math.round(30 - Math.abs(offsetPhase) * 2) + (selected ? 10 : 0)
                        opacity: root.rouletteSpinning ? 0.98 : Math.max(0.58, 0.82 + focusAmount * 0.18 - Math.abs(offsetPhase) * 0.035)
                        scale: 1.0 + root.applyPulse * focusAmount * 0.018
                        onClicked: {
                            if (root.rouletteSpinning)
                                return
                            const next = root.wheelIndex(index)
                            if (next === root.selectedIndex)
                                root.applySelected()
                            else
                                root.selectedIndex = next
                        }
                    }
                }

                RouletteRimCanvas {
                    anchors.fill: parent
                    outerRadius: wheelStage.outerRadiusX
                    innerRadius: wheelStage.innerRadiusX
                    centerX: wheelStage.centerX
                    centerY: wheelStage.centerY
                    slotCount: root.wheelSlotCount()
                    phase: root.deckDirection * (1 - root.wheelProgress)
                    opacity: 0.94
                }
            }

            PointerNeedle {
                x: Math.round(wheelStage.centerX - width / 2)
                y: Math.round(wheelStage.centerY - wheelStage.outerRadiusY - 13)
                z: 80
            }

            Rectangle {
                x: Math.round(wheelStage.centerX - wheelStage.outerRadiusX - 4)
                y: wheelStage.height - 4
                width: Math.round(wheelStage.outerRadiusX * 2 + 8)
                height: 4
                radius: 2
                color: root.alpha(root.borderSoft, root.neon ? 0.62 : 0.54)
                z: 72
            }

            Rectangle {
                id: visibilityHub

                property bool hovered: false

                x: wheelStage.centerX - width / 2
                y: wheelStage.centerY - height / 2
                width: Math.round(wheelStage.innerRadiusX * 1.18)
                height: width
                radius: width / 2
                color: root.alpha(root.card, root.neon ? (visibilityHub.hovered ? 0.84 : 0.76) : (visibilityHub.hovered ? 0.92 : 0.84))
                border.width: 1
                border.color: root.alpha(root.borderSoft, visibilityHub.hovered ? 0.82 : 0.64)
                antialiasing: true
                z: 60
                scale: visibilityHub.hovered ? 1.018 : 1
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 22
                    samples: 45
                    horizontalOffset: 0
                    verticalOffset: 9
                    color: root.alpha(root.neon ? root.lilac : root.pink, visibilityHub.hovered ? 0.22 : 0.14)
                }

                Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
                Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
                Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: visibilityHub.hovered = true
                    onExited: visibilityHub.hovered = false
                    onClicked: root.visibilityRequested()
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height * 0.16)
                    spacing: 3

                    PanelIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(15, Math.round(parent.parent.width * 0.18))
                        height: width
                        kind: "hide"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "非表示"
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: Math.max(11, Math.round(parent.parent.width * 0.110))
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "HIDE"
                        color: root.inkSoft
                        font.family: root.monoFont
                        font.pixelSize: Math.max(7, Math.round(parent.parent.width * 0.060))
                        font.weight: Font.Bold
                    }
                }
            }

            RoundButton {
                compact: true
                icon: "left"
                x: Math.round(wheelStage.centerX - wheelStage.innerRadiusX * 1.42 - width / 2)
                y: wheelStage.height - height - 18
                z: 86
                onClicked: if (!root.rouletteSpinning) root.moveSelection(-1)
            }

            RoundButton {
                compact: true
                icon: "right"
                x: Math.round(wheelStage.centerX + wheelStage.innerRadiusX * 1.42 - width / 2)
                y: wheelStage.height - height - 18
                z: 86
                onClicked: if (!root.rouletteSpinning) root.moveSelection(1)
            }
        }

        Rectangle {
            id: infoPanel

            visible: false
            x: Math.round(wheelStage.x + wheelStage.width + 24)
            y: 28
            width: Math.max(248, parent.width - x - 28)
            height: parent.height - 56
            radius: 24
            color: root.alpha(root.card, root.neon ? 0.32 : 0.46)
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.48)
            antialiasing: true
            z: 30

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    height: 28
                    spacing: 8

                    Text {
                        width: parent.width - 92
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: "壁紙ルーレット"
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 19
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: 84
                        height: parent.height
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: root.wallpapers.length + " slots"
                        color: root.inkSoft
                        font.family: root.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Row {
                    spacing: 8
                    ModeButton { label: "STATIC"; active: root.activeFilter === 1; onClicked: root.setModeFilter(1) }
                    ModeButton { label: "MPV"; active: root.activeFilter === 2; onClicked: root.setModeFilter(2) }
                    ModeButton { label: "ENGINE"; active: root.activeFilter === 3; onClicked: root.setModeFilter(3) }
                }

                Rectangle {
                    width: parent.width
                    height: Math.min(178, Math.max(130, parent.height * 0.31))
                    radius: 20
                    color: root.alpha(root.glass, 0.34)
                    border.width: 1
                    border.color: root.alpha(root.borderSoft, 0.44)
                    clip: true
                    antialiasing: true

                    Image {
                        anchors.fill: parent
                        source: root.contentActive ? root.currentWallpaperPreview() : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 680
                        sourceSize.height: 420
                        asynchronous: true
                        cache: true
                        smooth: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.00) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.neon ? 0.42 : 0.28) }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        width: parent.width
                        text: root.currentWallpaperTitle()
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.currentWallpaperCategory() + " / " + root.modeLabelFromFilter(root.activeFilter)
                        color: root.inkSoft
                        font.family: root.monoFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                Row {
                    width: parent.width
                    height: 44
                    spacing: 10

                    RoundButton {
                        compact: true
                        icon: "left"
                        onClicked: if (!root.rouletteSpinning) root.moveSelection(-1)
                    }

                    RoundButton {
                        compact: true
                        icon: "right"
                        onClicked: if (!root.rouletteSpinning) root.moveSelection(1)
                    }

                    VisibilityButton {
                        onClicked: root.visibilityRequested()
                    }
                }

                Item {
                    width: 1
                    height: 1
                    Layout.fillHeight: true
                }

                ActionButton {
                    width: parent.width
                    label: root.rouletteSpinning ? "回転中..." : "ランダムに回す"
                    primary: false
                    enabled: !root.rouletteSpinning
                    onClicked: root.spinRoulette()
                }

                ActionButton {
                    width: parent.width
                    label: applyWallpaper.running ? "適用中..." : "選択を適用"
                    primary: true
                    enabled: !applyWallpaper.running && !root.rouletteSpinning
                    onClicked: root.applySelected()
                }
            }
        }
    }

    component WheelTile: Item {
        id: tile

        property var entry: null
        property bool selected: false
        property real centerX: width * 0.5
        property real centerY: height
        property real outerRadiusX: width * 0.45
        property real outerRadiusY: height * 0.8
        property real innerRadiusX: width * 0.28
        property real innerRadiusY: height * 0.5
        property real startAngle: Math.PI
        property real endAngle: Math.PI * 2
        readonly property real segmentPadding: 4
        readonly property real segmentMid: (startAngle + endAngle) / 2
        readonly property real segmentX: Math.max(0, Math.floor(segmentMinX() - segmentPadding))
        readonly property real segmentY: Math.max(0, Math.floor(segmentMinY() - segmentPadding))
        readonly property real segmentWidth: Math.min(width - segmentX, Math.ceil(segmentMaxX() - segmentMinX() + segmentPadding * 2))
        readonly property real segmentHeight: Math.min(height - segmentY, Math.ceil(segmentMaxY() - segmentMinY() + segmentPadding * 2))
        signal clicked()

        onCenterXChanged: requestSegmentPaint()
        onCenterYChanged: requestSegmentPaint()
        onOuterRadiusXChanged: requestSegmentPaint()
        onOuterRadiusYChanged: requestSegmentPaint()
        onInnerRadiusXChanged: requestSegmentPaint()
        onInnerRadiusYChanged: requestSegmentPaint()
        onStartAngleChanged: requestSegmentPaint()
        onEndAngleChanged: requestSegmentPaint()
        onSelectedChanged: requestSegmentPaint()

        function px(angle, radiusX) {
            return centerX + Math.cos(angle) * radiusX
        }

        function py(angle, radiusY) {
            return centerY + Math.sin(angle) * radiusY
        }

        function segmentMinX() {
            return Math.min(px(startAngle, outerRadiusX), px(endAngle, outerRadiusX), px(segmentMid, outerRadiusX), px(startAngle, innerRadiusX), px(endAngle, innerRadiusX), px(segmentMid, innerRadiusX))
        }

        function segmentMaxX() {
            return Math.max(px(startAngle, outerRadiusX), px(endAngle, outerRadiusX), px(segmentMid, outerRadiusX), px(startAngle, innerRadiusX), px(endAngle, innerRadiusX), px(segmentMid, innerRadiusX))
        }

        function segmentMinY() {
            return Math.min(py(startAngle, outerRadiusY), py(endAngle, outerRadiusY), py(segmentMid, outerRadiusY), py(startAngle, innerRadiusY), py(endAngle, innerRadiusY), py(segmentMid, innerRadiusY))
        }

        function segmentMaxY() {
            return Math.max(py(startAngle, outerRadiusY), py(endAngle, outerRadiusY), py(segmentMid, outerRadiusY), py(startAngle, innerRadiusY), py(endAngle, innerRadiusY), py(segmentMid, innerRadiusY))
        }

        function requestSegmentPaint() {
            tileMask.requestPaint()
            tileBorder.requestPaint()
        }

        function drawSegment(ctx, offsetX, offsetY) {
            const ox = offsetX || 0
            const oy = offsetY || 0
            const samples = 22
            ctx.beginPath()

            for (let i = 0; i <= samples; i++) {
                const angle = startAngle + (endAngle - startAngle) * i / samples
                const x = px(angle, outerRadiusX) - ox
                const y = py(angle, outerRadiusY) - oy
                if (i === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }

            for (let i = samples; i >= 0; i--) {
                const angle = startAngle + (endAngle - startAngle) * i / samples
                ctx.lineTo(px(angle, innerRadiusX) - ox, py(angle, innerRadiusY) - oy)
            }

            ctx.closePath()
        }

        Item {
            id: tileSource

            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            visible: false

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.alpha(root.lilac, root.neon ? 0.28 : 0.18) }
                    GradientStop { position: 1.0; color: root.alpha(root.pink, root.neon ? 0.18 : 0.12) }
                }
            }

            Image {
                anchors.fill: parent
                source: root.contentActive ? root.displaySource(tile.entry) : ""
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                sourceSize.width: 420
                sourceSize.height: 260
                asynchronous: true
                smooth: true
                mipmap: true
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, selected ? 0.18 : 0.08) }
                    GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.00) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, selected ? 0.26 : 0.18) }
                }
            }
        }

        Canvas {
            id: tileMask

            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            visible: false
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")

                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "white"
                tile.drawSegment(ctx, tile.segmentX, tile.segmentY)
                ctx.fill()
            }
        }

        OpacityMask {
            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            source: tileSource
            maskSource: tileMask
            cached: false
        }

        Canvas {
            id: tileBorder

            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            opacity: selected ? 0.92 : 0.56
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")

                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = selected ? "rgba(255,255,255,0.82)" : "rgba(255,255,255,0.48)"
                ctx.lineWidth = selected ? 2.0 : 1.2
                tile.drawSegment(ctx, tile.segmentX, tile.segmentY)
                ctx.stroke()
            }
        }

        Rectangle {
            visible: selected
            x: tile.px(tile.segmentMid, (tile.outerRadiusX + tile.innerRadiusX) * 0.5) - width / 2
            y: tile.py(tile.segmentMid, (tile.outerRadiusY + tile.innerRadiusY) * 0.5) - height / 2
            width: 14
            height: 14
            radius: 7
            color: Qt.rgba(0.03, 0.03, 0.04, 0.50)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.54)
        }

        MouseArea {
            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    component ModeButton: Rectangle {
        id: chip

        property string label: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        width: Math.max(74, labelText.implicitWidth + 28)
        height: 28
        radius: 14
        color: active ? root.alpha(root.pink, 0.66) : (hovered ? root.alpha(root.card, 0.36) : root.alpha(root.card, 0.22))
        border.width: 1
        border.color: active ? root.alpha(root.borderSoft, 0.70) : root.alpha(root.borderSoft, 0.30)
        antialiasing: true

        Text {
            id: labelText

            anchors.centerIn: parent
            text: chip.label
            color: active ? (root.theme ? root.theme.activeText : "white") : root.inkSoft
            font.family: root.monoFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: chip.hovered = true
            onExited: chip.hovered = false
            onClicked: chip.clicked()
        }
    }

    component ActionButton: Rectangle {
        id: button

        property string label: ""
        property bool primary: false
        property bool hovered: false
        signal clicked()

        height: 46
        radius: 23
        opacity: enabled ? 1 : 0.58
        color: primary
            ? (hovered ? root.alpha(root.pink, 0.86) : root.alpha(root.pink, 0.72))
            : (hovered ? root.alpha(root.card, 0.54) : root.alpha(root.card, 0.36))
        border.width: 1
        border.color: primary ? root.alpha(root.borderSoft, 0.66) : root.alpha(root.borderSoft, 0.42)
        scale: actionMouse.pressed && enabled ? 0.975 : (hovered && enabled ? 1.015 : 1)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on opacity { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: primary ? (root.theme ? root.theme.activeText : "white") : root.ink
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        MouseArea {
            id: actionMouse

            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component RoundButton: Rectangle {
        id: button

        property string icon: "down"
        property string label: ""
        property bool compact: false
        property bool hovered: false
        signal clicked()

        width: compact ? 48 : 92
        height: compact ? 48 : 72
        radius: height / 2
        color: compact ? (hovered ? root.alpha(root.card, 0.56) : root.alpha(root.card, 0.38)) : (hovered ? Qt.rgba(0, 0, 0, 0.46) : Qt.rgba(0, 0, 0, 0.34))
        border.width: 1
        border.color: compact ? root.alpha(root.borderSoft, hovered ? 0.66 : 0.44) : Qt.rgba(1, 1, 1, hovered ? 0.32 : 0.18)
        scale: hovered ? 1.025 : 1
        antialiasing: true
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 22
            samples: 45
            horizontalOffset: 0
            verticalOffset: 10
            color: Qt.rgba(0, 0, 0, 0.22)
        }

        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Column {
            anchors.centerIn: parent
            spacing: compact ? 0 : 3

            PanelIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: compact ? 18 : 20
                height: compact ? 18 : 20
                kind: button.icon
            }

            Text {
                visible: !button.compact && button.label.length > 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.label
                color: root.inkSoft
                font.family: root.monoFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component HubButton: Item {
        id: hub

        property bool hovered: false
        property bool pressed: false
        signal clicked()

        width: 104
        height: 78

        function roundedRect(ctx, x, y, w, h, r) {
            const radius = Math.min(r, w / 2, h / 2)
            ctx.beginPath()
            ctx.moveTo(x + radius, y)
            ctx.lineTo(x + w - radius, y)
            ctx.arcTo(x + w, y, x + w, y + radius, radius)
            ctx.lineTo(x + w, y + h - radius)
            ctx.arcTo(x + w, y + h, x + w - radius, y + h, radius)
            ctx.lineTo(x + radius, y + h)
            ctx.arcTo(x, y + h, x, y + h - radius, radius)
            ctx.lineTo(x, y + radius)
            ctx.arcTo(x, y, x + radius, y, radius)
            ctx.closePath()
        }

        Canvas {
            id: hubCanvas

            anchors.fill: parent
            antialiasing: true
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                const lift = hub.pressed ? 3 : (hub.hovered ? -1 : 0)

                ctx.reset()
                ctx.clearRect(0, 0, width, height)

                ctx.save()
                hub.roundedRect(ctx, 4, 8 + lift, width - 8, height + 18, 34)
                ctx.fillStyle = hub.hovered ? "rgba(55, 55, 58, 0.74)" : "rgba(42, 42, 45, 0.66)"
                ctx.fill()
                ctx.strokeStyle = "rgba(255, 255, 255, 0.26)"
                ctx.lineWidth = 1.2
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(22, 15 + lift)
                ctx.quadraticCurveTo(width / 2, 2 + lift, width - 22, 15 + lift)
                ctx.strokeStyle = "rgba(255, 255, 255, 0.20)"
                ctx.lineWidth = 1.0
                ctx.stroke()
                ctx.restore()
            }
        }

        PanelIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 25 + (hub.pressed ? 3 : 0)
            width: 19
            height: 19
            kind: "down"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                hub.hovered = true
                hubCanvas.requestPaint()
            }
            onExited: {
                hub.hovered = false
                hub.pressed = false
                hubCanvas.requestPaint()
            }
            onPressed: {
                hub.pressed = true
                hubCanvas.requestPaint()
            }
            onReleased: {
                hub.pressed = false
                hubCanvas.requestPaint()
            }
            onClicked: hub.clicked()
        }
    }

    component VisibilityButton: Rectangle {
        id: button

        property bool hovered: false
        signal clicked()

        width: 44
        height: 44
        radius: height / 2
        z: 91
        color: hovered ? Qt.rgba(58, 58, 62, 0.54) : Qt.rgba(42, 42, 46, 0.42)
        border.width: 1
        border.color: hovered ? Qt.rgba(255, 255, 255, 0.34) : Qt.rgba(255, 255, 255, 0.20)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        PanelIcon {
            anchors.centerIn: parent
            width: 20
            height: 20
            kind: "hide"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component PanelIcon: Canvas {
        id: iconCanvas

        property string kind: "down"

        onKindChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.cssColor(root.ink, 0.86)
            ctx.fillStyle = root.cssColor(root.ink, 0.86)
            ctx.lineWidth = Math.max(1.8, Math.min(width, height) * 0.10)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (kind === "left" || kind === "right") {
                const flip = kind === "left" ? -1 : 1
                ctx.translate(width / 2, height / 2)
                ctx.scale(flip, 1)
                ctx.beginPath()
                ctx.moveTo(-width * 0.18, -height * 0.27)
                ctx.lineTo(width * 0.16, 0)
                ctx.lineTo(-width * 0.18, height * 0.27)
                ctx.stroke()
                return
            }

            if (kind === "tune") {
                for (let i = 0; i < 3; i++) {
                    const y = height * (0.28 + i * 0.22)
                    ctx.beginPath()
                    ctx.moveTo(width * 0.18, y)
                    ctx.lineTo(width * 0.82, y)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.arc(width * (i === 0 ? 0.62 : (i === 1 ? 0.38 : 0.70)), y, 2.1, 0, Math.PI * 2)
                    ctx.fill()
                }
                return
            }

            if (kind === "hide") {
                ctx.beginPath()
                ctx.ellipse(width * 0.50, height * 0.50, width * 0.31, height * 0.22, 0, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(width * 0.50, height * 0.50, Math.min(width, height) * 0.09, 0, Math.PI * 2)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(width * 0.20, height * 0.80)
                ctx.lineTo(width * 0.80, height * 0.20)
                ctx.stroke()
                return
            }

            ctx.beginPath()
            ctx.moveTo(width * 0.28, height * 0.38)
            ctx.lineTo(width * 0.50, height * 0.62)
            ctx.lineTo(width * 0.72, height * 0.38)
            ctx.stroke()
        }
    }

    component PointerNeedle: Canvas {
        id: needle

        width: 44
        height: 48
        antialiasing: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.save()
            ctx.shadowColor = root.cssColor(root.neon ? root.lilac : root.pink, root.neon ? 0.34 : 0.22)
            ctx.shadowBlur = 14
            ctx.shadowOffsetY = 5
            ctx.beginPath()
            ctx.moveTo(width * 0.50, height * 0.92)
            ctx.lineTo(width * 0.20, height * 0.24)
            ctx.quadraticCurveTo(width * 0.50, height * 0.05, width * 0.80, height * 0.24)
            ctx.closePath()
            ctx.fillStyle = root.cssColor(root.card, root.neon ? 0.88 : 0.94)
            ctx.fill()
            ctx.restore()

            ctx.beginPath()
            ctx.moveTo(width * 0.50, height * 0.86)
            ctx.lineTo(width * 0.30, height * 0.28)
            ctx.quadraticCurveTo(width * 0.50, height * 0.16, width * 0.70, height * 0.28)
            ctx.closePath()
            ctx.fillStyle = root.cssColor(root.neon ? root.lilac : root.pink, 0.90)
            ctx.fill()
            ctx.strokeStyle = root.cssColor(root.borderSoft, 0.58)
            ctx.lineWidth = 1.0
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(width * 0.50, height * 0.25, 4.0, 0, Math.PI * 2)
            ctx.fillStyle = root.cssColor(root.theme ? root.theme.activeText : root.ink, 0.82)
            ctx.fill()
        }
    }

    component RouletteRimCanvas: Canvas {
        id: rim

        property real centerX: width * 0.5
        property real centerY: height * 0.5
        property real outerRadius: Math.min(width, height) * 0.47
        property real innerRadius: Math.min(width, height) * 0.18
        property int slotCount: 1
        property real phase: 0

        antialiasing: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onCenterXChanged: requestPaint()
        onCenterYChanged: requestPaint()
        onOuterRadiusChanged: requestPaint()
        onInnerRadiusChanged: requestPaint()
        onSlotCountChanged: requestPaint()
        onPhaseChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const count = Math.max(1, slotCount)
            const centerSlot = Math.floor(count / 2)

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            ctx.beginPath()
            ctx.arc(centerX, centerY, outerRadius, -Math.PI, 0)
            ctx.strokeStyle = root.cssColor(root.borderSoft, root.neon ? 0.74 : 0.62)
            ctx.lineWidth = 7
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(centerX, centerY, innerRadius, -Math.PI, 0)
            ctx.strokeStyle = root.cssColor(root.borderSoft, root.neon ? 0.58 : 0.46)
            ctx.lineWidth = 3
            ctx.stroke()

            for (let i = 0; i <= count; i++) {
                const offset = i - centerSlot - 0.5 + phase
                const degrees = root.wheelBoundaryAngle(offset, count)
                const a = (-90 + degrees) * Math.PI / 180
                ctx.beginPath()
                ctx.moveTo(centerX + Math.cos(a) * innerRadius, centerY + Math.sin(a) * innerRadius)
                ctx.lineTo(centerX + Math.cos(a) * outerRadius, centerY + Math.sin(a) * outerRadius)
                ctx.strokeStyle = root.cssColor(root.borderSoft, i % 2 === 0 ? 0.42 : 0.28)
                ctx.lineWidth = i === centerSlot || i === centerSlot + 1 ? 1.8 : 1.2
                ctx.stroke()
            }
        }
    }

    component ReferencePetalsCanvas: Canvas {
        id: petals

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const cx = width * 0.50
            const baseY = height * 0.62

            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.save()
            ctx.strokeStyle = "rgba(236,236,236,0.52)"
            ctx.fillStyle = "rgba(242,242,242,0.64)"
            ctx.lineWidth = 1.8
            ctx.beginPath()
            ctx.moveTo(cx - 12, baseY)
            ctx.bezierCurveTo(cx - 42, height * 0.48, cx - 18, height * 0.35, cx + 18, height * 0.25)
            ctx.stroke()

            function flower(x, y, s, dark) {
                ctx.save()
                ctx.translate(x, y)
                ctx.fillStyle = dark ? "rgba(210,210,210,0.52)" : "rgba(250,250,250,0.74)"
                ctx.strokeStyle = dark ? "rgba(185,185,185,0.32)" : "rgba(255,255,255,0.40)"
                ctx.lineWidth = 0.8
                for (let i = 0; i < 6; i++) {
                    ctx.rotate(Math.PI / 3)
                    ctx.beginPath()
                    ctx.arc(0, -s * 0.78, s * 0.42, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.stroke()
                }
                ctx.fillStyle = "rgba(225,225,225,0.70)"
                ctx.beginPath()
                ctx.arc(0, 0, s * 0.28, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()
            }

            flower(cx + 16, height * 0.28, 21, false)
            flower(cx - 34, height * 0.40, 18, true)
            flower(cx + 84, height * 0.49, 16, false)
            flower(cx - 96, height * 0.51, 14, true)
            flower(cx + 145, height * 0.54, 13, false)

            ctx.strokeStyle = "rgba(232,232,232,0.32)"
            ctx.lineWidth = 1.0
            for (let b = 0; b < 6; b++) {
                const bx = cx + [-28, 42, 76, -82, 112, -116][b]
                const by = height * [0.36, 0.38, 0.44, 0.48, 0.52, 0.56][b]
                ctx.beginPath()
                ctx.moveTo(cx, height * 0.44)
                ctx.quadraticCurveTo((cx + bx) / 2, by - 26, bx, by)
                ctx.stroke()
            }
            ctx.restore()

            const flecks = [
                [0.07, 0.21, 4, 0], [0.15, 0.34, 5, 1], [0.22, 0.47, 3, 0],
                [0.31, 0.08, 3, 1], [0.40, 0.49, 4, 0], [0.62, 0.18, 3, 1],
                [0.74, 0.31, 5, 0], [0.83, 0.43, 4, 1], [0.93, 0.26, 5, 0],
                [0.55, 0.06, 3, 1], [0.69, 0.51, 3, 0], [0.12, 0.55, 4, 1]
            ]

            for (let i = 0; i < flecks.length; i++) {
                const p = flecks[i]
                const x = width * p[0]
                const y = height * p[1]
                const s = p[2]
                ctx.save()
                ctx.translate(x, y)
                ctx.rotate((i * 37 % 160) * Math.PI / 180)
                ctx.fillStyle = p[3] ? "rgba(255,255,255,0.78)" : "rgba(0,0,0,0.76)"
                ctx.beginPath()
                ctx.moveTo(0, -s)
                ctx.quadraticCurveTo(s * 0.72, 0, 0, s)
                ctx.quadraticCurveTo(-s * 0.55, 0, 0, -s)
                ctx.fill()
                ctx.restore()
            }
        }
    }

    component RadialGlassCanvas: Canvas {
        id: glass

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const cx = width * 0.50
            const cy = height + 34
            const rOuterX = Math.min(width * 0.47, 390)
            const rOuterY = Math.min(height * 0.84, 352)
            const rInnerX = Math.min(width * 0.29, 244)
            const rInnerY = Math.min(height * 0.53, 222)
            const rCoreX = rInnerX * 0.42
            const rCoreY = rInnerY * 0.44

            function annularSegment(outerX, outerY, innerX, innerY, start, end) {
                const samples = 64
                ctx.beginPath()
                for (let i = 0; i <= samples; i++) {
                    const a = start + (end - start) * i / samples
                    const x = cx + Math.cos(a) * outerX
                    const y = cy + Math.sin(a) * outerY
                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }
                for (let i = samples; i >= 0; i--) {
                    const a = start + (end - start) * i / samples
                    ctx.lineTo(cx + Math.cos(a) * innerX, cy + Math.sin(a) * innerY)
                }
                ctx.closePath()
            }

            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.fillStyle = "rgba(236, 238, 242, 0.30)"
            annularSegment(rOuterX, rOuterY, rInnerX, rInnerY, Math.PI, Math.PI * 2)
            ctx.fill()

            ctx.fillStyle = "rgba(236, 238, 242, 0.22)"
            annularSegment(rInnerX, rInnerY, rCoreX, rCoreY, Math.PI, Math.PI * 2)
            ctx.fill()

            ctx.strokeStyle = "rgba(255, 255, 255, 0.26)"
            ctx.lineWidth = 1.4
            annularSegment(rOuterX, rOuterY, rInnerX, rInnerY, Math.PI, Math.PI * 2)
            ctx.stroke()
        }
    }

    component RadialFrameCanvas: Canvas {
        id: frame

        property int topSlots: Math.max(1, root.wheelSlotCount())
        property int bottomSlots: Math.max(0, root.bottomWheelSlotCount())
        property real topPhase: root.deckDirection * (1 - root.wheelProgress) * (Math.PI / topSlots)
        readonly property real bottomSpan: 118 * Math.PI / 180

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onTopSlotsChanged: requestPaint()
        onBottomSlotsChanged: requestPaint()
        onTopPhaseChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const cx = width * 0.50
            const cy = height + 34
            const rOuterX = Math.min(width * 0.47, 390)
            const rOuterY = Math.min(height * 0.84, 352)
            const rInnerX = Math.min(width * 0.29, 244)
            const rInnerY = Math.min(height * 0.53, 222)
            const rCoreX = rInnerX * 0.42
            const rCoreY = rInnerY * 0.44

            function strokeArc(rx, ry, start, end, color, lineWidth) {
                const samples = 96
                ctx.beginPath()
                for (let i = 0; i <= samples; i++) {
                    const a = start + (end - start) * i / samples
                    const x = cx + Math.cos(a) * rx
                    const y = cy + Math.sin(a) * ry
                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }
                ctx.strokeStyle = color
                ctx.lineWidth = lineWidth
                ctx.stroke()
            }

            function strokeDivider(angle, innerX, innerY, outerX, outerY, alpha, lineWidth) {
                const sx = cx + Math.cos(angle) * innerX
                const sy = cy + Math.sin(angle) * innerY
                const ex = cx + Math.cos(angle) * outerX
                const ey = cy + Math.sin(angle) * outerY
                ctx.beginPath()
                ctx.moveTo(sx, sy)
                ctx.lineTo(ex, ey)
                ctx.strokeStyle = "rgba(255,255,255," + alpha + ")"
                ctx.lineWidth = lineWidth
                ctx.stroke()
            }

            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.lineCap = "butt"
            ctx.lineJoin = "round"

            strokeArc(rOuterX, rOuterY, Math.PI, Math.PI * 2, "rgba(255,255,255,0.54)", 9)
            strokeArc(rInnerX, rInnerY, Math.PI, Math.PI * 2, "rgba(255,255,255,0.36)", 5)

            if (bottomSlots > 0)
                strokeArc(rCoreX, rCoreY, -Math.PI / 2 - bottomSpan / 2, -Math.PI / 2 + bottomSpan / 2, "rgba(255,255,255,0.30)", 3.2)

            const topStep = Math.PI / topSlots
            for (let i = 0; i <= topSlots; i++) {
                const a = -Math.PI + frame.topPhase + i * topStep
                if (a >= -Math.PI && a <= 0)
                    strokeDivider(a, rInnerX, rInnerY, rOuterX, rOuterY, 0.24, 1.25)
            }

            if (bottomSlots > 0) {
                const start = -Math.PI / 2 - bottomSpan / 2
                const step = bottomSpan / bottomSlots
                for (let i = 0; i <= bottomSlots; i++)
                    strokeDivider(start + i * step, rCoreX, rCoreY, rInnerX, rInnerY, 0.18, 1.0)
            }
        }
    }
}
