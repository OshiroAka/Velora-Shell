import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    required property var motion
    required property var config
    required property var preview
    required property var profileService
    required property var editorController

    property bool mounted: false
    property bool shown: false
    property bool picking: false
    property string page: "appearance"
    property var draft: ({})
    property bool dirty: false
    property bool savedPulse: false
    property string pendingWallpaperPath: ""
    property int pendingImageTarget: 0
    property string pendingImagePath: ""
    property string pendingPackageKind: ""
    property string pendingPackagePath: ""
    property string pendingPackageProfileId: ""

    signal opened
    signal closed

    function syncNativeOptics(mode) {
        Hyprland.dispatch("velora-blur:appearance " + String(mode) + " "
            + Number(root.config.blurStrength).toFixed(4) + " "
            + Number(root.config.appearanceContrast).toFixed(4) + " "
            + Number(root.config.reflectionStrength).toFixed(4))
    }

    function clone(value) {
        return value === undefined ? undefined
            : JSON.parse(JSON.stringify(value))
    }

    function snapshot() {
        const value = root.config.appearanceSnapshot()
        value.topbar = {
            variant: root.config.topbarVariant,
            height: root.config.topbarHeight,
            scale: root.config.topbarScale,
            gap: root.config.topbarGap,
            margin: root.config.topbarMargin
        }
        return value
    }

    function beginDraft() {
        draft = snapshot()
        dirty = false
        savedPulse = false
    }

    function previewDraft() {
        const value = draft || ({})
        root.config.localeName = String(value.locale || root.config.localeName)
        root.config.reducedMotion = Boolean(value.reducedMotion)
        root.config.motionPreset = String(value.motionPreset || "balanced")
        root.config.intelligentContrast = Boolean(value.intelligentContrast)
        root.config.reduceTransparency = Boolean(value.reduceTransparency)
        root.config.visualStyle = String(value.visualStyle || "editorial")
        root.config.colorScheme = String(value.colorScheme || "dark")
        root.config.materialMode = String(value.material || "glass")
        root.config.surfaceOpacity = Number(value.surfaceOpacity)
        root.config.blurStrength = Number(value.blurStrength)
        root.config.appearanceContrast = Number(value.contrast)
        root.config.reflectionStrength = Number(value.reflection)
        root.config.accentMode = String(value.accentMode || "wallpaper")
        root.config.accentColor = String(value.accentColor || "#c8788f")
        root.config.customColors = root.config.normalizedCustomColors(
            value.customColors === undefined
                ? root.config.customColors : value.customColors)
        if (value.topbar) {
            const requestedVariant = String(value.topbar.variant || "velora")
            root.config.topbarVariant = ["velora", "end4-first"].includes(
                requestedVariant) ? requestedVariant : "velora"
            root.config.topbarHeight = Number(value.topbar.height)
            root.config.topbarScale = Number(value.topbar.scale)
            root.config.topbarGap = Number(value.topbar.gap)
            root.config.topbarMargin = Number(value.topbar.margin)
        }
        root.config.configurationChanged()
        syncNativeOptics("preview")
    }

    function update(field, value) {
        const next = clone(draft || snapshot())
        next[String(field)] = value
        draft = next
        dirty = true
        savedPulse = false
        previewDraft()
        return true
    }

    function updateTopbar(field, value) {
        const next = clone(draft || snapshot())
        next.topbar = Object.assign({}, next.topbar || ({}))
        next.topbar[String(field)] = value
        draft = next
        dirty = true
        savedPulse = false
        previewDraft()
        return true
    }

    function restoreDefaults() {
        const current = snapshot()
        draft = {
            locale: current.locale,
            reducedMotion: false,
            motionPreset: "balanced",
            intelligentContrast: true,
            reduceTransparency: false,
            visualStyle: "editorial",
            colorScheme: "dark",
            material: "glass",
            surfaceOpacity: 0.82,
            blurStrength: 0.55,
            contrast: 1.08,
            reflection: 0.35,
            accentMode: "wallpaper",
            accentColor: "#c8788f",
            customColors: root.config.defaultCustomColors(),
            characterPywal: current.characterPywal,
            topbar: {
                variant: "velora", height: 40, scale: 1, gap: 4, margin: 8
            }
        }
        dirty = true
        previewDraft()
    }

    function apply() {
        if (!draft)
            return false
        root.config.applyAppearance(draft)
        root.config.setTopbarMetrics(draft.topbar || ({}))
        syncNativeOptics("commit")
        if (root.profileService.activeProfileId.length > 0)
            root.profileService.updateProfile(root.profileService.activeProfileId)
        beginDraft()
        savedPulse = true
        savedTimer.restart()
        return true
    }

    function cancelDraft() {
        Hyprland.dispatch("velora-blur:appearance reset")
        root.config.recompute()
        beginDraft()
    }

    function show(targetPage) {
        if (picking)
            return false
        if (root.editorController.mounted) {
            if (root.editorController.sessionDirty)
                root.editorController.saveSession()
            root.editorController.deactivate()
        }
        root.preview.hide()
        closeTimer.stop()
        if (!mounted) {
            mounted = true
            beginDraft()
            syncNativeOptics("commit")
        }
        if (String(targetPage || "").length > 0)
            page = String(targetPage)
        Qt.callLater(function() {
            if (!root.mounted)
                return
            root.shown = true
            root.opened()
        })
        return true
    }

    function hide() {
        if (!mounted)
            return false
        if (dirty)
            cancelDraft()
        shown = false
        closeTimer.restart()
        return true
    }

    function openEditor(space) {
        if (dirty)
            apply()
        shown = false
        mounted = false
        root.editorController.show(space)
        closed()
        return true
    }

    function chooseWallpaper() {
        if (picking || wallpaperPicker.running)
            return false
        pendingWallpaperPath = ""
        picking = true
        shown = false
        pickerDelay.restart()
        return true
    }

    function chooseImage(target) {
        if (picking || imagePicker.running || wallpaperPicker.running)
            return false
        pendingImageTarget = Math.max(0, Math.min(3, Number(target)))
        pendingImagePath = ""
        picking = true
        shown = false
        imagePickerDelay.restart()
        return true
    }

    function packageFileName(profileId) {
        const profile = root.profileService.profileById(profileId)
        const source = String(profile && profile.name || "composicao")
        const safe = source.trim().replace(/[^a-zA-Z0-9._-]+/g, "-")
            .replace(/^-+|-+$/g, "")
        return (safe.length > 0 ? safe : "composicao") + ".helixpack"
    }

    function importPackage() {
        if (picking || packagePicker.running)
            return false
        pendingPackageKind = "import"
        pendingPackagePath = ""
        pendingPackageProfileId = ""
        picking = true
        shown = false
        packagePickerDelay.restart()
        return true
    }

    function exportPackage(profileId) {
        if (picking || packagePicker.running
                || !root.profileService.profileById(profileId))
            return false
        pendingPackageKind = "export"
        pendingPackagePath = ""
        pendingPackageProfileId = String(profileId)
        picking = true
        shown = false
        packagePickerDelay.restart()
        return true
    }

    function packagePickerCommand() {
        const exporting = pendingPackageKind === "export"
        const command = ["zenity", "--file-selection"]
        if (exporting)
            command.push("--save", "--confirm-overwrite")
        command.push(exporting
            ? "--title=Exportar perfil do Velora"
            : "--title=Importar perfil do Velora")
        command.push("--filename=" + root.config.homeDir + "/Downloads/"
            + (exporting ? packageFileName(pendingPackageProfileId) : ""))
        command.push("--file-filter=Pacote Velora Shell | *.helixpack")
        return command
    }

    function status() {
        return {
            mounted: mounted,
            shown: shown,
            picking: picking,
            page: page,
            dirty: dirty,
            lifecycle: picking ? "picking" : (!mounted ? "unloaded"
                : (shown ? "active" : "closing"))
        }
    }

    Timer {
        id: savedTimer
        interval: 1500
        onTriggered: root.savedPulse = false
    }

    Timer {
        id: closeTimer
        interval: root.motion.exit + 80
        onTriggered: {
            root.mounted = false
            root.closed()
        }
    }

    Timer {
        id: pickerDelay
        interval: root.motion.exit + 80
        onTriggered: wallpaperPicker.running = true
    }

    Timer {
        id: imagePickerDelay
        interval: root.motion.exit + 80
        repeat: false
        onTriggered: imagePicker.running = true
    }

    Timer {
        id: packagePickerDelay
        interval: root.motion.exit + 80
        repeat: false
        onTriggered: {
            packagePicker.command = root.packagePickerCommand()
            packagePicker.running = true
        }
    }

    Process {
        id: wallpaperPicker
        running: false
        command: ["zenity", "--file-selection",
            "--title=Escolha o wallpaper do perfil",
            "--filename=" + root.config.homeDir + "/Pictures/Wallpapers/",
            "--file-filter=Wallpapers | *.png *.jpg *.jpeg *.webp *.gif *.mp4 *.webm *.mkv *.mov"]
        stdout: SplitParser {
            onRead: function(line) {
                root.pendingWallpaperPath = String(line).trim()
            }
        }
        onExited: function(exitCode) {
            if (exitCode === 0 && root.pendingWallpaperPath.length > 0)
                root.profileService.setDraftWallpaper(
                    encodeURI("file://" + root.pendingWallpaperPath))
            root.picking = false
            root.mounted = true
            Qt.callLater(function() {
                root.shown = true
                root.opened()
            })
        }
    }

    Process {
        id: imagePicker
        running: false
        command: ["zenity", "--file-selection",
            pendingImageTarget === 0
                ? "--title=Escolha o personagem principal"
                : "--title=Escolha a foto da galeria",
            "--filename=" + root.config.homeDir + "/Templates de imagens/",
            pendingImageTarget === 0
                ? "--file-filter=Personagem transparente ou animada | *.png *.webp *.gif *.apng *.mng *.mp4 *.webm *.mkv *.mov"
                : "--file-filter=Imagens | *.png *.jpg *.jpeg *.webp"]
        stdout: SplitParser {
            onRead: function(line) {
                root.pendingImagePath = String(line).trim()
            }
        }
        onExited: function(exitCode) {
            if (exitCode === 0 && root.pendingImagePath.length > 0) {
                const selectedUrl = encodeURI(
                    "file://" + root.pendingImagePath)
                if (root.pendingImageTarget === 0)
                    root.config.setCharacterValue("path", selectedUrl)
                else
                    root.config.setGalleryValue(
                        root.pendingImageTarget - 1, "path", selectedUrl)
                Qt.callLater(function() {
                    if (root.profileService.activeProfileId.length > 0)
                        root.profileService.updateProfile(
                            root.profileService.activeProfileId)
                })
            }
            root.picking = false
            root.mounted = true
            Qt.callLater(function() {
                root.shown = true
                root.opened()
            })
        }
    }

    Process {
        id: packagePicker
        running: false
        command: []
        stdout: SplitParser {
            onRead: function(line) {
                root.pendingPackagePath = String(line).trim()
            }
        }
        onExited: function(exitCode) {
            if (exitCode === 0 && root.pendingPackagePath.length > 0) {
                if (root.pendingPackageKind === "import")
                    root.profileService.importPackage(root.pendingPackagePath)
                else
                    root.profileService.exportPackage(
                        root.pendingPackageProfileId,
                        root.pendingPackagePath)
            }
            root.picking = false
            root.mounted = true
            Qt.callLater(function() {
                root.shown = true
                root.opened()
            })
        }
    }
}
