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
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.43, 0.36, 0.52, 0.90)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.56, 0.48, 0.64, 0.64)
    readonly property color pink: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.43, 0.66, 0.92)
    readonly property color pinkSoft: theme ? theme.activeBg : Qt.rgba(0.96, 0.72, 0.84, 0.34)
    readonly property color lilac: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.48, 0.73, 0.78)
    readonly property color line: theme ? theme.alpha(theme.borderActive, 0.18) : Qt.rgba(0.72, 0.54, 0.65, 0.16)
    readonly property color glass: theme ? theme.surfacePopup : Qt.rgba(1.0, 0.986, 1.0, 0.82)
    readonly property color card: theme ? theme.surfaceCard : Qt.rgba(1, 1, 1, 0.68)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.76)
    readonly property color shadow: theme ? (neon ? theme.alpha(theme.popupBorderGlow, theme.popupBorderGlow.a * 0.50) : theme.shadowColor) : Qt.rgba(0.56, 0.30, 0.50, 0.075)
    readonly property string uiFont: "Noto Sans CJK JP"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string applyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property var tabs: ["壁紙", "カラー", "アイコン", "カーソル"]
    readonly property var filters: ["すべて", "静止画", "MPV", "Engine", "人物", "風景", "お気に入り"]
    readonly property var filterKeys: ["all", "static", "live", "engine", "人物", "風景", "favorite"]
    readonly property var fallbackWallpapers: [
        { kind: "static", label: "夢見る白羽", title: "白い朝", category: "人物", path: wallpaperDir + "/static/wp15708544.jpg", preview: wallpaperDir + "/static/wp15708544.jpg" },
        { kind: "static", label: "朱の回廊", title: "朱の回廊", category: "風景", path: wallpaperDir + "/WallpaperSelector/1238960-best-japan-wallpaper-4k-3840x2160-for-xiaomi.jpg", preview: wallpaperDir + "/WallpaperSelector/1238960-best-japan-wallpaper-4k-3840x2160-for-xiaomi.jpg" },
        { kind: "static", label: "静寂の夕暮れ", title: "静寂の夕暮れ", category: "風景", path: wallpaperDir + "/WallpaperSelector/1238973-japan-wallpaper-4k-3840x2160-for-mobile-hd.jpg", preview: wallpaperDir + "/WallpaperSelector/1238973-japan-wallpaper-4k-3840x2160-for-mobile-hd.jpg" },
        { kind: "static", label: "淡い記憶", title: "淡い記憶", category: "アニメ", path: wallpaperDir + "/WallpaperSelector/columbina-anime-3840x2160-26082.jpg", preview: wallpaperDir + "/WallpaperSelector/columbina-anime-3840x2160-26082.jpg" },
        { kind: "static", label: "夜の都市", title: "夜の都市", category: "シンプル", path: wallpaperDir + "/static/wp12419255-tokyo-night-4k-wallpapers.jpg", preview: wallpaperDir + "/static/wp12419255-tokyo-night-4k-wallpapers.jpg" }
    ]

    property int activeTab: 0
    property int activeFilter: 0
    property int selectedIndex: 2
    property bool favoriteSelected: false
    property bool open: visible
    property real revealProgress: 0
    property var allWallpapers: fallbackWallpapers
    property var wallpapers: fallbackWallpapers
    property bool suppressDeckAnimation: false
    property bool deckReady: false
    property int deckLastIndex: selectedIndex
    property int deckDirection: 1
    property real deckProgress: 1
    property real deckSnapScale: 1
    property real thumbProgress: 1
    property string deckFromSource: ""
    property string deckToSource: ""

    signal closeRequested()

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    opacity: revealProgress
    transformOrigin: attachSide === "right" ? Item.Right : Item.Left
    scale: 0.992 + revealProgress * 0.008
    focus: visible
    activeFocusOnTab: true

    transform: Translate {
        x: Math.round((1 - root.revealProgress) * (root.attachSide === "right" ? 36 : -36))
        y: Math.round((1 - root.revealProgress) * 6)
    }

    onOpenChanged: animateReveal()
    onVisibleChanged: {
        if (visible && open && revealProgress <= 0.001)
            animateReveal()
    }

    function animateReveal() {
        revealAnimation.stop()
        revealAnimation.from = revealProgress
        revealAnimation.to = open ? 1 : 0
        revealAnimation.duration = open ? 440 : 180
        revealAnimation.restart()
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        from: root.revealProgress
        to: root.open ? 1 : 0
        duration: root.open ? 440 : 180
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
    }

    onActiveFilterChanged: refreshWallpapers()
    onAllWallpapersChanged: refreshWallpapers()
    onSelectedIndexChanged: startDeckTransition()

    Component.onCompleted: {
        syncDeckState()
        reload()
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
        return root.currentWallpaper().title || root.currentWallpaper().label
    }

    function currentWallpaperCategory() {
        return root.currentWallpaper().category || "壁紙"
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

    function filterMatches(entry) {
        if (!entry)
            return false

        const key = root.filterKeys[Math.max(0, Math.min(root.activeFilter, root.filterKeys.length - 1))]
        if (key === "all")
            return true
        if (key === "favorite")
            return root.favoriteSelected
        if (key === "static" || key === "live" || key === "engine")
            return (entry.kind || "static") === key
        return entry.category === key
    }

    function refreshWallpapers() {
        var next = []
        for (var i = 0; i < root.allWallpapers.length; i++) {
            if (root.filterMatches(root.allWallpapers[i]))
                next.push(root.allWallpapers[i])
        }

        root.suppressDeckAnimation = true
        root.wallpapers = next.length > 0 ? next : root.allWallpapers
        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, Math.max(0, root.wallpapers.length - 1)))
        root.syncDeckState()
        root.suppressDeckAnimation = false
    }

    function reload() {
        if (!scanWallpapers.running)
            scanWallpapers.running = true
    }

    function thumbCount() {
        return Math.min(5, root.wallpapers.length)
    }

    function thumbIndex(slot) {
        const count = root.wallpapers.length
        if (count <= 5)
            return slot

        const center = Math.floor(root.thumbCount() / 2)
        return (root.selectedIndex - center + slot + count) % count
    }

    function thumbWallpaper(slot) {
        if (root.wallpapers.length <= 0)
            return root.fallbackWallpapers[0]
        return root.wallpapers[root.thumbIndex(slot)]
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

    function syncDeckState() {
        const item = root.currentWallpaper()
        const src = root.displaySource(item)
        deckAnimation.stop()
        thumbAnimation.stop()
        root.deckFromSource = src
        root.deckToSource = src
        root.deckLastIndex = root.normalizedIndex()
        root.deckProgress = 1
        root.deckSnapScale = 1
        root.thumbProgress = 1
        root.deckReady = true
    }

    function startDeckTransition() {
        if (root.suppressDeckAnimation) {
            root.syncDeckState()
            return
        }

        if (!root.deckReady) {
            root.syncDeckState()
            return
        }

        const count = root.wallpapers.length
        if (count <= 0)
            return

        const nextIndex = root.normalizedIndex()
        const prevIndex = Math.max(0, Math.min(root.deckLastIndex, count - 1))
        const fromItem = root.wallpapers[prevIndex]
        const toItem = root.wallpapers[nextIndex]
        const fromSource = root.displaySource(fromItem)
        const toSource = root.displaySource(toItem)

        if (prevIndex === nextIndex && root.deckToSource === toSource)
            return

        deckAnimation.stop()
        thumbAnimation.stop()
        root.deckDirection = root.selectionDirection(prevIndex, nextIndex)
        root.deckFromSource = fromSource
        root.deckToSource = toSource
        root.deckProgress = 0
        root.deckSnapScale = 1
        root.thumbProgress = 0
        root.deckLastIndex = nextIndex
        deckAnimation.restart()
        thumbAnimation.restart()
    }

    function moveSelection(dir) {
        const count = root.wallpapers.length
        if (count <= 0)
            return
        root.selectedIndex = (root.selectedIndex + dir + count) % count
    }

    function applySelected() {
        if (applyWallpaper.running)
            return
        const item = root.currentWallpaper()
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

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelected()
            event.accepted = true
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
                const category = kind === "static" ? root.kindCategory(kind) : root.kindCategory(kind)

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
            if (tmp.length > 0)
                root.allWallpapers = tmp.slice()
        }
    }

    SequentialAnimation {
        id: deckAnimation

        NumberAnimation {
            target: root
            property: "deckProgress"
            from: 0
            to: 1
            duration: 520
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "deckSnapScale"
            from: 1
            to: 1.012
            duration: 58
            easing.type: Easing.OutSine
        }

        NumberAnimation {
            target: root
            property: "deckSnapScale"
            from: 1.012
            to: 1
            duration: 72
            easing.type: Easing.InOutSine
        }

        onFinished: {
            root.deckFromSource = root.deckToSource
            root.deckProgress = 1
            root.deckSnapScale = 1
        }
    }

    SequentialAnimation {
        id: thumbAnimation

        PauseAnimation { duration: 55 }

        NumberAnimation {
            target: root
            property: "thumbProgress"
            from: 0
            to: 1
            duration: 445
            easing.type: Easing.OutCubic
        }
    }

    Repeater {
        model: 2

        Rectangle {
            required property int index

            visible: !root.externalSurface
            x: -12 * (index + 1)
            y: 10 * (index + 1)
            width: root.width
            height: root.height
            radius: root.cornerRadius + 2
            opacity: index === 0 ? 0.18 : 0.08
            color: root.glass
            border.width: 1
            border.color: root.theme ? (root.pywalStyle ? root.theme.alpha(root.lilac, index === 0 ? 0.18 : 0.10) : root.theme.alpha(root.borderSoft, index === 0 ? 0.34 : 0.20)) : Qt.rgba(1, 1, 1, index === 0 ? 0.34 : 0.20)
            antialiasing: true
            layer.enabled: true
            layer.effect: FastBlur {
                radius: index === 0 ? 2 : 4
            }
        }
    }

    Rectangle {
        id: panelSurface

        anchors.fill: parent
        radius: root.cornerRadius
        color: root.externalSurface ? "transparent" : root.glass
        border.width: root.externalSurface ? 0 : 1
        border.color: root.pywalStyle && root.theme ? root.theme.popupBorderGlow : root.borderSoft
        clip: true
        antialiasing: true
        layer.enabled: !root.externalSurface
        layer.effect: DropShadow {
            transparentBorder: true
            radius: root.pywalStyle ? 52 : 60
            samples: root.pywalStyle ? 105 : 105
            horizontalOffset: 0
            verticalOffset: root.pywalStyle ? 0 : 18
            color: root.shadow
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: mouse.accepted = true
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !root.externalSurface
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.theme ? root.theme.alpha(root.card, root.neon ? 0.26 : 0.42) : Qt.rgba(1, 1, 1, 0.42) }
                GradientStop { position: 0.52; color: root.theme ? root.theme.alpha(root.card, root.neon ? 0.14 : 0.20) : Qt.rgba(1, 1, 1, 0.20) }
                GradientStop { position: 1.0; color: root.theme ? root.theme.alpha(root.pink, root.neon ? 0.10 : 0.14) : Qt.rgba(1, 0.965, 0.995, 0.24) }
            }
        }

        Rectangle {
            visible: !root.externalSurface
            anchors {
                fill: parent
                margins: 1
            }

            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: root.alpha(root.borderSoft, root.pywalStyle ? 0.28 : 0.18)
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 28
                rightMargin: 28
                topMargin: 88
            }

            height: 1
            color: root.line
        }

        Text {
            id: titleText

            x: 42
            y: 31
            text: "テーマ"
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 18
            font.weight: Font.Bold
            opacity: 0.86
            layer.enabled: root.pywalStyle
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 8
                samples: 17
                horizontalOffset: 0
                verticalOffset: 0
                color: root.theme ? root.theme.textGlow : Qt.rgba(0, 0, 0, 0)
            }
        }

        Rectangle {
            x: titleText.x + titleText.implicitWidth + 13
            y: 31
            width: 52
            height: 24
            radius: 12
            color: root.pinkSoft

            Text {
                anchors.centerIn: parent
                text: "壁紙"
                color: root.pink
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }

        Text {
            x: 42
            y: 62
            text: "お気に入りの壁紙で、心地よいデスクトップに。"
            color: root.inkSoft
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Row {
            id: topActions

            x: parent.width - width - 34
            y: 31
            height: 40
            spacing: 18

            Rectangle {
                id: favoriteButton

                width: 40
                height: 40
                radius: 20
                color: root.theme
                    ? (favoriteMouse.containsMouse || root.favoriteSelected ? root.theme.alpha(root.card, 0.72) : root.theme.alpha(root.card, 0.50))
                    : (favoriteMouse.containsMouse || root.favoriteSelected ? Qt.rgba(1, 1, 1, 0.72) : Qt.rgba(1, 1, 1, 0.50))
                border.width: 1
                border.color: root.theme
                    ? (root.favoriteSelected ? root.theme.alpha(root.pink, 0.48) : root.theme.alpha(root.borderSoft, 0.56))
                    : (root.favoriteSelected ? Qt.rgba(0.86, 0.47, 0.66, 0.42) : Qt.rgba(1, 1, 1, 0.56))
                scale: favoriteMouse.pressed ? 0.96 : (favoriteMouse.containsMouse ? 1.03 : 1.0)
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 20
                    samples: 41
                    horizontalOffset: 0
                    verticalOffset: 8
                    color: root.theme ? (root.pywalStyle ? root.theme.iconGlow : root.theme.alpha(root.theme.shadowColor, 0.12)) : Qt.rgba(0.42, 0.24, 0.42, 0.12)
                }

                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

                HeartIcon {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    filled: root.favoriteSelected
                }

                MouseArea {
                    id: favoriteMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.favoriteSelected = !root.favoriteSelected
                }
            }

            Rectangle {
                id: applyButton

                width: 126
                height: 40
                radius: 19
                color: root.theme
                    ? (applyMouse.containsMouse || activeFocus ? root.theme.alpha(root.theme.buttonPrimaryBg, 0.96) : root.theme.alpha(root.theme.buttonPrimaryBg, 0.86))
                    : (applyMouse.containsMouse || activeFocus ? Qt.rgba(0.88, 0.45, 0.67, 0.94) : Qt.rgba(0.86, 0.45, 0.66, 0.82))
                scale: applyMouse.pressed ? 0.96 : (applyMouse.containsMouse ? 1.02 : 1.0)
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 24
                    samples: 49
                    horizontalOffset: 0
                    verticalOffset: 8
                    color: root.theme ? root.theme.buttonPrimaryGlow : Qt.rgba(0.60, 0.28, 0.48, 0.16)
                }

                Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: applyWallpaper.running ? "適用中..." : "適用する"
                    color: root.theme ? root.theme.buttonPrimaryText : "white"
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: applyMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applySelected()
                }
            }
        }

        Row {
            id: filterRow

            x: 42
            y: 108
            spacing: 10

            Repeater {
                model: root.filters

                FilterChip {
                    required property int index
                    required property string modelData

                    text: modelData
                    active: root.activeFilter === index
                    onClicked: root.activeFilter = index
                }
            }
        }

        Rectangle {
            id: tuneButton

            width: 30
            height: 30
            radius: 15
            x: parent.width - width - 42
            y: 105
            color: tuneMouse.containsMouse ? root.alpha(root.card, 0.58) : root.alpha(root.card, 0.38)
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.46)

            TuneIcon {
                anchors.centerIn: parent
                width: 15
                height: 15
            }

            MouseArea {
                id: tuneMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }

        Rectangle {
            id: heroCard

            x: 34
            y: 151
            width: parent.width - 68
            height: Math.round(parent.height * 0.415)
            radius: 15
            color: root.alpha(root.card, 0.30)
            border.width: root.activeFocus ? 2 : 1
            border.color: root.pywalStyle ? root.alpha(root.lilac, root.activeFocus ? 0.54 : 0.34) : (root.activeFocus ? root.alpha(root.pink, 0.52) : root.alpha(root.borderSoft, 0.68))
            clip: true
            antialiasing: true
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 22
                samples: 47
                horizontalOffset: 0
                verticalOffset: 8
                color: root.pywalStyle && root.theme ? root.theme.popupGlow : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.42, 0.24, 0.40, 1), 0.10)
            }

            Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Item {
                id: deckStage

                anchors.fill: parent
                anchors.margins: 1
                clip: true

                DeckImage {
                    width: parent.width
                    height: parent.height
                    source: root.deckFromSource
                    direction: root.deckDirection
                    progress: root.deckProgress
                    incoming: false
                    visible: root.deckProgress < 0.995 && root.deckFromSource !== root.deckToSource
                }

                DeckImage {
                    width: parent.width
                    height: parent.height
                    source: root.deckToSource.length > 0 ? root.deckToSource : root.currentWallpaperPreview()
                    direction: root.deckDirection
                    progress: root.deckProgress
                    incoming: true
                    snapScale: root.deckSnapScale
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: heroCard.radius
                gradient: Gradient {
                    GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 0.46; color: Qt.rgba(0.18, 0.10, 0.17, 0.00) }
                    GradientStop { position: 1.00; color: Qt.rgba(0.13, 0.09, 0.16, 0.56) }
                }
            }

            Rectangle {
                x: 18
                y: parent.height - 44
                width: 28
                height: 22
                radius: 8
                color: Qt.rgba(0.05, 0.05, 0.08, 0.30)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.72)

                Text {
                    anchors.centerIn: parent
                    text: "4K"
                    color: "white"
                    font.family: root.monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            Column {
                x: 58
                y: parent.height - 55
                spacing: 2

                Text {
                    text: root.currentWallpaperTitle()
                    color: "white"
                    font.family: root.uiFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.22)
                }

                Text {
                    text: root.currentWallpaperCategory() + "・" + root.currentWallpaperTitle()
                    color: Qt.rgba(1, 1, 1, 0.86)
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }

            Row {
                anchors {
                    right: heroCheck.left
                    rightMargin: 18
                    bottom: parent.bottom
                    bottomMargin: 23
                }

                spacing: 5

                    Repeater {
                    model: root.thumbCount()

                    Rectangle {
                        required property int index

                        width: root.thumbIndex(index) === root.selectedIndex ? 8 : 6
                        height: 6
                        radius: 3
                        color: root.thumbIndex(index) === root.selectedIndex ? root.pink : Qt.rgba(1, 1, 1, 0.46)

                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Rectangle {
                id: heroHeart

                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 18
                    topMargin: 16
                }

                width: 25
                height: 25
                radius: 13
                color: Qt.rgba(1, 1, 1, 0.22)
                border.width: 2
                border.color: Qt.rgba(1, 1, 1, 0.84)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.favoriteSelected = !root.favoriteSelected
                }
            }

            Rectangle {
                id: heroCheck

                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 20
                    bottomMargin: 15
                }

                width: 37
                height: 37
                radius: 19
                color: Qt.rgba(1, 1, 1, 0.86)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.74)

                CheckIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applySelected()
            }

            WheelHandler {
                onWheel: function(event) {
                    root.moveSelection(event.angleDelta.y < 0 ? 1 : -1)
                    event.accepted = true
                }
            }
        }

        Row {
            id: thumbStrip

            x: 46
            y: parent.height - 104
            width: parent.width - 92
            height: 82
            spacing: 12
            opacity: 0.60 + root.thumbProgress * 0.40
            scale: 0.985 + root.thumbProgress * 0.015
            transformOrigin: Item.Center

            transform: Translate {
                x: Math.round(-root.deckDirection * 24 * (1 - root.thumbProgress))
                y: Math.round(2 * (1 - root.thumbProgress))
            }

            WheelHandler {
                onWheel: function(event) {
                    root.moveSelection(event.angleDelta.y < 0 ? 1 : -1)
                    event.accepted = true
                }
            }

            Repeater {
                model: root.thumbCount()

                WallpaperThumb {
                    required property int index

                    width: (thumbStrip.width - thumbStrip.spacing * 4) / 5
                    height: thumbStrip.height
                    source: root.displaySource(root.thumbWallpaper(index))
                    selected: root.thumbIndex(index) === root.selectedIndex
                    onClicked: root.selectedIndex = root.thumbIndex(index)
                }
            }
        }

        NavButton {
            x: 18
            y: thumbStrip.y + Math.round((thumbStrip.height - height) / 2)
            direction: -1
            onClicked: root.moveSelection(-1)
        }

        NavButton {
            x: parent.width - width - 18
            y: thumbStrip.y + Math.round((thumbStrip.height - height) / 2)
            direction: 1
            onClicked: root.moveSelection(1)
        }
    }

    component DeckImage: Item {
        id: deckLayer

        property string source: ""
        property int direction: 1
        property real progress: 1
        property bool incoming: true
        property real snapScale: 1
        readonly property real travel: 90
        readonly property real visualProgress: Math.max(0, Math.min(1, progress))
        readonly property real stickyPull: Math.sin(visualProgress * Math.PI) * 10

        x: Math.round(incoming
            ? direction * (travel * (1 - visualProgress) - stickyPull)
            : -direction * (travel * visualProgress - stickyPull * 0.35))
        y: 0
        scale: (incoming ? 0.96 + visualProgress * 0.04 : 1.0 - visualProgress * 0.04) * (incoming ? snapScale : 1.0)
        opacity: incoming ? 0.55 + visualProgress * 0.45 : 1.0 - visualProgress * 0.45
        z: incoming ? 3 : (visualProgress < 0.82 ? 2 : 1)
        transformOrigin: Item.Center
        clip: true
        layer.enabled: true
        layer.effect: FastBlur {
            radius: deckLayer.incoming
                ? Math.max(0, 1.5 * (1 - deckLayer.visualProgress))
                : Math.min(1.5, 1.5 * deckLayer.visualProgress)
        }

        Image {
            anchors.fill: parent
            source: deckLayer.source
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1000
            sourceSize.height: 560
            asynchronous: true
            smooth: true
            mipmap: true
        }

        Rectangle {
            anchors.fill: parent
            color: deckLayer.incoming
                ? Qt.rgba(1, 1, 1, 0.030 * (1 - deckLayer.visualProgress))
                : Qt.rgba(0.18, 0.10, 0.18, 0.045 * deckLayer.visualProgress)
        }
    }

    component FilterChip: Rectangle {
        id: chip

        property string text: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        width: Math.max(76, chipText.implicitWidth + 28)
        height: 26
        radius: height / 2
        color: active
            ? root.alpha(root.pink, 0.78)
            : (hovered ? root.alpha(root.card, root.pywalStyle ? 0.46 : 0.42) : root.alpha(root.card, root.pywalStyle ? 0.24 : 0.28))
        border.width: 1
        border.color: active ? root.alpha(root.pink, 0.40) : root.alpha(root.borderSoft, root.pywalStyle ? 0.26 : 0.34)
        antialiasing: true
        layer.enabled: root.pywalStyle && (active || hovered)
        layer.effect: DropShadow {
            transparentBorder: true
            radius: active ? 14 : 9
            samples: active ? 29 : 19
            horizontalOffset: 0
            verticalOffset: 0
            color: root.theme ? root.theme.buttonPrimaryGlow : Qt.rgba(0, 0, 0, 0)
        }

        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Text {
            id: chipText

            anchors.centerIn: parent
            text: chip.text
            color: chip.active ? (root.theme ? root.theme.activeText : "white") : root.inkSoft
            font.family: root.uiFont
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

    component WallpaperThumb: Rectangle {
        id: card

        property string source: ""
        property bool selected: false
        property bool hovered: false
        signal clicked()

        radius: 9
        color: root.alpha(root.card, 0.30)
        border.width: selected ? 2 : 1
        border.color: selected ? root.alpha(root.pink, 0.86) : root.alpha(root.borderSoft, root.pywalStyle ? 0.30 : 0.42)
        clip: true
        antialiasing: true
        scale: hovered ? 1.025 : 1.0
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: card.hovered || card.selected ? 20 : 12
            samples: card.hovered || card.selected ? 41 : 25
            horizontalOffset: 0
            verticalOffset: card.hovered || card.selected ? 8 : 4
            color: root.pywalStyle && root.theme && (card.hovered || card.selected) ? root.theme.buttonPrimaryGlow : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.30, 0.20, 0.34, 1), card.hovered || card.selected ? 0.14 : 0.07)
        }

        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Image {
            anchors.fill: parent
            anchors.margins: 1
            source: card.source
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 260
            sourceSize.height: 160
            asynchronous: true
            smooth: true
            mipmap: true
        }

        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: card.hovered ? root.alpha(root.card, 0.10) : "transparent"
        }

        Rectangle {
            visible: card.selected
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: 6
                bottomMargin: 6
            }

            width: 26
            height: 26
            radius: 13
            color: root.pink
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.78)

            CheckIcon {
                anchors.centerIn: parent
                width: 13
                height: 13
                colorOverride: root.theme ? root.theme.activeText : "white"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: card.clicked()
        }
    }

    component NavButton: Rectangle {
        id: nav

        property int direction: 1
        property bool hovered: false
        signal clicked()

        width: 32
        height: 42
        radius: 16
        color: hovered ? root.alpha(root.card, 0.74) : root.alpha(root.card, root.pywalStyle ? 0.38 : 0.46)
        border.width: 1
        border.color: hovered && root.pywalStyle ? root.alpha(root.lilac, 0.40) : root.alpha(root.borderSoft, 0.50)
        antialiasing: true
        layer.enabled: root.pywalStyle && hovered
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 16
            samples: 33
            horizontalOffset: 0
            verticalOffset: 0
            color: root.theme ? root.theme.iconGlow : Qt.rgba(0, 0, 0, 0)
        }

        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        ArrowIcon {
            anchors.centerIn: parent
            width: 13
            height: 18
            direction: nav.direction
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: nav.hovered = true
            onExited: nav.hovered = false
            onClicked: nav.clicked()
        }
    }

    component HeartIcon: Canvas {
        id: heart

        property bool filled: false

        onFilledChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = "rgba(214, 112, 158, 0.86)"
            ctx.fillStyle = filled ? "rgba(214, 112, 158, 0.36)" : "transparent"
            ctx.lineWidth = Math.max(1.6, s * 0.085)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(width * 0.50, height * 0.78)
            ctx.bezierCurveTo(width * 0.20, height * 0.58, width * 0.12, height * 0.36, width * 0.27, height * 0.25)
            ctx.bezierCurveTo(width * 0.38, height * 0.17, width * 0.48, height * 0.24, width * 0.50, height * 0.33)
            ctx.bezierCurveTo(width * 0.52, height * 0.24, width * 0.64, height * 0.17, width * 0.75, height * 0.25)
            ctx.bezierCurveTo(width * 0.90, height * 0.36, width * 0.80, height * 0.58, width * 0.50, height * 0.78)
            ctx.closePath()
            ctx.fill()
            ctx.stroke()
        }
    }

    component CheckIcon: Canvas {
        id: check

        property color colorOverride: root.pink

        onColorOverrideChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = colorOverride
            ctx.lineWidth = Math.max(2.0, Math.min(width, height) * 0.14)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(width * 0.23, height * 0.52)
            ctx.lineTo(width * 0.43, height * 0.72)
            ctx.lineTo(width * 0.78, height * 0.30)
            ctx.stroke()
        }
    }

    component ArrowIcon: Canvas {
        id: arrow

        property int direction: 1

        onDirectionChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const dir = direction < 0 ? -1 : 1

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = "rgba(145, 107, 166, 0.82)"
            ctx.lineWidth = 2.0
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            if (dir > 0) {
                ctx.moveTo(width * 0.35, height * 0.24)
                ctx.lineTo(width * 0.66, height * 0.50)
                ctx.lineTo(width * 0.35, height * 0.76)
            } else {
                ctx.moveTo(width * 0.65, height * 0.24)
                ctx.lineTo(width * 0.34, height * 0.50)
                ctx.lineTo(width * 0.65, height * 0.76)
            }
            ctx.stroke()
        }
    }

    component TuneIcon: Canvas {
        id: tune

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = "rgba(145, 107, 166, 0.84)"
            ctx.fillStyle = "rgba(145, 107, 166, 0.84)"
            ctx.lineWidth = 1.6
            ctx.lineCap = "round"

            for (let i = 0; i < 3; i++) {
                const y = height * (0.25 + i * 0.25)
                ctx.beginPath()
                ctx.moveTo(width * 0.18, y)
                ctx.lineTo(width * 0.82, y)
                ctx.stroke()

                const knobX = width * (i === 0 ? 0.60 : (i === 1 ? 0.38 : 0.68))
                ctx.beginPath()
                ctx.arc(knobX, y, 2.1, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }
}
