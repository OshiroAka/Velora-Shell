pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell
import "../core/AppGlyphs.js" as AppGlyphs

Item {
    id: root
    property url source
    property string iconName: ""
    property string identifier: ""
    property color ink: "white"
    property bool outline: true
    readonly property string sharedGlyph: AppGlyphs.resolve(identifier, iconName)
    readonly property string symbolicName: iconName.endsWith("-symbolic") ? iconName : iconName + "-symbolic"
    readonly property bool hasSymbolic: iconName.length > 0 && !iconName.includes("/") && Quickshell.hasThemeIcon(symbolicName)
    readonly property bool useGlyph: outline && sharedGlyph.length > 0
    readonly property bool useSymbolic: outline && !useGlyph && hasSymbolic && GraphicsInfo.api !== GraphicsInfo.Software
    implicitWidth: 28; implicitHeight: 28
    Image {
        id: original
        anchors.fill: parent
        source: root.useSymbolic ? Quickshell.iconPath(root.symbolicName) : root.source
        sourceSize: Qt.size(112, 112)
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: !root.useGlyph && !root.useSymbolic
    }
    Loader {
        anchors.fill: parent
        active: root.useGlyph
        sourceComponent: Component {
            VeloraEdgeAppIcon { iconName: root.sharedGlyph; ink: root.ink }
        }
    }
    Loader {
        anchors.fill: parent
        active: root.useSymbolic
        sourceComponent: Component {
            ColorOverlay { source: original; color: root.ink; cached: true }
        }
    }
}
