import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../features/settings" as Settings

Variants {
    id: root

    required property var controller
    required property var compositor
    required property var config
    required property var theme
    required property var motion
    required property var profileService
    required property var editor
    required property var status
    required property int opticsGeneration

    model: controller.mounted && !controller.picking && compositor.focusedScreen
        ? [compositor.focusedScreen] : []

    PanelWindow {
        id: settingsWindow

        required property var modelData

        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        implicitHeight: modelData.height
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        focusable: root.controller.shown

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "velora-shell-settings"
        WlrLayershell.keyboardFocus: root.controller.shown
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        BackgroundEffect.blurRegion: Region {}

        // Settings must not steal clicks from the desktop outside its panel.
        mask: Region { item: settingsPanel; radius: 34 }

        property bool settingsShapeDirty: true
        property int appliedOpticsGeneration: root.opticsGeneration
        onAppliedOpticsGenerationChanged: queueSettingsShape()

        function queueSettingsShape() {
            settingsShapeDirty = true
        }

        function syncSettingsShape() {
            if (width <= 0 || height <= 0)
                return
            const topLeft = settingsPanel.mapToItem(inputScope, 0, 0)
            const bottomRight = settingsPanel.mapToItem(
                inputScope, settingsPanel.width, settingsPanel.height)
            const left = Math.min(topLeft.x, bottomRight.x)
            const top = Math.min(topLeft.y, bottomRight.y)
            const shapeWidth = Math.abs(bottomRight.x - topLeft.x)
            const shapeHeight = Math.abs(bottomRight.y - topLeft.y)
            Hyprland.dispatch("velora-blur:settings-shape "
                + (root.controller.mounted ? "1 " : "0 ")
                + (left / width).toFixed(6) + " "
                + (top / height).toFixed(6) + " "
                + (shapeWidth / width).toFixed(6) + " "
                + (shapeHeight / height).toFixed(6) + " "
                + (34 / width).toFixed(6))
        }

        FrameAnimation {
            running: settingsWindow.settingsShapeDirty
            onTriggered: {
                settingsWindow.syncSettingsShape()
                settingsWindow.settingsShapeDirty = false
            }
        }

        FocusScope {
            id: inputScope
            anchors.fill: parent
            focus: root.controller.shown

            Keys.onEscapePressed: {
                root.controller.hide()
            }

            MouseArea {
                anchors.fill: parent
                enabled: false
            }

            Settings.PreferencesPanel {
                id: settingsPanel
                anchors.centerIn: parent
                z: 2
                presented: root.controller.shown
                controller: root.controller
                config: root.config
                theme: root.theme
                motion: root.motion
                profileService: root.profileService
                editor: root.editor
                status: root.status
                compositor: root.compositor
            }

            function claimFocus() {
                if (root.controller.shown)
                    forceActiveFocus(Qt.ShortcutFocusReason)
            }

            Component.onCompleted: Qt.callLater(claimFocus)

            Connections {
                target: root.controller
                function onOpened() {
                    settingsWindow.queueSettingsShape()
                    Qt.callLater(inputScope.claimFocus)
                }
                function onClosed() { settingsWindow.queueSettingsShape() }
            }

            Connections {
                target: settingsPanel
                function onScaleChanged() { settingsWindow.queueSettingsShape() }
                function onWidthChanged() { settingsWindow.queueSettingsShape() }
                function onHeightChanged() { settingsWindow.queueSettingsShape() }
                function onXChanged() { settingsWindow.queueSettingsShape() }
                function onYChanged() { settingsWindow.queueSettingsShape() }
            }
        }

        Component.onCompleted: queueSettingsShape()
        Component.onDestruction: Hyprland.dispatch(
            "velora-blur:settings-shape 0 0 0 0.001 0.001 0")
    }
}
