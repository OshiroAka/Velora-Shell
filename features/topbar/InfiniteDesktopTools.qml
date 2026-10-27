pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../../components" as Components

Item {
    id: root
    required property var shell
    required property var theme
    required property var config
    required property var controller
    required property var host
    required property var actions
    required property var status
    property real progress: 0
    property real reveal: 0
    property bool rightSide: false
    readonly property var tools: rightSide ? ["media", "whatsapp"]
        : ["volume", "brightness", "notifications", "bluetooth", "wifi", "avatar"]
    readonly property var sidebar: shell.infiniteDesktopPanels[host.screen.name] || null
    readonly property color ink: sidebar ? sidebar.desktopIconInk : theme.textPrimary
    readonly property real glyphSize: sidebar ? sidebar.desktopIconSize : 22
    readonly property real targetWidth: tools.length * 34 + 24
    width: targetWidth * progress
    height: 40
    opacity: reveal
    layer.enabled: reveal > .001 && reveal < .999
    layer.effect: MultiEffect { blurEnabled: true; blurMax: 18; blur: 1 - root.reveal }
    function label(type) {
        return ({ volume: "Volume", brightness: "Brilho", notifications: "Notificações",
            bluetooth: "Bluetooth", wifi: "Wi-Fi", media: "Spotify",
            whatsapp: "WhatsApp", avatar: "Configurações" })[type]
    }
    Flickable {
        anchors.fill: parent
        contentWidth: toolsRow.width + 24
        contentHeight: height
        clip: true
        interactive: root.reveal > .999 && contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        Row {
            id: toolsRow
            x: 12
            height: root.height
            Repeater {
                model: root.tools
                BarItem {
                    id: tool
                    required property string modelData
                    readonly property string type: modelData
                    readonly property bool popoverTool: !["media", "whatsapp", "avatar"].includes(type)
                    width: 34
                    height: root.height
                    theme: root.theme
                    reducedMotion: root.config.reducedMotion
                    interactive: root.reveal > .999 && !root.shell.infiniteDesktopMorphing
                    objectName: "infiniteDesktopTool-" + type
                    label: root.label(type)
                    selected: popoverTool && root.controller.owner === root.host && root.controller.activeType === type
                    scrollable: type === "volume" || type === "brightness"
                    onScrolled: delta => type === "volume" ? root.status.adjustVolume(delta) : root.status.adjustBrightness(delta)
                    onActivated: {
                        if (popoverTool) root.controller.toggle(type, tool, root.host)
                        else {
                            root.controller.close()
                            if (type === "media") root.shell.railMediaRequested()
                            else if (type === "whatsapp") root.shell.railWhatsAppRequested()
                            else root.actions.openSettings()
                        }
                    }
                    onSecondaryActivated: activated()
                    onHoveredChanged: {
                        if (!popoverTool || !interactive) return
                        if (hovered) root.controller.enter(type, tool, root.host)
                        else root.controller.leave(tool)
                    }
                    Component.onCompleted: if (popoverTool) root.controller.registerItem(type, tool, root.host)
                    Component.onDestruction: if (popoverTool) root.controller.unregisterItem(tool)
                    Components.VeloraIconMotion {
                        id: iconMotion
                        highlighted: tool.hovered || tool.activeFocus
                        reducedMotion: root.config.reducedMotion
                    }
                    Components.VeloraSidebarIcon {
                        anchors.centerIn: parent
                        width: root.glyphSize; height: width
                        visible: tool.popoverTool
                        iconName: ({ volume: root.status.muted ? "volume-muted" : "volume",
                            brightness: "sun", notifications: "bell", bluetooth: "bluetooth", wifi: "wifi" })[tool.type] || ""
                        level: root.status.volume
                        ink: root.ink
                        opacity: Math.max(.88, root.sidebar ? root.sidebar.desktopIconOpacity : .8) * iconMotion.inkOpacity
                        scale: iconMotion.zoom
                        transform: Translate { y: iconMotion.lift }
                    }
                    Components.VeloraEdgeAppIcon {
                        anchors.centerIn: parent
                        width: 28; height: 28
                        visible: tool.type === "media" || tool.type === "whatsapp"
                        iconName: tool.type === "media" ? "Spotify" : "WhatsApp"
                        ink: root.ink
                        opacity: iconMotion.inkOpacity
                        scale: iconMotion.zoom
                        transform: Translate { y: iconMotion.lift }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 28; height: 28
                        visible: tool.type === "avatar"
                        property string requestedSource: tool.type === "avatar"
                            ? (String(root.sidebar ? root.sidebar.desktopAvatarSource : "").trim()
                                || Qt.resolvedUrl("../../assets/profile-avatar.svg")) : ""
                        source: requestedSource
                        onRequestedSourceChanged: source = requestedSource
                        onStatusChanged: if (status === Image.Error && source !== Qt.resolvedUrl("../../assets/profile-avatar.svg"))
                            source = Qt.resolvedUrl("../../assets/profile-avatar.svg")
                        sourceSize: Qt.size(128, 128)
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        scale: iconMotion.zoom
                        transform: Translate { y: iconMotion.lift }
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 28; height: 28; radius: 14; color: "white" }
                        }
                    }
                }
            }
        }
    }
}
