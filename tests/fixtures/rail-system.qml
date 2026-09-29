import QtQuick
import Quickshell
import "components" as Components

ShellRoot {
    id: test
    property int stage: 0
    property int ticks: 0
    function check(value, message) { if (!value) throw new Error(message) }
    QtObject { id: theme }
    QtObject { id: system }
    ListModel { id: history }
    Item {
        width: 800; height: 600
        Components.VeloraRailPopover {
            id: first
            anchors.fill: parent
            theme: theme; system: system
            handoffSource: second
            preferredWidth: 360; preferredHeight: 346; anchorY: 220
            customContent: Component { Item {} }
        }
        Components.VeloraRailNotifications {
            id: second
            anchors.fill: parent
            theme: theme; system: system
            handoffSource: first
            notificationsModel: history
            anchorY: 360
            onClearRequested: history.clear()
        }
    }
    Component.onCompleted: history.append({id: "n1", summary: "Teste", body: "Mensagem", app: "Fixture", timeText: "agora"})
    Timer {
        interval: 80; running: true; repeat: true
        onTriggered: {
            if (++test.ticks > 55) { console.error("RAIL_SYSTEM_FAILED timeout", test.stage); Qt.quit(); return }
            try {
                switch (test.stage) {
                case 0: first.open(); break
                case 1:
                    if (first.reveal < 0.99) return
                    second.open()
                    test.check(!first.mounted && second.mounted, "handoff closes old panel immediately")
                    test.check(second.bodyWidth > 300, "new surface starts at previous width")
                    break
                case 2:
                    first.open()
                    test.check(!second.mounted && first.bodyWidth > 300, "rapid reverse keeps current surface")
                    break
                case 3:
                    second.open()
                    test.check(!first.mounted && second.bodyWidth > 300, "second rapid reversal keeps current surface")
                    break
                case 4:
                    if (second.handoffActive) return
                    test.check(Math.abs(second.bodyWidth - second.targetWidth) < 1, "surface reaches target")
                    test.check(second.count === 1, "notification rendered")
                    second.clearAnimated()
                    break
                case 5:
                    if (second.clearing) return
                    test.check(second.count === 0, "clear runs after exit animation")
                    console.info("RAIL_SYSTEM_OK"); Qt.quit(); return
                }
                test.stage++
            } catch (error) { console.error("RAIL_SYSTEM_FAILED", test.stage, error.message); Qt.quit() }
        }
    }
}
