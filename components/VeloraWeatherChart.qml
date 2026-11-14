pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property var hours: []
    property int metric: 0
    property bool fahrenheit: false
    property bool reducedMotion: false
    property bool presented: false
    property color ink: "white"
    property color muted: "#bac5ce"
    property color accent: ink
    property string uiFont: "Sans Serif"
    property string emptyText: "Previsão indisponível"
    property int selectedIndex: 0
    property var fromY: []
    property var toY: []
    property real progress: 1
    readonly property bool animating: transition.running
    readonly property bool interactionHeld: pointer.pressed
    readonly property bool hasValues: toY.some(value => value !== null)
    readonly property int selected: Math.max(0,Math.min(hours.length - 1,selectedIndex))
    readonly property var selectedHour: hours[selected] || ({})
    readonly property var plotted: currentPositions()
    signal interactionRequested()
    activeFocusOnTab: true
    Accessible.role: Accessible.Graphic
    Accessible.name: ["Temperatura","Chance de chuva","Vento"][metric] + " por hora"
    Accessible.description: (selectedHour.time || "") + " · " + label(selectedHour)

    function value(entry) {
        const v = entry ? entry[["temp","rain","wind"][metric]] : undefined
        return v === undefined || v === null || String(v).trim() === "" ? NaN : Number(v)
    }
    function label(entry) {
        const n = value(entry)
        if (!isFinite(n)) return "—"
        return metric === 0 ? Math.round(fahrenheit ? n * 9 / 5 + 32 : n) + "°"
            : Math.round(n) + (metric === 1 ? "%" : " km/h")
    }
    function positions() {
        const values = hours.map(entry => value(entry))
        const valid = values.filter(n => isFinite(n))
        if (!valid.length) return values.map(() => null)
        const low = metric === 1 ? 0 : Math.min.apply(null,valid) - 1
        const high = metric === 1 ? 100 : Math.max.apply(null,valid) + 1
        const span = Math.max(2,high - low)
        return values.map(n => isFinite(n) ? .12 + .76 * (high - n) / span : null)
    }
    function currentPositions() {
        return toY.map((target,i) => {
            const previous = fromY[i]
            return target === null ? null : previous === null || previous === undefined ? target
                : previous + (target - previous) * progress
        })
    }
    function retarget() {
        const previous = currentPositions()
        transition.stop()
        fromY = previous
        toY = positions()
        if (reducedMotion || !presented || previous.length !== toY.length) {
            fromY = toY; progress = 1
        } else { progress = 0; transition.start() }
        if (presented) graph.requestPaint()
    }
    function choose(index) {
        selectedIndex = Math.max(0,Math.min(hours.length - 1,index))
        interactionRequested()
    }
    onHoursChanged: retarget()
    onMetricChanged: retarget()
    onReducedMotionChanged: retarget()
    onPresentedChanged: retarget()
    onProgressChanged: if (presented) graph.requestPaint()
    onAccentChanged: if (presented) graph.requestPaint()
    Component.onCompleted: retarget()
    NumberAnimation { id: transition; target: root; property: "progress"; to: 1; duration: 240; easing.type: Easing.InOutCubic }
    Keys.onLeftPressed: choose(selected - 1)
    Keys.onRightPressed: choose(selected + 1)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) choose(0)
        else if (event.key === Qt.Key_End) choose(hours.length - 1)
        else event.accepted = false
    }
    Item {
        id: plot
        width: parent.width; height: Math.max(0,parent.height - 22)
        Canvas {
            id: graph
            anchors.fill: parent
            antialiasing: true
            onWidthChanged: if (root.presented) requestPaint()
            onHeightChanged: if (root.presented) requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                const values = root.plotted
                let start = 0
                while (start < values.length) {
                    while (start < values.length && values[start] === null) start++
                    let end = start
                    while (end < values.length && values[end] !== null) end++
                    if (start === end) break
                    const x = i => (i + .5) * width / values.length
                    function curve() {
                        c.beginPath(); c.moveTo(x(start),values[start] * height)
                        for(let i=start+1;i<end;i++) {
                            const mid = (x(i-1) + x(i)) / 2
                            c.bezierCurveTo(mid,values[i-1] * height,mid,values[i] * height,x(i),values[i] * height)
                        }
                    }
                    curve()
                    c.lineTo(x(end-1),height); c.lineTo(x(start),height); c.closePath()
                    const fill = c.createLinearGradient(0,0,0,height)
                    fill.addColorStop(0,Qt.rgba(root.accent.r,root.accent.g,root.accent.b,.15))
                    fill.addColorStop(1,Qt.rgba(root.accent.r,root.accent.g,root.accent.b,0))
                    c.fillStyle = fill; c.fill()
                    curve(); c.strokeStyle = root.accent; c.lineWidth = 1.5; c.lineCap = "round"; c.stroke()
                    if(end-start === 1) { c.beginPath(); c.arc(x(start),values[start] * height,2,0,Math.PI*2); c.fillStyle = root.accent; c.fill() }
                    start = end
                }
            }
        }
        Item {
            visible: root.hasValues && root.plotted[root.selected] !== null
            x: (root.selected + .5) * plot.width / Math.max(1,root.hours.length)
            width: 1; height: plot.height
            Rectangle { width: 1; height: parent.height; color: root.ink; opacity: .12 }
            Rectangle {
                x: -2.5; y: (root.plotted[root.selected] || 0) * plot.height - 2.5
                width: 5; height: 5; radius: 3; color: root.ink
            }
        }
        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.presented && root.hours.length > 0
            function at(x) { return Math.floor(x / Math.max(1,width) * root.hours.length) }
            onPositionChanged: mouse => root.selectedIndex = Math.max(0,Math.min(root.hours.length-1,at(mouse.x)))
            onClicked: mouse => { root.choose(at(mouse.x)); root.forceActiveFocus() }
        }
    }
    Row {
        y: parent.height - 16; width: parent.width
        Repeater {
            model: root.hours
            Text {
                required property int index
                required property var modelData
                width: root.width / Math.max(1,root.hours.length)
                text: width < 32 && index % 2 ? "" : String(modelData.time || "—").replace(":00","h")
                color: index === root.selected ? root.ink : root.muted
                font.family: root.uiFont; font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
            }
        }
    }
    Text {
        anchors.centerIn: plot; width: root.width - 20; visible: !root.hasValues
        text: root.emptyText; color: root.muted; font.family: root.uiFont; font.pixelSize: 11
        maximumLineCount: 2; elide: Text.ElideRight
        wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
    }
}
