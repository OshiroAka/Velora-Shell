import QtQuick
import "../../components" as Components

Column {
    id: root
    required property var theme
    required property var motion
    required property var barTheme
    enabled: !!barTheme
    spacing: 12

    function applyIcons(size, opacity, spacing, hide) {
        if (!barTheme) return
        barTheme.applyBarAppearance(size, opacity, spacing, hide,
            barTheme.barCornerRadius, true)
    }

    Text {
        text: "Posição do trecho vertical"; color: root.theme.textPrimary
        font.family: root.theme.bodyFont; font.pixelSize: 13
    }
    Components.VeloraSettingsTabs {
        objectName: "bar.position"; theme: root.theme; motion: root.motion
        options: [{id:"left",label:"Esquerda"},{id:"right",label:"Direita"}]
        selected: root.barTheme ? root.barTheme.barPosition : "left"
        onChosen: id => { if (root.barTheme) root.barTheme.setBarPosition(id) }
    }
    Components.VeloraSettingsSlider {
        objectName: "bar.icon-size"; width: parent.width; theme: root.theme
        label: "Tamanho dos ícones"; minimum: 32; maximum: 56
        value: root.barTheme ? root.barTheme.barIconSize : 48
        valueText: Math.round(value / 48 * 100) + "%"
        resettable: true; defaultValue: 48
        onEdited: value => root.applyIcons(value, root.barTheme.barIconOpacity,
            root.barTheme.barIconSpacing, root.barTheme.barAutoHideEnabled)
    }
    Components.VeloraSettingsSlider {
        objectName: "bar.icon-opacity"; width: parent.width; theme: root.theme
        label: "Opacidade dos ícones"; minimum: .3; maximum: 1
        value: root.barTheme ? root.barTheme.barIconOpacity : .8
        resettable: true; defaultValue: .8
        onEdited: value => root.applyIcons(root.barTheme.barIconSize, value,
            root.barTheme.barIconSpacing, root.barTheme.barAutoHideEnabled)
    }
    Components.VeloraSettingsSlider {
        objectName: "bar.icon-gap"; width: parent.width; theme: root.theme
        label: "Espaçamento entre ícones"; minimum: 8; maximum: 24
        value: root.barTheme ? root.barTheme.barIconSpacing : 16
        valueText: Math.round(value) + " px"; resettable: true; defaultValue: 16
        onEdited: value => root.applyIcons(root.barTheme.barIconSize,
            root.barTheme.barIconOpacity, value, root.barTheme.barAutoHideEnabled)
    }
    Components.VeloraSettingsSwitch {
        objectName: "bar.hide-icons"; width: parent.width
        theme: root.theme; motion: root.motion; label: "Ocultar ícones em repouso"
        hint: "Oculta os ícones do trecho vertical e mantém a moldura."
        checked: root.barTheme ? root.barTheme.barAutoHideEnabled : false
        onTriggered: root.applyIcons(root.barTheme.barIconSize,
            root.barTheme.barIconOpacity, root.barTheme.barIconSpacing, !checked)
    }
}
