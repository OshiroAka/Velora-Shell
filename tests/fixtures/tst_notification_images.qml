import QtQuick
import QtQuick.Window
import QtTest
import "../../components" as Components
import "../../features/topbar" as Topbar
import "../../core/NotificationMedia.js" as NotificationMedia

Window {
    visible: true
    width: 850; height: 650
    QtObject {
        id: theme
        property color textPrimary: "white"
        property color textSecondary: "#bbbbbb"
        property color accentSoft: "#8bcbb9"
        property color danger: "#ff8888"
        property color success: "#88ffaa"
        property string bodyFont: "Sans Serif"
        function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    }
    QtObject { id: system }
    QtObject {
        id: status
        property bool shown: false
        property var current: ({phase: "idle", agent: "", label: "", detail: "", progress: -1})
    }
    Topbar.ExecutionIndicator {
        id: toast
        x: 20; y: 20
        theme: theme; service: status
    }
    ListModel { id: history }
    Components.VeloraRailNotifications {
        id: panel
        x: 430; width: 350; height: 540
        embedded: true; contentPadding: 0
        theme: theme; system: system
        notificationsModel: history
    }
    SignalSpy { id: toastClicks; target: toast; signalName: "notificationClicked" }
    SignalSpy { id: historyClicks; target: panel; signalName: "activateRequested" }
    SignalSpy { id: dismisses; target: panel; signalName: "dismissRequested" }
    TestCase {
        name: "NotificationImages"
        // Quickshell hosts its own window instead of qmltestrunner's root.
        when: true
        windowShown: true
        function cleanup() {
            if (qtest_results.failed)
                console.error("NOTIFICATION_IMAGES_FAILED", qtest_results.functionName)
        }
        function cleanupTestCase() {
            console.info("NOTIFICATION_IMAGES_RESULTS", qtest_results.passCount, qtest_results.failCount)
            if (qtest_results.failCount === 0 && qtest_results.passCount >= 5)
                console.info("NOTIFICATION_IMAGES_OK")
            else console.error("NOTIFICATION_IMAGES_FAILED")
        }
        function init() {
            status.shown = false
            tryCompare(toast, "mounted", false, 2000)
            history.clear()
            toastClicks.clear(); historyClicks.clear(); dismisses.clear()
        }
        function notification(id, source) {
            return {phase: "notification", agent: "Velora screenshot", label: "Captura de tela", detail: "",
                progress: -1, notificationId: id, imageSource: source, iconKey: "velora"}
        }
        function showToast(id, source) {
            status.current = notification(id, source)
            status.shown = true
            tryCompare(toast, "contentReveal", 1, 2500)
        }
        function test_media_preserves_special_characters_and_rejects_nonlocal_open_targets() {
            const path = "/tmp/Prints com espaço # & <imagem> ç.png"
            const media = NotificationMedia.attachment({hints: {"x-velora-screenshot-path": path}, image: "image://old/provider"})
            compare(media.imageSource, media.openUrl)
            compare(media.openUrl, "file:///tmp/Prints%20com%20espa%C3%A7o%20%23%20%26%20%3Cimagem%3E%20%C3%A7.png")
            compare(NotificationMedia.attachment({hints: {"x-velora-screenshot-path": "https://example.org/image.png"}}).openUrl, "")
            compare(NotificationMedia.attachment({hints: {"x-velora-screenshot-path": "relative.png"}}).openUrl, "")
            compare(NotificationMedia.attachment({image: "image://notifications/123"}).imageSource, "image://notifications/123")
            compare(NotificationMedia.attachment({}).imageSource, "")
        }
        function test_toast_preview_and_mouse_keyboard_actions() {
            showToast("capture-1", Qt.resolvedUrl("notification-preview.svg").toString())
            const image = findChild(toast, "notificationImage")
            tryCompare(image, "status", Image.Ready)
            verify(image.y >= 39, "Preview is below the notification text")
            verify(image.paintedWidth <= image.width && image.paintedHeight <= image.height)
            verify(toast.height > 200 && image.mapToItem(toast, 0, image.height).y <= toast.height)
            mouseClick(toast, toast.width / 2, toast.height - 30)
            compare(toastClicks.count, 1)
            compare(toastClicks.signalArguments[0][0], "capture-1")
            compare(toastClicks.signalArguments[0][1], Qt.LeftButton)
            toast.forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(toastClicks.count, 2)
            mouseClick(toast, 30, 20, Qt.RightButton)
            compare(toastClicks.signalArguments[2][1], Qt.RightButton)
            // Same text, new file: the displayed ID must follow the displayed image.
            status.current = notification("capture-2", Qt.resolvedUrl("notification-preview.svg").toString())
            tryCompare(toast, "presented", status.current)
            mouseClick(toast, 40, 30)
            compare(toastClicks.signalArguments[3][0], "capture-2")
        }
        function test_plain_notifications_and_missing_images_remain_compact() {
            showToast("plain", "")
            tryCompare(toast, "height", 52)
            verify(!findChild(toast, "notificationImage").visible)
            status.current = notification("missing", Qt.resolvedUrl("missing-capture.png").toString())
            tryCompare(findChild(toast, "notificationImage"), "status", Image.Error)
            tryCompare(toast, "height", 52, 1500)
        }
        function test_history_image_opens_and_dismiss_does_not_open() {
            history.append({id: "capture-history", summary: "Captura de tela", body: "Salvo e copiado", app: "Velora screenshot",
                timeText: "13:45", imageSource: Qt.resolvedUrl("notification-preview.svg").toString(), actionable: true})
            tryVerify(() => findChild(panel, "notificationCard-capture-history") !== null)
            const card = findChild(panel, "notificationCard-capture-history")
            const image = findChild(card, "notificationImage")
            tryCompare(image, "status", Image.Ready)
            verify(image.y >= 76 && card.height > 230)
            mouseClick(card, card.width / 2, 140)
            compare(historyClicks.count, 1)
            compare(historyClicks.signalArguments[0][0], "capture-history")
            card.forceActiveFocus(); keyClick(Qt.Key_Space)
            compare(historyClicks.count, 2)
            mouseClick(findChild(card, "notificationDismiss-capture-history"))
            compare(dismisses.count, 1)
            compare(historyClicks.count, 2)
            history.setProperty(0, "imageSource", "")
            tryCompare(card, "height", 76)
        }
    }
}
