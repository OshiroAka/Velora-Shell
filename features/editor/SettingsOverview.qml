pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Pipewire
import "../../components" as Components

Column {
    id: root
    required property var theme
    required property var controller
    required property var motion
    property string previewSource: ""
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioAvailable: !!(sink && sink.ready && sink.audio)
    signal sectionOpened(var item)
    function openTool(kind) {
        const card=({monitor:displayCard,brightness:displayCard,volume:soundCard,
            notifications:notificationCard,battery:powerCard,wifi:networkCard})[kind]
        if (!card) return false
        card.open()
        return true
    }
    spacing: 12

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Rectangle {
        id: preview
        objectName: "settingsWallpaperPreview"
        width: parent.width; height: Math.min(230, Math.max(140, width * .30))
        radius: 26; color: Qt.rgba(root.theme.textPrimary.r,root.theme.textPrimary.g,root.theme.textPrimary.b,.025)
        border.color: root.theme.borderSubtle
        Image {
            id: artwork
            objectName: "settingsOverviewArtwork"
            anchors.fill: parent; anchors.margins: 1
            source: root.previewSource
            sourceSize: Qt.size(1400, 700)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true; retainWhileLoading: true
            layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
            layer.effect: OpacityMask { maskSource: artworkMask }
        }
        Rectangle { id: artworkMask; width: artwork.width; height: artwork.height; radius: 25; visible: false }
        Components.VeloraMaterialIcon {
            anchors.centerIn: parent; width: 42; height: 42
            visible: artwork.status !== Image.Ready
            iconName: "wallpaper"; iconColor: root.theme.textSecondary
        }
        Accessible.role: Accessible.Button; Accessible.name: "Abrir configurações de wallpaper"
        Accessible.onPressAction: root.controller.setSettingsPage("wallpapers")
        activeFocusOnTab: true
        Keys.onReturnPressed: root.controller.setSettingsPage("wallpapers")
        Keys.onSpacePressed: root.controller.setSettingsPage("wallpapers")
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: root.controller.setSettingsPage("wallpapers")
        }
    }

    component OverviewCard: Rectangle {
        id: card
        property string title: ""
        property string detail: ""
        property string icon: ""
        property string tool: ""
        property bool volumeControl: false
        property bool expanded: false
        property bool revealRequested: false
        property bool contentMounted: false
        property real reveal: 0
        objectName: "settingsSystem-"+tool
        width: root.width
        height: 72+(bodyLoader.height+20)*reveal
        radius: 24
        color: Qt.rgba(root.theme.textPrimary.r,root.theme.textPrimary.g,root.theme.textPrimary.b, pointer.containsMouse ? .085 : .045)
        Behavior on color { ColorAnimation { duration: root.motion.surfaceHover } }
        function syncReveal() {
            cardExpansion.stop()
            const target=expanded ? 1 : 0
            if (root.motion.reduced) reveal=target
            else if (reveal!==target) { cardExpansion.to=target;cardExpansion.start() }
        }
        function releaseBody() {
            if (!expanded && reveal===0 && (!bodyLoader.item || !bodyLoader.item.busy)) contentMounted=false
        }
        onExpandedChanged: {
            if (expanded) contentMounted=true
            else if (bodyLoader.item) bodyLoader.item.deactivate()
            syncReveal()
        }
        Component.onCompleted: syncReveal()
        NumberAnimation { id: cardExpansion; target: card; property: "reveal"
            duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry }
        Connections { target: root.motion; function onReducedChanged() { card.syncReveal() } }
        border.width: header.activeFocus ? 1 : 0; border.color: root.theme.accent
        function open() {
            revealRequested=true
            expanded=true
            header.forceActiveFocus(Qt.TabFocusReason)
            if (reveal===1) { revealRequested=false;Qt.callLater(function(){root.sectionOpened(card)}) }
        }
        onRevealChanged: {
            if (reveal===0) Qt.callLater(releaseBody)
            if (reveal===1 && revealRequested) {
                revealRequested=false;Qt.callLater(function(){root.sectionOpened(card)})
            }
        }
        Connections { target: bodyLoader.item; function onBusyChanged() { Qt.callLater(card.releaseBody) } }
        Item {
            id: header
            width: parent.width; height: 72
            activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: card.title
            Accessible.description: card.detail
            Accessible.expandable: true; Accessible.expanded: card.expanded
            Accessible.onPressAction: card.expanded=!card.expanded
            Keys.onReturnPressed: card.expanded=!card.expanded
            Keys.onSpacePressed: card.expanded=!card.expanded
            MouseArea {
                id: pointer
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: card.expanded=!card.expanded
            }
            Components.VeloraMaterialIcon {
                x: 24; anchors.verticalCenter: parent.verticalCenter
                width: 26; height: 26; iconName: card.icon; iconColor: root.theme.textPrimary
            }
            Column {
                x: 74; anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0,parent.width-x-(card.volumeControl && !card.expanded && parent.width>510 ? 220 : 40))
                spacing: 4
                Text {
                    width: parent.width; text: card.title; color: root.theme.textPrimary
                    font.family: root.theme.bodyFont; font.pixelSize: 16; elide: Text.ElideRight
                }
                Text {
                    width: parent.width; text: card.detail; color: root.theme.textSecondary
                    font.family: root.theme.bodyFont; font.pixelSize: 12; elide: Text.ElideRight
                }
            }
            Slider {
                id: volume
                objectName: "settingsOverviewVolume"
                visible: card.volumeControl && !card.expanded && card.width > 510
                enabled: root.audioAvailable
                x: parent.width-width-58; width: 176; anchors.verticalCenter: parent.verticalCenter
                from: 0; to: 1; value: root.audioAvailable ? Math.min(1,root.sink.audio.volume) : 0
                Accessible.name: "Volume de saída"
                onMoved: if (root.audioAvailable) {
                    root.sink.audio.volume = value
                    if (value > 0) root.sink.audio.muted = false
                }
                background: Rectangle {
                    x: volume.leftPadding; y: volume.topPadding+(volume.availableHeight-height)/2
                    width: volume.availableWidth; height: 3; radius: 2
                    color: root.theme.borderStrong
                    Rectangle { width: volume.visualPosition*parent.width; height: parent.height; radius: 2; color: root.theme.textPrimary }
                }
                handle: Rectangle {
                    x: volume.leftPadding+volume.visualPosition*(volume.availableWidth-width)
                    y: volume.topPadding+(volume.availableHeight-height)/2
                    width: 18; height: 18; radius: 9; color: root.theme.textPrimary
                }
            }
            Components.VeloraMaterialIcon {
                x: parent.width-36; anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20; iconName: "chevron_right"; iconColor: root.theme.textPrimary
                rotation: 90*card.reveal
            }
        }
        Item {
            x: 24; y: 72; width: Math.max(0,parent.width-48)
            height: Math.max(0,card.height-y)
            visible: card.reveal>0
            clip: true
            enabled: card.expanded && card.reveal>.98
            Loader {
                id: bodyLoader
                objectName: "settingsSystemBody-"+card.tool
                width: parent.width
                height: item ? item.implicitHeight : 0
                active: card.contentMounted
                opacity: card.reveal
                sourceComponent: SettingsSystemPanel {
                    width: bodyLoader.width
                    kind: card.tool; theme: root.theme; motion: root.motion; controller: root.controller
                    presented: card.expanded && root.controller.shown && root.visible
                }
            }
        }
    }
    OverviewCard { id: displayCard; title: "Tela"; detail: "Resolução, escala e taxa de atualização"; icon: "display"; tool: "monitor" }
    OverviewCard { id: soundCard; title: "Som"; detail: "Volume de saída"; icon: "volume"; tool: "volume"; volumeControl: true }
    OverviewCard { id: notificationCard; title: "Notificações"; detail: "Histórico e alertas do desktop"; icon: "notifications"; tool: "notifications" }
    OverviewCard { id: powerCard; title: "Energia"; detail: "Bateria, perfis de energia e ventilação"; icon: "bolt"; tool: "battery" }
    OverviewCard { id: networkCard; title: "Rede"; detail: "Wi-Fi e conexões disponíveis"; icon: "wifi"; tool: "wifi" }
}
