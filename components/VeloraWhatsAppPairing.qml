pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var client
    property string family: "sans-serif"
    property bool reducedMotion: false
    readonly property bool interactionHeld: phone.activeFocus
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(340, parent.width - 40)
        height: Math.min(implicitHeight, Math.max(0, parent.height - 24))
        spacing: root.height < 520 ? 10 : 18
        Text {
            Layout.fillWidth: true
            text: "Conecte seu WhatsApp"
            color: "#f1f3f4"; font.family: root.family; font.pixelSize: 22
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            text: "Receba suas mensagens neste painel."
            color: "#a6aeb3"; font.family: root.family; font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 8
            Repeater {
                model: [{id:"qr",label:"QR Code"},{id:"code",label:"Código pelo telefone"}]
                delegate: Button {
                    id: methodButton
                    required property var modelData
                    objectName: "whatsappMethod" + modelData.id
                    text: modelData.label
                    enabled: root.client.ready
                    onClicked: root.client.setPairMethod(modelData.id)
                    background: Rectangle {
                        radius: 12
                        color: root.client.method === methodButton.modelData.id ? "#40348f75"
                            : methodButton.hovered || methodButton.activeFocus ? "#15f1f3f4" : "transparent"
                    }
                    contentItem: Text {
                        text: methodButton.text; color: "#f1f3f4"
                        font.family: root.family; font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    padding: 12; activeFocusOnTab: true
                }
            }
        }
        Rectangle {
            visible: root.client.method === "qr" && root.client.qrImage.length > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(250, parent.width)
            Layout.fillHeight: true
            Layout.minimumHeight: 110
            Layout.preferredHeight: Math.min(width, Math.max(140, root.height * .38))
            Layout.maximumHeight: width
            radius: 14; color: "white"
            Image {
                objectName: "whatsappPairQr"
                anchors.fill: parent; anchors.margins: 8
                source: root.client.qrImage
                sourceSize: Qt.size(256,256)
                fillMode: Image.PreserveAspectFit
            }
        }
        TextField {
            id: phone
            objectName: "whatsappPairPhone"
            visible: root.client.method === "code"
            Layout.fillWidth: true; implicitHeight: 44
            placeholderText: "Número com código do país"
            placeholderTextColor: "#a6aeb3"; color: "#f1f3f4"
            font.family: root.family; font.pixelSize: 13
            inputMethodHints: Qt.ImhDialableCharactersOnly
            selectByMouse: true; leftPadding: 14
            Accessible.name: "Número do WhatsApp com código do país"
            background: Rectangle { radius: 12; color: phone.activeFocus ? "#252f3c3b" : "#15f1f3f4" }
            onAccepted: if (root.client.ready && !root.client.busy) root.client.pair(text)
        }
        Text {
            objectName: "whatsappPairCode"
            visible: root.client.method === "code" && root.client.pairingCode.length > 0
            Layout.alignment: Qt.AlignHCenter
            text: root.client.pairingCode; color: "#f1f3f4"
            font.family: root.family; font.pixelSize: 30; font.letterSpacing: 4
        }
        Text {
            Layout.fillWidth: true
            text: root.client.method === "qr"
                ? "No celular, abra Aparelhos conectados → Conectar aparelho e leia o QR Code."
                : "No celular, abra Aparelhos conectados → Conectar aparelho → Conectar com número de telefone e informe o código."
            color: "#a6aeb3"; font.family: root.family; font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            visible: root.client.busy || root.client.error.length > 0
            text: root.client.error || root.client.statusText
            color: root.client.error ? "#e4b6a5" : "#a6aeb3"
            font.family: root.family; font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        }
        Button {
            id: connectButton
            objectName: "whatsappPairConnect"
            Layout.alignment: Qt.AlignHCenter
            text: !root.client.ready ? "Tentar novamente" : root.client.busy ? "Conectando…" : root.client.method === "qr"
                ? (root.client.qrImage ? "Atualizar QR Code" : "Gerar QR Code") : "Gerar código"
            enabled: !root.client.busy && (!root.client.ready || root.client.method === "qr" || phone.text.replace(/\D/g, "").length >= 8)
            onClicked: root.client.ready ? root.client.pair(phone.text) : root.client.reconnect()
            padding: 14; activeFocusOnTab: true
            background: Rectangle { radius: 14; color: connectButton.hovered || connectButton.activeFocus ? "#428f79" : "#34836d" }
            contentItem: Text {
                text: connectButton.text; color: "#f1f3f4"; font.family: root.family; font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
        Button {
            id: cancelButton
            objectName: "whatsappPairCancel"
            visible: root.client.busy || root.client.qrImage.length > 0 || root.client.pairingCode.length > 0
            Layout.alignment: Qt.AlignHCenter
            text: "Cancelar"; onClicked: root.client.cancelPairing()
            background: Item {}
            contentItem: Text { text: cancelButton.text; color: "#a6aeb3"; font.family: root.family; font.pixelSize: 12 }
        }
    }
}
