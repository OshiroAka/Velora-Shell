import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var media
    required property var weather
    required property var status
    required property var actions
    required property var compositor
    required property var settings
    required property var editorController
    required property int opticsGeneration

    property real nativeSurfaceHeight: height
    property bool revealed: false
    readonly property bool nativeGlassActive: false
    property alias barSurfaceItem: barSurface

    readonly property bool compact: width < 1400
    readonly property bool veryCompact: width < 1050
    readonly property int workspaceCount: compact ? 4 : 5

    function activeToplevelObject() {
        const toplevel = compositor.activeToplevel
        return toplevel ? (toplevel.lastIpcObject || ({})) : ({})
    }

    function contextualApp() {
        if (settings.mounted)
            return "Velora"
        if (editorController.mounted)
            return "Editor"
        const toplevel = compositor.activeToplevel
        if (!toplevel)
            return "Desktop"
        const ipc = activeToplevelObject()
        return String(ipc.class || ipc.initialClass || toplevel.appId
            || "Desktop")
    }

    function contextualTitle() {
        if (settings.mounted)
            return "Configurações"
        if (editorController.mounted)
            return editorController.editSpace === "lock"
                ? "Editar Lockscreen" : "Editar Desktop"
        const toplevel = compositor.activeToplevel
        if (!toplevel)
            return "Workspace " + (Hyprland.focusedWorkspace
                ? Hyprland.focusedWorkspace.id : 1)
        const ipc = activeToplevelObject()
        return String(toplevel.title || ipc.title || ipc.class || "Desktop")
    }

    function weatherGlyph() {
        const name = String(weather.iconName || "").toLowerCase()
        if (name.indexOf("rain") >= 0 || name.indexOf("drizzle") >= 0)
            return "\uf73d"
        if (name.indexOf("storm") >= 0 || name.indexOf("thunder") >= 0)
            return "\uf76c"
        if (name.indexOf("snow") >= 0)
            return "\uf2dc"
        if (name.indexOf("clear") >= 0 || name.indexOf("sun") >= 0)
            return "\uf185"
        return "\uf0c2"
    }

    function referenceClockText() {
        const day = root.clock.locale().toString(root.clock.now, "ddd, dd 'de' MMMM")
            .replace(/\./g, "")
        const time = root.clock.locale().toString(root.clock.now, "HH:mm")
        return day + " · " + time
    }

    function clearNativeShape() {
        Hyprland.dispatch("velora-blur:topbar-shape 0")
    }

    onOpticsGenerationChanged: clearNativeShape()
    Component.onCompleted: {
        clearNativeShape()
        revealDelay.start()
    }
    Component.onDestruction: clearNativeShape()

    FontLoader { source: "../../assets/fonts/Poppins-Regular.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-SemiBold.ttf" }

    Timer {
        id: revealDelay
        interval: 18
        repeat: false
        onTriggered: root.revealed = true
    }

    component BarButton: Item {
        id: button
        property string glyph: ""
        property string label: ""
        property bool selected: false
        property real glyphSize: 13
        property real labelSize: 10
        property string accessibleName: label
        signal clicked

        implicitWidth: label.length > 0
            ? Math.max(38, buttonLabel.implicitWidth + 31) : 32
        implicitHeight: 40
        scale: buttonPointer.pressed ? 0.92 : 1

        Behavior on scale {
            NumberAnimation {
                duration: root.motion.reduced ? 0 : 120
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: 30
            radius: 15
            color: button.selected
                ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                    root.theme.accent.b, 0.42)
                : (buttonPointer.containsMouse
                    ? Qt.rgba(1, 1, 1, root.theme.light ? 0.20 : 0.11)
                    : "transparent")
            Behavior on color {
                ColorAnimation { duration: root.motion.reduced ? 0 : 150 }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: button.label.length > 0 ? 7 : 0
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: button.glyph
                color: root.theme.iconInk
                font.family: "FontAwesome"
                font.pixelSize: button.glyphSize
            }
            Text {
                id: buttonLabel
                anchors.verticalCenter: parent.verticalCenter
                visible: button.label.length > 0
                text: button.label
                color: root.theme.textPrimary
                font.family: "Poppins"
                font.pixelSize: button.labelSize
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: buttonPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    Rectangle {
        id: barSurface
        anchors.fill: parent
        color: Qt.rgba(root.theme.barSurface.r, root.theme.barSurface.g,
                       root.theme.barSurface.b, 0.94)

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                root.theme.accent.b, root.theme.light ? 0.055 : 0.105)
        }
    }

    Item {
        id: content
        anchors.fill: parent
        y: root.revealed ? 0 : -height
        opacity: root.revealed ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.motion.reduced ? 0 : 190
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: root.motion.reduced ? 0 : 150 }
        }

        Item {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 10
            width: root.veryCompact ? 370 : Math.min(560, root.width * 0.36)
            height: parent.height

            Row {
                anchors.fill: parent
                spacing: 3

                BarButton {
                    width: 34
                    glyph: "\uf00a"
                    accessibleName: "Abrir aplicativos"
                    onClicked: root.actions.openLauncher()
                }

                Item {
                    id: workspaceSection
                    width: root.workspaceCount * 29
                    height: parent.height
                    readonly property int activeNumber: Math.max(1,
                        Hyprland.focusedWorkspace
                            ? Number(Hyprland.focusedWorkspace.id) : 1)
                    readonly property int groupStart:
                        Math.floor((activeNumber - 1) / root.workspaceCount)
                            * root.workspaceCount
                    readonly property int activeIndex:
                        (activeNumber - 1) % root.workspaceCount

                    Rectangle {
                        x: workspaceSection.activeIndex * 29 + 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 25
                        height: 25
                        radius: 13
                        color: Qt.rgba(root.theme.accent.r,
                            root.theme.accent.g, root.theme.accent.b, 0.46)
                        Behavior on x {
                            NumberAnimation {
                                duration: root.motion.reduced ? 0 : 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: root.workspaceCount
                            Item {
                                required property int index
                                width: 29
                                height: root.height
                                readonly property int workspaceNumber:
                                    workspaceSection.groupStart + index + 1
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.workspaceNumber
                                    color: root.theme.textPrimary
                                    font.family: "Poppins"
                                    font.pixelSize: 10
                                    font.weight: workspaceSection.activeIndex
                                        === parent.index ? Font.Bold : Font.Medium
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace "
                                        + parent.workspaceNumber)
                                }
                            }
                        }
                    }
                }

                Item {
                    width: Math.max(110, leftSection.width
                        - workspaceSection.width - 44)
                    height: parent.height
                    clip: true

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -2
                        Text {
                            width: parent.width
                            text: root.contextualApp()
                            color: root.theme.textMuted
                            elide: Text.ElideRight
                            font.family: "Poppins"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width
                            text: root.contextualTitle()
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                            font.family: "Poppins"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    root.status.adjustBrightness(
                        wheel.angleDelta.y >= 0 ? 1 : -1)
                    wheel.accepted = true
                }
            }
        }

        Row {
            id: centerSection
            anchors.centerIn: parent
            height: parent.height
            spacing: 8

            BarButton {
                width: 78
                glyph: root.weatherGlyph()
                label: root.weather.available
                    ? root.weather.temperature : "--°"
                accessibleName: root.weather.description
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 16
                color: Qt.rgba(root.theme.textSecondary.r,
                    root.theme.textSecondary.g,
                    root.theme.textSecondary.b, 0.22)
            }

            Item {
                width: root.compact ? 175 : 245
                height: parent.height
                Text {
                    anchors.centerIn: parent
                    text: root.compact ? root.clock.topbarTimeText
                        : root.referenceClockText()
                    color: root.theme.textPrimary
                    font.family: "Poppins"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }

        Item {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 10
            width: root.veryCompact ? 192 : Math.min(470, root.width * 0.30)
            height: parent.height

            Row {
                anchors.right: parent.right
                height: parent.height
                spacing: 3

                BarButton {
                    visible: !root.veryCompact
                    width: root.compact ? 110 : 184
                    glyph: root.media.playing ? "\uf04c" : "\uf04b"
                    label: root.media.hasPlayer ? root.media.title : "Sem mídia"
                    accessibleName: "Mídia"
                    onClicked: root.media.hasPlayer
                        ? root.media.togglePlaying() : root.actions.openMusic()
                }
                BarButton {
                    width: 34
                    glyph: "\uf013"
                    accessibleName: "Configurações"
                    onClicked: root.actions.openSettings()
                }
                BarButton {
                    width: 34
                    glyph: root.status.wifiEnabled ? "\uf1eb" : "\uf071"
                    accessibleName: root.status.wifiName
                    onClicked: root.actions.openNetworkSettings()
                }
                BarButton {
                    width: root.compact ? 34 : 66
                    glyph: root.status.muted ? "\uf026" : "\uf028"
                    label: root.compact ? "" : root.status.volumePercent + "%"
                    accessibleName: "Volume"
                    onClicked: root.status.toggleMuted()
                }
                BarButton {
                    width: root.status.hasBattery && !root.compact ? 67 : 34
                    glyph: root.status.batteryCharging ? "\uf0e7" : "\uf240"
                    label: root.status.hasBattery && !root.compact
                        ? root.status.batteryPercent + "%" : ""
                    accessibleName: "Bateria"
                }
                BarButton {
                    width: 34
                    glyph: "\uf011"
                    accessibleName: "Energia"
                    onClicked: root.actions.openSettings()
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    root.status.adjustVolume(wheel.angleDelta.y >= 0 ? 1 : -1)
                    wheel.accepted = true
                }
            }
        }
    }
}
