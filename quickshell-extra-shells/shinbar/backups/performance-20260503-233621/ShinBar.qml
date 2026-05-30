import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
    id: win

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.namespace:     ShinConfig.namespace
    WlrLayershell.keyboardFocus: ShinPopup.focusMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }

    implicitHeight: ShinConfig.barH + ShinConfig.barMarginT * 2
    exclusionMode:  ExclusionMode.Auto
    color:          "transparent"
    focusable:      true

    property real focusX: 0
    property real focusY: 0
    property real focusW: 32
    property real focusH: 22

    property var trailSegments: []
    property var closeBursts: []
    property real burstDecay: 0.075

    // Ajustes principais do efeito
    property real focusPad: 2
    property real trailSpeed: 0.036
    property real trailTailDelay: 0.34
    property real trailFade: 0.105
    property real trailOpacity: 0.72

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    // Parecido com emphasizedDecel: começa rápido e desacelera no final.
    function emphasizedDecel(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.15)
    }

    function focusSlot() {
        if (ShinPopup.focusTarget === "notifications") return shinNotifyBellInline

        if (ShinPopup.focusTarget === "workspaces") return slotWorkspaces
        if (ShinPopup.focusTarget === "search")     return ShinConfig.searchEnabled ? slotSearch : shinNotifyBellInline
        if (ShinPopup.focusTarget === "clock")      return slotClock
        if (ShinPopup.focusTarget === "weather")    return slotWeather
        if (ShinPopup.focusTarget === "profile")    return slotProfile
        if (ShinPopup.focusTarget === "media")      return slotMedia
        if (ShinPopup.focusTarget === "bluetooth")  return slotBluetooth
        if (ShinPopup.focusTarget === "battery")    return slotBattery
        return slotClock
    }

    function measureSlot(slot) {
        if (!slot || !rootLayer)
            return { x: 0, y: 0, w: 32, h: 22 }

        var pillH = ShinConfig.pillH > 0 ? ShinConfig.pillH : Math.max(20, ShinConfig.barH - 8)
        var pillW = Math.max(24, slot.width)
        var pillY = Math.round((slot.height - pillH) / 2)

        var p = slot.mapToItem(rootLayer, 0, pillY)

        return {
            x: Math.round(p.x - focusPad),
            y: Math.round(p.y - focusPad),
            w: Math.round(pillW + focusPad * 2),
            h: Math.round(pillH + focusPad * 2)
        }
    }

    function rectAt(oldR, newR, t) {
        return {
            x: lerp(oldR.x, newR.x, t),
            y: lerp(oldR.y, newR.y, t),
            w: lerp(oldR.w, newR.w, t),
            h: lerp(oldR.h, newR.h, t)
        }
    }

    function capsuleBetween(a, b) {
        var left = Math.min(a.x, b.x)
        var right = Math.max(a.x + a.w, b.x + b.w)
        var top = Math.min(a.y, b.y)
        var bottom = Math.max(a.y + a.h, b.y + b.h)

        return {
            x: Math.round(left),
            y: Math.round(top),
            w: Math.round(right - left),
            h: Math.round(bottom - top)
        }
    }

    function setFocusRectFromCurrent() {
        var r = measureSlot(focusSlot())
        focusX = r.x
        focusY = r.y
        focusW = r.w
        focusH = r.h
    }

    function pushElasticTrail(oldR, newR) {
        var arr = trailSegments.slice()

        arr.unshift({
            oldX: oldR.x,
            oldY: oldR.y,
            oldW: oldR.w,
            oldH: oldR.h,

            newX: newR.x,
            newY: newR.y,
            newW: newR.w,
            newH: newR.h,

            raw: 0.0,
            life: 1.0,

            x: oldR.x,
            y: oldR.y,
            w: oldR.w,
            h: oldR.h
        })

        // Poucos rastros. O efeito vem do corpo elástico, não de acumular muito.
        while (arr.length > 2)
            arr.pop()

        trailSegments = ShinConfig.trailEnabled ? arr : []
    }

    function pushCloseBurst(r, dir) {
        var arr = closeBursts.slice()

        for (var i = 0; i < 5; i++) {
            arr.unshift({
                x: r.x + dir * i * 6,
                y: r.y,
                w: r.w + i * 10,
                h: r.h,
                life: 1.0 - i * 0.10,
                dir: dir
            })
        }

        while (arr.length > 18)
            arr.pop()

        closeBursts = arr
    }

    function moveFocus(dir) {
        var wasExpanded = ShinPopup.active !== ""

        var oldR = {
            x: focusX,
            y: focusY,
            w: focusW,
            h: focusH
        }

        if (wasExpanded)
            ShinPopup.active = ""

        ShinPopup.moveFocus(dir)
        if (!ShinConfig.searchEnabled && ShinPopup.focusTarget === "search")
            ShinPopup.moveFocus(dir)

        Qt.callLater(function() {
            var newR = measureSlot(focusSlot())

            pushElasticTrail(oldR, newR)

            focusX = newR.x
            focusY = newR.y
            focusW = newR.w
            focusH = newR.h

            if (wasExpanded)
                reopenExpandedAfterMove.restart()
        })
    }

    Timer {
        id: reopenExpandedAfterMove
        interval: 180
        repeat: false
        onTriggered: ShinPopup.openFocused()
    }

    Timer {
        id: closeBurstTimer
        interval: 16
        repeat: true
        running: ShinPopup.focusMode || closeBursts.length > 0

        onTriggered: {
            var arr = closeBursts.slice()

            for (var i = 0; i < arr.length; i++) {
                arr[i].life = Math.max(0.0, arr[i].life - burstDecay)
                arr[i].x += arr[i].dir * 1.8
                arr[i].w += 1.5
            }

            closeBursts = arr.filter(function(b) {
                return b.life > 0.02
            })
        }
    }

    Timer {
        id: trailTimer
        interval: 16
        repeat: true
        running: ShinConfig.trailEnabled && (ShinPopup.focusMode || trailSegments.length > 0)

        onTriggered: {
            var arr = trailSegments.slice()

            for (var i = 0; i < arr.length; i++) {
                var s = arr[i]

                if (s.raw < 1.0)
                    s.raw = Math.min(1.0, s.raw + trailSpeed)
                else
                    s.life = Math.max(0.0, s.life - trailFade)

                var oldR = { x: s.oldX, y: s.oldY, w: s.oldW, h: s.oldH }
                var newR = { x: s.newX, y: s.newY, w: s.newW, h: s.newH }

                var headT = emphasizedDecel(s.raw)

                // A cauda começa depois. Isso impede o rastro de virar linha completa instantânea.
                var tailRaw = Math.max(0.0, (s.raw - trailTailDelay) / (1.0 - trailTailDelay))
                var tailT = emphasizedDecel(tailRaw)

                var head = rectAt(oldR, newR, headT)
                var tail = rectAt(oldR, newR, tailT)
                var cap = capsuleBetween(tail, head)

                s.x = cap.x
                s.y = cap.y
                s.w = cap.w
                s.h = cap.h
            }

            trailSegments = arr.filter(function(s) {
                return s.life > 0.02
            })
        }
    }

    Connections {
        target: ShinPopup

        function onFocusModeChanged() {
            if (ShinPopup.focusMode) {
                Qt.callLater(function() {
                    rootLayer.forceActiveFocus()
                    trailSegments = []
                    setFocusRectFromCurrent()
                })
            } else {
                if (ShinPopup.keepActiveOnFocusExit)
                    ShinPopup.keepActiveOnFocusExit = false
                else
                    ShinPopup.active = ""
                trailSegments = []
            }
        }

        function onFocusIndexChanged() {
            Qt.callLater(function() {
                setFocusRectFromCurrent()
            })
        }
    }

    Item {
        id: rootLayer

        anchors {
            fill: parent
            leftMargin: ShinConfig.barMarginH
            rightMargin: ShinConfig.barMarginH
            topMargin: ShinConfig.barMarginT
            bottomMargin: ShinConfig.barMarginT
        }

        focus: ShinPopup.focusMode

        Keys.onEscapePressed: ShinPopup.exitFocus()
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_A) {
                win.moveFocus(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_D) {
                win.moveFocus(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                if (ShinPopup.active !== "")
                    ShinPopup.navigateInside(-1, 0)
                else
                    win.moveFocus(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                if (ShinPopup.active !== "")
                    ShinPopup.navigateInside(1, 0)
                else
                    win.moveFocus(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                ShinPopup.navigateInside(0, -1)
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                ShinPopup.navigateInside(0, 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (ShinPopup.active !== "" && ShinPopup.active !== "search")
                    ShinPopup.activateInside()
                else
                    ShinPopup.openFocused()
                event.accepted = true
            }
        }

        // Burst de fechamento do item expandido.
        Repeater {
            model: win.closeBursts

            Rectangle {
                z: -9

                x: modelData.x
                y: modelData.y
                width: modelData.w
                height: modelData.h
                radius: height / 2
                antialiasing: true

                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.34 * modelData.life
                )

                border.width: 1
                border.color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.62 * modelData.life
                )
            }
        }

        // Rastro preenchido atrás dos pills.
        Repeater {
            model: win.trailSegments

            Rectangle {
                z: -10

                x: modelData.x
                y: modelData.y
                width: modelData.w
                height: modelData.h
                radius: height / 2
                antialiasing: true

                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    trailOpacity * modelData.life
                )

                border.width: 1
                border.color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    Math.min(1.0, modelData.life)
                )
            }
        }

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: ShinConfig.pillSpacing

            Item {
                id: slotSearch
                width: ShinConfig.searchEnabled ? 42 : 0
                height: ShinConfig.barH

                ShinSearch {
                    id: searchItem
                    anchors.fill: parent
                }
            }

            Item {
                id: slotWorkspaces
                width: Math.max(34, workspacesItem.implicitWidth > 0 ? workspacesItem.implicitWidth : workspacesItem.childrenRect.width)
                height: ShinConfig.barH

                ShinWorkspaces {
                    id: workspacesItem
                    anchors.centerIn: parent
                }
            }

            Item {
                id: shinNotifyBellInline

                width: 42
                height: ShinConfig.barH

                function syncNotifyAnchor() {
                    if (!rootLayer)
                        return

                    var p = mapToItem(rootLayer, 0, 0)
                    ShinPopup.notificationsX = Math.round(p.x)
                }

                Component.onCompleted: syncNotifyAnchor()
                onXChanged: syncNotifyAnchor()
                onYChanged: syncNotifyAnchor()
                onWidthChanged: syncNotifyAnchor()
                onVisibleChanged: syncNotifyAnchor()

                ShinNotifyButton {
                    anchors.fill: parent
                }
            }
        }

            Row {
                anchors.centerIn: parent
                spacing: ShinConfig.pillSpacing

                Item {
                    id: slotWallpapers
                    width: Math.max(34, wallpapersItem.implicitWidth > 0 ? wallpapersItem.implicitWidth : wallpapersItem.childrenRect.width)
                    height: ShinConfig.barH

                    ShinWallpapers {
                        id: wallpapersItem
                        anchors.centerIn: parent
                    }
                }

                Item {
                    id: slotClock
                    width: Math.max(34, clockItem.implicitWidth > 0 ? clockItem.implicitWidth : clockItem.childrenRect.width)
                    height: ShinConfig.barH

                ShinClock {
                    id: clockItem
                    anchors.centerIn: parent
                    opacity: 1.0
                }
            }

            Item {
                id: slotWeather
                width: Math.max(34, weatherItem.implicitWidth > 0 ? weatherItem.implicitWidth : weatherItem.childrenRect.width)
                height: ShinConfig.barH

                ShinWeather {
                    id: weatherItem
                    anchors.centerIn: parent
                    opacity: 1.0
                }
            }

            Item {
                id: slotProfile
                width: Math.max(34, profileItem.implicitWidth > 0 ? profileItem.implicitWidth : profileItem.childrenRect.width)
                height: ShinConfig.barH

                ShinProfile {
                    id: profileItem
                    anchors.centerIn: parent
                }
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: ShinConfig.pillSpacing
            layoutDirection: Qt.RightToLeft

            Item {
                id: slotBattery
                width: Math.max(34, batteryItem.implicitWidth > 0 ? batteryItem.implicitWidth : batteryItem.childrenRect.width)
                height: ShinConfig.barH

                ShinBattery {
                    id: batteryItem
                    anchors.centerIn: parent
                }
            }

            Item {
                id: slotBluetooth
                width: Math.max(34, bluetoothItem.implicitWidth > 0 ? bluetoothItem.implicitWidth : bluetoothItem.childrenRect.width)
                height: ShinConfig.barH

                ShinBluetooth {
                    id: bluetoothItem
                    anchors.centerIn: parent
                }
            }

            Item {
                id: slotMedia
                width: Math.max(34, mediaItem.implicitWidth > 0 ? mediaItem.implicitWidth : mediaItem.childrenRect.width)
                height: ShinConfig.barH

                ShinMedia {
                    id: mediaItem
                    anchors.centerIn: parent
                }
            }
        }

        // Borda do item focado. Sem preenchimento, para não lavar a cor do pill.
        Rectangle {
            id: focusMain
            visible: ShinPopup.focusMode
            z: 50

            x: win.focusX
            y: win.focusY
            width: win.focusW
            height: win.focusH
            radius: height / 2

            color: "transparent"

            border.width: 2
            border.color: Qt.rgba(
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                1.0
            )

            antialiasing: true

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }
}
