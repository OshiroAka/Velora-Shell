pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int barH: 38
    property int pillH: 28
    property real pillOpacity: 0.72
    property real popupOpacity: 0.58
    property string fontFamily: "JetBrainsMono Nerd Font"

    property string settingsCategory: "bar"

    property string clockBg: ""
    property real clockBgOpacity: 0.22
    property real clockAccentBoost: 1.0

    property string mediaBg: ""
    property real mediaBgOpacity: 0.22

    property bool effectsEnabled: true
    property real motionStrength: 1.0
    property bool pywalActive: true
    property string weatherCity: "Guarulhos"

    function quote(s) {
        return "'" + ("" + s).replace(/'/g, "'\\''") + "'"
    }

    function applyConfig() {
        ShinConfig.barH = root.barH
        ShinConfig.pillH = root.pillH
        ShinConfig.pillOpacity = root.pillOpacity
        ShinConfig.popupOpacity = root.popupOpacity
        ShinConfig.fontFamily = root.fontFamily
        ShinConfig.weatherCity = root.weatherCity
        ShinColors.pywalActive = root.pywalActive
    }

    function setValue(key, value) {
        if (key === "barH") root.barH = parseInt(value)
        else if (key === "pillH") root.pillH = parseInt(value)
        else if (key === "pillOpacity") root.pillOpacity = Number(value)
        else if (key === "popupOpacity") root.popupOpacity = Number(value)
        else if (key === "fontFamily") root.fontFamily = value
        else if (key === "settingsCategory") root.settingsCategory = value
        else if (key === "clockBg") root.clockBg = value
        else if (key === "clockBgOpacity") root.clockBgOpacity = Number(value)
        else if (key === "clockAccentBoost") root.clockAccentBoost = Number(value)
        else if (key === "mediaBg") root.mediaBg = value
        else if (key === "mediaBgOpacity") root.mediaBgOpacity = Number(value)
        else if (key === "effectsEnabled") root.effectsEnabled = (value === true || value === "true" || value === "1")
        else if (key === "motionStrength") root.motionStrength = Number(value)
        else if (key === "pywalActive") root.pywalActive = (value === true || value === "true" || value === "1")
        else if (key === "weatherCity") root.weatherCity = value

        root.applyConfig()
    }

    function save(key, value) {
        root.setValue(key, value)

        saveProc.command = [
            "bash",
            "-lc",
            "~/.config/quickshell/shinbar/scripts/shinbar-data set " + key + " " + root.quote(value)
        ]

        if (!saveProc.running)
            saveProc.running = true
    }

    function reload() {
        if (!loadProc.running)
            loadProc.running = true
    }

    property Process loadProc: Process {
        running: false
        command: ["bash", "-lc", "~/.config/quickshell/shinbar/scripts/shinbar-data get"]

        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (!line || line.indexOf("=") < 0)
                    return

                var idx = line.indexOf("=")
                var key = line.slice(0, idx)
                var value = line.slice(idx + 1)

                root.setValue(key, value)
            }
        }

        onExited: {
            running = false
            root.applyConfig()
        }
    }

    property Process saveProc: Process {
        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Component.onCompleted: root.reload()
}
