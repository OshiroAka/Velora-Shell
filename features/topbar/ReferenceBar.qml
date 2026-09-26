import QtQuick
import Quickshell.Hyprland
import "../../components" as Components

Item {
    id: root
    required property var config
    required property var theme
    required property var clock
    required property var media
    required property var weather
    required property var status
    required property var actions
    required property var compositor
    required property var editorController
    // Geometry stays compact, while typography remains readable at 40 px.
    readonly property real unit: 1
    readonly property bool compact: width < 1280
    readonly property bool nativeGlassActive: config.barMaterial !== "solid"
    required property real wavePhase
    property int opticsGeneration: 0
    property alias barSurfaceItem: background

    function syncNativeShape() {
        if (width <= 0 || height <= 0 || config.barMaterial !== "liquid") {
            Hyprland.dispatch("velora-blur:topbar-shape 0")
            return
        }
        // Extend the native lens above the monitor. Its medial axis then sits
        // on the clipped screen edge instead of crossing the 40 px strip.
        Hyprland.dispatch("velora-blur:topbar-shape 1 0 -1 1 3.0 "
            + Number(Math.min(20, height / 2) / width).toFixed(6))
    }

    function itemWidth(type) {
        const widths = { launcher: 90, workspaces: 208, context: compact ? 130 : 250,
            clock: compact ? 210 : 330, media: compact ? 100 : 140,
            wifi: 54, volume: 54, battery: 86, settings: 48, avatar: 48,
            search: 48, weather: 60, brand: 90 }
        return (widths[type] || 48) * unit
    }
    function glyph(type) {
        if (type === "launcher") return "apps"
        if (type === "media") return media.playing ? "pause" : "play"
        if (type === "volume") return status.muted ? "volume-muted" : "volume"
        if (type === "battery") return "battery"
        return type === "avatar" ? "person" : type
    }
    function label(type) {
        if (type === "clock") return clock.locale().toString(clock.now,
            compact ? "ddd, dd MMM — HH:mm" : "ddd, dd 'de' MMMM — HH:mm").replace(/\./g, "")
        if (type === "media") return media.hasPlayer ? media.title : "Sem mídia"
        if (type === "battery") return status.hasBattery ? status.batteryPercent + "%" : ""
        if (type === "weather") return weather.available
            ? weather.temperature + "° · " + weather.description : ""
        if (type === "brand") return "Velora"
        return ""
    }
    function activate(type) {
        if (type === "launcher" || type === "search") actions.openLauncher()
        else if (type === "media") media.hasPlayer ? media.togglePlaying() : actions.openMusic()
        else if (type === "wifi") actions.openNetworkSettings()
        else if (type === "volume") status.toggleMuted()
        else if (type === "clock") editorController.show("desktop")
        else actions.openSettings()
    }

    Canvas {
        id: background
        anchors.fill: parent
        antialiasing: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const r = 20
            ctx.clearRect(0, 0, width, height)
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width - r, 0)
            ctx.arcTo(width, 0, width, r, r)
            // The lower-right edge meets the desktop frame and must remain
            // filled; a second rounded corner exposed the wallpaper here.
            ctx.lineTo(width, height)
            ctx.lineTo(0, height)
            ctx.lineTo(0, 0)
            ctx.closePath()
            ctx.fillStyle = root.theme.barSurface
            ctx.fill()
        }
        Component.onCompleted: requestPaint()
    }

    onWavePhaseChanged: background.requestPaint()
    onOpticsGenerationChanged: Qt.callLater(syncNativeShape)
    Connections {
        target: root.theme
        function onBarSurfaceChanged() { background.requestPaint() }
        function onAccentChanged() { background.requestPaint() }
        function onAccentAltChanged() { background.requestPaint() }
    }
    Connections {
        target: root.config
        function onBarMaterialChanged() {
            root.syncNativeShape(); background.requestPaint()
        }
        function onBarWaveStrengthChanged() { background.requestPaint() }
    }
    Component.onCompleted: Qt.callLater(root.syncNativeShape)
    Component.onDestruction: Hyprland.dispatch("velora-blur:topbar-shape 0")
    onWidthChanged: Qt.callLater(syncNativeShape)
    onHeightChanged: Qt.callLater(syncNativeShape)

    component Section: Row {
        id: section
        required property string sectionName
        height: root.height
        Repeater {
            model: root.config.topbarItemsForSection(section.sectionName, false)
            Item {
                id: entry
                required property var modelData
                readonly property string type: modelData.type
                width: root.itemWidth(type)
                height: root.height
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6 * root.unit
                    radius: 16 * root.unit
                    color: root.theme.accentMuted
                    visible: pointer.containsMouse && entry.type !== "workspaces"
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 8 * root.unit
                    visible: !["workspaces", "context"].includes(entry.type)
                    Components.VeloraMaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 23 * root.unit; height: width
                        visible: !["clock", "brand"].includes(entry.type)
                        iconName: root.glyph(entry.type)
                        iconColor: root.theme.accentSoft
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: text.length > 0
                        text: root.label(entry.type)
                        width: entry.type === "media" ? entry.width - 46 * root.unit : implicitWidth
                        elide: Text.ElideRight
                        color: root.theme.textPrimary
                        font.family: "Poppins"
                        font.pixelSize: (entry.type === "clock" ? 15 : 12) * root.unit
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 27 * root.unit
                    color: root.theme.borderSubtle
                    visible: ["launcher", "workspaces", "media", "battery"].includes(entry.type)
                }
                Column {
                    x: 14 * root.unit
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 * root.unit
                    visible: entry.type === "context"
                    spacing: -1 * root.unit
                    Text {
                        width: parent.width
                        text: root.editorController.mounted ? "Velora"
                            : String(root.compositor.activeToplevel
                                ? (root.compositor.activeToplevel.appId || "Desktop") : "Desktop")
                        color: root.theme.textMuted
                        font.family: "Poppins"; font.pixelSize: 11 * root.unit
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.editorController.mounted ? "Configurações"
                            : String(root.compositor.activeToplevel
                                ? root.compositor.activeToplevel.title : "Área de trabalho")
                        color: root.theme.textPrimary
                        font.family: "Poppins"; font.pixelSize: 12 * root.unit
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    enabled: entry.type !== "workspaces"
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(entry.type)
                    onWheel: function(event) {
                        if (entry.type === "volume") root.status.adjustVolume(event.angleDelta.y > 0 ? 1 : -1)
                    }
                }
                Row {
                    anchors.centerIn: parent
                    visible: entry.type === "workspaces"
                    spacing: 4 * root.unit
                    Repeater {
                        model: 5
                        Rectangle {
                            required property int index
                            readonly property int workspace: index + 1
                            readonly property bool selected: Hyprland.focusedWorkspace
                                && Hyprland.focusedWorkspace.id === workspace
                            width: 32 * root.unit; height: width; radius: width / 2
                            color: selected ? root.theme.accent : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: parent.workspace
                                color: root.theme.textPrimary
                                font.family: "Poppins"; font.pixelSize: 13 * root.unit
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + parent.workspace)
                            }
                        }
                    }
                }
            }
        }
    }
    Section { sectionName: "left"; anchors.left: parent.left }
    Section { sectionName: "center"; anchors.horizontalCenter: parent.horizontalCenter }
    Section { sectionName: "right"; anchors.right: power.left }
    Item {
        id: power
        anchors.right: parent.right
        width: 62 * root.unit; height: parent.height
        Components.VeloraMaterialIcon {
            anchors.centerIn: parent
            width: 25 * root.unit; height: width
            iconName: "power"; iconColor: root.theme.accentSoft
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.actions.openSettings()
        }
    }
}
