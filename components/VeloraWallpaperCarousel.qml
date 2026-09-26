import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: carousel

    property var theme: null
    property bool open: false
    property real revealProgress: open ? 1 : 0
    property var entries: []
    property int selectedIndex: 0
    property int slideDirection: 0
    property real slideProgress: 0
    property string activeKey: ""
    property var favorites: []
    property string mediaFilter: "all"
    property string colorFilter: ""
    property string searchQuery: ""
    property bool favoritesOnly: false
    property bool gridMode: false
    property bool applying: false
    property string errorMessage: ""
    property bool keyboardFocus: false
    property real blurStrength: theme ? theme.wallpaperSelectorBlur : 0.55

    readonly property color surface: theme ? theme.surfacePopup : Qt.rgba(0.10, 0.08, 0.14, 0.92)
    readonly property color surfaceSoft: theme ? theme.surfaceSidebar : Qt.rgba(0.14, 0.11, 0.18, 0.84)
    readonly property color textPrimary: theme ? theme.textPrimary : "#f6effa"
    readonly property color textSecondary: theme ? theme.textSecondary : "#cbbfd4"
    readonly property color accent: theme ? theme.accentPrimary : "#d88bc4"
    readonly property color accentSecondary: theme ? theme.accentSecondary : "#aa91dc"
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.18)
    readonly property string uiFont: theme ? theme.uiFont : "Sans Serif"
    readonly property int motionFast: theme ? theme.motionFast : 100
    readonly property int motionNormal: theme ? theme.motionNormal : 170
    readonly property int motionSlow: theme ? theme.motionSlow : 340
    readonly property bool motionEnabled: theme ? theme.motionEnabled : true
    readonly property real easedSlide: {
        const value = Math.max(0, Math.min(1, slideProgress))
        return value * value * (3 - 2 * value)
    }
    readonly property var currentEntry: entryAt(selectedIndex)
    readonly property string currentKey: currentEntry && currentEntry.key ? String(currentEntry.key) : ""
    readonly property bool currentFavorite: currentKey.length > 0 && favorites.indexOf(currentKey) >= 0
    readonly property var colorFilters: [
        { key: "red", color: "#ec5362" },
        { key: "orange", color: "#f19945" },
        { key: "yellow", color: "#e9cf52" },
        { key: "green", color: "#62b96c" },
        { key: "cyan", color: "#51bfc1" },
        { key: "blue", color: "#568ce4" },
        { key: "purple", color: "#a06bdb" },
        { key: "pink", color: "#df72ad" },
        { key: "neutral", color: "#c8c4ca" }
    ]

    signal navigateRequested(int delta)
    signal selectRelativeRequested(int delta)
    signal selectAbsoluteRequested(int index)
    signal applyRequested(var entry)
    signal randomRequested()
    signal favoriteRequested(var entry)
    signal hideRequested(var entry)
    signal refreshRequested()
    signal closeRequested()
    signal mediaFilterRequested(string filter)
    signal colorFilterRequested(string filter)
    signal searchRequested(string query)
    signal favoritesOnlyRequested(bool enabled)
    signal gridModeRequested(bool enabled)

    function alpha(color, opacity) {
        if (theme && typeof theme.alpha === "function")
            return theme.alpha(color, opacity)
        return Qt.rgba(color.r, color.g, color.b, opacity)
    }

    function normalizedIndex(index) {
        const count = entries ? entries.length : 0
        if (count <= 0)
            return 0
        return ((index % count) + count) % count
    }

    function entryAt(index) {
        if (!entries || entries.length <= 0)
            return null
        return entries[normalizedIndex(index)]
    }

    function entryForSlot(slot) {
        return entryAt(selectedIndex + slot)
    }

    function entryKey(entry) {
        if (!entry)
            return ""
        if (entry.key)
            return String(entry.key)
        return String(entry.kind || "static") + ":" + String(entry.path || "")
    }

    function mediaBadge(entry) {
        if (!entry)
            return ""
        const media = String(entry.mediaType || "")
        if (media === "engine" || String(entry.kind || "") === "engine")
            return "ENGINE"
        if (media === "gif")
            return "GIF"
        if (media === "vid" || String(entry.kind || "") === "live")
            return "VID"
        return ""
    }

    function requestSearchFocus() {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    function handleEscape() {
        closeRequested()
    }

    function handleWheel(delta) {
        if (Math.abs(delta) < 1 || entries.length <= 1)
            return
        navigateRequested(delta < 0 ? 1 : -1)
    }

    focus: keyboardFocus
    opacity: Math.max(0, Math.min(1, revealProgress))
    visible: open || opacity > 0.01

    Keys.onEscapePressed: function(event) {
        handleEscape()
        event.accepted = true
    }

    Keys.onPressed: function(event) {
        if (!open)
            return

        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
            navigateRequested(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
            navigateRequested(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentEntry)
                applyRequested(currentEntry)
            event.accepted = true
        }
    }

    onVisibleChanged: {
        if (visible && keyboardFocus)
            Qt.callLater(function() { carousel.forceActiveFocus() })
    }

    Rectangle {
        anchors.fill: parent
        // The compositor only blurs pixels painted by this backdrop. At zero the
        // selector stays crisp and the wallpaper is left completely untouched.
        color: Qt.rgba(
            0.025,
            0.020,
            0.032,
            (theme && theme.themeMode === "dark" ? 0.42 : 0.34) * Math.max(0, Math.min(1, carousel.blurStrength))
        )
        radius: 8
        antialiasing: true
        opacity: carousel.revealProgress

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: carousel.closeRequested()
            onWheel: function(wheel) {
                carousel.handleWheel(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x)
                wheel.accepted = true
            }
        }
    }

    Rectangle {
        id: topCapsule

        width: Math.min(parent.width - 48, 860)
        height: 48
        x: Math.round((parent.width - width) / 2)
        y: Math.round(28 + (1 - carousel.revealProgress) * -12)
        z: 80
        radius: 24
        color: carousel.alpha(carousel.surface, theme && theme.themeMode === "dark" ? 0.88 : 0.92)
        border.width: 1
        border.color: carousel.alpha(carousel.borderSoft, 0.42)
        opacity: carousel.revealProgress
        antialiasing: true
        visible: false

        Row {
            id: topFilterRow

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 6

            Repeater {
                model: [
                    { key: "all", label: "ALL" },
                    { key: "img", label: "IMG" },
                    { key: "vid", label: "VID" },
                    { key: "gif", label: "GIF" }
                ]

                delegate: FilterChip {
                    required property var modelData
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    label: modelData.label
                    active: carousel.mediaFilter === modelData.key
                    onClicked: carousel.mediaFilterRequested(modelData.key)
                }
            }

            Rectangle {
                width: 1
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                color: carousel.alpha(carousel.borderSoft, 0.34)
            }

            Repeater {
                model: carousel.colorFilters

                delegate: ColorChip {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    swatchColor: modelData.color
                    active: carousel.colorFilter === modelData.key
                    onClicked: carousel.colorFilterRequested(active ? "" : modelData.key)
                }
            }

            FilterChip {
                width: 38
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                label: "♥"
                active: carousel.favoritesOnly
                tooltip: "Somente favoritos (F)"
                onClicked: carousel.favoritesOnlyRequested(!carousel.favoritesOnly)
            }

            Item { width: Math.max(0, topCapsule.width - 720); height: 1 }

            Text {
                height: parent.height
                width: 88
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: carousel.entries.length > 0
                    ? (carousel.normalizedIndex(carousel.selectedIndex) + 1) + " / " + carousel.entries.length
                    : "0 / 0"
                color: carousel.textSecondary
                font.family: carousel.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
    }

    Item {
        id: carouselStage

        readonly property int cardCount: Math.min(13, Math.max(1, carousel.entries.length))
        readonly property real centerWidth: Math.min(740, Math.max(500, width * 0.46))
        readonly property real sideWidth: Math.min(110, Math.max(56, width * 0.064))
        readonly property real centerHeight: Math.min(height - 12, centerWidth * 0.5625)
        readonly property real sideHeight: centerHeight * 0.92
        readonly property real firstSideDistance: centerWidth / 2 + sideWidth / 2 + 7
        readonly property real sideStep: Math.max(
            sideWidth * 0.70 + 5,
            (width / 2 - firstSideDistance - sideWidth / 2 - 14) / 4)

        function focusForOffset(offset) {
            return Math.max(0, 1 - Math.min(1, Math.abs(offset)))
        }

        function widthForOffset(offset) {
            const focus = focusForOffset(offset)
            return sideWidth + (centerWidth - sideWidth) * focus
        }

        function heightForOffset(offset) {
            const focus = focusForOffset(offset)
            return sideHeight + (centerHeight - sideHeight) * focus
        }

        function centerForOffset(offset) {
            const sign = offset < 0 ? -1 : 1
            const distance = Math.abs(offset)
            if (distance <= 1)
                return width / 2 + sign * firstSideDistance * distance
            return width / 2 + sign * (firstSideDistance + (distance - 1) * sideStep)
        }

        x: 0
        y: Math.round((parent.height - height) / 2)
        width: parent.width
        height: Math.min(650, Math.max(360, parent.height * 0.60))
        z: 30
        visible: !carousel.gridMode && carousel.entries.length > 0
        opacity: carousel.revealProgress
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: function(wheel) {
                carousel.handleWheel(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x)
                wheel.accepted = true
            }
        }

        Repeater {
            // One card on each side remains outside the viewport. It keeps the
            // next thumbnails warm and prevent the edge card from being created
            // only after the slide has already finished.
            model: carousel.open && carousel.entries.length > 0 ? carouselStage.cardCount : 0

            delegate: Item {
                id: wallpaperCard

                required property int index
                readonly property int centerSlot: Math.floor(carouselStage.cardCount / 2)
                readonly property int slotOffset: index - centerSlot
                readonly property real visualOffset: slotOffset - carousel.slideDirection * carousel.easedSlide
                readonly property real distance: Math.abs(visualOffset)
                readonly property real focusAmount: carouselStage.focusForOffset(visualOffset)
                readonly property var entry: carousel.entryForSlot(slotOffset)
                readonly property string entryKey: carousel.entryKey(entry)
                readonly property bool activeWallpaper: entryKey.length > 0 && entryKey === carousel.activeKey
                readonly property bool favoriteWallpaper: entryKey.length > 0 && carousel.favorites.indexOf(entryKey) >= 0
                readonly property real sideSkew: Math.min(54, Math.max(15, width * 0.28))
                readonly property real centerSkew: Math.min(54, Math.max(15, width * 0.075))
                readonly property real cardSkew: sideSkew + (centerSkew - sideSkew) * focusAmount
                readonly property real visibleEdgeSpan: Math.min(x + width, carouselStage.width - x)
                readonly property real edgeFadeProgress: Math.max(0, Math.min(1,
                    visibleEdgeSpan / Math.max(64, carouselStage.sideWidth * 0.78)))
                readonly property real edgeOpacity: edgeFadeProgress * edgeFadeProgress * (3 - 2 * edgeFadeProgress)
                readonly property real distanceOpacity: Math.max(0.18, 1 - Math.max(0, distance - 3.6) * 0.20)

                function drawCardPath(ctx, inset) {
                    const pad = Math.max(0, inset || 0)
                    const left = pad
                    const right = Math.max(left + 1, width - pad)
                    const top = pad
                    const bottom = Math.max(top + 1, height - pad)
                    const skew = Math.min(cardSkew, Math.max(7, (right - left) * 0.32))
                    ctx.beginPath()
                    ctx.moveTo(left + skew, top)
                    ctx.lineTo(right, top)
                    ctx.lineTo(right - skew, bottom)
                    ctx.lineTo(left, bottom)
                    ctx.closePath()
                }

                width: Math.round(carouselStage.widthForOffset(visualOffset))
                height: Math.round(carouselStage.heightForOffset(visualOffset))
                x: Math.round(carouselStage.centerForOffset(visualOffset) - width / 2)
                y: Math.round((carouselStage.height - height) / 2)
                z: Math.round(100 + focusAmount * 100 - distance)
                opacity: distanceOpacity * edgeOpacity
                visible: entry !== null && x + width > -40 && x < carouselStage.width + 40

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: cardMask }

                    Rectangle {
                        anchors.fill: parent
                        color: carousel.alpha(carousel.surfaceSoft, 0.96)
                    }

                    Image {
                        id: wallpaperImage

                        anchors.fill: parent
                        source: wallpaperCard.entry && wallpaperCard.entry.preview ? wallpaperCard.entry.preview : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        retainWhileLoading: true
                        smooth: true
                        mipmap: false
                        sourceSize.width: 720
                        sourceSize.height: 405
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, wallpaperCard.focusAmount > 0.55 ? 0.02 : 0.14)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.min(92, parent.height * 0.25)
                        visible: wallpaperCard.focusAmount > 0.72
                        gradient: Gradient {
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.58) }
                        }
                    }
                }

                Canvas {
                    id: cardMask
                    anchors.fill: parent
                    visible: false
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        wallpaperCard.drawCardPath(ctx, 1)
                        ctx.fillStyle = "white"
                        ctx.fill()
                    }
                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        wallpaperCard.drawCardPath(ctx, wallpaperCard.focusAmount > 0.5 ? 2 : 1)
                        ctx.strokeStyle = carousel.alpha(
                            wallpaperCard.focusAmount > 0.5 ? carousel.accent : carousel.borderSoft,
                            wallpaperCard.focusAmount > 0.5 ? 0.72 : 0.36)
                        ctx.lineWidth = wallpaperCard.focusAmount > 0.5 ? 2 : 1
                        ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Math.round(wallpaperCard.cardSkew + 12)
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 15
                    visible: wallpaperCard.focusAmount > 0.72
                    text: wallpaperCard.entry ? String(wallpaperCard.entry.title || "Wallpaper") : ""
                    color: "white"
                    font.family: carousel.uiFont
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Badge {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 13
                    anchors.rightMargin: 15
                    visible: wallpaperCard.focusAmount > 0.55 && carousel.mediaBadge(wallpaperCard.entry).length > 0
                    label: carousel.mediaBadge(wallpaperCard.entry)
                }

                Badge {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 15
                    anchors.bottomMargin: 13
                    visible: wallpaperCard.activeWallpaper && wallpaperCard.focusAmount <= 0.72
                    label: "ACTIVE"
                    highlighted: true
                }

                MouseArea {
                    id: cardMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        carousel.forceActiveFocus()
                        if (wallpaperCard.slotOffset !== 0)
                            carousel.selectRelativeRequested(wallpaperCard.slotOffset)
                    }
                    onDoubleClicked: {
                        if (wallpaperCard.slotOffset === 0 && wallpaperCard.entry)
                            carousel.applyRequested(wallpaperCard.entry)
                    }
                    onWheel: function(wheel) {
                        carousel.handleWheel(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x)
                        wheel.accepted = true
                    }
                }

                scale: cardMouse.containsMouse && wallpaperCard.focusAmount > 0.5 ? 1.012 : 1
                Behavior on scale {
                    enabled: carousel.motionEnabled
                    NumberAnimation { duration: carousel.motionFast; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    Rectangle {
        id: gridStage

        x: Math.round(Math.max(34, (parent.width - width) / 2))
        y: topCapsule.y + topCapsule.height + 22
        width: Math.min(parent.width - 68, 1320)
        height: Math.max(220, bottomCapsule.y - y - 20)
        z: 32
        visible: false
        opacity: carousel.revealProgress
        radius: 24
        color: carousel.alpha(carousel.surface, theme && theme.themeMode === "dark" ? 0.76 : 0.84)
        border.width: 1
        border.color: carousel.alpha(carousel.borderSoft, 0.34)
        clip: true

        GridView {
            id: wallpaperGrid

            anchors.fill: parent
            anchors.margins: 14
            model: gridStage.visible ? carousel.entries : []
            cellWidth: Math.max(190, Math.floor(width / Math.max(1, Math.floor(width / 224))))
            cellHeight: Math.round(cellWidth * 0.62)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: carousel.normalizedIndex(carousel.selectedIndex)

            delegate: Item {
                id: gridTile

                required property int index
                readonly property var entry: carousel.entries[index]
                readonly property string entryKey: carousel.entryKey(entry)
                readonly property bool selected: index === carousel.normalizedIndex(carousel.selectedIndex)

                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 16
                    color: carousel.alpha(carousel.surfaceSoft, 0.92)
                    border.width: gridTile.selected ? 2 : 1
                    border.color: gridTile.selected ? carousel.alpha(carousel.accent, 0.86) : carousel.alpha(carousel.borderSoft, 0.30)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: gridTile.entry && gridTile.entry.preview ? gridTile.entry.preview : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        retainWhileLoading: true
                        sourceSize.width: 420
                        sourceSize.height: 260
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 42
                        gradient: Gradient {
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.72) }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 11
                        text: gridTile.entry ? String(gridTile.entry.title || "Wallpaper") : ""
                        color: "white"
                        font.family: carousel.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Badge {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 9
                        visible: gridTile.entryKey === carousel.activeKey || carousel.mediaBadge(gridTile.entry).length > 0
                        label: gridTile.entryKey === carousel.activeKey ? "ACTIVE" : carousel.mediaBadge(gridTile.entry)
                        highlighted: gridTile.entryKey === carousel.activeKey
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: carousel.selectAbsoluteRequested(gridTile.index)
                        onDoubleClicked: {
                            carousel.selectAbsoluteRequested(gridTile.index)
                            carousel.applyRequested(gridTile.entry)
                        }
                    }
                }
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    positionViewAtIndex(currentIndex, GridView.Contain)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: carousel.entries.length <= 0
        z: 45
        opacity: carousel.revealProgress

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nenhum wallpaper encontrado"
            color: carousel.textPrimary
            font.family: carousel.uiFont
            font.pixelSize: 21
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Limpe a busca ou os filtros para ver a biblioteca."
            color: carousel.textSecondary
            font.family: carousel.uiFont
            font.pixelSize: 13
        }

        FilterChip {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 126
            height: 36
            label: "LIMPAR FILTROS"
            active: true
            onClicked: {
                carousel.searchRequested("")
                carousel.mediaFilterRequested("all")
                carousel.colorFilterRequested("")
                carousel.favoritesOnlyRequested(false)
            }
        }
    }

    Rectangle {
        id: bottomCapsule

        width: Math.min(parent.width - 48, 1080)
        height: 66
        x: Math.round((parent.width - width) / 2)
        y: Math.round(parent.height - height - 30 + (1 - carousel.revealProgress) * 14)
        z: 90
        radius: 28
        color: carousel.alpha(carousel.surface, theme && theme.themeMode === "dark" ? 0.90 : 0.94)
        border.width: 1
        border.color: carousel.alpha(carousel.borderSoft, 0.44)
        opacity: carousel.revealProgress
        antialiasing: true
        visible: false

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            ActionButton {
                glyph: "‹"
                tooltip: "Anterior (A / ←)"
                enabled: carousel.entries.length > 1
                onClicked: carousel.navigateRequested(-1)
            }

            ActionButton {
                glyph: "›"
                tooltip: "Próximo (D / →)"
                enabled: carousel.entries.length > 1
                onClicked: carousel.navigateRequested(1)
            }

            Item {
                width: Math.max(126, bottomCapsule.width - 710)
                height: parent.height

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: carousel.currentEntry ? String(carousel.currentEntry.title || "Wallpaper") : "Sem resultados"
                        color: carousel.textPrimary
                        font.family: carousel.uiFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: carousel.applying
                            ? "Aplicando…"
                            : (carousel.currentKey === carousel.activeKey ? "Ativo" : "Enter ou duplo clique para aplicar")
                        color: carousel.currentKey === carousel.activeKey ? carousel.accent : carousel.textSecondary
                        font.family: carousel.uiFont
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }

            ActionButton {
                glyph: "⤨"
                tooltip: "Escolher aleatoriamente"
                enabled: carousel.entries.length > 1
                onClicked: carousel.randomRequested()
            }

            ActionButton {
                glyph: carousel.currentFavorite ? "♥" : "♡"
                active: carousel.currentFavorite
                tooltip: carousel.currentFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos"
                enabled: carousel.currentEntry !== null
                onClicked: carousel.favoriteRequested(carousel.currentEntry)
            }

            ActionButton {
                glyph: "⊘"
                tooltip: "Ocultar este wallpaper"
                enabled: carousel.currentEntry !== null
                onClicked: carousel.hideRequested(carousel.currentEntry)
            }

            Rectangle {
                width: Math.min(260, Math.max(190, bottomCapsule.width * 0.235))
                height: 42
                anchors.verticalCenter: parent.verticalCenter
                radius: 19
                color: carousel.alpha(carousel.surfaceSoft, 0.72)
                border.width: searchInput.activeFocus ? 1.5 : 1
                border.color: searchInput.activeFocus ? carousel.alpha(carousel.accent, 0.80) : carousel.alpha(carousel.borderSoft, 0.32)

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⌕"
                    color: carousel.textSecondary
                    font.pixelSize: 17
                }

                TextInput {
                    id: searchInput

                    anchors.left: parent.left
                    anchors.leftMargin: 39
                    anchors.right: parent.right
                    anchors.rightMargin: 32
                    anchors.verticalCenter: parent.verticalCenter
                    text: carousel.searchQuery
                    color: carousel.textPrimary
                    selectionColor: carousel.alpha(carousel.accent, 0.44)
                    selectedTextColor: carousel.textPrimary
                    font.family: carousel.uiFont
                    font.pixelSize: 12
                    clip: true
                    onTextEdited: carousel.searchRequested(text)
                    Keys.onEscapePressed: function(event) {
                        carousel.handleEscape()
                        event.accepted = true
                    }
                    Keys.onReturnPressed: function(event) {
                        carousel.forceActiveFocus()
                        event.accepted = true
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    visible: carousel.searchQuery.length <= 0 && !searchInput.activeFocus
                    text: "/"
                    color: carousel.textSecondary
                    font.family: carousel.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Text {
                    anchors.left: searchInput.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: carousel.searchQuery.length <= 0 && !searchInput.activeFocus
                    text: "Buscar wallpapers"
                    color: carousel.textSecondary
                    font.family: carousel.uiFont
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.IBeamCursor
                    onClicked: carousel.requestSearchFocus()
                }
            }

            ActionButton {
                glyph: carousel.gridMode ? "▰" : "▦"
                active: carousel.gridMode
                tooltip: carousel.gridMode ? "Voltar ao carrossel (G)" : "Visualização em grade (G)"
                onClicked: carousel.gridModeRequested(!carousel.gridMode)
            }

            ActionButton {
                glyph: "↻"
                tooltip: "Atualizar biblioteca"
                onClicked: carousel.refreshRequested()
            }

            ActionButton {
                glyph: "×"
                tooltip: "Fechar (Esc)"
                onClicked: carousel.closeRequested()
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomCapsule.top
        anchors.bottomMargin: 10
        width: Math.min(560, errorText.implicitWidth + 34)
        height: errorMessage.length > 0 ? 34 : 0
        radius: 17
        color: carousel.alpha("#8f334d", 0.92)
        visible: height > 0
        opacity: carousel.revealProgress
        z: 95

        Text {
            id: errorText
            anchors.centerIn: parent
            text: carousel.errorMessage
            color: "white"
            font.family: carousel.uiFont
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    component FilterChip: Rectangle {
        id: filterChip

        property string label: "ALL"
        property bool active: false
        property string tooltip: ""
        signal clicked()

        width: Math.max(46, label.length * 8 + 22)
        height: 32
        radius: height / 2
        color: active
            ? carousel.alpha(carousel.accent, theme && theme.themeMode === "dark" ? 0.30 : 0.24)
            : (filterMouse.containsMouse ? carousel.alpha(carousel.surfaceSoft, 0.72) : "transparent")
        border.width: active ? 1 : 0
        border.color: carousel.alpha(carousel.accent, 0.62)

        Text {
            anchors.centerIn: parent
            text: filterChip.label
            color: filterChip.active ? carousel.textPrimary : carousel.textSecondary
            font.family: carousel.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        MouseArea {
            id: filterMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: filterChip.clicked()
        }

        Behavior on color {
            enabled: carousel.motionEnabled
            ColorAnimation { duration: carousel.motionFast }
        }
    }

    component ColorChip: Rectangle {
        id: colorChip

        property color swatchColor: "white"
        property bool active: false
        signal clicked()

        width: 24
        height: 32
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: colorChip.active ? 18 : 14
            height: width
            radius: width / 2
            color: colorChip.swatchColor
            border.width: colorChip.active ? 2 : 1
            border.color: colorChip.active ? carousel.textPrimary : carousel.alpha(carousel.borderSoft, 0.48)

            Behavior on width {
                enabled: carousel.motionEnabled
                NumberAnimation { duration: carousel.motionFast; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: colorChip.clicked()
        }
    }

    component ActionButton: Rectangle {
        id: actionButton

        property string glyph: "×"
        property string tooltip: ""
        property bool active: false
        signal clicked()

        width: 44
        height: 44
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        radius: 18
        color: active
            ? carousel.alpha(carousel.accent, 0.26)
            : (actionMouse.containsMouse ? carousel.alpha(carousel.surfaceSoft, 0.82) : "transparent")
        border.width: active ? 1 : 0
        border.color: carousel.alpha(carousel.accent, 0.58)
        opacity: enabled ? 1 : 0.34
        scale: actionMouse.pressed ? 0.94 : (actionMouse.containsMouse ? 1.06 : 1)

        Text {
            anchors.centerIn: parent
            text: actionButton.glyph
            color: actionButton.active ? carousel.accent : carousel.textPrimary
            font.family: carousel.uiFont
            font.pixelSize: actionButton.glyph === "×" ? 24 : 19
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            enabled: actionButton.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.clicked()
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 7
            width: tooltipLabel.implicitWidth + 18
            height: actionButton.tooltip.length > 0 && actionMouse.containsMouse ? 28 : 0
            radius: 12
            visible: height > 0
            color: carousel.alpha(carousel.surface, 0.97)
            border.width: 1
            border.color: carousel.alpha(carousel.borderSoft, 0.36)
            z: 500

            Text {
                id: tooltipLabel
                anchors.centerIn: parent
                text: actionButton.tooltip
                color: carousel.textPrimary
                font.family: carousel.uiFont
                font.pixelSize: 10
                wrapMode: Text.NoWrap
            }
        }

        Behavior on scale {
            enabled: carousel.motionEnabled
            NumberAnimation { duration: carousel.motionFast; easing.type: Easing.OutCubic }
        }
    }

    component Badge: Rectangle {
        id: badge

        property string label: "VID"
        property bool highlighted: false

        width: badgeText.implicitWidth + 16
        height: 24
        radius: 10
        color: highlighted ? carousel.alpha(carousel.accent, 0.86) : Qt.rgba(0.04, 0.035, 0.055, 0.76)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, highlighted ? 0.34 : 0.20)

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: badge.label
            color: "white"
            font.family: carousel.uiFont
            font.pixelSize: 9
            font.weight: Font.Bold
        }
    }
}
