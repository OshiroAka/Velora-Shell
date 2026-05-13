import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string stateScript: Quickshell.shellDir + "/scripts/velora-theme-state"
    readonly property string pywalScript: Quickshell.shellDir + "/scripts/velora-pywal-theme.py"
    readonly property string pywalGeneratedPath: Quickshell.shellDir + "/themes/pywal16.json"

    property string themeId: "default"
    property string themeName: "Velora Default"
    property string themeMode: "light"
    property string themeNotice: ""
    property bool pywalAvailable: false
    property bool opacityOverrideActive: false
    property bool glowOverrideActive: false
    property bool borderOverrideActive: false
    property bool borderAdaptEnabled: true
    property bool paletteApplying: false
    property bool paletteAnimatedApply: false
    readonly property bool paletteBehaviorEnabled: !paletteApplying || paletteAnimatedApply
    readonly property int paletteTransitionDuration: paletteAnimatedApply ? 560 : 260
    property string barPosition: "left"
    property bool desktopFrameEnabled: true
    property real sidebarOpacity: 0.78
    property real popupOpacity: 0.84
    property real cardOpacity: 0.68
    property real generalGlow: 0.50
    property real sidebarBorderGlowLevel: 0.50
    property real popupBorderGlowLevel: 0.50
    property real iconGlowLevel: 0.50
    property real textGlowLevel: 0.78
    property real borderHue: 0.55

    property color surfaceBase: Qt.rgba(250 / 255, 246 / 255, 253 / 255, 0.72)
    property color surfaceSidebar: Qt.rgba(248 / 255, 242 / 255, 252 / 255, 0.78)
    property color surfacePopup: Qt.rgba(250 / 255, 246 / 255, 253 / 255, 0.84)
    property color surfaceCard: Qt.rgba(1, 1, 1, 0.68)
    property color surfaceInput: Qt.rgba(1, 1, 1, 0.54)
    property color surfaceButton: Qt.rgba(1, 1, 1, 0.58)
    property color textPrimary: "#4d3f63"
    property color textSecondary: "#8d7ca3"
    property color textMuted: "#b7a9c7"
    property color accentPrimary: "#e8a6c8"
    property color accentSecondary: "#c894f2"
    property color accentTertiary: "#a8d8ff"
    property color borderSoft: Qt.rgba(1, 1, 1, 0.65)
    property color borderActive: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.78)
    property color borderGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.26)
    property color sidebarBorderGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.26)
    property color popupBorderGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.26)
    property color buttonPrimaryBg: "#e8a6c8"
    property color buttonPrimaryText: "#ffffff"
    property color buttonPrimaryGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.22)
    property color buttonSecondaryBg: Qt.rgba(1, 1, 1, 0.58)
    property color buttonSecondaryText: "#6d5a82"
    property color activeBg: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.35)
    property color activeText: "#ffffff"
    property color hoverBg: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.16)
    property color shadowColor: Qt.rgba(95 / 255, 70 / 255, 130 / 255, 0.13)
    property color sidebarGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.16)
    property color popupGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.14)
    property color textGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.12)
    property color iconGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
    property int glassBlur: 18

    readonly property var themeOptions: [
        { id: "default", title: "Light", subtitle: "Velora Default", mode: "light", preview: "default" },
        { id: "dark", title: "Dark", subtitle: "Manual", mode: "dark", preview: "dark" },
        { id: "pink", title: "Pink", subtitle: "Soft rose", mode: "light", preview: "pink" },
        { id: "lavender", title: "Lavender", subtitle: "Lilac glass", mode: "light", preview: "lavender" },
        { id: "pywal16", title: "pywal16", subtitle: "auto", mode: "dynamic", preview: "pywal16" }
    ]

    Behavior on surfaceBase { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceSidebar { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfacePopup { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceCard { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceInput { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceButton { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textPrimary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textSecondary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textMuted { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on accentPrimary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on accentSecondary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on accentTertiary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on borderSoft { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on borderActive { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on borderGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on sidebarBorderGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on popupBorderGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonPrimaryBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonPrimaryText { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonPrimaryGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonSecondaryBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonSecondaryText { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on activeBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on activeText { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on hoverBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on shadowColor { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on sidebarGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on popupGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on iconGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }

    function alpha(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function minOpacityForRole(role) {
        if (themeId === "pywal16" && themeMode === "dark") {
            if (role === "sidebar")
                return 0.54
            if (role === "popup")
                return 0.58
            if (role === "card")
                return 0.42
        }

        return 0.25
    }

    function minPanelOpacity() {
        if (themeId === "pywal16" && themeMode === "dark")
            return 0.48
        if (themeMode === "dark")
            return 0.46
        return 0.25
    }

    function clampOpacity(value, fallback, role) {
        const n = Number(value)
        if (isNaN(n))
            return fallback
        return Math.max(minOpacityForRole(role), Math.min(0.96, n))
    }

    function clampPanelOpacity(value, fallback) {
        const n = Number(value)
        const base = isNaN(n) ? fallback : n
        return Math.max(minPanelOpacity(), Math.min(0.98, base))
    }

    function beginPaletteApply(animate) {
        paletteAnimatedApply = animate === true
        paletteApplying = true
    }

    function endPaletteApply() {
        paletteApplying = false
    }

    function loadPywal16(animate) {
        if (pywalLoadProc.running) {
            pywalLoadProc.pendingReload = true
            pywalLoadProc.animateTheme = pywalLoadProc.animateTheme || animate === true
            return
        }

        pywalLoadProc.animateTheme = animate === true
        pywalLoadProc.command = [root.pywalScript, "--emit-or-generate"]
        pywalLoadProc.running = true
    }

    function panelOpacitySource(sidebar, popup) {
        const sidebarValue = Number(sidebar)
        const popupValue = Number(popup)
        const sidebarChanged = !isNaN(sidebarValue) && Math.abs(sidebarValue - sidebarOpacity) > 0.001
        const popupChanged = !isNaN(popupValue) && Math.abs(popupValue - popupOpacity) > 0.001

        if (popupChanged && !sidebarChanged)
            return popupValue
        if (!isNaN(sidebarValue))
            return sidebarValue
        if (!isNaN(popupValue))
            return popupValue
        return Math.max(surfaceSidebar.a, surfacePopup.a)
    }

    function syncPanelMaterial(opacity) {
        const sharedOpacity = clampPanelOpacity(opacity, Math.max(surfaceSidebar.a, surfacePopup.a))
        const r = surfaceSidebar.r
        const g = surfaceSidebar.g
        const b = surfaceSidebar.b
        surfaceSidebar = Qt.rgba(r, g, b, sharedOpacity)
        surfacePopup = Qt.rgba(r, g, b, sharedOpacity)
        sidebarOpacity = sharedOpacity
        popupOpacity = sharedOpacity
    }

    function clampLevel(value, fallback) {
        const n = Number(value)
        if (isNaN(n))
            return fallback
        return Math.max(0, Math.min(1, n))
    }

    function withOpacity(colorValue, opacity, role) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, clampOpacity(opacity, colorValue.a, role))
    }

    function withAlpha(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, Math.max(0, Math.min(1, Number(opacity) || 0)))
    }

    function hsvColor(hue, saturation, value, opacity) {
        const h = ((Number(hue) || 0) % 1 + 1) % 1
        const s = Math.max(0, Math.min(1, Number(saturation) || 0))
        const v = Math.max(0, Math.min(1, Number(value) || 0))
        const i = Math.floor(h * 6)
        const f = h * 6 - i
        const p = v * (1 - s)
        const q = v * (1 - f * s)
        const t = v * (1 - (1 - f) * s)
        var r = v
        var g = t
        var b = p

        switch (i % 6) {
        case 0: r = v; g = t; b = p; break
        case 1: r = q; g = v; b = p; break
        case 2: r = p; g = v; b = t; break
        case 3: r = p; g = q; b = v; break
        case 4: r = t; g = p; b = v; break
        case 5: r = v; g = p; b = q; break
        }

        return Qt.rgba(r, g, b, opacity === undefined ? 1 : Math.max(0, Math.min(1, Number(opacity) || 0)))
    }

    function hueOf(colorValue) {
        const maxV = Math.max(colorValue.r, colorValue.g, colorValue.b)
        const minV = Math.min(colorValue.r, colorValue.g, colorValue.b)
        const d = maxV - minV
        if (d <= 0.0001)
            return borderHue

        var h = 0
        if (maxV === colorValue.r)
            h = ((colorValue.g - colorValue.b) / d) % 6
        else if (maxV === colorValue.g)
            h = (colorValue.b - colorValue.r) / d + 2
        else
            h = (colorValue.r - colorValue.g) / d + 4

        return ((h / 6) % 1 + 1) % 1
    }

    function syncBorderValuesFromSurfaces() {
        borderAdaptEnabled = true
        borderHue = hueOf(sidebarBorderGlow)
    }

    function applyBorderAccent(adapt, hue, persist) {
        borderOverrideActive = true
        borderAdaptEnabled = adapt !== false
        borderHue = clampLevel(hue, borderHue)

        const accent = borderAdaptEnabled ? accentPrimary : hsvColor(borderHue, 0.82, 1.0, 1)
        const sharedBorderAlpha = Math.max(sidebarBorderGlow.a, popupBorderGlow.a)
        borderGlow = withAlpha(accent, borderGlow.a)
        sidebarBorderGlow = withAlpha(accent, sharedBorderAlpha)
        popupBorderGlow = withAlpha(accent, sharedBorderAlpha)
        if (persist !== false)
            saveBorder()
    }

    function applyLoadedBorderOverrides() {
        if (borderOverrideActive)
            applyBorderAccent(borderAdaptEnabled, borderHue, false)
        else
            syncBorderValuesFromSurfaces()
    }

    function resetBorderAccent() {
        borderOverrideActive = false
        borderAdaptEnabled = true
        borderResetProc.running = true
        applyTheme(themeId, false)
    }

    function syncOpacityValuesFromSurfaces() {
        syncPanelMaterial(Math.max(surfaceSidebar.a, surfacePopup.a))
        cardOpacity = surfaceCard.a
    }

    function applyOpacity(sidebar, popup, card, persist) {
        opacityOverrideActive = true
        syncPanelMaterial(panelOpacitySource(sidebar, popup))
        cardOpacity = clampOpacity(card, surfaceCard.a, "card")
        surfaceCard = withOpacity(surfaceCard, cardOpacity, "card")
        surfaceInput = withOpacity(surfaceInput, Math.max(minOpacityForRole("card"), cardOpacity - 0.08), "card")
        surfaceButton = withOpacity(surfaceButton, Math.max(minOpacityForRole("card"), cardOpacity - 0.06), "card")
        if (persist !== false)
            saveOpacity()
    }

    function applyLoadedOpacityOverrides() {
        if (opacityOverrideActive)
            applyOpacity(sidebarOpacity, popupOpacity, cardOpacity, false)
        else
            syncOpacityValuesFromSurfaces()
    }

    function resetOpacity() {
        opacityOverrideActive = false
        opacityResetProc.running = true
        applyTheme(themeId, false)
    }

    function syncGlowValuesFromSurfaces() {
        generalGlow = Math.max(0, Math.min(1, Math.max(sidebarBorderGlow.a / 0.78, popupBorderGlow.a / 0.78, textGlow.a / 0.38, iconGlow.a / 0.52)))
        const sharedBorderLevel = generalGlow > 0 ? Math.max(0, Math.min(1, Math.max(sidebarBorderGlow.a, popupBorderGlow.a) / (generalGlow * 0.78))) : 0
        sidebarBorderGlowLevel = sharedBorderLevel
        popupBorderGlowLevel = sharedBorderLevel
        iconGlowLevel = generalGlow > 0 ? Math.max(0, Math.min(1, iconGlow.a / (generalGlow * 0.52))) : 0
        textGlowLevel = Math.max(0, Math.min(1, textGlow.a / textGlowMaxAlpha()))

        const sharedGlowAlpha = Math.max(sidebarGlow.a, popupGlow.a)
        sidebarGlow = withAlpha(sidebarGlow, sharedGlowAlpha)
        popupGlow = withAlpha(sidebarGlow, sharedGlowAlpha)
        const sharedBorderAlpha = Math.max(sidebarBorderGlow.a, popupBorderGlow.a)
        sidebarBorderGlow = withAlpha(sidebarBorderGlow, sharedBorderAlpha)
        popupBorderGlow = withAlpha(sidebarBorderGlow, sharedBorderAlpha)
    }

    function textGlowMaxAlpha() {
        if (themeId === "pywal16" && themeMode === "dark")
            return 0.82
        if (themeMode === "dark")
            return 0.66
        return 0.48
    }

    function applyTextGlow(text, persist) {
        glowOverrideActive = true
        textGlowLevel = clampLevel(text, textGlowLevel)
        textGlow = withAlpha(textGlow, textGlowLevel * textGlowMaxAlpha())
        if (persist !== false)
            saveGlow()
    }

    function applyGlow(general, sidebarBorder, popupBorder, icon, text, persist) {
        glowOverrideActive = true
        generalGlow = clampLevel(general, generalGlow)
        const sidebarBorderValue = Number(sidebarBorder)
        const popupBorderValue = Number(popupBorder)
        const sidebarBorderChanged = !isNaN(sidebarBorderValue) && Math.abs(sidebarBorderValue - sidebarBorderGlowLevel) > 0.001
        const popupBorderChanged = !isNaN(popupBorderValue) && Math.abs(popupBorderValue - popupBorderGlowLevel) > 0.001
        const sharedBorderLevel = clampLevel(popupBorderChanged && !sidebarBorderChanged ? popupBorderValue : sidebarBorderValue, sidebarBorderGlowLevel)
        sidebarBorderGlowLevel = sharedBorderLevel
        popupBorderGlowLevel = sharedBorderLevel
        iconGlowLevel = clampLevel(icon === undefined ? generalGlow : icon, iconGlowLevel)
        sidebarGlow = withAlpha(sidebarGlow, generalGlow * sharedBorderLevel * 0.10)
        popupGlow = withAlpha(sidebarGlow, generalGlow * sharedBorderLevel * 0.10)
        iconGlow = withAlpha(iconGlow, generalGlow * iconGlowLevel * 0.52)
        buttonPrimaryGlow = withAlpha(buttonPrimaryGlow, generalGlow * 0.44)
        sidebarBorderGlow = withAlpha(sidebarBorderGlow, generalGlow * sharedBorderLevel * 0.78)
        popupBorderGlow = withAlpha(sidebarBorderGlow, generalGlow * sharedBorderLevel * 0.78)
        borderGlow = withAlpha(borderGlow, generalGlow * sharedBorderLevel * 0.66)
        applyTextGlow(text === undefined ? textGlowLevel : text, false)
        if (persist !== false)
            saveGlow()
    }

    function applyLoadedGlowOverrides() {
        if (glowOverrideActive)
            applyGlow(generalGlow, sidebarBorderGlowLevel, popupBorderGlowLevel, iconGlowLevel, textGlowLevel, false)
        else
            syncGlowValuesFromSurfaces()
    }

    function resetGlow() {
        glowOverrideActive = false
        glowResetProc.running = true
        applyTheme(themeId, false)
    }

    function mix(a, b, amount, opacity) {
        const t = Math.max(0, Math.min(1, Number(amount) || 0))
        const o = opacity === undefined ? (a.a + (b.a - a.a) * t) : opacity
        return Qt.rgba(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            o
        )
    }

    function fromHex(hex, fallback, opacity) {
        var h = String(hex || "").replace("#", "").trim()
        if (h.length !== 6)
            return fallback

        var r = parseInt(h.slice(0, 2), 16)
        var g = parseInt(h.slice(2, 4), 16)
        var b = parseInt(h.slice(4, 6), 16)
        if (isNaN(r) || isNaN(g) || isNaN(b))
            return fallback

        return Qt.rgba(r / 255, g / 255, b / 255, opacity === undefined ? 1 : opacity)
    }

    function fromCss(value, fallback) {
        const s = String(value || "").trim()
        if (s.indexOf("#") === 0)
            return fromHex(s, fallback)

        const match = s.match(/rgba?\(([^)]+)\)/)
        if (!match)
            return fallback

        const parts = match[1].split(",").map(function(v) { return Number(String(v).trim()) })
        if (parts.length < 3 || isNaN(parts[0]) || isNaN(parts[1]) || isNaN(parts[2]))
            return fallback

        return Qt.rgba(parts[0] / 255, parts[1] / 255, parts[2] / 255, parts.length > 3 && !isNaN(parts[3]) ? parts[3] : 1)
    }

    function applyThemeData(data, idOverride, notice, animate) {
        if (!data)
            return false

        beginPaletteApply(animate === true)
        themeId = idOverride || data.id || "pywal16"
        themeName = data.themeName || themeId
        themeMode = data.themeMode || "balanced"
        themeNotice = notice || data.notice || ""
        surfaceBase = fromCss(data.surfaceBase, surfaceBase)
        surfaceSidebar = fromCss(data.surfaceSidebar, surfaceSidebar)
        surfacePopup = fromCss(data.surfacePopup, surfacePopup)
        surfaceCard = fromCss(data.surfaceCard, surfaceCard)
        surfaceInput = fromCss(data.surfaceInput, surfaceInput)
        surfaceButton = fromCss(data.surfaceButton, surfaceButton)
        textPrimary = fromCss(data.textPrimary, textPrimary)
        textSecondary = fromCss(data.textSecondary, textSecondary)
        textMuted = fromCss(data.textMuted, textMuted)
        accentPrimary = fromCss(data.accentPrimary, accentPrimary)
        accentSecondary = fromCss(data.accentSecondary, accentSecondary)
        accentTertiary = fromCss(data.accentTertiary, accentTertiary)
        borderSoft = fromCss(data.borderSoft, borderSoft)
        borderActive = fromCss(data.borderActive, borderActive)
        borderGlow = fromCss(data.borderGlow, borderGlow)
        sidebarBorderGlow = fromCss(data.sidebarBorderGlow, borderGlow)
        popupBorderGlow = fromCss(data.popupBorderGlow, borderGlow)
        buttonPrimaryBg = fromCss(data.buttonPrimaryBg, buttonPrimaryBg)
        buttonPrimaryText = fromCss(data.buttonPrimaryText, buttonPrimaryText)
        buttonPrimaryGlow = fromCss(data.buttonPrimaryGlow, buttonPrimaryGlow)
        buttonSecondaryBg = fromCss(data.buttonSecondaryBg, buttonSecondaryBg)
        buttonSecondaryText = fromCss(data.buttonSecondaryText, buttonSecondaryText)
        activeBg = fromCss(data.activeBg, activeBg)
        activeText = fromCss(data.activeText, activeText)
        hoverBg = fromCss(data.hoverBg, hoverBg)
        shadowColor = fromCss(data.shadowColor, shadowColor)
        sidebarGlow = fromCss(data.sidebarGlow, sidebarGlow)
        popupGlow = fromCss(data.popupGlow, popupGlow)
        textGlow = fromCss(data.textGlow, textGlow)
        iconGlow = fromCss(data.iconGlow, iconGlow)
        glassBlur = Number(data.glassBlur || glassBlur)
        applyLoadedBorderOverrides()
        applyLoadedGlowOverrides()
        applyLoadedOpacityOverrides()
        endPaletteApply()
        return true
    }

    function setDefaultPalette() {
        themeId = "default"
        themeName = "Velora Default"
        themeMode = "light"
        themeNotice = ""
        surfaceBase = Qt.rgba(250 / 255, 246 / 255, 253 / 255, 0.72)
        surfaceSidebar = Qt.rgba(248 / 255, 242 / 255, 252 / 255, 0.78)
        surfacePopup = Qt.rgba(250 / 255, 246 / 255, 253 / 255, 0.84)
        surfaceCard = Qt.rgba(1, 1, 1, 0.68)
        surfaceInput = Qt.rgba(1, 1, 1, 0.54)
        surfaceButton = Qt.rgba(1, 1, 1, 0.58)
        textPrimary = "#4d3f63"
        textSecondary = "#8d7ca3"
        textMuted = "#b7a9c7"
        accentPrimary = "#e8a6c8"
        accentSecondary = "#c894f2"
        accentTertiary = "#a8d8ff"
        borderSoft = Qt.rgba(1, 1, 1, 0.65)
        borderActive = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.78)
        borderGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.26)
        sidebarBorderGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.26)
        popupBorderGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.26)
        buttonPrimaryBg = "#e8a6c8"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.22)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.58)
        buttonSecondaryText = "#6d5a82"
        activeBg = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.35)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.16)
        shadowColor = Qt.rgba(95 / 255, 70 / 255, 130 / 255, 0.13)
        sidebarGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.16)
        popupGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.14)
        textGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.12)
        iconGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
        glassBlur = 18
    }

    function setDarkPalette() {
        themeId = "dark"
        themeName = "Dark"
        themeMode = "dark"
        themeNotice = ""
        surfaceBase = Qt.rgba(28 / 255, 25 / 255, 36 / 255, 0.78)
        surfaceSidebar = Qt.rgba(34 / 255, 29 / 255, 44 / 255, 0.82)
        surfacePopup = Qt.rgba(39 / 255, 34 / 255, 50 / 255, 0.90)
        surfaceCard = Qt.rgba(62 / 255, 54 / 255, 74 / 255, 0.72)
        surfaceInput = Qt.rgba(62 / 255, 54 / 255, 74 / 255, 0.50)
        surfaceButton = Qt.rgba(1, 1, 1, 0.12)
        textPrimary = "#f2eaf7"
        textSecondary = "#d9c6ea"
        textMuted = "#a899b8"
        accentPrimary = "#e7a3c7"
        accentSecondary = "#b89cf2"
        accentTertiary = "#89c8ef"
        borderSoft = Qt.rgba(1, 1, 1, 0.18)
        borderActive = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.66)
        borderGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.22)
        sidebarBorderGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.22)
        popupBorderGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.22)
        buttonPrimaryBg = "#d889b5"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(216 / 255, 137 / 255, 181 / 255, 0.24)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.12)
        buttonSecondaryText = "#eadff3"
        activeBg = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.32)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(1, 1, 1, 0.10)
        shadowColor = Qt.rgba(16 / 255, 10 / 255, 24 / 255, 0.24)
        sidebarGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.16)
        popupGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.13)
        textGlow = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.12)
        iconGlow = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.18)
        glassBlur = 18
    }

    function setPinkPalette() {
        themeId = "pink"
        themeName = "Pink"
        themeMode = "light"
        themeNotice = ""
        surfaceBase = Qt.rgba(255 / 255, 244 / 255, 249 / 255, 0.74)
        surfaceSidebar = Qt.rgba(255 / 255, 239 / 255, 248 / 255, 0.80)
        surfacePopup = Qt.rgba(255 / 255, 244 / 255, 250 / 255, 0.86)
        surfaceCard = Qt.rgba(1, 1, 1, 0.72)
        surfaceInput = Qt.rgba(1, 1, 1, 0.58)
        surfaceButton = Qt.rgba(1, 1, 1, 0.60)
        textPrimary = "#5d3d56"
        textSecondary = "#966785"
        textMuted = "#c9a0b8"
        accentPrimary = "#ef8cba"
        accentSecondary = "#f2b1cf"
        accentTertiary = "#a8d8ff"
        borderSoft = Qt.rgba(1, 1, 1, 0.70)
        borderActive = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.74)
        borderGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        sidebarBorderGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        popupBorderGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        buttonPrimaryBg = "#ef8cba"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.60)
        buttonSecondaryText = "#80536f"
        activeBg = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.34)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.16)
        shadowColor = Qt.rgba(130 / 255, 72 / 255, 110 / 255, 0.13)
        sidebarGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.15)
        popupGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.13)
        textGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.10)
        iconGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.16)
        glassBlur = 18
    }

    function setLavenderPalette() {
        themeId = "lavender"
        themeName = "Lavender"
        themeMode = "light"
        themeNotice = ""
        surfaceBase = Qt.rgba(248 / 255, 246 / 255, 255 / 255, 0.74)
        surfaceSidebar = Qt.rgba(244 / 255, 240 / 255, 255 / 255, 0.80)
        surfacePopup = Qt.rgba(248 / 255, 246 / 255, 255 / 255, 0.86)
        surfaceCard = Qt.rgba(1, 1, 1, 0.70)
        surfaceInput = Qt.rgba(1, 1, 1, 0.56)
        surfaceButton = Qt.rgba(1, 1, 1, 0.58)
        textPrimary = "#4b416a"
        textSecondary = "#8171a4"
        textMuted = "#aaa0c6"
        accentPrimary = "#d8a4e6"
        accentSecondary = "#b994f2"
        accentTertiary = "#99d4ff"
        borderSoft = Qt.rgba(1, 1, 1, 0.68)
        borderActive = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.72)
        borderGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.24)
        sidebarBorderGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.24)
        popupBorderGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.24)
        buttonPrimaryBg = "#b994f2"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.22)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.58)
        buttonSecondaryText = "#675685"
        activeBg = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.32)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.14)
        shadowColor = Qt.rgba(82 / 255, 62 / 255, 130 / 255, 0.12)
        sidebarGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.15)
        popupGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.13)
        textGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.10)
        iconGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.16)
        glassBlur = 18
    }

    function applyTheme(id, persist) {
        const next = String(id || "default")

        beginPaletteApply(persist !== false)
        if (next === "dark")
            setDarkPalette()
        else if (next === "pink")
            setPinkPalette()
        else if (next === "lavender")
            setLavenderPalette()
        else if (next === "pywal16") {
            themeId = "pywal16"
            themeName = "pywal16"
            themeMode = "dynamic"
            themeNotice = "pywal16 selecionado; carregando tema gerado."
            loadPywal16(persist !== false)
        } else {
            setDefaultPalette()
        }

        applyLoadedGlowOverrides()
        applyLoadedBorderOverrides()
        applyLoadedOpacityOverrides()
        endPaletteApply()

        if (persist !== false)
            saveTheme()
    }

    function reloadPywal16() {
        pywalAvailable = false
        if (themeId === "pywal16") {
            themeId = "pywal16"
            themeName = "pywal16"
            themeMode = "dynamic"
            themeNotice = "Recarregando pywal16."
            loadPywal16(true)
        } else if (!pywalProbe.running) {
            pywalProbe.running = true
        }
    }

    function saveTheme() {
        if (saveProc.running)
            saveProc.pendingTheme = themeId
        else {
            saveProc.command = [root.stateScript, "set", themeId]
            saveProc.running = true
        }
    }

    function saveOpacity() {
        const sidebar = Number(sidebarOpacity).toFixed(2)
        const popup = Number(popupOpacity).toFixed(2)
        const card = Number(cardOpacity).toFixed(2)
        if (opacitySaveProc.running)
            opacitySaveProc.pending = sidebar + "|" + popup + "|" + card
        else {
            opacitySaveProc.command = [root.stateScript, "opacity", "set", sidebar, popup, card]
            opacitySaveProc.running = true
        }
    }

    function saveGlow() {
        const general = Number(generalGlow).toFixed(2)
        const sidebarBorder = Number(sidebarBorderGlowLevel).toFixed(2)
        const popupBorder = Number(popupBorderGlowLevel).toFixed(2)
        const icon = Number(iconGlowLevel).toFixed(2)
        const text = Number(textGlowLevel).toFixed(2)
        if (glowSaveProc.running)
            glowSaveProc.pending = general + "|" + sidebarBorder + "|" + popupBorder + "|" + icon + "|" + text
        else {
            glowSaveProc.command = [root.stateScript, "glow", "set", general, sidebarBorder, popupBorder, icon, text]
            glowSaveProc.running = true
        }
    }

    function saveBorder() {
        const mode = borderAdaptEnabled ? "adapt" : "manual"
        const hue = Number(borderHue).toFixed(3)
        if (borderSaveProc.running)
            borderSaveProc.pending = mode + "|" + hue
        else {
            borderSaveProc.command = [root.stateScript, "border", "set", mode, hue]
            borderSaveProc.running = true
        }
    }

    function applyLayout(position, frameEnabled, persist) {
        const nextPosition = String(position || "left") === "right" ? "right" : "left"
        const nextFrameEnabled = frameEnabled !== false && String(frameEnabled) !== "0" && String(frameEnabled) !== "false"
        barPosition = nextPosition
        desktopFrameEnabled = nextFrameEnabled
        if (persist !== false)
            saveLayout()
    }

    function setBarPosition(position, persist) {
        applyLayout(position, desktopFrameEnabled, persist)
    }

    function setDesktopFrameEnabled(enabled, persist) {
        applyLayout(barPosition, enabled, persist)
    }

    function saveLayout() {
        const enabled = desktopFrameEnabled ? "1" : "0"
        if (layoutSaveProc.running)
            layoutSaveProc.pending = barPosition + "|" + enabled
        else {
            layoutSaveProc.command = [root.stateScript, "layout", "set", barPosition, enabled]
            layoutSaveProc.running = true
        }
    }

    Component.onCompleted: {
        setDefaultPalette()
        if (!loadProc.running)
            loadProc.running = true
        if (!opacityLoadProc.running)
            opacityLoadProc.running = true
        if (!glowLoadProc.running)
            glowLoadProc.running = true
        if (!borderLoadProc.running)
            borderLoadProc.running = true
        if (!layoutLoadProc.running)
            layoutLoadProc.running = true
    }

    property Process loadProc: Process {
        running: false
        command: [root.stateScript, "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const id = String(data || "").trim()
                if (id.length > 0)
                    root.applyTheme(id, false)
            }
        }

        onExited: running = false
    }

    property Process saveProc: Process {
        property string pendingTheme: ""

        running: false
        command: [root.stateScript, "set", "default"]
        onExited: {
            running = false
            if (pendingTheme.length > 0) {
                const next = pendingTheme
                pendingTheme = ""
                command = [root.stateScript, "set", next]
                running = true
            }
        }
    }

    property Process opacityLoadProc: Process {
        running: false
        command: [root.stateScript, "opacity", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0 || line === "auto") {
                    root.opacityOverrideActive = false
                    root.syncOpacityValuesFromSurfaces()
                    return
                }

                const parts = line.split("|")
                if (parts.length >= 3)
                    root.applyOpacity(parts[0], parts[1], parts[2], false)
            }
        }

        onExited: running = false
    }

    property Process opacitySaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "opacity", "set", "0.78", "0.84", "0.68"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "opacity", "set", parts[0], parts[1], parts[2]]
                running = true
            }
        }
    }

    property Process opacityResetProc: Process {
        running: false
        command: [root.stateScript, "opacity", "reset"]
        onExited: running = false
    }

    property Process glowLoadProc: Process {
        running: false
        command: [root.stateScript, "glow", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0 || line === "auto") {
                    root.glowOverrideActive = false
                    root.syncGlowValuesFromSurfaces()
                    return
                }

                const parts = line.split("|")
                if (parts.length >= 3)
                    root.applyGlow(parts[0], parts[1], parts[2], parts.length >= 4 ? parts[3] : parts[0], parts.length >= 5 ? parts[4] : root.textGlowLevel, false)
            }
        }

        onExited: running = false
    }

    property Process glowSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "glow", "set", "0.50", "0.50", "0.50", "0.50", "0.78"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "glow", "set", parts[0], parts[1], parts[2], parts[3], parts.length >= 5 ? parts[4] : root.textGlowLevel]
                running = true
            }
        }
    }

    property Process glowResetProc: Process {
        running: false
        command: [root.stateScript, "glow", "reset"]
        onExited: running = false
    }

    property Process borderLoadProc: Process {
        running: false
        command: [root.stateScript, "border", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0 || line === "auto") {
                    root.borderOverrideActive = false
                    root.syncBorderValuesFromSurfaces()
                    return
                }

                const parts = line.split("|")
                root.applyBorderAccent(parts[0] !== "manual", parts.length >= 2 ? parts[1] : root.borderHue, false)
            }
        }

        onExited: running = false
    }

    property Process borderSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "border", "set", "adapt", "0.55"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "border", "set", parts[0], parts[1]]
                running = true
            }
        }
    }

    property Process borderResetProc: Process {
        running: false
        command: [root.stateScript, "border", "reset"]
        onExited: running = false
    }

    property Process layoutLoadProc: Process {
        running: false
        command: [root.stateScript, "layout", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0)
                    return

                const parts = line.split("|")
                root.applyLayout(parts[0], parts.length >= 2 ? parts[1] : "1", false)
            }
        }

        onExited: running = false
    }

    property Process layoutSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "layout", "set", "left", "1"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "layout", "set", parts[0], parts.length >= 2 ? parts[1] : "1"]
                running = true
            }
        }
    }

    property Process pywalProbe: Process {
        running: false
        command: [root.pywalScript, "--status"]

        stdout: SplitParser {
            onRead: function(data) {
                const status = String(data || "").trim()
                root.pywalAvailable = status !== "missing"
                if (root.themeId === "pywal16")
                    root.themeNotice = root.pywalAvailable
                        ? "pywal16 disponivel."
                        : "pywal16 ainda nao gerado; fallback Velora Default ativo."
            }
        }

        onExited: running = false
    }

    property Process pywalLoadProc: Process {
        property bool gotTheme: false
        property bool pendingReload: false
        property bool animateTheme: false

        running: false
        command: [root.pywalScript, "--emit-or-generate"]
        onStarted: gotTheme = false

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0)
                    return

                try {
                    const parsed = JSON.parse(line)
                    pywalLoadProc.gotTheme = true
                    if (root.themeId !== "pywal16")
                        return
                    root.pywalAvailable = !parsed.fallback
                    root.applyThemeData(parsed, "pywal16", parsed.fallback
                        ? "pywal16 falhou; usando Velora Default como fallback."
                        : "pywal16 aplicado: " + (parsed.themeMode || "balanced"),
                        pywalLoadProc.animateTheme)
                } catch (e) {
                    if (root.themeId === "pywal16") {
                        root.setDefaultPalette()
                        root.themeNotice = "pywal16 invalido; fallback Velora Default ativo."
                    }
                }
            }
        }

        onExited: {
            running = false
            if (pendingReload && root.themeId === "pywal16") {
                pendingReload = false
                root.loadPywal16(animateTheme)
                return
            }
            pendingReload = false
            if (!gotTheme && root.themeId === "pywal16") {
                root.setDefaultPalette()
                root.themeNotice = "pywal16 falhou; Velora Default preservado."
            }
        }
    }
}
