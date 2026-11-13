import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: ui

    property var theme: null
    property var controller: null
    property bool embedded: false
    property var palette: null
    property string category: ""
    property bool resetArmed: false
    property string mediaSection: "playback"
    property int activeTab: 1

    readonly property color accent: palette ? palette.accent : theme ? theme.accentPrimary : "#3f7cff"
    readonly property color primaryText: palette ? palette.textPrimary : theme ? theme.textPrimary : "#f5f7ff"
    readonly property color secondaryText: palette ? palette.textSecondary : theme ? theme.textSecondary : "#8f99b2"
    readonly property color panelColor: theme
        ? theme.withAlpha(theme.surfacePopup, theme.themeMode === "dark" ? 0.90 : 0.86)
        : Qt.rgba(0.025, 0.045, 0.10, 0.94)
    readonly property color cardColor: theme
        ? theme.withAlpha(theme.surfaceCard, theme.themeMode === "dark" ? 0.44 : 0.58)
        : Qt.rgba(0.04, 0.07, 0.14, 0.82)
    readonly property color inputColor: theme
        ? theme.withAlpha(theme.surfaceInput, theme.themeMode === "dark" ? 0.38 : 0.55)
        : Qt.rgba(0.03, 0.055, 0.12, 0.88)
    readonly property color lineColor: theme
        ? theme.withAlpha(theme.borderSoft, theme.themeMode === "dark" ? 0.13 : 0.30)
        : Qt.rgba(0.35, 0.50, 0.82, 0.22)
    readonly property string uiFont: palette ? palette.bodyFont : theme ? theme.uiFont : "Noto Sans"
    readonly property var tabs: ["Barra", "Menu", "Wallpaper", "Moldura", "Lyrics", "Velyrics"]
    readonly property bool externalSurface: controller ? controller.externalSurface === true : false

    implicitHeight: embedded ? (pageLoader.item ? pageLoader.item.implicitHeight : 0) + 50 : 640
    radius: 24
    color: externalSurface || embedded ? "transparent" : panelColor
    border.width: externalSurface || embedded ? 0 : 1
    border.color: theme ? theme.withAlpha(theme.accentPrimary, 0.25) : Qt.rgba(0.20, 0.42, 0.85, 0.34)
    clip: true
    antialiasing: true

    function resetCurrentPage() {
        if (!theme)
            return

        if (embedded && category === "appearance") {
            if (controller) controller.selectTheme("default")
            return
        }
        if (embedded && category === "language") {
            theme.setLanguage("pt-BR")
            return
        }
        if (activeTab === 1) {
            theme.resetBarAppearance()
            theme.resetBarWidth()
            theme.resetTopBarAppearance()
            theme.setBarLabelsVisible(true)
            theme.setBarBlurEnabled(true)
        } else if (activeTab === 2) {
            theme.setControlCenterPosition("bottom")
        } else if (activeTab === 3 && controller) {
            controller.wallpaperTransition = "fade"
            controller.wallpaperTransitionDuration = 1.0
            controller.wallpaperStaticDelay = 0.12
            controller.saveWallpaperTransition()
            controller.setWallpaperLiveTransition("shader")
            if (!embedded) controller.setTerminalStrongColors(false)
            theme.setWallpaperSelectorPosition("center")
            theme.setWallpaperSelectorBlur(0.55)
        } else if (activeTab === 4) {
            theme.setDesktopFrameEnabled(true)
            theme.setFrameBlurEnabled(true)
            theme.setPopupAttachedToBar(true)
            theme.setVisualizerMode("wave")
            theme.setVisualizerStrength(0.46)
        } else if (activeTab === 5) {
            theme.resetLyricsSettings()
            theme.resetLyricsTransformSettings()
            theme.resetLyricsMaterialSettings()
        } else if (activeTab === 6 && controller) {
            controller.resetVelyricsSettings()
        }
    }

    Keys.onEscapePressed: if (controller) controller.closeRequested()

    component SectionTitle: Text {
        required property string label
        text: label
        color: ui.accent
        font.family: ui.uiFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
    }

    component Divider: Rectangle {
        implicitHeight: 1
        color: ui.lineColor
    }

    component UiIcon: Canvas {
        id: glyph

        property string iconName: "settings"
        property color lineColor: ui.primaryText

        antialiasing: true
        onIconNameChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function boxPath(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const ox = (width - s) / 2
            const oy = (height - s) / 2
            const cx = width / 2
            const cy = height / 2
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = lineColor
            ctx.fillStyle = lineColor
            ctx.lineWidth = Math.max(1.4, s * 0.075)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconName === "check") {
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.22, oy + s * 0.52)
                ctx.lineTo(ox + s * 0.43, oy + s * 0.72)
                ctx.lineTo(ox + s * 0.80, oy + s * 0.29)
                ctx.stroke()
            } else if (iconName === "refresh") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.29, Math.PI * 0.25, Math.PI * 1.78)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.18, oy + s * 0.29)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.52)
                ctx.lineTo(ox + s * 0.38, oy + s * 0.42)
                ctx.stroke()
            } else if (iconName === "discord") {
                boxPath(ctx, ox + s * 0.17, oy + s * 0.27, s * 0.66, s * 0.48, s * 0.18)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(ox + s * 0.40, oy + s * 0.50, s * 0.045, 0, Math.PI * 2)
                ctx.arc(ox + s * 0.60, oy + s * 0.50, s * 0.045, 0, Math.PI * 2)
                ctx.fill()
                ctx.beginPath()
                ctx.arc(cx, oy + s * 0.54, s * 0.19, 0.16, Math.PI - 0.16)
                ctx.stroke()
            } else if (iconName === "battery") {
                boxPath(ctx, ox + s * 0.17, oy + s * 0.30, s * 0.60, s * 0.40, s * 0.07)
                ctx.stroke()
                ctx.fillRect(ox + s * 0.78, oy + s * 0.42, s * 0.07, s * 0.16)
                ctx.fillRect(ox + s * 0.25, oy + s * 0.38, s * 0.34, s * 0.24)
            } else if (iconName === "sun") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.17, 0, Math.PI * 2)
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.28, cy + Math.sin(a) * s * 0.28)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.39, cy + Math.sin(a) * s * 0.39)
                    ctx.stroke()
                }
            } else if (iconName === "wallpaper") {
                boxPath(ctx, ox + s * 0.13, oy + s * 0.20, s * 0.74, s * 0.60, s * 0.06)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.19, oy + s * 0.70)
                ctx.lineTo(ox + s * 0.39, oy + s * 0.49)
                ctx.lineTo(ox + s * 0.53, oy + s * 0.62)
                ctx.lineTo(ox + s * 0.70, oy + s * 0.43)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.62)
                ctx.stroke()
            } else if (iconName === "volume") {
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.18, oy + s * 0.42)
                ctx.lineTo(ox + s * 0.34, oy + s * 0.42)
                ctx.lineTo(ox + s * 0.53, oy + s * 0.26)
                ctx.lineTo(ox + s * 0.53, oy + s * 0.74)
                ctx.lineTo(ox + s * 0.34, oy + s * 0.58)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.58)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(ox + s * 0.52, cy, s * 0.25, -0.8, 0.8)
                ctx.stroke()
            } else if (iconName === "box") {
                ctx.beginPath()
                ctx.moveTo(cx, oy + s * 0.16)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.34)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.68)
                ctx.lineTo(cx, oy + s * 0.84)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.68)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.34)
                ctx.closePath()
                ctx.moveTo(ox + s * 0.18, oy + s * 0.34)
                ctx.lineTo(cx, oy + s * 0.51)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.34)
                ctx.moveTo(cx, oy + s * 0.51)
                ctx.lineTo(cx, oy + s * 0.84)
                ctx.stroke()
            } else {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.21, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.07, 0, Math.PI * 2)
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.27, cy + Math.sin(a) * s * 0.27)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.39, cy + Math.sin(a) * s * 0.39)
                    ctx.stroke()
                }
            }
        }
    }

    component ChoiceButton: Rectangle {
        id: choice

        property string label: ""
        property string iconName: ""
        property bool active: false
        property bool compact: false
        signal clicked()
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button; Accessible.name: label
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()

        implicitHeight: compact ? 34 : 38
        radius: 9
        color: active ? ui.theme.withAlpha(ui.accent, 0.22) : ui.inputColor
        border.width: 1
        border.color: active ? ui.theme.withAlpha(ui.accent, 0.82) : ui.lineColor

        Row {
            anchors.centerIn: parent
            spacing: 6

            UiIcon {
                visible: choice.iconName.length > 0
                width: visible ? 18 : 0
                height: 18
                iconName: choice.iconName
                lineColor: choice.active ? ui.accent : ui.secondaryText
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: choice.label
                color: choice.active ? ui.primaryText : ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 11
                font.weight: choice.active ? Font.DemiBold : Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.clicked()
        }
    }

    component ToggleRow: Item {
        id: toggleRow

        property string label: ""
        property string hint: ""
        property bool checked: false
        signal toggled()
        activeFocusOnTab: enabled
        Accessible.role: Accessible.CheckBox; Accessible.name: label; Accessible.checked: checked
        Accessible.description: hint
        Accessible.onPressAction: toggled()
        Keys.onSpacePressed: toggled()
        Keys.onReturnPressed: toggled()

        implicitHeight: ui.embedded ? 36 : 54

        Column {
            anchors.left: parent.left
            anchors.right: switchTrack.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: toggleRow.label
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: !ui.embedded && text.length > 0
                text: toggleRow.hint
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: switchTrack
            x: Math.min(parent.width-width, 360)
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 24
            radius: 12
            color: toggleRow.checked ? ui.accent : ui.inputColor
            border.width: toggleRow.checked ? 0 : 1
            border.color: ui.lineColor

            Rectangle {
                width: 18
                height: 18
                radius: 9
                x: toggleRow.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                color: toggleRow.checked ? "#ffffff" : ui.secondaryText

                Behavior on x { NumberAnimation { duration: ui.palette && ui.palette.config && ui.palette.config.reducedMotion ? 0 : 140; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: togglePointer
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleRow.toggled()
        }
    }

    component SettingSlider: VeloraSettingsSlider {
        theme: ui.palette || sliderPalette
        signal valueRequested(real newValue)
        signal valueCommitted(real newValue)
        onEdited: value => valueRequested(value)
        onFinalized: value => valueCommitted(value)
    }
    QtObject {
        id: sliderPalette
        readonly property var config: null
        readonly property color inverseInk: "white"
        function withAlpha(value, alpha) { return Qt.rgba(value.r,value.g,value.b,alpha) }
        readonly property color textPrimary: ui.primaryText
        readonly property color textSecondary: ui.secondaryText
        readonly property color accent: ui.accent
        readonly property color borderStrong: ui.lineColor
        readonly property color borderSubtle: ui.lineColor
        readonly property string bodyFont: ui.uiFont
    }


    component TextInputRow: Item {
        id: inputRow

        property string label: ""
        property string hint: ""
        property string value: ""
        signal valueSubmitted(string newValue)

        implicitHeight: hint.length > 0 ? 76 : 62

        Column {
            anchors.left: parent.left
            anchors.right: inputBox.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: inputRow.label
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: inputRow.hint.length > 0
                text: inputRow.hint
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: inputBox
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 126
            height: 38
            radius: 9
            color: ui.inputColor
            border.width: 1
            border.color: colorInput.activeFocus ? ui.accent : ui.lineColor

            TextInput {
                id: colorInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: inputRow.value
                color: ui.primaryText
                selectionColor: ui.theme.withAlpha(ui.accent, 0.45)
                selectedTextColor: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                clip: true

                onEditingFinished: inputRow.valueSubmitted(text)
                Keys.onReturnPressed: {
                    inputRow.valueSubmitted(text)
                    focus = false
                }
                Keys.onEnterPressed: {
                    inputRow.valueSubmitted(text)
                    focus = false
                }
            }
        }
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: ui.embedded ? 0 : 76
        visible: !ui.embedded

        UiIcon {
            anchors.left: parent.left
            anchors.leftMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            width: 35
            height: 35
            iconName: "settings"
            lineColor: ui.primaryText
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 68
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: "Configurações"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            Text {
                text: "Personalize sua experiência"
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
            }
        }
    }

    Rectangle {
        id: tabBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        height: ui.embedded ? 0 : 43
        visible: !ui.embedded
        radius: 10
        color: ui.inputColor
        border.width: 1
        border.color: ui.lineColor

        Row {
            anchors.fill: parent
            anchors.margins: 2

            Repeater {
                model: ui.tabs

                Rectangle {
                    id: tabButton
                    required property int index
                    required property string modelData
                    readonly property int tabIndex: index+1

                    width: parent.width / ui.tabs.length
                    height: parent.height
                    radius: 8
                    color: ui.activeTab === tabIndex ? ui.theme.withAlpha(ui.accent, 0.20) : "transparent"
                    border.width: ui.activeTab === tabIndex ? 1 : 0
                    border.color: ui.theme.withAlpha(ui.accent, 0.75)

                    Text {
                        anchors.centerIn: parent
                        text: tabButton.modelData
                        color: ui.activeTab === tabButton.tabIndex ? ui.primaryText : ui.secondaryText
                        font.family: ui.uiFont
                        font.pixelSize: 10
                        font.weight: ui.activeTab === tabButton.tabIndex ? Font.DemiBold : Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ui.activeTab = tabButton.tabIndex
                            scroller.contentY = 0
                        }
                    }
                }
            }
        }
    }

    Flickable {
        id: scroller
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: ui.embedded ? parent.top : tabBar.bottom
        anchors.bottom: footer.top
        anchors.leftMargin: ui.embedded ? 0 : 18
        anchors.rightMargin: ui.embedded ? 0 : 12
        anchors.topMargin: ui.embedded ? 0 : 12
        anchors.bottomMargin: ui.embedded ? 0 : 8
        clip: true
        contentWidth: width
        contentHeight: pageLoader.item ? pageLoader.item.implicitHeight + 8 : 0
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600
        interactive: !ui.embedded

        Loader {
            id: pageLoader
            width: scroller.width - (ui.embedded ? 0 : 6)
            sourceComponent: ui.embedded
                ? (ui.category === "bar" ? sidebarPage
                : ui.category === "wallpapers" ? wallpaperPage
                : ui.category === "desktop" ? framePage
                : ui.category === "media" ? mediaPage
                : null)
                : (ui.activeTab === 1 ? barPage
                : (ui.activeTab === 2 ? menuPage
                : (ui.activeTab === 3 ? wallpaperPage
                : (ui.activeTab === 4 ? framePage
                : (ui.activeTab === 5 ? mediaPage : terminalPage)))))
        }

        Rectangle {
            anchors.right: parent.right
            y: scroller.visibleArea.yPosition * scroller.height
            width: 3
            height: Math.max(24, scroller.visibleArea.heightRatio * scroller.height)
            radius: 2
            color: ui.theme.withAlpha(ui.accent, 0.40)
            visible: scroller.visibleArea.heightRatio < 0.99
        }
    }

    Item {
        id: footer
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 50
        visible: height > 0
        ChoiceButton { x: 18; anchors.verticalCenter: parent.verticalCenter; width: 114
            objectName: "legacy.reset"
            label: ui.resetArmed ? "Confirmar" : "Redefinir"; onClicked: {
                if (!ui.resetArmed) { ui.resetArmed = true; return }
                const tabs = {appearance:0,language:0,bar:1,wallpapers:3,desktop:4,media:ui.mediaSection === "velyrics" ? 6 : 5}
                if (ui.embedded) ui.activeTab = tabs[ui.category] === undefined ? 0 : tabs[ui.category]
                ui.resetCurrentPage(); ui.resetArmed = false
            } }
        Text { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
            visible: !ui.embedded
            text: ui.controller ? ui.controller.noticeText || "Salvamento automático" : ""
            color: ui.secondaryText; font.pixelSize: 11; font.family: ui.uiFont }
    }










    Component {
        id: barPage

        Column {
            spacing: 8

            SectionTitle { label: "APARÊNCIA" }

            SettingSlider {
                width: parent.width
                label: "Tamanho dos ícones"
                hint: "O layout atual usa largura fixa; o valor antigo é preservado."
                minimum: 32
                maximum: 56
                value: ui.theme ? ui.theme.barIconSize : 48
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(Math.round(newValue), ui.theme.barIconOpacity, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                }
            }



            Row {
                width: parent.width
                spacing: (width - 4 * 46) / 3

                Repeater {
                    model: [32, 40, 48, 56]

                    Rectangle {
                        id: iconPreview
                        required property int modelData
                        width: 46
                        height: 42
                        radius: 9
                        color: ui.theme && Math.abs(ui.theme.barIconSize - modelData) < 3 ? ui.theme.withAlpha(ui.accent, 0.20) : ui.inputColor
                        border.width: 1
                        border.color: ui.theme && Math.abs(ui.theme.barIconSize - modelData) < 3 ? ui.accent : ui.lineColor

                        UiIcon {
                            anchors.centerIn: parent
                            width: Math.round(iconPreview.modelData * 0.48)
                            height: width
                            iconName: "discord"
                            lineColor: ui.primaryText
                            opacity: ui.theme ? ui.theme.barIconOpacity : 0.8
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ui.theme) ui.theme.applyBarAppearance(iconPreview.modelData, ui.theme.barIconOpacity, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                        }
                    }
                }
            }

            SettingSlider {
                width: parent.width
                label: "Opacidade dos ícones"
                hint: "Transparência dos ícones da barra"
                minimum: 0.30
                maximum: 1.0
                value: ui.theme ? ui.theme.barIconOpacity : 0.8
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, newValue, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                }
            }

            SettingSlider {
                width: parent.width
                label: "Transparência da barra lateral"
                hint: "Controla somente a superfície da barra lateral"
                minimum: ui.theme ? ui.theme.minOpacityForRole("sidebar") : 0.25
                maximum: 0.98
                value: ui.theme ? ui.theme.barOpacity : 0.88
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { if (ui.theme) ui.theme.applyBarOpacity(newValue) }
            }

            SettingSlider {
                width: parent.width
                label: "Espaçamento entre ícones"
                hint: "Distância vertical entre os ícones"
                minimum: 8
                maximum: 24
                value: ui.theme ? ui.theme.barIconSpacing : 16
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, ui.theme.barIconOpacity, Math.round(newValue), ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                }
            }

            Divider { width: parent.width }
            SectionTitle { label: "POSIÇÃO" }

            Row {
                width: parent.width
                spacing: 7

                Column {
                    width: parent.width - positionButtons.width - 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "Posição da barra"
                        color: ui.primaryText
                        font.family: ui.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "Escolha onde a barra será exibida"
                        color: ui.secondaryText
                        font.family: ui.uiFont
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Row {
                    id: positionButtons
                    width: implicitWidth
                    spacing: 4

                    ChoiceButton {
                        width: 66
                        compact: true
                        label: "Esquerda"
                        active: ui.theme && ui.theme.barPosition === "left"
                        onClicked: {
                            if (ui.theme) {
                                ui.theme.setBarPosition("left")
                            }
                        }
                    }

                    ChoiceButton {
                        width: 60
                        compact: true
                        label: "Direita"
                        active: ui.theme && ui.theme.barPosition === "right"
                        onClicked: {
                            if (ui.theme) {
                                ui.theme.setBarPosition("right")
                            }
                        }
                    }
                }
            }

            Divider { width: parent.width }
            SectionTitle { label: "COMPORTAMENTO" }



            ToggleRow {
                width: parent.width
                label: "Auto-ocultar"
                hint: "Oculta a barra automaticamente"
                checked: ui.theme ? ui.theme.barAutoHideEnabled : false
                onToggled: if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, ui.theme.barIconOpacity, ui.theme.barIconSpacing, !ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
            }

            Divider { width: parent.width }
            SectionTitle { label: "ESTILO" }

            SettingSlider {
                width: parent.width
                label: "Borda arredondada"
                hint: "Arredondamento dos cantos da barra"
                minimum: 0
                maximum: 30
                value: ui.theme ? ui.theme.barCornerRadius : 16
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, ui.theme.barIconOpacity, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, Math.round(newValue), true)
                }
            }


        }
    }

    Component {
        id: menuPage

        Column {
            objectName: "legacy.menu-position"
            spacing: 12

            SectionTitle { label: "CENTRAL DE CONTROLE" }

            Text {
                width: parent.width
                text: "Escolha onde a Central será exibida ao pressionar SUPER+R"
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: 10

                Repeater {
                    model: [
                        { id: "bottom", title: "Inferior central", hint: "Central integrada à borda inferior" },
                        { id: "right", title: "Lateral direita", hint: "Central alta inspirada no Android" }
                    ]

                    Rectangle {
                        id: menuChoice
                        required property var modelData
                        readonly property bool selected: ui.theme && ui.theme.controlCenterPosition === modelData.id

                        width: (parent.width - 10) / 2
                        height: 232
                        radius: 14
                        color: selected ? ui.theme.withAlpha(ui.accent, 0.17) : ui.cardColor
                        border.width: selected ? 2 : 1
                        border.color: selected ? ui.accent : ui.lineColor
                        clip: true

                        Rectangle {
                            id: previewStage
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            height: 150
                            radius: 10
                            color: ui.theme.withAlpha(ui.theme.surfaceBase, 0.38)
                            border.width: 1
                            border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.20)

                            Rectangle {
                                visible: menuChoice.modelData.id === "bottom"
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 9
                                width: parent.width * 0.74
                                height: 62
                                radius: 11
                                color: ui.theme.withAlpha(ui.accent, 0.30)
                                border.width: 1
                                border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.48)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Repeater {
                                        model: 4
                                        Rectangle { width: 18; height: 18; radius: 5; color: ui.theme.withAlpha(index % 2 === 0 ? ui.theme.accentPrimary : ui.theme.accentTertiary, 0.56) }
                                    }
                                }
                            }

                            Rectangle {
                                visible: menuChoice.modelData.id === "right"
                                anchors.right: parent.right
                                anchors.rightMargin: 9
                                anchors.verticalCenter: parent.verticalCenter
                                width: 70
                                height: 128
                                radius: 12
                                color: ui.theme.withAlpha(ui.accent, 0.30)
                                border.width: 1
                                border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.48)

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 7
                                    spacing: 5
                                    Rectangle { width: parent.width; height: 17; radius: 5; color: ui.theme.withAlpha(ui.theme.accentPrimary, 0.48) }
                                    Row {
                                        width: parent.width
                                        spacing: 4
                                        Rectangle { width: (parent.width - 4) / 2; height: 18; radius: 6; color: ui.theme.withAlpha(ui.theme.accentTertiary, 0.48) }
                                        Rectangle { width: (parent.width - 4) / 2; height: 18; radius: 6; color: ui.theme.withAlpha(ui.theme.accentSecondary, 0.48) }
                                    }
                                    Rectangle { width: parent.width; height: 31; radius: 6; color: ui.theme.withAlpha(ui.theme.accentPrimary, 0.38) }
                                    Grid {
                                        columns: 3
                                        spacing: 4
                                        Repeater { model: 6; Rectangle { width: 15; height: 15; radius: 5; color: ui.theme.withAlpha(index % 2 === 0 ? ui.theme.accentSecondary : ui.theme.accentTertiary, 0.46) } }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: previewStage.bottom
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.topMargin: 9
                            text: menuChoice.modelData.title
                            color: ui.primaryText
                            font.family: ui.uiFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.bottomMargin: 10
                            text: menuChoice.modelData.hint
                            color: ui.secondaryText
                            font.family: ui.uiFont
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ui.theme) ui.theme.setControlCenterPosition(menuChoice.modelData.id)
                        }
                    }
                }
            }

            Divider { width: parent.width }

            Text {
                width: parent.width
                text: ui.theme && ui.theme.controlCenterPosition === "right"
                    ? "A Central abre à direita. Som, Wi‑Fi, Tela, Notificações, Bluetooth e Bateria continuam no centro inferior."
                    : "A Central e as seis páginas de sistema permanecem juntas no centro inferior."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }

    Component {
        id: wallpaperPage

        Column {
            spacing: 12

            SectionTitle { label: "SELETOR" }

            Text {
                text: "Posição do seletor de wallpapers"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Row {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Centro"
                    iconName: "wallpaper"
                    active: ui.theme && ui.theme.wallpaperSelectorPosition === "center"
                    onClicked: if (ui.theme) ui.theme.setWallpaperSelectorPosition("center")
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Inferior (clássico)"
                    iconName: "box"
                    active: ui.theme && ui.theme.wallpaperSelectorPosition === "bottom"
                    onClicked: if (ui.theme) ui.theme.setWallpaperSelectorPosition("bottom")
                }
            }

            Text {
                width: parent.width
                text: ui.theme && ui.theme.wallpaperSelectorPosition === "bottom"
                    ? "Usa o seletor antigo abaixo da moldura."
                    : "Usa o accordion de wallpapers no centro."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            ChoiceButton {
                visible: !ui.embedded
                objectName: "legacy.selector-glass"
                width: parent.width
                label: active ? "Vidro do seletor ligado" : "Vidro do seletor desligado"
                active: !!ui.controller && ui.controller.wallpaperSelectorGlassEnabled
                onClicked: if (ui.controller) ui.controller.setWallpaperSelectorGlass(!active)
            }

            Divider { width: parent.width }
            SectionTitle { objectName: "wallpaper.transition"; label: "TRANSIÇÃO" }

            Text {
                text: "Animação ao trocar o wallpaper"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: ui.controller ? ui.controller.wallpaperTransitionOptions() : []

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(220, (parent.width - 7) / 2)
                        label: modelData.label
                        active: ui.controller && ui.controller.wallpaperTransition === modelData.id
                        onClicked: if (ui.controller) ui.controller.setWallpaperTransition(modelData.id)
                    }
                }
            }

            Text {
                text: "Motor para troca live → live"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Row {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Shaders"
                    active: ui.controller && ui.controller.wallpaperLiveTransition === "shader"
                    onClicked: if (ui.controller) ui.controller.setWallpaperLiveTransition("shader")
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Nativa do awww"
                    active: ui.controller && ui.controller.wallpaperLiveTransition === "native"
                    onClicked: if (ui.controller) ui.controller.setWallpaperLiveTransition("native")
                }
            }

            Text {
                width: parent.width
                text: ui.controller && ui.controller.wallpaperLiveTransition === "native"
                    ? "Desativa o shader entre lives. Wallpapers estáticos continuam leves com o awww."
                    : "O shader só é usado de live para live. Wallpapers estáticos usam sempre o awww."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }



            SettingSlider {
                width: parent.width
                label: "Duração"
                hint: "Velocidade da animação de transição"
                minimum: 0.15
                maximum: 3.0
                value: ui.controller ? ui.controller.wallpaperTransitionDuration : 1.0
                valueText: value.toFixed(2) + "s"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setWallpaperTransitionDuration(newValue) }
            }

            SettingSlider {
                width: parent.width
                label: "Atraso da imagem estática"
                hint: "Tempo de preparação antes da troca"
                minimum: 0
                maximum: 0.8
                value: ui.controller ? ui.controller.wallpaperStaticDelay : 0.12
                valueText: value.toFixed(2) + "s"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setWallpaperStaticDelay(newValue) }
            }

            Rectangle {
                width: parent.width
                height: 76
                radius: 11
                color: ui.theme.withAlpha(ui.accent, 0.10)
                border.width: 1
                border.color: ui.theme.withAlpha(ui.accent, 0.30)

                UiIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    iconName: "wallpaper"
                    lineColor: ui.accent
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 54
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: ui.controller && ui.controller.wallpaperLiveTransition === "native"
                            ? "Awww nativo prioriza leveza"
                            : "Shaders somente entre wallpapers live"
                        color: ui.primaryText
                        font.family: ui.uiFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "Imagens estáticas não usam mais mpvpaper nem shader."
                        color: ui.secondaryText
                        font.family: ui.uiFont
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Component {
        id: framePage

        Column {
            spacing: 8

            SectionTitle { label: "MOLDURA" }

            ToggleRow {
                width: parent.width
                label: "Moldura da área de trabalho"
                hint: "Exibe a moldura integrada do Velora"
                checked: ui.theme ? ui.theme.desktopFrameEnabled : true
                onToggled: if (ui.theme) ui.theme.setDesktopFrameEnabled(!ui.theme.desktopFrameEnabled)
            }



            SettingSlider {
                width: parent.width
                label: "Transparência da moldura"
                hint: "Controla a moldura sem sobrepor a barra"
                minimum: ui.theme ? ui.theme.minOpacityForRole("sidebar") : 0.25
                maximum: 0.98
                value: ui.theme ? ui.theme.sidebarOpacity : 0.88
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) {
                    if (ui.theme)
                        ui.theme.applyOpacity(newValue, ui.theme.popupOpacity, ui.theme.cardOpacity)
                }
            }

            ToggleRow {
                width: parent.width
                label: "Painéis unidos à barra"
                hint: "Integra buscas e seletores à moldura"
                checked: ui.theme ? ui.theme.popupAttachedToBar : true
                onToggled: if (ui.theme) ui.theme.setPopupAttachedToBar(!ui.theme.popupAttachedToBar)
            }

            Divider { width: parent.width }
            SectionTitle { label: "VISUALIZADOR" }

            Row {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Wave"
                    iconName: "volume"
                    active: ui.theme && ui.theme.visualizerMode === "wave"
                    onClicked: if (ui.theme) ui.theme.setVisualizerMode("wave")
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Pixels"
                    iconName: "box"
                    active: ui.theme && ui.theme.visualizerMode === "pixels"
                    onClicked: if (ui.theme) ui.theme.setVisualizerMode("pixels")
                }
            }

            SettingSlider {
                width: parent.width
                label: "Intensidade"
                hint: "Força do visualizador de áudio"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.visualizerStrength : 0.46
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { if (ui.theme) ui.theme.setVisualizerStrength(newValue) }
            }
        }
    }


    Component { id: mediaPage; VeloraMediaSettings {
        width: parent ? parent.width : 400
        theme: ui.theme; controller: ui.controller; styleTheme: ui.palette || sliderPalette
        mediaSection: ui.mediaSection
    } }
    Component { id: terminalPage; VeloraMediaSettings {
        width: parent ? parent.width : 400
        theme: ui.theme; controller: ui.controller; styleTheme: ui.palette || sliderPalette
        mediaSection: "velyrics"
    } }

    Component { id: sidebarPage; Column { width: parent ? parent.width : 400; spacing: 12

        Loader { width: parent.width; sourceComponent: barPage }
        Loader { width: parent.width; sourceComponent: menuPage }

    } }


}
