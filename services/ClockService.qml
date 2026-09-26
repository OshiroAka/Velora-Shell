import QtQuick
import Quickshell

Scope {
    id: root

    property string localeName: "system"
    property date now: new Date()

    readonly property string timeText: Qt.formatTime(now, "HH:mm")
    readonly property string dateText: locale().toString(now, "dddd, dd 'de' MMMM")
    readonly property string topbarTimeText: Qt.formatTime(now, "HH:mm")
    readonly property string topbarDateText: locale().toString(now, "dddd, MMMM d")
    readonly property string topbarCompactDateText: compactDateText()
    readonly property string monthName: locale().monthName(now.getMonth(), Locale.LongFormat)
    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth()
    readonly property int day: now.getDate()
    readonly property var weekdayLabels: weekdayNames()

    function locale() {
        return localeName === "system" ? Qt.locale() : Qt.locale(localeName)
    }

    function weekdayNames() {
        const names = []
        const currentLocale = locale()
        names.push(currentLocale.standaloneDayName(7, Locale.NarrowFormat))
        for (let dayIndex = 1; dayIndex <= 6; dayIndex += 1)
            names.push(currentLocale.standaloneDayName(dayIndex, Locale.NarrowFormat))
        return names
    }

    function compactDateText() {
        const value = locale().toString(now, "ddd, d MMM")
        return String(value).replace(/\./g, "")
    }

    function refresh() {
        now = new Date()
        minuteTick.interval = Math.max(100, 60010 - now.getSeconds() * 1000 - now.getMilliseconds())
        minuteTick.restart()
    }

    Component.onCompleted: refresh()

    Timer {
        id: minuteTick
        repeat: false
        onTriggered: root.refresh()
    }
}
