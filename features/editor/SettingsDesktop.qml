import QtQuick
import "../../components" as Components

Column {
    id: root
    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var motion
    property var legacyTheme: null
    spacing: 16

    function prepareResult(result) {
        const group = result.group === "widgets" ? widgetsGroup : null
        if (!group) return false
        group.expanded = true
        if (!group.contentItem || group.reveal < .98) return true
        return typeof group.contentItem.prepareResult === "function"
            ? group.contentItem.prepareResult(result) : false
    }

    Rectangle {
        id: entry
        objectName: "scene.enter-desktop"
        width: parent.width; height: Math.max(132, entryText.implicitHeight + 40)
        radius: 18
        color: root.theme.withAlpha(root.theme.accent, hover.hovered ? .16 : .09)
        border.width: 1
        border.color: activeFocus ? root.theme.accent : root.theme.borderSubtle
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: "Abrir Editor do desktop"
        Accessible.description: "Organizar widgets e itens da barra arrastando diretamente na tela."
        function triggered() { root.controller.beginEditing("desktop") }
        Accessible.onPressAction: triggered()
        Keys.onReturnPressed: triggered()
        Keys.onSpacePressed: triggered()
        Components.VeloraMaterialIcon {
            x: 20; y: 24; width: 32; height: 32
            iconName: "edit"; iconColor: root.theme.accentSoft
        }
        Column {
            id: entryText
            x: 70; y: 20; width: parent.width - x - 20; spacing: 8
            Text {
                width: parent.width; text: "Editor do desktop"
                color: root.theme.textPrimary; font.family: root.theme.bodyFont
                font.pixelSize: 17; font.weight: Font.DemiBold; wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width; text: "Mova widgets e itens da barra diretamente no desktop."
                color: root.theme.textSecondary; font.family: root.theme.bodyFont
                font.pixelSize: 12; wrapMode: Text.WordWrap
            }
            Text {
                text: "Abrir editor"; color: root.theme.accentSoft
                font.family: root.theme.bodyFont; font.pixelSize: 12; font.weight: Font.DemiBold
            }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: entry.triggered() }
    }
    SettingsAppearanceGroup {
        id: widgetsGroup; objectName: "desktopGroup-widgets"
        width: parent.width; title: "Widgets e composição"; icon: "grid"
        theme: root.theme; motion: root.motion
        contentComponent: SettingsWidgets {
            width: parent.width; config: root.config; controller: root.controller
            editor: root.editor; theme: root.theme; motion: root.motion
            legacyTheme: root.legacyTheme
        }
    }
}
