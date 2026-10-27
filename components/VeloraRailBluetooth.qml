pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../services" as Services

VeloraRailPopover {
    id: root
    system: backend
    Services.RailBluetoothService { id: backend }
    property var manager: backend
    property bool managing: false
    property string removeAddress: ""
    closeOnLeave: !managing && !manager.busy
    property color ink: "white"
    property color accent: "#e4c6c0"
    property string uiFont: "sans-serif"
    // ObjectModel notifications keep the list current without starting discovery.
    property var devices: manager.devices
    property bool available: manager.available
    property bool powered: manager.powered
    readonly property var knownDevices: devices.filter(d => d && (d.paired || d.bonded || d.connected))
    readonly property bool hasDevices: available && powered && knownDevices.length > 0
    preferredWidth: managing ? 360 : 72
    preferredHeight: managing ? (manager.pairPrompt ? 460 : 380) : (Math.min(hasDevices ? knownDevices.length : 0, 5) + 1) * 56 + 32
    contentPadding: 12
    onOpenedChanged: {
        if (!opened) {
            manager.stopScan()
            if (manager.busy && manager.action === "pair") manager.cancel()
        } else if (manager.error) managing = true
    }
    onMountedChanged: if (!mounted) { managing = false; removeAddress = "" }
    Behavior on preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    function openManager() {
        managing = true; removeAddress = ""
        manager.scan()
    }
    Connections {
        target: root.manager
        function onErrorChanged() { if (root.opened && root.manager.error) root.managing = true }
        function onBusyChanged() { if (!root.manager.busy) root.updatePresence() }
    }

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function iconFor(device) {
        const icon = String(device.icon || "").toLowerCase()
        const name = String(device.name || device.deviceName || "").toLowerCase()
        if (/head|audio-card/.test(icon) || /qcy|airpods|buds|headphone|headset/.test(name)) return "headphones"
        if (/phone/.test(icon) || /iphone|pixel|galaxy|android/.test(name)) return "phone"
        if (/gaming|gamepad|joystick/.test(icon) || /controller|dualshock|dualsense|xbox/.test(name)) return "controller"
        if (/keyboard/.test(icon)) return "keyboard"
        if (/mouse/.test(icon)) return "mouse"
        if (/audio/.test(icon)) return "speaker"
        if (/computer/.test(icon)) return "display"
        return "bluetooth"
    }
    Behavior on preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    customContent: Component {
        Item {
            Flickable {
                id: list
                x: 0; y: 8
                width: parent.width; height: parent.height - 72
                visible: root.hasDevices && !root.managing
                clip: true
                contentHeight: deviceColumn.height
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: deviceColumn
                    width: list.width
                    spacing: 8
                    Repeater {
                        model: root.hasDevices ? root.knownDevices : []
                        Rectangle {
                            id: tile
                            objectName: "bluetoothDevice" + modelData.address
                            required property var modelData
                            width: deviceColumn.width
                            height: 48
                            radius: 11
                            activeFocusOnTab: true
                            readonly property bool pending: root.manager.busy && root.manager.targetAddress === modelData.address
                            readonly property bool highlighted: tileHover.hovered || activeFocus
                            enabled: root.powered && !root.manager.busy
                            color: root.alpha(root.ink, highlighted ? 0.15 : modelData.connected ? 0.10 : 0.035)
                            border.width: 1
                            border.color: root.alpha(root.ink, highlighted ? 0.32 : 0.14)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Accessible.role: Accessible.Button
                            Accessible.name: (modelData.connected ? "Desconectar " : "Conectar ")
                                + (modelData.name || modelData.deviceName || modelData.address)
                            Accessible.description: pending ? "Aguarde" : modelData.connected ? "Conectado" : "Pareado"
                            Accessible.onPressAction: activate()
                            function activate() { if (enabled) root.manager.toggleDevice(modelData) }
                            onActiveFocusChanged: if (activeFocus)
                                list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, y))
                            Keys.onReturnPressed: activate()
                            Keys.onSpacePressed: activate()
                            VeloraMaterialIcon {
                                anchors.centerIn: parent
                                width: 28; height: 28
                                iconName: root.iconFor(tile.modelData)
                                opacity: tile.pending ? .35 : 1
                                iconColor: root.ink
                            }
                            BusyIndicator {
                                objectName: "bluetoothPending" + tile.modelData.address
                                anchors.centerIn: parent; width: 38; height: 38
                                running: tile.pending && root.visible && !root.reducedMotion
                                visible: tile.pending
                            }
                            Rectangle {
                                anchors { right: parent.right; bottom: parent.bottom; margins: 5 }
                                width: 4; height: 4; radius: 2
                                color: root.accent
                                visible: tile.modelData.connected
                            }
                            HoverHandler { id: tileHover; blocking: false }
                            TapHandler { onTapped: tile.activate() }
                        }
                    }
                }
            }
            Button {
                id: addButton
                objectName: "bluetoothAdd"
                x: 0; y: parent.height - 56
                width: 48; height: 48
                visible: !root.managing
                enabled: root.available
                Accessible.name: "Adicionar dispositivo Bluetooth"
                onClicked: root.openManager()
                background: Rectangle {
                    radius: 11
                    color: root.alpha(root.ink, addButton.hovered ? 0.18 : 0.08)
                    border.width: 1; border.color: root.alpha(root.ink, 0.20)
                }
                contentItem: VeloraMaterialIcon { iconName: "plus"; iconColor: root.ink; glyphScale: 0.65 }
            }
            Column {
                anchors.fill: parent
                spacing: 10
                visible: root.managing
                Row {
                    width: parent.width; spacing: 8
                    Text { width: parent.width - 84; height: 32; text: "Bluetooth"; color: root.ink; font.family: root.uiFont; font.pixelSize: 17; verticalAlignment: Text.AlignVCenter }
                    ManagerButton { width: 76; text: "Voltar"; enabled: !root.manager.busy; onClicked: { root.manager.stopScan(); root.managing = false } }
                }
                Text {
                    width: parent.width; height: 32
                    text: root.manager.error || (!root.available ? "Bluetooth indisponível" : !root.powered ? "Bluetooth desligado" : root.manager.busy ? (root.manager.action === "connect" ? "Conectando…" : root.manager.action === "disconnect" ? "Desconectando…" : "Aguarde…") : root.manager.scanning ? "Buscando dispositivos…" : "Dispositivos disponíveis")
                    color: root.ink; font.family: root.uiFont; font.pixelSize: 12
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                }
                Flickable {
                    width: parent.width; height: 210
                    clip: true; contentHeight: managerDevices.height
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: managerDevices
                        width: parent.width; spacing: 6
                        Repeater {
                            model: root.managing ? root.devices : []
                            Rectangle {
                                id: deviceRow
                                objectName: "bluetoothRow" + modelData.address
                                required property var modelData
                                width: managerDevices.width; height: 48; radius: 10
                                color: root.alpha(root.ink, 0.055)
                                VeloraMaterialIcon { x: 8; y: 12; width: 24; height: 24; iconName: root.iconFor(deviceRow.modelData); iconColor: root.ink }
                                Text {
                                    x: 40; width: parent.width - 174; height: 48
                                    text: deviceRow.modelData.name || deviceRow.modelData.deviceName || deviceRow.modelData.address
                                    color: root.ink; font.family: root.uiFont; font.pixelSize: 12
                                    verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                                }
                                ManagerButton {
                                    objectName: "bluetoothConnect" + deviceRow.modelData.address
                                    x: parent.width - 126; y: 8; width: 84
                                    text: root.manager.busy && root.manager.targetAddress === deviceRow.modelData.address ? "…"
                                        : deviceRow.modelData.connected ? "Desconectar"
                                        : deviceRow.modelData.paired || deviceRow.modelData.bonded ? "Conectar" : "Parear"
                                    enabled: root.powered && !root.manager.busy
                                    onClicked: { root.removeAddress = ""; root.manager.toggleDevice(deviceRow.modelData) }
                                }
                                ManagerButton {
                                    objectName: "bluetoothAction" + deviceRow.modelData.address
                                    x: parent.width - 34; y: 8; width: 32
                                    visible: deviceRow.modelData.paired || deviceRow.modelData.bonded
                                    enabled: root.powered && !root.manager.busy
                                    Accessible.name: root.removeAddress === deviceRow.modelData.address ? "Confirmar remoção" : "Remover dispositivo"
                                    contentItem: VeloraMaterialIcon {
                                        iconName: root.removeAddress === deviceRow.modelData.address ? "check" : "delete"
                                        iconColor: root.ink; glyphScale: .7
                                    }
                                    onClicked: {
                                        if (root.removeAddress === deviceRow.modelData.address) { root.manager.remove(deviceRow.modelData.address); root.removeAddress = "" }
                                        else root.removeAddress = deviceRow.modelData.address
                                    }
                                }
                            }
                        }
                        Text { visible: root.devices.length === 0; width: parent.width; text: "Deixe o acessório em modo de pareamento."; color: root.ink; font.family: root.uiFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    }
                }
                Row {
                    spacing: 8
                    ManagerButton {
                        width: 164
                        text: !root.powered ? "Ativar Bluetooth" : root.manager.scanning ? "Parar busca" : "Buscar dispositivos"
                        enabled: root.available && !root.manager.busy
                        onClicked: { root.removeAddress = ""; if (!root.powered) root.manager.powerOn(); else if (root.manager.scanning) root.manager.stopScan(); else root.manager.scan() }
                    }
                    ManagerButton { width: 144; text: root.manager.busy ? "Cancelar operação" : "Cancelar remoção"; visible: root.manager.busy || root.removeAddress.length > 0; onClicked: { root.removeAddress = ""; if (root.manager.busy) root.manager.cancel() } }
                }
                Column {
                    width: parent.width; spacing: 6
                    visible: root.manager.pairPrompt.length > 0
                    Text { width: parent.width; text: root.manager.pairPrompt; color: root.ink; font.family: root.uiFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    Row {
                        spacing: 8
                        TextField { id: pin; width: 128; height: 32; visible: root.manager.needsPin; placeholderText: "PIN"; onAccepted: { root.manager.answer(text); clear() } }
                        ManagerButton { width: 86; text: root.manager.needsPin ? "Enviar" : "Confirmar"; enabled: !root.manager.needsPin || pin.text.trim().length > 0; onClicked: { root.manager.answer(root.manager.needsPin ? pin.text : "yes"); pin.clear() } }
                        ManagerButton { width: 80; text: "Recusar"; onClicked: root.manager.cancel() }
                    }
                }
            }
        }
    }
    component ManagerButton: Button {
        id: button
        height: 32
        background: Rectangle { radius: 8; color: root.alpha(root.ink, button.hovered ? 0.16 : 0.08); border.width: 1; border.color: root.alpha(root.ink, 0.15) }
        contentItem: Text { text: button.text; color: root.ink; opacity: button.enabled ? 1 : 0.4; font.family: root.uiFont; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
}
