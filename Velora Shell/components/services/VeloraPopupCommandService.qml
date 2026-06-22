import QtQuick
import Quickshell.Io

Item {
    id: root

    property string homeDir: ""
    property string pendingCommand: ""
    property string activeCommand: ""

    signal commandFinished()

    visible: false
    width: 0
    height: 0

    function runCommand(command) {
        if (!command || command.length <= 0)
            return

        pendingCommand = command
        commandDebounce.restart()
    }

    function runDetached(command) {
        if (!command || command.length <= 0)
            return

        runCommand(command + " >/dev/null 2>&1 &")
    }

    function shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\\''") + "'"
    }

    function openPath(path) {
        const target = String(path || "")
        if (target.length <= 0)
            return

        runDetached("xdg-open " + shellQuote(target))
    }

    function openUrl(url) {
        const target = String(url || "")
        if (target.length <= 0)
            return

        runDetached("(command -v zen-browser >/dev/null 2>&1 && zen-browser " + shellQuote(target) + " || xdg-open " + shellQuote(target) + ")")
    }

    function openSettings(module) {
        const suffix = String(module || "")
        var command = "if command -v systemsettings >/dev/null 2>&1; then systemsettings"
        if (suffix.length > 0)
            command += " " + suffix
        command += "; elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center"
        command += "; elif command -v nwg-look >/dev/null 2>&1; then nwg-look"
        command += "; fi"
        runDetached(command)
    }

    function openFileSearch() {
        runDetached("if command -v fsearch >/dev/null 2>&1; then fsearch; elif command -v dolphin >/dev/null 2>&1; then dolphin --new-window " + shellQuote(homeDir) + "; else xdg-open " + shellQuote(homeDir) + "; fi")
    }

    function openTrash() {
        runDetached("xdg-open trash:/// || xdg-open " + shellQuote(homeDir + "/.local/share/Trash/files"))
    }

    function browserSearch(queryText) {
        const query = String(queryText || "").trim().length > 0 ? String(queryText || "").trim() : "Velora Shell"
        openUrl("https://www.google.com/search?q=" + encodeURIComponent(query))
    }

    function browserCommand(action) {
        if (action === "new-window") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser --new-window about:newtab; else xdg-open about:blank; fi")
            return
        }
        if (action === "private") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser --private-window; elif command -v firefox >/dev/null 2>&1; then firefox --private-window; else xdg-open about:blank; fi")
            return
        }
        if (action === "downloads") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser about:downloads; else xdg-open " + shellQuote(homeDir + "/Downloads") + "; fi")
            return
        }
        if (action === "bookmarks") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser about:preferences#search; else xdg-open about:blank; fi")
            return
        }
        openUrl("about:newtab")
    }

    function openCalendarApp() {
        runDetached("if command -v kalendar >/dev/null 2>&1; then kalendar; elif command -v gnome-calendar >/dev/null 2>&1; then gnome-calendar; else xdg-open https://calendar.google.com; fi")
    }

    function openClockApp() {
        runDetached("if command -v kclock >/dev/null 2>&1; then kclock; elif command -v gnome-clocks >/dev/null 2>&1; then gnome-clocks; fi")
    }

    Timer {
        id: commandDebounce

        interval: 80
        repeat: false
        onTriggered: {
            if (commandRunner.running || root.pendingCommand.length <= 0)
                return

            root.activeCommand = root.pendingCommand
            commandRunner.command = ["bash", "-lc", root.activeCommand]
            commandRunner.running = true
        }
    }

    Process {
        id: commandRunner

        running: false
        command: ["bash", "-lc", ""]
        onExited: {
            running = false
            if (root.pendingCommand !== root.activeCommand)
                commandDebounce.restart()
            root.commandFinished()
        }
    }
}
