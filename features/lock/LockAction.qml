import QtQuick
import QtQuick.Effects
import "../../components" as Components

FocusScope {
    id: root
    property string iconName: "play"
    property string label: ""
    property bool reducedMotion: false
    property bool filled: true
    property color ink: "#fff0e6"
    property real iconSize: 30
    readonly property bool highlighted: hover.hovered || activeFocus
    readonly property real emphasis: iconMotion.emphasis
    signal triggered
    implicitWidth: 64; implicitHeight: 64
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: activate()
    function activate() { if (enabled && visible) triggered() }
    Keys.onReturnPressed: activate()
    Keys.onSpacePressed: activate()
    Components.VeloraIconMotion {
        id: iconMotion
        highlighted: root.highlighted && root.enabled
        reducedMotion: root.reducedMotion
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2 - 5 * root.emphasis
        color: root.filled ? Qt.rgba(.90, .69, .66, .16 + .12 * root.emphasis)
                           : Qt.rgba(.90, .69, .66, .10 * root.emphasis)
        border.width: root.activeFocus ? 1 : 0; border.color: "#dcaea3"
    }
    Item {
        anchors.centerIn: parent; width: root.iconSize; height: width
        Components.VeloraMaterialIcon {
            anchors.fill: parent; visible: root.iconName !== "arrow_forward"
            iconName: root.iconName; iconColor: root.ink
        }
        Canvas {
            anchors.fill: parent; visible: root.iconName === "arrow_forward"
            property color ink: root.ink
            onInkChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c=getContext("2d"); c.reset(); c.scale(width/30,height/30)
                c.strokeStyle=ink; c.lineWidth=2; c.lineCap="round"; c.lineJoin="round"
                c.beginPath(); c.moveTo(3,15); c.lineTo(26,15)
                c.moveTo(16,5); c.lineTo(26,15); c.lineTo(16,25); c.stroke()
            }
        }
        opacity: root.enabled ? iconMotion.inkOpacity : .28
        scale: iconMotion.zoom
        transform: Translate { y: iconMotion.lift }
        layer.enabled: root.enabled && root.emphasis > .001 && GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: "#efb6c3"; shadowOpacity: .65 * root.emphasis
            shadowBlur: .7; shadowScale: 1.12
            shadowHorizontalOffset: 0; shadowVerticalOffset: 0
        }
    }
    HoverHandler { id: hover; cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { onTapped: { root.forceActiveFocus(); root.activate() } }
}
