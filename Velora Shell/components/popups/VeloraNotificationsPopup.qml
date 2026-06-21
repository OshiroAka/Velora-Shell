import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var popup: null
    property var notificationsModel: null

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Central de notificações"
                color: root.popup ? root.popup.ink : "white"
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 17
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: clearLabel.implicitWidth + 18
                Layout.preferredHeight: 28
                radius: 14
                color: clearMouse.containsMouse && root.popup ? root.popup.alpha(root.popup.winAccent, 0.16) : "transparent"

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Limpar tudo"
                    color: root.popup ? root.popup.winAccent2 : Qt.rgba(1, 1, 1, 0.7)
                    font.family: root.popup ? root.popup.uiFont : "sans"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.popup) root.popup.clearNotifications()
                }
            }
        }

        VeloraPopupCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            popup: root.popup

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Repeater {
                    model: Math.min(root.notificationsModel ? root.notificationsModel.count : 0, 7)

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        radius: 10
                        color: notificationMouse.containsMouse && root.popup ? root.popup.winCardHover : (root.popup ? root.popup.alpha(root.popup.winCardHover, index === 0 ? 0.52 : 0.36) : Qt.rgba(1, 1, 1, 0.10))
                        border.width: 1
                        border.color: root.popup ? root.popup.alpha(index === 0 ? root.popup.winAccent : root.popup.winLine, index === 0 ? 0.34 : 0.9) : Qt.rgba(1, 1, 1, 0.12)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 12
                            spacing: 12

                            VeloraPopupIcon {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                popup: root.popup
                                iconName: "bell"
                                lineColor: root.popup ? (index === 0 ? root.popup.winAccent2 : root.popup.inkSoft) : "white"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.notificationsModel ? root.notificationsModel.get(index).summary : ""
                                        color: root.popup ? root.popup.ink : "white"
                                        font.family: root.popup ? root.popup.uiFont : "sans"
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: root.notificationsModel ? root.notificationsModel.get(index).timeText : ""
                                        color: root.popup ? root.popup.winAccent2 : Qt.rgba(1, 1, 1, 0.7)
                                        font.family: root.popup ? root.popup.monoFont : "monospace"
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.notificationsModel
                                        ? (root.notificationsModel.get(index).body.length > 0 ? root.notificationsModel.get(index).body : root.notificationsModel.get(index).app)
                                        : ""
                                    color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.65)
                                    font.family: root.popup ? root.popup.uiFont : "sans"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 7
                                Layout.preferredHeight: 7
                                radius: 4
                                color: root.popup ? root.popup.winAccent2 : "white"
                            }
                        }

                        MouseArea {
                            id: notificationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.popup && root.notificationsModel) root.popup.dismissNotification(root.notificationsModel.get(index).id)
                        }
                    }
                }

                Item {
                    visible: root.notificationsModel && root.notificationsModel.count > 0
                    Layout.fillHeight: true
                }

                ColumnLayout {
                    visible: !root.notificationsModel || root.notificationsModel.count <= 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Item { Layout.fillHeight: true }

                    VeloraPopupIcon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        popup: root.popup
                        iconName: "bell"
                        lineColor: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.7)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Sem notificações"
                        color: root.popup ? root.popup.ink : "white"
                        horizontalAlignment: Text.AlignHCenter
                        font.family: root.popup ? root.popup.uiFont : "sans"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Não há novas notificações"
                        color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.65)
                        horizontalAlignment: Text.AlignHCenter
                        font.family: root.popup ? root.popup.uiFont : "sans"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
