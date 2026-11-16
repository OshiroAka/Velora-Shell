import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../components" as Components

Item {
    id: root

    required property var config
    required property var controller
    required property var editor
    required property var theme
    signal requestClose
    signal revealSetting(string id)
    signal inlineToolOpened(var item)
    property string pendingSystemTool: ""

    property string page: "wallpapers"
    property string pendingColorRole: ""
    property color pendingColorValue: "#c8788f"
    onPageChanged: pendingColorRole = ""
    readonly property color ink: theme.textPrimary
    readonly property color mutedInk: theme.textSecondary
    readonly property color accent: theme.accent
    readonly property string barAvatarPath: controller.shell
        && controller.shell.unifiedTheme
        ? String(controller.shell.unifiedTheme.profileImagePath || "")
        : String(config.avatarPath || "")
    readonly property var manualColorTargets: [
        { role: "accent", label: "Destaque" },
        { role: "bar", label: "Barra" },
        { role: "bubbles", label: "Balões" },
        { role: "icons", label: "Ícones" },
        { role: "widgets", label: "Widgets" },
        { role: "text", label: "Texto" },
        { role: "panels", label: "Painéis" }
    ]

    // The host owns the initial/page fade; section changes still animate locally.
    property bool animatePageEntrance: true
    property var motion: null
    property var integrations: controller.integrations || null
    property string mediaSection: "playback"
    property string section: "main"
    onSectionChanged: Qt.callLater(function() {
        if (root.motion && !root.motion.reduced) sectionEntrance.restart()
    })
    readonly property var legacyTheme: controller.shell ? controller.shell.unifiedTheme : null
    readonly property var wallpaper: controller.wallpaperService || null
    implicitHeight: pageLoader.y + (pageLoader.item ? pageLoader.item.implicitHeight : 0)

    function prepareResult(result) {
        return pageLoader.item && typeof pageLoader.item.prepareResult === "function"
            ? pageLoader.item.prepareResult(result) : false
    }
    component SettingSwitch: Components.VeloraSettingsSwitch { theme: root.theme; motion: root.motion }
    component ContextLink: Components.VeloraSettingsLink { theme: root.theme }

    function rgbHex(value) {
        const part = function(channel) {
            const text = Math.round(Math.max(0, Math.min(1, channel)) * 255)
                .toString(16)
            return text.length < 2 ? "0" + text : text
        }
        return "#" + part(value.r) + part(value.g) + part(value.b)
    }

    function openManualColor(role, value) {
        pendingColorValue = value
        pendingColorRole = String(role)
    }

    Timer {
        id: manualPickerReveal
        property var target: null
        interval: 35; repeat: false
        onTriggered: if (target) root.inlineToolOpened(target)
    }

    component ActionButton: Rectangle {
        id: button
        property string label: ""
        property bool primary: false
        property bool selected: false
        signal triggered
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: label
        Keys.onSpacePressed: triggered()
        Keys.onReturnPressed: triggered()
        implicitWidth: Math.max(94, textItem.implicitWidth + 28)
        implicitHeight: 38
        radius: 13
        opacity: enabled ? 1 : 0.46
        color: primary || selected
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b,
                      pointer.containsMouse ? 0.46 : 0.28)
            : Qt.rgba(1, 1, 1, pointer.containsMouse ? 0.14 : 0.055)
        border.width: 1
        border.color: primary || selected || activeFocus ? root.theme.accentSoft
            : Qt.rgba(1, 1, 1, 0.13)
        Text {
            id: textItem; anchors.centerIn: parent; text: button.label
            color: root.ink; font.family: root.theme.bodyFont
            font.pixelSize: 12; font.weight: Font.DemiBold
        }
        MouseArea {
            id: pointer; anchors.fill: parent; hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }

    component ColorChoice: Rectangle {
        id: choice
        required property string role
        required property string label
        required property color selectedColor
        signal triggered
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: label
        Keys.onSpacePressed: triggered()
        Keys.onReturnPressed: triggered()
        implicitHeight: 54
        radius: 15
        color: colorPointer.containsMouse
            ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        border.color: root.theme.borderSubtle

        Rectangle {
            x: 9; anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 36; radius: 11
            color: choice.selectedColor
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.32)
        }
        Column {
            x: 56; anchors.verticalCenter: parent.verticalCenter; spacing: 1
            Text { text: choice.label; color: root.ink; font.pixelSize: 12; font.weight: Font.DemiBold }
            Text { text: root.rgbHex(choice.selectedColor).toUpperCase(); color: root.mutedInk; font.pixelSize: 10 }
        }
        MouseArea {
            id: colorPointer; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.triggered()
        }
    }

    function setAutomaticColors(enabled) {
        if (enabled || config.accentMode === "custom") {
            config.setWallpaperColorsEnabled(enabled)
            return
        }
        config.setWallpaperColorsEnabled(false, {
            accent: rgbHex(theme.accent), bar: rgbHex(theme.independentBarSurface),
            icons: rgbHex(theme.iconInk), widgets: rgbHex(theme.widgetSolidSurface),
            text: rgbHex(theme.textPrimary), panels: rgbHex(theme.wallpaperSurfaceTone),
            bubbles: rgbHex(theme.barBubbleTint)
        })
    }

    component SettingSlider: Components.VeloraSettingsSlider {
        theme: root.theme
        signal committed(real value)
        onEdited: value => committed(value)
    }

    component LiquidStylePicker: Column {
        width: parent ? parent.width : 300
        spacing: 8
        Text { text: root.config.barMaterial === "liquid" ? "Liquid Ass" : "Liquid Glass"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
        Components.VeloraSettingsTabs {
            theme: root.theme; motion: root.motion
            options: [{id:"clear",label:"Nítido"},{id:"frosted",label:"Fosco"}]
            selected: root.config.liquidGlassStyle
            onChosen: id => root.config.setValue("bar.liquidStyle", id)
        }
        Text {
            width: parent.width; wrapMode: Text.WordWrap
            text: root.config.liquidGlassStyle === "frosted"
                ? "Fundo suavizado para facilitar a leitura, com reflexos nas bordas."
                : "Fundo nítido, com refração ajustável e reflexos nas bordas."
            color: root.mutedInk; font.pixelSize: 11
        }
    }

    component PageTitle: Column {
        property string title: ""
        property string detail: ""
        width: parent ? parent.width : 500; spacing: 4
        Text { text: parent.title; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 23; font.weight: Font.Bold }
        Text { width: parent.width; text: parent.detail; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
    }

    function revealSystemTool() {
        if (!pendingSystemTool || !pageLoader.item || typeof pageLoader.item.openTool !== "function") return
        if (pageLoader.item.openTool(pendingSystemTool)) pendingSystemTool=""
    }
    function openTool(kind) {
        if (!["monitor","brightness","volume","notifications","battery","wifi"].includes(kind)) return
        pendingSystemTool=kind
        controller.setSettingsPage("system")
        Qt.callLater(revealSystemTool)
    }
    Text {
        id: pickerErrorLabel
        width: parent.width
        visible: root.controller.pickerError.length > 0
        text: root.controller.pickerError
        color: root.theme.danger
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
    Loader {
        id: pageLoader
        readonly property real restingY: pickerErrorLabel.visible ? pickerErrorLabel.height + 12 : 0
        y: restingY
        onRestingYChanged: if (!sectionEntrance.running) y = restingY
        width: parent.width
        onLoaded: {
            sectionEntrance.stop()
            opacity = 1; y = restingY
            if (root.animatePageEntrance && root.motion && !root.motion.reduced) sectionEntrance.restart()
            Qt.callLater(root.revealSystemTool)
        }
        sourceComponent: root.page === "appearance" ? appearancePage
            : root.page === "lock" ? lockPage
            : root.page === "system" ? systemPage
            : root.page === "media" ? mediaPage
            : root.page === "infiniteDesk" ? infiniteDeskPage
            : root.page === "credits" ? creditsPage
            : wallpapersPage
    }
    SequentialAnimation {
        id: sectionEntrance
        ScriptAction { script: { pageLoader.opacity=0; pageLoader.y=pageLoader.restingY+8 } }
        PauseAnimation { duration: root.motion ? root.motion.geometryDuration : 0 }
        ParallelAnimation {
            NumberAnimation { target: pageLoader; property: "opacity"; to: 1; duration: root.motion ? root.motion.contentDuration : 0 }
            NumberAnimation { target: pageLoader; property: "y"; to: pageLoader.restingY; duration: root.motion ? root.motion.contentDuration : 0; easing.type: Easing.OutCubic }
        }
    }
    Connections { target: root.motion
        function onReducedChanged() { if(root.motion.reduced) { sectionEntrance.stop(); pageLoader.opacity=1; pageLoader.y=pageLoader.restingY } }
    }
    Component { id: appearancePage
                Column {
                    width: parent ? parent.width : 600; spacing: 12
                    function prepareResult(result) {
                        if (result.group === "widgets") return desktopEditor.prepareResult(result)
                        const group=({bar:materialGroup})[result.group]
                        if (!group) return false
                        group.expanded=true
                        if (!group.contentItem || group.reveal<.98) return true
                        return typeof group.contentItem.prepareResult === "function" ? group.contentItem.prepareResult(result) : false
                    }
                    SettingsDesktop {
                        id: desktopEditor
                        width: parent.width; config: root.config; controller: root.controller
                        editor: root.editor; theme: root.theme; motion: root.motion
                        legacyTheme: root.legacyTheme
                    }
                    Text { text: "Paleta de cores"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Components.VeloraSettingsTabs {
                        theme: root.theme; motion: root.motion; tabWidth: 130
                        options: [{id:"wallpaper",label:"Do wallpaper"},{id:"custom",label:"Cor manual"}]
                        selected: root.config.accentMode
                        onChosen: id => root.setAutomaticColors(id === "wallpaper")
                    }
                    SettingSwitch {
                        objectName: "appearance.automatic-colors"
                        label: "Cores automáticas do wallpaper"
                        hint: "Atualiza as cores ao trocar o wallpaper. Desligado mantém as cores escolhidas."
                        width: parent.width
                        checked: root.config.wallpaperColorsEnabled
                        onTriggered: root.setAutomaticColors(!checked)
                    }
                    Column {
                        width: parent.width
                        spacing: 8
                        visible: root.config.accentMode === "custom"
                        Text {
                            text: "Cores por bloco"
                            color: root.ink; font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Text {
                            width: parent.width
                            text: "Clique em cada bloco para escolher sua cor. A paleta acompanha o perfil atual."
                            color: root.mutedInk; font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: root.manualColorTargets
                                ColorChoice {
                                    required property var modelData
                                    width: Math.max(150, (parent.width - 16) / 3)
                                    objectName: "appearance.color." + modelData.role
                                    role: modelData.role
                                    label: modelData.label
                                    selectedColor: root.config.customColor(modelData.role)
                                    onTriggered: root.openManualColor(
                                        modelData.role, selectedColor)
                                }
                            }
                        }
                        Loader {
                            id: manualPickerLoader
                            width: parent.width
                            height: item ? item.implicitHeight : 0
                            onHeightChanged: if (active && item) { manualPickerReveal.target=item; manualPickerReveal.restart() }
                            active: root.pendingColorRole.length > 0
                            visible: active
                            onLoaded: { manualPickerReveal.target=item; manualPickerReveal.restart() }
                            sourceComponent: SettingsColorPicker {
                                width: manualPickerLoader.width
                                theme: root.theme
                                label: (root.manualColorTargets.find(entry => entry.role === root.pendingColorRole) || {}).label || "Cor"
                                initialColor: root.pendingColorValue
                                onAccepted: color => {
                                    root.config.setCustomColor(root.pendingColorRole, color)
                                    Qt.callLater(function() { root.pendingColorRole = "" })
                                }
                                onCanceled: Qt.callLater(function() { root.pendingColorRole = "" })
                            }
                        }
                    }
                    SettingsAppearanceGroup {
                        id: materialGroup; objectName: "appearanceGroup-bar"
                        width: parent.width; title: "Barra"; icon: "tune"; theme: root.theme; motion: root.motion
                        contentComponent: barPage
                    }

                }
    }

    Component { id: barPage
        Column {
            width: parent ? parent.width : 600; spacing: 10
            function prepareResult(result) {
                const group = ({material:barMaterialGroup, icons:barIconsGroup,
                    items:barItemsGroup, behavior:barBehaviorGroup,
                    image:barImageGroup, terminal:barTerminalGroup})[result.subgroup || "material"]
                if (!group) return false
                group.expanded = true
                let waiting = !group.contentItem || group.reveal < .98
                if (result.fallbackLabel === "Kitty e barra iguais"
                        && (root.config.barMatchKittyMaterial
                            || !["liquid", "liquid-glass"].includes(root.config.barMaterial))) {
                    barTerminalGroup.expanded = true
                    waiting = waiting || !barTerminalGroup.contentItem || barTerminalGroup.reveal < .98
                }
                return waiting
            }
            SettingsAppearanceGroup {
                id: barMaterialGroup; objectName: "barGroup-material"
                width: parent.width; title: "Material e cor"; icon: "palette"
                theme: root.theme; motion: root.motion
                contentComponent: Column {
                    width: parent.width; spacing: 12
                    SettingsMaterialChoices {
                        objectName: "bar.material"
                        width: parent.width; theme: root.theme; config: root.config; motion: root.motion
                        imageSource: root.wallpaper ? root.wallpaper.currentPreviewPath || root.wallpaper.currentPath : ""
                    }
                    SettingSwitch {
                        objectName: "bar.background"; label: "Fundo da barra"
                        hint: "Mostra o fundo e a moldura; ícones, balões e menus continuam disponíveis."
                        checked: root.config.barBackgroundEnabled
                        onTriggered: root.config.setValue("bar.backgroundEnabled", !checked)
                    }
                    LiquidStylePicker { visible: ["liquid", "liquid-glass"].includes(root.config.barMaterial) && !root.config.barMatchKittyMaterial }
                    SettingSlider {
                        objectName: "bar.brightness"; label: "Brilho da barra"
                        minimum: .2; maximum: 1.2; value: root.config.barBrightness
                        valueText: Math.round(value * 100) + "%"
                        resettable: true; defaultValue: 1
                        hint: "Barra, menus, molduras e Kitty sincronizado."
                        onCommitted: value => root.config.setValue("bar.brightness", value)
                    }
                    SettingSlider {
                        objectName: "bar.refraction"; label: "Refração da barra"
                        visible: ["liquid", "liquid-glass"].includes(root.config.barMaterial)
                        enabled: !root.config.barMatchKittyMaterial
                        minimum: 0; maximum: 10; value: root.config.barRefractionStrength
                        valueText: Number(value).toFixed(1) + "×"
                        resettable: true; defaultValue: 1
                        hint: root.config.barMatchKittyMaterial
                            ? "Desative Kitty e barra iguais para ajustar separadamente."
                            : "Distorção do fundo da barra e molduras. Padrão: 1×."
                        onCommitted: value => root.config.setValue(root.config.barRefractionKey, value)
                    }
                    SettingSlider {
                        label: "Opacidade da barra"
                        value: root.config.barMatchKittyMaterial ? root.theme.kittyOpacity : root.config.barOpacity
                        enabled: !root.config.barMatchKittyMaterial
                        visible: root.config.barMaterial !== "solid"
                        onCommitted: function(value) {
                            root.config.setBarOpacity(Math.max(0.08, value))
                        }
                    }
                    SettingSwitch {
                        visible: root.config.barMaterial === "glass"
                        objectName: "barBlurToggle"; label: "Blur da barra"
                        hint: "Desfoque do material compartilhado da barra."
                        checked: root.config.barBlurEnabled
                        onTriggered: root.config.setValue("bar.blurEnabled", !checked)
                    }
                }
            }
            SettingsAppearanceGroup {
                id: barIconsGroup; objectName: "barGroup-icons"
                width: parent.width; title: "Ícones e balões"; icon: "apps"
                theme: root.theme; motion: root.motion
                contentComponent: Column {
                    width: parent.width; spacing: 12
                    SettingSwitch {
                        objectName: "bar.item-bubbles"; width: parent.width
                        label: "Balões nos itens"
                        hint: "Fundo na cor do tema ao redor dos botões, ícones e widgets da barra."
                        checked: root.config.barItemBubblesEnabled
                        onTriggered: root.config.setValue("bar.itemBubblesEnabled", !checked)
                    }
                    SettingSwitch {
                        objectName: "bar.item-bubbles-solid"; width: parent.width
                        label: "Balões sólidos"
                        hint: "Cor do tema com fundo opaco, sem blur ou refração."
                        enabled: root.config.barItemBubblesEnabled
                        checked: root.config.barItemBubblesSolid
                        onTriggered: root.config.setValue("bar.itemBubblesSolid", !checked)
                    }
                    SettingSwitch {
                        objectName: "bar.item-bubbles-liquid"; width: parent.width
                        label: "Liquid Ass nos balões"
                        hint: "Refrata a cena atrás da barra, mesmo com a barra sólida. Desativa Balões sólidos."
                        enabled: root.config.barItemBubblesEnabled
                        checked: root.config.barItemBubblesLiquid
                        onTriggered: root.config.setValue("bar.itemBubblesLiquid", !checked)
                    }
                    SettingsBarControls {
                        width: parent.width; theme: root.theme; motion: root.motion
                        barTheme: root.legacyTheme
                    }
                }
            }
            SettingsAppearanceGroup {
                id: barItemsGroup; objectName: "barGroup-items"
                width: parent.width; title: "Itens e organização"; icon: "workspaces"
                theme: root.theme; motion: root.motion
                contentComponent: Column {
                    width: parent.width; spacing: 12
                    ContextLink { objectName: "bar.open-editor"; label: "Organizar no Editor do desktop →"
                        onTriggered: root.controller.beginEditing("desktop") }
                    Flow {
                        id: barItemsGrid
                        objectName: "barItemsGrid"
                        width: parent.width; spacing: 12
                        readonly property int columns: Math.max(1, Math.floor((width + spacing) / 260))
                        readonly property real cellWidth: (width - (columns - 1) * spacing) / columns
                        SettingsBarItemChoice {
                            theme: root.theme; motion: root.motion
                            width: barItemsGrid.cellWidth
                            objectName: "topbarMessageToggle"; label: "Mensagem"
                            checked: root.config.topbarOneThingEnabled
                            onTriggered: root.config.setValue("topbar.oneThingEnabled", !checked)
                        }
                        SettingsBarItemChoice {
                            theme: root.theme; motion: root.motion
                            width: barItemsGrid.cellWidth
                            objectName: "topbarNotesToggle"; label: "Notas"
                            checked: root.config.topbarNotesEnabled
                            onTriggered: root.config.setValue("topbar.notesEnabled", !checked)
                        }
                        Repeater {
                            model: root.config.topbarLayout.filter(item => item.section !== "right")
                            SettingsBarItemChoice {
                                theme: root.theme; motion: root.motion
                                width: barItemsGrid.cellWidth
                                required property var modelData
                                objectName: "bar.item-visible"
                                label: root.config.topbarItemLabel(modelData.type); checked: modelData.enabled
                                onTriggered: root.config.setTopbarItemEnabled(modelData.id, !checked)
                            }
                        }
                    }
                }
            }
            SettingsAppearanceGroup {
                id: barBehaviorGroup; objectName: "barGroup-behavior"
                width: parent.width; title: "Comportamento"; icon: "tune"
                theme: root.theme; motion: root.motion
                contentComponent: Column {
                    width: parent.width; spacing: 12
                    SettingSwitch {
                        objectName: "bar.infinite-desktop-topbar"; label: "Barra do Infinite Desk"
                        hint: "Desative para manter a barra e molduras ao usar Super+Z."
                        checked: root.config.infiniteDesktopTopbarEnabled
                        onTriggered: root.config.setValue("bar.infiniteDesktopTopbarEnabled", !checked)
                    }
                }
            }
            SettingsAppearanceGroup {
                id: barImageGroup; objectName: "barGroup-image"
                width: parent.width; title: "Imagem da barra"; icon: "person"
                theme: root.theme; motion: root.motion
                contentComponent: Column {
                    width: parent.width; spacing: 12
                    Rectangle {
                        width: Math.min(520,parent.width); height: 88; radius: 15
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1; border.color: root.theme.borderSubtle
                        Rectangle {
                            x: 14; anchors.verticalCenter: parent.verticalCenter
                            width: 58; height: 58; radius: 29; clip: true
                            color: Qt.rgba(0, 0, 0, 0.22)
                            Image {
                                id: avatarPreviewImage
                                anchors.fill: parent
                                source: root.barAvatarPath.length > 0
                                    && !/\.webp(?:[?#].*)?$/i.test(root.barAvatarPath)
                                    ? root.barAvatarPath
                                    : Qt.resolvedUrl("../../assets/profile-avatar.svg")
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                onStatusChanged: {
                                    if (status === Image.Error && root.controller.shell
                                            && root.controller.shell.unifiedTheme
                                            && root.config.avatarPath.length > 0
                                            && root.barAvatarPath !== root.config.avatarPath)
                                        root.controller.shell.unifiedTheme.setProfileImagePath(root.config.avatarPath)
                                }
                            }
                        }
                        Text {
                            x: 88; y: 12
                            text: "Imagem da barra"
                            color: root.mutedInk; font.pixelSize: 11
                        }
                        Row {
                            x: 88; y: 38; spacing: 8
                            ActionButton { label: "Trocar imagem"; onTriggered: root.controller.chooseBarAvatar() }
                            ContextLink {
                                label: "Usar padrão"
                                enabled: root.barAvatarPath.length > 0
                                onTriggered: root.controller.resetBarAvatar()
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        visible: root.controller.profileAvatarError.length > 0
                        text: root.controller.profileAvatarError
                        color: root.theme.danger
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                }
            }
            SettingsAppearanceGroup {
                id: barTerminalGroup; objectName: "barGroup-terminal"
                width: parent.width; title: "Terminal Kitty"; icon: "terminal"
                theme: root.theme; motion: root.motion
                contentComponent: Column {
                    width: parent.width; spacing: 12
                    SettingSwitch {
                        objectName: "bar.kitty-match"; label: "Kitty e barra iguais"
                        hint: "A barra acompanha a cor, transparência e refração do Kitty."
                        checked: root.config.barMatchKittyMaterial
                        onTriggered: root.config.setValue("bar.matchKittyMaterial", !checked)
                    }
                    SettingSwitch {
                        objectName: "bar.terminal-liquid"; label: "Liquid Ass no Kitty"
                        checked: root.config.terminalLiquidEnabled
                        onTriggered: root.config.setValue("appearance.terminalLiquidEnabled", !checked)
                    }
                    SettingSwitch {
                        objectName: "bar.terminal-follow-bar"; label: "Kitty acompanha a barra"
                        hint: "Usa a cor, opacidade, blur e refração atuais da barra."
                        checked: root.config.terminalFollowBar
                        onTriggered: root.config.setValue("appearance.terminalFollowBar", !checked)
                    }
                    SettingSlider {
                        objectName: "bar.terminal-brightness"; label: "Brilho do Kitty"
                        visible: root.config.terminalFollowBar
                        enabled: root.config.terminalLiquidEnabled
                        minimum: .8; maximum: 1.2; value: root.config.terminalBarBrightness
                        valueText: Math.round(value * 100) + "%"
                        resettable: true; defaultValue: 1
                        hint: "Ajuste fino do fundo do terminal. 100% usa o brilho da barra."
                        onCommitted: value => root.config.setValue("appearance.terminalBarBrightness", value)
                    }
                    SettingSlider {
                        objectName: "bar.terminal-refraction"; label: "Refração do Kitty"
                        minimum: 0; maximum: 3; value: root.config.terminalRefraction
                        valueText: Number(value).toFixed(1) + "×"
                        enabled: !root.config.terminalFollowBar && (root.config.terminalLiquidEnabled || root.config.barMatchKittyMaterial)
                        hint: root.config.terminalFollowBar ? "A intensidade acompanha Refração da barra." : ""
                        onCommitted: value => root.config.setValue("appearance.terminalRefraction", value)
                    }
                }
            }
        }
    }
    Component { id: lockPage
        SettingsLock { width: parent.width; theme: root.theme; motion: root.motion; controller: root.controller }
    }
    Component { id: creditsPage
        SettingsCredits {
            width: parent.width; theme: root.theme; motion: root.motion
            onProfileLinkRequested: url => Qt.openUrlExternally(url)
        }
    }
    Component { id: infiniteDeskPage
        SettingsInfiniteDesk {
            width: parent.width; config: root.config; theme: root.theme; motion: root.motion
        }
    }
    Component { id: wallpapersPage
        SettingsWallpaper {
            width: parent.width; config: root.config; controller: root.controller
            theme: root.theme; motion: root.motion; backend: root.integrations
        }
    }
    Component { id: systemPage
Column { width: parent ? parent.width : 600; spacing: 14
                    function openTool(kind) { return overview.openTool(kind) }
                    function prepareResult(result) {
                        if (result.group !== "accessibility") return false
                        if (!accessibility.expanded) { accessibility.expanded=true; return true }
                        return !accessibility.contentItem || accessibility.reveal<.98
                    }
                    SettingsOverview {
                        id: overview
                        width: parent.width
                        theme: root.theme; motion: root.motion; controller: root.controller
                        previewSource: root.wallpaper ? root.wallpaper.currentPreviewPath
                            || (/\.(png|jpe?g|bmp|gif)(?:[?#].*)?$/i.test(root.wallpaper.currentPath || "") ? root.wallpaper.currentPath : "") : ""
                        onSectionOpened: item => root.inlineToolOpened(item)
                    }
                    SettingsAppearanceGroup {
                        id: accessibility
                        objectName: "systemGroup-accessibility"
                        width: parent.width; title: "Acessibilidade e formatos"; icon: "language"
                        theme: root.theme; motion: root.motion; contentPadding: 12
                        contentComponent: Column {
                            width: parent.width; spacing: 18
                            SettingSwitch {
                                objectName: "motion.reduced"; label: "Movimento reduzido"
                                hint: "Mostra os controles diretamente, sem expansão nem deslocamentos."
                                checked: root.config.reducedMotion
                                onTriggered: root.config.setValue("appearance.reducedMotion", !checked)
                            }
                            Column {
                                width: parent.width; spacing: 10
                                Text { text: "Formato de data e hora"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12 }
                                Components.VeloraSettingsTabs {
                                    objectName: "system.locale"
                                    width: parent.width; theme: root.theme; motion: root.motion; tabWidth: 110
                                    options: [{id:"pt_BR",label:"Português"},{id:"en_US",label:"English"},{id:"ja_JP",label:"日本語"}]
                                    selected: root.config.localeName
                                    onChosen: id => root.config.setValue("appearance.locale", id)
                                }
                            }
                        }
                    }


}
    }
    Component { id: mediaPage
        SettingsMedia {
            width: parent ? parent.width : 600
            theme: root.theme; motion: root.motion; controller: root.controller
            legacyTheme: root.legacyTheme; integrations: root.integrations
        }
    }
}
