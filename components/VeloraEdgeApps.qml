pragma ComponentBehavior: Bound
import QtQuick

// Spotify and the local WhatsApp preview share the connected edge surface.
Item {
    id: root
    property color ink: "white"
    property bool reducedMotion: false
    signal spotifyRequested()
    signal whatsappRequested()
    signal spotifyHoverChanged(bool hovered)
    implicitWidth: 56
    implicitHeight: 164

    Column {
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            model: ["Spotify", "Discord", "WhatsApp"]
            delegate: Item {
                id: entry
                required property string modelData
                objectName: "edgeApp" + modelData
                width: 44
                height: 44
                activeFocusOnTab: true
                Accessible.role: modelData === "Discord" ? Accessible.Graphic : Accessible.Button
                Accessible.name: modelData
                function activate() {
                    if (modelData === "Spotify") root.spotifyRequested()
                    else if (modelData === "WhatsApp") root.whatsappRequested()
                }
                Accessible.onPressAction: activate()
                Keys.onReturnPressed: activate()
                Keys.onSpacePressed: activate()
                readonly property bool highlighted: pointer.hovered || activeFocus
                onHighlightedChanged: if (modelData === "Spotify") root.spotifyHoverChanged(highlighted)
                readonly property real emphasis: iconMotion.emphasis
                VeloraIconMotion {
                    id: iconMotion
                    highlighted: entry.highlighted
                    reducedMotion: root.reducedMotion
                }
                HoverHandler { id: pointer; blocking: false }
                TapHandler { enabled: entry.modelData !== "Discord"; onTapped: entry.activate() }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 13
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .08 * entry.emphasis)
                    border.width: entry.activeFocus ? 1 : 0
                    border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .5)
                }
                VeloraEdgeAppIcon {
                    width: 28; height: 28
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2 + iconMotion.lift
                    scale: iconMotion.zoom
                    opacity: iconMotion.inkOpacity
                    ink: root.ink
                    iconName: entry.modelData
                }
            }
        }
    }
}
