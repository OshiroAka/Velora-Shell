import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var theme: null
    property var entries: []
    property string activeKey: ""
    property bool applying: false
    property string errorMessage: ""
    property int sessionSerial: 0
    property string selectedKey: ""
    property string colorFilter: ""
    readonly property var filteredEntries: filteredLibrary()
    readonly property var selectedEntry: entryForKey(selectedKey)
    readonly property color ink: theme ? theme.textPrimary : "#f5f7fb"
    readonly property color inkSoft: theme ? theme.textSecondary : "#b8c4ce"
    readonly property color accent: theme ? theme.accentPrimary : "#73c9cb"
    readonly property color accent2: theme ? theme.accentSecondary : "#9f89d8"
    readonly property color surface: theme
        ? theme.alpha(theme.surfaceCard, theme.themeMode === "dark" ? 0.48 : 0.60)
        : Qt.rgba(0.08, 0.12, 0.15, 0.72)
    readonly property color surfaceHigh: theme
        ? theme.alpha(theme.surfaceButton, theme.themeMode === "dark" ? 0.62 : 0.72)
        : Qt.rgba(0.12, 0.17, 0.20, 0.82)
    readonly property color outline: theme
        ? theme.alpha(theme.borderSoft, theme.themeMode === "dark" ? 0.34 : 0.46)
        : Qt.rgba(1, 1, 1, 0.24)
    readonly property var colorFilters: [
        { key: "", color: "#d6dde0", label: "Todos" },
        { key: "red", color: "#ec5362", label: "Vermelho" },
        { key: "orange", color: "#f19945", label: "Laranja" },
        { key: "yellow", color: "#e9cf52", label: "Amarelo" },
        { key: "green", color: "#62b96c", label: "Verde" },
        { key: "cyan", color: "#51bfc1", label: "Ciano" },
        { key: "blue", color: "#568ce4", label: "Azul" },
        { key: "purple", color: "#a06bdb", label: "Roxo" },
        { key: "pink", color: "#df72ad", label: "Rosa" },
        { key: "neutral", color: "#bfc5c7", label: "Neutro" }
    ]

    signal applyRequested(var entry)
    signal libraryRequested(bool refresh)

    function entryKey(entry) {
        if (!entry)
            return ""
        return String(entry.key || (String(entry.kind || "static") + ":" + String(entry.path || "")))
    }

    function filteredLibrary() {
        const source = Array.isArray(entries) ? entries : []
        const result = []
        for (let index = 0; index < source.length; ++index) {
            const entry = source[index]
            if (!entry || !entry.path)
                continue
            if (colorFilter.length > 0
                    && String(entry.colorGroup || "neutral").toLowerCase() !== colorFilter)
                continue
            result.push(entry)
        }
        return result
    }

    function entryForKey(key) {
        const wanted = String(key || "")
        const source = Array.isArray(entries) ? entries : []
        for (let index = 0; index < source.length; ++index) {
            if (entryKey(source[index]) === wanted)
                return source[index]
        }
        return null
    }

    function resetSession() {
        colorFilter = ""
        selectedKey = activeKey
        libraryRequested(false)
        Qt.callLater(function() {
            if (wallpaperGrid)
                wallpaperGrid.positionViewAtBeginning()
        })
    }

    function mediaBadge(entry) {
        const media = String(entry && entry.mediaType ? entry.mediaType : "").toLowerCase()
        if (media === "engine" || String(entry && entry.kind ? entry.kind : "") === "engine")
            return "ENGINE"
        if (media === "gif")
            return "GIF"
        if (media === "vid" || String(entry && entry.kind ? entry.kind : "") === "live")
            return "VID"
        return ""
    }

    onSessionSerialChanged: resetSession()
    onActiveKeyChanged: {
        if (selectedKey.length <= 0 || entryForKey(selectedKey) === null)
            selectedKey = activeKey
    }
    Component.onCompleted: resetSession()

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 20
            rightMargin: 20
            topMargin: 14
            bottomMargin: 34
        }
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: gallerySurface
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    right: filterRail.left
                    rightMargin: 12
                }
                radius: 24
                color: root.surface
                border.width: 1
                border.color: root.outline

                Rectangle {
                    id: scrollTrack
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 9
                        topMargin: 14
                        bottomMargin: 14
                    }
                    width: 3
                    radius: 1.5
                    color: root.theme
                        ? root.theme.alpha(root.inkSoft, 0.13)
                        : Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        width: parent.width
                        radius: parent.radius
                        color: root.theme
                            ? root.theme.alpha(root.accent, 0.78)
                            : root.accent
                        height: wallpaperGrid.contentHeight <= wallpaperGrid.height
                            ? parent.height
                            : Math.max(28, parent.height * wallpaperGrid.height / wallpaperGrid.contentHeight)
                        y: wallpaperGrid.contentHeight <= wallpaperGrid.height
                            ? 0
                            : (parent.height - height)
                                * Math.max(0, Math.min(1,
                                    wallpaperGrid.contentY
                                        / Math.max(1, wallpaperGrid.contentHeight - wallpaperGrid.height)))
                    }
                }

                GridView {
                    id: wallpaperGrid
                    anchors {
                        fill: parent
                        leftMargin: 20
                        rightMargin: 10
                        topMargin: 12
                        bottomMargin: 12
                    }
                    clip: true
                    model: root.filteredEntries
                    cellWidth: width / 2
                    cellHeight: Math.max(112, (cellWidth - 8) * 0.59 + 16)
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 2600
                    maximumFlickVelocity: 3400

                    delegate: Item {
                        id: wallpaperTile
                        required property var modelData
                        readonly property string key: root.entryKey(modelData)
                        readonly property bool selected: root.selectedKey === key
                        readonly property bool active: root.activeKey === key

                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight

                        DropShadow {
                            anchors.fill: tileSurface
                            source: tileSurface
                            horizontalOffset: 0
                            verticalOffset: 4
                            radius: 10
                            samples: 21
                            color: Qt.rgba(0, 0, 0, tileMouse.containsMouse ? 0.30 : 0.21)
                            transparentBorder: true
                        }

                        Rectangle {
                            id: tileSurface
                            anchors {
                                fill: parent
                                leftMargin: 5
                                rightMargin: 5
                                topMargin: 4
                                bottomMargin: 10
                            }
                            radius: 18
                            color: root.surfaceHigh
                            border.width: wallpaperTile.selected || wallpaperTile.active ? 2 : 1
                            border.color: wallpaperTile.selected
                                ? root.accent
                                : (wallpaperTile.active ? root.accent2 : root.outline)
                            clip: true
                            scale: tileMouse.pressed ? 0.975 : (tileMouse.containsMouse ? 1.012 : 1)

                            Behavior on scale {
                                NumberAnimation {
                                    duration: root.theme && !root.theme.motionEnabled ? 1 : 120
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Image {
                                anchors.fill: parent
                                source: wallpaperTile.modelData.preview || wallpaperTile.modelData.path || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: 42
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(0.01, 0.015, 0.02, 0.82) }
                                }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: 10
                                }
                                text: wallpaperTile.modelData.title || "Wallpaper"
                                color: "#f6f8fb"
                                font.family: root.theme ? root.theme.uiFont : "Sans Serif"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                style: Text.Outline
                                styleColor: Qt.rgba(0, 0, 0, 0.72)
                            }

                            Rectangle {
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    margins: 8
                                }
                                width: Math.max(22, statusRow.implicitWidth + 12)
                                height: 22
                                radius: 11
                                color: Qt.rgba(0.02, 0.025, 0.03, 0.70)
                                border.width: 1
                                border.color: wallpaperTile.active
                                    ? root.accent2
                                    : Qt.rgba(1, 1, 1, 0.25)
                                visible: wallpaperTile.active
                                    || wallpaperTile.selected
                                    || root.mediaBadge(wallpaperTile.modelData).length > 0

                                Row {
                                    id: statusRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    VeloraMaterialIcon {
                                        width: 13
                                        height: 13
                                        visible: wallpaperTile.active || wallpaperTile.selected
                                        iconName: wallpaperTile.active ? "check" : "wallpaper"
                                        iconColor: wallpaperTile.active ? root.accent2 : root.accent
                                        filled: true
                                    }

                                    Text {
                                        text: wallpaperTile.active
                                            ? "ATIVO"
                                            : root.mediaBadge(wallpaperTile.modelData)
                                        visible: text.length > 0
                                        color: "#f6f8fb"
                                        font.family: root.theme ? root.theme.monoFont : "Monospace"
                                        font.pixelSize: 7
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                enabled: !root.applying
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    root.selectedKey = wallpaperTile.key
                                    root.applyRequested(wallpaperTile.modelData)
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 30, 300)
                        visible: root.filteredEntries.length <= 0
                        text: root.entries && root.entries.length > 0
                            ? "Nenhum wallpaper nesta cor."
                            : "Carregando biblioteca de wallpapers…"
                        color: root.inkSoft
                        font.family: root.theme ? root.theme.uiFont : "Sans Serif"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                id: filterRail
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }
                width: 48
                radius: 22
                color: root.surface
                border.width: 1
                border.color: root.outline

                Column {
                    anchors.centerIn: parent
                    spacing: 7

                    Repeater {
                        model: root.colorFilters

                        Rectangle {
                            required property var modelData
                            readonly property bool selected: root.colorFilter === modelData.key
                            width: 28
                            height: 28
                            radius: 10
                            color: modelData.color
                            border.width: selected ? 3 : 1
                            border.color: selected
                                ? root.ink
                                : (filterMouse.containsMouse ? root.inkSoft : root.outline)
                            scale: filterMouse.pressed ? 0.92 : (filterMouse.containsMouse ? 1.08 : 1)

                            Behavior on scale {
                                NumberAnimation {
                                    duration: root.theme && !root.theme.motionEnabled ? 1 : 100
                                    easing.type: Easing.OutCubic
                                }
                            }

                            VeloraMaterialIcon {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                visible: parent.modelData.key.length <= 0
                                iconName: "wallpaper"
                                iconColor: "#384248"
                                filled: true
                            }

                            MouseArea {
                                id: filterMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.colorFilter = parent.modelData.key
                                    wallpaperGrid.positionViewAtBeginning()
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
