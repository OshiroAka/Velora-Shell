import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool active: false
    property var weather: ({})
    property string error: ""

    readonly property string helper: Quickshell.shellDir
        + "/scripts/velora-weather-state"
    readonly property bool available: String(weather.temp || "").length > 0
    readonly property string temperature: String(weather.temp || "--")
    readonly property string maximum: String(weather.max || "--")
    readonly property string minimum: String(weather.min || "--")
    readonly property string feelsLike: String(weather.feels || "--")
    readonly property string description: String(weather.desc || "Clima indisponível")
    readonly property string iconName: String(weather.icon || "partly")
    readonly property var forecast: Array.isArray(weather.daily)
        ? weather.daily.slice(0, 4)
        : (Array.isArray(weather.forecast) ? weather.forecast.slice(0, 4) : [])
    readonly property var hourly: Array.isArray(weather.hourly)
        ? weather.hourly.slice(0, 8) : []
    readonly property string humidity: String(weather.humidity || "--")
    readonly property string wind: String(weather.wind || "--")
    readonly property string rain: String(weather.rain || "--")
    readonly property string location: String(weather.location || "")

    function refresh(force) {
        if (!active || weatherProcess.running)
            return false
        weatherProcess.command = force
            ? ["python3", helper, "--json", "--force"]
            : ["python3", helper, "--json"]
        weatherProcess.running = true
        return true
    }

    onActiveChanged: {
        if (active) {
            Qt.callLater(function() { root.refresh(false) })
            liveRefreshDelay.restart()
        } else if (weatherProcess.running) {
            weatherProcess.running = false
        }
    }

    Process {
        id: weatherProcess
        stdout: StdioCollector { id: weatherOutput }
        stderr: StdioCollector { id: weatherError }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.error = weatherError.text.trim() || "Clima indisponível"
                return
            }
            try {
                root.weather = JSON.parse(weatherOutput.text || "{}")
                root.error = ""
            } catch (parseError) {
                root.error = String(parseError)
            }
        }
    }

    Timer {
        id: liveRefreshDelay
        interval: 1500
        repeat: false
        onTriggered: root.refresh(true)
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.active
        onTriggered: root.refresh(true)
    }
}
