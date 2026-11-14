pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property var preview
    property color ink: "#f1f3f4"
    property bool reducedMotion: false
    property bool vertical: true
    readonly property bool interactionHeld: contacts.dragging || contacts.flicking
    Flickable {
        id: contacts
        objectName: "whatsappContactsScroll"
        anchors.fill: parent; clip: true
        contentWidth: root.vertical ? width : Math.max(width, entries.width + 24)
        contentHeight: root.vertical ? Math.max(height, entries.height + 24) : height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: root.vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick
        readonly property real scrollOffset: root.vertical ? contentY : contentX
        readonly property real scrollExtent: root.vertical ? contentHeight - height : contentWidth - width
        readonly property real fadeExtent: root.vertical ? height : width
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: contacts.width; height: contacts.height
                gradient: Gradient {
                    orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
                    GradientStop { position: 0; color: contacts.scrollOffset > 1 ? "transparent" : "white" }
                    GradientStop { position: Math.min(.15, 20 / Math.max(1,contacts.fadeExtent)); color: "white" }
                    GradientStop { position: 1 - Math.min(.15, 24 / Math.max(1,contacts.fadeExtent)); color: "white" }
                    GradientStop { position: 1; color: contacts.scrollOffset < contacts.scrollExtent - 1 ? "transparent" : "white" }
                }
            }
        }
        Connections {
            target: root.preview
            function onGroupsChanged() {
                contacts.cancelFlick()
                contacts.contentX = 0; contacts.contentY = 0
            }
        }
        Grid {
            id: entries
            columns: root.vertical ? 1 : root.preview.contacts.length + 3
            x: root.vertical ? (contacts.width - width) / 2 : 12
            y: root.vertical ? 12 : (contacts.height - height) / 2
            spacing: 12
            VeloraWhatsAppButton {
                objectName: "whatsappPeople"
                width: 44; height: 44; iconName: "person"; hint: "Conversas"
                selected: !root.preview.groups; ink: root.ink; reducedMotion: root.reducedMotion
                onClicked: root.preview.selectGroupMode(false)
            }
            VeloraWhatsAppButton {
                objectName: "whatsappGroups"
                width: 44; height: 44; iconName: "group"; hint: "Grupos"
                selected: root.preview.groups; ink: root.ink; reducedMotion: root.reducedMotion
                onClicked: root.preview.selectGroupMode(true)
            }
            Repeater {
                model: root.preview.contacts
                delegate: AbstractButton {
                    id: contactButton
                    required property var modelData
                    required property int index
                    objectName: "whatsappContact" + index
                    width: 44; height: 44
                    hoverEnabled: true; activeFocusOnTab: true
                    Accessible.name: modelData.name
                    Keys.onReturnPressed: clicked()
                    background: Item {}
                    contentItem: VeloraWhatsAppAvatar {
                        style: contactButton.modelData.style
                        imageSource: contactButton.modelData.avatar || ""
                        initials: Array.from(String(contactButton.modelData.name || ""))[0] || ""
                        opacity: root.preview.selected === contactButton.index || contactButton.hovered || contactButton.activeFocus ? 1 : .7
                        scale: contactButton.hovered || contactButton.activeFocus ? 1.06 : 1
                        transform: Translate { y: root.reducedMotion ? 0 : Math.max(-4,Math.min(4,-contacts.verticalVelocity/900)); Behavior on y { NumberAnimation { duration: root.reducedMotion ? 0 : 120; easing.type: Easing.OutCubic } } }
                        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 160 } }
                        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic } }
                    }
                    scale: pressed ? .94 : 1
                    Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 130; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.right: parent.right
                        width: 7; height: 7; radius: 3.5
                        color: "#36c79b"; visible: root.preview.selected === contactButton.index || contactButton.modelData.unread > 0
                    }
                    onClicked: root.preview.selectContact(index)
                }
            }
            VeloraWhatsAppButton {
                width: 44; height: 44; iconName: "add"; hint: "Nova conversa"
                ink: root.ink; enabled: false; reducedMotion: root.reducedMotion
            }
        }
    }
}
