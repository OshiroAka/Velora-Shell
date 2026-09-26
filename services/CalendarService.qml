import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var config
    property bool active: true
    property var externalEvents: []
    property var sources: []
    property string error: ""
    property string processOutput: ""
    readonly property var events: mergeEvents()

    function clone(value) { return JSON.parse(JSON.stringify(value)) }

    function mergeEvents() {
        const merged = Array.isArray(externalEvents) ? clone(externalEvents) : []
        const reminders = Array.isArray(config.calendarReminders)
            ? config.calendarReminders : []
        for (let index = 0; index < reminders.length; index += 1) {
            const item = Object.assign({}, reminders[index], {
                source: "velora", readOnly: false
            })
            merged.push(item)
        }
        merged.sort(function(first, second) {
            return String(first.start).localeCompare(String(second.start))
        })
        return merged
    }

    function dateKey(value) {
        return String(value || "").slice(0, 10)
    }

    function eventsForDate(year, month, day) {
        const key = Number(year).toString().padStart(4, "0") + "-"
            + (Number(month) + 1).toString().padStart(2, "0") + "-"
            + Number(day).toString().padStart(2, "0")
        return events.filter(function(item) { return dateKey(item.start) === key })
    }

    function addReminder(title, start, end, allDay, notes) {
        const next = clone(config.calendarReminders || [])
        next.push({ id: "reminder-" + Date.now(), title: String(title || "Lembrete"),
            start: String(start || ""), end: String(end || ""),
            allDay: Boolean(allDay), notes: String(notes || ""),
            color: "#8ca8ff", completed: false, repeat: "none" })
        return config.setCalendarReminders(next)
    }

    function removeReminder(identifier) {
        const next = (config.calendarReminders || []).filter(function(item) {
            return String(item.id) !== String(identifier)
        })
        return config.setCalendarReminders(next)
    }

    function reload() {
        if (active && !reader.running) {
            processOutput = ""
            reader.running = true
        }
    }

    onActiveChanged: {
        if (active)
            reload()
    }

    Process {
        id: reader
        command: [Quickshell.shellDir + "/scripts/velora-calendar-state"]
        running: false
        stdout: SplitParser { onRead: function(line) { root.processOutput += line } }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.error = "calendar reader exited with " + exitCode
                return
            }
            try {
                const document = JSON.parse(root.processOutput || "{}")
                root.externalEvents = Array.isArray(document.events) ? document.events : []
                root.sources = Array.isArray(document.sources) ? document.sources : []
                root.error = String(document.error || "")
            } catch (parseError) {
                root.error = String(parseError)
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.reload()
    }
}
