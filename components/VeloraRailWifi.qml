pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking
import "../features/topbar" as TopBar

VeloraRailPopover {
    id: root
    toolType: "wifi"
    preferredWidth: 330
    preferredHeight: 366
    property color ink: "white"
    property string uiFont: "sans-serif"
    readonly property var status: system ? system.status : null
    property var selectedNetwork: null
    property string error: ""
    readonly property var networks: status ? status.wifiNetworks.slice().sort((a,b) =>
        Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength) : []
    onOpenedChanged: if (!opened) { selectedNetwork = null; error = "" }
    Binding {
        target: root.status ? root.status.wifiDevice : null
        property: "scannerEnabled"
        value: root.opened && !!root.status && root.status.wifiEnabled
        when: !!root.status && !!root.status.wifiDevice
        restoreMode: Binding.RestoreBindingOrValue
    }
    Connections {
        target: root.selectedNetwork
        function onConnectionFailed(reason) { root.error = "Não foi possível conectar. Confira a senha ou abra os ajustes de rede." }
        function onConnectedChanged() { if (root.selectedNetwork && root.selectedNetwork.connected) root.selectedNetwork = null }
    }
    function choose(network) {
        error = ""
        selectedNetwork = network
        if (network.connected) return
        if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) network.connect()
        else if ([WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].indexOf(network.security) < 0) {
            system.runAction("network-editor")
            error = "Configure esta rede nos ajustes de rede."
        }
    }
    customContent: Component {
        ColumnLayout {
            id: content
            spacing: 9
            readonly property bool needsPassword: !!root.selectedNetwork && !root.selectedNetwork.connected
                && !root.selectedNetwork.known && [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(root.selectedNetwork.security)
            readonly property bool interactionHeld: password.activeFocus || needsPassword || !!root.selectedNetwork && root.selectedNetwork.stateChanging
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Internet"; color: root.ink; font.family: root.uiFont; font.pixelSize: 17; Layout.fillWidth: true }
                TopBar.BarAction {
                    theme: root.theme
                    text: root.status && root.status.wifiEnabled ? "Wi-Fi ligado" : "Ligar Wi-Fi"
                    highlighted: !!root.status && root.status.wifiEnabled
                    enabled: !!root.status && !!root.status.wifiDevice
                    onClicked: root.status.toggleWifi()
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.system.networkChanging ? "Conectando…" : root.system.network.interface
                    ? root.system.network.interface + (root.system.network.addresses && root.system.network.addresses.length ? " · " + root.system.network.addresses[0] : "") : "Redes disponíveis"
                color: root.ink; opacity: 0.7; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight
            }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 5; boundsBehavior: Flickable.StopAtBounds
                model: root.status && root.status.wifiEnabled ? root.networks : []
                delegate: Rectangle {
                    id: networkRow
                    required property var modelData
                    width: ListView.view.width; height: 44; radius: 10
                    color: root.theme.withAlpha(root.ink, modelData.connected ? 0.14 : networkMouse.containsMouse ? 0.10 : 0.04)
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 9; spacing: 9
                        TopBar.BarIcon { name: "wifi"; color: root.ink; level: networkRow.modelData.signalStrength; connected: true }
                        Text { Layout.fillWidth: true; text: networkRow.modelData.name || "Rede oculta"; color: root.ink; font.family: root.uiFont; font.pixelSize: 11; elide: Text.ElideRight }
                        Text { text: networkRow.modelData.connected ? "Conectada" : networkRow.modelData.stateChanging ? "…" : networkRow.modelData.known ? "Salva" : networkRow.modelData.security === WifiSecurityType.Open ? "Aberta" : "Senha"; color: root.ink; opacity: 0.65; font.pixelSize: 9 }
                    }
                    MouseArea { id: networkMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.choose(networkRow.modelData) }
                }
                Text { anchors.centerIn: parent; visible: parent.count === 0; text: root.status && root.status.wifiEnabled ? "Procurando redes…" : "Wi-Fi desligado"; color: root.ink; opacity: 0.65; font.pixelSize: 12 }
            }
            RowLayout {
                visible: content.needsPassword
                Layout.fillWidth: true
                TextField {
                    id: password
                    Layout.fillWidth: true
                    implicitHeight: 34; echoMode: TextInput.Password
                    placeholderText: "Senha da rede"; color: root.ink
                    placeholderTextColor: root.theme.textSecondary
                    font.family: root.uiFont; font.pixelSize: 11
                    background: Rectangle { radius: 8; color: root.theme.withAlpha(root.ink, 0.08); border.color: root.theme.borderStrong }
                    onAccepted: connectButton.clicked()
                    onVisibleChanged: { text = ""; if (visible) forceActiveFocus() }
                }
                TopBar.BarAction {
                    id: connectButton
                    theme: root.theme; text: "Conectar"; enabled: password.text.length >= 8 && !!root.selectedNetwork && !root.selectedNetwork.stateChanging
                    onClicked: if (enabled) { root.selectedNetwork.connectWithPsk(password.text); password.focus = false }
                }
            }
            Text { Layout.fillWidth: true; visible: root.error.length > 0; text: root.error; color: root.ink; font.pixelSize: 10; wrapMode: Text.WordWrap }
            RowLayout {
                Layout.fillWidth: true
                TopBar.BarAction { theme: root.theme; text: "Ajustes de rede"; onClicked: root.system.runAction("network-editor") }
                Item { Layout.fillWidth: true }
                TopBar.BarAction { theme: root.theme; text: "Desconectar"; visible: !!root.selectedNetwork && root.selectedNetwork.connected; onClicked: root.selectedNetwork.disconnect() }
            }
        }
    }
}
