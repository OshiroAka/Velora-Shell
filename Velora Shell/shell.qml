import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"

ShellRoot {
    id: root

    VeloraTheme {
        id: veloraTheme
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
    property bool rightDashboardOpen: false
    property string rightDashboardSection: "weather"
    property bool focusMode: false
    property int focusIndex: 0
    readonly property bool barOnRight: veloraTheme.barPosition === "right"
    readonly property bool rightSoftLayout: barOnRight
    readonly property int sidebarVisualWidth: rightSoftLayout ? 112 : 108
    readonly property int sidebarOuterMargin: rightSoftLayout ? 18 : 0
    readonly property int sidebarVerticalMargin: rightSoftLayout ? 20 : desktopFrameMargin
    readonly property int barPanelWidth: sidebarVisualWidth + sidebarOuterMargin
    readonly property int barReserveWidth: barPanelWidth
    readonly property int desktopFrameMargin: rightSoftLayout ? 14 : 20
    readonly property int desktopFrameRadius: 10
    readonly property real desktopFrameMatteOpacity: rightSoftLayout
        ? (veloraTheme.themeMode === "dark" ? 0.055 : Math.max(0.10, Math.min(0.18, veloraTheme.sidebarOpacity * 0.16)))
        : Math.max(0, Math.min(0.18, veloraTheme.sidebarOpacity * 0.20))
    readonly property int popupFrameGap: rightSoftLayout ? 14 : 0
    readonly property string popupAttachSide: barOnRight ? "right" : "left"
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

    function desktopFrameMatteColor() {
        return veloraTheme.alpha(veloraTheme.surfaceBase, desktopFrameMatteOpacity)
    }

    function desktopFrameBorderColor() {
        return rightSoftLayout
            ? veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.16 : 0.24)
            : veloraTheme.alpha(veloraTheme.popupBorderGlow, veloraTheme.themeMode === "dark" ? 0.42 : 0.26)
    }

    function desktopFrameHighlightColor() {
        return rightSoftLayout
            ? "transparent"
            : veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.24 : 0.34)
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

    function quickPopupArrowCenter(type) {
        if (type === "volume")
            return 78
        if (type === "wifi")
            return 288
        if (type === "brightness")
            return 248
        if (type === "notifications")
            return 414
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

        if (!sidebarPopupHovering && !quickPopupHovering && !wallpaperSelectorHovering && !settingsPanelHovering)
            hoverPopupType = ""
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

    function barX(screenWidth) {
        return barOnRight ? Math.max(0, screenWidth - sidebarOuterMargin - sidebarVisualWidth) : 0
    }

    function mainAreaX(screenWidth) {
        return barOnRight ? desktopFrameMargin : barPanelWidth
    }

    function mainAreaRightInset(screenWidth) {
        return barOnRight ? barPanelWidth + desktopFrameMargin : desktopFrameMargin
    }

    function mainAreaWidth(screenWidth) {
        return Math.max(0, screenWidth - mainAreaX(screenWidth) - mainAreaRightInset(screenWidth))
    }

    function quickPopupX(screenWidth, popupWidth) {
        if (barOnRight) {
            if (rightSoftLayout)
                return Math.round(Math.max(desktopFrameMargin, screenWidth - barPanelWidth - desktopFrameMargin - popupFrameGap - popupWidth))
            return Math.round(Math.max(desktopFrameMargin, screenWidth - barPanelWidth - popupWidth))
        }
        return barPanelWidth
    }

    function attachedPopupX(screenWidth, popupWidth) {
        if (barOnRight) {
            if (rightSoftLayout)
                return Math.round(Math.max(desktopFrameMargin, screenWidth - barPanelWidth - desktopFrameMargin - popupFrameGap - popupWidth))
            return Math.round(Math.max(desktopFrameMargin, screenWidth - barPanelWidth - popupWidth))
        }
        return barPanelWidth
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
        return 324
    }

    function quickPopupY(type, panelHeight, screenHeight) {
        const edgeMargin = rightSoftLayout ? desktopFrameMargin + popupFrameGap : 22
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
        id: quickPopupUnmountTimer

        interval: 190
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

        interval: 220
        repeat: false
        onTriggered: {
            if (!root.wallpaperSelectorVisible)
                root.wallpaperSelectorWindowOpen = false
        }
    }

    Timer {
        id: settingsPanelUnmountTimer

        interval: 200
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
            id: framePanel

            required property var modelData
            readonly property bool compositorReservedBarSpace: modelData.width > 0 && width <= modelData.width - root.barPanelWidth + 2
            readonly property color frameMatteColor: root.desktopFrameMatteColor()
            readonly property color frameBorderColor: root.desktopFrameBorderColor()
            readonly property color frameHighlightColor: root.desktopFrameHighlightColor()

            visible: veloraTheme.desktopFrameEnabled
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
                return root.rightSoftLayout ? root.mainAreaX(width) : root.mainAreaX(width) + root.desktopFrameMargin
            }

            function frameY() {
                return root.desktopFrameMargin
            }

            function frameWidth() {
                if (compositorReservedBarSpace)
                    return Math.max(0, width - root.desktopFrameMargin * 2)
                return root.rightSoftLayout ? Math.max(0, root.mainAreaWidth(width)) : Math.max(0, root.mainAreaWidth(width) - root.desktopFrameMargin * 2)
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

                onPaint: {
                    const ctx = getContext("2d")
                    const fx = Math.round(framePanel.frameX())
                    const fy = Math.round(framePanel.frameY())
                    const fw = Math.round(framePanel.frameWidth())
                    const fh = Math.round(framePanel.frameHeight())
                    const radius = Math.min(root.desktopFrameRadius, Math.max(0, fw / 2), Math.max(0, fh / 2))

                    ctx.clearRect(0, 0, width, height)
                    if (fw <= 0 || fh <= 0)
                        return

                    ctx.fillStyle = framePanel.frameMatteColor
                    ctx.fillRect(0, 0, width, fy)
                    ctx.fillRect(0, fy + fh, width, Math.max(0, height - fy - fh))
                    ctx.fillRect(0, fy, fx, fh)
                    ctx.fillRect(fx + fw, fy, Math.max(0, width - fx - fw), fh)
                    paintCorner(ctx, "topLeft", fx, fy, fw, fh, radius)
                    paintCorner(ctx, "topRight", fx, fy, fw, fh, radius)
                    paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
                    paintCorner(ctx, "bottomLeft", fx, fy, fw, fh, radius)
                }

                Component.onCompleted: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            Rectangle {
                id: desktopFrame

                x: framePanel.frameX()
                y: framePanel.frameY()
                width: framePanel.frameWidth()
                height: framePanel.frameHeight()
                radius: root.desktopFrameRadius
                color: "transparent"
                border.width: 1
                border.color: framePanel.frameBorderColor
                antialiasing: true
            }

            Rectangle {
                x: desktopFrame.x + 1
                y: desktopFrame.y + 1
                width: Math.max(0, desktopFrame.width - 2)
                height: Math.max(0, desktopFrame.height - 2)
                radius: Math.max(0, desktopFrame.radius - 1)
                color: "transparent"
                visible: !root.rightSoftLayout
                border.width: 1
                border.color: framePanel.frameHighlightColor
                antialiasing: true
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { frameMatteCanvas.requestPaint() }
                function onSidebarOpacityChanged() { frameMatteCanvas.requestPaint() }
                function onThemeModeChanged() { frameMatteCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { frameMatteCanvas.requestPaint() }
                function onBorderSoftChanged() { frameMatteCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { frameMatteCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { frameMatteCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { frameMatteCanvas.requestPaint() }
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
                    radius: inlineQuickPopup.cornerRadius
                }

                Region {
                    item: inlineModalOverlayInputMask
                    radius: 0
                }

                Region {
                    item: inlineWallpaperInputMask
                    radius: inlineWallpaperSelector.cornerRadius
                }

                Region {
                    item: inlineSettingsInputMask
                    radius: inlineSettingsPanel.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: !root.barOnRight
                right: root.barOnRight
            }

            Rectangle {
                id: barGutterFill

                x: root.rightSoftLayout ? root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width) : root.barX(parent.width)
                y: 0
                width: root.rightSoftLayout ? Math.max(0, parent.width - x) : root.barPanelWidth
                height: parent.height
                visible: veloraTheme.desktopFrameEnabled
                color: root.desktopFrameMatteColor()
                antialiasing: false
            }

            Rectangle {
                id: rightSoftBackRail

                readonly property int railX: Math.round(root.barX(parent.width) + root.sidebarVisualWidth)

                x: railX
                y: root.desktopFrameMargin
                width: Math.max(0, parent.width - railX)
                height: Math.max(0, parent.height - root.desktopFrameMargin * 2)
                visible: false
                color: "transparent"
                border.width: 1
                border.color: veloraTheme.alpha(veloraTheme.sidebarBorderGlow, 0.20)
                antialiasing: false
            }

            VeloraBarV2 {
                id: barRoot

                theme: veloraTheme
                width: root.sidebarVisualWidth
                x: root.barX(parent.width)
                focusMode: root.focusMode
                focusIndex: root.focusIndex
                focusTarget: root.focusTarget
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

                x: inlineQuickPopup.x
                y: inlineQuickPopup.y
                width: root.quickPopupPanelVisible ? inlineQuickPopup.width : 0
                height: root.quickPopupPanelVisible ? inlineQuickPopup.height : 0
            }

            VeloraAttachedSurface {
                id: inlineQuickPopupSurface

                theme: veloraTheme
                attachSide: root.popupAttachSide
                x: inlineQuickPopup.x
                y: inlineQuickPopup.y
                width: inlineQuickPopup.width
                height: inlineQuickPopup.height
                radius: inlineQuickPopup.cornerRadius
                revealProgress: inlineQuickPopup.revealProgress
                visible: root.quickPopupPanelVisible && !root.rightSoftLayout
            }

            VeloraSidePopup {
                id: inlineQuickPopup

                theme: veloraTheme
                externalSurface: !root.rightSoftLayout
                attachSide: root.popupAttachSide
                popupType: root.visibleQuickPopupType
                open: root.quickPopupVisible
                interactiveFocus: root.quickPopupType === "search"
                width: root.quickPopupWidth(root.visibleQuickPopupType)
                height: root.quickPopupHeight(root.visibleQuickPopupType)
                x: root.quickPopupX(parent.width, width)
                y: root.quickPopupY(root.visibleQuickPopupType, height, parent.height)
                visible: root.quickPopupPanelVisible
                onCloseRequested: root.closeQuickPopup()
                onPointerInsideChanged: function(inside) {
                    root.quickPopupHovering = inside
                    if (inside)
                        hoverCloseTimer.stop()
                    else if (root.hoverPopupType.length > 0)
                        root.scheduleHoverClose()
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 360
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 360
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 360
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
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
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                            inlineWallpaperSelector.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                            inlineWallpaperSelector.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            inlineWallpaperSelector.applySelected()
                            event.accepted = true
                            return
                        }
                    }

                    if (root.settingsPanelOpen) {
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                            inlineSettingsPanel.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                            inlineSettingsPanel.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            inlineSettingsPanel.applySelected()
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

                    x: inlineWallpaperSelector.x
                    y: inlineWallpaperSelector.y
                    width: root.wallpaperSelectorPanelVisible ? inlineWallpaperSelector.width : 0
                    height: root.wallpaperSelectorPanelVisible ? inlineWallpaperSelector.height : 0
                }

                VeloraAttachedSurface {
                    z: 2
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    x: inlineWallpaperSelector.x
                    y: inlineWallpaperSelector.y
                    width: inlineWallpaperSelector.width
                    height: inlineWallpaperSelector.height
                    radius: inlineWallpaperSelector.cornerRadius
                    revealProgress: inlineWallpaperSelector.revealProgress
                    visible: root.wallpaperSelectorPanelVisible && !root.rightSoftLayout
                }

                VeloraWallpaperSelector {
                    id: inlineWallpaperSelector

                    z: 3
                    theme: veloraTheme
                    externalSurface: !root.rightSoftLayout
                    width: Math.round(Math.min(root.quickPopupWidth("theme"), parent.width * 0.47))
                    height: Math.round(Math.min(root.quickPopupHeight("theme"), width * 0.63))
                    x: root.attachedPopupX(parent.width, width)
                    y: root.quickPopupY("theme", height, parent.height)
                    open: root.wallpaperSelectorVisible
                    visible: root.wallpaperSelectorPanelVisible
                    focus: root.wallpaperSelectorOpen
                    onCloseRequested: root.wallpaperSelectorOpen = false

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

                    Behavior on y {
                        NumberAnimation {
                            duration: 360
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 360
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 360
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }
                }

                Item {
                    id: inlineSettingsInputMask

                    x: inlineSettingsPanel.x
                    y: inlineSettingsPanel.y
                    width: root.settingsPanelPanelVisible ? inlineSettingsPanel.width : 0
                    height: root.settingsPanelPanelVisible ? inlineSettingsPanel.height : 0
                }

                VeloraAttachedSurface {
                    z: 4
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    x: inlineSettingsPanel.x
                    y: inlineSettingsPanel.y
                    width: inlineSettingsPanel.width
                    height: inlineSettingsPanel.height
                    radius: inlineSettingsPanel.cornerRadius
                    revealProgress: inlineSettingsPanel.revealProgress
                    visible: root.settingsPanelPanelVisible && !root.rightSoftLayout
                }

                VeloraSettingsPanel {
                    id: inlineSettingsPanel

                    z: 5
                    theme: veloraTheme
                    externalSurface: !root.rightSoftLayout
                    width: Math.round(Math.min(root.quickPopupWidth("settings"), parent.width * 0.49))
                    height: Math.round(Math.min(root.quickPopupHeight("settings"), width * 0.66))
                    x: root.attachedPopupX(parent.width, width)
                    y: root.quickPopupY("settings", height, parent.height)
                    open: root.settingsPanelVisible
                    visible: root.settingsPanelPanelVisible
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

                    Behavior on y {
                        NumberAnimation {
                            duration: 360
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 360
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 360
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }
                }

                Connections {
                    target: root

                    function onWallpaperSelectorOpenChanged() {
                        if (root.wallpaperSelectorOpen)
                            Qt.callLater(function() {
                                inlineWallpaperSelector.forceActiveFocus()
                            })
                    }

                    function onSettingsPanelOpenChanged() {
                        if (root.settingsPanelOpen)
                            Qt.callLater(function() {
                                inlineSettingsPanel.forceActiveFocus()
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
                NumberAnimation {
                    duration: 360
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
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
                return dashboardTriggerMouse.containsMouse || dashboardHoverArea.containsMouse
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
                    radius: dashboard.cornerRadius
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

                x: dashboard.x
                y: dashboard.y
                width: dashboard.visible ? dashboard.width : 0
                height: dashboard.visible ? dashboard.height : 0
            }

            VeloraDashboard {
                id: dashboard

                theme: veloraTheme
                compact: true
                activeSection: root.rightDashboardSection
                width: dashboardPanel.cardWidth
                height: dashboardPanel.activeCardHeight
                x: dashboardPanel.dashboardOnLeft ? dashboardPanel.triggerWidth : dashboardPanel.width - dashboardPanel.triggerWidth - width
                y: dashboardPanel.activeCardY
                visible: root.rightDashboardOpen || dashboardPanel.dashboardReveal > 0.01
                opacity: dashboardPanel.dashboardReveal
                scale: 0.982 + dashboardPanel.dashboardReveal * 0.018
                transformOrigin: dashboardPanel.dashboardOnLeft ? Item.Left : Item.Right
                transform: Translate {
                    x: Math.round((1 - dashboardPanel.dashboardReveal) * (dashboardPanel.dashboardOnLeft ? -28 : 28))
                    y: Math.round((1 - dashboardPanel.dashboardReveal) * -4)
                }
                onThemeRequested: function(centerY) {
                    root.rightDashboardOpen = false
                    root.showWallpaperSelector(Number(centerY) > 0 ? centerY : root.defaultQuickPopupCenterY("theme"))
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 360
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 360
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 360
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                    }
                }

                MouseArea {
                    id: dashboardHoverArea

                    anchors.fill: parent
                    enabled: dashboard.visible
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: dashboardPanel.requestDashboardOpen(root.rightDashboardSection)
                    onExited: dashboardPanel.requestDashboardClose()
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: quickPopupPanel

            required property var modelData

            visible: false
            screen: modelData
            color: "transparent"
            implicitWidth: root.barPanelWidth + root.quickPopupWidth(root.visibleQuickPopupType) + 24
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: root.quickPopupType === "search"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: root.quickPopupType === "search" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                Region {
                    item: quickPopup
                    radius: quickPopup.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: true
            }

            Item {
                id: quickPopupLayer

                anchors.fill: parent

                VeloraAttachedSurface {
                    theme: veloraTheme
                    x: quickPopup.x
                    y: quickPopup.y
                    width: quickPopup.width
                    height: quickPopup.height
                    radius: quickPopup.cornerRadius
                    revealProgress: quickPopup.revealProgress
                    visible: root.quickPopupPanelVisible

                    Behavior on x {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }
                }

                VeloraSidePopup {
                    id: quickPopup

                    theme: veloraTheme
                    externalSurface: true
                    popupType: root.visibleQuickPopupType
                    open: root.quickPopupVisible
                    interactiveFocus: root.quickPopupType === "search"
                    width: root.quickPopupWidth(root.visibleQuickPopupType)
                    height: root.quickPopupHeight(root.visibleQuickPopupType)
                    x: root.quickPopupX(parent.width, width)
                    y: root.quickPopupY(root.visibleQuickPopupType, height, parent.height)
                    visible: root.quickPopupPanelVisible
                    onCloseRequested: root.closeQuickPopup()
                    onPointerInsideChanged: function(inside) {
                        root.quickPopupHovering = inside
                        if (inside)
                            hoverCloseTimer.stop()
                        else if (root.hoverPopupType.length > 0)
                            root.scheduleHoverClose()
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: wallpaperPanel

            required property var modelData

            visible: false
            screen: modelData
            color: "transparent"
            focusable: true
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: root.wallpaperSelectorOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                Region {
                    item: root.wallpaperSelectorOpen ? wallpaperOverlay : wallpaperSelector
                    radius: root.wallpaperSelectorOpen ? 0 : wallpaperSelector.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: wallpaperOverlay

                anchors.fill: parent
                focus: root.wallpaperSelectorOpen

                Keys.onEscapePressed: root.wallpaperSelectorOpen = false
                Keys.onPressed: function(event) {
                    if (!root.wallpaperSelectorOpen)
                        return

                    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                        wallpaperSelector.moveSelection(-1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                        wallpaperSelector.moveSelection(1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        wallpaperSelector.applySelected()
                        event.accepted = true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.wallpaperSelectorOpen
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.wallpaperSelectorOpen = false
                }

                VeloraAttachedSurface {
                    theme: veloraTheme
                    x: wallpaperSelector.x
                    y: wallpaperSelector.y
                    width: wallpaperSelector.width
                    height: wallpaperSelector.height
                    radius: wallpaperSelector.cornerRadius
                    revealProgress: wallpaperSelector.revealProgress
                    visible: root.wallpaperSelectorVisible

                    transform: Translate {
                        x: Math.round((1 - wallpaperSelector.revealProgress) * -20)
                        y: Math.round((1 - wallpaperSelector.revealProgress) * 12)
                    }
                }

                VeloraWallpaperSelector {
                    id: wallpaperSelector

                    theme: veloraTheme
                    externalSurface: true
                    width: Math.round(Math.min(820, parent.width * 0.47))
                    height: Math.round(Math.min(520, width * 0.63))
                    x: root.attachedPopupX(parent.width, width)
                    y: Math.round(Math.max(112, Math.min(parent.height - height - 24, parent.height * 0.18)))
                    visible: root.wallpaperSelectorVisible
                    focus: root.wallpaperSelectorOpen
                    onCloseRequested: root.wallpaperSelectorOpen = false

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

                Connections {
                    enabled: false
                    target: root

                    function onWallpaperSelectorOpenChanged() {
                        if (root.wallpaperSelectorOpen)
                            Qt.callLater(function() {
                                wallpaperSelector.forceActiveFocus()
                            })
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: settingsPanelWindow

            required property var modelData

            visible: false
            screen: modelData
            color: "transparent"
            focusable: true
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: root.settingsPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                Region {
                    item: root.settingsPanelOpen ? settingsOverlay : settingsPanel.surfaceItem
                    radius: root.settingsPanelOpen ? 0 : settingsPanel.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: settingsOverlay

                anchors.fill: parent
                focus: root.settingsPanelOpen

                Keys.onEscapePressed: root.settingsPanelOpen = false
                Keys.onPressed: function(event) {
                    if (!root.settingsPanelOpen)
                        return

                    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                        settingsPanel.moveSelection(-1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                        settingsPanel.moveSelection(1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        settingsPanel.applySelected()
                        event.accepted = true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.settingsPanelOpen
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.settingsPanelOpen = false
                }

                VeloraAttachedSurface {
                    theme: veloraTheme
                    x: settingsPanel.x
                    y: settingsPanel.y
                    width: settingsPanel.width
                    height: settingsPanel.height
                    radius: settingsPanel.cornerRadius
                    revealProgress: settingsPanel.revealProgress
                    visible: root.settingsPanelVisible

                    transform: Translate {
                        x: Math.round((1 - settingsPanel.revealProgress) * -18)
                        y: Math.round((1 - settingsPanel.revealProgress) * 10)
                    }
                }

                VeloraSettingsPanel {
                    id: settingsPanel

                    theme: veloraTheme
                    externalSurface: true
                    width: Math.round(Math.min(820, parent.width * 0.49))
                    height: Math.round(Math.min(560, width * 0.66))
                    x: root.attachedPopupX(parent.width, width)
                    y: Math.round(Math.max(118, Math.min(parent.height - height - 30, parent.height * 0.54)))
                    visible: root.settingsPanelVisible
                    focus: root.settingsPanelOpen
                    onCloseRequested: root.settingsPanelOpen = false
                }

                Connections {
                    enabled: false
                    target: root

                    function onSettingsPanelOpenChanged() {
                        if (root.settingsPanelOpen)
                            Qt.callLater(function() {
                                settingsPanel.forceActiveFocus()
                            })
                    }
                }
            }
        }
    }
}
