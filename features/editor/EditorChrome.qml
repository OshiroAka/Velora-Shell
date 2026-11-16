import QtQuick
import "../widgets" as Widgets
import "../../core/SurfaceGeometry.js" as Geometry

Item {
    id: root

    required property bool presented
    required property var controller
    required property var config
    required property var theme
    required property var motion
    required property var profileService
    required property var wallpaperStore
    required property var editor

    property bool catalogOpen: false
    readonly property bool settingsMode: controller.mode === "settings"
    readonly property bool editingMode: controller.mode === "editing"
    onEditingModeChanged: if (!editingMode) catalogOpen = false
    readonly property bool railOnRight: controller.shell ? controller.shell.barOnRight : false
    readonly property var surfaceArea: Geometry.area(width, height, config.topbarEnabled ? 64 : 0,
        railOnRight, config.topbarEnabled ? 40 : 0, 0, 18)
    function fitPanel(w, h, x, y) { return Geometry.fit(surfaceArea, w, h, x, y) }
    MouseArea {
        anchors.fill: parent
        z: 39
        visible: root.settingsMode
        onClicked: mouse => {
            if (mouse.x < settingsHome.x || mouse.x > settingsHome.x + settingsHome.width
                    || mouse.y < settingsHome.y || mouse.y > settingsHome.y + settingsHome.height)
                root.controller.hide()
        }
    }
    SettingsHome {
        id: settingsHome
        readonly property real bottomInset: root.controller.shell && root.controller.shell.bottomBarHeight !== undefined
            ? root.controller.shell.bottomBarHeight : 18
        property real wantedWidth: Math.min(preferredWidth, root.surfaceArea.width,
            launcherMode ? preferredWidth : Math.max(640, root.width * .66))
        property real wantedHeight: launcherMode
            ? Math.min(720, Math.max(220, preferredHeight), root.surfaceArea.height)
            : Math.min(preferredHeight, root.height * .80, root.surfaceArea.height)
        Behavior on wantedWidth { enabled: settingsHome.reveal > .999 && root.presented
            NumberAnimation { duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry } }
        Behavior on wantedHeight { enabled: settingsHome.reveal > .999 && root.presented
            NumberAnimation { duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry } }
        layoutWidth: launcherMode ? width : wantedWidth
        layoutHeight: launcherMode ? height : wantedHeight
        width: Math.min(root.surfaceArea.width, (launcherMode ? 140 : 72)
            + (wantedWidth - (launcherMode ? 140 : 72)) * reveal)
        height: Math.max(0, wantedHeight * (launcherMode ? reveal : .22 + .78 * reveal))
        x: launcherMode ? root.surfaceArea.x+(root.surfaceArea.width-width)/2
            : parent.width-width
        y: launcherMode ? Math.min(root.surfaceArea.y+root.surfaceArea.height,parent.height-bottomInset)-height
            : root.surfaceArea.y+(root.surfaceArea.height-height)/2
        presented: root.presented && root.settingsMode
        motion: root.motion
        z: 40; visible: root.settingsMode && reveal > .001
        config: root.config; controller: root.controller; editor: root.editor
        theme: root.theme; profileService: root.profileService
        wallpaperStore: root.wallpaperStore
        onRequestClose: root.controller.hide()
    }
    readonly property bool desktop: editor.editSpace === "desktop"
    readonly property var selectedLayer: editor.layerById(editor.selectedLayerId)
    property alias toolBarItem: toolBar
    property alias catalogItem: catalog
    property alias settingsItem: settingsHome

    opacity: settingsMode ? 1 : (presented ? 1 : 0)
    visible: opacity > 0.001
    Behavior on opacity {
        NumberAnimation { duration: root.settingsMode ? 0 : root.motion.selection; easing.type: Easing.OutCubic }
    }

    component ToolButton: Rectangle {
        id: button
        property string glyph: ""
        property string caption: ""
        property bool activeState: false
        property bool compact: false
        signal triggered
        width: compact ? 42 : Math.max(54, label.implicitWidth + 22)
        height: 42
        radius: 16
        color: activeState
            ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                      root.theme.accent.b, pointer.containsMouse ? 0.55 : 0.38)
            : Qt.rgba(1, 1, 1, pointer.containsMouse ? 0.20 : 0.08)
        border.width: 1
        border.color: pointer.containsMouse
            ? Qt.rgba(1, 1, 1, 0.56) : Qt.rgba(1, 1, 1, 0.18)
        scale: pointer.pressed ? 0.94 : 1
        opacity: enabled ? 1 : 0.38

        Behavior on color { ColorAnimation { duration: root.motion.reduced ? 0 : 190 } }
        Behavior on scale { NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic } }

        Text {
            id: label
            anchors.centerIn: parent
            text: button.caption.length ? button.caption : button.glyph
            color: "white"
            font.family: root.theme.bodyFont
            font.pixelSize: button.caption.length ? 11 : 18
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }

    Item {
        id: toolBar
        property bool nativeConnected: false
        readonly property real join: Math.min(24, height * .3)
        readonly property real radius: 25
        readonly property real bottomInset: root.controller.shell
            ? root.controller.shell.bottomBarHeight : 18
        readonly property color surfaceTint: settingsHome.surfaceTint
        visible: root.editingMode
        width: Math.min(root.surfaceArea.width, 560)
        height: 64
        x: Geometry.clamp((parent.width - width) / 2, root.surfaceArea.x, root.surfaceArea.x + root.surfaceArea.width - width)
        y: root.desktop ? parent.height - bottomInset - height
            : Geometry.clamp(18, root.surfaceArea.y, root.surfaceArea.y + root.surfaceArea.height - height)
        z: 30

        // The desktop toolbar is a body of the bottom frame. Its native pass
        // owns the shared material; the fallback meets the frame without a rim.
        SettingsSurface {
            objectName: "editorToolbarSurface"
            x: -toolBar.join
            width: parent.width + 2 * toolBar.join
            height: parent.height
            visible: root.desktop && !toolBar.nativeConnected
            join: toolBar.join
            corner: toolBar.radius
            tint: toolBar.surfaceTint
            rim: "transparent"
        }
        Widgets.GlassPanel {
            anchors.fill: parent
            visible: !root.desktop
            radius: toolBar.radius
            nativeOptics: false
            materialMode: "solid"
            solidColor: "#202634"
            materialOpacity: 0.98
            surfaceColor: root.theme.glass
            borderColor: root.theme.border
            shadowColor: root.theme.shadow
        }
        MouseArea { anchors.fill: parent }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top; anchors.bottomMargin: 9
            visible: root.desktop
            text: "Arraste os itens da barra para mudar a ordem."
            color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
            style: Text.Outline; styleColor: root.theme.surfaceRaised
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            ToolButton {
                glyph: "+"; compact: true; activeState: root.catalogOpen
                onTriggered: { root.catalogOpen = !root.catalogOpen }
            }
            ToolButton {
                glyph: "↖"; compact: true
                activeState: root.editor.toolMode === "select"
                onTriggered: root.editor.setToolMode("select")
            }
            ToolButton {
                caption: "Recortar"
                enabled: root.selectedLayer && root.selectedLayer.type === "image"
                activeState: root.editor.toolMode === "crop"
                onTriggered: root.editor.setToolMode(
                    root.editor.toolMode === "crop" ? "select" : "crop")
            }
            ToolButton {
                caption: "Texto"
                onTriggered: root.editor.addText("Novo texto")
            }
            ToolButton {
                glyph: "↶"; compact: true; enabled: root.editor.canUndo
                onTriggered: root.editor.undo()
            }
            ToolButton {
                glyph: "↷"; compact: true; enabled: root.editor.canRedo
                onTriggered: root.editor.redo()
            }
            ToolButton {
                caption: "Concluir"
                activeState: true
                onTriggered: root.controller.returnToSettings()
            }
        }
    }





    EditorWidgetCatalog {
        id: catalog
        presented: root.editingMode && root.catalogOpen
        config: root.config
        editor: root.editor
        controller: root.controller
        theme: root.theme
        motion: root.motion
        surfaceTint: settingsHome.surfaceTint
        onCloseRequested: root.catalogOpen = false
    }

    Widgets.GlassPanel {
        visible: root.editingMode && root.controller.closePrompt
        anchors.centerIn: parent
        width: 430
        height: 190
        z: 80
        radius: 26
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.surfaceRaised
        borderColor: root.theme.borderStrong
        shadowColor: root.theme.shadow

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12
            Text {
                text: "Salvar alterações?"
                color: root.theme.textPrimary
                font.family: root.theme.bodyFont
                font.pixelSize: 19
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: "A composição foi modificada neste modo de edição."
                color: root.theme.textSecondary
                font.family: root.theme.bodyFont
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
            Row {
                spacing: 8
                ToolButton {
                    caption: "Salvar"
                    activeState: true
                    onTriggered: root.controller.resolveClose("save")
                }
                ToolButton {
                    caption: "Descartar"
                    onTriggered: root.controller.resolveClose("discard")
                }
                ToolButton {
                    caption: "Voltar"
                    onTriggered: root.controller.resolveClose("return")
                }
            }
        }
    }
}
