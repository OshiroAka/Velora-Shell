import QtQuick
import "../../components" as Components

WidgetSurface {
    id: root
    required property var media
    required property var motion
    property url fallbackArt
    readonly property bool poster: variantId === "poster"
    readonly property bool vinyl: variantId === "vinyl"
    readonly property real coverSize: poster ? Math.min(width - 40, height - 124) : vinyl ? Math.min(height - 36, width * .36) : Math.min(height - 28, 72)
    width: 330; height: 112
    RoundedImage {
        id: cover; x: root.poster ? (root.width - width) / 2 : 16; y: root.poster ? 16 : (parent.height - height) / 2
        width: root.coverSize; height: width; radius: root.vinyl ? width/2 : 14
        source: root.media.hasPlayer ? root.media.artUrl : ""
        NumberAnimation on rotation {
            running: root.animateContent && root.vinyl && root.media.hasPlayer && root.media.playing
            from: 0; to: 360; duration: 14000; loops: Animation.Infinite
        }
    }
    Rectangle {
        x: cover.x; y: cover.y; width: cover.width; height: cover.height; radius: cover.radius
        visible: !root.media.hasPlayer || !String(root.media.artUrl || "").length
        color: root.quietColor
        Components.VeloraMaterialIcon { anchors.centerIn: parent; width: 28; height: 28; iconName: "music_note"; iconColor: root.mutedColor }
    }
    Rectangle {
        visible: root.vinyl; anchors.centerIn: cover; width: 19; height: 19; radius: 10
        color: root.solidColor; border.width: 5; border.color: root.contentColor
    }
    Column {
        id: info
        x: root.poster ? 20 : cover.x + cover.width + 14
        y: root.poster ? cover.y + cover.height + 12 : Math.max(18, root.height/2 - 34)
        width: parent.width - x - 20; spacing: 4
        Text {
            width: parent.width; text: root.media.hasPlayer ? root.media.title : "Nenhuma mídia"
            color: root.contentColor; font.family: root.contentFont; font.pixelSize: 12 * root.fontScale
            font.weight: Font.Medium; elide: Text.ElideRight
        }
        Text {
            width: parent.width; text: root.media.hasPlayer ? root.media.artist : "Abra seu player"
            color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 10 * root.fontScale
            elide: Text.ElideRight
        }
        Row {
            spacing: 8
            Repeater {
                model: [{id: "previous", icon: "skip_previous", available: root.media.canPrevious},
                    {id: "toggle", icon: root.media.playing ? "pause" : "play_arrow", available: root.media.canToggle},
                    {id: "next", icon: "skip_next", available: root.media.canNext}]
                Item {
                    id: control
                    objectName: "widgetMedia." + modelData.id
                    required property var modelData
                    width: 30; height: 30; enabled: modelData.available
                    opacity: enabled ? 1 : .3
                    activeFocusOnTab: enabled
                    function trigger() {
                        if (!enabled) return
                        if (modelData.id === "previous") root.media.previous()
                        else if (modelData.id === "toggle") root.media.togglePlaying()
                        else root.media.next()
                    }
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.id === "previous" ? "Faixa anterior" : modelData.id === "next" ? "Próxima faixa" : root.media.playing ? "Pausar" : "Reproduzir"
                    Accessible.onPressAction: trigger()
                    Keys.onSpacePressed: trigger()
                    Keys.onReturnPressed: trigger()
                    Rectangle { anchors.fill: parent; radius: 15; color: root.quietColor; visible: control.activeFocus }
                    Components.VeloraMaterialIcon { anchors.centerIn: parent; width: 20; height: 20; iconName: control.modelData.icon; iconColor: root.contentColor }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: control.trigger() }
                }
            }
        }
    }
    Rectangle {
        x: info.x; y: root.poster ? parent.height - 14 : parent.height - 10
        width: parent.width - x - 20; height: 2; radius: 1
        visible: root.media.hasPlayer; color: root.quietColor
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, Number(root.media.progress || 0)))
            height: 2; radius: 1; color: root.contentColor
            Behavior on width {
                NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
            }
        }
    }
}
