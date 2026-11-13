import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../features/topbar" as Topbar
import "../../services" as Services
import "../../core" as Core

ShellRoot {
    id: test
    property int step: 0
    property int attempts: 0
    property real previousStrength: 0
    property real previousPhase: 0
    property real hiddenGlowPhase: 0
    function check(value, message) { if (!value) throw Error(message) }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found = find(child, name); if (found) return found }
        return null
    }
    function expire() {
        timer.countdown = {running: true, deadline: Date.now() - 1, remaining: 0}
        timer.tick()
        timer.tick()
    }
    Services.TopBarTimerService { id: timer }
    Core.Motion { id: motion }
    QtObject { id: host; property var screen: ({name: "fixture"}) }
    Topbar.TopBarController { id: controller; motion: motion }
    QtObject {
        id: theme
        property string bodyFont: "Sans Serif"
        property color textPrimary: "#edf2f5"
        property color accent: "#94b6c1"
        property color accentSoft: "#94b6c1"
        property color danger: "#ef6675"
        function withAlpha(c, a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    Window {
        id: win; width: 500; height: 200; visible: true; color: "#1c252b"
        Topbar.ConnectedSurface {
            anchors.fill: parent
            fillColor: "#725b6f78"
            timerRect: alert.surfaceRect
            timerNeck: alert.neckHalfWidth
            timerRadius: alert.cornerRadius
            timerJoin: alert.joinRadius
            timerAnchor: alert.anchorX
            timerProgress: timer.alertPhase
            timerStrength: timer.alertStrength
        }
        Item { id: menuAnchor; x: 375; width: 74; height: 40 }
        Topbar.MorphPopover {
            id: menu
            anchors.fill: parent
            controller: controller; motion: motion
            desiredType: controller.owner === host ? controller.activeType : ""
        }
        Topbar.TimerAlertMorph {
            id: alert; theme: theme; service: timer; anchorX: 360
            reducedMotion: timer.reducedMotion
            suppressed: menu.mounted
        }
    }
    TestCase { id: input; name: "TimerAlertActions"; when: false }
    Timer {
        interval: 80; repeat: true; running: true
        onTriggered: {
            try {
                if (++test.attempts > 100) throw Error("Timer alert timed out")
                if (!timer.loaded) return
                const mode = Quickshell.env("VELORA_TIMER_ALERT_MODE")
                if (mode === "reload") {
                    test.check(timer.finished && timer.remaining === 0 && alert.visible, "Completion lost across reload")
                    test.check(timer.dismissAlert(), "Restored completion cannot be dismissed")
                    console.info("TIMER_ALERT_RELOAD_OK"); Qt.quit(); return
                }
                if (mode === "notification") {
                    if (test.step === 0) { timer.startDuration(1); test.expire(); test.step = 1; return }
                    if (timer.finished) return
                    test.check(timer.countdown.running && timer.remaining > 599000 && timer.remaining <= 600000,
                        "Notification action did not snooze by ten minutes")
                    console.info("TIMER_ALERT_NOTIFICATION_OK"); Qt.quit(); return
                }
                if (test.step === 0) {
                    test.check(!alert.visible && timer.alertStrength === 0, "Idle clock is pulsing")
                    test.check(timer.alertDuration === 6000, "Timer gradient must use the battery's six-second duration")
                    timer.alertDuration = 1000 // Shorten only this test's loop.
                    timer.startDuration(1)
                    test.check(!alert.visible, "Running timer expanded the alert early")
                    test.expire(); test.step = 1
                } else if (test.step === 1 && alert.reveal > 0.999 && timer.alertStrength > 0.1) {
                    test.check(timer.finished && !timer.countdown.running && timer.remaining === 0, "Completion state invalid")
                    test.check(alert.x + alert.width / 2 === alert.anchorX, "Morph lost the timer anchor")
                    for (const name of ["timerAlertDismiss", "timerAlertSnooze"]) {
                        const button = test.find(alert, name), p = button.mapToItem(alert, 0, 0)
                        test.check(p.x >= 0 && p.y >= 0 && p.x + button.width <= alert.width
                            && p.y + button.height <= alert.height, "Alert button is clipped")
                        test.check(button.width === button.height, "Timer controls must be circular")
                    }
                    test.check(alert.width <= 124 && alert.height <= 52, "Clock morph has excessive empty space")
                    test.check(alert.neckHalfWidth >= 40 && alert.joinRadius >= 14, "Clock morph still has a narrow connection")
                    test.previousStrength = timer.alertStrength
                    controller.show("thing", menuAnchor, host, false)
                    test.check(menu.mounted && !alert.visible && !alert.enabled && alert.surfaceRect.height === 0,
                        "Timer controls overlap the entering menu")
                    test.hiddenGlowPhase = test.find(alert, "timerAlertSnooze").glowPhase
                    test.previousPhase = timer.alertPhase; test.step = 10
                } else if (test.step === 10) {
                    test.check(timer.finished && timer.alertPhase !== test.previousPhase,
                        "Opening another menu stopped or dismissed the clock wave")
                    test.check(test.find(alert, "timerAlertSnooze").glowPhase === test.hiddenGlowPhase,
                        "Hidden timer buttons keep animating")
                    controller.close()
                    test.check(menu.mounted && !alert.visible, "Timer controls overlap the closing menu")
                    test.step = 11
                } else if (test.step === 11) {
                    if (menu.mounted || alert.reveal < 0.999) return
                    test.check(alert.visible && alert.enabled && timer.finished, "Clock controls did not return after the menu closed")
                    test.hiddenGlowPhase = test.find(alert, "timerAlertSnooze").glowPhase
                    test.step = 2
                } else if (test.step === 2) {
                    if (timer.alertPhase < 0.9) return
                    test.check(timer.alertStrength < test.previousStrength * 0.15,
                        "The timer wave does not lose force like the battery")
                    const expected = Math.min(1, timer.alertPhase * 10) * Math.pow(1 - timer.alertPhase, 1.4) * 0.62
                    test.check(Math.abs(timer.alertStrength - expected) < 0.000001,
                        "Timer and battery gradient intensity differ")
                    test.previousPhase = timer.alertPhase; test.step = 22
                } else if (test.step === 22) {
                    if (timer.alertPhase >= test.previousPhase) return
                    test.check(timer.alertPhase < 0.2 && alert.visible,
                        "Next wave must restart only after the previous one dissipates")
                    test.check(test.find(alert, "timerAlertSnooze").glowPhase !== test.hiddenGlowPhase,
                        "Visible timer buttons do not animate their glow")
                    timer.reducedMotion = true
                    test.check(timer.alertStrength === 0 && alert.visible,
                        "Reduced motion must match battery color policy and keep the actions")
                    timer.reducedMotion = false
                    const snooze = test.find(alert, "timerAlertSnooze")
                    const phase = timer.alertPhase
                    input.mouseClick(snooze, snooze.width / 2, snooze.height / 2)
                    test.check(!timer.finished && timer.countdown.running && timer.duration === 600000
                        && timer.remaining > 599000 && timer.remaining <= 600000, "Snooze button did not start ten minutes")
                    test.check(timer.alertWaveActive && timer.alertPhase === phase,
                        "Snooze cut off or restarted the current wave")
                    test.check(!timer.dismissAlert(), "A stale dismiss must not cancel the new timer")
                    test.previousPhase = phase
                    test.step = 3
                } else if (test.step === 3 && !alert.visible) {
                    test.check(timer.alertPhase >= test.previousPhase, "Snoozed wave restarted instead of finishing")
                    test.previousPhase = timer.alertPhase
                    if (timer.alertWaveActive) return
                    test.check(timer.alertPhase === 1 && timer.alertStrength === 0, "Snoozed wave did not dissipate")
                    test.step = 31
                } else if (test.step === 31) {
                    test.check(!timer.alertWaveActive && timer.alertPhase === 1, "Snooze allowed another wave")
                    test.expire(); test.step = 4
                } else if (test.step === 4 && alert.reveal > 0.999) {
                    const dismiss = test.find(alert, "timerAlertDismiss")
                    const phase = timer.alertPhase
                    input.mouseClick(dismiss, dismiss.width / 2, dismiss.height / 2)
                    test.check(!timer.finished && !timer.countdown.running,
                        "Dismiss button did not stop the alert")
                    test.check(timer.alertWaveActive && timer.alertPhase === phase && timer.alertStrength > 0,
                        "Stop cut off the current gradient instantly")
                    test.previousPhase = phase; test.step = 5
                } else if (test.step === 5 && !alert.visible) {
                    test.check(timer.alertPhase >= test.previousPhase, "Stopped wave restarted instead of finishing")
                    test.previousPhase = timer.alertPhase
                    if (timer.alertWaveActive) return
                    test.check(timer.alertPhase === 1 && timer.alertStrength === 0, "Stopped wave did not dissipate")
                    test.step = 51
                } else if (test.step === 51) {
                    test.check(!timer.alertWaveActive && timer.alertPhase === 1, "Stop allowed another wave")
                    test.expire() // Leave completion persisted for the next process.
                    test.step = 6
                } else if (test.step === 6 && alert.reveal > 0.999) {
                    const path = Quickshell.env("VELORA_TIMER_ALERT_SCREENSHOT")
                    if (path) win.contentItem.grabToImage(result => { result.saveToFile(path); console.info("TIMER_ALERT_OK"); Qt.quit() })
                    else { console.info("TIMER_ALERT_OK"); Qt.quit() }
                    test.step = 7
                }
            } catch (error) { console.error("TIMER_ALERT_FAILED", String(error), error.stack); Qt.quit() }
        }
    }
}
