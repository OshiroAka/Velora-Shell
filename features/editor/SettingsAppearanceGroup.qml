pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../../components" as Components

Item {
    id: root
    required property var theme
    required property var motion
    property string title: ""
    property string detail: ""
    property string icon: "settings"
    property real contentPadding: 0
    property bool expanded: false
    property Component contentComponent: null
    property real reveal: 0
    readonly property var contentItem: contentLoader.item
    width: parent ? parent.width : 600
    readonly property real headerHeight: detail.length ? 72 : 54
    implicitHeight: headerHeight+(contentLoader.height+18)*reveal
    function syncReveal() {
        if (!motion) return
        expansion.stop()
        const target=expanded ? 1 : 0
        if (motion.reduced) reveal=target
        else if (reveal!==target) { expansion.to=target;expansion.start() }
    }
    onExpandedChanged: syncReveal()
    Component.onCompleted: syncReveal()
    NumberAnimation { id: expansion; target: root; property: "reveal"
        duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry }
    Connections { target: root.motion; function onReducedChanged() { root.syncReveal() } }
    Rectangle {
        width: parent.width; height: root.headerHeight; radius: 18
        color: root.theme.withAlpha(root.theme.textPrimary,pointer.containsMouse ? .09 : .045)
        Behavior on color { ColorAnimation { duration: root.motion.surfaceHover } }
        border.width: header.activeFocus ? 1 : 0; border.color: root.theme.accent
        Item {
            id: header; anchors.fill: parent; activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: root.title
            Accessible.expandable: true; Accessible.expanded: root.expanded
            Accessible.onPressAction: root.expanded=!root.expanded
            Keys.onReturnPressed: root.expanded=!root.expanded
            Keys.onSpacePressed: root.expanded=!root.expanded
            Components.VeloraIconMotion {
                id: iconMotion
                highlighted: header.enabled && (pointer.containsMouse || header.activeFocus)
                reducedMotion: root.motion.reduced
            }
            Components.VeloraMaterialIcon {
                x: 18; anchors.verticalCenter: parent.verticalCenter
                width: 24; height: 24; iconName: root.icon; iconColor: root.theme.textPrimary
                scale: iconMotion.zoom
                transform: Translate { y: iconMotion.lift }
                opacity: iconMotion.inkOpacity
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software && iconMotion.emphasis>.001 && root.visible
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowColor: root.theme.textPrimary
                    shadowOpacity: .5*iconMotion.emphasis; shadowBlur: .5; blurMax: 12
                    shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true
                }
            }
            Column {
                x: 58; width: parent.width-104; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                Text { width: parent.width; text: root.title; color: root.theme.textPrimary
                    font.family: root.theme.bodyFont; font.pixelSize: 14; elide: Text.ElideRight }
                Text { width: parent.width; visible: root.detail.length>0; text: root.detail
                    color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 10; elide: Text.ElideRight }
            }
            Components.VeloraMaterialIcon { x: parent.width-36; anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20; iconName: "chevron_right"; iconColor: root.theme.textPrimary; rotation: 90*root.reveal }
            MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded=!root.expanded }
        }
    }
    Item {
        x: root.contentPadding; y: root.headerHeight+10
        width: Math.max(0,parent.width-2*x); height: Math.max(0,parent.height-y)
        clip: true; visible: root.reveal>0; enabled: root.expanded && root.reveal>.98
        Loader {
            id: contentLoader
            width: parent.width
            height: item ? (item as Item).implicitHeight : 0
            opacity: root.reveal
            active: root.expanded || root.reveal>0
            asynchronous: !root.motion.reduced
            sourceComponent: root.contentComponent
        }
    }
}
