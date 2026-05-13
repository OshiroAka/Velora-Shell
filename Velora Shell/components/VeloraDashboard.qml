import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

Item {
    id: root

    property var theme: null
    property alias panelMaskItem: panelSurface
    readonly property int cornerRadius: 22
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.43, 0.35, 0.52, 0.88)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.56, 0.47, 0.63, 0.66)
    readonly property color inkFaint: theme ? theme.textMuted : Qt.rgba(0.58, 0.50, 0.66, 0.42)
    readonly property color pink: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.86, 0.45, 0.66, 0.86)
    readonly property color pinkSoft: theme ? theme.activeBg : Qt.rgba(0.94, 0.67, 0.80, 0.44)
    readonly property color lilac: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.62, 0.49, 0.74, 0.82)
    readonly property color glass: theme ? theme.surfacePopup : Qt.rgba(1.0, 0.988, 0.998, 0.90)
    readonly property color cardGlass: theme ? theme.surfaceCard : Qt.rgba(1, 1, 1, 0.78)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.82)
    readonly property string uiFont: "Noto Sans CJK JP"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property var forecastDays: [
        { day: "火", icon: "suncloud", high: "22°", low: "14°" },
        { day: "水", icon: "cloud", high: "23°", low: "15°" },
        { day: "木", icon: "suncloud", high: "24°", low: "16°" },
        { day: "金", icon: "sun", high: "25°", low: "17°" },
        { day: "土", icon: "cloud", high: "22°", low: "14°" }
    ]

    property date now: new Date()
    property string weatherCity: "Sao Paulo"
    property string weatherTemp: "22°C"
    property string weatherDesc: "くもり時々晴れ"
    property string weatherHumidity: "60%"
    property string weatherWind: "12 km/h"
    property string weatherFeels: "22°C"
    property int cpuPercent: 23
    property int ramPercent: 41
    property int storagePercent: 58
    property string uptimeText: "2h 14m"
    property string cpuDetail: "2.4 GHz"
    property string ramDetail: "6.5 GB / 16 GB"
    property string storageDetail: "372 GB / 640 GB"
    property string networkText: "98 Mbps"
    property string batteryText: "100%"
    property string mediaTitle: "夜明けの鈴聲"
    property string mediaArtist: "yuikonnu"
    property string mediaArt: ""
    property string mediaPositionText: "1:45"
    property string mediaDurationText: "4:12"
    property real mediaPositionSeconds: 105
    property real mediaDurationSeconds: 252
    property real mediaSampleMs: 0
    property real mediaProgress: 0.42
    property bool mediaPlaying: true
    property string mediaPlayer: ""
    property string mediaActionCommand: ""
    property bool compact: false
    property string activeSection: "weather"
    signal themeRequested()

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    readonly property string statsCommand: "read -r up _ < /proc/uptime; up=${up%.*}; d=$((up/86400)); h=$(((up%86400)/3600)); m=$(((up%3600)/60)); if [ \"$d\" -gt 0 ]; then uptime=\"${d}d ${h}h\"; elif [ \"$h\" -gt 0 ]; then uptime=\"${h}h ${m}m\"; else uptime=\"${m}m\"; fi; read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ < /proc/stat; t1=$((u1+n1+s1+i1+w1+irq1+sirq1+st1)); idle1=$((i1+w1)); sleep 0.2; read -r _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ < /proc/stat; t2=$((u2+n2+s2+i2+w2+irq2+sirq2+st2)); idle2=$((i2+w2)); dt=$((t2-t1)); di=$((idle2-idle1)); cpu=$((dt>0 ? (100*(dt-di)/dt) : 0)); ram=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf \"%d|%.1f GB / %.0f GB\", (total-avail)*100/total, (total-avail)/1048576, total/1048576}' /proc/meminfo); disk=$(df -hP / 2>/dev/null | awk 'NR==2 {gsub(\"%\",\"\",$5); printf \"%s|%s / %s\", $5, $3, $2; exit}'); clock=$(awk -F: '/cpu MHz/ {printf \"%.1f GHz\", $2/1000; exit}' /proc/cpuinfo); net=$(awk 'NR>2 {rx+=$2; tx+=$10} END {printf \"%.0f Mbps\", (rx+tx)/1024/1024}' /proc/net/dev); batt=$(upower -i $(upower -e 2>/dev/null | grep BAT | head -1) 2>/dev/null | awk '/percentage/ {print $2; exit}'); printf '%s|%s|%s|%s|%s|%s|%s|%s\\n' \"$uptime\" \"${cpu:-0}\" \"$ram\" \"$disk\" \"${clock:-2.4 GHz}\" \"${net:-98 Mbps}\" \"${batt:-100%}\""
    readonly property string weatherCommand: "if command -v curl >/dev/null 2>&1; then curl -fsS --max-time 3 'https://wttr.in/?format=%l|%t|%C|%h|%w|%f&lang=ja' 2>/dev/null || true; fi"
    readonly property string mediaCommand: "players=$(playerctl -l 2>/dev/null || true); pick=\"\"; for p in $players; do state=$(playerctl -p \"$p\" status 2>/dev/null || true); if [ \"$state\" = \"Playing\" ]; then pick=\"$p\"; break; fi; done; if [ -z \"$pick\" ]; then pick=$(printf '%s\\n' \"$players\" | sed -n '1p'); fi; [ -z \"$pick\" ] && exit 0; title=$(playerctl -p \"$pick\" metadata title 2>/dev/null || true); artist=$(playerctl -p \"$pick\" metadata artist 2>/dev/null || true); length=$(playerctl -p \"$pick\" metadata mpris:length 2>/dev/null || true); art=$(playerctl -p \"$pick\" metadata mpris:artUrl 2>/dev/null || true); pos=$(playerctl -p \"$pick\" position 2>/dev/null || true); status=$(playerctl -p \"$pick\" status 2>/dev/null || true); printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$title\" \"$artist\" \"$length\" \"$art\" \"$pos\" \"$status\""

    function clampPercent(value) {
        return Math.max(0, Math.min(100, Number(value) || 0))
    }

    function formatMonth(date) {
        return date.getFullYear() + "年" + (date.getMonth() + 1) + "月"
    }

    function calendarCells(date) {
        const year = date.getFullYear()
        const month = date.getMonth()
        const first = new Date(year, month, 1)
        const days = new Date(year, month + 1, 0).getDate()
        const lead = first.getDay()
        const out = []

        for (let i = 0; i < lead; i += 1)
            out.push({ text: "", active: false, today: false })

        for (let day = 1; day <= days; day += 1)
            out.push({ text: String(day), active: true, today: day === date.getDate() })

        while (out.length < 42)
            out.push({ text: "", active: false, today: false })

        return out
    }

    function formatSeconds(value) {
        const total = Math.max(0, Math.floor(Number(value) || 0))
        const minutes = Math.floor(total / 60)
        const seconds = total % 60
        return minutes + ":" + String(seconds).padStart(2, "0")
    }

    function updateMediaClock() {
        let position = mediaPositionSeconds

        if (mediaPlaying && mediaSampleMs > 0)
            position += Math.max(0, (Date.now() - mediaSampleMs) / 1000)

        if (mediaDurationSeconds > 0)
            position = Math.min(position, mediaDurationSeconds)

        mediaPositionText = formatSeconds(position)
        mediaDurationText = mediaDurationSeconds > 0 ? formatSeconds(mediaDurationSeconds) : "--:--"
        mediaProgress = mediaDurationSeconds > 0 ? Math.max(0, Math.min(1, position / mediaDurationSeconds)) : 0
    }

    function runMediaAction(action) {
        if (action.length === 0 || mediaAction.running)
            return

        mediaActionCommand = mediaPlayer.length > 0 ? "playerctl -p " + mediaPlayer + " " + action + " 2>/dev/null || true" : "playerctl " + action + " 2>/dev/null || true"
        mediaAction.running = true
    }

    function sectionTitle(section) {
        if (section === "weather")
            return "天気予報"
        if (section === "system")
            return "システム"
        if (section === "calendar")
            return "カレンダー"
        if (section === "media")
            return "メディアプレーヤー"
        if (section === "memo")
            return "メモ・リマインダー"
        if (section === "todo")
            return "アラーム・ToDo"
        return "Velora"
    }

    function sectionComponent(section) {
        if (section === "weather")
            return weatherSectionComponent
        if (section === "system")
            return systemSectionComponent
        if (section === "calendar")
            return calendarSectionComponent
        if (section === "media")
            return mediaSectionComponent
        if (section === "memo")
            return memoSectionComponent
        if (section === "todo")
            return todoSectionComponent
        return weatherSectionComponent
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsQuery.running)
                statsQuery.running = true
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!weatherQuery.running)
                weatherQuery.running = true
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!mediaQuery.running)
                mediaQuery.running = true
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateMediaClock()
    }

    Process {
        id: statsQuery

        running: false
        command: ["bash", "-lc", root.statsCommand]

        stdout: SplitParser {
            onRead: function(data) {
                const fields = data.trim().split("|")
                if (fields.length < 8)
                    return

                root.uptimeText = fields[0]
                root.cpuPercent = root.clampPercent(fields[1])
                root.ramPercent = root.clampPercent(fields[2])
                root.ramDetail = fields[3]
                root.storagePercent = root.clampPercent(fields[4])
                root.storageDetail = fields[5]
                root.cpuDetail = fields[6]
                root.networkText = fields[7]
                root.batteryText = fields.length > 8 && fields[8].length > 0 ? fields[8] : root.batteryText
            }
        }

        onExited: running = false
    }

    Process {
        id: weatherQuery

        running: false
        command: ["bash", "-lc", root.weatherCommand]

        stdout: SplitParser {
            onRead: function(data) {
                const fields = data.trim().split("|")
                if (fields.length < 6 || fields[1].length === 0)
                    return

                root.weatherCity = fields[0]
                root.weatherTemp = fields[1].replace("+", "")
                root.weatherDesc = fields[2]
                root.weatherHumidity = fields[3]
                root.weatherWind = fields[4]
                root.weatherFeels = fields[5].replace("+", "")
            }
        }

        onExited: running = false
    }

    Process {
        id: mediaQuery

        running: false
        command: ["bash", "-lc", root.mediaCommand]

        stdout: SplitParser {
            onRead: function(data) {
                const fields = data.trim().split("\t")
                if (fields.length < 6 || fields[0].length === 0)
                    return

                root.mediaTitle = fields[0]
                root.mediaArtist = fields[1] || "Unknown artist"
                root.mediaDurationSeconds = Math.max(0, Math.round((Number(fields[2]) || 0) / 1000000))
                root.mediaArt = fields[3] || ""
                root.mediaPositionSeconds = Math.max(0, Number(fields[4]) || 0)
                root.mediaPlaying = fields[5] === "Playing"
                root.mediaSampleMs = Date.now()
                root.updateMediaClock()
            }
        }

        onExited: running = false
    }

    Process {
        id: mediaAction

        running: false
        command: ["bash", "-lc", root.mediaActionCommand]
        onExited: {
            running = false
            if (!mediaQuery.running)
                mediaQuery.running = true
        }
    }

    Rectangle {
        x: panelSurface.x + 9
        y: panelSurface.y + 14
        width: panelSurface.width - 8
        height: panelSurface.height - 8
        radius: root.cornerRadius + 2
        color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.60, 0.36, 0.52, 1), 0.075)
        layer.enabled: true
        layer.effect: FastBlur { radius: 14 }
    }

    Rectangle {
        id: panelSurface

        anchors.fill: parent
        radius: root.cornerRadius
        color: root.glass
        border.width: 1
        border.color: root.neon && root.theme ? root.theme.popupBorderGlow : root.borderSoft
        clip: true
        antialiasing: true
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: root.neon ? 46 : 50
            samples: root.neon ? 93 : 95
            horizontalOffset: 0
            verticalOffset: root.neon ? 0 : 14
            color: root.neon && root.theme ? root.alpha(root.theme.popupBorderGlow, root.theme.popupBorderGlow.a * 0.48) : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.44, 0.25, 0.40, 1), 0.095)
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.00; color: root.alpha(root.cardGlass, root.neon ? 0.28 : 0.58) }
                GradientStop { position: 0.55; color: root.alpha(root.cardGlass, root.neon ? 0.16 : 0.34) }
                GradientStop { position: 1.00; color: root.alpha(root.pink, root.neon ? 0.10 : 0.16) }
            }
        }
    }

    Item {
        anchors.fill: panelSurface
        visible: !root.compact

        RowLayout {
        anchors {
            fill: parent
            leftMargin: 25
            rightMargin: 25
            topMargin: 22
            bottomMargin: 22
        }

        spacing: 21

        DashboardColumn {
            title: "天気"
            Layout.preferredWidth: 300
            Layout.fillWidth: true
            Layout.fillHeight: true

            WeatherContent {}
        }

        DashboardColumn {
            title: "システム"
            Layout.preferredWidth: 342
            Layout.fillWidth: true
            Layout.fillHeight: true

            SystemContent {}
        }

        DashboardColumn {
            title: "カレンダー"
            Layout.preferredWidth: 246
            Layout.maximumWidth: 290
            Layout.fillWidth: true
            Layout.fillHeight: true

            CalendarContent {}
        }

        DashboardColumn {
            title: "メディア"
            Layout.preferredWidth: 270
            Layout.maximumWidth: 318
            Layout.fillWidth: true
            Layout.fillHeight: true

            MediaContent {}
        }

        DashboardColumn {
            title: "テーマ"
            Layout.preferredWidth: 268
            Layout.maximumWidth: 320
            Layout.fillWidth: true
            Layout.fillHeight: true

            ThemeContent {}
        }
        }
    }

    Item {
        id: compactView

        anchors.fill: panelSurface
        visible: root.compact

        ColumnLayout {
            anchors {
                fill: parent
                leftMargin: 18
                rightMargin: 18
                topMargin: 15
                bottomMargin: 16
            }

            spacing: 11

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.sectionTitle(root.activeSection)
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: root.pink
                }
            }

            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    z: 3
                    anchors.fill: parent
                    sourceComponent: root.sectionComponent(root.activeSection)
                }
            }
        }
    }

    Component { id: weatherSectionComponent; WeatherContent {} }
    Component { id: systemSectionComponent; SystemContent {} }
    Component { id: calendarSectionComponent; CalendarContent {} }
    Component { id: mediaSectionComponent; MediaContent {} }
    Component { id: memoSectionComponent; MemoContent {} }
    Component { id: todoSectionComponent; TodoContent {} }

    component DashboardColumn: Item {
        id: column

        default property alias content: contentHost.data
        property string title: ""

        ColumnLayout {
            anchors.fill: parent
            spacing: 11

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: column.title
                color: root.pink
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    id: contentHost

                    anchors.fill: parent
                }
            }
        }
    }

    component DashboardCard: Rectangle {
        id: card

        property bool hovered: cardHover.containsMouse

        radius: 14
        color: hovered ? root.alpha(root.cardGlass, root.neon ? 0.62 : 0.86) : root.cardGlass
        border.width: 1
        border.color: root.neon && root.theme ? root.alpha(root.theme.popupBorderGlow, root.theme.popupBorderGlow.a * (hovered ? 0.52 : 0.34)) : (hovered ? root.alpha(root.borderSoft, 0.92) : root.alpha(root.borderSoft, 0.70))
        clip: true
        antialiasing: true
        scale: hovered ? 1.006 : 1.0
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: card.hovered ? 24 : 18
            samples: card.hovered ? 49 : 37
            horizontalOffset: 0
            verticalOffset: card.hovered ? 9 : 5
            color: root.neon && root.theme ? root.theme.popupGlow : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.36, 0.20, 0.34, 1), card.hovered ? 0.12 : 0.065)
        }

        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors {
                fill: parent
                margins: 1
            }

            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.26)
        }

        MouseArea {
            id: cardHover

            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }
    }

    component WeatherContent: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors {
                fill: parent
                margins: 16
            }

            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                WeatherGlyph {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 58
                    iconName: "suncloud"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.weatherTemp
                        color: root.ink
                        font.family: root.monoFont
                        font.pixelSize: 31
                        font.weight: Font.Medium
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.weatherDesc
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                WeatherMetric { label: "湿度"; value: root.weatherHumidity }
                WeatherMetric { label: "風速"; value: root.weatherWind }
                WeatherMetric { label: "体感温度"; value: root.weatherFeels }
            }

            Hairline {}

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                Repeater {
                    model: root.forecastDays

                    ForecastItem {
                        Layout.fillWidth: true
                        day: modelData.day
                        iconName: modelData.icon
                        high: modelData.high
                        low: modelData.low
                    }
                }
            }
        }
    }

    component WeatherMetric: Item {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        Layout.preferredHeight: 36

        ColumnLayout {
            anchors.fill: parent
            spacing: 1

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: label
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: value
                color: root.ink
                font.family: root.monoFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    component ForecastItem: Item {
        id: forecast

        property string day: ""
        property string iconName: "cloud"
        property string high: ""
        property string low: ""

        Layout.preferredHeight: 54

        ColumnLayout {
            anchors.fill: parent
            spacing: 2

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: day
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            WeatherGlyph {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 25
                Layout.preferredHeight: 20
                iconName: forecast.iconName
                compact: true
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: high + "/" + low
                color: root.inkSoft
                font.family: root.monoFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }

    component SystemContent: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors {
                fill: parent
                margins: 16
            }

            spacing: 13

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                spacing: 14

                GaugeMeter {
                    Layout.fillWidth: true
                    label: "CPU"
                    value: root.cpuPercent
                    detail: root.cpuDetail
                }

                GaugeMeter {
                    Layout.fillWidth: true
                    label: "メモリ"
                    value: root.ramPercent
                    detail: root.ramDetail
                }

                GaugeMeter {
                    Layout.fillWidth: true
                    label: "ストレージ"
                    value: root.storagePercent
                    detail: root.storageDetail
                }
            }

            Hairline {}

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                SystemMetric { label: "アップタイム"; value: root.uptimeText }
                SystemMetric { label: "ネットワーク"; value: root.networkText }
                SystemMetric { label: "バッテリー"; value: root.batteryText }
            }
        }
    }

    component GaugeMeter: Item {
        id: meter

        property string label: ""
        property int value: 0
        property string detail: ""

        Layout.preferredHeight: 95

        ColumnLayout {
            anchors.fill: parent
            spacing: 5

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 70
                Layout.preferredHeight: 70

                GaugeRing {
                    anchors.fill: parent
                    value: meter.value / 100
                }

                Column {
                    anchors.centerIn: parent
                    spacing: -1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: meter.value + "%"
                        color: root.ink
                        font.family: root.monoFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: meter.label
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: meter.detail
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    component SystemMetric: Item {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: label
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: value
                color: root.ink
                font.family: root.monoFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    component CalendarContent: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }

            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 20
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.formatMonth(root.now)
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                Text {
                    text: "›"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 20
                    font.weight: Font.Medium
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: ["日", "月", "火", "水", "木", "金", "土"]

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: index === 0 ? root.pink : root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: root.calendarCells(root.now)

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.min(width, height) / 2
                        color: modelData.today ? root.pinkSoft : "transparent"
                        border.width: modelData.today ? 1 : 0
                        border.color: root.alpha(root.borderSoft, 0.66)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.text
                            color: modelData.today ? root.pink : (modelData.active ? root.ink : root.inkFaint)
                            font.family: root.monoFont
                            font.pixelSize: 11
                            font.weight: modelData.today ? Font.Bold : Font.Medium
                        }
                    }
                }
            }
        }
    }

    component MediaContent: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors {
                fill: parent
                leftMargin: 17
                rightMargin: 17
                topMargin: 15
                bottomMargin: 14
            }

            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 15

                Rectangle {
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 76
                    radius: 11
                    color: root.alpha(root.lilac, 0.20)
                    clip: true
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        radius: 16
                        samples: 33
                        horizontalOffset: 0
                        verticalOffset: 5
                        color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.36, 0.20, 0.34, 1), 0.10)
                    }

                    Image {
                        anchors.fill: parent
                        source: root.mediaArt.length > 0 ? root.mediaArt : Qt.resolvedUrl("../assets/dashboard-cover.png")
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 180
                        sourceSize.height: 180
                        smooth: true
                        mipmap: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        Layout.fillWidth: true
                        text: root.mediaTitle
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.mediaArtist
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }
            }

            ProgressLine {
                Layout.fillWidth: true
                value: root.mediaProgress
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.mediaPositionText
                    color: root.inkSoft
                    font.family: root.monoFont
                    font.pixelSize: 10
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.mediaDurationText
                    color: root.inkSoft
                    font.family: root.monoFont
                    font.pixelSize: 10
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 20

                Item { Layout.fillWidth: true }
                MediaButton { label: "◀"; action: "previous" }
                MediaButton { label: root.mediaPlaying ? "Ⅱ" : "▶"; action: "play-pause"; emphasized: true }
                MediaButton { label: "▶"; action: "next" }
                Item { Layout.fillWidth: true }
            }
        }
    }

    component MediaButton: Rectangle {
        id: button

        property string label: ""
        property string action: ""
        property bool emphasized: false
        property bool hovered: mouse.containsMouse

        Layout.preferredWidth: emphasized ? 52 : 31
        Layout.preferredHeight: emphasized ? 52 : 31
        radius: height / 2
        color: emphasized ? root.alpha(root.pink, 0.56) : root.alpha(root.lilac, hovered ? 0.13 : 0.04)
        scale: hovered ? 1.05 : 1.0
        border.width: emphasized ? 1 : 0
        border.color: root.alpha(root.borderSoft, 0.68)
        layer.enabled: emphasized
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 16
            samples: 33
            horizontalOffset: 0
            verticalOffset: 5
            color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.56, 0.30, 0.50, 1), 0.11)
        }

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.emphasized ? (root.theme ? root.theme.activeText : "white") : root.lilac
            font.family: root.uiFont
            font.pixelSize: button.emphasized ? 21 : 18
            font.weight: Font.Bold
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: button.action.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.runMediaAction(button.action)
        }
    }

    component ThemeContent: Item {
        anchors.fill: parent

        Rectangle {
            id: themeCard

            property bool hovered: themeMouse.containsMouse

            anchors {
                fill: parent
                margins: 8
            }

            radius: 15
            color: hovered ? root.alpha(root.cardGlass, 0.62) : root.alpha(root.pinkSoft, 0.42)
            border.width: 1
            border.color: hovered ? root.alpha(root.pink, 0.44) : root.alpha(root.borderSoft, 0.76)
            clip: true
            scale: hovered ? 1.012 : 1.0
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: themeCard.hovered ? 28 : 20
                samples: themeCard.hovered ? 57 : 41
                horizontalOffset: 0
                verticalOffset: themeCard.hovered ? 10 : 6
                color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.48, 0.24, 0.42, 1), themeCard.hovered ? 0.16 : 0.09)
            }

            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/dashboard-cover.png")
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 520
                sourceSize.height: 320
                smooth: true
                mipmap: true
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.00; color: root.alpha(root.cardGlass, themeCard.hovered ? 0.00 : 0.04) }
                    GradientStop { position: 0.56; color: root.alpha(root.cardGlass, 0.00) }
                    GradientStop { position: 1.00; color: root.alpha(root.pinkSoft, themeCard.hovered ? 0.68 : 0.80) }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: themeCard.hovered ? root.alpha(root.cardGlass, 0.12) : "transparent"
            }

            Rectangle {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 14
                }

                width: 30
                height: 30
                radius: 15
                color: root.pinkSoft
                border.width: 2
                border.color: root.alpha(root.borderSoft, 0.88)

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: root.theme ? root.theme.activeText : "white"
                    font.family: root.uiFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 16
                    rightMargin: 16
                    bottomMargin: 17
                }

                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: "Velora Pastel"
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "by Velora Team"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Row {
                    Layout.topMargin: 8
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Repeater {
                        model: 3

                        Rectangle {
                            width: index === 0 ? 7 : 5
                            height: 5
                            radius: 3
                            color: index === 0 ? root.pink : root.alpha(root.lilac, 0.24)
                        }
                    }
                }
            }

            MouseArea {
                id: themeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.themeRequested()
            }
        }
    }

    component MemoContent: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
                topMargin: 14
                bottomMargin: 14
            }

            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        { label: "今日も", value: "おつかれさま!" },
                        { label: "ゆっくり", value: "休もう" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 12
                        color: root.alpha(root.pinkSoft, index === 0 ? 0.58 : 0.36)
                        border.width: 1
                        border.color: root.alpha(root.borderSoft, 0.58)

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: root.inkSoft
                                font.family: root.uiFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: root.ink
                                font.family: root.uiFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            Hairline {}

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                MemoLine { text: "買い物リストを確認する" }
                MemoLine { text: "プレゼン資料を仕上げる" }
                MemoLine { text: "ジムに行く（19:00〜）" }
            }
        }
    }

    component MemoLine: RowLayout {
        property string text: ""

        Layout.fillWidth: true
        Layout.preferredHeight: 22
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 10
            Layout.preferredHeight: 10
            radius: 5
            color: "transparent"
            border.width: 1
            border.color: root.alpha(root.lilac, 0.58)
        }

        Text {
            Layout.fillWidth: true
            text: parent.text
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    component TodoContent: Item {
        anchors.fill: parent

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 15
                rightMargin: 15
                topMargin: 13
                bottomMargin: 13
            }

            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                AlarmRow { time: "07:00"; label: "朝の支度"; active: true }
                AlarmRow { time: "22:30"; label: "ストレッチ・読書"; active: false }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 8
                    color: root.alpha(root.pinkSoft, 0.30)
                    border.width: 1
                    border.color: root.alpha(root.borderSoft, 0.50)

                    Text {
                        anchors.centerIn: parent
                        text: "+ 新しいタスク"
                        color: root.pink
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: root.alpha(root.cardGlass, root.neon ? 0.26 : 0.46)
                border.width: 1
                border.color: root.alpha(root.borderSoft, 0.46)

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 12
                    }

                    spacing: 6

                    TodoLine { text: "レポートを提出する"; checked: false }
                    TodoLine { text: "部屋の掃除"; checked: false }
                    TodoLine { text: "読書を30分する"; checked: true }
                }
            }
        }
    }

    component AlarmRow: Rectangle {
        property string time: ""
        property string label: ""
        property bool active: false

        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: 10
        color: root.alpha(root.cardGlass, active ? 0.60 : 0.35)
        border.width: 1
        border.color: root.alpha(active ? root.pink : root.borderSoft, active ? 0.38 : 0.42)

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }

            spacing: 8

            Text {
                text: time
                color: root.ink
                font.family: root.monoFont
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: label
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 16
                radius: 8
                color: active ? root.alpha(root.pink, 0.58) : root.alpha(root.lilac, 0.18)

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    x: active ? parent.width - width - 2 : 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.alpha(root.borderSoft, 0.92)

                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    component TodoLine: RowLayout {
        property string text: ""
        property bool checked: false

        Layout.fillWidth: true
        Layout.preferredHeight: 24
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 13
            Layout.preferredHeight: 13
            radius: 3
            color: checked ? root.alpha(root.pink, 0.55) : "transparent"
            border.width: 1
            border.color: checked ? root.alpha(root.pink, 0.68) : root.alpha(root.lilac, 0.42)

            Text {
                anchors.centerIn: parent
                text: checked ? "✓" : ""
                color: root.theme ? root.theme.activeText : "white"
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        Text {
            Layout.fillWidth: true
            text: parent.text
            color: checked ? root.inkSoft : root.ink
            font.family: root.uiFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    component Hairline: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: root.alpha(root.lilac, 0.14)
    }

    component ProgressLine: Rectangle {
        property real value: 0

        Layout.preferredHeight: 7
        radius: 4
        color: root.alpha(root.lilac, 0.14)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.value))
            height: parent.height
            radius: parent.radius
            color: root.alpha(root.pink, 0.56)

            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }
    }

    component GaugeRing: Canvas {
        id: gauge

        property real value: 0.0

        onValueChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const r = s * 0.39
            const start = Math.PI * 0.76
            const end = Math.PI * 2.24
            const amount = Math.max(0, Math.min(1, value))

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineWidth = Math.max(5, s * 0.085)
            ctx.strokeStyle = "rgba(168, 137, 184, 0.14)"
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, end, false)
            ctx.stroke()

            const grad = ctx.createLinearGradient(0, 0, width, height)
            grad.addColorStop(0, "rgba(228, 143, 181, 0.78)")
            grad.addColorStop(1, "rgba(173, 143, 219, 0.82)")
            ctx.strokeStyle = grad
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + (end - start) * amount, false)
            ctx.stroke()
        }
    }

    component WeatherGlyph: Canvas {
        id: icon

        property string iconName: "suncloud"
        property bool compact: false

        onIconNameChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const line = compact ? Math.max(1.2, s * 0.075) : Math.max(2.0, s * 0.055)

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            function drawSun(x, y, r) {
                ctx.strokeStyle = "rgba(244, 176, 92, 0.74)"
                ctx.fillStyle = "rgba(255, 213, 128, 0.38)"
                ctx.lineWidth = line
                ctx.beginPath()
                ctx.arc(x, y, r, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = (i / 8) * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(x + Math.cos(a) * r * 1.45, y + Math.sin(a) * r * 1.45)
                    ctx.lineTo(x + Math.cos(a) * r * 1.86, y + Math.sin(a) * r * 1.86)
                    ctx.stroke()
                }
            }

            function drawCloud(x, y, w) {
                ctx.strokeStyle = "rgba(157, 136, 180, 0.70)"
                ctx.fillStyle = "rgba(255, 255, 255, 0.50)"
                ctx.lineWidth = line
                ctx.beginPath()
                ctx.moveTo(x - w * 0.34, y + w * 0.14)
                ctx.lineTo(x + w * 0.34, y + w * 0.14)
                ctx.quadraticCurveTo(x + w * 0.52, y + w * 0.12, x + w * 0.49, y - w * 0.05)
                ctx.quadraticCurveTo(x + w * 0.45, y - w * 0.22, x + w * 0.26, y - w * 0.17)
                ctx.quadraticCurveTo(x + w * 0.12, y - w * 0.38, x - w * 0.11, y - w * 0.24)
                ctx.quadraticCurveTo(x - w * 0.30, y - w * 0.17, x - w * 0.28, y + w * 0.01)
                ctx.quadraticCurveTo(x - w * 0.48, y + w * 0.03, x - w * 0.45, y + w * 0.13)
                ctx.quadraticCurveTo(x - w * 0.43, y + w * 0.14, x - w * 0.34, y + w * 0.14)
                ctx.fill()
                ctx.stroke()
            }

            if (iconName === "sun")
                drawSun(cx, cy, s * 0.20)
            else if (iconName === "cloud")
                drawCloud(cx, cy, s * 0.72)
            else {
                drawSun(cx + s * 0.18, cy - s * 0.19, s * 0.17)
                drawCloud(cx - s * 0.04, cy + s * 0.09, s * 0.72)
            }
        }
    }
}
