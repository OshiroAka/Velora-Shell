import QtQuick
import "../../components" as Components
import "../../core/WidgetCatalog.js" as Catalog

Column {
    id: root
    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var motion
    property var legacyTheme: null
    readonly property string space: "desktop"
    property string selectedKind: "clock"
    onSelectedKindChanged: {
        contextEntrance.stop()
        if (motion && !motion.reduced && visible) contextEntrance.restart()
        else context.opacity = 1
    }
    onVisibleChanged: if (!visible) { contextEntrance.stop(); context.opacity = 1 }
    readonly property var selectedWidget: config.sharedWidgets.find(item => item.kind === selectedKind) || null
    readonly property string selectedName: selectedWidget ? selectedWidget.name
        : selectedKind === "visualizer" ? "Visualizador" : "Widgets"
    readonly property var variants: Catalog.variants(selectedKind)
    readonly property string selectedVariant: selectedWidget
        ? Catalog.resolve(selectedKind, selectedWidget.variantId).id : ""
    readonly property int variantColumns: Math.max(1, Math.min(3, Math.floor((width + 12) / 220)))
    readonly property int columns: Math.max(1, Math.min(4, Math.floor((width+12)/190)))
    spacing: 10

    SequentialAnimation {
        id: contextEntrance
        ScriptAction { script: context.opacity = 0 }
        PauseAnimation { duration: root.motion ? root.motion.geometryDuration : 0 }
        NumberAnimation { target: context; property: "opacity"; to: 1; duration: root.motion ? root.motion.contentDuration : 0 }
    }
    Connections {
        target: root.motion
        function onReducedChanged() { if (root.motion.reduced) { contextEntrance.stop(); context.opacity = 1 } }
    }

    function prepareResult(result) {
        let kind = ""
        if (result.id.indexOf("legacy.visualizer") === 0 || result.id === "desktop.visualizer") kind = "visualizer"
        else if (result.id.indexOf("scene.gallery") === 0) kind = "gallery"
        else if (result.id.indexOf("widget.") === 0) kind = result.id.split(".")[1]
        if (kind && selectedKind !== kind) { selectedKind = kind; return true }
        return false
    }
    function editSelected() {
        const identifier = selectedWidget ? selectedWidget.id : ""
        controller.beginEditing(space)
        if (identifier) editor.select(identifier)
    }
    function toggleWidget(widget) {
        config.setSharedWidgetVisibility(widget.kind,
            !widget.desktopEnabled, widget.lockEnabled)
    }

    component Link: Components.VeloraSettingsLink { theme: root.theme }
    component Toggle: Components.VeloraSettingsSwitch { theme: root.theme; motion: root.motion }
    component Caption: Text { color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }

    Flow {
        width: parent.width; spacing: 18
        Toggle {
            objectName: "desktopWidgetsToggle"; visible: root.space === "desktop"
            label: "Widgets no desktop"; checked: root.config.desktopWidgetsEnabled
            hint: "Ocultar todos preserva a escolha de cada widget."
            onTriggered: root.config.setValue("desktop.widgetsEnabled", !checked)
        }
    }
    Caption {
        width: parent.width; wrapMode: Text.WordWrap
        text: root.space === "desktop" && !root.config.desktopWidgetsEnabled
            ? "Widgets ocultos no desktop. Suas escolhas estão preservadas."
            : "Escolha uma família e depois a aparência do widget. A posição continua no editor."
    }

    component WidgetCard: Rectangle {
        id: card
        required property string kind
        required property string title
        property bool checked: false
        property bool canToggle: true
        property string toggleName: ""
        signal toggleRequested()
        readonly property bool selected: root.selectedKind === kind
        width: (root.width-(root.columns-1)*12)/root.columns; height: 151; radius: 17
        color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,selected ? .14 : hover.hovered ? .08 : .035)
        border.color: selected || activeFocus ? root.theme.accentSoft : root.theme.borderSubtle
        border.width: 1
        Behavior on color { ColorAnimation { duration: root.motion ? root.motion.surfaceHover : 0 } }
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: title + ", ajustes"
        Accessible.checkable: true; Accessible.checked: selected
        Accessible.onPressAction: triggered()
        function triggered() { root.selectedKind = kind }
        Keys.onSpacePressed: triggered()
        Keys.onReturnPressed: triggered()
        HoverHandler { id: hover }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.triggered() }
        SettingsWidgetPreview {
            anchors.top: parent.top; anchors.topMargin: 9; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width-28; height: 81; theme: root.theme; kind: card.kind
            variantId: Catalog.resolve(card.kind, (root.config.sharedWidgetByKind(card.kind) || {}).variantId)
                ? Catalog.resolve(card.kind, (root.config.sharedWidgetByKind(card.kind) || {}).variantId).id : "editorial"
            solid: root.config.widgetSurfaceMode === "solid"
            visualizerMode: root.legacyTheme ? root.legacyTheme.visualizerMode : "wave"
            opacity: card.checked ? 1 : .56
            Accessible.ignored: true
        }
        Text {
            x: 13; y: 99; width: parent.width-70
            text: card.title; color: root.theme.textPrimary; font.family: root.theme.bodyFont
            font.pixelSize: 11; elide: Text.ElideRight
        }
        Text {
            x: 13; y: 122; width: parent.width - 26
            text: Catalog.variants(card.kind).length ? Catalog.variants(card.kind).length + " aparências" : "Ajustes da composição"
            color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 9
            elide: Text.ElideRight
        }
        Toggle {
            objectName: card.toggleName
            anchors.right: parent.right; anchors.rightMargin: 10; y: 90
            width: 42; label: card.title + " no desktop"
            checked: card.checked; enabled: card.canToggle
            onTriggered: card.toggleRequested()
        }
    }
    Flow {
        width: parent.width; spacing: 12
        Repeater {
            model: root.config.sharedWidgets.filter(item => item.kind !== "calendar")
            WidgetCard {
                required property var modelData
                objectName: "widgetCard."+kind
                kind: modelData.kind; title: modelData.name
                toggleName: "widget."+kind+"."+root.space
                checked: modelData.desktopEnabled
                onToggleRequested: root.toggleWidget(modelData)
            }
        }
        WidgetCard {
            visible: root.space === "desktop"; objectName: "widgetCard.visualizer"
            kind: "visualizer"; title: "Visualizador"; toggleName: "desktopVisualizerToggle"
            checked: root.config.desktopVisualizerEnabled
            onToggleRequested: root.config.setValue("desktop.visualizerEnabled", !checked)
        }

    }
    Rectangle {
        width: parent.width; height: context.implicitHeight+22; radius: 14
        color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,.055)
        Column {
            id: context; x: 14; y: 11; width: parent.width-28; spacing: 8
            Row {
                spacing: 18
                Text { text: root.selectedName; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12; font.weight: Font.DemiBold; height: 32; verticalAlignment: Text.AlignVCenter }
                Link { visible: !!root.selectedWidget; label: "Posição e estilo ↗"; onTriggered: root.editSelected() }
            }
            Caption {
                visible: root.variants.length > 0
                width: parent.width; wrapMode: Text.WordWrap
                text: Catalog.description(root.selectedKind) + " · " + root.variants.length + " aparências. A escolha é salva para este widget."
            }
            Flow {
                objectName: "widgetVariants"
                width: parent.width; spacing: 10
                Repeater {
                    model: root.variants
                    Rectangle {
                        id: choice
                        required property var modelData
                        readonly property bool chosen: root.selectedVariant === modelData.id
                        objectName: "widgetVariant." + root.selectedKind + "." + modelData.id
                        width: (context.width - (root.variantColumns - 1) * 10) / root.variantColumns
                        height: 176; radius: 14
                        color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, chosen ? .10 : .025)
                        border.width: 1; border.color: chosen || activeFocus ? root.theme.accent : root.theme.borderSubtle
                        activeFocusOnTab: true
                        function choose() { root.config.setWidgetVariant(root.selectedKind, modelData.id) }
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: root.selectedName + ": " + modelData.name
                        Accessible.checkable: true; Accessible.checked: chosen
                        Accessible.onPressAction: choose()
                        Keys.onSpacePressed: choose()
                        Keys.onReturnPressed: choose()
                        SettingsWidgetPreview {
                            x: 14; y: 12; width: parent.width - 28; height: 112
                            theme: root.theme; kind: root.selectedKind; variantId: choice.modelData.id
                            Accessible.ignored: true
                        }
                        Text {
                            x: 13; y: 134; width: parent.width - 38; text: choice.modelData.name
                            font.family: root.theme.bodyFont; font.pixelSize: 11; color: root.theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            x: 13; y: 154; width: parent.width - 26; text: choice.modelData.detail
                            font.family: root.theme.bodyFont; font.pixelSize: 9; color: root.theme.textSecondary
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 13; y: 137
                            width: 7; height: 7; radius: 4; color: root.theme.accent; visible: choice.chosen
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: choice.choose() }
                    }
                }
            }
            Caption {
                visible: !!root.selectedWidget && root.selectedKind !== "gallery"
                width: parent.width; wrapMode: Text.WordWrap
                text: ({clock:"Tipografia e tamanho no editor.",weather:"A previsão acompanha sua localização configurada.",media:"Controles conectados ao seu player.",system:"CPU, memória e armazenamento no desktop.",battery:"Nível de carga e alimentação do dispositivo."})[root.selectedKind] || ""
            }
            Loader {
                width: parent.width; active: root.selectedKind === "gallery"
                sourceComponent: Column {
                    width: parent.width; spacing: 6
                    Caption { text: "Fotos do desktop." }
                    Flow { width: parent.width; spacing: 8
                        Repeater { model: 3
                            Rectangle {
                                id: photo; required property int index
                                readonly property int assetIndex: root.config.galleryOrder[index] === undefined ? index : root.config.galleryOrder[index]
                                objectName: "scene.gallery."+(index+1)
                                width: Math.min(174,(context.width-16)/3); height: 100; radius: 10
                                color: Qt.rgba(0,0,0,.12); clip: true
                                activeFocusOnTab: true
                                function triggered() { root.controller.chooseImage(assetIndex+1) }
                                Accessible.role: Accessible.Button; Accessible.name: "Trocar imagem " + (index+1)
                                Accessible.onPressAction: triggered()
                                Keys.onSpacePressed: triggered()
                                Keys.onReturnPressed: triggered()
                                Image { id: photoImage; anchors.fill: parent; source: String(root.config.galleryPaths[photo.assetIndex] || ""); sourceSize.width: 220; asynchronous: true; fillMode: Image.PreserveAspectCrop }
                                SettingsWidgetPreview { anchors.fill: parent; visible: photoImage.status !== Image.Ready; theme: root.theme; kind: "gallery"; opacity: .45 }
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 27; color: Qt.rgba(0,0,0,.5)
                                    Text { anchors.centerIn: parent; text: ["Esquerda", "Centro", "Direita"][photo.index]+" ↗"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 10 } }
                                Rectangle { anchors.fill: parent; radius: 10; color: "transparent"; border.color: root.theme.accent; border.width: parent.activeFocus ? 2 : 0 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: photo.triggered() }
                            }
                        }
                    }
                }
            }
            Loader {
                width: parent.width; active: root.selectedKind === "visualizer" && !!root.legacyTheme
                sourceComponent: Column {
                    width: parent.width; spacing: 4
                    Components.VeloraSettingsTabs {
                        objectName: "legacy.visualizer-mode"; theme: root.theme; motion: root.motion
                        options: [{id:"wave",label:"Wave"},{id:"pixels",label:"Pixels"}]
                        selected: root.legacyTheme.visualizerMode
                        onChosen: id => root.legacyTheme.setVisualizerMode(id)
                    }
                    Components.VeloraSettingsSlider {
                        objectName: "legacy.visualizer-strength"; theme: root.theme; label: "Intensidade"
                        value: root.legacyTheme.visualizerStrength
                        onEdited: value => root.legacyTheme.setVisualizerStrength(value)
                    }
                }
            }

        }
    }
    Flow {
        visible: root.space === "desktop"; width: parent.width; spacing: 14
        Text { text: "Superfície"; height: 36; verticalAlignment: Text.AlignVCenter; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        Components.VeloraSettingsTabs {
            objectName: "widgets.surface"; theme: root.theme; motion: root.motion; tabWidth: 116
            options: [{id:"solid",label:"100% sólidos"},{id:"bar",label:"Iguais à barra"}]
            selected: root.config.widgetSurfaceMode
            onChosen: id => root.config.setWidgetSurfaceMode(id)
        }
        Toggle {
            objectName: "widgets.blur"; label: "Blur dos widgets"
            visible: root.config.widgetSurfaceMode === "bar" && root.config.barMaterial === "glass"
            checked: root.config.widgetBlurEnabled
            onTriggered: root.config.setValue("lockPreview.sharedWidgets.blurEnabled", !checked)
        }
    }
    Flow {
        width: parent.width; spacing: 20
        Link { label: "Wallpaper →"; onTriggered: root.controller.setSettingsPage("wallpapers") }
        Link { visible: root.space === "desktop"; label: "Material da barra →"; hint: "A opção Iguais à barra herda a cor, transparência e desfoque da barra."; onTriggered: root.controller.setSettingsPage("bar") }
        Link { label: "Nova lockscreen →"; hint: "Prévia visual e integrações pendentes de revisão."; onTriggered: root.controller.setSettingsPage("lock") }
    }
}
