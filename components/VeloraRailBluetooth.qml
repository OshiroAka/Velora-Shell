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
    closeOnLeave: !managing
    property color ink: "white"
    property color accent: "#e4c6c0"
    property string uiFont: "sans-serif"
    // ObjectModel notifications keep the list current without starting discovery.
    property var devices: manager.devices
    property bool available: manager.available
    property bool powered: manager.powered
    readonly property var knownDevices: devices.filter(d => d && (d.paired || d.bonded || d.connected))
    readonly property bool hasDevices: available && powered && knownDevices.length > 0
    property string selectedAddress: ""
    property real selectedCenter: 42
    readonly property var selectedDevice: knownDevices.find(d => d.address === selectedAddress) || null
    readonly property string deviceName: selectedDevice ? (selectedDevice.name || selectedDevice.deviceName || selectedDevice.address) : ""
    property real nameReveal: 0
    property real nameContentReveal: 0
    readonly property real nameWidth: Math.min(280, nameMetrics.advanceWidth + 32, Math.max(0, width - railWidth - targetWidth - 16))
    readonly property real nameY: Math.max(bodyY + 22, Math.min(bodyY + bodyHeight - 66, bodyY + selectedCenter - 22))
    property alias nameMask: nameArea
    preferredWidth: managing ? 360 : 72
    preferredHeight: managing ? (manager.pairPrompt ? 460 : 380) : (Math.min(hasDevices ? knownDevices.length : 0, 5) + 1) * 56 + 32
    contentPadding: 12
    extraHovered: nameHover.hovered
    extension: ({ y: nameY, width: nameWidth * nameReveal * reveal, height: 44 })
    onOpenedChanged: if (!opened) {
        hideName(); manager.stopScan()
        if (manager.busy) manager.cancel()
    }
    onMountedChanged: if (!mounted) { managing = false; removeAddress = "" }
    Behavior on preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    function openManager() {
        hideName(); managing = true; removeAddress = ""
        manager.scan()
    }
    onSelectedDeviceChanged: if (!selectedDevice) hideName()
    onHasDevicesChanged: if (!hasDevices) hideName()

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
    function showName(device, center) {
        if (!opened || managing || !device) return
        nameLeave.stop(); nameClosing.stop()
        selectedAddress = device.address
        selectedCenter = center
        nameExpanding.restart()
        if (nameContentReveal < 0.99) nameDelay.restart()
    }
    function hideName() {
        nameDelay.stop(); nameEntering.stop(); nameExpanding.stop(); nameLeave.stop()
        nameClosing.restart()
    }
    Behavior on selectedCenter { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    Behavior on preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    Timer { id: nameLeave; interval: 180; onTriggered: if (!nameHover.hovered) root.hideName() }
    NumberAnimation { id: nameExpanding; target: root; property: "nameReveal"; to: 1; duration: 210; easing.type: Easing.OutCubic }
    Timer { id: nameDelay; interval: 135; onTriggered: nameEntering.restart() }
    NumberAnimation { id: nameEntering; target: root; property: "nameContentReveal"; to: 1; duration: 150; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: nameClosing
        NumberAnimation { target: root; property: "nameContentReveal"; to: 0; duration: 65 }
        NumberAnimation { target: root; property: "nameReveal"; to: 0; duration: 125; easing.type: Easing.InOutCubic }
    }
    TextMetrics { id: nameMetrics; font.family: root.uiFont; font.pixelSize: 14; text: root.deviceName }
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
                onContentYChanged: root.hideName()
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
                            readonly property bool highlighted: tileHover.hovered || activeFocus
                            color: root.alpha(root.ink, highlighted ? 0.15 : modelData.connected ? 0.10 : 0.035)
                            border.width: 1
                            border.color: root.alpha(root.ink, highlighted ? 0.32 : 0.14)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.name || modelData.deviceName || modelData.address
                            Accessible.description: modelData.connected ? "Conectado" : "Pareado"
                            Accessible.onPressAction: revealName()
                            function revealName() {
                                const point = mapToItem(root, width / 2, height / 2)
                                root.showName(modelData, point.y - root.bodyY)
                            }
                            onActiveFocusChanged: {
                                if (activeFocus) { list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, y)); revealName() }
                                else nameLeave.restart()
                            }
                            Keys.onReturnPressed: revealName()
                            Keys.onSpacePressed: revealName()
                            VeloraMaterialIcon {
                                anchors.centerIn: parent
                                width: 28; height: 28
                                iconName: root.iconFor(tile.modelData)
                                iconColor: root.ink
                            }
                            Rectangle {
                                anchors { right: parent.right; bottom: parent.bottom; margins: 5 }
                                width: 4; height: 4; radius: 2
                                color: root.accent
                                visible: tile.modelData.connected
                            }
                            HoverHandler {
                                id: tileHover
                                blocking: false
                                onHoveredChanged: {
                                    if (hovered) tile.revealName()
                                    else nameLeave.restart()
                                }
                            }
                            TapHandler { onTapped: tile.revealName() }
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
                    text: root.manager.error || (!root.available ? "Bluetooth indisponível" : !root.powered ? "Bluetooth desligado" : root.manager.busy ? "Aguarde…" : root.manager.scanning ? "Buscando dispositivos…" : "Dispositivos disponíveis")
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
                                    x: 40; width: parent.width - 136; height: 48
                                    text: deviceRow.modelData.name || deviceRow.modelData.deviceName || deviceRow.modelData.address
                                    color: root.ink; font.family: root.uiFont; font.pixelSize: 12
                                    verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                                }
                                ManagerButton {
                                    objectName: "bluetoothAction" + deviceRow.modelData.address
                                    x: parent.width - 88; y: 8; width: 80
                                    text: deviceRow.modelData.paired || deviceRow.modelData.bonded ? (root.removeAddress === deviceRow.modelData.address ? "Confirmar" : "Remover") : "Parear"
                                    enabled: root.powered && !root.manager.busy
                                    onClicked: {
                                        if (deviceRow.modelData.paired || deviceRow.modelData.bonded) {
                                            if (root.removeAddress === deviceRow.modelData.address) { root.manager.remove(deviceRow.modelData.address); root.removeAddress = "" }
                                            else root.removeAddress = deviceRow.modelData.address
                                        } else { root.removeAddress = ""; root.manager.pair(deviceRow.modelData.address) }
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
                    ManagerButton { width: 144; text: root.manager.busy ? "Cancelar pareamento" : "Cancelar remoção"; visible: root.manager.busy || root.removeAddress.length > 0; onClicked: { root.removeAddress = ""; if (root.manager.busy) root.manager.cancel() } }
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
    Item {
        id: nameArea
        x: root.rightSide ? root.width - root.railWidth - root.bodyWidth - width : root.railWidth + root.bodyWidth
        y: root.nameY - 8
        width: root.mounted ? root.extension.width : 0
        height: root.mounted && root.nameReveal > 0.01 ? 60 : 0
        visible: root.mounted && width > 0.01
        HoverHandler {
            id: nameHover
            blocking: false
            onHoveredChanged: {
                if (hovered) nameLeave.stop()
                else nameLeave.restart()
            }
        }
        Item {
            anchors.fill: parent
            clip: true
            Text {
                x: 16
                y: 8
                width: Math.max(0, parent.width - 32)
                height: 44
                text: root.deviceName
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                opacity: root.nameContentReveal * root.contentReveal
            }
        }
    }
}
