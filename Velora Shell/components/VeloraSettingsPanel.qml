import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property alias surfaceItem: panelSurface
    property var theme: null
    property bool externalSurface: false
    readonly property int cornerRadius: 18
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property string uiFont: "Noto Sans CJK JP"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string applyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property var navItems: [
        { key: "theme", label: "テーマ", icon: "palette" },
        { key: "wallpaper", label: "壁紙", icon: "image" },
        { key: "icons", label: "アイコン", icon: "puzzle" },
        { key: "cursor", label: "カーソル", icon: "cursor" },
        { key: "fonts", label: "フォント", icon: "font" }
    ]
    readonly property var fallbackThemes: [
        { id: "default", title: "Light", subtitle: "Velora Default", mode: "light", preview: "default" },
        { id: "dark", title: "Dark", subtitle: "Manual", mode: "dark", preview: "dark" },
        { id: "pink", title: "Pink", subtitle: "Soft rose", mode: "light", preview: "pink" },
        { id: "lavender", title: "Lavender", subtitle: "Lilac glass", mode: "light", preview: "lavender" },
        { id: "pywal16", title: "pywal16", subtitle: "auto", mode: "dynamic", preview: "pywal16" }
    ]
    readonly property var fallbackWallpapers: [
        { kind: "static", label: "夢見る白羽", title: "白い朝", category: "人物", path: wallpaperDir + "/static/wp15708544.jpg", preview: wallpaperDir + "/static/wp15708544.jpg" },
        { kind: "static", label: "朱の回廊", title: "朱の回廊", category: "風景", path: wallpaperDir + "/WallpaperSelector/1238960-best-japan-wallpaper-4k-3840x2160-for-xiaomi.jpg", preview: wallpaperDir + "/WallpaperSelector/1238960-best-japan-wallpaper-4k-3840x2160-for-xiaomi.jpg" },
        { kind: "static", label: "静寂の夕暮れ", title: "静寂の夕暮れ", category: "風景", path: wallpaperDir + "/WallpaperSelector/1238973-japan-wallpaper-4k-3840x2160-for-mobile-hd.jpg", preview: wallpaperDir + "/WallpaperSelector/1238973-japan-wallpaper-4k-3840x2160-for-mobile-hd.jpg" },
        { kind: "static", label: "淡い記憶", title: "淡い記憶", category: "アニメ", path: wallpaperDir + "/WallpaperSelector/columbina-anime-3840x2160-26082.jpg", preview: wallpaperDir + "/WallpaperSelector/columbina-anime-3840x2160-26082.jpg" },
        { kind: "static", label: "花霞", title: "花霞", category: "風景", path: wallpaperDir + "/WallpaperSelector/1238954-widescreen-japan-wallpaper-4k-3840x2160-hd-1080p.jpg", preview: wallpaperDir + "/WallpaperSelector/1238954-widescreen-japan-wallpaper-4k-3840x2160-hd-1080p.jpg" }
    ]

    property int activeNav: 0
    property int selectedIndex: 0
    property var allWallpapers: fallbackWallpapers
    property var wallpapers: fallbackWallpapers
    property string noticeText: ""
    property bool open: visible
    property real revealProgress: 0

    signal closeRequested()

    opacity: revealProgress
    scale: 0.992 + revealProgress * 0.008
    transformOrigin: Item.Left
    focus: visible
    activeFocusOnTab: true

    transform: Translate {
        x: Math.round((1 - root.revealProgress) * -34)
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
        revealAnimation.duration = open ? 420 : 170
        revealAnimation.restart()
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        from: root.revealProgress
        to: root.open ? 1 : 0
        duration: root.open ? 420 : 170
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
    }

    Component.onCompleted: reload()

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

    function c(name, fallback) {
        return root.theme ? root.theme[name] : fallback
    }

    function accentPrimary() {
        return root.pywalStyle && root.theme ? root.theme.accentSecondary : root.c("accentPrimary", Qt.rgba(232 / 255, 166 / 255, 200 / 255, 1))
    }

    function accentSecondary() {
        return root.pywalStyle && root.theme ? root.theme.accentPrimary : root.c("accentSecondary", Qt.rgba(200 / 255, 148 / 255, 242 / 255, 1))
    }

    function alpha(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function fontGlowEnabled() {
        return root.theme && root.theme.textGlow.a > 0.001
    }

    component FontGlowEffect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowColor: root.theme ? root.theme.textGlow : Qt.rgba(0, 0, 0, 0)
        shadowOpacity: root.theme ? Math.min(1, 0.34 + root.theme.textGlowLevel * 0.66) : 0
        shadowBlur: root.theme ? Math.min(1, 0.24 + root.theme.textGlowLevel * 0.72) : 0
        blurMax: root.theme ? Math.round(12 + root.theme.textGlowLevel * 22) : 12
        autoPaddingEnabled: true
    }

    function percent(value) {
        return Math.round(Number(value || 0) * 100) + "%"
    }

    function themeOptions() {
        return root.theme ? root.theme.themeOptions : root.fallbackThemes
    }

    function currentThemeId() {
        return root.theme ? root.theme.themeId : "default"
    }

    function selectTheme(id) {
        if (root.theme)
            root.theme.applyTheme(id)
        if (id === "pywal16")
            root.noticeText = "pywal16 preparado como opcao. Se nao houver tema gerado, o Default continua como fallback."
        else
            root.noticeText = "Tema aplicado: " + id
        noticeReset.restart()
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

    function currentWallpaper() {
        if (root.wallpapers.length > 0)
            return root.wallpapers[Math.max(0, Math.min(root.selectedIndex, root.wallpapers.length - 1))]
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

    function reload() {
        if (!scanWallpapers.running)
            scanWallpapers.running = true
    }

    Timer {
        id: noticeReset
        interval: 2800
        repeat: false
        onTriggered: root.noticeText = ""
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
        id: customWallpaperChooser

        running: false
        command: ["bash", "-lc", "xdg-open \"$HOME/Pictures/Wallpapers\" >/dev/null 2>&1 || true"]
        onExited: running = false
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
                    if (scanWallpapers.tmp.length > 0) {
                        root.allWallpapers = scanWallpapers.tmp.slice()
                        root.wallpapers = scanWallpapers.tmp.slice(0, Math.min(5, scanWallpapers.tmp.length))
                        root.selectedIndex = 0
                    }
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
                    : root.basename(path)

                scanWallpapers.tmp.push({
                    kind: kind,
                    path: path,
                    preview: preview,
                    title: title,
                    label: title,
                    category: kind === "static" ? "静止画" : kind
                })
            }
        }

        onExited: {
            running = false
            if (tmp.length > 0) {
                root.allWallpapers = tmp.slice()
                root.wallpapers = tmp.slice(0, Math.min(5, tmp.length))
                root.selectedIndex = 0
            }
        }
    }

    Rectangle {
        visible: !root.externalSurface
        x: 10
        y: 13
        width: parent.width - 2
        height: parent.height - 4
        radius: root.cornerRadius + 4
        color: root.c("shadowColor", Qt.rgba(0.37, 0.25, 0.45, 0.11))
        opacity: 0.58
    }

    Rectangle {
        id: panelSurface

        anchors.fill: parent
        radius: root.cornerRadius
        color: root.externalSurface ? "transparent" : root.c("surfacePopup", Qt.rgba(1.0, 0.986, 1.0, 0.86))
        border.width: root.externalSurface ? 0 : 1
        border.color: root.pywalStyle && root.theme ? root.theme.popupBorderGlow : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.74))
        clip: true
        antialiasing: true
        layer.enabled: !root.externalSurface
        layer.effect: DropShadow {
            transparentBorder: true
            radius: root.pywalStyle ? 42 : 52
            samples: root.pywalStyle ? 85 : 101
            horizontalOffset: 0
            verticalOffset: root.pywalStyle ? 0 : 18
            color: root.pywalStyle && root.theme ? root.alpha(root.theme.popupBorderGlow, root.theme.popupBorderGlow.a * 0.48) : root.c("shadowColor", Qt.rgba(0.48, 0.30, 0.50, 0.10))
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
                GradientStop { position: 0.0; color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.54) }
                GradientStop { position: 0.56; color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.20) }
                GradientStop { position: 1.0; color: root.alpha(root.accentPrimary(), root.neon ? 0.08 : 0.10) }
            }
        }

        Rectangle {
            x: 182
            y: 0
            width: 1
            height: parent.height
            color: root.alpha(root.c("borderActive", Qt.rgba(232 / 255, 166 / 255, 200 / 255, 1)), 0.16)
        }

        Column {
            id: navColumn

            x: 22
            y: 26
            width: 136
            spacing: 16

            Repeater {
                model: root.navItems

                SettingsNavItem {
                    required property int index
                    required property var modelData

                    width: navColumn.width
                    itemData: modelData
                    active: root.activeNav === index
                    onClicked: root.activeNav = index
                }
            }
        }

        Item {
            id: mainArea

            x: 212
            y: 35
            width: parent.width - x - 34
            height: parent.height - 62

            Flickable {
                id: mainFlick

                anchors.fill: parent
                visible: root.activeNav <= 1
                clip: true
                contentWidth: width
                contentHeight: root.activeNav === 0 ? 640 : height
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    id: mainContent

                    width: mainFlick.width
                    height: mainFlick.contentHeight

                Text {
                    x: 0
                    y: 0
                    visible: root.activeNav === 0
                    text: "テーマスタイル"
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
                    id: themeRow

                    x: 0
                    y: 34
                    visible: root.activeNav === 0
                    spacing: 13

                    Repeater {
                        model: root.themeOptions()

                        ThemeCard {
                            required property var modelData

                            width: Math.floor((mainArea.width - themeRow.spacing * 4) / 5)
                            height: 124
                            itemData: modelData
                            selected: root.currentThemeId() === modelData.id
                            onClicked: root.selectTheme(modelData.id)
                        }
                    }
                }

	                Text {
	                    x: 0
	                    y: 160
	                    visible: root.activeNav === 0
	                    text: "レイアウト"
	                    color: root.c("textPrimary", "#4d3f63")
	                    font.family: root.uiFont
	                    font.pixelSize: 14
	                    font.weight: Font.Bold
	                    layer.enabled: root.fontGlowEnabled()
	                    layer.effect: FontGlowEffect {}
	                }

                Row {
                    id: layoutRow

                    x: 0
                    y: 190
                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 10

                    LayoutToggleButton {
                        width: 116
                        label: "左Classic"
                        active: root.theme ? root.theme.barPosition === "left" : true
                        onClicked: {
                            if (root.theme)
                                root.theme.setBarPosition("left")
                        }
                    }

                    LayoutToggleButton {
                        width: 116
                        label: "右Soft"
                        active: root.theme ? root.theme.barPosition === "right" : false
                        onClicked: {
                            if (root.theme)
                                root.theme.setBarPosition("right")
                        }
                    }

                    LayoutToggleButton {
                        width: 142
                        label: root.theme && root.theme.desktopFrameEnabled ? "枠 ON" : "枠 OFF"
                        active: root.theme ? root.theme.desktopFrameEnabled : true
                        onClicked: {
                            if (root.theme)
                                root.theme.setDesktopFrameEnabled(!root.theme.desktopFrameEnabled)
                        }
                    }
                }

                Text {
                    x: 0
                    y: 256
                    visible: root.activeNav === 0
                    text: "透明度"
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

	                Row {
	                    id: opacityRow

	                    x: 0
	                    y: 286
	                    width: mainArea.width
	                    visible: root.activeNav === 0
	                    spacing: 12

                    OpacityControl {
                        width: Math.floor((opacityRow.width - opacityRow.spacing * 4 - 74) / 4)
                        label: "全体"
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.sidebarOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(nextValue, nextValue, Math.max(root.theme.minOpacityForRole("card"), nextValue - 0.10))
                        }
                    }

                    OpacityControl {
                        width: Math.floor((opacityRow.width - opacityRow.spacing * 4 - 74) / 4)
                        label: "バー/ポップ"
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.sidebarOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(nextValue, nextValue, root.theme.cardOpacity)
                        }
                    }

                    OpacityControl {
                        width: Math.floor((opacityRow.width - opacityRow.spacing * 4 - 74) / 4)
                        label: "同期"
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.popupOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(nextValue, nextValue, root.theme.cardOpacity)
                        }
                    }

                    OpacityControl {
                        width: Math.floor((opacityRow.width - opacityRow.spacing * 4 - 74) / 4)
                        label: "カード"
                        minValue: root.theme ? root.theme.minOpacityForRole("card") : 0.25
                        value: root.theme ? root.theme.cardOpacity : 0.68
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(root.theme.sidebarOpacity, root.theme.sidebarOpacity, nextValue)
                        }
                    }

                    Rectangle {
                        id: resetOpacityButton

                        width: 74
                        height: 42
                        radius: 9
                        color: resetOpacityMouse.containsMouse
                            ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.16))
                            : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.34)
                        border.width: 1
                        border.color: resetOpacityMouse.containsMouse
                            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.62))
                            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.56)

                        Text {
                            anchors.centerIn: parent
                            text: "リセット"
                            color: root.c("textSecondary", "#8d7ca3")
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            layer.enabled: root.fontGlowEnabled()
                            layer.effect: FontGlowEffect {}
                        }

                        MouseArea {
                            id: resetOpacityMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.theme)
                                    root.theme.resetGlow()
                                if (root.theme)
                                    root.theme.resetBorderAccent()
                                if (root.theme)
                                    root.theme.resetOpacity()
                                root.noticeText = "Material restaurado."
                                noticeReset.restart()
                            }
                        }
                    }
                }

	                Text {
	                    x: 0
	                    y: 346
	                    visible: root.activeNav === 0
	                    text: "Glow"
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
	                    id: glowRow

	                    x: 0
	                    y: 376
	                    width: mainArea.width
                    visible: root.activeNav === 0

                    OpacityControl {
                        width: Math.min(260, glowRow.width)
                        label: "フォント"
                        minValue: 0
                        maxValue: 1
                        value: root.theme ? root.theme.textGlowLevel : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyTextGlow(nextValue)
                        }
                    }
                }

	                Text {
	                    x: 0
	                    y: 436
	                    visible: root.activeNav === 0
	                    text: "Borda"
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
	                    id: borderRow

	                    x: 0
	                    y: 466
	                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 14

                    BorderAdaptButton {
                        width: 116
                        active: root.theme ? root.theme.borderAdaptEnabled : true
                        onClicked: {
                            if (root.theme)
                                root.theme.applyBorderAccent(true, root.theme.borderHue)
                        }
                    }

                    BorderPaletteWheel {
                        width: 104
                        height: 104
                    }

                    Rectangle {
                        width: 220
                        height: 42
                        radius: 10
                        color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.30)
                        border.width: 1
                        border.color: root.theme ? root.theme.sidebarBorderGlow : root.accentPrimary()
                        antialiasing: true
                        layer.enabled: root.pywalStyle
                        layer.effect: DropShadow {
                            transparentBorder: true
                            radius: 22
                            samples: 45
                            horizontalOffset: 0
                            verticalOffset: 0
                            color: root.theme ? root.alpha(root.theme.sidebarBorderGlow, root.theme.sidebarBorderGlow.a * 0.34) : Qt.rgba(0, 0, 0, 0)
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 10
                                rightMargin: 10
                            }

                            height: 5
                            radius: 3
                            color: root.theme ? root.theme.sidebarBorderGlow : root.accentPrimary()
                        }
                    }
                }

                Text {
                    x: 0
                    y: 0
                    visible: root.activeNav === 1
                    text: "壁紙"
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Row {
                    id: wallpaperRow

                    x: 0
                    y: 34
                    visible: root.activeNav === 1
                    spacing: 13

                    Repeater {
                        model: Math.min(5, root.wallpapers.length)

                        WallpaperMini {
                            required property int index

                            width: Math.floor((mainArea.width - wallpaperRow.spacing * 4) / 5)
                            height: 88
                            source: root.displaySource(root.wallpapers[index])
                            selected: root.selectedIndex === index
                            onClicked: root.selectedIndex = index
                        }
                    }
                }

                Rectangle {
                    id: customButton

                    x: 0
                    y: 156
                    visible: root.activeNav === 1
                    width: 178
                    height: 42
                    radius: 8
                    color: customMouse.containsMouse
                        ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.16))
                        : root.c("buttonSecondaryBg", Qt.rgba(1, 1, 1, 0.58))
                    border.width: 1
                    border.color: customMouse.containsMouse
                        ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.62))
                        : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68))
                    scale: customMouse.pressed ? 0.97 : (customMouse.containsMouse ? 1.015 : 1.0)
                    antialiasing: true

                    Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 9

                        SmallIcon {
                            width: 17
                            height: 17
                            iconName: "folder"
                            colorOverride: root.c("textSecondary", "#8d7ca3")
                        }

                        Text {
                            text: "カスタム壁紙を選択"
                            color: root.c("buttonSecondaryText", "#6d5a82")
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        id: customMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.noticeText = "Pasta de wallpapers aberta."
                            noticeReset.restart()
                            if (!customWallpaperChooser.running)
                                customWallpaperChooser.running = true
                        }
                    }
                }

                Rectangle {
                    id: applyButton

                    x: mainArea.width - width
                    y: 156
                    visible: root.activeNav === 1
                    width: 132
                    height: 42
                    radius: 12
                    color: applyMouse.containsMouse
                        ? root.c("buttonPrimaryBg", root.accentPrimary())
                        : root.alpha(root.c("buttonPrimaryBg", root.accentPrimary()), 0.82)
                    scale: applyMouse.pressed ? 0.96 : (applyMouse.containsMouse ? 1.018 : 1.0)
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        radius: 20
                        samples: 41
                        horizontalOffset: 0
                        verticalOffset: 8
                        color: root.c("buttonPrimaryGlow", root.c("shadowColor", Qt.rgba(0.50, 0.28, 0.46, 0.15)))
                    }

                    Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: applyWallpaper.running ? "適用中..." : "適用する"
                        color: root.c("buttonPrimaryText", "#ffffff")
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

                Text {
                    x: 196
                    y: 168
                    visible: root.activeNav === 1
                    width: mainArea.width - 350
                    text: root.noticeText.length > 0 ? root.noticeText : (root.theme && root.theme.themeNotice.length > 0 ? root.theme.themeNotice : "")
                    color: root.c("textMuted", "#b7a9c7")
                    elide: Text.ElideRight
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
                }
            }

            Item {
                anchors.fill: parent
                visible: root.activeNav > 1

                Text {
                    anchors.centerIn: parent
                    text: "このセクションは次の段階で接続します"
                    color: root.c("textSecondary", "#8d7ca3")
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }
        }
    }

    component LayoutToggleButton: Rectangle {
        id: button

        property string label: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        height: 42
        radius: 9
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.34))
        border.width: 1
        border.color: active
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.72))
            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true
        scale: clickArea.pressed ? 0.97 : (hovered ? 1.012 : 1.0)

        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: clickArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component OpacityControl: Rectangle {
        id: control

        property string label: ""
        property real value: 0.70
        property real minValue: 0.25
        property real maxValue: 0.95
        signal moved(real value)

        height: 42
        radius: 9
        color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.34)
        border.width: 1
        border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true

        function valueFromX(xPos) {
            const span = Math.max(0.01, maxValue - minValue)
            return Math.max(minValue, Math.min(maxValue, minValue + (xPos - track.x) / Math.max(1, track.width) * span))
        }

        Text {
            x: 10
            y: 7
            text: control.label
            color: root.c("textPrimary", "#4d3f63")
            font.family: root.uiFont
            font.pixelSize: 10
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: 10
                top: parent.top
                topMargin: 7
            }

            text: root.percent(control.value)
            color: root.c("textMuted", "#b7a9c7")
            font.family: root.monoFont
            font.pixelSize: 10
            font.weight: Font.Medium
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        Rectangle {
            id: track

            x: 10
            y: 28
            width: parent.width - 20
            height: 4
            radius: 2
            color: root.alpha(root.c("textSecondary", "#8d7ca3"), 0.18)
        }

        Rectangle {
            x: track.x
            y: track.y
            width: Math.round(track.width * Math.max(0, Math.min(1, (control.value - control.minValue) / Math.max(0.01, control.maxValue - control.minValue))))
            height: track.height
            radius: track.radius
            color: root.accentPrimary()
        }

        Rectangle {
            x: Math.round(track.x + track.width * Math.max(0, Math.min(1, (control.value - control.minValue) / Math.max(0.01, control.maxValue - control.minValue))) - width / 2)
            y: track.y - 5
            width: 14
            height: 14
            radius: 7
            color: root.c("buttonPrimaryText", "#ffffff")
            border.width: 1
            border.color: root.alpha(root.accentPrimary(), 0.72)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) {
                mouse.accepted = true
                control.moved(control.valueFromX(mouse.x))
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    mouse.accepted = true
                    control.moved(control.valueFromX(mouse.x))
                }
            }
        }
    }

    component BorderAdaptButton: Rectangle {
        id: button

        property bool active: true
        property bool hovered: false
        signal clicked()

        height: 42
        radius: 10
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.30))
        border.width: 1
        border.color: active && root.theme ? root.theme.sidebarBorderGlow : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: "Adaptar"
            color: root.c("textPrimary", "#4d3f63")
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
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

    component BorderPaletteWheel: Item {
        id: wheel

        readonly property real selectedHue: root.theme ? root.theme.borderHue : 0.55
        readonly property color selectedColor: root.theme ? root.theme.sidebarBorderGlow : root.accentPrimary()
        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real outerRadius: Math.min(width, height) / 2 - 3
        readonly property real dotRadius: outerRadius * 0.78

        function applyFromPoint(xPos, yPos) {
            if (!root.theme)
                return

            const dx = xPos - centerX
            const dy = yPos - centerY
            const hue = (Math.atan2(dy, dx) / (Math.PI * 2) + 1) % 1
            root.theme.applyBorderAccent(false, hue)
        }

        Canvas {
            id: wheelCanvas

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d")
                const cx = width / 2
                const cy = height / 2
                const r = Math.min(width, height) / 2 - 3
                ctx.clearRect(0, 0, width, height)

                for (let i = 0; i < 96; i += 1) {
                    const start = i / 96 * Math.PI * 2
                    const end = (i + 1.4) / 96 * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, r, start, end)
                    ctx.closePath()
                    ctx.fillStyle = root.theme ? root.theme.hsvColor(i / 96, 0.82, 1.0, 1) : Qt.rgba(1, 1, 1, 1)
                    ctx.fill()
                }

                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.38, 0, Math.PI * 2)
                ctx.fillStyle = root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.58)
                ctx.fill()
            }
        }

        Rectangle {
            x: Math.round(wheel.centerX + Math.cos(wheel.selectedHue * Math.PI * 2) * wheel.dotRadius - width / 2)
            y: Math.round(wheel.centerY + Math.sin(wheel.selectedHue * Math.PI * 2) * wheel.dotRadius - height / 2)
            width: 14
            height: 14
            radius: 7
            color: wheel.selectedColor
            border.width: 2
            border.color: root.c("buttonPrimaryText", "#ffffff")
            antialiasing: true
        }

        Rectangle {
            anchors.centerIn: parent
            width: 24
            height: 24
            radius: 12
            color: root.theme && root.theme.borderAdaptEnabled ? root.theme.accentPrimary : wheel.selectedColor
            border.width: 2
            border.color: root.alpha(root.c("buttonPrimaryText", Qt.rgba(1, 1, 1, 1)), 0.84)
            antialiasing: true
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) {
                mouse.accepted = true
                wheel.applyFromPoint(mouse.x, mouse.y)
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    mouse.accepted = true
                    wheel.applyFromPoint(mouse.x, mouse.y)
                }
            }
        }

        Connections {
            target: root.theme
            function onBorderHueChanged() { wheelCanvas.requestPaint() }
            function onBorderAdaptEnabledChanged() { wheelCanvas.requestPaint() }
            function onAccentPrimaryChanged() { wheelCanvas.requestPaint() }
        }

        Component.onCompleted: wheelCanvas.requestPaint()
        onWidthChanged: wheelCanvas.requestPaint()
        onHeightChanged: wheelCanvas.requestPaint()
    }

    component SettingsNavItem: Rectangle {
        id: item

        property var itemData
        property bool active: false
        property bool hovered: false
        signal clicked()

        height: 54
        radius: 8
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : "transparent")
        border.width: active ? 1 : 0
        border.color: root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.45))
        antialiasing: true

        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 16
            spacing: 12

            SmallIcon {
                width: 21
                height: 21
                iconName: item.itemData.icon
                colorOverride: item.active
                    ? root.accentPrimary()
                    : root.c("textSecondary", "#8d7ca3")
            }

            Text {
                text: item.itemData.label
                color: item.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
                font.family: root.uiFont
                font.pixelSize: 13
                font.weight: Font.Bold
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: item.hovered = true
            onExited: item.hovered = false
            onClicked: item.clicked()
        }
    }

    component ThemeCard: Item {
        id: card

        property var itemData
        property bool selected: false
        property bool hovered: false
        signal clicked()

        scale: mouse.pressed ? 0.96 : (hovered ? 1.02 : 1.0)
        transformOrigin: Item.Center

        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Rectangle {
            id: preview

            width: parent.width
            height: 86
            radius: 8
            color: root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68))
            border.width: card.selected ? 2 : 1
            border.color: card.selected
                ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.76))
                : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.58))
            clip: true
            antialiasing: true
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: card.hovered || card.selected ? 18 : 10
                samples: card.hovered || card.selected ? 37 : 21
                horizontalOffset: 0
                verticalOffset: card.hovered || card.selected ? 7 : 4
                color: root.c("shadowColor", Qt.rgba(0.46, 0.28, 0.48, card.hovered || card.selected ? 0.14 : 0.07))
            }

            Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ThemePreview {
                anchors.fill: parent
                anchors.margins: 7
                kind: card.itemData.preview
            }

            Rectangle {
                visible: card.selected
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: -5
                    topMargin: -5
                }

                width: 26
                height: 26
                radius: 13
                color: root.accentPrimary()
                border.width: 1
                border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.65)), 0.86)

                CheckIcon {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    colorOverride: root.c("buttonPrimaryText", "#ffffff")
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 96
            text: card.itemData.title
            color: card.selected ? root.accentPrimary() : root.c("textPrimary", "#4d3f63")
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: card.clicked()
        }
    }

    component WallpaperMini: Rectangle {
        id: card

        property string source: ""
        property bool selected: false
        property bool hovered: false
        signal clicked()

        radius: 8
        color: root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68))
        border.width: selected ? 2 : 1
        border.color: selected
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.78))
            : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.52))
        clip: true
        antialiasing: true
        scale: mouse.pressed ? 0.97 : (hovered ? 1.02 : 1.0)
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: hovered || selected ? 18 : 10
            samples: hovered || selected ? 37 : 21
            horizontalOffset: 0
            verticalOffset: hovered || selected ? 7 : 4
            color: root.c("shadowColor", Qt.rgba(0.38, 0.25, 0.44, hovered || selected ? 0.13 : 0.06))
        }

        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Image {
            anchors.fill: parent
            anchors.margins: 1
            source: card.source
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 260
            sourceSize.height: 170
            asynchronous: true
            smooth: true
            mipmap: true
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: hovered ? root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.12) : "transparent"
        }

        Rectangle {
            visible: selected
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: -5
                topMargin: -5
            }

            width: 26
            height: 26
            radius: 13
            color: root.accentPrimary()
            border.width: 1
            border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.65)), 0.84)

            CheckIcon {
                anchors.centerIn: parent
                width: 12
                height: 12
                colorOverride: root.c("buttonPrimaryText", "#ffffff")
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: card.clicked()
        }
    }

    component ThemePreview: Item {
        id: preview

        property string kind: "default"
        readonly property color baseColor: kind === "dark"
            ? Qt.rgba(0.12, 0.11, 0.16, 1)
            : kind === "pink"
                ? Qt.rgba(1, 0.82, 0.90, 1)
                : kind === "lavender"
                    ? Qt.rgba(0.88, 0.82, 1, 1)
                    : kind === "pywal16"
                        ? Qt.rgba(0.92, 0.94, 0.98, 1)
                        : Qt.rgba(1, 0.96, 0.99, 1)

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: preview.baseColor
        }

        Repeater {
            model: preview.kind === "pywal16" ? ["#e8a6c8", "#c894f2", "#a8d8ff", "#f4c56f", "#8fd6b8", "#6f7ea9"] : []

            Rectangle {
                required property int index
                required property string modelData

                x: 10 + (index % 3) * 23
                y: 13 + Math.floor(index / 3) * 24
                width: 17
                height: 17
                radius: 5
                color: modelData
            }
        }

        Rectangle {
            visible: preview.kind !== "pywal16"
            x: 10
            y: 12
            width: 21
            height: 52
            radius: 6
            color: preview.kind === "dark" ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.55)
        }

        Repeater {
            model: preview.kind !== "pywal16" ? 4 : 0

            Rectangle {
                required property int index

                x: 42 + (index % 2) * 28
                y: 14 + Math.floor(index / 2) * 25
                width: 22
                height: 18
                radius: 5
                color: preview.kind === "dark"
                    ? Qt.rgba(1, 1, 1, 0.12)
                    : Qt.rgba(1, 1, 1, 0.68)
                border.width: 1
                border.color: preview.kind === "pink"
                    ? Qt.rgba(0.95, 0.50, 0.70, 0.22)
                    : preview.kind === "lavender"
                        ? Qt.rgba(0.58, 0.42, 0.88, 0.22)
                        : Qt.rgba(1, 1, 1, 0.28)
            }
        }

        Text {
            visible: preview.kind === "pywal16"
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: 8
                bottomMargin: 7
            }

            text: "auto"
            color: root.c("textSecondary", "#8d7ca3")
            font.family: root.monoFont
            font.pixelSize: 9
            font.weight: Font.Bold
        }
    }

    component SmallIcon: Canvas {
        id: icon

        property string iconName: "palette"
        property color colorOverride: root.c("textSecondary", "#8d7ca3")

        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            const s = Math.min(w, h)
            const cx = w / 2
            const cy = h / 2
            ctx.reset()
            ctx.strokeStyle = colorOverride
            ctx.fillStyle = colorOverride
            ctx.lineWidth = Math.max(1.4, s * 0.09)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconName === "palette") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.36, Math.PI * 0.15, Math.PI * 1.95, false)
                ctx.quadraticCurveTo(s * 0.34, s * 0.92, s * 0.44, s * 0.67)
                ctx.stroke()
                for (let i = 0; i < 3; i += 1) {
                    ctx.beginPath()
                    ctx.arc(s * (0.35 + i * 0.15), s * (0.38 + (i % 2) * 0.12), s * 0.035, 0, Math.PI * 2)
                    ctx.fill()
                }
            } else if (iconName === "image" || iconName === "folder") {
                ctx.strokeRect(s * 0.14, s * 0.24, s * 0.72, s * 0.52)
                ctx.beginPath()
                ctx.moveTo(s * 0.20, s * 0.66)
                ctx.lineTo(s * 0.38, s * 0.50)
                ctx.lineTo(s * 0.52, s * 0.62)
                ctx.lineTo(s * 0.68, s * 0.44)
                ctx.lineTo(s * 0.82, s * 0.66)
                ctx.stroke()
            } else if (iconName === "puzzle") {
                ctx.strokeRect(s * 0.22, s * 0.24, s * 0.52, s * 0.52)
                ctx.beginPath()
                ctx.arc(s * 0.50, s * 0.24, s * 0.10, 0, Math.PI * 2)
                ctx.stroke()
            } else if (iconName === "cursor") {
                ctx.beginPath()
                ctx.moveTo(s * 0.22, s * 0.14)
                ctx.lineTo(s * 0.70, s * 0.54)
                ctx.lineTo(s * 0.48, s * 0.60)
                ctx.lineTo(s * 0.38, s * 0.82)
                ctx.closePath()
                ctx.stroke()
            } else if (iconName === "font") {
                ctx.beginPath()
                ctx.moveTo(s * 0.24, s * 0.76)
                ctx.lineTo(s * 0.46, s * 0.22)
                ctx.lineTo(s * 0.68, s * 0.76)
                ctx.moveTo(s * 0.34, s * 0.56)
                ctx.lineTo(s * 0.58, s * 0.56)
                ctx.stroke()
            }
        }

        onColorOverrideChanged: requestPaint()
        onIconNameChanged: requestPaint()
    }

    component CheckIcon: Canvas {
        id: check

        property color colorOverride: "white"

        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            ctx.reset()
            ctx.strokeStyle = colorOverride
            ctx.lineWidth = Math.max(1.7, s * 0.16)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(s * 0.18, s * 0.52)
            ctx.lineTo(s * 0.40, s * 0.72)
            ctx.lineTo(s * 0.82, s * 0.25)
            ctx.stroke()
        }

        onColorOverrideChanged: requestPaint()
    }
}
