import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "components"

ShellRoot {
    id: root

    VeloraTheme {
        id: veloraTheme
    }

    Component.onCompleted: {
        NotificationServer.keepOnReload = true
        NotificationServer.persistenceSupported = true
        NotificationServer.bodySupported = true
        NotificationServer.bodyMarkupSupported = true
        NotificationServer.actionsSupported = true
        NotificationServer.imageSupported = true
    }

    Connections {
        target: NotificationServer

        function onNotification(notification) {
            if (!notification)
                return

            notification.tracked = true
        }
    }

    property bool wallpaperSelectorOpen: false
    property bool settingsPanelOpen: false
    property string quickPopupType: ""
    property string hoverPopupType: ""
    property bool sidebarPopupHovering: false
    property bool quickPopupHovering: false
    property bool wallpaperSelectorHovering: false
    property bool settingsPanelHovering: false
    property bool wallpaperSelectorWindowOpen: false
    property bool settingsPanelWindowOpen: false
    property bool wallpaperPreloadEnabled: false
    property bool rightDashboardOpen: false
    property bool leftMenuOpen: false
    property bool leftMenuHovering: false
    property bool leftMenuTriggerHovering: false
    property bool leftMenuPanelHovering: false
    property bool leftMediaWindowOpen: false
    property bool leftMediaWindowHovering: false
    property bool leftMediaWindowEntranceHold: false
    property real leftMediaWindowCenterY: 300
    property bool leftMenuPreloadEnabled: false
    property string rightDashboardSection: "weather"
    property bool focusMode: false
    property int focusIndex: 0
    readonly property bool barOnRight: veloraTheme.barPosition === "right"
    readonly property bool rightSoftLayout: barOnRight
    readonly property int sidebarVisualWidth: 112
    readonly property int desktopFrameMargin: 14
    readonly property int sidebarOuterMargin: desktopFrameMargin
    readonly property int sidebarVerticalMargin: 20
    readonly property int sidebarCornerRadius: 24
    readonly property int sideVisualizerWaveWidth: 58
    readonly property int barPanelWidth: sidebarVisualWidth + sidebarOuterMargin
    readonly property int barReserveWidth: barPanelWidth
    readonly property int desktopFrameRadius: 10
    readonly property bool frameVisualsEnabled: veloraTheme.desktopFrameEnabled
    readonly property int frameVisualInset: frameVisualsEnabled ? desktopFrameMargin : 0
    readonly property bool frameVisualsMounted: frameVisualsEnabled || frameVisualsReveal > 0.01
    property real frameVisualsReveal: frameVisualsEnabled ? 1 : 0
    readonly property real desktopFrameMatteOpacity: sidebarPanelGlassAlpha()
    readonly property int popupFrameGap: 14
    readonly property string popupAttachSide: barOnRight ? "right" : "left"
    readonly property int leftMenuWidth: 348
    readonly property int leftMenuTriggerWidth: 18
    readonly property int leftMenuFrameInset: frameVisualsEnabled ? desktopFrameMargin + 1 : desktopFrameMargin
    readonly property int leftMediaWindowWidth: 640
    readonly property int leftMediaWindowHeight: 690
    readonly property int leftMediaWindowGap: 12
    property real quickPopupCenterY: 300
    property bool quickPopupWindowOpen: false
    property string renderedQuickPopupType: ""
    readonly property bool wallpaperSelectorHoverPreview: hoverPopupType === "theme" && !wallpaperSelectorOpen
    readonly property bool settingsPanelHoverPreview: hoverPopupType === "settings" && !settingsPanelOpen
    readonly property bool wallpaperSelectorPreview: (focusMode && focusTarget === "theme" && !wallpaperSelectorOpen) || wallpaperSelectorHoverPreview
    readonly property bool wallpaperSelectorVisible: wallpaperSelectorOpen || wallpaperSelectorPreview
    readonly property bool settingsPanelVisible: settingsPanelOpen || settingsPanelHoverPreview
    readonly property bool wallpaperSelectorPanelVisible: wallpaperSelectorVisible || wallpaperSelectorWindowOpen
    readonly property bool settingsPanelPanelVisible: settingsPanelVisible || settingsPanelWindowOpen
    readonly property bool quickPopupOpen: quickPopupType.length > 0
    readonly property string quickPopupPreviewType: focusMode ? quickPopupForFocus(focusTarget) : ((hoverPopupType !== "theme" && hoverPopupType !== "settings") ? hoverPopupType : "")
    readonly property string activeQuickPopupType: quickPopupOpen ? quickPopupType : quickPopupPreviewType
    readonly property bool quickPopupVisible: activeQuickPopupType.length > 0
    readonly property bool quickPopupPanelVisible: quickPopupVisible || quickPopupWindowOpen
    readonly property string visibleQuickPopupType: quickPopupVisible ? activeQuickPopupType : renderedQuickPopupType
    readonly property var focusItems: [
        "clock",
        "theme",
        "search",
        "workspace1",
        "workspace2",
        "workspace3",
        "workspace4",
        "files",
        "browser",
        "discord",
        "volume",
        "wifi",
        "brightness",
        "notifications",
        "settings",
        "avatar"
    ]
    readonly property string focusTarget: focusItems[Math.max(0, Math.min(focusIndex, focusItems.length - 1))]

    Behavior on frameVisualsReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.frameVisualsEnabled ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
            easing.type: root.frameVisualsEnabled ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
        }
    }

    function desktopFrameMatteColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, desktopFrameMatteOpacity)
    }

    function sidebarPanelGlassAlpha() {
        return Math.max(0.62, Math.min(veloraTheme.surfaceSidebar.a, 0.78))
    }

    function sidebarBarGlassAlpha() {
        return Math.max(veloraTheme.minOpacityForRole("sidebar"), Math.min(veloraTheme.barOpacity, 0.98))
    }

    function sidebarPanelMaterialColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function sidebarBarMaterialColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarBarGlassAlpha())
    }

    function sideRailMaterialColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function sidebarPanelBorderColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return desktopFrameBorderColor()
    }

    function sidebarPanelInnerLineColor() {
        if (!frameVisualsMounted)
            return "transparent"
        if (veloraTheme.themeMode === "dark")
            return Qt.rgba(1, 1, 1, 0.055)
        return veloraTheme.alpha(sidebarPanelBorderColor(), veloraTheme.themeId === "pywal16" ? 0.16 : 0.24)
    }

    function desktopFrameBorderColor() {
        if (!frameVisualsMounted)
            return "transparent"
        if (veloraTheme.themeId === "pywal16")
            return veloraTheme.alpha(veloraTheme.sidebarBorderGlow, Math.min(0.18, Math.max(0.08, veloraTheme.sidebarBorderGlow.a * 0.50)))
        return veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.11 : 0.26)
    }

    function desktopFrameHighlightLineColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.activeText, veloraTheme.themeMode === "dark" ? 0.24 : 0.32)
    }

    function desktopFrameHighlightColor() {
        return "transparent"
    }

    function enterFocus() {
        exitFocus()
    }

    function exitFocus() {
        focusMode = false
    }

    function toggleFocus() {
        exitFocus()
    }

    function moveFocus(dir) {
        focusIndex = Math.max(0, Math.min(focusIndex + dir, focusItems.length - 1))
    }

    function quickPopupForFocus(target) {
        if (target === "search")
            return "search"
        if (target === "volume")
            return "volume"
        if (target === "wifi")
            return "wifi"
        if (target === "brightness")
            return "brightness"
        if (target === "notifications")
            return "notifications"
        return ""
    }

    onActiveQuickPopupTypeChanged: {
        if (quickPopupVisible && activeQuickPopupType.length > 0)
            renderedQuickPopupType = activeQuickPopupType
    }

    onQuickPopupVisibleChanged: {
        if (quickPopupVisible) {
            quickPopupUnmountTimer.stop()
            quickPopupWindowOpen = true
            renderedQuickPopupType = activeQuickPopupType
        } else if (renderedQuickPopupType.length > 0) {
            quickPopupUnmountTimer.restart()
        }
    }

    onWallpaperSelectorVisibleChanged: {
        if (wallpaperSelectorVisible) {
            wallpaperSelectorUnmountTimer.stop()
            wallpaperSelectorWindowOpen = true
        } else if (wallpaperSelectorWindowOpen) {
            wallpaperSelectorUnmountTimer.restart()
        }
    }

    onSettingsPanelVisibleChanged: {
        if (settingsPanelVisible) {
            settingsPanelUnmountTimer.stop()
            settingsPanelWindowOpen = true
        } else if (settingsPanelWindowOpen) {
            settingsPanelUnmountTimer.restart()
        }
    }

    onLeftMenuOpenChanged: {
        if (!leftMenuOpen) {
            leftMediaWindowOpen = false
            leftMediaWindowHovering = false
            leftMediaWindowEntranceHold = false
        }
    }

    function quickPopupArrowCenter(type) {
        if (type === "volume")
            return 78
        if (type === "wifi")
            return 288
        if (type === "brightness")
            return 248
        if (type === "notifications")
            return 414
        if (type === "wallpaperVisibility")
            return 132
        return 38
    }

    function defaultQuickPopupCenterY(type) {
        if (type === "theme")
            return 212
        if (type === "settings")
            return 1018
        if (type === "volume")
            return 782
        if (type === "wifi")
            return 888
        if (type === "brightness")
            return 938
        if (type === "notifications")
            return 982
        if (type === "wallpaperVisibility")
            return defaultQuickPopupCenterY("theme")
        return 290
    }

    function setQuickPopupCenter(type, centerY) {
        const value = Number(centerY)
        quickPopupCenterY = value > 0 ? value : defaultQuickPopupCenterY(type)
    }

    function prepareWallpaperSelector(centerY) {
        setQuickPopupCenter("theme", centerY)
        discardQuickPopupAnimation()
        settingsPanelOpen = false
    }

    function openWallpaperVisibility(centerY) {
        const value = Number(centerY)
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        wallpaperSelectorHovering = false
        wallpaperSelectorUnmountTimer.stop()
        openQuickPopup("wallpaperVisibility", value > 0 ? value : defaultQuickPopupCenterY("theme"))
    }

    function showWallpaperSelector(centerY) {
        exitFocus()
        prepareWallpaperSelector(centerY)
        wallpaperSelectorOpen = true
    }

    function toggleWallpaperSelector(centerY, forceOpen) {
        exitFocus()
        prepareWallpaperSelector(centerY)
        wallpaperSelectorOpen = forceOpen ? true : !wallpaperSelectorOpen
    }

    function prepareSettingsPanel(centerY) {
        setQuickPopupCenter("settings", centerY)
        discardQuickPopupAnimation()
        wallpaperSelectorOpen = false
    }

    function toggleSettingsPanel(centerY, forceOpen) {
        exitFocus()
        prepareSettingsPanel(centerY)
        settingsPanelOpen = forceOpen ? true : !settingsPanelOpen
    }

    function openQuickPopup(type, centerY) {
        exitFocus()
        setQuickPopupCenter(type, centerY)
        renderedQuickPopupType = type
        hoverPopupType = ""
        hoverCloseTimer.stop()
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        quickPopupType = type
    }

    function closeQuickPopup() {
        quickPopupType = ""
        hoverPopupType = ""
        sidebarPopupHovering = false
        quickPopupHovering = false
        hoverCloseTimer.stop()
    }

    function discardQuickPopupAnimation() {
        closeQuickPopup()
        quickPopupUnmountTimer.stop()
        quickPopupWindowOpen = false
        renderedQuickPopupType = ""
    }

    function previewSidebarPopup(type, centerY) {
        if (!type || type.length <= 0)
            return

        if (wallpaperSelectorOpen || settingsPanelOpen)
            return

        exitFocus()
        setQuickPopupCenter(type, centerY)
        renderedQuickPopupType = type
        hoverCloseTimer.stop()
        sidebarPopupHovering = true
        quickPopupType = ""
        hoverPopupType = type
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
    }

    function endSidebarPopupHover(type) {
        if (hoverPopupType !== type)
            return

        sidebarPopupHovering = false
        scheduleHoverClose()
    }

    function scheduleHoverClose() {
        if (hoverPopupType.length > 0)
            hoverCloseTimer.restart()
    }

    function clearHoveredSidebarPopup() {
        if (quickPopupType.length > 0 || wallpaperSelectorOpen || settingsPanelOpen)
            return

        if (!quickPopupHovering && !wallpaperSelectorHovering && !settingsPanelHovering) {
            sidebarPopupHovering = false
            hoverPopupType = ""
        }
    }

    function toggleQuickPopup(type, centerY) {
        hoverPopupType = ""
        hoverCloseTimer.stop()
        if (quickPopupType === type) {
            quickPopupType = ""
            return
        }

        openQuickPopup(type, centerY)
    }

    function openRightDashboard(section) {
        if (rightSoftLayout) {
            rightDashboardOpen = false
            return
        }

        const value = section && section.length > 0 ? section : "weather"
        rightDashboardSection = value
        rightDashboardOpen = true
    }

    function closeRightDashboard() {
        rightDashboardOpen = false
    }

    function openLeftMenu() {
        leftMenuCloseTimer.stop()
        leftMenuOpen = true
    }

    function updateLeftMenuHovering() {
        leftMenuHovering = leftMenuTriggerHovering || leftMenuPanelHovering || leftMediaWindowHovering || leftMediaWindowEntranceHold
    }

    function scheduleLeftMenuClose() {
        updateLeftMenuHovering()
        if (!leftMenuHovering)
            leftMenuCloseTimer.restart()
    }

    function openLeftMediaWindow(centerY) {
        const value = Number(centerY)
        leftMediaWindowCenterY = value > 0 ? value : 300
        leftMediaWindowEntranceHold = true
        leftMediaWindowEntranceHoldTimer.restart()
        leftMediaWindowOpen = true
        openLeftMenu()
    }

    function leftMediaWindowY(panelHeight, screenHeight) {
        const edgeMargin = leftMenuFrameInset
        const wanted = leftMediaWindowCenterY - panelHeight / 2
        return Math.round(Math.max(edgeMargin, Math.min(screenHeight - panelHeight - edgeMargin, wanted)))
    }

    function barX(screenWidth) {
        return barOnRight ? Math.max(0, screenWidth - sidebarOuterMargin - sidebarVisualWidth) : sidebarOuterMargin
    }

    function mainAreaX(screenWidth) {
        return barOnRight ? frameVisualInset : barPanelWidth
    }

    function mainAreaRightInset(screenWidth) {
        return barOnRight ? barPanelWidth : frameVisualInset
    }

    function mainAreaWidth(screenWidth) {
        return Math.max(0, screenWidth - mainAreaX(screenWidth) - mainAreaRightInset(screenWidth))
    }

    function quickPopupX(screenWidth, popupWidth) {
        if (barOnRight) {
            return Math.round(Math.max(frameVisualInset, screenWidth - barPanelWidth - frameVisualInset - popupFrameGap - popupWidth))
        }
        return barPanelWidth + frameVisualInset + popupFrameGap
    }

    function attachedPopupX(screenWidth, popupWidth) {
        if (barOnRight) {
            return Math.round(Math.max(frameVisualInset, screenWidth - barPanelWidth - frameVisualInset - popupFrameGap - popupWidth))
        }
        return barPanelWidth + frameVisualInset + popupFrameGap
    }

    function quickPopupWidth(type) {
        if (type === "theme")
            return 820
        if (type === "settings")
            return 820
        if (type === "volume")
            return 350
        if (type === "wifi")
            return 324
        if (type === "brightness")
            return 286
        if (type === "notifications")
            return 360
        if (type === "wallpaperVisibility")
            return 372
        return 286
    }

    function quickPopupHeight(type) {
        if (type === "theme")
            return 520
        if (type === "settings")
            return 560
        if (type === "volume")
            return 266
        if (type === "wifi")
            return 448
        if (type === "brightness")
            return 376
        if (type === "notifications")
            return 560
        if (type === "wallpaperVisibility")
            return 470
        return 324
    }

    function quickPopupY(type, panelHeight, screenHeight) {
        const edgeMargin = frameVisualInset + popupFrameGap
        const wanted = quickPopupCenterY - panelHeight / 2
        return Math.round(Math.max(edgeMargin, Math.min(screenHeight - panelHeight - edgeMargin, wanted)))
    }

    Timer {
        id: hoverCloseTimer

        interval: 360
        repeat: false
        onTriggered: root.clearHoveredSidebarPopup()
    }

    Timer {
        id: leftMenuCloseTimer

        interval: 280
        repeat: false
        onTriggered: {
            root.updateLeftMenuHovering()
            if (!root.leftMenuHovering)
                root.leftMenuOpen = false
        }
    }

    Timer {
        id: leftMediaWindowEntranceHoldTimer

        interval: Math.max(520, veloraTheme.motionPanelIn + 180)
        repeat: false
        onTriggered: {
            root.leftMediaWindowEntranceHold = false
            root.scheduleLeftMenuClose()
        }
    }

    Timer {
        id: leftMenuPreloadTimer

        interval: 700
        running: true
        repeat: false
        onTriggered: root.leftMenuPreloadEnabled = true
    }

    Timer {
        id: quickPopupUnmountTimer

        interval: veloraTheme.motionUnmountDelay
        repeat: false
        onTriggered: {
            if (!root.quickPopupVisible) {
                root.quickPopupWindowOpen = false
                root.renderedQuickPopupType = ""
            }
        }
    }

    Timer {
        id: wallpaperSelectorUnmountTimer

        interval: veloraTheme.motionUnmountDelay
        repeat: false
        onTriggered: {
            if (!root.wallpaperSelectorVisible)
                root.wallpaperSelectorWindowOpen = false
        }
    }

    Timer {
        id: wallpaperPreloadTimer

        interval: 900
        running: true
        repeat: false
        onTriggered: root.wallpaperPreloadEnabled = true
    }

    Timer {
        id: settingsPanelUnmountTimer

        interval: veloraTheme.motionUnmountDelay
        repeat: false
        onTriggered: {
            if (!root.settingsPanelVisible)
                root.settingsPanelWindowOpen = false
        }
    }

    IpcHandler {
        target: "velora"

        function focus(): void {
            root.enterFocus()
        }

        function unfocus(): void {
            root.exitFocus()
        }

        function toggleFocus(): void {
            root.toggleFocus()
        }

        function theme(): void {
            root.showWallpaperSelector(root.defaultQuickPopupCenterY("theme"))
        }

        function wallpaper(): void {
            theme()
        }

        function wallpaperFilter(): void {
            root.openWallpaperVisibility(root.defaultQuickPopupCenterY("theme"))
        }

        function filter(): void {
            wallpaperFilter()
        }

        function settings(): void {
            root.toggleSettingsPanel()
        }

        function pywal16(): void {
            veloraTheme.applyTheme("pywal16")
        }

        function reloadPywal16(): void {
            veloraTheme.reloadPywal16()
        }

        function search(): void {
            root.openQuickPopup("search")
        }

        function volume(): void {
            root.openQuickPopup("volume")
        }

        function wifi(): void {
            root.openQuickPopup("wifi")
        }

        function brightness(): void {
            root.openQuickPopup("brightness")
        }

        function notifications(): void {
            root.openQuickPopup("notifications")
        }

        function weather(): void {
            root.openRightDashboard("weather")
        }

        function system(): void {
            root.openRightDashboard("system")
        }

        function calendar(): void {
            root.openRightDashboard("calendar")
        }

        function media(): void {
            root.openRightDashboard("media")
        }

        function leftMedia(): void {
            root.openLeftMediaWindow(root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560)
        }

        function closeLeftMedia(): void {
            root.leftMediaWindowOpen = false
            root.leftMediaWindowEntranceHold = false
        }

        function memo(): void {
            root.openRightDashboard("memo")
        }

        function todo(): void {
            root.openRightDashboard("todo")
        }

        function closeDashboard(): void {
            root.closeRightDashboard()
        }

        function barLeft(): void {
            veloraTheme.setBarPosition("left")
        }

        function barRight(): void {
            veloraTheme.setBarPosition("right")
        }

        function frameOn(): void {
            veloraTheme.setDesktopFrameEnabled(true)
        }

        function frameOff(): void {
            veloraTheme.setDesktopFrameEnabled(false)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: leftMenuPanel

            required property var modelData
            property real reveal: root.leftMenuOpen ? 1 : 0
            property real mediaReveal: root.leftMenuOpen && root.leftMediaWindowOpen ? 1 : 0
            readonly property int slideDistance: root.leftMenuWidth + root.leftMenuFrameInset + root.leftMenuTriggerWidth + 8
            readonly property bool mediaWindowVisible: root.leftMediaWindowOpen || mediaReveal > 0.01
            readonly property int mediaWindowX: root.leftMenuFrameInset + root.leftMenuWidth + root.leftMediaWindowGap
            readonly property int mediaWindowSlideDistance: Math.min(118, Math.max(82, Math.round(root.leftMediaWindowWidth * 0.18)))

            screen: modelData
            color: "transparent"
            implicitWidth: Math.max(root.leftMenuTriggerWidth, root.leftMenuFrameInset + root.leftMenuWidth + 1, mediaWindowVisible ? mediaWindowX + root.leftMediaWindowWidth + root.leftMenuFrameInset : 0)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-left-menu"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
            }

            mask: Region {
                Region {
                    item: leftMenuTrigger
                    radius: 0
                }

                Region {
                    item: leftMenuInputMask
                    radius: leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 13
                }

                Region {
                    item: leftMediaWindowInputMask
                    radius: leftMediaWindowLoader.item ? leftMediaWindowLoader.item.cornerRadius : 22
                }
            }

            Behavior on reveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.leftMenuOpen ? veloraTheme.motionLayersIn : veloraTheme.motionLayersOut
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.leftMenuOpen ? veloraTheme.motionCurveEmphasizedDecel : veloraTheme.motionCurveEmphasizedAccel
                }
            }

            Behavior on mediaReveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.leftMediaWindowOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.leftMediaWindowOpen ? veloraTheme.motionCurveEmphasizedDecel : veloraTheme.motionCurveEmphasizedAccel
                }
            }

            Item {
                id: leftMenuTrigger

                x: 0
                y: 0
                width: root.leftMenuTriggerWidth
                height: parent.height

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        root.leftMenuTriggerHovering = true
                        root.updateLeftMenuHovering()
                        root.openLeftMenu()
                    }
                    onPositionChanged: {
                        root.leftMenuTriggerHovering = true
                        root.updateLeftMenuHovering()
                        root.openLeftMenu()
                    }
                    onExited: {
                        root.leftMenuTriggerHovering = false
                        root.scheduleLeftMenuClose()
                    }
                }
            }

            Item {
                id: leftMenuInputMask

                x: leftMenuLoader.x
                y: leftMenuLoader.y
                width: (root.leftMenuOpen || leftMenuPanel.reveal > 0.01) ? leftMenuLoader.width : 0
                height: (root.leftMenuOpen || leftMenuPanel.reveal > 0.01) ? leftMenuLoader.height : 0
            }

            Item {
                id: leftMediaWindowInputMask

                x: leftMediaWindowLoader.x
                y: leftMediaWindowLoader.y
                width: leftMediaWindowLoader.active ? leftMediaWindowLoader.width : 0
                height: leftMediaWindowLoader.active ? leftMediaWindowLoader.height : 0
            }

            VeloraAttachedSurface {
                theme: veloraTheme
                sidebarMaterial: true
                attachSide: "left"
                x: leftMenuLoader.x
                y: leftMenuLoader.y
                width: leftMenuLoader.width
                height: leftMenuLoader.height
                radius: leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 13
                revealProgress: 1
                visible: root.leftMenuOpen || leftMenuPanel.reveal > 0.01
            }

            Loader {
                id: leftMenuLoader

                active: root.leftMenuPreloadEnabled || root.leftMenuOpen || leftMenuPanel.reveal > 0.01
                asynchronous: true
                width: root.leftMenuWidth
                height: Math.max(0, parent.height - root.leftMenuFrameInset * 2)
                x: root.leftMenuFrameInset - Math.round((1 - leftMenuPanel.reveal) * leftMenuPanel.slideDistance)
                y: root.leftMenuFrameInset
                visible: root.leftMenuOpen || leftMenuPanel.reveal > 0.01
                opacity: 1

                sourceComponent: Component {
                    VeloraLeftMenu {
                        theme: veloraTheme
                        externalSurface: true
                        attachSide: "left"
                        popupType: "search"
                        open: root.leftMenuOpen
                        preload: root.leftMenuPreloadEnabled
                        interactiveFocus: false
                        width: leftMenuLoader.width
                        height: leftMenuLoader.height
                        visible: leftMenuLoader.visible

                        onMediaWindowRequested: function(centerY) {
                            root.openLeftMediaWindow(leftMenuLoader.y + centerY)
                        }

                        HoverHandler {
                            margin: 18
                            onHoveredChanged: {
                                root.leftMenuPanelHovering = hovered
                                root.updateLeftMenuHovering()
                                if (hovered)
                                    root.openLeftMenu()
                                else
                                    root.scheduleLeftMenuClose()
                            }
                        }
                    }
                }
            }

            VeloraAttachedSurface {
                theme: veloraTheme
                sidebarMaterial: true
                attachSide: "left"
                x: leftMediaWindowLoader.x
                y: leftMediaWindowLoader.y
                width: leftMediaWindowLoader.width
                height: leftMediaWindowLoader.height
                radius: leftMediaWindowLoader.cornerRadius
                revealProgress: leftMenuPanel.mediaReveal
                visible: leftMenuPanel.mediaWindowVisible
            }

            Loader {
                id: leftMediaWindowLoader

                readonly property int cornerRadius: item ? item.cornerRadius : 22

                active: leftMenuPanel.mediaWindowVisible
                asynchronous: false
                width: root.leftMediaWindowWidth
                height: root.leftMediaWindowHeight
                x: leftMenuPanel.mediaWindowX - Math.round((1 - leftMenuPanel.mediaReveal) * leftMenuPanel.mediaWindowSlideDistance)
                y: root.leftMediaWindowY(height, parent.height) + Math.round((1 - leftMenuPanel.mediaReveal) * 14)
                visible: active
                opacity: leftMenuPanel.mediaReveal
                scale: 0.94 + leftMenuPanel.mediaReveal * 0.06
                transformOrigin: Item.Left

                onActiveChanged: if (!active) root.leftMediaWindowHovering = false

                sourceComponent: Component {
                    VeloraDashboard {
                        theme: veloraTheme
                        compact: true
                        externalSurface: true
                        entryProgress: leftMenuPanel.mediaReveal
                        activeSection: "media"
                        width: leftMediaWindowLoader.width
                        height: leftMediaWindowLoader.height
                        visible: leftMediaWindowLoader.active

                        MouseArea {
                            anchors.fill: parent
                            enabled: leftMediaWindowLoader.active
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: {
                                root.leftMediaWindowHovering = true
                                root.updateLeftMenuHovering()
                                root.openLeftMenu()
                            }
                            onExited: {
                                root.leftMediaWindowHovering = false
                                root.scheduleLeftMenuClose()
                            }
                        }
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && leftMediaWindowLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled && leftMediaWindowLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }
            }
        }
    }

    Variants {
        model: root.frameVisualsMounted ? Quickshell.screens : []

        PanelWindow {
            id: framePanel

            required property var modelData
            readonly property bool compositorReservedBarSpace: modelData.width > 0 && width <= modelData.width - root.barPanelWidth + 2
            readonly property color frameMatteColor: root.desktopFrameMatteColor()
            readonly property color frameBorderColor: root.desktopFrameBorderColor()
            readonly property color frameHighlightColor: root.desktopFrameHighlightColor()

            visible: false
            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : 1
            implicitHeight: modelData.height > 0 ? modelData.height : 1
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-shell-frame"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {}

            function frameX() {
                if (compositorReservedBarSpace)
                    return root.desktopFrameMargin
                return root.mainAreaX(width)
            }

            function frameY() {
                return root.desktopFrameMargin
            }

            function frameWidth() {
                if (compositorReservedBarSpace)
                    return Math.max(0, width - root.desktopFrameMargin * 2)
                return Math.max(0, root.mainAreaWidth(width))
            }

            function frameHeight() {
                return Math.max(0, height - root.desktopFrameMargin * 2)
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Canvas {
                id: frameMatteCanvas

                anchors.fill: parent
                antialiasing: true
                visible: false
                opacity: root.frameVisualsReveal

                function paintCorner(ctx, corner, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    ctx.beginPath()

                    if (corner === "topLeft") {
                        ctx.moveTo(fx, fy)
                        ctx.lineTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, fy)
                    } else if (corner === "topRight") {
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, fy)
                    } else if (corner === "bottomRight") {
                        ctx.moveTo(x2, y2)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                        ctx.lineTo(x2, y2)
                    } else if (corner === "bottomLeft") {
                        ctx.moveTo(fx, y2)
                        ctx.lineTo(fx + radius, y2)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI / 2, Math.PI, false)
                        ctx.lineTo(fx, y2)
                    }

                    ctx.closePath()
                    ctx.fill()
                }

                function paintFrameOutline(ctx, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    const barSide = root.barOnRight ? "right" : "left"
                    const openSideTrim = Math.max(radius, root.sideVisualizerWaveWidth + 4)
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2 - radius

                    ctx.save()
                    ctx.strokeStyle = framePanel.frameBorderColor
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()

                    if (barSide !== "left") {
                        ctx.moveTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, y2 - radius)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI, Math.PI / 2, true)
                    } else {
                        ctx.moveTo(fx + radius, fy)
                    }

                    if (barSide !== "right") {
                        ctx.moveTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, fy)
                        ctx.lineTo(horizontalEnd, fy)
                        ctx.moveTo(horizontalStart, y2)
                        ctx.lineTo(horizontalEnd, y2)
                    }

                    ctx.stroke()
                    ctx.restore()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const fx = Math.round(framePanel.frameX())
                    const fy = Math.round(framePanel.frameY())
                    const fw = Math.round(framePanel.frameWidth())
                    const fh = Math.round(framePanel.frameHeight())
                    const radius = Math.min(root.desktopFrameRadius, Math.max(0, fw / 2), Math.max(0, fh / 2))

                    ctx.clearRect(0, 0, width, height)
                    if (!root.frameVisualsMounted || fw <= 0 || fh <= 0)
                        return

                    const barSide = root.barOnRight ? "right" : "left"

                    ctx.fillStyle = framePanel.frameMatteColor
                    ctx.fillRect(0, 0, width, fy)
                    ctx.fillRect(0, fy + fh, width, Math.max(0, height - fy - fh))
                    if (barSide !== "left") {
                        ctx.fillRect(0, fy, fx, fh)
                        paintCorner(ctx, "topLeft", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomLeft", fx, fy, fw, fh, radius)
                    }
                    if (barSide !== "right") {
                        ctx.fillRect(fx + fw, fy, Math.max(0, width - fx - fw), fh)
                        paintCorner(ctx, "topRight", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
                    }
                    paintFrameOutline(ctx, fx, fy, fw, fh, radius)
                }

                Component.onCompleted: if (root.frameVisualsMounted) requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            Rectangle {
                id: desktopFrame

                x: framePanel.frameX()
                y: framePanel.frameY()
                width: framePanel.frameWidth()
                height: framePanel.frameHeight()
                radius: root.desktopFrameRadius
                color: "transparent"
                border.width: 0
                border.color: framePanel.frameBorderColor
                opacity: root.frameVisualsReveal
                antialiasing: true
            }

            Rectangle {
                x: desktopFrame.x + 1
                y: desktopFrame.y + 1
                width: Math.max(0, desktopFrame.width - 2)
                height: Math.max(0, desktopFrame.height - 2)
                radius: Math.max(0, desktopFrame.radius - 1)
                color: "transparent"
                visible: false
                border.width: 1
                border.color: framePanel.frameHighlightColor
                antialiasing: true
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onSidebarOpacityChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onThemeModeChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onBorderSoftChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            readonly property bool wantsDrawerKeyboard: root.quickPopupType === "search" || root.settingsPanelOpen || root.wallpaperSelectorOpen

            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : root.barPanelWidth + root.quickPopupWidth(root.visibleQuickPopupType) + 24
            exclusiveZone: root.barReserveWidth
            exclusionMode: ExclusionMode.Normal
            focusable: wantsDrawerKeyboard

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: wantsDrawerKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                intersection: Intersection.Combine

                Region {
                    item: barRoot.panelMaskItem
                    radius: barRoot.cornerRadius
                }

                Region {
                    item: inlineQuickPopupInputMask
                    radius: inlineQuickPopupLoader.cornerRadius
                }

                Region {
                    item: inlineModalOverlayInputMask
                    radius: 0
                }

                Region {
                    item: inlineWallpaperInputMask
                    radius: inlineWallpaperLoader.cornerRadius
                }

                Region {
                    item: inlineSettingsInputMask
                    radius: inlineSettingsLoader.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: !root.barOnRight
                right: root.barOnRight
            }

            Canvas {
                id: unifiedFrameCanvas

                anchors.fill: parent
                antialiasing: true
                visible: root.frameVisualsMounted
                opacity: 1
                z: 0

                function roundedRectPath(ctx, x, y, w, h, radius) {
                    const r = Math.min(radius, Math.max(0, w / 2), Math.max(0, h / 2))
                    const x2 = x + w
                    const y2 = y + h

                    ctx.beginPath()
                    ctx.moveTo(x + r, y)
                    ctx.lineTo(x2 - r, y)
                    ctx.arcTo(x2, y, x2, y + r, r)
                    ctx.lineTo(x2, y2 - r)
                    ctx.arcTo(x2, y2, x2 - r, y2, r)
                    ctx.lineTo(x + r, y2)
                    ctx.arcTo(x, y2, x, y2 - r, r)
                    ctx.lineTo(x, y + r)
                    ctx.arcTo(x, y, x + r, y, r)
                    ctx.closePath()
                }

                function paintCorner(ctx, corner, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    ctx.beginPath()

                    if (corner === "topLeft") {
                        ctx.moveTo(fx, fy)
                        ctx.lineTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, fy)
                    } else if (corner === "topRight") {
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, fy)
                    } else if (corner === "bottomRight") {
                        ctx.moveTo(x2, y2)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                        ctx.lineTo(x2, y2)
                    } else if (corner === "bottomLeft") {
                        ctx.moveTo(fx, y2)
                        ctx.lineTo(fx + radius, y2)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI / 2, Math.PI, false)
                        ctx.lineTo(fx, y2)
                    }

                    ctx.closePath()
                    ctx.fill()
                }

                function paintFrameOutline(ctx, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    const barSide = root.barOnRight ? "right" : "left"
                    const openSideTrim = Math.max(radius, root.sideVisualizerWaveWidth + 4)
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2 - radius

                    ctx.save()
                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()

                    if (barSide !== "left") {
                        ctx.moveTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, y2 - radius)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI, Math.PI / 2, true)
                    }

                    if (barSide !== "right") {
                        ctx.moveTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, fy)
                        ctx.lineTo(horizontalEnd, fy)
                        ctx.moveTo(horizontalStart, y2)
                        ctx.lineTo(horizontalEnd, y2)
                    }

                    ctx.stroke()
                    ctx.restore()
                }

                function paintSidebarGutterFill(ctx) {
                    const bx = Math.round(root.barX(width))
                    const by = root.sidebarVerticalMargin
                    const bw = root.sidebarVisualWidth
                    const bh = Math.max(0, height - root.sidebarVerticalMargin * 2)
                    const radius = Math.min(root.sidebarCornerRadius, Math.max(0, bw / 2), Math.max(0, bh / 2))
                    const frameTop = root.desktopFrameMargin
                    const frameBottom = Math.max(frameTop, height - root.desktopFrameMargin)
                    const capX = root.barOnRight ? bx : 0
                    const capW = root.barOnRight ? Math.max(0, width - bx) : Math.max(0, bx + bw)
                    const outerStripX = root.barOnRight ? bx + bw : 0
                    const outerStripW = root.barOnRight ? Math.max(0, width - bx - bw) : Math.max(0, bx)

                    if (bw <= 0 || bh <= 0)
                        return

                    ctx.save()
                    ctx.fillStyle = root.sidebarPanelMaterialColor()
                    ctx.fillRect(capX, frameTop, capW, Math.max(0, by - frameTop))
                    ctx.fillRect(capX, by + bh, capW, Math.max(0, frameBottom - by - bh))
                    ctx.fillRect(outerStripX, by, outerStripW, bh)

                    paintCorner(ctx, "topLeft", bx, by, bw, bh, radius)
                    paintCorner(ctx, "topRight", bx, by, bw, bh, radius)
                    paintCorner(ctx, "bottomRight", bx, by, bw, bh, radius)
                    paintCorner(ctx, "bottomLeft", bx, by, bw, bh, radius)

                    ctx.fillStyle = root.sidebarBarMaterialColor()
                    roundedRectPath(ctx, bx, by, bw, bh, radius)
                    ctx.fill()
                    ctx.restore()
                }

                function paintSidebarSurface(ctx) {
                    const bx = Math.round(root.barX(width))
                    const by = root.sidebarVerticalMargin
                    const bw = root.sidebarVisualWidth
                    const bh = Math.max(0, height - root.sidebarVerticalMargin * 2)
                    const radius = Math.min(root.sidebarCornerRadius, Math.max(0, bw / 2), Math.max(0, bh / 2))

                    if (bw <= 0 || bh <= 0)
                        return

                    ctx.save()

                    ctx.strokeStyle = root.sidebarPanelBorderColor()
                    ctx.lineWidth = 1
                    roundedRectPath(ctx, bx + 0.5, by + 0.5, Math.max(0, bw - 1), Math.max(0, bh - 1), Math.max(0, radius - 0.5))
                    ctx.stroke()

                    ctx.strokeStyle = root.sidebarPanelInnerLineColor()
                    ctx.lineWidth = 1
                    roundedRectPath(ctx, bx + 1.5, by + 1.5, Math.max(0, bw - 3), Math.max(0, bh - 3), Math.max(0, radius - 1.5))
                    ctx.stroke()
                    ctx.restore()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const fx = root.mainAreaX(width)
                    const fy = root.desktopFrameMargin
                    const fw = root.mainAreaWidth(width)
                    const fh = Math.max(0, height - root.desktopFrameMargin * 2)
                    const radius = Math.min(root.desktopFrameRadius, Math.max(0, fw / 2), Math.max(0, fh / 2))
                    const barSide = root.barOnRight ? "right" : "left"

                    ctx.clearRect(0, 0, width, height)
                    if (!root.frameVisualsMounted || fw <= 0 || fh <= 0)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    ctx.fillRect(0, 0, width, fy)
                    ctx.fillRect(0, fy + fh, width, Math.max(0, height - fy - fh))

                    if (barSide !== "left") {
                        ctx.fillRect(0, fy, fx, fh)
                        paintCorner(ctx, "topLeft", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomLeft", fx, fy, fw, fh, radius)
                    }

                    if (barSide !== "right") {
                        ctx.fillRect(fx + fw, fy, Math.max(0, width - fx - fw), fh)
                        paintCorner(ctx, "topRight", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
                    }

                    paintFrameOutline(ctx, fx, fy, fw, fh, radius)
                    ctx.restore()

                    paintSidebarGutterFill(ctx)
                    paintSidebarSurface(ctx)
                }

                Component.onCompleted: if (root.frameVisualsMounted) requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSurfaceSidebarChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSidebarOpacityChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onBarOpacityChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onThemeModeChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onThemeIdChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSidebarBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onBorderSoftChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsMountedChanged() { unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Item {
                id: sideVisualizerRail

                readonly property int frameEdgeX: Math.round(root.barOnRight
                    ? root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                    : root.mainAreaX(parent.width))
                readonly property int barEdgeX: Math.round(root.barOnRight
                    ? root.barX(parent.width)
                    : root.barX(parent.width) + root.sidebarVisualWidth)
                readonly property int gutterSpan: Math.max(0, root.barOnRight
                    ? barEdgeX - frameEdgeX
                    : frameEdgeX - barEdgeX)
                readonly property int railOverlap: 2
                readonly property int bandCount: barRoot.cavaBandCount || 40
                readonly property int waveWidth: root.sideVisualizerWaveWidth
                readonly property int railWidth: waveWidth + gutterSpan
                readonly property real waveStrength: veloraTheme.visualizerStrength
                readonly property real centerX: root.barOnRight ? waveWidth - 2 : gutterSpan + 2
                readonly property int waveDirection: root.barOnRight ? -1 : 1
                readonly property real localFrameEdgeX: frameEdgeX - x
                readonly property real localBarEdgeX: barEdgeX - x
                readonly property real bridgeLeftX: Math.max(0, Math.min(localFrameEdgeX, localBarEdgeX) - 1)
                readonly property real bridgeRightX: Math.min(width, Math.max(localFrameEdgeX, localBarEdgeX) + 2)
                readonly property bool activeForPaint: root.frameVisualsMounted && visible && panel.visible && width > 0 && height > 0

                function requestWaveformPaint(force) {
                    if (!activeForPaint) {
                        waveformPaintTimer.stop()
                        if (force)
                            waveformCanvas.requestPaint()
                        return
                    }

                    if (force) {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                        return
                    }

                    if (!waveformPaintTimer.running)
                        waveformPaintTimer.restart()
                }

                x: root.barOnRight ? frameEdgeX - waveWidth + 1 : barEdgeX - 1
                y: root.frameVisualInset - 1
                width: root.frameVisualsMounted ? railWidth : 0
                height: root.frameVisualsMounted ? Math.max(0, parent.height - root.frameVisualInset * 2 + 2) : 0
                visible: root.frameVisualsMounted
                opacity: root.frameVisualsReveal
                clip: true
                z: 1

                onActiveForPaintChanged: {
                    if (activeForPaint)
                        requestWaveformPaint(true)
                    else {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                    }
                }

                Canvas {
                    id: waveformCanvas

                    anchors.fill: parent
                    antialiasing: true

                    function rawVisualizerValue(index) {
                        if (!barRoot.cavaValues || barRoot.cavaValues.length <= 0)
                            return 0

                        const value = Number(barRoot.cavaValues[Math.max(0, Math.min(index, barRoot.cavaValues.length - 1))])
                        return Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
                    }

                    function pointAt(index) {
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const top = 1
                        const bottom = Math.max(top + 1, height - 1)
                        const step = (bottom - top) / (count - 1)
                        const lifted = rawVisualizerValue(index)
                        const maxAmp = Math.max(16, sideVisualizerRail.waveWidth * sideVisualizerRail.waveStrength)
                        const edgeFade = Math.min(1, index / 5, (count - 1 - index) / 5)
                        const amp = Math.min(maxAmp, Math.pow(lifted, 0.82) * maxAmp) * edgeFade
                        const pulse = 0.78 + Math.abs(Math.sin(index * 0.70)) * 0.22

                        return {
                            x: sideVisualizerRail.centerX + sideVisualizerRail.waveDirection * amp * pulse,
                            y: top + step * index
                        }
                    }

                    function moldedEdgeX() {
                        return root.barOnRight ? width : 0
                    }

                    function continueSmoothLine(ctx, points) {
                        continueSmoothLineRange(ctx, points, 0, points.length - 1)
                    }

                    function continueSmoothLineRange(ctx, points, startIndex, endIndex) {
                        const start = Math.max(0, Math.min(points.length - 1, startIndex))
                        const end = Math.max(start, Math.min(points.length - 1, endIndex))

                        for (let i = start + 1; i <= end; i += 1) {
                            const previous = points[i - 1]
                            const current = points[i]
                            const midX = (previous.x + current.x) / 2
                            const midY = (previous.y + current.y) / 2
                            ctx.quadraticCurveTo(previous.x, previous.y, midX, midY)
                        }

                        const last = points[end]
                        ctx.lineTo(last.x, last.y)
                    }

                    function smoothLine(ctx, points) {
                        if (points.length <= 0)
                            return

                        ctx.moveTo(points[0].x, points[0].y)
                        continueSmoothLine(ctx, points)
                    }

                    function moldedFramePath(ctx, points) {
                        if (points.length <= 0)
                            return

                        const geometry = moldedCapGeometry(points)
                        ctx.moveTo(geometry.capX, 0)
                        ctx.bezierCurveTo(geometry.controlX, 0, geometry.topJoin.x, geometry.topCurveY, geometry.topJoin.x, geometry.topJoin.y)
                        continueSmoothLineRange(ctx, points, geometry.topIndex, geometry.bottomIndex)
                        ctx.bezierCurveTo(geometry.bottomJoin.x, geometry.bottomCurveY, geometry.controlX, height, geometry.capX, height)
                    }

                    function moldedGlassPath(ctx, points) {
                        if (points.length <= 0)
                            return

                        const edgeX = moldedEdgeX()
                        const geometry = moldedCapGeometry(points)

                        ctx.moveTo(geometry.capX, 0)
                        ctx.bezierCurveTo(geometry.controlX, 0, geometry.topJoin.x, geometry.topCurveY, geometry.topJoin.x, geometry.topJoin.y)
                        continueSmoothLineRange(ctx, points, geometry.topIndex, geometry.bottomIndex)
                        ctx.bezierCurveTo(geometry.bottomJoin.x, geometry.bottomCurveY, geometry.controlX, height, geometry.capX, height)
                        ctx.lineTo(edgeX, height)
                        ctx.lineTo(edgeX, 0)
                        ctx.closePath()
                    }

                    function moldedCapGeometry(points) {
                        const edgeX = moldedEdgeX()
                        const side = root.barOnRight ? -1 : 1
                        const capReach = Math.min(38, width * 0.46)
                        const capControl = capReach * 0.52
                        const topIndex = Math.min(points.length - 1, Math.max(2, Math.round(points.length * 0.055)))
                        const bottomIndex = Math.max(topIndex, points.length - 1 - topIndex)
                        const topJoin = points[topIndex]
                        const bottomJoin = points[bottomIndex]
                        const capX = Math.max(0, Math.min(width, edgeX + side * capReach))
                        const controlX = Math.max(0, Math.min(width, edgeX + side * capControl))
                        const topCurveY = Math.max(6, topJoin.y * 0.34)
                        const bottomCurveY = Math.min(height - 6, height - (height - bottomJoin.y) * 0.34)

                        return {
                            topIndex: topIndex,
                            bottomIndex: bottomIndex,
                            topJoin: topJoin,
                            bottomJoin: bottomJoin,
                            capX: capX,
                            controlX: controlX,
                            topCurveY: topCurveY,
                            bottomCurveY: bottomCurveY
                        }
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const wave = []
                        var peak = 0

                        ctx.clearRect(0, 0, width, height)
                        if (!sideVisualizerRail.activeForPaint)
                            return

                        for (let i = 0; i < count; i += 1) {
                            peak = Math.max(peak, rawVisualizerValue(i))
                            wave.push(pointAt(i))
                        }

                        ctx.save()
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        ctx.fillStyle = root.sideRailMaterialColor()
                        ctx.beginPath()
                        moldedGlassPath(ctx, wave)
                        ctx.fill()

                        if (peak >= 0.045) {
                            const waveAlpha = Math.min(0.22, 0.08 + peak * 0.24)
                            ctx.strokeStyle = veloraTheme.alpha(root.sidebarPanelBorderColor(), veloraTheme.themeId === "pywal16" ? waveAlpha : Math.min(0.42, waveAlpha + 0.08))
                            ctx.lineWidth = 0.75
                            ctx.beginPath()
                            smoothLine(ctx, wave)
                            ctx.stroke()
                        }

                        ctx.restore()
                    }

                    Component.onCompleted: sideVisualizerRail.requestWaveformPaint(true)
                    onWidthChanged: sideVisualizerRail.requestWaveformPaint(true)
                    onHeightChanged: sideVisualizerRail.requestWaveformPaint(true)
                }

                Timer {
                    id: waveformPaintTimer

                    interval: 16
                    repeat: false
                    onTriggered: {
                        if (sideVisualizerRail.activeForPaint)
                            waveformCanvas.requestPaint()
                    }
                }

                Connections {
                    target: barRoot
                    function onCavaValuesChanged() {
                        if (root.frameVisualsMounted)
                            sideVisualizerRail.requestWaveformPaint(false)
                    }
                }

                Connections {
                    target: veloraTheme
                    function onActiveTextChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onThemeModeChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onThemeIdChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerStrengthChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSurfaceBaseChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSurfaceSidebarChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSidebarBorderGlowChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onBorderSoftChanged() { if (root.frameVisualsMounted) sideVisualizerRail.requestWaveformPaint(true) }
                }
            }

            Rectangle {
                id: sideVisualizerFrameVeil

                readonly property int frameEdgeX: Math.round(root.barOnRight
                    ? root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                    : root.mainAreaX(parent.width))

                x: frameEdgeX - 1
                y: root.frameVisualInset
                width: 2
                height: root.frameVisualsMounted ? Math.max(0, parent.height - root.frameVisualInset * 2) : 0
                visible: false && root.frameVisualsMounted
                color: root.desktopFrameBorderColor()
                opacity: root.frameVisualsReveal * (veloraTheme.themeMode === "dark" ? 0.72 : 0.86)
                antialiasing: false
                z: 3
            }

            Rectangle {
                id: rightSoftBackRail

                readonly property int railX: Math.round(root.barX(parent.width) + root.sidebarVisualWidth)

                x: railX
                y: root.frameVisualInset
                width: Math.max(0, parent.width - railX)
                height: root.frameVisualsMounted ? Math.max(0, parent.height - root.frameVisualInset * 2) : 0
                visible: false && root.frameVisualsMounted
                color: "transparent"
                border.width: 1
                border.color: veloraTheme.alpha(veloraTheme.sidebarBorderGlow, 0.20)
                antialiasing: false
            }

            VeloraBarV2 {
                id: barRoot

                theme: veloraTheme
                z: 10
                width: root.sidebarVisualWidth
                x: root.barX(parent.width)
                focusMode: root.focusMode
                focusIndex: root.focusIndex
                focusTarget: root.focusTarget
                visualizerActive: root.frameVisualsEnabled && sideVisualizerRail.activeForPaint
                shellDrawsPanelSurface: root.frameVisualsMounted
                activePopupType: root.wallpaperSelectorVisible ? "theme" : (root.settingsPanelVisible ? "settings" : root.activeQuickPopupType)
                onMoveFocusRequested: function(dir) {
                    root.moveFocus(dir)
                }
                onExitFocusRequested: root.exitFocus()
                onThemeRequested: function(centerY) {
                    const fromFocusedBrush = root.focusMode && root.focusTarget === "theme"
                    const localCenter = Number(centerY)
                    const popupCenter = localCenter > 0 ? barRoot.y + localCenter : root.defaultQuickPopupCenterY("theme")
                    root.toggleWallpaperSelector(popupCenter, fromFocusedBrush)
                }
                onSettingsRequested: function(centerY) {
                    const localCenter = Number(centerY)
                    root.toggleSettingsPanel(localCenter > 0 ? barRoot.y + localCenter : root.defaultQuickPopupCenterY("settings"))
                }
                onQuickPopupRequested: function(type, centerY) {
                    root.toggleQuickPopup(type, barRoot.y + centerY)
                }
                onQuickPopupHovered: function(type, centerY) {
                    root.previewSidebarPopup(type, barRoot.y + centerY)
                }
                onQuickPopupHoverEnded: function(type) {
                    root.endSidebarPopupHover(type)
                }
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    topMargin: root.sidebarVerticalMargin
                    bottomMargin: root.sidebarVerticalMargin
                }
            }

            Item {
                id: inlineModalOverlayInputMask

                x: 0
                y: 0
                width: root.settingsPanelOpen || root.wallpaperSelectorOpen ? panel.width : 0
                height: root.settingsPanelOpen || root.wallpaperSelectorOpen ? panel.height : 0
            }

            Item {
                id: inlineQuickPopupInputMask

                x: inlineQuickPopupLoader.x
                y: inlineQuickPopupLoader.y
                width: inlineQuickPopupLoader.active ? inlineQuickPopupLoader.width : 0
                height: inlineQuickPopupLoader.active ? inlineQuickPopupLoader.height : 0
            }

            VeloraAttachedSurface {
                id: inlineQuickPopupSurface

                z: 20
                theme: veloraTheme
                attachSide: root.popupAttachSide
                x: inlineQuickPopupLoader.x
                y: inlineQuickPopupLoader.y
                width: inlineQuickPopupLoader.width
                height: inlineQuickPopupLoader.height
                radius: inlineQuickPopupLoader.cornerRadius
                revealProgress: inlineQuickPopupLoader.revealProgress
                visible: root.quickPopupPanelVisible
            }

            Loader {
                id: inlineQuickPopupLoader

                readonly property int cornerRadius: item ? item.cornerRadius : 13
                readonly property real revealProgress: item ? item.revealProgress : 0

                active: root.quickPopupPanelVisible
                asynchronous: false
                z: 21
                width: root.quickPopupWidth(root.visibleQuickPopupType)
                height: root.quickPopupHeight(root.visibleQuickPopupType)
                x: root.quickPopupX(parent.width, width)
                y: root.quickPopupY(root.visibleQuickPopupType, height, parent.height)
                visible: active

                onActiveChanged: if (!active) root.quickPopupHovering = false

                sourceComponent: Component {
                    VeloraSidePopup {
                        theme: veloraTheme
                        externalSurface: true
                        attachSide: root.popupAttachSide
                        popupType: root.visibleQuickPopupType
                        open: root.quickPopupVisible
                        interactiveFocus: root.quickPopupType === "search"
                        width: inlineQuickPopupLoader.width
                        height: inlineQuickPopupLoader.height
                        visible: inlineQuickPopupLoader.active
                        onCloseRequested: root.closeQuickPopup()
                        onPointerInsideChanged: function(inside) {
                            root.quickPopupHovering = inside
                            if (inside)
                                hoverCloseTimer.stop()
                            else if (root.hoverPopupType.length > 0)
                                root.scheduleHoverClose()
                        }
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on width {
                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }
            }

            Item {
                id: inlineModalLayer

                z: 40
                anchors.fill: parent
                visible: root.wallpaperSelectorPanelVisible || root.settingsPanelPanelVisible
                focus: root.wallpaperSelectorOpen || root.settingsPanelOpen

                Keys.onEscapePressed: {
                    root.wallpaperSelectorOpen = false
                    root.settingsPanelOpen = false
                }

                Keys.onPressed: function(event) {
                    if (root.wallpaperSelectorOpen) {
                        const selector = inlineWallpaperLoader.item
                        if (!selector)
                            return

                        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                            selector.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                            selector.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
                            selector.cycleWallpaperMode(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
                            selector.cycleWallpaperMode(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            selector.applySelected()
                            event.accepted = true
                            return
                        }
                    }

                    if (root.settingsPanelOpen) {
                        const settings = inlineSettingsLoader.item
                        if (!settings)
                            return

                        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                            settings.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                            settings.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            settings.applySelected()
                            event.accepted = true
                        }
                    }
                }

                MouseArea {
                    z: 0
                    anchors.fill: parent
                    enabled: root.wallpaperSelectorOpen || root.settingsPanelOpen
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        root.wallpaperSelectorOpen = false
                        root.settingsPanelOpen = false
                    }
                }

                Item {
                    id: inlineWallpaperInputMask

                    x: inlineWallpaperLoader.x
                    y: inlineWallpaperLoader.y
                    width: root.wallpaperSelectorPanelVisible ? inlineWallpaperLoader.width : 0
                    height: root.wallpaperSelectorPanelVisible ? inlineWallpaperLoader.height : 0
                }

                VeloraAttachedSurface {
                    z: 2
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    x: inlineWallpaperLoader.x
                    y: inlineWallpaperLoader.y
                    width: inlineWallpaperLoader.width
                    height: inlineWallpaperLoader.height
                    radius: inlineWallpaperLoader.cornerRadius
                    revealProgress: inlineWallpaperLoader.revealProgress
                    visible: false
                }

                Loader {
                    id: inlineWallpaperLoader

                    readonly property int cornerRadius: item ? item.cornerRadius : 28
                    readonly property real revealProgress: item ? item.revealProgress : 0
                    readonly property int availableWidth: Math.max(340, root.mainAreaWidth(parent.width) - root.popupFrameGap * 2)
                    readonly property int availableHeight: Math.max(360, parent.height - root.frameVisualInset * 2 - 24)

                    active: root.wallpaperSelectorPanelVisible || root.wallpaperPreloadEnabled
                    asynchronous: false
                    z: 3
                    width: Math.round(Math.min(790, availableWidth, Math.max(570, availableWidth * 0.47)))
                    height: Math.round(Math.min(475, availableHeight, Math.max(330, width * 0.60)))
                    x: Math.round(root.mainAreaX(parent.width) + Math.max(0, (root.mainAreaWidth(parent.width) - width) / 2))
                    y: Math.round(Math.max(root.frameVisualInset, parent.height - height - 12))
                    visible: root.wallpaperSelectorPanelVisible

                    onActiveChanged: if (!active) root.wallpaperSelectorHovering = false

                    sourceComponent: Component {
                        VeloraWallpaperSelector {
                            theme: veloraTheme
                            externalSurface: true
                            attachSide: root.popupAttachSide
                            width: inlineWallpaperLoader.width
                            height: inlineWallpaperLoader.height
                            open: root.wallpaperSelectorVisible
                            preload: root.wallpaperPreloadEnabled
                            visible: inlineWallpaperLoader.active
                            focus: root.wallpaperSelectorOpen
                            onCloseRequested: root.wallpaperSelectorOpen = false
                            onVisibilityRequested: root.openWallpaperVisibility(root.defaultQuickPopupCenterY("theme"))

                            HoverHandler {
                                margin: 24
                                onHoveredChanged: {
                                    root.wallpaperSelectorHovering = hovered
                                    if (hovered)
                                        hoverCloseTimer.stop()
                                    else
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }

                    Behavior on y {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on width {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on height {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }
                }

                Item {
                    id: inlineSettingsInputMask

                    x: inlineSettingsLoader.x
                    y: inlineSettingsLoader.y
                    width: inlineSettingsLoader.active ? inlineSettingsLoader.width : 0
                    height: inlineSettingsLoader.active ? inlineSettingsLoader.height : 0
                }

                VeloraAttachedSurface {
                    z: 4
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    x: inlineSettingsLoader.x
                    y: inlineSettingsLoader.y
                    width: inlineSettingsLoader.width
                    height: inlineSettingsLoader.height
                    radius: inlineSettingsLoader.cornerRadius
                    revealProgress: inlineSettingsLoader.revealProgress
                    visible: root.settingsPanelPanelVisible
                }

                Loader {
                    id: inlineSettingsLoader

                    readonly property int cornerRadius: item ? item.cornerRadius : 18
                    readonly property real revealProgress: item ? item.revealProgress : (root.settingsPanelVisible ? 1 : 0)

                    active: root.settingsPanelPanelVisible
                    asynchronous: true
                    z: 5
                    width: Math.round(Math.min(root.quickPopupWidth("settings"), parent.width * 0.49))
                    height: Math.round(Math.min(root.quickPopupHeight("settings"), width * 0.66))
                    x: root.attachedPopupX(parent.width, width)
                    y: root.quickPopupY("settings", height, parent.height)
                    visible: active

                    onActiveChanged: if (!active) root.settingsPanelHovering = false

                    sourceComponent: Component {
                        VeloraSettingsPanel {
                            theme: veloraTheme
                            externalSurface: true
                            attachSide: root.popupAttachSide
                            width: inlineSettingsLoader.width
                            height: inlineSettingsLoader.height
                            open: root.settingsPanelVisible
                            visible: inlineSettingsLoader.active
                            focus: root.settingsPanelOpen
                            onCloseRequested: root.settingsPanelOpen = false

                            HoverHandler {
                                margin: 24
                                onHoveredChanged: {
                                    root.settingsPanelHovering = hovered
                                    if (hovered)
                                        hoverCloseTimer.stop()
                                    else
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }

                    Behavior on y {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on width {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on height {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }
                }

                Connections {
                    target: root

                    function onWallpaperSelectorOpenChanged() {
                        if (root.wallpaperSelectorOpen)
                            Qt.callLater(function() {
                                if (inlineWallpaperLoader.item)
                                    inlineWallpaperLoader.item.forceActiveFocus()
                            })
                    }

                    function onSettingsPanelOpenChanged() {
                        if (root.settingsPanelOpen)
                            Qt.callLater(function() {
                                if (inlineSettingsLoader.item)
                                    inlineSettingsLoader.item.forceActiveFocus()
                            })
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dashboardPanel

            required property var modelData
            property real dashboardReveal: !root.rightSoftLayout && root.rightDashboardOpen ? 1 : 0
            property bool dashboardCardHovering: false
            readonly property bool dashboardOnLeft: root.barOnRight
            readonly property int triggerWidth: 34
            readonly property int cardWidth: 372
            readonly property int panelWidth: cardWidth + triggerWidth
            readonly property var sections: [
                { id: "weather", y: 16, height: 206 },
                { id: "system", y: 232, height: 162 },
                { id: "calendar", y: 404, height: 218 },
                { id: "media", y: 632, height: 166 },
                { id: "memo", y: 808, height: 154 },
                { id: "todo", y: 972, height: 180 }
            ]
            readonly property int activeCardY: sectionY(root.rightDashboardSection)
            readonly property int activeCardHeight: sectionHeight(root.rightDashboardSection)

            visible: !root.rightSoftLayout
            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Behavior on dashboardReveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.rightDashboardOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
                    easing.type: root.rightDashboardOpen ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
                }
            }

            function sectionAtY(localY) {
                for (let i = 0; i < sections.length; i += 1) {
                    const section = sections[i]
                    if (localY >= section.y && localY <= section.y + section.height)
                        return section.id
                }

                return ""
            }

            function sectionData(sectionId) {
                for (let i = 0; i < sections.length; i += 1) {
                    if (sections[i].id === sectionId)
                        return sections[i]
                }

                return sections[0]
            }

            function sectionY(sectionId) {
                return sectionData(sectionId).y
            }

            function sectionHeight(sectionId) {
                return sectionData(sectionId).height
            }

            function requestDashboardOpen(section) {
                if (section && section.length > 0)
                    root.rightDashboardSection = section

                dashboardCloseDelay.stop()
                root.rightDashboardOpen = true
            }

            function dashboardHovering() {
                return dashboardTriggerMouse.containsMouse || dashboardCardHovering
            }

            function requestDashboardClose() {
                if (!dashboardHovering())
                    dashboardCloseDelay.restart()
            }

            mask: Region {
                Region {
                    item: dashboardInteractionArea
                    radius: 0
                }

                Region {
                    item: dashboardCardInputMask
                    radius: dashboardLoader.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: dashboardOnLeft
                right: !dashboardOnLeft
            }

            Timer {
                id: dashboardCloseDelay

                interval: 260
                repeat: false
                onTriggered: {
                    if (!dashboardPanel.dashboardHovering())
                        root.rightDashboardOpen = false
                }
            }

            Item {
                id: dashboardInteractionArea

                x: dashboardPanel.dashboardOnLeft ? 0 : dashboardPanel.width - dashboardPanel.triggerWidth
                y: 0
                width: dashboardPanel.triggerWidth
                height: dashboardPanel.height

                MouseArea {
                    id: dashboardTriggerMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        const section = dashboardPanel.sectionAtY(mouseY)
                        if (section.length > 0)
                            dashboardPanel.requestDashboardOpen(section)
                    }
                    onPositionChanged: function(mouse) {
                        const section = dashboardPanel.sectionAtY(mouse.y)
                        if (section.length > 0)
                            dashboardPanel.requestDashboardOpen(section)
                        else
                            dashboardPanel.requestDashboardClose()
                    }
                    onExited: dashboardPanel.requestDashboardClose()
                }
            }

            Item {
                id: dashboardCardInputMask

                x: dashboardLoader.x
                y: dashboardLoader.y
                width: dashboardLoader.active ? dashboardLoader.width : 0
                height: dashboardLoader.active ? dashboardLoader.height : 0
            }

            Loader {
                id: dashboardLoader

                readonly property int cornerRadius: item ? item.cornerRadius : 22

                active: dashboardPanel.visible && (root.rightDashboardOpen || dashboardPanel.dashboardReveal > 0.01)
                asynchronous: true
                width: dashboardPanel.cardWidth
                height: dashboardPanel.activeCardHeight
                x: dashboardPanel.dashboardOnLeft ? dashboardPanel.triggerWidth : dashboardPanel.width - dashboardPanel.triggerWidth - width
                y: dashboardPanel.activeCardY
                visible: active
                opacity: dashboardPanel.dashboardReveal
                scale: 0.982 + dashboardPanel.dashboardReveal * 0.018
                transformOrigin: dashboardPanel.dashboardOnLeft ? Item.Left : Item.Right
                transform: Translate {
                    x: Math.round((1 - dashboardPanel.dashboardReveal) * (dashboardPanel.dashboardOnLeft ? -28 : 28))
                    y: Math.round((1 - dashboardPanel.dashboardReveal) * -4)
                }

                sourceComponent: Component {
                    VeloraDashboard {
                        theme: veloraTheme
                        compact: true
                        activeSection: root.rightDashboardSection
                        width: dashboardLoader.width
                        height: dashboardLoader.height
                        visible: dashboardLoader.active
                        onThemeRequested: function(centerY) {
                            root.rightDashboardOpen = false
                            root.showWallpaperSelector(Number(centerY) > 0 ? centerY : root.defaultQuickPopupCenterY("theme"))
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: dashboardLoader.active
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: {
                                dashboardPanel.dashboardCardHovering = true
                                dashboardPanel.requestDashboardOpen(root.rightDashboardSection)
                            }
                            onExited: {
                                dashboardPanel.dashboardCardHovering = false
                                dashboardPanel.requestDashboardClose()
                            }
                        }
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

            }
        }
    }

}
