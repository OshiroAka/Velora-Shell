pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Item {
    id: root
    property url source
    property string iconName: ""
    readonly property string symbolicName: iconName.endsWith("-symbolic") ? iconName : iconName + "-symbolic"
    readonly property bool hasSymbolic: iconName.length > 0 && !iconName.includes("/") && Quickshell.hasThemeIcon(symbolicName)
    property string identifier: ""
    property color ink: "white"
    property bool outline: true
    // Match desktop IDs, including Flatpak IDs, without matching unrelated names.
    readonly property string sharedGlyph: {
        const parts = identifier.toLowerCase().replace(/\.desktop$/, "").split(".")
        const names = {spotify: "Spotify", discord: "Discord", whatsapp: "WhatsApp", whatsappdesktop: "WhatsApp"}
        for (const part of parts) if (names[part]) return names[part]
        return ""
    }
    implicitWidth: 28; implicitHeight: 28
    Image {
        id: original
        anchors.fill: parent
        source: root.outline && root.hasSymbolic ? Quickshell.iconPath(root.symbolicName) : root.source
        sourceSize: Qt.size(112, 112)
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: !root.outline
    }
    Loader {
        anchors.fill: parent
        active: root.outline
        sourceComponent: root.sharedGlyph ? shared : converted
    }
    Component {
        id: shared
        VeloraEdgeAppIcon { iconName: root.sharedGlyph; ink: root.ink }
    }
    Component {
        id: converted
        ShaderEffect {
            // Supersample the thin strokes before the dock scales them down.
            layer.enabled: true
            layer.textureSize: Qt.size(112, 112)
            smooth: true
            // Capture only the icon, with transparent padding at the boundary.
            property var source: ShaderEffectSource {
                sourceItem: original
                hideSource: true
                sourceRect: Qt.rect(-2, -2, original.width + 4, original.height + 4)
                textureSize: Qt.size(112, 112)
                live: true
            }
            property vector2d pixelStep: Qt.vector2d(0.75 / Math.max(1, width), 0.75 / Math.max(1, height))
            property color ink: root.ink
            property real symbolic: root.hasSymbolic ? 1 : 0
            fragmentShader: "../shaders/app-outline.frag.qsb"
        }
    }
}
