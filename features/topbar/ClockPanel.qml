import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: root
    required property var theme
    required property var clock
    required property var timerService
    required property var calendar
    property string page: "timer"
    property bool timerOnly: false
    property date calendarMonth: new Date(clock.year, clock.month, 1)
    spacing: 10

    RowLayout {
        visible: !root.timerOnly
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text { text: root.clock.timeText; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 26 }
            Text { text: root.clock.dateText; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        }
        BarIcon { width: 24; height: 24; name: "clock"; color: root.theme.accentSoft }
    }
    RowLayout {
        visible: !root.timerOnly
        Layout.fillWidth: true
        Repeater {
            model: [{ key: "timer", label: "Timer" }, { key: "stopwatch", label: "Cronômetro" }, { key: "calendar", label: "Calendário" }]
            BarAction {
                required property var modelData
                Layout.fillWidth: true
                theme: root.theme; text: modelData.label; highlighted: root.page === modelData.key
                onClicked: root.page = modelData.key
            }
        }
    }
    ColumnLayout {
        visible: root.page === "timer"
        Layout.fillWidth: true
        spacing: 9
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: [5, 10, 25]
                BarAction {
                    required property int modelData
                    theme: root.theme; text: modelData + "m"; Layout.fillWidth: true
                    highlighted: root.timerService.duration === modelData * 60000
                    onClicked: root.timerService.setDuration(modelData * 60)
                }
            }
            TextField {
                id: customMinutes
                Layout.preferredWidth: 68
                implicitHeight: 36
                placeholderText: "min"
                color: root.theme.textPrimary
                font.family: root.theme.bodyFont
                font.pixelSize: 12
                validator: IntValidator { bottom: 1; top: 1440 }
                selectByMouse: true
                Accessible.name: "Duração personalizada em minutos"
                background: Rectangle { radius: 9; color: root.theme.withAlpha(root.theme.textPrimary, 0.05); border.width: 1; border.color: root.theme.borderSubtle }
                onEditingFinished: { if (acceptableInput && text.length) { root.timerService.setDuration(Number(text) * 60); text = "" } }
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.timerService.timerText
            color: root.timerService.finished ? root.theme.accentSoft : root.theme.textPrimary
            font.family: root.theme.bodyFont; font.pixelSize: 43; font.weight: Font.Light
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.timerService.finished ? "Tempo concluído" : root.timerService.countdown.running ? "Contagem em andamento" : "Pronto para o próximo foco"
            color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11
        }
        RowLayout {
            Layout.fillWidth: true
            BarAction {
                Layout.fillWidth: true; theme: root.theme; highlighted: true
                text: root.timerService.countdown.running ? "Pausar" : root.timerService.remaining < root.timerService.duration && !root.timerService.finished ? "Continuar" : "Iniciar"
                onClicked: root.timerService.toggleTimer()
            }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: "Resetar"; onClicked: root.timerService.resetTimer() }
        }
    }
    ColumnLayout {
        visible: root.page === "stopwatch"
        Layout.fillWidth: true
        Layout.fillHeight: true
        Text {
            Layout.alignment: Qt.AlignCenter
            text: root.timerService.stopwatchText
            color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 43
        }
        RowLayout {
            Layout.fillWidth: true
            BarAction {
                Layout.fillWidth: true; theme: root.theme; highlighted: true
                text: root.timerService.stopwatch.running ? "Pausar" : root.timerService.elapsed > 0 ? "Continuar" : "Iniciar"
                onClicked: root.timerService.toggleStopwatch()
            }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: "Resetar"; onClicked: root.timerService.resetStopwatch() }
        }
    }
    ColumnLayout {
        visible: root.page === "calendar"
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            BarAction { theme: root.theme; text: "‹"; Accessible.name: "Mês anterior"; onClicked: root.calendarMonth = new Date(root.calendarMonth.getFullYear(), root.calendarMonth.getMonth() - 1, 1) }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.clock.locale().toString(root.calendarMonth, "MMMM yyyy")
                color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
            }
            BarAction { theme: root.theme; text: "›"; Accessible.name: "Próximo mês"; onClicked: root.calendarMonth = new Date(root.calendarMonth.getFullYear(), root.calendarMonth.getMonth() + 1, 1) }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 3; rowSpacing: 2
            Repeater {
                model: root.clock.weekdayLabels
                Text { required property string modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData; color: root.theme.textMuted; font.pixelSize: 10 }
            }
            Repeater {
                model: 42
                Rectangle {
                    required property int index
                    readonly property date date: new Date(root.calendarMonth.getFullYear(), root.calendarMonth.getMonth(), index - root.calendarMonth.getDay() + 1)
                    readonly property bool today: date.getFullYear() === root.clock.year && date.getMonth() === root.clock.month && date.getDate() === root.clock.day
                    readonly property bool hasEvents: root.calendar.eventsForDate(date.getFullYear(), date.getMonth(), date.getDate()).length > 0
                    Layout.fillWidth: true; Layout.preferredHeight: 25; radius: 7
                    color: today ? root.theme.withAlpha(root.theme.accent, 0.24) : "transparent"
                    opacity: date.getMonth() === root.calendarMonth.getMonth() ? 1 : 0.35
                    Text { anchors.centerIn: parent; text: parent.date.getDate(); color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                    Rectangle { visible: parent.hasEvents; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; width: 3; height: 3; radius: 2; color: root.theme.accentSoft }
                }
            }
        }
    }
    Item { Layout.fillHeight: true }
    Text { visible: text.length > 0; text: root.timerService.saveError; color: root.theme.warning; font.pixelSize: 11 }
}
