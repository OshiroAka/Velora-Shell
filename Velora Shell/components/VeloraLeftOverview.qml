import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "popups"

Item {
    id: root

    property var theme: null
    property bool open: visible
    property bool preload: false
    property bool externalSurface: true
    property bool interactiveFocus: false
    property string popupType: "overview"
    property string attachSide: "left"
    property var clockState: null
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaAlbum: ""
    property string mediaArt: ""
    property string mediaPositionText: "0:00"
    property string mediaDurationText: "--:--"
    property real mediaPositionSeconds: 0
    property real mediaDurationSeconds: 0
    property real mediaProgress: 0.0
    property bool mediaPlaying: false
    property string mediaPlayer: ""
    property string mediaActionCommand: ""
    property int cpuPercent: 0
    property int ramPercent: 0
    property int batteryPercent: 0
    property string batteryState: ""
    property var eventItems: []
    property var upcomingEventItems: []
    property bool hovered: false

    readonly property int cornerRadius: 22
    readonly property bool placeholderOnly: true
    readonly property bool backgroundPollingActive: open && visible && !placeholderOnly
    readonly property bool hasMedia: mediaTitle.length > 0 || mediaArtist.length > 0 || mediaPlayer.length > 0
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrains Mono"
    readonly property bool dark: theme ? theme.themeMode === "dark" : true
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.86, 0.76, 0.62, 1)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.72, 0.62, 0.50, 0.84)
    readonly property color inkMuted: theme ? theme.textMuted : Qt.rgba(0.66, 0.57, 0.46, 0.68)
    readonly property color accent: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.74, 0.55, 0.36, 1)
    readonly property color accent2: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.86, 0.66, 0.45, 1)
    readonly property color popupBubble: theme ? theme.popupBubbleSurface() : Qt.rgba(1, 1, 1, 0.70)
    readonly property color winCard: theme ? theme.alpha(popupBubble, dark ? 0.42 : 0.54) : Qt.rgba(0.12, 0.20, 0.29, 0.48)
    readonly property color winCardHover: theme ? theme.alpha(popupBubble, dark ? 0.58 : 0.72) : Qt.rgba(0.16, 0.26, 0.36, 0.62)
    readonly property color card: theme ? theme.alpha(winCard, 0.82) : Qt.rgba(0.18, 0.12, 0.07, 0.62)
    readonly property color cardHover: theme ? theme.alpha(winCardHover, 0.86) : Qt.rgba(0.24, 0.16, 0.09, 0.72)
    readonly property color cardSoft: theme ? theme.alpha(winCardHover, dark ? 0.52 : 0.62) : Qt.rgba(1, 1, 1, 0.18)
    readonly property color cardSoftLow: theme ? theme.alpha(winCardHover, dark ? 0.40 : 0.52) : Qt.rgba(1, 1, 1, 0.14)
    readonly property color line: theme ? theme.alpha(accent, 0.18) : Qt.rgba(0.95, 0.78, 0.55, 0.30)
    readonly property color fill: theme ? theme.alpha(accent, dark ? 0.34 : 0.38) : Qt.rgba(0.80, 0.60, 0.40, 0.58)
    readonly property string mediaCommand: "players=$(playerctl -l 2>/dev/null || true); pick=\"\"; for p in $players; do state=$(playerctl -p \"$p\" status 2>/dev/null || true); if [ \"$state\" = \"Playing\" ]; then pick=\"$p\"; break; fi; done; if [ -z \"$pick\" ]; then pick=$(printf '%s\\n' \"$players\" | sed -n '1p'); fi; [ -z \"$pick\" ] && { printf '\\t\\t\\t\\t0\\tStopped\\t\\n'; exit 0; }; title=$(playerctl -p \"$pick\" metadata title 2>/dev/null || true); artist=$(playerctl -p \"$pick\" metadata artist 2>/dev/null || true); album=$(playerctl -p \"$pick\" metadata album 2>/dev/null || true); length=$(playerctl -p \"$pick\" metadata mpris:length 2>/dev/null || true); art=$(playerctl -p \"$pick\" metadata mpris:artUrl 2>/dev/null || true); pos=$(playerctl -p \"$pick\" position 2>/dev/null || true); status=$(playerctl -p \"$pick\" status 2>/dev/null || true); printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$title\" \"$artist\" \"$album\" \"$length\" \"$art\" \"$pos\" \"$status\" \"$pick\""
    readonly property string systemCommand: "cpu=$(vmstat 1 2 2>/dev/null | tail -1 | awk '{ if (NF >= 15) printf \"%d\", 100 - $15; else printf \"0\" }'); ram=$(free 2>/dev/null | awk '/Mem:/ { if ($2 > 0) printf \"%d\", ($3 * 100) / $2; else printf \"0\" }'); bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1); state=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1); printf '%s|%s|%s|%s\\n' \"${cpu:-0}\" \"${ram:-0}\" \"${bat:-0}\" \"${state:-}\""
    readonly property string eventsScript: Quickshell.shellDir + "/scripts/velora-events-state"

    signal closeRequested()
    signal pointerInsideChanged(bool inside)
    signal mediaWindowRequested(real centerY)
    signal detailWindowRequested(string detailType, real centerY)
    signal agendaRequested(real centerY)
    signal settingsRequested(real centerY)

    opacity: open ? 1 : 0

    function alpha(colorValue, opacityValue) {
        return root.theme ? root.theme.alpha(colorValue, opacityValue) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacityValue)
    }

    function shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\\''") + "'"
    }

    function runMediaAction(action) {
        if (!action || action.length <= 0 || mediaAction.running)
            return
        mediaActionCommand = mediaPlayer.length > 0
            ? "playerctl -p " + shellQuote(mediaPlayer) + " " + action + " 2>/dev/null || true"
            : "playerctl " + action + " 2>/dev/null || true"
        mediaAction.running = true
    }

    function formatSeconds(seconds) {
        const safe = Math.max(0, Math.round(Number(seconds) || 0))
        const m = Math.floor(safe / 60)
        const s = safe % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function refreshMediaPosition() {
        mediaPositionText = formatSeconds(mediaPositionSeconds)
        mediaDurationText = mediaDurationSeconds > 0 ? formatSeconds(mediaDurationSeconds) : "--:--"
        mediaProgress = mediaDurationSeconds > 0 ? Math.max(0, Math.min(1, mediaPositionSeconds / mediaDurationSeconds)) : 0
    }

    function greetingText() {
        const hour = new Date().getHours()
        if (hour < 12)
            return "Bom dia"
        if (hour < 18)
            return "Boa tarde"
        return "Boa noite"
    }

    function longDate() {
        const d = new Date()
        const weekdays = ["dom", "seg", "ter", "qua", "qui", "sex", "sab"]
        const months = ["janeiro", "fevereiro", "marco", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]
        return weekdays[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()]
    }

    function monthLabel() {
        const d = new Date()
        const months = ["Janeiro", "Fevereiro", "Marco", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
        return months[d.getMonth()] + " " + d.getFullYear()
    }

    function calendarDay(slot) {
        const d = new Date()
        const first = new Date(d.getFullYear(), d.getMonth(), 1)
        const count = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
        const start = first.getDay()
        const day = slot - start + 1
        return day >= 1 && day <= count ? day : ""
    }

    function pad2(value) {
        const number = Math.max(0, Number(value) || 0)
        return number < 10 ? "0" + number : "" + number
    }

    function todayIso() {
        const d = new Date()
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
    }

    function calendarDateForSlot(slot) {
        const day = calendarDay(slot)
        if (day === "")
            return ""
        const d = new Date()
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(day)
    }

    function eventCountForDate(date) {
        if (!date || date.length <= 0)
            return 0
        let count = 0
        for (let i = 0; i < eventItems.length; ++i) {
            if (String(eventItems[i].date || "") === date)
                count += 1
        }
        return count
    }

    function eventIconForCategory(category) {
        const value = String(category || "").toLowerCase()
        if (value.indexOf("trabalho") >= 0 || value.indexOf("projeto") >= 0)
            return "box"
        if (value.indexOf("estudo") >= 0 || value.indexOf("leitura") >= 0)
            return "memo"
        if (value.indexOf("saude") >= 0)
            return "heart"
        return "calendar"
    }

    function normalizeOverviewEvent(item, index) {
        const source = item || {}
        const date = String(source.date || todayIso()).trim()
        const start = String(source.start || "").trim()
        const end = String(source.end || "").trim()
        const title = String(source.title || "Evento").trim()
        const category = String(source.category || "").trim()
        return {
            title: title.length > 0 ? title : "Evento",
            date: date.length > 0 ? date : todayIso(),
            start: start,
            end: end,
            category: category,
            iconName: String(source.iconName || eventIconForCategory(category)).trim() || "calendar",
            accentIndex: index % 3
        }
    }

    function loadEventsText(rawText) {
        let parsed = []
        try {
            parsed = JSON.parse(String(rawText || "[]"))
        } catch (error) {
            parsed = []
        }
        if (!Array.isArray(parsed))
            parsed = []
        const items = []
        for (let i = 0; i < parsed.length; ++i)
            items.push(normalizeOverviewEvent(parsed[i], i))
        items.sort(function(a, b) {
            const left = String(a.date || "") + " " + String(a.start || "")
            const right = String(b.date || "") + " " + String(b.start || "")
            return left < right ? -1 : (left > right ? 1 : 0)
        })
        const today = todayIso()
        const upcoming = []
        for (let j = 0; j < items.length; ++j) {
            if (String(items[j].date || "") >= today)
                upcoming.push(items[j])
        }
        eventItems = items
        upcomingEventItems = upcoming.slice(0, 3)
    }

    function eventDateLabel(date) {
        const today = todayIso()
        const tomorrow = new Date()
        tomorrow.setDate(tomorrow.getDate() + 1)
        const tomorrowIso = tomorrow.getFullYear() + "-" + pad2(tomorrow.getMonth() + 1) + "-" + pad2(tomorrow.getDate())
        if (date === today)
            return "Hoje"
        if (date === tomorrowIso)
            return "Amanha"
        const parts = String(date || "").split("-")
        if (parts.length !== 3)
            return date || ""
        const parsed = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
        const weekdays = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab"]
        const months = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
        return weekdays[parsed.getDay()] + ", " + parsed.getDate() + " " + months[parsed.getMonth()]
    }

    function formatEventDetail(eventItem) {
        const event = eventItem || {}
        const time = String(event.start || "").length > 0
            ? String(event.start || "") + (String(event.end || "").length > 0 ? "-" + String(event.end || "") : "")
            : ""
        const date = eventDateLabel(String(event.date || ""))
        return date + (time.length > 0 ? " - " + time : "")
    }

    function upcomingEventTitle(index) {
        return index >= 0 && index < upcomingEventItems.length ? upcomingEventItems[index].title : ""
    }

    function upcomingEventDetail(index) {
        return index >= 0 && index < upcomingEventItems.length ? formatEventDetail(upcomingEventItems[index]) : ""
    }

    function upcomingEventIcon(index) {
        return index >= 0 && index < upcomingEventItems.length ? upcomingEventItems[index].iconName : "calendar"
    }

    function isToday(day) {
        return Number(day) === new Date().getDate()
    }

    function batteryText() {
        if (batteryState === "Charging")
            return "Carregando"
        if (batteryState === "Discharging")
            return "Na bateria"
        if (batteryState === "Full")
            return "Completa"
        return ""
    }

    function triggerRefresh() {
        if (!backgroundPollingActive)
            return
        if (!mediaQuery.running)
            mediaQuery.running = true
        if (!systemQuery.running)
            systemQuery.running = true
        if (!eventsQuery.running)
            eventsQuery.running = true
    }

    onBackgroundPollingActiveChanged: if (backgroundPollingActive) triggerRefresh()
    Component.onCompleted: if (backgroundPollingActive) triggerRefresh()

    Timer {
        interval: 2500
        repeat: true
        running: root.backgroundPollingActive
        onTriggered: if (!mediaQuery.running) mediaQuery.running = true
    }

    Timer {
        interval: 6000
        repeat: true
        running: root.backgroundPollingActive
        onTriggered: if (!systemQuery.running) systemQuery.running = true
    }

    Timer {
        interval: 20000
        repeat: true
        running: root.backgroundPollingActive
        onTriggered: if (!eventsQuery.running) eventsQuery.running = true
    }

    Process {
        id: mediaQuery

        running: false
        command: ["bash", "-lc", root.mediaCommand]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = String(text || "").replace(/\s+$/, "").split("\t")
                if (fields.length < 8) {
                    root.mediaTitle = ""
                    root.mediaArtist = ""
                    root.mediaAlbum = ""
                    root.mediaArt = ""
                    root.mediaPlaying = false
                    root.mediaPlayer = ""
                    root.mediaDurationSeconds = 0
                    root.mediaPositionSeconds = 0
                    root.refreshMediaPosition()
                    return
                }
                root.mediaTitle = fields[0]
                root.mediaArtist = fields[1]
                root.mediaAlbum = fields[2]
                root.mediaDurationSeconds = Math.max(0, Math.round((Number(fields[3]) || 0) / 1000000))
                root.mediaArt = fields[4] || ""
                root.mediaPositionSeconds = Math.max(0, Number(fields[5]) || 0)
                root.mediaPlaying = fields[6] === "Playing"
                root.mediaPlayer = fields[7] || ""
                root.refreshMediaPosition()
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

    Process {
        id: systemQuery

        running: false
        command: ["bash", "-lc", root.systemCommand]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("|")
                root.cpuPercent = Math.max(0, Math.min(100, Number(fields[0]) || 0))
                root.ramPercent = Math.max(0, Math.min(100, Number(fields[1]) || 0))
                root.batteryPercent = Math.max(0, Math.min(100, Number(fields[2]) || 0))
                root.batteryState = fields[3] || ""
            }
        }

        onExited: running = false
    }

    Process {
        id: eventsQuery

        running: false
        command: [root.eventsScript, "list"]

        stdout: StdioCollector {
            onStreamFinished: root.loadEventsText(text)
        }

        onExited: running = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            visible: false
            spacing: 20

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: root.greetingText()
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Tenha um momento tranquilo"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }

            Text {
                text: root.longDate()
                color: root.accent2
                font.family: root.uiFont
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 500
                spacing: 12

                OverviewCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 214
                    visible: true

                    ColumnLayout {
                        visible: !root.placeholderOnly
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        SectionTitle { title: "Musica"; iconName: "volume" }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 18

                            Rectangle {
                                Layout.preferredWidth: 122
                                Layout.preferredHeight: 122
                                radius: 9
                                clip: true
                                color: root.cardHover

                                Image {
                                    id: coverImage
                                    anchors.fill: parent
                                    source: root.mediaArt.length > 0 ? root.mediaArt : Qt.resolvedUrl("../assets/dashboard-cover.png")
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    mipmap: true
                                    sourceSize.width: 256
                                    sourceSize.height: 256
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 8

                                Item { Layout.fillHeight: true }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.mediaTitle.length > 0 ? root.mediaTitle : "Nenhuma midia tocando"
                                    color: root.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.mediaArtist.length > 0 ? root.mediaArtist : "playerctl / MPRIS"
                                    color: root.inkSoft
                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.mediaAlbum.length > 0 ? root.mediaAlbum : "Velora"
                                    color: root.inkMuted
                                    font.family: root.uiFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                ProgressBar {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 6
                                    value: root.mediaProgress
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: root.mediaPositionText; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: root.mediaDurationText; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 12 }
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 4
                                    spacing: 18

                                    MediaButton { label: "↝"; onClicked: root.runMediaAction("shuffle Toggle") }
                                    MediaButton { label: "‹"; onClicked: root.runMediaAction("previous") }
                                    MediaButton { label: root.mediaPlaying ? "Ⅱ" : "▶"; emphasized: true; onClicked: root.runMediaAction("play-pause") }
                                    MediaButton { label: "›"; onClicked: root.runMediaAction("next") }
                                    MediaButton { label: "↻"; onClicked: root.runMediaAction("loop Playlist") }
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }

                OverviewCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 248

                    ColumnLayout {
                        visible: !root.placeholderOnly
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            SectionTitle { Layout.fillWidth: true; title: "Notificacoes"; iconName: "bell" }
                            Text {
                                id: viewAllNotificationsText
                                text: "Ver tudo"
                                color: root.accent2
                                font.family: root.uiFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        NotificationRow { iconName: "memo"; title: "Nova mensagem"; timeText: "agora"; accentIndex: 0 }
                        NotificationRow { iconName: "spark"; title: "Push realizado com sucesso"; timeText: "ha 1 h"; accentIndex: 1 }
                        NotificationRow { iconName: "clock"; title: "Reuniao amanha as 14:00"; timeText: "ha 3 h"; accentIndex: 2 }
                        Item { Layout.fillHeight: true }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            ColumnLayout {
                Layout.preferredWidth: 242
                Layout.fillHeight: true
                spacing: 12

                OverviewCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 278

                    ColumnLayout {
                        visible: !root.placeholderOnly
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        SectionTitle { title: "Calendario"; iconName: "clock" }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 148
                            radius: 10
                            color: root.cardSoftLow
                            border.width: 1
                            border.color: root.line

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "‹"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 18 }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.monthLabel()
                                        color: root.ink
                                        horizontalAlignment: Text.AlignHCenter
                                        font.family: root.uiFont
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                    }
                                    Text { text: "›"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 18 }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 4
                                    columnSpacing: 4

                                    Repeater {
                                        model: ["D", "S", "T", "Q", "Q", "S", "S"]
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData
                                            color: root.inkMuted
                                            horizontalAlignment: Text.AlignHCenter
                                            font.family: root.uiFont
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Repeater {
                                        model: 42
                                        Rectangle {
                                            readonly property var dayValue: root.calendarDay(index)
                                            readonly property string cellDate: root.calendarDateForSlot(index)
                                            readonly property int eventCount: root.eventCountForDate(cellDate)
                                            readonly property bool today: root.isToday(dayValue)

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 8
                                            color: today ? root.fill : (eventCount > 0 ? root.alpha(root.accent2, 0.16) : "transparent")
                                            border.width: eventCount > 0 && !today ? 1 : 0
                                            border.color: root.alpha(root.accent2, 0.24)

                                            Text {
                                                anchors.centerIn: parent
                                                text: parent.dayValue
                                                color: parent.today ? (root.theme ? root.theme.activeText : "#ffffff") : (parent.eventCount > 0 ? root.ink : root.inkSoft)
                                                font.family: root.uiFont
                                                font.pixelSize: 10
                                                font.weight: parent.today || parent.eventCount > 0 ? Font.Bold : Font.Medium
                                            }

                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 2
                                                spacing: 2
                                                visible: parent.eventCount > 0

                                                Repeater {
                                                    model: Math.min(3, parent.parent.eventCount)
                                                    Rectangle {
                                                        width: 3
                                                        height: 3
                                                        radius: 2
                                                        color: parent.parent.today && root.theme ? root.theme.activeText : root.accent2
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            SectionTitle { Layout.fillWidth: true; title: "Proximo"; iconName: "memo" }
                            Text {
                                id: viewAgendaText
                                text: "Agenda"
                                color: root.accent2
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.Bold

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.agendaRequested(viewAgendaText.mapToItem(root, 0, viewAgendaText.height / 2).y)
                                }
                            }
                        }

                        Repeater {
                            model: Math.min(2, root.upcomingEventItems.length)
                            EventRow {
                                title: root.upcomingEventTitle(index)
                                detail: root.upcomingEventDetail(index)
                                iconName: root.upcomingEventIcon(index)
                                accentIndex: index
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.upcomingEventItems.length <= 0
                            text: "Sem eventos"
                            color: root.inkMuted
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }

                OverviewCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        visible: !root.placeholderOnly
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        SectionTitle { title: "Sistema"; iconName: "settings" }
                        MetricRow { label: "CPU"; value: root.cpuPercent; iconName: "settings" }
                        MetricRow { label: "RAM"; value: root.ramPercent; iconName: "memo" }
                        MetricRow { label: "Bateria"; value: root.batteryPercent; iconName: "battery"; detail: root.batteryText() }
                    }
                }
            }
        }
    }

    HoverHandler {
        margin: 18
        onHoveredChanged: {
            root.hovered = hovered
            root.pointerInsideChanged(hovered)
        }
    }

    component OverviewCard: Rectangle {
        radius: 13
        color: root.card
        border.width: 1
        border.color: root.line
        antialiasing: true
    }

    component SectionTitle: RowLayout {
        property string title: ""
        property string iconName: "spark"

        spacing: 9

        VeloraPopupIcon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            iconName: parent.iconName
            lineColor: root.accent2
        }

        Text {
            Layout.fillWidth: true
            text: parent.title
            color: root.accent2
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
    }

    component ProgressBar: Rectangle {
        property real value: 0

        Layout.preferredHeight: 4
        radius: 2
        color: root.theme ? root.alpha(root.theme.borderSoft, 0.20) : Qt.rgba(1, 1, 1, 0.16)
        clip: true

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.value))
            height: parent.height
            radius: parent.radius
            color: root.fill
        }
    }

    component MediaButton: Rectangle {
        id: button

        property string label: ""
        property bool emphasized: false
        property bool hovered: false
        signal clicked()

        Layout.preferredWidth: emphasized ? 44 : 30
        Layout.preferredHeight: emphasized ? 44 : 30
        radius: height / 2
        color: emphasized ? root.fill : (hovered ? root.cardHover : "transparent")
        border.width: emphasized ? 0 : 1
        border.color: hovered ? root.accent2 : "transparent"

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.emphasized ? (root.theme ? root.theme.activeText : "#ffffff") : root.accent2
            font.family: root.uiFont
            font.pixelSize: button.emphasized ? 18 : 17
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component NotificationRow: Rectangle {
        property string iconName: "memo"
        property string title: ""
        property string timeText: ""
        property int accentIndex: 0

        Layout.fillWidth: true
        Layout.minimumHeight: 31
        Layout.preferredHeight: 31
        Layout.maximumHeight: 31
        implicitHeight: 31
        radius: 10
        color: root.cardSoftLow

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 6
                color: root.alpha(root.accent2, 0.20 + accentIndex * 0.04)

                VeloraPopupIcon {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    iconName: parent.parent.parent.iconName
                    lineColor: root.accent2
                }
            }

            Text {
                Layout.fillWidth: true
                text: parent.parent.title
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: parent.parent.timeText
                color: root.inkMuted
                font.family: root.uiFont
                font.pixelSize: 11
            }
        }
    }

    component EventRow: RowLayout {
        property string title: ""
        property string detail: ""
        property string iconName: "memo"
        property int accentIndex: 0

        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 7
            color: root.alpha(root.accent2, 0.17 + accentIndex * 0.04)
            VeloraPopupIcon {
                anchors.centerIn: parent
                width: 14
                height: 14
                iconName: parent.parent.iconName
                lineColor: root.accent2
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text { Layout.fillWidth: true; text: parent.parent.title; color: root.ink; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.Bold; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: parent.parent.detail; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
        }
    }

    component MetricRow: RowLayout {
        property string label: ""
        property int value: 0
        property string iconName: "settings"
        property string detail: ""

        Layout.fillWidth: true
        spacing: 12

        VeloraPopupIcon {
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            iconName: parent.iconName
            lineColor: root.accent2
        }

        Text {
            Layout.preferredWidth: 56
            text: parent.label
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        ProgressBar {
            Layout.fillWidth: true
            value: parent.value / 100
        }

        ColumnLayout {
            Layout.preferredWidth: 62
            spacing: 0
            Text { Layout.fillWidth: true; text: parent.parent.value + "%"; color: root.ink; horizontalAlignment: Text.AlignRight; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.Bold }
            Text { Layout.fillWidth: true; text: parent.parent.detail; color: root.inkMuted; horizontalAlignment: Text.AlignRight; visible: text.length > 0; font.family: root.uiFont; font.pixelSize: 10 }
        }
    }
}
