pragma ComponentBehavior: Bound
import QtQuick

// The connected bar owns the material. These are visual placeholders only.
Grid {
    id: root
    required property var theme
    columns: 3
    readonly property var tools: [
        { key: "eyedropper", label: "Conta-gotas" },
        { key: "record", label: "Gravação" },
        { key: "timer", label: "Temporizador" },
        { key: "calendar", label: "Calendário" },
        { key: "markings", label: "Marcações" },
        { key: "documents", label: "Documentos" }
    ]
    Repeater {
        model: root.tools
        BarItem {
            id: tool
            required property var modelData
            objectName: "toolbox-" + modelData.key
            width: root.width / 3
            height: root.height / 2
            theme: root.theme
            label: modelData.label
            reducedMotion: !!root.theme.config && root.theme.config.reducedMotion
            BarIcon {
                anchors.centerIn: parent
                width: 27; height: 27
                name: tool.modelData.key
                color: root.theme.textPrimary
            }
        }
    }
}
