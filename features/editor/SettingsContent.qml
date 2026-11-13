import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import "../../components" as Components

Item {
    id: root

    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var profileService
    required property var wallpaperStore
    signal requestClose
    signal revealSetting(string id)
    signal inlineToolOpened(var item)
    property string pendingSystemTool: ""

    property string page: "wallpapers"
    property string pendingColorRole: "accent"
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
        pendingColorRole = String(role)
        manualColorDialog.selectedColor = value
        manualColorDialog.open()
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

    ColorDialog {
        id: manualColorDialog
        title: "Escolher cor de " + root.pendingColorRole
        onAccepted: root.config.setCustomColor(
            root.pendingColorRole, root.rgbHex(selectedColor))
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

    component WallpaperAdjustments: Column {
        width: parent ? parent.width : 640; spacing: 14
        Row {
            width: parent.width; spacing: 12
            Repeater { model: ["Original", "Com seus ajustes"]
                Column {
                    required property string modelData
                    required property int index
                    width: (parent.width-12)/2; spacing: 7
                    SettingsScenePreview {
                        width: parent.width; height: Math.min(194,width*.6)
                        theme: root.theme
                        imageSource: root.wallpaper ? root.wallpaper.currentPreviewPath || root.wallpaper.currentPath : ""
                        blur: index === 1 && root.config.wallpaperBlurEnabled ? root.config.wallpaperBlurStrength : 0
                        dimming: index === 1 ? root.config.wallpaperDimming : 0
                    }
                    Text { text: parent.modelData; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                }
            }
        }
        Flow {
            width: parent.width; spacing: 24
            Column { width: Math.min(320,(parent.width-24)/2); spacing: 2
                SettingSwitch {
                    objectName: "wallpaperBlurToggle"; label: "Blur do wallpaper"
                    checked: root.config.wallpaperBlurEnabled
                    onTriggered: root.config.setValue("desktop.wallpaperBlurEnabled", !checked)
                }
                SettingSlider {
                    objectName: "wallpaper.blur-strength"; label: "Intensidade"
                    enabled: root.config.wallpaperBlurEnabled
                    value: root.config.wallpaperBlurStrength
                    onCommitted: value => root.config.setValue("desktop.wallpaperBlurStrength",value)
                }
            }
            Column { width: Math.min(320,(parent.width-24)/2); spacing: 2
                Text { height: 36; text: "Luz do fundo"; verticalAlignment: Text.AlignVCenter; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12 }
                SettingSlider { objectName: "wallpaper.dimming"; label: "Escurecer wallpaper"; value: root.config.wallpaperDimming
                    onCommitted: value => root.config.setValue("desktop.wallpaperDimming",value) }
            }
        }
    }

    component PageTitle: Column {
        property string title: ""
        property string detail: ""
        width: parent ? parent.width : 500; spacing: 4
        Text { text: parent.title; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 23; font.weight: Font.Bold }
        Text { width: parent.width; text: parent.detail; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
    }

    component LegacyControls: Loader {
        property string category: ""
        width: parent ? parent.width : 600
        active: visible && !!root.legacyTheme && !!root.integrations
        sourceComponent: Components.VeloraCompactSettings {
            width: parent.width; height: implicitHeight
            embedded: true; category: parent.category
            theme: root.legacyTheme; palette: root.theme; controller: root.integrations
            mediaSection: root.mediaSection
        }
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
            : root.page === "lock" ? desktopPage
            : root.page === "motion" ? motionPage
            : root.page === "system" ? systemPage
            : root.page === "media" ? mediaPage
            : root.page === "language" ? languagePage
            : root.page === "profiles" ? profilesPage : wallpapersPage
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
    Component { id: sidebarPage; LegacyControls { category: "bar" } }
    Component { id: appearancePage
                Column {
                    width: parent ? parent.width : 600; spacing: 12
                    function prepareResult(result) {
                        const group=({bar:materialGroup,layout:layoutGroup,sidebar:sidebarGroup,widgets:widgetsGroup})[result.group]
                        if (!group) return false
                        group.expanded=true
                        if (!group.contentItem || group.reveal<.98) return true
                        return typeof group.contentItem.prepareResult === "function" ? group.contentItem.prepareResult(result) : false
                    }
                    Text { text: "Paleta de cores"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Components.VeloraSettingsTabs {
                        theme: root.theme; motion: root.motion; tabWidth: 130
                        options: [{id:"wallpaper",label:"Do wallpaper"},{id:"custom",label:"Cor manual"}]
                        selected: root.config.accentMode
                        onChosen: id => root.config.setValue("appearance.accentMode",id)
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
                    }
                    SettingsAppearanceGroup {
                        id: materialGroup; objectName: "appearanceGroup-bar"
                        width: parent.width; title: "Barra e material"; icon: "tune"; theme: root.theme; motion: root.motion
                        contentComponent: barPage
                    }
                    SettingsAppearanceGroup {
                        id: layoutGroup; objectName: "appearanceGroup-layout"
                        width: parent.width; title: "Organização da barra"; icon: "workspaces"; theme: root.theme; motion: root.motion
                        contentComponent: barLayoutPage
                    }
                    SettingsAppearanceGroup {
                        id: sidebarGroup; objectName: "appearanceGroup-sidebar"
                        width: parent.width; title: "Lateral e menus"; icon: "settings"; theme: root.theme; motion: root.motion
                        contentComponent: sidebarPage
                    }
                    SettingsAppearanceGroup {
                        id: widgetsGroup; objectName: "appearanceGroup-widgets"
                        width: parent.width; title: "Desktop e widgets"; icon: "grid"; theme: root.theme; motion: root.motion
                        contentComponent: desktopPage
                    }
                }
    }

    Component { id: barPage
                Column {
                    width: parent ? parent.width : 600; spacing: 13
                    SettingsMaterialChoices {
                        objectName: "bar.material"
                        width: parent.width; theme: root.theme; config: root.config; motion: root.motion
                        imageSource: root.wallpaper ? root.wallpaper.currentPreviewPath || root.wallpaper.currentPath : ""
                    }
                    LiquidStylePicker { visible: ["liquid", "liquid-glass"].includes(root.config.barMaterial) && !root.config.barMatchKittyMaterial }
                    SettingSlider {
                        objectName: "bar.brightness"; label: "Brilho da barra"
                        minimum: .2; maximum: 1.2; value: root.config.barBrightness
                        valueText: Math.round(value * 100) + "%"
                        resettable: true; defaultValue: 1
                        hint: "Barras, menus, molduras e Kitty sincronizado."
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
                            ? "Desative Kitty e barras iguais para ajustar separadamente."
                            : "Distorção do fundo das barras e molduras. Padrão: 1×."
                        onCommitted: value => root.config.setValue(root.config.barRefractionKey, value)
                    }
                    SettingSwitch {
                        objectName: "bar.kitty-match"; label: "Kitty e barras iguais"
                        hint: "Barras acompanham a cor, transparência e refração do Kitty."
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
                        objectName: "barBlurToggle"; label: "Blur das barras"
                        hint: "Desfoque do fundo da barra superior e da lateral."
                        checked: root.config.barBlurEnabled
                        onTriggered: root.config.setValue("bar.blurEnabled", !checked)
                    }
                    Text { text: "Na barra superior"; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11 }
                    Row { spacing: 8
                        SettingSwitch {
                            objectName: "topbarMessageToggle"
                            label: "Mensagem"; hint: "Ocultar preserva a mensagem salva."
                            checked: root.config.topbarOneThingEnabled
                            onTriggered: root.config.setValue("topbar.oneThingEnabled", !root.config.topbarOneThingEnabled)
                        }
                        SettingSwitch {
                            objectName: "topbarNotesToggle"
                            label: "Notas"; hint: "Ocultar preserva as notas salvas."
                            checked: root.config.topbarNotesEnabled
                            onTriggered: root.config.setValue("topbar.notesEnabled", !root.config.topbarNotesEnabled)
                        }
                    }
                    SettingSwitch {
                        objectName: "bar.infinite-desktop-topbar"; label: "Barra do Infinite Desk"
                        hint: "Desative para manter as barras e molduras ao usar Super+Z."
                        checked: root.config.infiniteDesktopTopbarEnabled
                        onTriggered: root.config.setValue("bar.infiniteDesktopTopbarEnabled", !checked)
                    }
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
                            text: "Avatar da lateral e da barra superior"
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
    Component { id: barLayoutPage
        Column { width: parent.width; spacing: 12
                    Text { text: "Organização da parte superior"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    ActionButton {
                        label: "Arrastar itens no Desktop"
                        onTriggered: root.controller.beginEditing("desktop")
                    }
                    Flow { width: parent.width; spacing: 12
                    Repeater {
                        model: root.config.topbarToolsOrder
                        Rectangle {
                            id: toolOrderRow
                            objectName: "bar.tools-order"
                            required property string modelData
                            required property int index
                            width: (root.width-12*(Math.max(1,Math.floor(root.width/230))-1))/Math.max(1,Math.floor(root.width/230)); height: 44; radius: 11
                            color: Qt.rgba(1, 1, 1, 0.06)
                            Text {
                                x: 13; anchors.verticalCenter: parent.verticalCenter
                                width: parent.width-120; elide: Text.ElideRight
                                text: root.config.topbarToolLabel(toolOrderRow.modelData)
                                color: root.ink; font.pixelSize: 12
                            }
                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                ActionButton {
                                    implicitWidth: 42; label: "←"
                                    enabled: toolOrderRow.index > 0
                                    onTriggered: root.config.stepTopbarTool(toolOrderRow.modelData, -1)
                                }
                                ActionButton {
                                    implicitWidth: 42; label: "→"
                                    enabled: toolOrderRow.index < root.config.topbarToolsOrder.length - 1
                                    onTriggered: root.config.stepTopbarTool(toolOrderRow.modelData, 1)
                                }
                            }
                        }
                    }
                    }
                    Text { text: "Esquerda e centro"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Repeater {
                        model: root.config.referenceAppearance ? root.config.topbarLayout.filter(item => item.section !== "right") : root.config.topbarLayout
                        Rectangle {
                            id: barRow; objectName: "bar.layout"; required property var modelData
                            width: parent.width; height: 48; radius: 13
                            color: Qt.rgba(1,1,1,0.06); border.width: 1; border.color: root.theme.borderSubtle
                            Text { x: 13; width: Math.max(60,parent.width-330); elide: Text.ElideRight; height: parent.height; verticalAlignment: Text.AlignVCenter; text: barRow.modelData.type; color: root.ink; font.pixelSize: 11 }
                            Row { anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                Components.VeloraSettingsTabs {
                                    theme: root.theme; motion: root.motion; tabWidth: 64
                                    options: [{id:"left",label:"Esquerda"},{id:"center",label:"Centro"},{id:"right",label:"Direita"}]
                                    selected: barRow.modelData.section
                                    onChosen: id => root.config.moveTopbarItemToSection(barRow.modelData.id,id)
                                }
                                ActionButton { width: 32; label: "↑"; Accessible.name: "Mover " + barRow.modelData.type + " para cima"; onTriggered: root.config.moveTopbarItem(barRow.modelData.id, -1) }
                                ActionButton { width: 32; label: "↓"; Accessible.name: "Mover " + barRow.modelData.type + " para baixo"; onTriggered: root.config.moveTopbarItem(barRow.modelData.id, 1) }
                                SettingSwitch { width: 42; label: barRow.modelData.type; checked: barRow.modelData.enabled; onTriggered: root.config.setTopbarItemEnabled(barRow.modelData.id, !checked) }

                            }
                        }
                    }


}
    }
    Component { id: desktopPage
        SettingsWidgets {
            width: parent.width
            config: root.config; controller: root.controller; editor: root.editor
            theme: root.theme; motion: root.motion; legacyTheme: root.legacyTheme; space: root.page === "lock" ? "lock" : "desktop"
        }
    }
    Component { id: wallpapersPage
        Column {
            objectName: "wallpaperSettingsPage"
            width: parent.width; spacing: 22
            Text { text: "Enquadramento"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold }
            Flow {
                objectName: "wallpaper.fit"
                width: parent.width; spacing: 10
                Components.VeloraSettingsChoice {
                    width: Math.min(230,(parent.width-10)/2); theme: root.theme; motion: root.motion
                    label: "Preencher tela"; iconName: "wallpaper"
                    active: root.config.wallpaperFit === "cover"
                    onClicked: {
                        if (root.config.wallpaperFit==="cover") root.controller.wallpaperFitRefreshRequested()
                        else root.config.setValue("desktop.wallpaperFit","cover")
                    }
                }
                Components.VeloraSettingsChoice {
                    width: Math.min(230,(parent.width-10)/2); theme: root.theme; motion: root.motion
                    label: "Imagem inteira"; iconName: "image"
                    active: root.config.wallpaperFit === "contain"
                    onClicked: {
                        if (root.config.wallpaperFit==="contain") root.controller.wallpaperFitRefreshRequested()
                        else root.config.setValue("desktop.wallpaperFit","contain")
                    }
                }
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap
                text: root.config.wallpaperFit === "contain"
                    ? "Preserva a proporção, sem cortar nem deformar. Imagens ultrawide podem deixar bordas pretas na tela."
                    : "Preserva a proporção e preenche a tela, cortando o que ficar além das bordas."
                color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11
            }
            Text { text: "Efeitos"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold }
            WallpaperAdjustments { width: parent.width }
            Text { text: "Transições"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold }
            WallpaperTransitions { width: parent.width; theme: root.theme; motion: root.motion; backend: root.integrations }
            Loader { width: parent.width; sourceComponent: wallpaperSelectorPage }
            Text { objectName: "wallpaper.autosave"; width: parent.width; wrapMode: Text.WordWrap
                text: "O Velora salva automaticamente a composição por wallpaper, preservando as cores e a barra atuais ao restaurá-la."
                color: root.mutedInk; font.pixelSize: 12 }
        }
    }
    Component { id: wallpaperSelectorPage
        Column { width: parent.width; spacing: 18
            Text { text: "Seletor alternativo"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 14 }
            Components.VeloraSettingsTabs {
                objectName: "legacy.selector-position"
                theme: root.theme; motion: root.motion; tabWidth: 155
                options: [{id:"center",label:"Centro"},{id:"bottom",label:"Inferior (clássico)"}]
                selected: root.legacyTheme ? root.legacyTheme.wallpaperSelectorPosition : "center"
                onChosen: id => { if(root.legacyTheme) root.legacyTheme.setWallpaperSelectorPosition(id) }
            }
            ActionButton {
                objectName: "openAlternativeWallpaperSelector"
                label: "Abrir seletor alternativo"
                onTriggered: {
                    root.controller.hide()
                    if (root.controller.shell) root.controller.shell.showAlternativeWallpaperSelector()
                }
            }
            Text { width: parent.width; wrapMode: Text.WordWrap
                text: "A grade conectada à barra é o seletor principal. O carrossel continua disponível aqui."
                color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        SettingSwitch {
            objectName: "wallpaperSelectorGlassToggle"
            label: "Vidro do seletor alternativo"
            checked: root.config.wallpaperSelectorGlassEnabled
            onTriggered: root.config.setValue("desktop.wallpaperSelectorGlassEnabled", !root.config.wallpaperSelectorGlassEnabled)
        }
        }
    }
    Component { id: profilesPage
        Column {
            id: profilesPanel
            width: parent.width; spacing: 12
            property string selectedId: root.profileService.activeProfileId
            readonly property var selectedProfile: root.profileService.profiles.find(item => String(item.id) === selectedId) || null
            Flow { width: parent.width; spacing: 18
                ActionButton { label: "Novo perfil"; onTriggered: root.profileService.createProfile("") }
                ContextLink { label: "Importar .helixpack"; onTriggered: root.controller.importPackage() }
            }
            Flow { width: parent.width; spacing: 10
                Repeater { model: root.profileService.profiles
                    Rectangle {
                        id: profileCard
                        required property var modelData
                        readonly property bool selected: String(modelData.id) === profilesPanel.selectedId
                        width: Math.min(280,(profilesPanel.width-10)/2); height: 66; radius: 13
                        color: Qt.rgba(root.accent.r,root.accent.g,root.accent.b,selected ? .16 : .04)
                        border.width: 1; border.color: selected || activeFocus ? root.theme.accentSoft : root.theme.borderSubtle
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button; Accessible.name: modelData.name
                        Accessible.checkable: true; Accessible.checked: selected
                        function triggered() { profilesPanel.selectedId=String(modelData.id) }
                        Accessible.onPressAction: triggered()
                        Keys.onSpacePressed: triggered()
                        Keys.onReturnPressed: triggered()
                        Components.VeloraMaterialIcon { x: 14; y: 22; width: 22; height: 22; iconName: "layers"; iconColor: root.mutedInk }
                        Text { x: 50; y: 13; width: parent.width-62; text: profileCard.modelData.name; elide: Text.ElideRight; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12 }
                        Text { x: 50; y: 35; text: String(profileCard.modelData.id) === root.profileService.activeProfileId ? "Em uso" : "Salvo"; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: profileCard.triggered() }
                    }
                }
            }
            Flow { visible: !!profilesPanel.selectedProfile; width: parent.width; spacing: 18
                ActionButton { objectName: "profile.apply"; label: "Aplicar"; primary: true; onTriggered: root.profileService.applyProfile(profilesPanel.selectedId,true) }
                ContextLink { objectName: "profile.save"; label: "Salvar"; enabled: profilesPanel.selectedId === root.profileService.activeProfileId; onTriggered: root.profileService.updateProfile(profilesPanel.selectedId) }
                ContextLink { objectName: "profile.export"; label: "Exportar"; onTriggered: root.controller.exportPackage(profilesPanel.selectedId) }
            }
            ContextLink {
                label: "O que o perfil guarda?"
                hint: "Composição, imagens, paleta e organização da barra. Material da barra, opções gerais do desktop e movimento reduzido permanecem como estão. Saves por wallpaper restauram apenas a composição."
                onTriggered: scopeNote.visible=!scopeNote.visible
            }
            Text { id: scopeNote; visible: false; width: parent.width; wrapMode: Text.WordWrap; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11
                text: "Composição, imagens, paleta e organização da barra. Material da barra, opções gerais do desktop e movimento reduzido permanecem como estão. Saves por wallpaper restauram apenas a composição." }
            Text { width: parent.width; wrapMode: Text.WordWrap; color: root.theme.danger; font.pixelSize: 12; text: root.profileService.error || ""; visible: text.length > 0 }
        }
    }
    Component { id: motionPage
        Column { width: parent.width; spacing: 14
            SettingsMotionPreview { width: parent.width; theme: root.theme; motion: root.motion }
            Flow { width: parent.width; spacing: 24
                SettingSwitch {
                    objectName: "motion.reduced"; label: "Movimento reduzido"
                    hint: "Mostra os controles diretamente, sem expansão nem deslocamentos."
                    checked: root.config.reducedMotion
                    onTriggered: root.config.setValue("appearance.reducedMotion", !checked)
                }
                ContextLink { label: "Transições do wallpaper →"; onTriggered: root.revealSetting("wallpaper.transition") }
            }
        }
    }
    Component { id: systemPage
Column { width: parent ? parent.width : 600; spacing: 14
                    function openTool(kind) { return overview.openTool(kind) }
                    SettingsOverview {
                        id: overview
                        width: parent.width
                        theme: root.theme; motion: root.motion; controller: root.controller
                        previewSource: root.wallpaper ? root.wallpaper.currentPreviewPath
                            || (/\.(png|jpe?g|bmp|gif)(?:[?#].*)?$/i.test(root.wallpaper.currentPath || "") ? root.wallpaper.currentPath : "") : ""
                        onSectionOpened: item => root.inlineToolOpened(item)
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
    Component { id: languagePage
Column { width: parent ? parent.width : 600; spacing: 16

    Text { width: parent.width; wrapMode: Text.WordWrap; text: "Ajuste o formato de data e hora."; color: root.mutedInk; font.pixelSize: 12 }
    Text { text: "Formato de data e hora"; color: root.ink; font.pixelSize: 14 }
    Components.VeloraSettingsTabs {
        theme: root.theme; motion: root.motion; tabWidth: 110
        options: [{id:"pt_BR",label:"Português"},{id:"en_US",label:"English"},{id:"ja_JP",label:"日本語"}]
        selected: root.config.localeName
        onChosen: id => root.config.setValue("appearance.locale",id)
    }
    ContextLink { label: "Movimento reduzido →"; onTriggered: root.controller.setSettingsPage("motion") }
}
    }
}
