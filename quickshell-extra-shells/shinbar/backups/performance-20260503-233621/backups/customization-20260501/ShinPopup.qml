pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool useExpandedHost: false

    property string active: ""
    property int notificationsX: 128
    property bool notificationsOpen: active === "notifications"

    property bool focusMode: false
    property int focusIndex: 1
    property bool keepActiveOnFocusExit: false

    readonly property var focusItems: [
        "workspaces",
        "notifications",
        "clock",
        "weather",
        "media",
        "battery"
    ]

    property string focusTarget: focusItems[Math.max(0, Math.min(focusIndex, focusItems.length - 1))]

    // Host expandido compartilhado.
    property string expandedPage: ""
    property string switchingTo: ""
    property int switchDir: 1
    property int switchNonce: 0

    readonly property bool expandedOpen: expandedPage !== ""

    // Weather mode cycle.
    property int weatherFxCycleNonce: 0

    function isHostPage(name) {
        return name === "clock" || name === "weather"
    }

    function open(name) {
        active = name
    }

    function close(name) {
        if (active === name)
            active = ""
    }

    function openNotifications() {
        open("notifications")
    }

    function closeNotifications() {
        close("notifications")
    }

    function toggleNotifications() {
        toggle("notifications")
    }

    function toggle(name) {
        active = active === name ? "" : name
    }

    function closeExpanded() {
        expandedPage = ""
        switchingTo = ""
        active = ""
    }

    function switchExpanded(name, dir) {
        if (!isHostPage(name)) {
            closeExpanded()
            active = name
            return
        }

        if (!expandedOpen) {
            open(name)
            return
        }

        if (expandedPage === name)
            return

        switchDir = dir === undefined ? 1 : dir
        switchingTo = name
        switchNonce += 1
    }

    function finishSwitch() {
        if (switchingTo.length > 0) {
            expandedPage = switchingTo
            active = switchingTo
            switchingTo = ""
        }
    }

    function cycleWeatherFx() {
        weatherFxCycleNonce += 1
    }

    function enterFocus() {
        var clockIndex = focusItems.indexOf("clock")
        focusIndex = clockIndex >= 0 ? clockIndex : 0
        focusMode = true
    }

    function exitFocus() {
        keepActiveOnFocusExit = false
        focusMode = false
        active = ""
        closeExpanded()
    }

    function releaseFocusKeepActive() {
        keepActiveOnFocusExit = true
        focusMode = false
    }

    function toggleFocus() {
        if (focusMode)
            exitFocus()
        else
            enterFocus()
    }

    function moveFocus(dir) {
        active = ""
        focusIndex = Math.max(0, Math.min(focusIndex + dir, focusItems.length - 1))
    }

    function openFocused() {
        if (focusTarget === "workspaces") {
            toggle("workspaces")
            return
        }

        if (focusTarget === "notifications") {
            toggle("notifications")
            return
        }

        if (focusTarget === "media") {
            active = "media-tab"
            releaseFocusKeepActive()
            return
        }

        open(focusTarget)
    }
}
