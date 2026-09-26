import QtQuick
import "../lock" as Lock

Item {
    id: root

    required property bool presented
    required property var controller
    required property var config
    required property var theme
    required property var motion
    required property var profileService
    required property var editor
    required property var status
    required property var compositor
    property alias panelItem: panel
    readonly property bool compactLayout: Boolean(parent)
        && (parent.width < 1500 || parent.height < 850)
    property bool drawerOpen: false
    property string selectedProfileId: String(profileService.activeProfileId || "")
    property string deleteArmedId: ""
    property string profileFeedback: ""
    property string profileEditName: ""

    width: Math.min(parent ? parent.width - (compactLayout ? 24 : 64) : 1180,
                    1180)
    height: Math.min(parent ? parent.height - (compactLayout ? 24 : 80) : 780,
                     780)
    opacity: presented ? 1 : 0
    scale: presented ? 1 : 0.965
    visible: opacity > 0.001

    Behavior on opacity {
        NumberAnimation { duration: root.motion.selection; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: root.motion.morph; easing.type: Easing.OutCubic }
    }
    onPresentedChanged: {
        if (!presented)
            drawerOpen = false
    }

    function d(name, fallback) {
        const value = root.controller.draft
        return value && value[name] !== undefined ? value[name] : fallback
    }

    function bar(name, fallback) {
        const value = root.controller.draft
        return value && value.topbar && value.topbar[name] !== undefined
            ? value.topbar[name] : fallback
    }

    function widgetLabel(kind) {
        const labels = { clock: "Relógio", calendar: "Calendário",
            weather: "Clima", media: "Mídia", gallery: "Galeria",
            system: "Sistema" }
        return labels[String(kind)] || String(kind)
    }

    function isVideoPath(value) {
        return /\.(mp4|webm|mkv|mov)(\?.*)?$/i.test(String(value || ""))
    }

    function ensureProfileSelection() {
        if (profileService.profileById(selectedProfileId))
            return
        selectedProfileId = String(profileService.activeProfileId || "")
        if (!profileService.profileById(selectedProfileId)
                && profileService.profiles.length > 0)
            selectedProfileId = String(profileService.profiles[0].id)
        const selected = profileService.profileById(selectedProfileId)
        profileEditName = String(selected && selected.name || "")
        deleteArmedId = ""
    }

    function selectProfile(profileId) {
        selectedProfileId = String(profileId || "")
        deleteArmedId = ""
        profileFeedback = ""
        const selected = profileService.profileById(selectedProfileId)
        profileEditName = String(selected && selected.name || "")
    }

    component ActionButton: Rectangle {
        id: action
        property string label: ""
        property bool primary: false
        property bool selected: false
        property bool destructive: false
        signal triggered
        implicitWidth: Math.max(88, actionText.implicitWidth + 30)
        implicitHeight: 42
        radius: 13
        color: destructive
            ? Qt.rgba(root.theme.danger.r, root.theme.danger.g,
                root.theme.danger.b, pointer.containsMouse ? 0.88 : 0.68)
            : (primary || selected
            ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                root.theme.accent.b, pointer.containsMouse ? 0.92 : 0.76)
            : (pointer.containsMouse ? root.theme.surfaceHover
                : root.theme.surfaceSoft))
        border.width: 1
        border.color: destructive ? root.theme.danger
            : (primary || selected ? root.theme.accentSoft
                : root.theme.borderSubtle)
        opacity: enabled ? 1 : 0.38
        scale: pointer.pressed ? 0.97 : 1
        Behavior on color { ColorAnimation { duration: root.motion.micro } }
        Behavior on scale { NumberAnimation { duration: root.motion.micro } }
        Text {
            id: actionText
            anchors.centerIn: parent
            text: action.label
            color: primary || selected || destructive
                ? "white" : root.theme.textPrimary
            font.family: root.theme.bodyFont
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: pointer
            anchors.fill: parent
            enabled: action.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }

    component SwitchRow: Item {
        id: switchRow
        property string label: ""
        property string description: ""
        property bool checked: false
        signal toggled(bool value)
        width: parent ? parent.width : 420
        height: description.length > 0 ? 58 : 46
        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 7
            text: switchRow.label
            color: root.theme.textPrimary
            font.family: root.theme.bodyFont
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
            text: switchRow.description
            visible: text.length > 0
            color: root.theme.textMuted
            font.family: root.theme.bodyFont
            font.pixelSize: 10
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44; height: 24; radius: 12
            color: switchRow.checked ? root.theme.accent : root.theme.surfaceSoft
            border.width: 1; border.color: root.theme.borderStrong
            Rectangle {
                width: 18; height: 18; radius: 9
                y: 3; x: switchRow.checked ? parent.width - width - 3 : 3
                color: switchRow.checked ? "white" : root.theme.textSecondary
                Behavior on x {
                    NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: switchRow.toggled(!switchRow.checked)
            }
        }
    }

    component ValueSlider: Item {
        id: valueSlider
        property string label: ""
        property real from: 0
        property real to: 1
        property real value: 0
        property string suffix: "%"
        property real multiplier: 100
        signal edited(real value)
        width: parent ? parent.width : 420
        height: 48
        readonly property real ratio: Math.max(0, Math.min(1,
            (value - from) / Math.max(0.0001, to - from)))
        function setFromMouse(mouseX) {
            const next = from + Math.max(0, Math.min(1,
                mouseX / track.width)) * (to - from)
            edited(next)
        }
        Text {
            anchors.left: parent.left; anchors.top: parent.top
            text: valueSlider.label
            color: root.theme.textSecondary
            font.family: root.theme.bodyFont; font.pixelSize: 11
        }
        Text {
            anchors.right: parent.right; anchors.top: parent.top
            text: Math.round(valueSlider.value * valueSlider.multiplier)
                + valueSlider.suffix
            color: root.theme.textPrimary
            font.family: root.theme.bodyFont; font.pixelSize: 11
            font.weight: Font.DemiBold
        }
        Rectangle {
            id: track
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.bottomMargin: 9
            height: 5; radius: 3; color: root.theme.surfaceSoft
            Rectangle {
                width: parent.width * valueSlider.ratio
                height: parent.height; radius: parent.radius
                color: root.theme.accent
            }
            Rectangle {
                x: parent.width * valueSlider.ratio - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 14; height: 14; radius: 7
                color: root.theme.accentSoft
                border.width: 2; border.color: root.theme.surfaceRaised
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) { valueSlider.setFromMouse(mouse.x - 10) }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        valueSlider.setFromMouse(mouse.x - 10)
                }
            }
        }
    }

    component SectionCard: Rectangle {
        default property alias content: body.data
        property string title: ""
        width: parent ? parent.width : 420
        height: body.childrenRect.height + 58
        radius: 18
        color: root.theme.surfaceSoft
        border.width: 1
        border.color: root.theme.borderSubtle
        Text {
            x: 18; y: 15
            text: parent.title
            color: root.theme.textPrimary
            font.family: root.theme.bodyFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Column {
            id: body
            x: 18; y: 45; width: parent.width - 36
            spacing: 7
        }
    }

    component PageTitle: Item {
        property string title: ""
        property string subtitle: ""
        width: parent ? parent.width : 600
        height: 65
        Text {
            text: parent.title
            color: root.theme.textPrimary
            font.family: root.theme.bodyFont
            font.pixelSize: 23
            font.weight: Font.DemiBold
        }
        Text {
            y: 32; text: parent.subtitle
            color: root.theme.textSecondary
            font.family: root.theme.bodyFont
            font.pixelSize: 11
        }
    }

    Lock.GlassPanel {
        id: panel
        anchors.fill: parent
        radius: 30
        nativeOptics: true
        surfaceColor: root.theme.surfaceRaised
        borderColor: root.theme.borderStrong
        shadowColor: root.theme.shadow

        Rectangle {
            id: titleBar
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: 72; color: "transparent"
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1; color: root.theme.borderSubtle
            }
            Rectangle {
                x: 24; anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34; radius: 17
                color: root.theme.accentMuted
                border.width: 2; border.color: root.theme.accent
                Text { anchors.centerIn: parent; text: "H"; color: root.theme.accentSoft; font.pixelSize: 16; font.weight: Font.Bold }
            }
            Text {
                x: root.compactLayout ? 124 : 72
                anchors.verticalCenter: parent.verticalCenter
                text: "Configurações"
                color: root.theme.textPrimary
                font.family: root.theme.bodyFont; font.pixelSize: 18; font.weight: Font.DemiBold
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: 380; height: 38; radius: 12
                visible: !root.compactLayout
                color: root.theme.surfaceSoft
                border.width: 1; border.color: root.theme.borderSubtle
                Text { x: 15; anchors.verticalCenter: parent.verticalCenter; text: "⌕  Buscar configurações"; color: root.theme.textMuted; font.family: root.theme.bodyFont; font.pixelSize: 11 }
            }
            ActionButton {
                anchors.right: parent.right; anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 42; label: "×"
                onTriggered: root.controller.hide()
            }
            ActionButton {
                x: 70
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 42; label: "☰"
                visible: root.compactLayout
                selected: root.drawerOpen
                onTriggered: root.drawerOpen = !root.drawerOpen
            }
        }

        MouseArea {
            anchors.fill: parent
            z: 11
            visible: root.compactLayout && root.drawerOpen
            enabled: visible
            onClicked: root.drawerOpen = false
        }

        Rectangle {
            id: sideBar
            x: root.compactLayout ? (root.drawerOpen ? 0 : -width) : 0
            anchors.top: titleBar.bottom; anchors.bottom: parent.bottom
            width: 260; color: Qt.rgba(root.theme.surface.r,
                root.theme.surface.g, root.theme.surface.b, 0.42)
            z: 12
            Behavior on x {
                NumberAnimation {
                    duration: root.motion.reduced ? 0 : root.motion.selection
                    easing.type: Easing.OutCubic
                }
            }
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.theme.borderSubtle }
            Column {
                x: 14; y: 22; width: parent.width - 28; spacing: 6
                Repeater {
                    model: [
                        ["appearance", "▣", "Aparência"],
                        ["wallpaper", "▧", "Wallpaper"],
                        ["images", "▥", "Imagens"],
                        ["widgets", "▦", "Widgets"],
                        ["bar", "▤", "Barra"],
                        ["motion", "✣", "Movimento"],
                        ["system", "▥", "Sistema"],
                        ["profiles", "♙", "Perfis"],
                        ["about", "ⓘ", "Sobre"]
                    ]
                    Rectangle {
                        required property var modelData
                        width: parent.width; height: 48; radius: 13
                        color: root.controller.page === modelData[0]
                            ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                                root.theme.accent.b, 0.66)
                            : (navPointer.containsMouse ? root.theme.surfaceSoft : "transparent")
                        Text { x: 16; anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: root.controller.page === modelData[0] ? "white" : root.theme.textSecondary; font.pixelSize: 17 }
                        Text { x: 54; anchors.verticalCenter: parent.verticalCenter; text: modelData[2]; color: root.controller.page === modelData[0] ? "white" : root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 13; font.weight: Font.Medium }
                        MouseArea {
                            id: navPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.controller.page = modelData[0]
                                root.drawerOpen = false
                            }
                        }
                    }
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 14; anchors.rightMargin: 14
                anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                height: 76; radius: 16
                color: root.theme.surfaceSoft
                border.width: 1; border.color: root.theme.borderSubtle
                Lock.RoundedImage { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 46; height: 46; radius: 23; source: root.config.avatarPath }
                Text { x: 70; y: 17; width: 140; text: root.config.profileName; elide: Text.ElideRight; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 13; font.weight: Font.DemiBold }
                Text { x: 70; y: 39; text: "Perfil " + root.config.visualStyle; color: root.theme.textMuted; font.family: root.theme.bodyFont; font.pixelSize: 10 }
            }
        }

        Item {
            id: pageArea
            anchors.left: root.compactLayout ? parent.left : sideBar.right
            anchors.right: parent.right
            anchors.top: titleBar.bottom; anchors.bottom: footer.top
            anchors.margins: 26
            Loader {
                anchors.fill: parent
                sourceComponent: root.controller.page === "appearance" ? appearancePage
                    : (root.controller.page === "wallpaper" ? wallpaperPage
                    : (root.controller.page === "images" ? imagesPage
                    : (root.controller.page === "widgets" ? widgetsPage
                    : (root.controller.page === "bar" ? barPage
                    : (root.controller.page === "motion" ? motionPage
                    : (root.controller.page === "profiles" ? profilesPage
                    : (root.controller.page === "system" ? systemPage : aboutPage)))))))
            }
        }

        Rectangle {
            id: footer
            anchors.left: root.compactLayout ? parent.left : sideBar.right
            anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 72; color: "transparent"
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.theme.borderSubtle }
            Text {
                anchors.right: reset.left; anchors.rightMargin: 22; anchors.verticalCenter: parent.verticalCenter
                text: root.controller.savedPulse ? "✓ Alterações salvas"
                    : (root.controller.dirty ? "Alterações não aplicadas" : "Sem alterações")
                color: root.controller.dirty ? root.theme.warning : root.theme.success
                font.family: root.theme.bodyFont; font.pixelSize: 11
            }
            ActionButton {
                id: reset
                anchors.right: applyButton.left; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                label: "Restaurar padrões"
                onTriggered: root.controller.restoreDefaults()
            }
            ActionButton {
                id: applyButton
                anchors.right: parent.right; anchors.rightMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                label: "Aplicar"; primary: true
                enabled: root.controller.dirty
                onTriggered: root.controller.apply()
            }
        }
    }

    Component {
        id: appearancePage
        Item {
            PageTitle { id: appearanceTitle; title: "Aparência"; subtitle: "Defina a linguagem visual do Velora" }
            Flickable {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: appearanceTitle.bottom; anchors.bottom: parent.bottom
                id: appearanceScroll
                clip: true
                contentWidth: width
                contentHeight: appearanceLayout.height
                boundsBehavior: Flickable.StopAtBounds
                Item {
                    id: appearanceLayout
                    width: appearanceScroll.width
                    height: root.compactLayout
                        ? appearanceColumn.height + appearancePreview.height + 18
                        : Math.max(appearanceColumn.height, appearancePreview.height)
                    Column {
                        id: appearanceColumn
                        width: root.compactLayout ? parent.width
                            : Math.floor((parent.width - 18) * 0.60)
                        spacing: 12
                        SectionCard {
                            title: "Estilo visual"
                            Row {
                                spacing: 8
                                Repeater {
                                    model: [["editorial", "Editorial"], ["classic", "Clássico"], ["minimal", "Minimal"]]
                                    ActionButton {
                                        required property var modelData
                                        implicitWidth: 122; label: modelData[1]
                                        selected: root.d("visualStyle", "editorial") === modelData[0]
                                        onTriggered: root.controller.update("visualStyle", modelData[0])
                                    }
                                }
                            }
                        }
                        SectionCard {
                            title: "Material"
                            Row {
                                spacing: 8
                                Repeater {
                                    model: [["glass", "Vidro"], ["solid", "Sólido"], ["adaptive", "Adaptativo"]]
                                    ActionButton {
                                        required property var modelData
                                        implicitWidth: 122; label: modelData[1]
                                        selected: root.d("material", "glass") === modelData[0]
                                        onTriggered: root.controller.update("material", modelData[0])
                                    }
                                }
                            }
                            ValueSlider { label: "Transparência"; value: root.d("surfaceOpacity", 0.82); from: 0.45; to: 1; onEdited: function(value) { root.controller.update("surfaceOpacity", value) } }
                            ValueSlider { label: "Desfoque"; value: root.d("blurStrength", 0.55); suffix: "%"; onEdited: function(value) { root.controller.update("blurStrength", value) } }
                            ValueSlider { label: "Contraste"; value: root.d("contrast", 1.08); from: 0.8; to: 1.35; multiplier: 100; onEdited: function(value) { root.controller.update("contrast", value) } }
                            ValueSlider { label: "Reflexo"; value: root.d("reflection", 0.35); onEdited: function(value) { root.controller.update("reflection", value) } }
                        }
                        SectionCard {
                            title: "Cor de destaque"
                            Row {
                                spacing: 12
                                Repeater {
                                    model: ["#c8788f", "#8d6bd1", "#5e91e8", "#63b6ca", "#69bba5", "#e2b75e", "#e58e5e", "#dc6774"]
                                    Rectangle {
                                        required property string modelData
                                        width: 30; height: 30; radius: 15; color: modelData
                                        border.width: root.d("accentColor", "#c8788f") === modelData ? 3 : 1
                                        border.color: root.d("accentColor", "#c8788f") === modelData ? "white" : root.theme.borderStrong
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.controller.update("accentMode", "custom"); root.controller.update("accentColor", modelData) } }
                                    }
                                }
                            }
                            SwitchRow { label: "Usar cor do wallpaper"; checked: root.d("accentMode", "wallpaper") === "wallpaper"; onToggled: function(value) { root.controller.update("accentMode", value ? "wallpaper" : "custom") } }
                        }
                    }
                    Column {
                        id: appearancePreview
                        x: root.compactLayout ? 0 : appearanceColumn.width + 18
                        y: root.compactLayout ? appearanceColumn.height + 18 : 0
                        width: root.compactLayout ? parent.width
                            : parent.width - appearanceColumn.width - 18
                        spacing: 12
                        SectionCard {
                            title: "Prévia ao vivo"
                            height: 340
                            Rectangle {
                                width: parent.width; height: 260; radius: 16
                                color: Qt.rgba(0.10, 0.08, 0.10, 0.72)
                                border.width: 1; border.color: root.theme.borderSubtle
                                Rectangle { x: 14; y: 14; width: parent.width - 28; height: 28; radius: 14; color: root.theme.surfaceRaised; border.width: 1; border.color: root.theme.borderStrong }
                                Rectangle { x: 18; y: 60; width: 120; height: 140; radius: root.theme.cardRadius * 0.5; color: root.theme.surface; border.width: 1; border.color: root.theme.borderStrong }
                                Rectangle { anchors.right: parent.right; anchors.rightMargin: 18; y: 60; width: 140; height: 62; radius: root.theme.cardRadius * 0.5; color: root.theme.surface; border.width: 1; border.color: root.theme.borderStrong
                                    Text { anchors.centerIn: parent; text: "18:02"; color: root.theme.textPrimary; font.family: root.theme.displayFont; font.pixelSize: 24; font.weight: Font.DemiBold }
                                }
                                Rectangle { anchors.right: parent.right; anchors.rightMargin: 18; y: 134; width: 140; height: 66; radius: root.theme.cardRadius * 0.5; color: root.theme.surface; border.width: 1; border.color: root.theme.borderStrong
                                    Text { anchors.centerIn: parent; text: "13°C  ☀"; color: root.theme.textPrimary; font.pixelSize: 18 }
                                }
                                Rectangle { x: 70; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; width: parent.width - 140; height: 42; radius: 14; color: root.theme.surfaceRaised; border.width: 1; border.color: root.theme.borderStrong
                                    Text { anchors.centerIn: parent; text: "♫  Nenhuma mídia"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                                }
                            }
                            Row {
                                spacing: 8
                                ActionButton { implicitWidth: Math.min(150, (appearancePreview.width - 8) / 2); label: "Claro"; selected: root.d("colorScheme", "dark") === "light"; onTriggered: root.controller.update("colorScheme", "light") }
                                ActionButton { implicitWidth: Math.min(150, (appearancePreview.width - 8) / 2); label: "Escuro"; selected: root.d("colorScheme", "dark") === "dark"; onTriggered: root.controller.update("colorScheme", "dark") }
                            }
                        }
                        SectionCard {
                            title: "Legibilidade"
                            SwitchRow { label: "Contraste inteligente"; checked: root.d("intelligentContrast", true); onToggled: function(value) { root.controller.update("intelligentContrast", value) } }
                            SwitchRow { label: "Reduzir transparência"; checked: root.d("reduceTransparency", false); onToggled: function(value) { root.controller.update("reduceTransparency", value) } }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: wallpaperPage
        Flickable {
            clip: true
            contentWidth: width
            contentHeight: wallpaperContent.height
            boundsBehavior: Flickable.StopAtBounds
        Column {
            id: wallpaperContent
            width: parent.width
            spacing: 14
            PageTitle { title: "Wallpaper"; subtitle: "Imagem ou vídeo associado ao perfil ativo" }
            SectionCard {
                title: "Wallpaper do perfil"
                Rectangle {
                    width: parent.width; height: 250; radius: 18
                    color: root.theme.surfaceSoft
                    border.width: 1; border.color: root.theme.borderSubtle
                    clip: true
                    Lock.RoundedImage {
                        anchors.fill: parent
                        source: root.profileService.draftWallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        visible: !root.isVideoPath(
                            root.profileService.draftWallpaperPath)
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.isVideoPath(
                            root.profileService.draftWallpaperPath)
                        text: "▶  Wallpaper em vídeo"
                        color: root.theme.textPrimary
                        font.family: root.theme.bodyFont
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                }
                Text { width: parent.width; text: root.profileService.draftWallpaperPath || "O wallpaper atual será preservado"; elide: Text.ElideMiddle; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
                Row { spacing: 10
                    ActionButton { label: "Escolher arquivo"; primary: true; onTriggered: root.controller.chooseWallpaper() }
                    ActionButton { label: "Editar composição"; onTriggered: root.controller.openEditor("desktop") }
                }
            }
            SectionCard {
                title: "Compatibilidade"
                Text { width: parent.width; wrapMode: Text.WordWrap; text: "PNG, JPG, WebP, GIF, MP4, WebM, MKV e MOV. O wallpaper é copiado para o perfil quando as alterações são aplicadas."; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
            }
        }
        }
    }

    Component {
        id: imagesPage
        Flickable {
            clip: true
            contentWidth: width
            contentHeight: imageSettings.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: imageSettings
                width: parent.width
                spacing: 14

                PageTitle {
                    title: "Imagens"
                    subtitle: "Personagem principal e as três fotos do módulo à direita"
                }

                SectionCard {
                    title: "Personagem principal"
                    Row {
                        width: parent.width
                        spacing: 18
                        Rectangle {
                            width: 132; height: 148; radius: 18
                            color: root.theme.surfaceSoft
                            border.width: 1
                            border.color: root.theme.borderSubtle
                            clip: true
                            Image {
                                anchors.fill: parent
                                anchors.margins: 7
                                source: root.config.characterPath
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                            }
                        }
                        Column {
                            width: parent.width - 150
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            Text {
                                width: parent.width
                                text: "PNG transparente, WebP/GIF animado ou vídeo. Esta é a figura usada na composição da Lock e do Desktop."
                                wrapMode: Text.WordWrap
                                color: root.theme.textSecondary
                                font.family: root.theme.bodyFont
                                font.pixelSize: 11
                            }
                            ActionButton {
                                label: "Trocar personagem"
                                primary: true
                                onTriggered: root.controller.chooseImage(0)
                            }
                        }
                    }
                }

                SectionCard {
                    title: "Fotos da direita"
                    Row {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: 3
                            Item {
                                required property int index
                                readonly property int assetIndex:
                                    root.config.galleryOrder[index] === undefined
                                        ? index : root.config.galleryOrder[index]
                                readonly property string slotName:
                                    ["Esquerda", "Centro", "Direita"][index]
                                width: (parent.width - 20) / 3
                                height: 184

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    height: 116; radius: 16
                                    color: root.theme.surfaceSoft
                                    border.width: 1
                                    border.color: root.theme.borderSubtle
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        source: root.config.galleryPaths[
                                            parent.parent.assetIndex] || ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                    }
                                }
                                Text {
                                    y: 122
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Foto " + parent.slotName
                                    color: root.theme.textSecondary
                                    font.family: root.theme.bodyFont
                                    font.pixelSize: 10
                                }
                                ActionButton {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    implicitHeight: 38
                                    label: "Trocar"
                                    onTriggered: root.controller.chooseImage(
                                        parent.assetIndex + 1)
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "Ao escolher um arquivo, a composição e o perfil ativo são atualizados automaticamente."
                    wrapMode: Text.WordWrap
                    color: root.theme.textMuted
                    font.family: root.theme.bodyFont
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: widgetsPage
        Column {
            spacing: 12
            PageTitle { title: "Widgets"; subtitle: "Escolha onde cada módulo aparece" }
            SectionCard {
                title: "Módulos compartilhados"
                Repeater {
                    model: root.config.sharedWidgets
                    Item {
                        required property var modelData
                        width: parent.width; height: 48
                        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: root.widgetLabel(modelData.kind); color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 13 }
                        Row { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            ActionButton { label: "Desktop"; selected: Boolean(modelData.desktopEnabled); onTriggered: root.config.setSharedWidgetVisibility(modelData.kind, !modelData.desktopEnabled, modelData.lockEnabled) }
                            ActionButton { label: "Lock"; selected: Boolean(modelData.lockEnabled); onTriggered: root.config.setSharedWidgetVisibility(modelData.kind, modelData.desktopEnabled, !modelData.lockEnabled) }
                        }
                    }
                }
            }
            Row { spacing: 10
                ActionButton { label: "Editar Desktop"; primary: true; onTriggered: root.controller.openEditor("desktop") }
                ActionButton { label: "Editar Lockscreen"; onTriggered: root.controller.openEditor("lock") }
            }
        }
    }

    Component {
        id: barPage
        Column {
            spacing: 12
            PageTitle { title: "Barra"; subtitle: "Faixa fina e contínua inspirada na referência" }
            SectionCard {
                title: "Visual"
                Row {
                    spacing: 8
                    ActionButton {
                        label: "end4 — primeira cena"
                        selected: root.bar("variant", "velora") === "end4-first"
                        onTriggered: root.controller.updateTopbar(
                            "variant", "end4-first")
                    }
                    ActionButton {
                        label: "Velora"
                        selected: root.bar("variant", "velora") === "velora"
                        onTriggered: root.controller.updateTopbar(
                            "variant", "velora")
                    }
                }
            }
            SectionCard {
                title: "Geometria"
                ValueSlider { label: "Altura"; from: 36; to: 52; value: root.bar("height", 40); multiplier: 1; suffix: " px"; onEdited: function(value) { root.controller.updateTopbar("height", value) } }
                ValueSlider { label: "Escala"; from: 0.75; to: 1.35; value: root.bar("scale", 1); multiplier: 100; suffix: "%"; onEdited: function(value) { root.controller.updateTopbar("scale", value) } }
                ValueSlider { label: "Espaço entre módulos"; from: 0; to: 12; value: root.bar("gap", 4); multiplier: 1; suffix: " px"; onEdited: function(value) { root.controller.updateTopbar("gap", value) } }
                ValueSlider { label: "Margem lateral"; from: 6; to: 20; value: root.bar("margin", 8); multiplier: 1; suffix: " px"; onEdited: function(value) { root.controller.updateTopbar("margin", value) } }
            }
            ActionButton { label: "Editar itens e ordem"; primary: true; onTriggered: root.controller.openEditor("desktop") }
        }
    }

    Component {
        id: motionPage
        Column {
            spacing: 12
            PageTitle { title: "Movimento"; subtitle: "Ritmo consistente para toda a interface" }
            SectionCard {
                title: "Preset de animação"
                Row { spacing: 8
                    Repeater {
                        model: [["calm", "Calmo"], ["balanced", "Equilibrado"], ["snappy", "Ágil"]]
                        ActionButton { required property var modelData; implicitWidth: 140; label: modelData[1]; selected: root.d("motionPreset", "balanced") === modelData[0]; onTriggered: root.controller.update("motionPreset", modelData[0]) }
                    }
                }
                SwitchRow { label: "Reduzir movimento"; description: "Remove deslocamentos e transições longas"; checked: root.d("reducedMotion", false); onToggled: function(value) { root.controller.update("reducedMotion", value) } }
            }
            SectionCard {
                title: "Idioma e região"
                Row {
                    spacing: 8
                    Repeater {
                        model: [["system", "Sistema"], ["pt_BR", "Português"], ["en_US", "English"]]
                        ActionButton {
                            required property var modelData
                            implicitWidth: 128
                            label: modelData[1]
                            selected: root.d("locale", "system") === modelData[0]
                            onTriggered: root.controller.update(
                                "locale", modelData[0])
                        }
                    }
                }
                Text {
                    width: parent.width
                    text: "Define idioma e formato regional de datas e horários."
                    wrapMode: Text.WordWrap
                    color: root.theme.textMuted
                    font.family: root.theme.bodyFont
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: profilesPage
        Flickable {
            clip: true
            contentWidth: width
            contentHeight: profilesContent.height
            boundsBehavior: Flickable.StopAtBounds
        Column {
            id: profilesContent
            width: parent.width
            spacing: 12
            PageTitle { title: "Perfis"; subtitle: "Composições completas, sem alterar seus perfis originais" }
            SectionCard {
                title: "Perfis disponíveis"
                Item {
                    width: parent.width
                    height: Math.min(250, Math.max(52,
                        root.profileService.profiles.length * 54))
                    ListView {
                        id: profileList
                        anchors.fill: parent
                        spacing: 6
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.profileService.profiles
                        delegate: Rectangle {
                            id: profileRow
                            required property var modelData
                            width: profileList.width
                            height: 48
                            radius: 13
                            readonly property bool activeProfile:
                                String(modelData.id) === root.profileService.activeProfileId
                            readonly property bool selectedProfile:
                                String(modelData.id) === root.selectedProfileId
                            color: selectedProfile ? root.theme.accentMuted
                                : (rowPointer.containsMouse
                                    ? root.theme.surfaceHover : "transparent")
                            border.width: 1
                            border.color: selectedProfile
                                ? root.theme.accentSoft : root.theme.borderSubtle

                            Lock.RoundedImage {
                                x: 5
                                anchors.verticalCenter: parent.verticalCenter
                                width: 38; height: 38; radius: 11
                                source: String(profileRow.modelData.preview || "")
                            }
                            Text {
                                x: 54
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - applyProfileButton.width - 80
                                elide: Text.ElideRight
                                text: String(profileRow.modelData.name
                                    || profileRow.modelData.id)
                                    + (profileRow.activeProfile ? "  •  Ativo" : "")
                                color: root.theme.textPrimary
                                font.family: root.theme.bodyFont
                                font.pixelSize: 13
                                font.weight: profileRow.activeProfile
                                    ? Font.Bold : Font.Normal
                            }
                            ActionButton {
                                id: applyProfileButton
                                z: 2
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: 38
                                label: profileRow.activeProfile ? "Aplicado" : "Aplicar"
                                selected: profileRow.activeProfile
                                onTriggered: {
                                    root.selectProfile(profileRow.modelData.id)
                                    root.profileService.applyProfile(
                                        profileRow.modelData.id, true)
                                }
                            }
                            MouseArea {
                                id: rowPointer
                                z: 1
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectProfile(
                                    profileRow.modelData.id)
                            }
                        }
                    }
                }
            }
            Row {
                spacing: 10
                Rectangle {
                    width: 280; height: 42; radius: 13
                    color: root.theme.surfaceSoft
                    border.width: 1; border.color: root.theme.borderSubtle
                    TextInput {
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.profileEditName
                        selectByMouse: true
                        color: root.theme.textPrimary
                        selectionColor: root.theme.accent
                        selectedTextColor: "white"
                        font.family: root.theme.bodyFont
                        font.pixelSize: 12
                        onTextEdited: root.profileEditName = text
                    }
                }
                ActionButton {
                    label: "Renomear selecionado"
                    enabled: !root.profileService.busy
                        && root.selectedProfileId.length > 0
                        && root.profileEditName.trim().length > 0
                    onTriggered: root.profileService.renameProfile(
                        root.selectedProfileId, root.profileEditName)
                }
            }
            Row {
                spacing: 10
                Rectangle {
                    width: 280; height: 42; radius: 13
                    color: root.theme.surfaceSoft
                    border.width: 1; border.color: root.theme.borderSubtle
                    TextInput {
                        id: newProfileName
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        text: "Novo perfil"
                        selectByMouse: true
                        color: root.theme.textPrimary
                        selectionColor: root.theme.accent
                        selectedTextColor: "white"
                        font.family: root.theme.bodyFont
                        font.pixelSize: 12
                    }
                }
                ActionButton {
                    label: "Salvar como novo"
                    primary: true
                    enabled: !root.profileService.busy
                    onTriggered: root.profileService.createProfile(
                        newProfileName.text)
                }
            }
            Row {
                spacing: 10
                ActionButton {
                    label: "Exportar .helixpack"
                    enabled: !root.profileService.busy
                        && root.selectedProfileId.length > 0
                    onTriggered: root.controller.exportPackage(
                        root.selectedProfileId)
                }
                ActionButton {
                    label: "Importar .helixpack"
                    enabled: !root.profileService.busy
                    onTriggered: root.controller.importPackage()
                }
            }
            Row {
                spacing: 10
                ActionButton {
                    label: "Atualizar perfil ativo"
                    enabled: !root.profileService.busy
                        && root.profileService.activeProfileId.length > 0
                    onTriggered: root.profileService.updateProfile(
                        root.profileService.activeProfileId)
                }
                ActionButton {
                    destructive: true
                    label: root.deleteArmedId === root.selectedProfileId
                        ? "Confirmar exclusão" : "Excluir selecionado"
                    enabled: !root.profileService.busy
                        && root.profileService.profiles.length > 1
                        && root.selectedProfileId.length > 0
                    onTriggered: {
                        if (root.deleteArmedId === root.selectedProfileId) {
                            root.profileService.deleteProfile(
                                root.selectedProfileId)
                            root.deleteArmedId = ""
                        } else {
                            root.deleteArmedId = root.selectedProfileId
                            root.profileFeedback = "Clique novamente para confirmar."
                        }
                    }
                }
            }
            Text {
                width: parent.width
                visible: root.profileService.busy
                    || root.profileService.error.length > 0
                    || root.profileFeedback.length > 0
                text: root.profileService.busy ? "Processando perfil…"
                    : (root.profileService.error.length > 0
                        ? root.profileService.error : root.profileFeedback)
                color: root.profileService.error.length > 0
                    ? root.theme.danger : root.theme.textSecondary
                font.family: root.theme.bodyFont
                font.pixelSize: 11
            }
        }
        }
    }

    Component {
        id: systemPage
        Column {
            spacing: 12
            PageTitle { title: "Sistema"; subtitle: "Estado real observado pelo shell" }
            SectionCard {
                title: "Desempenho"
                Text { text: "CPU  " + Math.round(root.status.cpuPercent) + "%"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 14 }
                Text { text: "RAM  " + Math.round(root.status.ramPercent) + "%"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 14 }
                Text { text: "Armazenamento  " + Math.round(root.status.storagePercent) + "%"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 14 }
            }
            SectionCard {
                title: "Conectividade e áudio"
                Text { text: "Rede: " + (root.status.wifiName || "sem conexão") + "   •   Volume: " + root.status.volumePercent + "%"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12 }
                Text { text: "Tráfego: ↓ " + root.status.networkDownKbps.toFixed(0) + " KB/s   ↑ " + root.status.networkUpKbps.toFixed(0) + " KB/s"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12 }
            }
            SectionCard {
                title: "Energia e compositor"
                Text { text: root.status.hasBattery ? ("Bateria: " + root.status.batteryPercent + "%" + (root.status.batteryCharging ? " • carregando" : "")) : "Bateria: não detectada"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12 }
                Text { text: "Compositor: " + root.compositor.backend + "   •   Monitor: " + (root.compositor.focusedMonitorName || "—"); color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12 }
            }
        }
    }

    Component {
        id: aboutPage
        Column {
            spacing: 12
            PageTitle { title: "Sobre"; subtitle: "Velora Shell Editorial Glass" }
            SectionCard {
                title: "Velora Shell"
                Text { text: "Versão 0.7.0-preview"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { text: "Schema 7   •   plugin óptico 0.13.0   •   IPC v2"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: "Interface Quickshell para Hyprland. Esta versão inclui schema 7, estilos Editorial, Clássico e Minimal, editor visual separado e configurações com prévia ao vivo."; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
                Text { text: "Configuração: " + root.config.configPath; color: root.theme.textMuted; font.family: root.theme.bodyFont; font.pixelSize: 10; elide: Text.ElideMiddle; width: parent.width }
                Text { text: "Perfis: " + root.profileService.profilesRoot; color: root.theme.textMuted; font.family: root.theme.bodyFont; font.pixelSize: 10; elide: Text.ElideMiddle; width: parent.width }
            }
        }
    }

    Connections {
        target: root.profileService

        function onProfilesChangedExternally() {
            root.ensureProfileSelection()
        }

        function onProfileApplied(profileId) {
            root.selectProfile(profileId)
        }

        function onOperationFinished(operation, ok, message) {
            const successMessages = {
                create: "Perfil criado e aplicado.",
                update: "Perfil atualizado.",
                rename: "Perfil renomeado.",
                delete: "Perfil excluído.",
                import: "Perfil importado.",
                export: "Pacote exportado."
            }
            root.profileFeedback = ok
                ? String(successMessages[String(operation)] || "Operação concluída.")
                : String(message || root.profileService.error)
            root.deleteArmedId = ""
        }
    }

    Component.onCompleted: Qt.callLater(ensureProfileSelection)
}
