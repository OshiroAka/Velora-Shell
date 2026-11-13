pragma ComponentBehavior: Bound
import QtQuick
import "../../components" as Components

Column {
    id: root
    required property var theme
    required property var motion
    required property var controller
    required property var legacyTheme
    required property var integrations
    spacing: 12
    QtObject { id: selectedBlockState; property int index: 0 }

    function prepareResult(result) {
        const group=result.group || (result.id.indexOf("velyrics.")===0 ? "velyrics" : "playback")
        if (group==="audio") {
            audioGroup.expanded=true
            return !audioGroup.contentItem || audioGroup.reveal<.98
        }
        if (group==="velyrics") {
            terminalGroup.expanded=true
            return !terminalGroup.contentItem || terminalGroup.reveal<.98
        }
        lyricsGroup.expanded=true
        if (!lyricsGroup.contentItem || lyricsGroup.reveal<.98) return true
        if (["lyrics.x2","lyrics.y2"].includes(result.id)) selectedBlockState.index=1
        if (["lyrics.x","lyrics.y"].includes(result.id)) selectedBlockState.index=0
        return lyricsGroup.contentItem.prepareResult(group)
    }

    component Controls: Components.VeloraMediaSettings {
        width: parent ? parent.width : 500
        theme: root.legacyTheme; styleTheme: root.theme
        controller: root.integrations; motion: root.motion; blockState: selectedBlockState
    }

    SettingsAppearanceGroup {
        id: audioGroup; objectName: "mediaGroup-audio"
        width: parent.width; title: "Áudio"; detail: "Saída de som e controle de volume."
        icon: "volume"; expanded: true; contentPadding: 16
        theme: root.theme; motion: root.motion
        contentComponent: Controls { mediaSection: "audio" }
    }
    SettingsAppearanceGroup {
        id: lyricsGroup; objectName: "mediaGroup-lyrics"
        width: parent.width; title: "Lyrics no wallpaper"; detail: "Exibição, layout e aparência das letras na área de trabalho."
        icon: "article"; contentPadding: 12
        theme: root.theme; motion: root.motion
        contentComponent: Column {
            width: parent ? parent.width : 500; spacing: 8
            function prepareResult(group) {
                const target=({playback:playback,layout:layout,position:position,style:style,material:material,movement:movement})[group]
                if (!target) return false
                target.expanded=true
                return !target.contentItem || target.reveal<.98
            }
            SettingsAppearanceGroup {
                id: playback; objectName: "mediaGroup-playback"
                width: parent.width; title: "Exibição e sincronia"; icon: "music_note"
                theme: root.theme; motion: root.motion; expanded: true; contentPadding: 12
                contentComponent: Controls { mediaSection: "playback" }
            }
            SettingsAppearanceGroup {
                id: layout; objectName: "mediaGroup-layout"
                width: parent.width; title: "Layout das letras"; icon: "grid"
                theme: root.theme; motion: root.motion; contentPadding: 12
                contentComponent: Controls { mediaSection: "layout" }
            }
            SettingsAppearanceGroup {
                id: position; objectName: "mediaGroup-position"
                width: parent.width; title: "Posição e transformação"; icon: "location"
                theme: root.theme; motion: root.motion; contentPadding: 12
                contentComponent: Controls { mediaSection: "position" }
            }
            SettingsAppearanceGroup {
                id: style; objectName: "mediaGroup-style"
                width: parent.width; title: "Texto, cor e brilho"; icon: "palette"
                theme: root.theme; motion: root.motion; contentPadding: 12
                contentComponent: Controls { mediaSection: "style" }
            }
            SettingsAppearanceGroup {
                id: material; objectName: "mediaGroup-material"
                width: parent.width; title: "Material e máscara"; icon: "apps"
                theme: root.theme; motion: root.motion; contentPadding: 12
                contentComponent: Controls { mediaSection: "material" }
            }
            SettingsAppearanceGroup {
                id: movement; objectName: "mediaGroup-movement"
                width: parent.width; title: "Movimento das letras"; icon: "rotate"
                theme: root.theme; motion: root.motion; contentPadding: 12
                contentComponent: Controls { mediaSection: "movement" }
            }
        }
    }
    SettingsAppearanceGroup {
        id: terminalGroup; objectName: "mediaGroup-velyrics"
        onExpandedChanged: if (root.controller) root.controller.settingsSection=expanded ? "velyrics" : "main"
        width: parent.width; title: "VeLyrics no terminal"; detail: "Agrupamento, sincronismo e fonte dos terminais."
        icon: "terminal"; contentPadding: 16
        theme: root.theme; motion: root.motion
        contentComponent: Column {
            width: parent ? parent.width : 500; spacing: 12
            Controls { mediaSection: "velyrics" }
            Components.VeloraSettingsChoice {
                width: Math.min(parent.width,260); theme: root.theme; motion: root.motion
                label: "Redefinir VeLyrics"; iconName: "refresh"; checkable: false
                onClicked: if (root.integrations) root.integrations.resetVelyricsSettings()
            }
        }
    }
}
