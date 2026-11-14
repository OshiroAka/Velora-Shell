import QtQuick
import "../../components" as Components

Column {
    id: root
    required property var theme
    required property var motion
    required property var controller
    spacing: 16
    Text {
        width: parent.width; text: "Nova lockscreen"
        color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 22
    }
    Text {
        width: parent.width
        text: "A nova composição substitui a prévia antiga. As integrações abaixo aguardam revisão."
        color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 13; wrapMode: Text.WordWrap
    }
    Rectangle {
        id: previewButton; objectName: "lock.preview"
        width: parent.width; height: 64; radius: 18
        color: root.theme.withAlpha(root.theme.accent, previewHover.hovered || activeFocus ? .20 : .10)
        border.width: 1; border.color: root.theme.borderSubtle
        activeFocusOnTab: true
        Accessible.role: Accessible.Button; Accessible.name: "Visualizar nova tela"
        function activate() { root.controller.showLockPreview() }
        Accessible.onPressAction: activate()
        Keys.onReturnPressed: activate()
        Keys.onSpacePressed: activate()
        Components.VeloraMaterialIcon { x: 20; anchors.verticalCenter: parent.verticalCenter; width: 26; height: 26; iconName: "lock"; iconColor: root.theme.accentSoft }
        Text { x: 62; anchors.verticalCenter: parent.verticalCenter; text: "Visualizar nova tela"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 15 }
        HoverHandler { id: previewHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: previewButton.activate() }
    }
    Repeater {
        model: ["Autenticação e senha do sistema", "Bloqueio seguro da sessão, monitores e retomada", "Mídia, progresso e bateria", "Desligar, reiniciar e suspender", "Personalização, perfis e atalhos automáticos"]
        Text {
            required property string modelData
            objectName: "lock.pending"
            width: root.width; text: "Pendente · " + modelData
            color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 13; wrapMode: Text.WordWrap
        }
    }
    Text {
        width: parent.width; text: "Esta é uma prévia visual. Escape retorna ao desktop."
        color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12; wrapMode: Text.WordWrap
    }
}
