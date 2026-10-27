import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool active: false
    property var weather: ({})
    property string error: ""
    readonly property bool refreshing: weatherProcess.running

    readonly property string helper: Quickshell.shellDir
        + "/scripts/velora-weather-state"
    function reading(value) { return value === undefined || value === null || String(value).trim() === "" ? "--" : String(value) }
    readonly property bool available: temperature !== "--" && isFinite(Number(temperature))
    readonly property string temperature: reading(weather.temp)
    readonly property string maximum: reading(weather.max)
    readonly property string minimum: reading(weather.min)
    readonly property string feelsLike: reading(weather.feels)
    readonly property string description: String(weather.desc || "Clima indisponível")
    readonly property string iconName: String(weather.icon || "partly")
    readonly property var forecast: Array.isArray(weather.daily)
        ? weather.daily.slice(0, 4)
        : (Array.isArray(weather.forecast) ? weather.forecast.slice(0, 4) : [])
    readonly property var hourly: Array.isArray(weather.hourly)
        ? weather.hourly.slice(0, 8) : []
    readonly property string humidity: reading(weather.humidity)
    readonly property string wind: reading(weather.wind)
    readonly property string rain: reading(weather.rain)
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
