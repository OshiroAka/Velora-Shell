import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower

Item {
    id: root

    property var theme: null
    property alias maskItem: surface
    property string clockText: Qt.formatDateTime(new Date(), "HH:mm")
    property string dateText: formatLocalizedDate(new Date())
    property var batteryDevice: null
    property int volume: 70
    property bool muted: false
    property int notificationCount: 0
    property int notificationCountOverride: -1
    property string activePopupType: ""
    readonly property int effectiveNotificationCount: notificationCountOverride >= 0 ? notificationCountOverride : notificationCount
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property color glass: theme ? theme.alpha(theme.surfaceSidebar, 0.72) : Qt.rgba(0.050, 0.070, 0.045, 0.72)
    readonly property color card: Qt.rgba(1, 1, 1, 0.065)
    readonly property color cardHover: Qt.rgba(1, 1, 1, 0.13)
    readonly property color cardActive: Qt.rgba(0.30, 0.58, 0.66, 0.74)
    readonly property color ink: theme ? theme.textPrimary : "#fbf8f2"
    readonly property color inkSoft: theme ? theme.alpha(theme.textSecondary, 0.86) : "#d5d1c8"
    readonly property color mutedInk: theme ? theme.alpha(theme.textMuted, 0.78) : "#aaa59c"
    readonly property color accent: theme ? theme.accentPrimary : "#8ccdd9"
    readonly property color accent2: theme ? theme.activeText : "#f3eee6"
    readonly property color pink: theme ? (theme.themeId === "pywal16" ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.45, 0.66, 0.86)
    readonly property color lilac: theme ? (theme.themeId === "pywal16" ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.47, 0.76, 0.78)
    readonly property real configuredIconScale: theme ? Math.max(0.72, Math.min(1.18, theme.barIconSize / 48.0)) : 1.0
    readonly property real configuredIconOpacity: theme ? theme.barIconOpacity : 0.80
    readonly property real configuredIconGap: theme ? theme.barIconSpacing : 16
    readonly property int topControlHeight: Math.round(32 * configuredIconScale)
    readonly property int topIconButtonSize: topControlHeight
    readonly property int topIconCanvasSize: Math.round(19 * configuredIconScale)
    readonly property int utilityButtonWidth: Math.round(26 * configuredIconScale)
    readonly property int utilityIconSize: Math.round(17 * configuredIconScale)
    readonly property int workspaceButtonWidth: Math.round(37 * configuredIconScale)
    readonly property int topButtonGap: Math.round(Math.max(8, Math.min(18, configuredIconGap * 0.62)))
    readonly property int topBarVerticalMargin: Math.max(5, Math.round(7 - (configuredIconScale - 1) * 4))
    readonly property int sectionInset: 34
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionNormal: theme ? theme.motionNormal : 200

    signal searchRequested(real centerX)
    signal themeRequested(real centerX)
    signal settingsRequested(real centerX)
    signal layoutRequested(real centerX)
    signal quickPopupRequested(string popupType, real centerX)
    signal quickPopupHovered(string popupType, real centerX)
    signal quickPopupHoverEnded(string popupType)

    implicitHeight: 56
    clip: false

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function fontGlowEnabled() {
        return false
    }

    function profileImageSource() {
        const customPath = root.theme ? String(root.theme.profileImagePath || "").trim() : ""
        return customPath.length > 0 ? customPath : Qt.resolvedUrl("../assets/profile-avatar.png")
    }

    function formatLocalizedDate(date) {
        const lang = root.theme ? root.theme.language : "pt-BR"
        const weekdays = ["dom", "seg", "ter", "qua", "qui", "sex", "sab"]
        return date.getDate() + "/" + (date.getMonth() + 1) + " (" + weekdays[date.getDay()] + ")"
    }

    function updateClockText() {
        const now = new Date()
        clockText = Qt.formatDateTime(now, "HH:mm")
        dateText = formatLocalizedDate(now)
        clockMinuteTimer.interval = Math.max(1000, 60050 - now.getSeconds() * 1000 - now.getMilliseconds())
        clockMinuteTimer.restart()
    }

    function pickBattery() {
        batteryDevice = null
        for (let i = 0; i < UPower.devices.count; i += 1) {
            const dev = UPower.devices.get(i)
            if (dev && dev.isLaptopBattery) {
                batteryDevice = dev
                return
            }
        }
    }

    function batteryLevel() {
        if (!batteryDevice || !batteryDevice.ready)
            return 0

        const value = Number(batteryDevice.percentage)
        if (isNaN(value))
            return 0
        return Math.max(0, Math.min(1, value > 1 ? value / 100 : value))
    }

    function runCommand(command) {
        if (commandRunner.running)
            commandRunner.running = false
        commandRunner.command = ["bash", "-lc", command]
        commandRunner.running = true
    }

    function launchFiles() {
        runCommand("if command -v dolphin >/dev/null 2>&1; then dolphin >/dev/null 2>&1 & elif command -v thunar >/dev/null 2>&1; then thunar >/dev/null 2>&1 & elif command -v nautilus >/dev/null 2>&1; then nautilus >/dev/null 2>&1 & fi")
    }

    function launchBrowser() {
        runCommand("if command -v zen-browser >/dev/null 2>&1; then zen-browser >/dev/null 2>&1 & elif command -v firefox >/dev/null 2>&1; then firefox >/dev/null 2>&1 & fi")
    }

    function launchDiscord() {
        runCommand("if command -v discord >/dev/null 2>&1; then discord >/dev/null 2>&1 & elif command -v vesktop >/dev/null 2>&1; then vesktop >/dev/null 2>&1 & elif command -v webcord >/dev/null 2>&1; then webcord >/dev/null 2>&1 & fi")
    }

    component FontGlowEffect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowColor: root.theme ? root.theme.textGlow : Qt.rgba(0, 0, 0, 0)
        shadowOpacity: root.theme ? Math.min(1, 0.28 + root.theme.textGlowLevel * 0.42) : 0
        shadowBlur: root.theme ? Math.min(1, 0.20 + root.theme.textGlowLevel * 0.46) : 0
        blurMax: 16
        autoPaddingEnabled: true
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: height / 2
        color: root.glass
        border.width: 1
        border.color: root.theme ? root.alpha(root.theme.borderSoft, 0.54) : Qt.rgba(1, 1, 1, 0.13)
        antialiasing: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.035)
            antialiasing: true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 12
            anchors.topMargin: root.topBarVerticalMargin
            anchors.bottomMargin: root.topBarVerticalMargin
            spacing: root.topButtonGap

            Item {
                id: clockBlock

                Layout.preferredWidth: Math.round(142 + (root.configuredIconScale - 1) * 24)
                Layout.fillHeight: true

                function centerX() {
                    return clockBlock.mapToItem(root, clockBlock.width / 2, clockBlock.height / 2).x
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: Math.round(10 * root.configuredIconScale)

                    IconCanvas {
                        Layout.preferredWidth: Math.round(35 * root.configuredIconScale)
                        Layout.preferredHeight: Layout.preferredWidth
                        iconName: "clock"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.clockText
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: Math.round(15 * root.configuredIconScale)
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.dateText
                            color: root.inkSoft
                            font.family: root.uiFont
                            font.pixelSize: Math.round(9 * root.configuredIconScale)
                            font.weight: Font.DemiBold
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.quickPopupHovered("time", clockBlock.centerX())
                    onExited: root.quickPopupHoverEnded("time")
                    onClicked: root.quickPopupRequested("time", clockBlock.centerX())
                }
            }

            TopDivider {}

            TopButton {
                Layout.preferredWidth: Math.round(104 * root.configuredIconScale)
                Layout.preferredHeight: root.topControlHeight
                iconName: "search"
                label: "Busca"
                hoverPopupType: "search"
                selected: root.activePopupType === "search"
                onClicked: function(centerX) { root.searchRequested(centerX) }
            }

            TopDivider {}

            RowLayout {
                Layout.preferredWidth: root.workspaceButtonWidth * 4 + root.topButtonGap * 3
                Layout.preferredHeight: root.topControlHeight
                spacing: root.topButtonGap

                Repeater {
                    model: 4
                    WorkspaceButton {
                        Layout.preferredWidth: root.workspaceButtonWidth
                        Layout.preferredHeight: root.topControlHeight
                        number: index + 1
                    }
                }
            }

            TopDivider {}

            RowLayout {
                Layout.preferredWidth: root.topIconButtonSize * 3 + root.topButtonGap * 2
                Layout.preferredHeight: root.topControlHeight
                spacing: root.topButtonGap

                TopIconButton {
                    Layout.preferredWidth: root.topIconButtonSize
                    Layout.preferredHeight: root.topControlHeight
                    iconName: "folder"
                    onClicked: root.launchFiles()
                }

                TopIconButton {
                    Layout.preferredWidth: root.topIconButtonSize
                    Layout.preferredHeight: root.topControlHeight
                    iconName: "browser"
                    onClicked: root.launchBrowser()
                }

                TopIconButton {
                    Layout.preferredWidth: root.topIconButtonSize
                    Layout.preferredHeight: root.topControlHeight
                    iconName: "discord"
                    onClicked: root.launchDiscord()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 8
            }

            RowLayout {
                id: utilityRow

                Layout.preferredWidth: root.utilityButtonWidth * 7 + Math.round(root.topButtonGap * 0.9) * 6
                Layout.preferredHeight: root.topControlHeight
                spacing: Math.round(root.topButtonGap * 0.9)

                UtilityIconButton {
                    iconName: root.muted ? "volume-muted" : "volume"
                    badgeText: root.muted ? "0" : ""
                    hoverPopupType: "volume"
                    selected: root.activePopupType === "volume"
                    onClicked: function(centerX) { root.quickPopupRequested("volume", centerX) }
                }

                UtilityIconButton {
                    iconName: "wifi"
                    hoverPopupType: "wifi"
                    selected: root.activePopupType === "wifi"
                    onClicked: function(centerX) { root.quickPopupRequested("wifi", centerX) }
                }

                UtilityIconButton {
                    iconName: "sun"
                    hoverPopupType: "brightness"
                    selected: root.activePopupType === "brightness"
                    onClicked: function(centerX) { root.quickPopupRequested("brightness", centerX) }
                }

                UtilityIconButton {
                    iconName: "bell"
                    badgeText: root.effectiveNotificationCount > 0 ? String(Math.min(99, root.effectiveNotificationCount)) : ""
                    hoverPopupType: "notifications"
                    selected: root.activePopupType === "notifications"
                    onClicked: function(centerX) { root.quickPopupRequested("notifications", centerX) }
                }

                UtilityIconButton {
                    iconName: "bluetooth"
                    hoverPopupType: "bluetooth"
                    selected: root.activePopupType === "bluetooth"
                    onClicked: function(centerX) { root.quickPopupRequested("bluetooth", centerX) }
                }

                UtilityIconButton {
                    iconName: "battery"
                    progress: root.batteryLevel()
                    hoverPopupType: "battery"
                    selected: root.activePopupType === "battery"
                    onClicked: function(centerX) { root.quickPopupRequested("battery", centerX) }
                }

                UtilityIconButton {
                    iconName: "settings"
                    selected: root.activePopupType === "settings"
                    onClicked: function(centerX) { root.settingsRequested(centerX) }
                }
            }

            Item {
                id: avatarButton

                Layout.preferredWidth: Math.round(36 * root.configuredIconScale)
                Layout.preferredHeight: Layout.preferredWidth

                function centerX() {
                    return avatarButton.mapToItem(root, avatarButton.width / 2, avatarButton.height / 2).x
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.36)
                    antialiasing: true
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.profileImageSource()
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.quickPopupHovered("profile", avatarButton.centerX())
                    onExited: root.quickPopupHoverEnded("profile")
                    onClicked: root.quickPopupRequested("profile", avatarButton.centerX())
                }
            }
        }
    }

    Timer {
        id: clockMinuteTimer
        interval: 60000
        running: false
        repeat: false
        onTriggered: root.updateClockText()
    }

    Timer {
        interval: 15000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pickBattery()
            if (!volumeQuery.running)
                volumeQuery.running = true
            if (!notificationCountQuery.running)
                notificationCountQuery.running = true
        }
    }

    Component.onCompleted: root.updateClockText()

    Process {
        id: commandRunner

        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Process {
        id: volumeQuery

        running: false
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.70'"]

        stdout: SplitParser {
            onRead: function(data) {
                const text = String(data || "").trim()
                const match = text.match(/[0-9]+\\.?[0-9]*/)
                root.muted = text.indexOf("MUTED") >= 0
                if (match)
                    root.volume = Math.max(0, Math.min(100, Math.round(parseFloat(match[0]) * 100)))
            }
        }

        onExited: running = false
    }

    Process {
        id: notificationCountQuery

        running: false
        command: ["bash", "-lc", "if command -v makoctl >/dev/null 2>&1; then makoctl list -j 2>/dev/null | python3 -c 'import sys,json; raw=sys.stdin.read().strip() or \"[]\"; print(len(json.loads(raw)))' 2>/dev/null || printf '0\\n'; else printf '0\\n'; fi"]

        stdout: SplitParser {
            onRead: function(data) {
                if (root.notificationCountOverride >= 0)
                    return
                const value = parseInt(String(data || "").trim())
                root.notificationCount = isNaN(value) ? 0 : Math.max(0, value)
            }
        }

        onExited: running = false
    }

    component TopDivider: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 30
        color: Qt.rgba(1, 1, 1, 0.085)
    }

    component TopSection: Item {
        id: section

        property string title: ""
        property int contentInset: root.sectionInset

        Layout.fillHeight: true

        Text {
            anchors.left: parent.left
            anchors.leftMargin: section.contentInset
            anchors.top: parent.top
            text: section.title
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    component TopButton: Rectangle {
        id: button

        property string iconName: "search"
        property string label: ""
        property bool selected: false
        property string hoverPopupType: ""
        signal clicked(real centerX)

        radius: height / 2
        color: selected ? root.cardActive : (mouse.containsMouse ? root.cardHover : "transparent")
        border.width: 1
        border.color: selected ? Qt.rgba(1, 1, 1, 0.16) : (mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.11) : "transparent")
        scale: mouse.pressed ? 0.98 : (mouse.containsMouse ? 1.012 : 1)
        antialiasing: true

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        function iconLineColor() {
            if (button.selected)
                return root.pink
            if (button.iconName === "folder")
                return root.theme ? root.theme.accentTertiary : Qt.rgba(0.46, 0.64, 0.90, 0.94)
            if (button.iconName === "browser")
                return root.theme ? root.theme.accentPrimary : Qt.rgba(0.91, 0.46, 0.36, 0.90)
            if (button.iconName === "discord")
                return root.theme ? root.theme.accentSecondary : Qt.rgba(0.53, 0.47, 0.84, 0.90)
            if (button.iconName === "palette")
                return root.pink
            return root.inkSoft
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(10 * root.configuredIconScale)
            anchors.rightMargin: Math.round(11 * root.configuredIconScale)
            spacing: Math.round(7 * root.configuredIconScale)

                    IconCanvas {
                        Layout.preferredWidth: Math.round(16 * root.configuredIconScale)
                        Layout.preferredHeight: Layout.preferredWidth
                        iconName: button.iconName
                        lineColor: button.selected ? root.accent2 : root.inkSoft
                    }

            Text {
                Layout.fillWidth: true
                text: button.label
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: Math.round(11 * root.configuredIconScale)
                font.weight: Font.Bold
                elide: Text.ElideRight
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHovered(button.hoverPopupType, button.centerX())
            }
            onExited: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(button.hoverPopupType)
            }
            onClicked: button.clicked(button.centerX())
        }
    }

    component WorkspaceButton: Rectangle {
        id: button

        property int number: 1
        readonly property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === number

        radius: 8
        color: active ? root.cardActive : (mouse.containsMouse ? root.cardHover : root.card)
        border.width: 1
        border.color: active ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
        scale: mouse.pressed ? 0.96 : (mouse.containsMouse ? 1.035 : 1)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: String(button.number)
            color: button.active ? "#ffffff" : root.ink
            font.family: root.uiFont
            font.pixelSize: Math.round(12 * root.configuredIconScale)
            font.weight: Font.DemiBold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("workspace " + button.number)
        }
    }

    component TopIconButton: Rectangle {
        id: button

        property string iconName: "files"
        property string badgeText: ""
        property real progress: -1
        property bool selected: false
        property string hoverPopupType: ""
        signal clicked(real centerX)

        radius: 8
        color: selected ? root.cardActive : (mouse.containsMouse ? root.cardHover : root.card)
        border.width: 1
        border.color: selected ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
        scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.04 : 1)
        antialiasing: true

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        function iconLineColor() {
            if (button.selected)
                return root.pink
            if (button.iconName === "folder")
                return root.theme ? root.theme.accentTertiary : Qt.rgba(0.46, 0.64, 0.90, 0.94)
            if (button.iconName === "browser")
                return root.theme ? root.theme.accentPrimary : Qt.rgba(0.91, 0.46, 0.36, 0.90)
            if (button.iconName === "discord")
                return root.theme ? root.theme.accentSecondary : Qt.rgba(0.53, 0.47, 0.84, 0.90)
            if (button.iconName === "palette")
                return root.pink
            return root.inkSoft
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        IconCanvas {
            anchors.centerIn: parent
            width: Math.min(root.topIconCanvasSize, parent.width - 8)
            height: width
            iconName: button.iconName
            progress: button.progress
            lineColor: button.iconLineColor()
        }

        Rectangle {
            visible: button.badgeText.length > 0
            x: parent.width - width + 2
            y: -5
            width: Math.max(16, badgeLabel.implicitWidth + 8)
            height: 16
            radius: 8
            color: root.alpha(root.accent, 0.84)
            border.width: 1
            border.color: root.alpha(root.theme ? root.theme.activeText : Qt.rgba(1, 1, 1, 1), 0.50)

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: button.badgeText
                color: root.theme ? root.theme.buttonPrimaryText : "white"
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHovered(button.hoverPopupType, button.centerX())
            }
            onExited: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(button.hoverPopupType)
            }
            onClicked: button.clicked(button.centerX())
        }
    }

    component UtilityIconButton: Item {
        id: button

        property string iconName: "volume"
        property string badgeText: ""
        property real progress: -1
        property bool selected: false
        property string hoverPopupType: ""
        signal clicked(real centerX)

        Layout.preferredWidth: root.utilityButtonWidth
        Layout.preferredHeight: root.topControlHeight
        scale: mouse.pressed ? 0.94 : (mouse.containsMouse ? 1.10 : 1)

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.centerIn: parent
            width: root.utilityButtonWidth
            height: root.utilityButtonWidth
            radius: height / 2
            color: button.selected || mouse.containsMouse ? root.cardHover : "transparent"
            border.width: button.selected ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.12)
        }

        IconCanvas {
            anchors.centerIn: parent
            width: root.utilityIconSize
            height: root.utilityIconSize
            iconName: button.iconName
            progress: button.progress
            lineColor: button.selected ? root.pink : root.inkSoft
        }

        Rectangle {
            visible: button.badgeText.length > 0
            x: parent.width - width + 5
            y: 0
            width: Math.max(14, utilityBadgeLabel.implicitWidth + 7)
            height: 14
            radius: 7
            color: root.cardActive
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.20)

            Text {
                id: utilityBadgeLabel
                anchors.centerIn: parent
                text: button.badgeText
                color: "#ffffff"
                font.family: root.uiFont
                font.pixelSize: Math.round(8 * root.configuredIconScale)
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHovered(button.hoverPopupType, button.centerX())
            }
            onExited: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(button.hoverPopupType)
            }
            onClicked: button.clicked(button.centerX())
        }
    }

    component BatteryPill: Rectangle {
        id: pill

        radius: 8
        color: root.card
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)
        antialiasing: true
        scale: mouse.pressed ? 0.96 : (mouse.containsMouse ? 1.035 : 1)

        function centerX() {
            return pill.mapToItem(root, pill.width / 2, pill.height / 2).x
        }

        function batteryPercentText() {
            const value = Math.round(root.batteryLevel() * 100)
            return value > 0 ? String(value) : "50"
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        IconCanvas {
            anchors.centerIn: parent
            width: Math.round(20 * root.configuredIconScale)
            height: width
            iconName: "battery"
            progress: root.batteryLevel()
            lineColor: root.inkSoft
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.quickPopupHovered("battery", pill.centerX())
            onExited: root.quickPopupHoverEnded("battery")
            onClicked: root.quickPopupRequested("battery", pill.centerX())
        }
    }

    component IconCanvas: Canvas {
        id: canvas

        property string iconName: "search"
        property real progress: -1
        property color lineColor: root.inkSoft

        antialiasing: true
        onIconNameChanged: requestPaint()
        onProgressChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function roundedRect(ctx, x, y, w, h, r) {
            const radius = Math.min(r, w / 2, h / 2)
            ctx.beginPath()
            ctx.moveTo(x + radius, y)
            ctx.lineTo(x + w - radius, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + radius)
            ctx.lineTo(x + w, y + h - radius)
            ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h)
            ctx.lineTo(x + radius, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - radius)
            ctx.lineTo(x, y + radius)
            ctx.quadraticCurveTo(x, y, x + radius, y)
            ctx.closePath()
        }

        function normalizedName() {
            if (iconName === "files")
                return "folder"
            if (iconName === "theme")
                return "palette"
            if (iconName === "brightness")
                return "sun"
            if (iconName === "notifications")
                return "bell"
            return iconName
        }

        function colorString(colorValue, opacity) {
            const a = opacity === undefined ? colorValue.a : opacity
            return "rgba("
                + Math.round(colorValue.r * 255) + ", "
                + Math.round(colorValue.g * 255) + ", "
                + Math.round(colorValue.b * 255) + ", "
                + Math.max(0, Math.min(1, a)) + ")"
        }

        function mixedColorString(colorValue, r, g, b, amount, opacity) {
            const t = Math.max(0, Math.min(1, amount))
            const rr = colorValue.r + (r - colorValue.r) * t
            const gg = colorValue.g + (g - colorValue.g) * t
            const bb = colorValue.b + (b - colorValue.b) * t
            const a = opacity === undefined ? colorValue.a : opacity
            return "rgba("
                + Math.round(rr * 255) + ", "
                + Math.round(gg * 255) + ", "
                + Math.round(bb * 255) + ", "
                + Math.max(0, Math.min(1, a)) + ")"
        }

        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            const s = Math.min(w, h)
            const cx = w / 2
            const cy = h / 2
            const name = normalizedName()
            const fg = lineColor
            const value = progress >= 0 ? Math.max(0, Math.min(1, progress)) : 1.0

            ctx.reset()
            ctx.clearRect(0, 0, w, h)
            ctx.strokeStyle = fg
            ctx.fillStyle = fg
            ctx.lineWidth = Math.max(1.5, s * 0.085)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (name === "clock") {
                ctx.strokeStyle = root.alpha(root.inkSoft, 0.82)
                ctx.lineWidth = Math.max(1.15, w * 0.040)
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.38, 0, Math.PI * 2)
                ctx.stroke()

                ctx.strokeStyle = root.alpha(root.inkSoft, 0.42)
                ctx.lineWidth = Math.max(0.75, w * 0.020)
                for (let i = 0; i < 12; i += 1) {
                    const a = -Math.PI / 2 + i * Math.PI / 6
                    const outer = w * 0.34
                    const inner = i % 3 === 0 ? w * 0.29 : w * 0.31
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
                    ctx.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer)
                    ctx.stroke()
                }

                ctx.strokeStyle = root.ink
                ctx.lineWidth = Math.max(1.1, w * 0.035)
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + w * 0.15, cy - h * 0.18)
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx - w * 0.03, cy - h * 0.26)
                ctx.stroke()

                ctx.fillStyle = root.ink
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.035, 0, Math.PI * 2)
                ctx.fill()
            } else if (name === "palette") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.34, Math.PI * 0.20, Math.PI * 1.95, false)
                ctx.quadraticCurveTo(s * 0.20, s * 0.86, s * 0.48, s * 0.72)
                ctx.stroke()
                for (let i = 0; i < 4; i += 1) {
                    const a = -1.9 + i * 0.78
                    ctx.beginPath()
                    ctx.arc(cx + Math.cos(a) * s * 0.16, cy + Math.sin(a) * s * 0.15, s * 0.026, 0, Math.PI * 2, false)
                    ctx.fill()
                }
            } else if (name === "search") {
                ctx.beginPath()
                ctx.arc(cx - s * 0.07, cy - s * 0.07, s * 0.25, 0, Math.PI * 2, false)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx + s * 0.13, cy + s * 0.13)
                ctx.lineTo(cx + s * 0.32, cy + s * 0.32)
                ctx.stroke()
            } else if (name === "folder") {
                ctx.save()
                ctx.fillStyle = colorString(fg, 0.78)
                roundedRect(ctx, s * 0.16, s * 0.34, s * 0.68, s * 0.44, s * 0.08)
                ctx.fill()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.26, 0.86)
                roundedRect(ctx, s * 0.18, s * 0.25, s * 0.31, s * 0.20, s * 0.06)
                ctx.fill()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.74, 0.34)
                roundedRect(ctx, s * 0.23, s * 0.43, s * 0.50, s * 0.09, s * 0.04)
                ctx.fill()
                ctx.strokeStyle = mixedColorString(fg, 0, 0, 0, 0.28, 0.58)
                ctx.lineWidth = Math.max(1, s * 0.045)
                roundedRect(ctx, s * 0.16, s * 0.34, s * 0.68, s * 0.44, s * 0.08)
                ctx.stroke()
                ctx.restore()
            } else if (name === "discord") {
                ctx.save()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.26, 0.46)
                ctx.strokeStyle = colorString(fg, 0.84)
                ctx.lineWidth = Math.max(1.4, s * 0.070)
                ctx.beginPath()
                ctx.moveTo(s * 0.21, s * 0.45)
                ctx.quadraticCurveTo(s * 0.29, s * 0.27, s * 0.44, s * 0.31)
                ctx.quadraticCurveTo(s * 0.50, s * 0.35, s * 0.56, s * 0.31)
                ctx.quadraticCurveTo(s * 0.71, s * 0.27, s * 0.79, s * 0.45)
                ctx.quadraticCurveTo(s * 0.88, s * 0.62, s * 0.75, s * 0.75)
                ctx.quadraticCurveTo(s * 0.67, s * 0.82, s * 0.57, s * 0.72)
                ctx.quadraticCurveTo(s * 0.50, s * 0.76, s * 0.43, s * 0.72)
                ctx.quadraticCurveTo(s * 0.33, s * 0.82, s * 0.25, s * 0.75)
                ctx.quadraticCurveTo(s * 0.12, s * 0.62, s * 0.21, s * 0.45)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.72, 0.94)
                ctx.beginPath()
                ctx.arc(s * 0.39, s * 0.53, s * 0.038, 0, Math.PI * 2, false)
                ctx.arc(s * 0.61, s * 0.53, s * 0.038, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.strokeStyle = mixedColorString(fg, 1, 1, 1, 0.68, 0.86)
                ctx.lineWidth = Math.max(1, s * 0.040)
                ctx.beginPath()
                ctx.moveTo(s * 0.35, s * 0.64)
                ctx.quadraticCurveTo(s * 0.50, s * 0.70, s * 0.65, s * 0.64)
                ctx.stroke()
                ctx.restore()
            } else if (name === "browser") {
                ctx.save()
                const grad = ctx.createLinearGradient(s * 0.22, s * 0.18, s * 0.82, s * 0.78)
                grad.addColorStop(0, mixedColorString(fg, 1, 1, 1, 0.34, 0.94))
                grad.addColorStop(0.48, colorString(fg, 0.90))
                grad.addColorStop(1, colorString(root.lilac, 0.82))
                ctx.fillStyle = grad
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.34, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.58, 0.66)
                ctx.beginPath()
                ctx.arc(cx - s * 0.11, cy - s * 0.06, s * 0.20, Math.PI * 0.12, Math.PI * 1.62, false)
                ctx.lineTo(cx + s * 0.16, cy - s * 0.16)
                ctx.closePath()
                ctx.fill()
                ctx.fillStyle = colorString(root.lilac, 0.78)
                ctx.beginPath()
                ctx.arc(cx + s * 0.04, cy + s * 0.05, s * 0.16, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.restore()
            } else if (name === "volume" || name === "volume-muted") {
                ctx.beginPath()
                ctx.moveTo(s * 0.16, s * 0.43)
                ctx.lineTo(s * 0.32, s * 0.43)
                ctx.lineTo(s * 0.52, s * 0.27)
                ctx.lineTo(s * 0.52, s * 0.73)
                ctx.lineTo(s * 0.32, s * 0.57)
                ctx.lineTo(s * 0.16, s * 0.57)
                ctx.closePath()
                ctx.stroke()
                if (name === "volume-muted") {
                    ctx.beginPath()
                    ctx.moveTo(s * 0.66, s * 0.40)
                    ctx.lineTo(s * 0.84, s * 0.58)
                    ctx.moveTo(s * 0.84, s * 0.40)
                    ctx.lineTo(s * 0.66, s * 0.58)
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    ctx.arc(s * 0.55, s * 0.50, s * (0.14 + value * 0.10), Math.PI * 1.68, Math.PI * 0.32, false)
                    ctx.stroke()
                }
            } else if (name === "wifi") {
                for (let i = 0; i < 3; i += 1) {
                    ctx.globalAlpha = 0.52 + i * 0.14
                    ctx.beginPath()
                    ctx.arc(cx, cy + s * 0.16, s * (0.16 + i * 0.14), Math.PI * 1.18, Math.PI * 1.82, false)
                    ctx.stroke()
                }
                ctx.globalAlpha = 1
                ctx.beginPath()
                ctx.arc(cx, cy + s * 0.20, s * 0.035, 0, Math.PI * 2, false)
                ctx.fill()
            } else if (name === "sun") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.16, 0, Math.PI * 2, false)
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = (i / 8) * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.29, cy + Math.sin(a) * s * 0.29)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.40, cy + Math.sin(a) * s * 0.40)
                    ctx.stroke()
                }
            } else if (name === "bell") {
                ctx.beginPath()
                ctx.moveTo(s * 0.29, s * 0.64)
                ctx.lineTo(s * 0.71, s * 0.64)
                ctx.quadraticCurveTo(s * 0.65, s * 0.53, s * 0.65, s * 0.42)
                ctx.quadraticCurveTo(s * 0.65, s * 0.24, s * 0.50, s * 0.24)
                ctx.quadraticCurveTo(s * 0.35, s * 0.24, s * 0.35, s * 0.42)
                ctx.quadraticCurveTo(s * 0.35, s * 0.53, s * 0.29, s * 0.64)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.44, s * 0.74)
                ctx.quadraticCurveTo(s * 0.50, s * 0.81, s * 0.56, s * 0.74)
                ctx.stroke()
            } else if (name === "bluetooth") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.18)
                ctx.lineTo(s * 0.69, s * 0.35)
                ctx.lineTo(cx, s * 0.50)
                ctx.lineTo(s * 0.69, s * 0.65)
                ctx.lineTo(cx, s * 0.82)
                ctx.lineTo(cx, s * 0.18)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.31, s * 0.35)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.31, s * 0.65)
                ctx.stroke()
            } else if (name === "settings") {
                ctx.lineWidth = Math.max(1.5, s * 0.070)
                ctx.beginPath()
                for (let i = 0; i < 16; i += 1) {
                    const a = -Math.PI / 2 + (i / 16) * Math.PI * 2
                    const r = i % 2 === 0 ? s * 0.38 : s * 0.30
                    const x = cx + Math.cos(a) * r
                    const y = cy + Math.sin(a) * r
                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.13, 0, Math.PI * 2, false)
                ctx.stroke()
            } else if (name === "display") {
                ctx.save()
                ctx.strokeStyle = colorString(fg, 0.86)
                ctx.lineWidth = Math.max(1.35, s * 0.060)
                roundedRect(ctx, s * 0.18, s * 0.22, s * 0.64, s * 0.45, s * 0.07)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.67)
                ctx.lineTo(cx, s * 0.79)
                ctx.moveTo(s * 0.40, s * 0.80)
                ctx.lineTo(s * 0.60, s * 0.80)
                ctx.stroke()
                ctx.lineWidth = Math.max(1.1, s * 0.048)
                ctx.globalAlpha = 0.80
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.31)
                ctx.lineTo(cx, s * 0.22)
                ctx.moveTo(cx, s * 0.58)
                ctx.lineTo(cx, s * 0.67)
                ctx.moveTo(s * 0.30, s * 0.445)
                ctx.lineTo(s * 0.18, s * 0.445)
                ctx.moveTo(s * 0.70, s * 0.445)
                ctx.lineTo(s * 0.82, s * 0.445)
                ctx.stroke()
                ctx.restore()
            } else if (name === "battery") {
                const level = progress >= 0 ? Math.max(0, Math.min(1, progress)) : 0.70
                const bodyX = s * 0.19
                const bodyY = s * 0.34
                const bodyW = s * 0.56
                const bodyH = s * 0.32
                const capW = s * 0.07
                const capH = s * 0.14
                const pad = s * 0.055
                const fillW = Math.max(0, (bodyW - pad * 2) * level)

                ctx.lineWidth = Math.max(1.4, s * 0.060)
                roundedRect(ctx, bodyX, bodyY, bodyW, bodyH, s * 0.070)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(bodyX + bodyW, cy - capH / 2)
                ctx.lineTo(bodyX + bodyW + capW, cy - capH / 2)
                ctx.lineTo(bodyX + bodyW + capW, cy + capH / 2)
                ctx.lineTo(bodyX + bodyW, cy + capH / 2)
                ctx.stroke()

                if (fillW > 0) {
                    ctx.fillStyle = colorString(fg, level <= 0.18 ? 0.52 : 0.74)
                    roundedRect(ctx, bodyX + pad, bodyY + pad, fillW, bodyH - pad * 2, s * 0.042)
                    ctx.fill()
                }
            } else {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.28, 0, Math.PI * 2, false)
                ctx.stroke()
            }
        }
    }
}
