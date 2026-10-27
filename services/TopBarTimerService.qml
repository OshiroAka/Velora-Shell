import QtQuick
import Quickshell
import Quickshell.Io
import "../features/topbar/TimerState.js" as TimerState

Scope {
    id: root
    property double now: Date.now()
    property int duration: 25 * 60000
    property var countdown: ({ running: false, deadline: 0, remaining: 25 * 60000 })
    property var stopwatch: ({ running: false, startedAt: 0, elapsed: 0 })
    property bool finished: false
    // Explicit activity also preserves a pause in the very first millisecond.
    property bool engaged: false
    property bool loaded: false
    property bool reducedMotion: false
    property int alertDuration: 6000
    property real alertPhase: 1
    property bool alertWaveActive: false
    readonly property real alertStrength: alertWaveActive && !reducedMotion
        ? Math.min(1, alertPhase * 10) * Math.pow(1 - alertPhase, 1.4) * 0.62 : 0
    onFinishedChanged: if (finished && !alertWaveActive) startAlertWave()
    onReducedMotionChanged: {
        if (reducedMotion) {
            alertSpread.stop()
            alertWaveActive = false
            alertPhase = 1
        } else if (finished) startAlertWave()
    }
    property string notificationId: ""
    signal closeNotificationRequested(string id)
    property string saveError: ""
    readonly property double remaining: TimerState.remaining(countdown, now)
    readonly property double elapsed: TimerState.elapsed(stopwatch, now)
    readonly property string timerText: TimerState.format(remaining)
    readonly property string stopwatchText: TimerState.format(elapsed)
    readonly property string barText: engaged || countdown.running || finished ? timerText
        : stopwatch.running ? stopwatchText : ""
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME")
        || Quickshell.env("HOME") + "/.local/state") + "/velora-shell/topbar-clock.json"

    function save() {
        if (loaded) stateFile.setText(JSON.stringify({ version: 1, duration: duration,
            timer: countdown, stopwatch: stopwatch, finished: finished, engaged: engaged }) + "\n")
    }
    function startAlertWave() {
        if (reducedMotion) return
        alertWaveActive = true
        alertSpread.restart()
    }
    function setDuration(seconds) {
        const value = Number(seconds)
        if (!Number.isFinite(value) || value < 1 || value > 86400) return false
        duration = Math.round(value * 1000)
        resetTimer()
        return true
    }
    function toggleTimer() {
        now = Date.now()
        engaged = true
        if (countdown.running)
            countdown = { running: false, deadline: 0, remaining: remaining }
        else {
            closeCompletionNotification()
            const left = remaining > 0 ? remaining : duration
            countdown = { running: true, deadline: now + left, remaining: left }
            finished = false
        }
        save()
    }
    function resetTimer() {
        closeCompletionNotification()
        countdown = { running: false, deadline: 0, remaining: duration }
        finished = false
        engaged = false
        save()
    }
    function dismissAlert() {
        if (!finished) return false
        resetTimer()
        return true
    }
    function snoozeAlert() {
        if (!finished) return false
        closeCompletionNotification()
        now = Date.now()
        finished = false
        engaged = true
        duration = 600000
        countdown = { running: true, deadline: now + 600000, remaining: 600000 }
        save()
        return true
    }
    function closeCompletionNotification() {
        if (notificationId) closeNotificationRequested(notificationId)
        notificationId = ""
        completionNotification.running = false
    }
    function startDuration(seconds) {
        if (!setDuration(seconds)) return false
        toggleTimer()
        return true
    }
    function toggleStopwatch() {
        now = Date.now()
        stopwatch = stopwatch.running
            ? { running: false, startedAt: 0, elapsed: elapsed }
            : { running: true, startedAt: now, elapsed: stopwatch.elapsed }
        save()
    }
    function resetStopwatch() {
        stopwatch = { running: false, startedAt: 0, elapsed: 0 }
        save()
    }
    function tick() {
        now = Date.now()
        if (countdown.running && remaining <= 0) {
            countdown = { running: false, deadline: 0, remaining: 0 }
            finished = true
            engaged = true
            save()
            completionNotification.running = true
        }
    }
    // Exactly the charging wave's six-second spread and fading envelope.
    // Repeat only after the previous wave has fully dissipated.
    NumberAnimation {
        id: alertSpread
        target: root; property: "alertPhase"
        from: 0; to: 1; duration: root.alertDuration
        onFinished: {
            if (root.finished && !root.reducedMotion) restart()
            else root.alertWaveActive = false
        }
    }
    Process {
        id: completionNotification
        command: ["stdbuf", "-oL", "notify-send", "--app-name", "Velora · Temporizador", "--urgency", "critical",
            "--expire-time", "0", "--print-id", "--action", "dismiss=Desligar",
            "--action", "snooze=+10 min", "Tempo concluído", "Temporizador encerrado."]
        stdout: SplitParser {
            onRead: line => {
                const value = line.trim()
                if (/^[0-9]+$/.test(value)) {
                    root.notificationId = value
                    if (!root.finished) root.closeCompletionNotification()
                } else if (value === "dismiss") root.dismissAlert()
                else if (value === "snooze") root.snoozeAlert()
            }
        }
    }
    FileView {
        id: stateFile
        path: root.statePath
        atomicWrites: true
        printErrors: false
        onLoaded: {
            if (root.loaded) return
            try {
                const state = TimerState.normalize(JSON.parse(text()), Date.now())
                root.duration = state.duration
                root.countdown = state.timer
                root.stopwatch = state.stopwatch
                root.finished = state.finished
                root.engaged = state.engaged
            } catch (error) { console.warn("Top bar timer: invalid saved state") }
            root.loaded = true
            root.tick()
        }
        onLoadFailed: root.loaded = true
        onSaved: root.saveError = ""
        onSaveFailed: root.saveError = "Não foi possível salvar o timer"
    }
    Timer {
        interval: 1000
        running: root.countdown.running || root.stopwatch.running
        repeat: true
        onTriggered: root.tick()
    }
}
