import QtQuick
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
    property bool nativeShapeDirty: true
    property bool revealed: false

    readonly property real barHeight: Math.round(
        config.topbarHeight * config.topbarScale)
    readonly property real contentPadding: Math.max(6,
        Math.min(20, Number(config.topbarMargin || 0)))
    readonly property real moduleGap: Math.max(0,
        Math.min(8, Number(config.topbarGap || 0)))
    readonly property real sectionGap: 16
    readonly property int compactLevel: width < 1100 ? 2
        : (width < 1450 ? 1 : 0)
    readonly property real maxSideVisibleWidth: Math.max(120,
        width * (compactLevel > 0 ? 0.38 : 0.43))
    readonly property real centerSafeLeft: leftGroup.x + leftGroup.width
        + sectionGap
    readonly property real centerSafeRight: rightGroup.x - sectionGap
    readonly property bool centerFits: centerItems.length > 0
        && centerGroup.x >= centerSafeLeft
        && centerGroup.x + centerGroup.width <= centerSafeRight

    readonly property var leftItems: itemsForSection("left")
    readonly property var centerItems: itemsForSection("center")
    readonly property var rightItems: itemsForSection("right")
    readonly property bool nativeGlassActive:
        theme.resolvedMaterial(({})) === "liquid"

    property alias barSurfaceItem: barSurface

    function itemsForSection(section) {
        return config.topbarItemsForSection(section, false)
    }

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
        if (theme.editorial && !compositor.activeToplevel)
            return "Perfil Editorial"
        if (theme.minimal && !compositor.activeToplevel)
            return "Perfil Minimal"
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

    function componentForType(type) {
        const components = {
            brand: brandComponent,
            workspaces: workspacesComponent,
            launcher: launcherComponent,
            search: searchComponent,
            context: contextComponent,
            weather: weatherComponent,
            clock: clockComponent,
            media: mediaComponent,
            wifi: wifiComponent,
            volume: volumeComponent,
            battery: batteryComponent,
            settings: settingsComponent,
            avatar: avatarComponent
        }
        return components[String(type)] || null
    }

    function queueNativeShape() {
        nativeShapeDirty = true
    }

    function shapeFields(item, radius) {
        const point = item.mapToItem(root, 0, 0)
        return [point.x / width, point.y / nativeSurfaceHeight,
                item.width / width, item.height / nativeSurfaceHeight,
                radius / width].map(function(value) {
            return Number(value).toFixed(6)
        }).join(" ")
    }

    function syncNativeShapes() {
        if (width <= 0 || nativeSurfaceHeight <= 0)
            return
        const shapes = []
        if (root.nativeGlassActive && barSurface.visible
                && barSurface.width > 1 && barSurface.height > 1)
            shapes.push(shapeFields(barSurface, 0))
        Hyprland.dispatch("velora-blur:topbar-shape " + shapes.length
            + (shapes.length ? " " + shapes.join(" ") : ""))
    }

    onWidthChanged: queueNativeShape()
    onHeightChanged: queueNativeShape()
    onNativeSurfaceHeightChanged: queueNativeShape()
    onOpticsGenerationChanged: queueNativeShape()
    onNativeGlassActiveChanged: queueNativeShape()

    FrameAnimation {
        running: root.nativeShapeDirty
        onTriggered: {
            root.syncNativeShapes()
            root.nativeShapeDirty = false
        }
    }

    Component.onCompleted: {
        queueNativeShape()
        revealTimer.start()
    }
    Component.onDestruction: Hyprland.dispatch("velora-blur:topbar-shape 0")

    FontLoader { source: "../../assets/fonts/Poppins-Regular.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-SemiBold.ttf" }

    Timer {
        id: revealTimer
        interval: 18
        repeat: false
        onTriggered: root.revealed = true
    }

    component BarLoader: Loader {
        id: loader
        required property var modelData
        sourceComponent: root.componentForType(modelData.type)
        width: item ? item.implicitWidth * Number(modelData.scale || 1) : 0
        height: root.barHeight
        visible: status === Loader.Ready

        onLoaded: {
            item.scale = Number(modelData.scale || 1)
            item.transformOrigin = Item.Center
            item.anchors.centerIn = loader
        }
    }

    component BarIconButton: NotchButton {
        glyphColor: root.theme.iconInk
    }

    Item {
        id: barContent
        width: root.width
        height: root.barHeight
        y: root.revealed ? 0 : -root.barHeight
        opacity: root.revealed ? 1 : 0

        onYChanged: root.queueNativeShape()

        Behavior on y {
            NumberAnimation {
                duration: root.motion.reduced ? 0 : 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.motion.reduced ? 0 : 160
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: barSurface
            anchors.fill: parent
            radius: 0
            color: root.nativeGlassActive
                ? Qt.rgba(root.theme.barSurface.r, root.theme.barSurface.g,
                    root.theme.barSurface.b, root.theme.light ? 0.76 : 0.68)
                : Qt.rgba(root.theme.barSurface.r,
                    root.theme.barSurface.g,
                    root.theme.barSurface.b, root.theme.light ? 0.96 : 0.94)

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                    root.theme.accent.b, root.theme.light ? 0.035 : 0.075)
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Qt.rgba(root.theme.borderSubtle.r,
                    root.theme.borderSubtle.g,
                    root.theme.borderSubtle.b, 0.72)
            }
        }

        Item {
            id: leftGroup
            x: root.contentPadding
            width: Math.min(leftContent.implicitWidth,
                root.maxSideVisibleWidth)
            height: root.barHeight
            clip: true

            Row {
                id: leftContent
                height: parent.height
                spacing: root.moduleGap
                Repeater { model: root.leftItems; BarLoader {} }
            }
        }

        Item {
            id: centerGroup
            x: Math.round((root.width - width) / 2)
            width: centerContent.implicitWidth
            height: root.barHeight
            visible: root.centerFits

            Row {
                id: centerContent
                anchors.centerIn: parent
                height: parent.height
                spacing: root.moduleGap
                Repeater { model: root.centerItems; BarLoader {} }
            }
        }

        Item {
            id: rightGroup
            x: root.width - root.contentPadding - width
            width: Math.min(rightContent.implicitWidth,
                root.maxSideVisibleWidth)
            height: root.barHeight
            clip: true

            Row {
                id: rightContent
                anchors.right: parent.right
                height: parent.height
                spacing: root.moduleGap
                Repeater { model: root.rightItems; BarLoader {} }
            }
        }
    }

    Component {
        id: brandComponent
        Item {
            implicitWidth: 26
            implicitHeight: root.barHeight

            Rectangle {
                anchors.centerIn: parent
                width: 24; height: 24; radius: 12
                color: brandPointer.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            VeloraLogo {
                anchors.centerIn: parent
                width: 19; height: 19
            }
            MouseArea {
                id: brandPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actions.openLauncher()
            }
        }
    }

    Component {
        id: workspacesComponent
        Item {
            id: workspaceStrip
            implicitWidth: workspaceRow.implicitWidth
            implicitHeight: root.barHeight
            readonly property int buttonWidth: 26
            readonly property int activeNumber: Math.max(1,
                Hyprland.focusedWorkspace
                    ? Number(Hyprland.focusedWorkspace.id) : 1)
            readonly property int groupStart:
                Math.floor((activeNumber - 1) / 5) * 5
            readonly property int activeIndex: (activeNumber - 1) % 5
            property real leadingIndex: activeIndex
            property real trailingIndex: activeIndex

            onActiveIndexChanged: {
                leadingIndex = activeIndex
                trailingIndex = activeIndex
            }

            Behavior on leadingIndex {
                NumberAnimation {
                    duration: root.motion.reduced ? 0 : 100
                    easing.type: Easing.OutSine
                }
            }
            Behavior on trailingIndex {
                NumberAnimation {
                    duration: root.motion.reduced ? 0 : 300
                    easing.type: Easing.OutSine
                }
            }

            Rectangle {
                id: activeWorkspaceIndicator
                z: 0
                x: Math.min(workspaceStrip.leadingIndex,
                    workspaceStrip.trailingIndex)
                    * workspaceStrip.buttonWidth + 2
                anchors.verticalCenter: parent.verticalCenter
                width: Math.abs(workspaceStrip.leadingIndex
                    - workspaceStrip.trailingIndex)
                    * workspaceStrip.buttonWidth
                    + workspaceStrip.buttonWidth - 4
                height: 24
                radius: 12
                color: Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                    root.theme.accent.b, root.theme.light ? 0.42 : 0.56)
                border.width: 1
                border.color: Qt.rgba(root.theme.accentSoft.r,
                    root.theme.accentSoft.g, root.theme.accentSoft.b, 0.28)
            }

            Row {
                id: workspaceRow
                z: 1
                height: parent.height
                spacing: 0
                Repeater {
                    model: 5
                    Item {
                        id: workspaceButton
                        required property int index
                        readonly property int workspaceNumber:
                            workspaceStrip.groupStart + index + 1
                        readonly property bool active:
                            workspaceStrip.activeIndex === index
                        width: workspaceStrip.buttonWidth
                        height: root.barHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: 22; height: 22; radius: 11
                            color: workspacePointer.containsMouse
                                && !workspaceButton.active
                                ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: workspaceButton.workspaceNumber
                            color: workspaceButton.active
                                ? root.theme.textPrimary
                                : root.theme.textSecondary
                            font.family: "Poppins"
                            font.pixelSize: 10
                            font.weight: workspaceButton.active
                                ? Font.Bold : Font.Medium
                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }
                        MouseArea {
                            id: workspacePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace "
                                + workspaceButton.workspaceNumber)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: launcherComponent
        BarIconButton {
            implicitWidth: 26; implicitHeight: root.barHeight
            glyph: "\uf002"; glyphSize: 12
            accessibleName: "Aplicativos"
            onClicked: root.actions.openLauncher()
        }
    }

    Component {
        id: searchComponent
        BarIconButton {
            implicitWidth: 26; implicitHeight: root.barHeight
            glyph: "\uf009"; glyphSize: 12
            accessibleName: "Pesquisar"
            onClicked: root.actions.openSearch()
        }
    }

    Component {
        id: contextComponent
        Item {
            implicitWidth: root.compactLevel > 0 ? 132 : 210
            implicitHeight: root.barHeight

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
                    font.pixelSize: 8
                    font.weight: Font.Medium
                }
                Text {
                    width: parent.width
                    text: root.contextualTitle()
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                    font.family: "Poppins"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }
        }
    }

    Component {
        id: weatherComponent
        Item {
            implicitWidth: root.weather.available ? 72 : 58
            implicitHeight: root.barHeight

            Row {
                anchors.centerIn: parent
                spacing: 5
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weatherGlyph()
                    color: root.theme.textSecondary
                    font.family: "FontAwesome"
                    font.pixelSize: 11
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weather.available
                        ? root.weather.temperature : "--°"
                    color: root.theme.textPrimary
                    font.family: "Poppins"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Component {
        id: clockComponent
        Item {
            implicitWidth: root.compactLevel > 1 ? 96
                : (root.compactLevel > 0 ? 126 : 168)
            implicitHeight: root.barHeight
            Text {
                anchors.fill: parent
                text: root.compactLevel > 1
                    ? root.clock.topbarTimeText
                    : root.clock.topbarCompactDateText
                        + "  •  " + root.clock.topbarTimeText
                color: root.theme.textPrimary
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                font.family: "Poppins"
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }
    }

    Component {
        id: mediaComponent
        Item {
            id: compactMedia
            implicitWidth: root.media.hasPlayer
                ? (root.compactLevel > 0 ? 126 : 194) : 82
            implicitHeight: root.barHeight
            clip: true

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: root.motion.reduced ? 0 : 200
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 5
                anchors.bottomMargin: 5
                radius: height / 2
                color: mediaPointer.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.09) : "transparent"
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                id: mediaArt
                visible: root.media.hasPlayer
                    && String(root.media.artUrl || "").length > 0
                x: 3
                anchors.verticalCenter: parent.verticalCenter
                width: 22; height: 22; radius: 11; clip: true
                color: Qt.rgba(1, 1, 1, 0.07)
                Image {
                    anchors.fill: parent
                    source: root.media.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Text {
                x: mediaArt.visible ? 30 : 8
                width: Math.max(20, transport.x - x - 3)
                height: parent.height
                text: root.media.hasPlayer ? root.media.title : "Sem mídia"
                color: root.media.hasPlayer
                    ? root.theme.textPrimary : root.theme.textSecondary
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.family: "Poppins"
                font.pixelSize: 9
                font.weight: Font.Medium
            }

            Row {
                id: transport
                anchors.right: parent.right
                height: parent.height
                visible: root.media.hasPlayer
                BarIconButton {
                    width: 20; height: parent.height
                    glyph: "\uf048"; glyphSize: 8
                    enabled: root.media.canPrevious
                    onClicked: root.media.previous()
                }
                BarIconButton {
                    width: 22; height: parent.height
                    glyph: root.media.playing ? "\uf04c" : "\uf04b"
                    glyphSize: 8; enabled: root.media.canToggle
                    onClicked: root.media.togglePlaying()
                }
                BarIconButton {
                    width: 20; height: parent.height
                    glyph: "\uf051"; glyphSize: 8
                    enabled: root.media.canNext
                    onClicked: root.media.next()
                }
            }

            MouseArea {
                id: mediaPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.media.hasPlayer
                    ? Qt.ArrowCursor : Qt.PointingHandCursor
                acceptedButtons: root.media.hasPlayer
                    ? Qt.NoButton : Qt.LeftButton
                onClicked: root.actions.openMusic()
            }
        }
    }

    Component {
        id: wifiComponent
        BarIconButton {
            implicitWidth: 26; implicitHeight: root.barHeight
            glyph: root.status.wifiEnabled ? "\uf1eb" : "\uf071"
            glyphSize: 11; accessibleName: root.status.wifiName
            onClicked: root.actions.openNetworkSettings()
        }
    }

    Component {
        id: volumeComponent
        Item {
            implicitWidth: 26; implicitHeight: root.barHeight
            BarIconButton {
                anchors.fill: parent
                glyph: root.status.muted ? "\uf026" : "\uf028"
                glyphSize: 11
                accessibleName: "Volume " + root.status.volumePercent + "%"
                onClicked: root.status.toggleMuted()
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    root.status.adjustVolume(wheel.angleDelta.y >= 0 ? 1 : -1)
                    wheel.accepted = true
                }
            }
        }
    }

    Component {
        id: batteryComponent
        Item {
            implicitWidth: root.compactLevel > 1 ? 29 : 50
            implicitHeight: root.barHeight
            BatteryIndicator {
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                level: root.status.batteryLevel
                charging: root.status.batteryCharging
                scale: 0.78
                color: root.theme.iconInk
                transformOrigin: Item.Left
            }
            Text {
                visible: root.compactLevel < 2
                x: 25; width: 25; height: parent.height
                text: root.status.hasBattery
                    ? root.status.batteryPercent + "%" : "AC"
                color: root.theme.textPrimary
                verticalAlignment: Text.AlignVCenter
                font.family: "Poppins"
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }
    }

    Component {
        id: settingsComponent
        BarIconButton {
            implicitWidth: 26; implicitHeight: root.barHeight
            glyph: "\uf013"; glyphSize: 11
            accessibleName: "Configurações"
            onClicked: root.actions.openSettings()
        }
    }

    Component {
        id: avatarComponent
        Item {
            implicitWidth: 30; implicitHeight: root.barHeight
            Rectangle {
                anchors.centerIn: parent
                width: 24; height: 24; radius: 12
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1,
                    avatarPointer.containsMouse ? 0.48 : 0.22)
                clip: true
                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: root.config.avatarPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                MouseArea {
                    id: avatarPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.actions.openSettings()
                }
            }
        }
    }
}
