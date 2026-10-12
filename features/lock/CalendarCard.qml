import QtQuick

GlassPanel {
    id: root

    required property var theme
    required property var motion
    required property var clock
    required property var calendarService
    property var itemStyle: ({})
    property string variantId: "classic"
    readonly property bool editorial: variantId === "editorial"
    readonly property bool minimal: variantId === "minimal"
    readonly property string contentFont: customFont.name.length
        ? customFont.name : String(itemStyle.fontFamily || root.theme.bodyFont)
    readonly property real fontScale: Number(itemStyle.fontScale || 1)
    readonly property color contentColor: String(itemStyle.textColor || "").length
        ? itemStyle.textColor : root.theme.inverseInk

    FontLoader { id: customFont; source: String(root.itemStyle.fontAsset || "") }

    property int selectedDay: clock.day
    property int monthOffset: 0
    property var displayedEvent: null
    property real eventReveal: 1
    property int eventAnimationDuration: 260
    readonly property date displayedDate: new Date(clock.year,
        clock.month + monthOffset, 1)
    readonly property int displayedYear: displayedDate.getFullYear()
    readonly property int displayedMonth: displayedDate.getMonth()
    readonly property string displayedMonthName: monthOffset === 0
        ? clock.monthName
        : clock.locale().monthName(displayedMonth, Locale.LongFormat)
    readonly property var selectedEvents: calendarService.eventsForDate(
        displayedYear, displayedMonth, selectedDay)
    readonly property int firstDayIndex: new Date(
        displayedYear, displayedMonth, 1).getDay()
    readonly property int daysInMonth: new Date(
        displayedYear, displayedMonth + 1, 0).getDate()
    readonly property int previousMonthDays: new Date(
        displayedYear, displayedMonth, 0).getDate()
    readonly property real cellWidth: editorial
        ? (width - 32 - cellGap * 6) / 7 : 35
    readonly property real cellHeight: editorial ? 21 : 18
    readonly property real cellGap: 2

    width: 282
    height: 260
    radius: Number(itemStyle.radius === undefined
        ? (editorial ? 24 : (minimal ? 14 : 28)) : itemStyle.radius)
    materialMode: root.theme.resolvedMaterial(itemStyle)
    solidColor: String(itemStyle.solidColor || "#20222a")
    materialOpacity: Number(itemStyle.surfaceOpacity === undefined
        ? 0.82 : itemStyle.surfaceOpacity)
    surfaceColor: theme.moduleSurface
    flatSurface: Boolean(itemStyle.matchBarSurface)
    borderColor: theme.moduleBorder
    shadowColor: Qt.rgba(theme.shadow.r, theme.shadow.g, theme.shadow.b, 0.12)

    Connections {
        target: root.clock
        function onDayChanged() {
            if (root.monthOffset === 0)
                root.selectedDay = root.clock.day
        }
    }

    function changeMonth(delta) {
        monthOffset += delta
        selectedDay = monthOffset === 0
            ? clock.day : Math.min(selectedDay, daysInMonth)
    }

    onSelectedDayChanged: {
        eventAnimationDuration = root.motion.reduced ? 0 : 180
        eventReveal = 0
        eventSwapTimer.restart()
    }

    Component.onCompleted: displayedEvent = selectedEvents.length
        ? selectedEvents[0] : null

    Timer {
        id: eventSwapTimer
        interval: root.motion.reduced ? 0 : 180
        repeat: false
        onTriggered: {
            root.displayedEvent = root.selectedEvents.length
                ? root.selectedEvents[0] : null
            eventEmergeTimer.restart()
        }
    }

    Timer {
        id: eventEmergeTimer
        interval: root.motion.reduced ? 0 : 45
        repeat: false
        onTriggered: {
            root.eventAnimationDuration = root.motion.reduced ? 0 : 260
            root.eventReveal = 1
        }
    }

    Behavior on eventReveal {
        NumberAnimation {
            duration: root.eventAnimationDuration
            easing.type: Easing.InOutCubic
        }
    }

    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: editorial ? 15 : 13
        text: root.displayedMonthName
        color: root.contentColor
        font.family: root.contentFont
        font.pixelSize: (editorial ? 20 : (minimal ? 17 : 22)) * root.fontScale
        font.weight: Font.DemiBold
        font.capitalization: Font.Capitalize
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 26
        anchors.topMargin: editorial ? 14 : 12
        text: "‹"
        color: root.contentColor
        opacity: previousMonthMouse.containsMouse ? 1 : 0.82
        font.family: root.contentFont
        font.pixelSize: 25 * root.fontScale
        visible: root.editorial

        MouseArea {
            id: previousMonthMouse
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.changeMonth(-1)
        }
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 26
        anchors.topMargin: editorial ? 14 : 12
        text: "›"
        color: root.contentColor
        opacity: nextMonthMouse.containsMouse ? 1 : 0.82
        font.family: root.contentFont
        font.pixelSize: 25 * root.fontScale
        visible: root.editorial

        MouseArea {
            id: nextMonthMouse
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.changeMonth(1)
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: editorial ? 50 : 47
        width: editorial ? parent.width - 32 : 136
        height: editorial ? 1 : 2
        radius: 1
        color: editorial ? root.theme.borderSubtle
            : Qt.rgba(1.0, 1.0, 1.0, 0.74)
    }

    Row {
        id: weekdayRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: editorial ? 61 : 59
        anchors.leftMargin: editorial ? 16 : 13
        spacing: root.cellGap

        Repeater {
            model: 7

            Text {
                required property int index
                width: root.cellWidth
                height: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.clock.weekdayLabels[index] || ""
                color: index === 0 || index === 6
                    ? root.theme.accentSoft : root.theme.calendarWeekday
                font.family: root.contentFont
                font.pixelSize: (root.editorial ? 11 : 12) * root.fontScale
                font.weight: Font.DemiBold
            }
        }
    }

    Item {
        id: daysArea
        anchors.top: weekdayRow.bottom
        anchors.left: parent.left
        anchors.topMargin: 2
        anchors.leftMargin: root.editorial ? 16 : 13
        width: root.cellWidth * 7 + root.cellGap * 6
        height: root.cellHeight * 6 + root.cellGap * 5

        Rectangle {
            id: activeDayCapsule
            readonly property int selectedIndex: root.firstDayIndex
                + Math.max(0, root.selectedDay - 1)
            x: (selectedIndex % 7) * (root.cellWidth + root.cellGap)
                + (root.cellWidth - width) / 2
            y: Math.floor(selectedIndex / 7) * (root.cellHeight + root.cellGap)
                + (root.cellHeight - height) / 2
            width: root.editorial ? 29 : 25
            height: root.editorial ? 24 : 20
            radius: 10
            color: Qt.rgba(root.theme.accentAlt.r, root.theme.accentAlt.g,
                           root.theme.accentAlt.b, 0.86)
            border.width: 1
            border.color: Qt.rgba(root.theme.accentSoft.r,
                                  root.theme.accentSoft.g,
                                  root.theme.accentSoft.b, 0.82)

            Behavior on x {
                NumberAnimation { duration: root.motion.reduced ? 0 : 300; easing.type: Easing.InOutCubic }
            }
            Behavior on y {
                NumberAnimation { duration: root.motion.reduced ? 0 : 300; easing.type: Easing.InOutCubic }
            }
        }

        Grid {
            anchors.fill: parent
            columns: 7
            columnSpacing: root.cellGap
            rowSpacing: root.cellGap

            Repeater {
                model: 42

                Item {
                    id: dayCell
                    required property int index
                    readonly property int dayNumber: index - root.firstDayIndex + 1
                    readonly property bool validDay: dayNumber >= 1
                        && dayNumber <= root.daysInMonth
                    readonly property int displayNumber: dayNumber < 1
                        ? root.previousMonthDays + dayNumber
                        : (dayNumber > root.daysInMonth
                            ? dayNumber - root.daysInMonth : dayNumber)
                    readonly property bool selected: validDay
                        && dayNumber === root.selectedDay
                    readonly property bool hovered: dayMouse.containsMouse
                    width: root.cellWidth
                    height: root.cellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: 23
                        height: 23
                        radius: 11.5
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.42)
                        opacity: dayCell.hovered && !dayCell.selected ? 1 : 0
                        scale: dayMouse.pressed ? 0.84
                            : (dayCell.hovered ? 1 : 0.72)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: root.motion.hover
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: root.motion.hover
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.displayNumber
                        color: dayCell.validDay ? root.contentColor
                            : Qt.rgba(root.contentColor.r, root.contentColor.g,
                                root.contentColor.b, 0.38)
                        font.family: root.contentFont
                        font.pixelSize: 12 * root.fontScale
                        font.weight: root.monthOffset === 0
                            && dayCell.validDay
                            && dayCell.dayNumber === root.clock.day
                            ? Font.DemiBold : Font.Normal
                        scale: dayCell.hovered ? 1.08 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: root.motion.hover
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 2
                        radius: 1
                        opacity: dayCell.validDay
                            && root.calendarService.eventsForDate(root.displayedYear,
                                root.displayedMonth, dayCell.dayNumber).length > 0 ? 1 : 0
                        color: root.contentColor

                        Behavior on opacity {
                            NumberAnimation {
                                duration: root.motion.micro
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        enabled: dayCell.validDay
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.selectedDay = dayCell.dayNumber
                    }
                }
            }
        }
    }

    Rectangle {
        id: eventDetail
        x: 13
        y: 205 + (1 - root.eventReveal) * 22
        width: 256
        height: 43
        radius: 15
        color: Qt.rgba(1, 1, 1, eventMouse.containsMouse ? 0.18 : 0.09)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, eventMouse.containsMouse ? 0.44 : 0.17)
        opacity: root.eventReveal
        visible: !root.editorial && !root.minimal
        scale: 0.96 + root.eventReveal * 0.04

        Behavior on color { ColorAnimation { duration: root.motion.reduced ? 0 : 190 } }

        Rectangle {
            x: 10; y: 9; width: 4; height: 25; radius: 2
            color: root.displayedEvent && String(root.displayedEvent.color || "").length
                ? root.displayedEvent.color : root.theme.accentSoft
        }

        Text {
            x: 22; y: 6
            width: 194
            text: root.displayedEvent
                ? String(root.displayedEvent.title || "Evento") : "Sem eventos"
            color: root.contentColor
            font.family: root.contentFont
            font.pixelSize: 11 * root.fontScale
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            x: 22; y: 23
            width: 194
            text: root.displayedEvent
                ? (Boolean(root.displayedEvent.allDay) ? "Dia inteiro"
                    : String(root.displayedEvent.start || "").slice(11, 16))
                : "Clique em + para criar"
            color: Qt.rgba(root.contentColor.r, root.contentColor.g,
                           root.contentColor.b, 0.68)
            font.family: root.contentFont
            font.pixelSize: 9 * root.fontScale
            elide: Text.ElideRight
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 27; height: 27; radius: 13.5
            color: Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                           root.theme.accent.b, plusMouse.containsMouse ? 0.54 : 0.30)
            Text { anchors.centerIn: parent; text: "+"; color: root.contentColor; font.pixelSize: 17 }
            MouseArea {
                id: plusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const date = root.displayedYear.toString().padStart(4, "0") + "-"
                        + (root.displayedMonth + 1).toString().padStart(2, "0") + "-"
                        + root.selectedDay.toString().padStart(2, "0")
                    root.calendarService.addReminder("Novo lembrete", date, date,
                        true, "Criado no Velora Shell")
                    root.eventSwapTimer.restart()
                }
            }
        }

        MouseArea {
            id: eventMouse
            anchors.fill: parent
            anchors.rightMargin: 42
            hoverEnabled: true
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        width: 92
        height: 5
        radius: 2.5
        color: root.contentColor
        visible: false
    }
}
