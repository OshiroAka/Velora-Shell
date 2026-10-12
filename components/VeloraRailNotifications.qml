pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

VeloraRailPopover {
    id: root
    toolType: "notifications"
    preferredWidth: 350
    preferredHeight: 410
    closeOnLeave: false
    property var notificationsModel: null
    property color ink: "white"
    property color accent: "#e4c6c0"
    property string uiFont: "sans-serif"
    signal dismissRequested(string notificationId)
    signal clearRequested()
    readonly property int count: notificationsModel ? notificationsModel.count : 0
    property bool clearing: false
    property real historyExit: 0
    property real emptyReveal: 1
    onCountChanged: {
        if (clearing) { clearMotion.stop(); clearing = false; historyExit = 0 }
        if (count === 0) { emptyReveal = 0; emptyEntering.restart() }
    }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function clearAnimated() {
        if (count <= 0 || clearing) return
        clearing = true
        clearMotion.restart()
    }
    SequentialAnimation {
        id: clearMotion
        NumberAnimation { target: root; property: "historyExit"; from: 0; to: 1; duration: 180; easing.type: Easing.InCubic }
        ScriptAction { script: { root.clearing = false; root.clearRequested(); root.historyExit = 0 } }
    }
    NumberAnimation { id: emptyEntering; target: root; property: "emptyReveal"; from: 0; to: 1; duration: 170; easing.type: Easing.OutCubic }

    customContent: Component {
        Item {
            Text {
                id: title
                anchors { left: parent.left; top: parent.top; right: clear.left; rightMargin: 8 }
                height: 30
                text: "Notificações"
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 17
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }
            Button {
                id: clear
                objectName: "notificationClear"
                anchors { right: parent.right; top: parent.top }
                width: 82; height: 30
                visible: root.count > 0
                enabled: !root.clearing
                text: "Limpar"
                onClicked: root.clearAnimated()
                background: Rectangle {
                    radius: 9
                    color: root.alpha(root.ink, clear.hovered ? 0.16 : 0.08)
                    border.width: 1
                    border.color: root.alpha(root.ink, 0.16)
                }
                contentItem: Text {
                    text: clear.text; color: root.ink; font.family: root.uiFont; font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                anchors.centerIn: parent
                visible: root.count === 0
                opacity: root.emptyReveal
                text: "Nenhuma notificação"
                color: root.alpha(root.ink, 0.7)
                font.family: root.uiFont
                font.pixelSize: 13
            }
            ListView {
                id: history
                objectName: "notificationHistory"
                anchors { left: parent.left; right: parent.right; top: title.bottom; bottom: parent.bottom; topMargin: 10 }
                visible: root.count > 0
                opacity: 1 - root.historyExit
                transform: Translate { x: root.historyExit * 12 }
                clip: true
                spacing: 7
                model: root.notificationsModel
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: card
                    required property string id
                    required property string summary
                    required property string body
                    required property string app
                    required property string timeText
                    width: history.width
                    height: 76
                    radius: 11
                    color: root.alpha(root.ink, 0.06)
                    border.width: 1
                    border.color: root.alpha(root.ink, 0.15)
                    Text {
                        anchors { left: parent.left; right: remove.left; top: parent.top; margins: 11 }
                        height: 19
                        text: card.summary || card.app
                        color: root.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors { left: parent.left; right: remove.left; top: parent.top; topMargin: 32; leftMargin: 11; rightMargin: 5 }
                        height: 16
                        text: card.body || card.app
                        color: root.alpha(root.ink, 0.73); font.family: root.uiFont; font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 11 }
                        height: 14; text: card.timeText
                        color: root.alpha(root.ink, 0.55); font.family: root.uiFont; font.pixelSize: 10
                    }
                    Button {
                        id: remove
                        anchors { right: parent.right; top: parent.top; margins: 9 }
                        width: 26; height: 26
                        Accessible.name: "Dispensar " + (card.summary || card.app)
                        onClicked: root.dismissRequested(card.id)
                        background: Rectangle { radius: 8; color: root.alpha(root.ink, remove.hovered ? 0.18 : 0.08) }
                        contentItem: Text { text: "×"; color: root.ink; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
                add: Transition { NumberAnimation { properties: "opacity,y"; from: 0; duration: 170; easing.type: Easing.OutCubic } }
                remove: Transition { NumberAnimation { properties: "opacity,x"; to: 0; duration: 130; easing.type: Easing.InCubic } }
            }
        }
    }
}
