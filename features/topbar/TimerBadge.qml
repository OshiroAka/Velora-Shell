import QtQuick
import "../../components" as Components

Components.VeloraBarItemBubble {
    id: root
    required property var config
    required property var theme
    required property var timerService
    property string monitor: ""
    property bool compact: false
    property real iconOpacity: 1
    property real labelPixelSize: 14
    tint: root.theme.barBubbleTint || root.theme.accent
    exactColor: !!root.theme.manualPalette
    monitorName: root.monitor
    surfaceTint: root.theme.barSurface
    solid: root.config.barItemBubblesSolid
    liquid: root.config.barItemBubblesEnabled && root.config.barItemBubblesLiquid
    objectName: "barExistingBubble-timer"
    opacity: root.theme.manualPalette ? 1 : root.iconOpacity
    width: parent.width - (root.compact ? 4 : root.config.barItemBubblesEnabled ? 14 : 10)
    height: root.config.barItemBubblesEnabled ? 28 : 25
    radius: 7
    color: nativeLiquid ? "transparent" : root.timerService.countdown.running || root.timerService.finished
        ? root.theme.textPrimary : root.config.barItemBubblesEnabled
            ? bubbleColor : root.theme.withAlpha(root.theme.textPrimary, 0.07)
    border.width: 1
    border.color: root.theme.withAlpha(root.theme.textPrimary, 0.18)
    Rectangle {
        visible: !root.config.barItemBubblesEnabled
        anchors.fill: parent; anchors.margins: 3
        radius: 4; color: "transparent"
        border.width: 1; border.color: root.theme.withAlpha(root.theme.textPrimary, 0.09)
    }
    Behavior on color { ColorAnimation { duration: 160 } }
    TimerLabel {
        anchors.centerIn: parent; text: root.timerService.barText || root.timerService.timerText
        transitionKey: root.timerService.duration + ":" + root.timerService.engaged
        color: root.timerService.countdown.running || root.timerService.finished ? root.theme.profileDark : root.theme.textPrimary
        family: root.theme.bodyFont; pixelSize: root.labelPixelSize; tabular: true
        Behavior on color { ColorAnimation { duration: 160 } }
    }
}
