pragma ComponentBehavior: Bound
import QtQuick
import "../../components" as Components

Column {
    id: root
    required property var config
    required property var controller
    required property var theme
    required property var motion
    required property var backend
    readonly property var wallpaper: controller.wallpaperService || null
    readonly property color ink: theme.textPrimary
    readonly property color mutedInk: theme.textSecondary
    width: parent ? parent.width : 600
    spacing: 12
    objectName: "wallpaperSettingsPage"
    function prepareResult(result) {
        const group=({image:imageGroup, effects:effectsGroup, transitions:transitionsGroup, animated:animatedGroup})[result.group]
        if (!group) return false
        if (!group.expanded) { group.expanded=true; return true }
        return !group.contentItem || group.reveal<.98
    }
    component SettingSwitch: Components.VeloraSettingsSwitch { theme: root.theme; motion: root.motion }
    component SettingSlider: Components.VeloraSettingsSlider {
        theme: root.theme
        signal committed(real value)
        onEdited: value => committed(value)
    }

    component Effects: Column {
        width: parent ? parent.width : 640; spacing: 14
        Row {
            width: parent.width; spacing: 12
            Repeater { model: ["Original", "Com seus ajustes"]
                Column {
                    id: comparison
                    required property string modelData
                    required property int index
                    width: (parent.width-12)/2; spacing: 7
                    SettingsScenePreview {
                        width: parent.width; height: Math.min(120,width*.45)
                        theme: root.theme
                        imageSource: root.wallpaper ? root.wallpaper.currentPreviewPath || root.wallpaper.currentPath : ""
                        blur: comparison.index === 1 && root.config.wallpaperBlurEnabled ? root.config.wallpaperBlurStrength : 0
                        dimming: comparison.index === 1 ? root.config.wallpaperDimming : 0
                    }
                    Text { text: parent.modelData; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                }
            }
        }
        Flow {
            width: parent.width; spacing: 24
            Column { width: Math.min(320,(parent.width-24)/2); spacing: 2
                SettingSwitch {
                    objectName: "wallpaperBlurToggle"; label: "Desfoque"
                    checked: root.config.wallpaperBlurEnabled
                    onTriggered: root.config.setValue("desktop.wallpaperBlurEnabled", !checked)
                }
                SettingSlider {
                    objectName: "wallpaper.blur-strength"; label: "Intensidade"
                    enabled: root.config.wallpaperBlurEnabled
                    value: root.config.wallpaperBlurStrength
                    onCommitted: value => root.config.setValue("desktop.wallpaperBlurStrength",value)
                }
            }
            Column { width: Math.min(320,(parent.width-24)/2); spacing: 2
                SettingSlider { objectName: "wallpaper.dimming"; label: "Escurecimento"; value: root.config.wallpaperDimming
                    onCommitted: value => root.config.setValue("desktop.wallpaperDimming",value) }
            }
        }
    }

    Components.VeloraSettingsLink {
        objectName: "wallpaper.choose"; theme: root.theme; label: "Escolher wallpaper"
        onTriggered: {
            root.controller.hide()
            if (root.controller.shell) root.controller.shell.toggleTopWallpaperPopup(true, true)
        }
    }
    SettingsAppearanceGroup {
        id: imageGroup; objectName: "wallpaperGroup-image"
        title: "Imagem e enquadramento"; icon: "image"
        width: parent.width; theme: root.theme; motion: root.motion; contentPadding: 12
        contentComponent: Column {
            width: parent.width; spacing: 14
            Flow {
                objectName: "wallpaper.fit"
                width: parent.width; spacing: 10
                Components.VeloraSettingsChoice {
                    width: Math.min(230,(parent.width-10)/2); theme: root.theme; motion: root.motion
                    label: "Preencher tela"; iconName: "wallpaper"
                    active: root.config.wallpaperFit === "cover"
                    onClicked: {
                        if (root.config.wallpaperFit==="cover") root.controller.wallpaperFitRefreshRequested()
                        else root.config.setValue("desktop.wallpaperFit","cover")
                    }
                }
                Components.VeloraSettingsChoice {
                    width: Math.min(230,(parent.width-10)/2); theme: root.theme; motion: root.motion
                    label: "Imagem inteira"; iconName: "image"
                    active: root.config.wallpaperFit === "contain"
                    onClicked: {
                        if (root.config.wallpaperFit==="contain") root.controller.wallpaperFitRefreshRequested()
                        else root.config.setValue("desktop.wallpaperFit","contain")
                    }
                }
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap
                text: root.config.wallpaperFit === "contain"
                    ? "Preserva a proporção, sem cortar nem deformar. Imagens ultrawide podem deixar bordas pretas na tela."
                    : "Preserva a proporção e preenche a tela, cortando o que ficar além das bordas."
                color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11
            }
        }
    }
    SettingsAppearanceGroup {
        id: effectsGroup; objectName: "wallpaperGroup-effects"
        title: "Efeitos"; icon: "tune"
        width: parent.width; theme: root.theme; motion: root.motion; contentPadding: 12
        contentComponent: Effects { width: parent.width }
    }
    SettingsAppearanceGroup {
        id: transitionsGroup; objectName: "wallpaperGroup-transitions"
        title: "Transições"; icon: "rotate"
        width: parent.width; theme: root.theme; motion: root.motion; contentPadding: 12
        contentComponent: WallpaperTransitions { width: parent.width; theme: root.theme; motion: root.motion; backend: root.backend }
    }
    SettingsAppearanceGroup {
        id: animatedGroup; objectName: "wallpaperGroup-animated"
        title: "Wallpapers animados"; icon: "play"
        width: parent.width; theme: root.theme; motion: root.motion; contentPadding: 12
        contentComponent: Column {
            width: parent.width; spacing: 10
            Text { text: "Transição entre vídeos"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12 }
            Components.VeloraSettingsTabs {
                objectName: "wallpaper.live-engine"
                width: parent.width; theme: root.theme; motion: root.motion; tabWidth: 135
                options: [{id:"shader",label:"Shaders"},{id:"native",label:"Nativa do awww"}]
                selected: root.backend ? root.backend.wallpaperLiveTransition : "shader"
                onChosen: id => { if(root.backend) root.backend.setWallpaperLiveTransition(id) }
            }
            Text { width: parent.width; text: "Vídeos usam o efeito do compositor quando disponível, sem imagem intermediária."
                wrapMode: Text.WordWrap; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        }
    }
    Text {
        objectName: "wallpaper.autosave"; width: parent.width; wrapMode: Text.WordWrap
        text: "A composição é salva automaticamente por wallpaper."
        color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11
    }
}
