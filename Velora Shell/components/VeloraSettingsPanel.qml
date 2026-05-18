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
    property string attachSide: "left"
    readonly property int cornerRadius: 18
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property string uiFont: "Noto Sans CJK JP"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string applyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string zenLiveScript: Quickshell.shellDir + "/scripts/velora-zen-live-apply"
    readonly property var navItems: [
        { key: "theme", icon: "palette" },
        { key: "wallpaper", icon: "image" },
        { key: "language", icon: "language" }
    ]
    readonly property var fallbackLanguageOptions: [
        { id: "ja", label: "日本語", shortLabel: "JP" },
        { id: "en", label: "English", shortLabel: "EN" },
        { id: "pt-BR", label: "Português Brasil", shortLabel: "BR" }
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
    property bool zenAutoRestart: true
    property bool open: visible
    property bool loadedOnce: false
    property bool scanComplete: false
    readonly property bool contentActive: visible || open || revealProgress > 0.01
    property real revealProgress: 0
    readonly property int motionPanelIn: theme ? theme.motionPanelIn : 220
    readonly property int motionPanelOut: theme ? theme.motionPanelOut : 140
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionPanelOffset: theme ? theme.motionPanelOffset : 28
    readonly property int motionEaseEnter: theme ? theme.motionEaseEnter : Easing.OutCubic
    readonly property int motionEaseExit: theme ? theme.motionEaseExit : Easing.InCubic
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic

    signal closeRequested()

    opacity: revealProgress
    scale: 0.992 + revealProgress * 0.008
    transformOrigin: attachSide === "right" ? Item.Right : Item.Left
    focus: visible
    activeFocusOnTab: true

    transform: Translate {
        x: Math.round((1 - root.revealProgress) * (root.attachSide === "right" ? root.motionPanelOffset : -root.motionPanelOffset))
        y: Math.round((1 - root.revealProgress) * 6)
    }

    onOpenChanged: {
        animateReveal()
        if (open)
            ensureLoaded()
    }
    onVisibleChanged: {
        if (visible && open && revealProgress <= 0.001)
            animateReveal()
        if (visible && open)
            ensureLoaded()
    }

    function animateReveal() {
        revealAnimation.stop()
        revealAnimation.from = revealProgress
        revealAnimation.to = open ? 1 : 0
        revealAnimation.duration = open ? motionPanelIn : motionPanelOut
        revealAnimation.restart()
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

    Component.onCompleted: {
        if (open)
            ensureLoaded()
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

    function tr(key) {
        const lang = root.theme ? root.theme.language : "ja"
        const texts = {
            "ja": {
                "nav_theme": "テーマ",
                "nav_wallpaper": "壁紙",
                "nav_language": "言語",
                "themeStyle": "テーマスタイル",
                "layout": "レイアウト",
                "frameOn": "枠 ON",
                "frameOff": "枠 OFF",
                "opacity": "透明度",
                "opacityAll": "全体",
                "opacityBar": "バー",
                "opacityPanel": "パネル",
                "opacitySync": "同期",
                "opacityCard": "カード",
                "reset": "リセット",
                "materialReset": "マテリアルを復元しました。",
                "glow": "グロー",
                "fontGlow": "フォント",
                "border": "ボーダー",
                "visualizer": "ビジュアライザー",
                "visualizerStrength": "強さ",
                "adapt": "自動",
                "zenRestartOn": "Zen 自動 ON",
                "zenRestartOff": "Zen 自動 OFF",
                "zenRestartOnNotice": "Zen の自動再起動を有効にしました。",
                "zenRestartOffNotice": "Zen の自動再起動を停止しました。",
                "wallpaper": "壁紙",
                "customWallpaper": "カスタム壁紙を選択",
                "applying": "適用中...",
                "apply": "適用する",
                "wallpaperFolderOpened": "壁紙フォルダを開きました。",
                "language": "言語",
                "languageHint": "パネルとサイドバーの表示言語。",
                "languageApplied": "言語を適用: "
            },
            "en": {
                "nav_theme": "Theme",
                "nav_wallpaper": "Wallpaper",
                "nav_language": "Language",
                "themeStyle": "Theme Style",
                "layout": "Layout",
                "frameOn": "Frame ON",
                "frameOff": "Frame OFF",
                "opacity": "Opacity",
                "opacityAll": "Global",
                "opacityBar": "Bar",
                "opacityPanel": "Panels",
                "opacitySync": "Sync",
                "opacityCard": "Cards",
                "reset": "Reset",
                "materialReset": "Material reset.",
                "glow": "Glow",
                "fontGlow": "Font",
                "border": "Border",
                "visualizer": "Visualizer",
                "visualizerStrength": "Strength",
                "adapt": "Adapt",
                "zenRestartOn": "Zen auto ON",
                "zenRestartOff": "Zen auto OFF",
                "zenRestartOnNotice": "Zen auto restart enabled.",
                "zenRestartOffNotice": "Zen auto restart disabled.",
                "wallpaper": "Wallpaper",
                "customWallpaper": "Choose wallpaper folder",
                "applying": "Applying...",
                "apply": "Apply",
                "wallpaperFolderOpened": "Wallpaper folder opened.",
                "language": "Language",
                "languageHint": "Panel and sidebar interface.",
                "languageApplied": "Language applied: "
            },
            "pt-BR": {
                "nav_theme": "Tema",
                "nav_wallpaper": "Papel de parede",
                "nav_language": "Idioma",
                "themeStyle": "Estilo do tema",
                "layout": "Layout",
                "frameOn": "Moldura ON",
                "frameOff": "Moldura OFF",
                "opacity": "Transparência",
                "opacityAll": "Geral",
                "opacityBar": "Barra",
                "opacityPanel": "Painéis",
                "opacitySync": "Sincronizar",
                "opacityCard": "Cards",
                "reset": "Resetar",
                "materialReset": "Material restaurado.",
                "glow": "Glow",
                "fontGlow": "Fonte",
                "border": "Borda",
                "visualizer": "Visualizer",
                "visualizerStrength": "Força",
                "adapt": "Adaptar",
                "zenRestartOn": "Zen auto ON",
                "zenRestartOff": "Zen auto OFF",
                "zenRestartOnNotice": "Reinício automático do Zen ativado.",
                "zenRestartOffNotice": "Reinício automático do Zen desativado.",
                "wallpaper": "Papel de parede",
                "customWallpaper": "Escolher pasta de wallpapers",
                "applying": "Aplicando...",
                "apply": "Aplicar",
                "wallpaperFolderOpened": "Pasta de wallpapers aberta.",
                "language": "Idioma",
                "languageHint": "Interface do painel e da barra lateral.",
                "languageApplied": "Idioma aplicado: "
            }
        }
        const table = texts[lang] || texts["ja"]
        return table[key] || texts["ja"][key] || key
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

    function languageOptions() {
        return root.theme ? root.theme.languageOptions : root.fallbackLanguageOptions
    }

    function currentLanguage() {
        return root.theme ? root.theme.language : "ja"
    }

    function currentLanguageIndex() {
        const options = root.languageOptions()
        for (let i = 0; i < options.length; i += 1) {
            if (options[i].id === root.currentLanguage())
                return i
        }
        return 0
    }

    function selectLanguage(id) {
        const options = root.languageOptions()
        var label = id
        for (let i = 0; i < options.length; i += 1) {
            if (options[i].id === id) {
                label = options[i].label
                break
            }
        }
        if (root.theme)
            root.theme.setLanguage(id)
        root.noticeText = root.tr("languageApplied") + label
        noticeReset.restart()
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
        if (root.activeNav === 2) {
            const options = root.languageOptions()
            if (options.length <= 0)
                return
            const nextIndex = (root.currentLanguageIndex() + dir + options.length) % options.length
            root.selectLanguage(options[nextIndex].id)
            return
        }

        if (root.activeNav !== 1)
            return

        const count = root.wallpapers.length
        if (count <= 0)
            return
        root.selectedIndex = (root.selectedIndex + dir + count) % count
    }

    function applySelected() {
        if (root.activeNav !== 1)
            return
        if (applyWallpaper.running)
            return
        const item = root.currentWallpaper()
        applyWallpaper.command = [root.applyScript, item.kind || "static", item.path, root.displaySource(item)]
        applyWallpaper.running = true
    }

    function setZenAutoRestart(enabled) {
        root.zenAutoRestart = enabled
        if (!zenModeSave.running) {
            zenModeSave.command = [root.zenLiveScript, "mode", "set", enabled ? "restart" : "off"]
            zenModeSave.running = true
        } else {
            zenModeSave.pendingMode = enabled ? "restart" : "off"
        }

        root.noticeText = enabled ? root.tr("zenRestartOnNotice") : root.tr("zenRestartOffNotice")
        noticeReset.restart()
    }

    function reload() {
        if (!scanWallpapers.running)
            scanWallpapers.running = true
    }

    function ensureLoaded() {
        if (loadedOnce)
            return

        loadedOnce = true
        reload()
        if (!zenModeLoad.running)
            zenModeLoad.running = true
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
        id: zenModeLoad

        running: false
        command: [root.zenLiveScript, "mode", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                root.zenAutoRestart = String(data || "").trim() !== "off"
            }
        }

        onExited: running = false
    }

    Process {
        id: zenModeSave

        property string pendingMode: ""
        running: false
        command: [root.zenLiveScript, "mode", "set", "restart"]
        onExited: {
            running = false
            if (pendingMode.length > 0) {
                const next = pendingMode
                pendingMode = ""
                command = [root.zenLiveScript, "mode", "set", next]
                running = true
            }
        }
    }

    Process {
        id: scanWallpapers

        running: false
        property var tmp: []
        command: [root.scanScript]

        onStarted: {
            tmp = []
            root.scanComplete = false
        }

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
                root.scanComplete = true
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
            x: 200
            y: 0
            width: 1
            height: parent.height
            color: root.alpha(root.c("borderActive", Qt.rgba(232 / 255, 166 / 255, 200 / 255, 1)), 0.16)
        }

        Column {
            id: navColumn

            x: 22
            y: 26
            width: 154
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

            x: 230
            y: 35
            width: parent.width - x - 34
            height: parent.height - 62

            Flickable {
                id: mainFlick

                anchors.fill: parent
                visible: root.activeNav <= 2
                clip: true
                contentWidth: width
                contentHeight: root.activeNav === 0 ? 780 : height
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    id: mainContent

                    width: mainFlick.width
                    height: mainFlick.contentHeight

                Text {
                    x: 0
                    y: 0
                    visible: root.activeNav === 0
                    text: root.tr("themeStyle")
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
	                    text: root.tr("layout")
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

                    LayoutPreviewButton {
                        width: 104
                        side: "left"
                        active: root.theme ? root.theme.barPosition === "left" : true
                        onClicked: {
                            if (root.theme)
                                root.theme.setBarPosition("left")
                        }
                    }

                    LayoutPreviewButton {
                        width: 104
                        side: "right"
                        active: root.theme ? root.theme.barPosition === "right" : false
                        onClicked: {
                            if (root.theme)
                                root.theme.setBarPosition("right")
                        }
                    }

                    LayoutToggleButton {
                        width: 142
                        label: root.theme && root.theme.desktopFrameEnabled ? root.tr("frameOn") : root.tr("frameOff")
                        active: root.theme ? root.theme.desktopFrameEnabled : true
                        onClicked: {
                            if (root.theme)
                                root.theme.setDesktopFrameEnabled(!root.theme.desktopFrameEnabled)
                        }
                    }

                    LayoutToggleButton {
                        width: 154
                        label: root.zenAutoRestart ? root.tr("zenRestartOn") : root.tr("zenRestartOff")
                        active: root.zenAutoRestart
                        onClicked: root.setZenAutoRestart(!root.zenAutoRestart)
                    }
                }

                Text {
                    x: 0
                    y: 256
                    visible: root.activeNav === 0
                    text: root.tr("opacity")
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
                        property int resetWidth: 74
                        property int controlCount: 4
                        property int controlWidth: Math.floor((width - spacing * controlCount - resetWidth) / controlCount)

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacityAll")
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.sidebarOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme) {
                                root.theme.applyOpacity(nextValue, nextValue, Math.max(root.theme.minOpacityForRole("card"), nextValue - 0.10))
                                root.theme.applyBarOpacity(nextValue)
                            }
                        }
                    }

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacityPanel")
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.sidebarOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(nextValue, nextValue, root.theme.cardOpacity)
                        }
                    }

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacitySync")
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.popupOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(nextValue, nextValue, root.theme.cardOpacity)
                        }
                    }

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacityCard")
                        minValue: root.theme ? root.theme.minOpacityForRole("card") : 0.25
                        value: root.theme ? root.theme.cardOpacity : 0.68
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(root.theme.sidebarOpacity, root.theme.sidebarOpacity, nextValue)
                        }
                    }

                    Rectangle {
                        id: resetOpacityButton

                        width: opacityRow.resetWidth
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
                            text: root.tr("reset")
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
                                if (root.theme)
                                    root.theme.resetVisualizerStrength()
                                root.noticeText = root.tr("materialReset")
                                noticeReset.restart()
                            }
                        }
	                    }
	                }

                Row {
                    id: barOpacityRow

                    x: 0
                    y: 346
                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 12

                    OpacityControl {
                        width: Math.min(280, barOpacityRow.width)
                        label: root.tr("opacityBar")
                        minValue: root.theme ? root.theme.minOpacityForRole("sidebar") : 0.25
                        maxValue: 0.98
                        value: root.theme ? root.theme.barOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyBarOpacity(nextValue)
                        }
                    }
                }

                Text {
                    x: 0
                    y: 656
                    visible: root.activeNav === 0
                    text: root.tr("visualizer")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
                    id: visualizerRow

                    x: 0
                    y: 686
                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 12

                    OpacityControl {
                        width: Math.min(280, visualizerRow.width)
                        label: root.tr("visualizerStrength")
                        minValue: 0.20
                        maxValue: 0.90
                        value: root.theme ? root.theme.visualizerStrength : 0.46
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.setVisualizerStrength(nextValue)
                        }
                    }
                }

                Text {
                    x: 0
	                    y: 406
	                    visible: root.activeNav === 0
	                    text: root.tr("glow")
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
	                    y: 436
	                    width: mainArea.width
                    visible: root.activeNav === 0

                    OpacityControl {
                        width: Math.min(260, glowRow.width)
                        label: root.tr("fontGlow")
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
	                    y: 496
	                    visible: root.activeNav === 0
	                    text: root.tr("border")
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
	                    y: 526
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
                    text: root.tr("wallpaper")
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
                            source: root.contentActive && root.scanComplete ? root.displaySource(root.wallpapers[index]) : ""
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
                    width: 242
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

                    Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
                    Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

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
                            text: root.tr("customWallpaper")
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
                            root.noticeText = root.tr("wallpaperFolderOpened")
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
                    scale: applyMouse.pressed ? 0.96 : (applyMouse.containsMouse ? 1.012 : 1.0)
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        radius: 20
                        samples: 41
                        horizontalOffset: 0
                        verticalOffset: 8
                        color: root.c("buttonPrimaryGlow", root.c("shadowColor", Qt.rgba(0.50, 0.28, 0.46, 0.15)))
                    }

                    Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
                    Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

                    Text {
                        anchors.centerIn: parent
                        text: applyWallpaper.running ? root.tr("applying") : root.tr("apply")
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
                    x: 0
                    y: 214
                    visible: root.activeNav === 1
                    width: mainArea.width
                    text: root.noticeText.length > 0 ? root.noticeText : (root.theme && root.theme.themeNotice.length > 0 ? root.theme.themeNotice : "")
                    color: root.c("textMuted", "#b7a9c7")
                    elide: Text.ElideRight
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                Text {
                    x: 0
                    y: 0
                    visible: root.activeNav === 2
                    text: root.tr("language")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Text {
                    x: 0
                    y: 28
                    visible: root.activeNav === 2
                    width: mainArea.width
                    text: root.tr("languageHint")
                    color: root.c("textMuted", "#b7a9c7")
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
                    id: languageRow

                    x: 0
                    y: 72
                    width: mainArea.width
                    visible: root.activeNav === 2
                    spacing: 14

                    Repeater {
                        model: root.languageOptions()

                        LanguageButton {
                            required property var modelData

                            width: Math.floor((languageRow.width - languageRow.spacing * 2) / 3)
                            itemData: modelData
                            active: root.currentLanguage() === modelData.id
                            onClicked: root.selectLanguage(modelData.id)
                        }
                    }
                }

                Text {
                    x: 0
                    y: 162
                    visible: root.activeNav === 2
                    width: mainArea.width
                    text: root.noticeText
                    color: root.c("textMuted", "#b7a9c7")
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }
                }
            }

            Item {
                anchors.fill: parent
                visible: root.activeNav > 2

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

    component LayoutPreviewButton: Rectangle {
        id: button

        property string side: "left"
        property bool active: false
        property bool hovered: false
        readonly property bool rightSide: side === "right"
        signal clicked()

        height: 58
        radius: 10
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.30))
        border.width: 1
        border.color: active
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.72))
            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true
        scale: previewMouse.pressed ? 0.97 : (hovered ? 1.012 : 1.0)

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Rectangle {
            id: previewScreen

            anchors {
                fill: parent
                margins: 9
            }

            radius: 6
            color: root.alpha(root.c("surfaceBase", Qt.rgba(1, 1, 1, 0.72)), 0.36)
            border.width: 1
            border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.38)
            clip: true
            antialiasing: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.22)
                antialiasing: true
            }

            Rectangle {
                width: 13
                height: parent.height - 8
                x: button.rightSide ? parent.width - width - 4 : 4
                y: 4
                radius: 6
                color: root.alpha(root.c("surfaceSidebar", Qt.rgba(1, 1, 1, 0.78)), button.active ? 0.96 : 0.74)
                border.width: 1
                border.color: button.active ? root.accentPrimary() : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.46)
                antialiasing: true

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: 4

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: index === 0 ? root.accentPrimary() : root.alpha(root.c("textSecondary", "#8d7ca3"), 0.55)
                        }
                    }
                }
            }

            Rectangle {
                x: button.rightSide ? 6 : 21
                y: 9
                width: Math.max(10, parent.width - 34)
                height: 3
                radius: 2
                color: root.alpha(root.c("textSecondary", "#8d7ca3"), 0.22)
            }

            Rectangle {
                x: button.rightSide ? 6 : 21
                y: 17
                width: Math.max(10, parent.width - 44)
                height: 18
                radius: 4
                color: root.alpha(root.accentSecondary(), button.active ? 0.24 : 0.12)
            }
        }

        MouseArea {
            id: previewMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
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

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

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

    component LanguageButton: Rectangle {
        id: button

        property var itemData
        property bool active: false
        property bool hovered: false
        signal clicked()

        height: 72
        radius: 10
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.32))
        border.width: 1
        border.color: active
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.72))
            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true
        scale: languageMouse.pressed ? 0.97 : (hovered ? 1.012 : 1.0)

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Rectangle {
            x: 12
            y: 14
            width: 34
            height: 34
            radius: 17
            color: button.active ? root.alpha(root.accentPrimary(), 0.32) : root.alpha(root.c("surfaceInput", Qt.rgba(1, 1, 1, 0.58)), 0.52)
            border.width: 1
            border.color: button.active ? root.accentPrimary() : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.48)
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: button.itemData.shortLabel || ""
                color: button.active ? root.accentPrimary() : root.c("textSecondary", "#8d7ca3")
                font.family: root.monoFont
                font.pixelSize: 11
                font.weight: Font.Bold
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        Text {
            x: 56
            y: 18
            width: parent.width - x - 12
            text: button.itemData.label || ""
            color: button.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
            font.family: root.uiFont
            font.pixelSize: 13
            font.weight: Font.Bold
            elide: Text.ElideRight
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: languageMouse

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

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Text {
            anchors.centerIn: parent
            text: root.tr("adapt")
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
        scale: hovered ? 1.006 : 1.0
        transform: Translate {
            x: item.hovered || item.active ? 1 : 0
        }
        color: active
            ? root.alpha(root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28)), 0.58)
            : (hovered ? root.alpha(root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)), 0.36) : "transparent")
        border.width: 1
        border.color: active
            ? root.alpha(root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.45)), 0.62)
            : (hovered ? root.alpha(root.accentPrimary(), 0.18) : "transparent")
        antialiasing: true
        layer.enabled: false
        layer.effect: DropShadow {
            transparentBorder: true
            radius: hovered ? 24 : 17
            samples: hovered ? 49 : 35
            horizontalOffset: 0
            verticalOffset: hovered ? 7 : 4
            color: root.alpha(root.c("shadowColor", Qt.rgba(0.28, 0.20, 0.34, 1)), hovered ? 0.20 : 0.12)
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

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
                width: item.width - 52
                text: root.tr("nav_" + item.itemData.key)
                color: item.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
                font.family: root.uiFont
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
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

        scale: mouse.pressed ? 0.96 : (hovered ? 1.012 : 1.0)
        transformOrigin: Item.Center

        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

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

            Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

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
        scale: mouse.pressed ? 0.97 : (hovered ? 1.012 : 1.0)
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: hovered || selected ? 18 : 10
            samples: hovered || selected ? 37 : 21
            horizontalOffset: 0
            verticalOffset: hovered || selected ? 7 : 4
            color: root.c("shadowColor", Qt.rgba(0.38, 0.25, 0.44, hovered || selected ? 0.13 : 0.06))
        }

        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Image {
            anchors.fill: parent
            anchors.margins: 1
            source: root.contentActive ? card.source : ""
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
            } else if (iconName === "language") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.35, 0, Math.PI * 2)
                ctx.moveTo(cx - s * 0.35, cy)
                ctx.lineTo(cx + s * 0.35, cy)
                ctx.moveTo(cx, cy - s * 0.35)
                ctx.bezierCurveTo(cx - s * 0.16, cy - s * 0.12, cx - s * 0.16, cy + s * 0.12, cx, cy + s * 0.35)
                ctx.moveTo(cx, cy - s * 0.35)
                ctx.bezierCurveTo(cx + s * 0.16, cy - s * 0.12, cx + s * 0.16, cy + s * 0.12, cx, cy + s * 0.35)
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
