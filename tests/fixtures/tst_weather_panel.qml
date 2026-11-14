import QtQuick
import QtTest
import "../../components" as Components

Item {
    id: fixture
    width: 388; height: 374
    property string artifactPath: ""
    Rectangle { anchors.fill: parent; color: "#20282e"; radius: 18 }
    QtObject { id: tokens; property bool reduced: true; property real pace: 1 }
    QtObject {
        id: theme
        property color textPrimary: "#eef2f6"
        property color textSecondary: "#b1bfc8"
        property color accent: "#c2d5de"
        property string bodyFont: "DejaVu Sans"
        property bool motionEnabled: true
    }
    QtObject {
        id: weather
        property string temperature: "24"
        property string maximum: "27"
        property string minimum: "18"
        property string feelsLike: "25"
        property string description: "Parcialmente nublado"
        property string iconName: "partly"
        property string location: "São Paulo, SP"
        property string humidity: "68"
        property string rain: "0"
        property string wind: "12"
        property string error: ""
        property bool refreshing: false
        property int refreshCalls: 0
        property var hourly: []
        property var forecast: []
        function refresh(force) { if (force) refreshCalls++; refreshing = true }
    }
    Components.VeloraWeatherTopPanel {
        id: panel
        x: 10; y: 10; width: 368; height: 354
        theme: theme; weather: weather; motionTokens: tokens
    }
    SignalSpy { id: activated; target: panel; signalName: "activated" }
    SignalSpy { id: close; target: panel; signalName: "closeRequested" }
    TestCase {
        name: "WeatherPanel"
        when: windowShown
        function hourly() {
            return Array.from({length: 8},(_,i) => ({time: i === 0 ? "Agora" : String((12+i*3)%24).padStart(2,"0")+":00",
                temp: 18+i, rain: i*10, wind: 20-i}))
        }
        function init() {
            tokens.reduced = true; theme.motionEnabled = true; panel.open = false
            panel.width = 368; panel.metric = 0; panel.fahrenheit = false
            weather.hourly = hourly()
            weather.forecast = Array.from({length:4},(_,i) => ({date:"2026-10-"+(15+i),label:i===0?"Hoje":"",max:27+i,min:18,icon:["partly","rain","storm","snow"][i]}))
            weather.refreshing = false; weather.refreshCalls = 0
            activated.clear(); close.clear()
            wait(20)
        }
        function open() { panel.open = true; wait(20) }
        function inside(item) {
            const p = item.mapToItem(panel,0,0)
            verify(p.x >= 15.9 && p.x+item.width <= panel.width-15.9,"Control clipped horizontally: "+item.objectName)
            verify(p.y >= 15.9 && p.y+item.height <= panel.height-15.9,"Control clipped vertically: "+item.objectName)
        }
        function test_compact_content_keeps_all_controls_and_days_inside() {
            open()
            compare(panel.width,368); compare(panel.height,354)
            for(const width of [312,336,368]) {
                panel.width = width; wait(20)
                for(const name of ["weatherSummary","weatherUnit","weatherRefresh","weatherMetric0","weatherMetric1","weatherMetric2","weatherChart","weatherForecast","weatherDay0","weatherDay3"])
                    inside(findChild(panel,name))
            }
        }
        function test_metric_retarget_preserves_curve_and_hidden_work_stops() {
            open(); tokens.reduced = false
            const chart = findChild(panel,"weatherChart")
            panel.metric = 1; wait(65)
            verify(chart.animating)
            const current = chart.currentPositions()
            panel.metric = 2
            const next = chart.currentPositions()
            for(let i=0;i<current.length;i++) fuzzyCompare(current[i],next[i],.001)
            tryCompare(chart,"animating",false,500)
            panel.metric = 0; wait(40); panel.open = false
            compare(chart.animating,false)
            const ended = chart.progress; wait(100); compare(chart.progress,ended)
            panel.open = true; tokens.reduced = true; panel.metric = 1
            compare(chart.animating,false)
        }
        function test_missing_observations_zero_and_units() {
            open()
            const chart = findChild(panel,"weatherChart")
            weather.hourly = [{time:"00:00",temp:0,rain:0,wind:0},{time:"03:00",temp:"--",rain:"--",wind:""},{time:"06:00",temp:-2,rain:100,wind:12}]
            compare(chart.label(weather.hourly[0]),"0°")
            compare(chart.toY[1],null)
            panel.fahrenheit = true
            compare(chart.label(weather.hourly[0]),"32°")
            compare(panel.temperature(-10),"14")
            panel.metric = 1
            compare(chart.label(weather.hourly[0]),"0%")
            compare(chart.label(weather.hourly[1]),"—")
            compare(panel.measurement("","%"),"—")
            weather.hourly = [{temp:"--"}]
            verify(!chart.hasValues)
        }
        function test_controls_refresh_hour_selection_and_keyboard() {
            open()
            const metric = findChild(panel,"weatherMetric1")
            mouseClick(metric,14,14)
            compare(panel.metric,1); compare(activated.count,1)
            const unit = findChild(panel,"weatherUnit")
            mouseClick(unit,16,14); compare(panel.fahrenheit,true)
            mouseClick(unit,16,14); compare(panel.fahrenheit,false)
            const refresh = findChild(panel,"weatherRefresh")
            mouseClick(refresh,14,14); compare(weather.refreshCalls,1); verify(!refresh.enabled)
            mouseClick(refresh,14,14); compare(weather.refreshCalls,1)
            const chart = findChild(panel,"weatherChart")
            chart.forceActiveFocus(); keyClick(Qt.Key_Right); compare(chart.selected,1)
            keyClick(Qt.Key_End); compare(chart.selected,7)
            keyClick(Qt.Key_Home); compare(chart.selected,0)
            keyClick(Qt.Key_Escape); compare(close.count,1)
        }
        function test_preview() {
            if(!fixture.artifactPath) return
            open(); wait(80)
            let saved = false
            fixture.grabToImage(result => { saved = result.saveToFile(fixture.artifactPath) })
            tryVerify(() => saved,2000)
        }
    }
}
