import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "."

PanelWindow {
    id: win

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shinbar-workspaces"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitHeight: 340

    property bool panelOpen: ShinPopup.active === "workspaces"
    property real panelReveal: panelOpen ? 1.0 : 0.0

    property int panelX: Math.max(8, ShinConfig.barMarginH)
    property int panelY: ShinConfig.barH + ShinConfig.barMarginT + 22

    property int cardW: 170
    property int cardH: 108
    property int gridGap: 12

    function wsWindowCount(ws) {
        if (!ws)
            return 0

        try {
            if (ws.toplevels && ws.toplevels.count !== undefined)
                return ws.toplevels.count
        } catch (e) {
        }

        try {
            if (ws.lastIpcObject && ws.lastIpcObject.windows !== undefined)
                return ws.lastIpcObject.windows
        } catch (e2) {
        }

        return 0
    }

    function wsOccupied(ws) {
        return wsWindowCount(ws) > 0
    }

    function titleOf(t) {
        if (!t)
            return "App"

        var title = t.title || ""
        if (title.length > 0)
            return title

        var ipc = t.lastIpcObject || {}
        return ipc.class || ipc.initialClass || "App"
    }

    function windowsForWs(ws) {
        var out = []
        var list = Hyprland.toplevels.values || []
        for (var i = 0; i < list.length; i++) {
            var t = list[i]
            if (t && t.workspace && ws && t.workspace.id === ws.id) {
                out.push(t)
                if (out.length >= 3)
                    break
            }
        }
        return out
    }

    function refreshNow() {
        try {
            Hyprland.refreshWorkspaces()
            Hyprland.refreshToplevels()
        } catch (e) {
            console.log("refreshWorkspaces falhou:", e)
        }
    }

    visible: panelOpen || panelReveal > 0.01

    onPanelOpenChanged: {
        if (panelOpen)
            refreshNow()
    }

    Behavior on panelReveal {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        interval: 900
        running: win.panelOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: win.refreshNow()
    }

    Item {
        x: panelX
        y: panelY
        width: Math.min(820, win.width - panelX * 2)
        height: 270
        visible: win.panelReveal > 0.01
        opacity: win.panelReveal

        transform: Translate {
            y: Math.round((1.0 - win.panelReveal) * -10)
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: "Workspaces"
                    color: ShinColors.fg
                    font.pixelSize: 15
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    text: "• ocupadas e ao vivo"
                    color: ShinColors.muted
                    font.pixelSize: 11
                    font.family: ShinConfig.fontFamily
                }
            }

            Flickable {
                width: parent.width
                height: parent.height - 34
                clip: true
                contentWidth: flow.implicitWidth
                contentHeight: flow.implicitHeight

                Flow {
                    id: flow
                    width: parent.width
                    spacing: win.gridGap

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Item {
                            property var ws: modelData
                            property int windowCount: win.wsWindowCount(ws)
                            property bool occupied: win.wsOccupied(ws)

                            visible: occupied
                            width: occupied ? win.cardW : 0
                            height: occupied ? win.cardH : 0

                            Rectangle {
                                anchors.fill: parent
                                radius: 20

                                color: ws.focused
                                    ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.22)
                                    : ws.active
                                        ? Qt.rgba(1, 1, 1, 0.10)
                                        : Qt.rgba(1, 1, 1, 0.06)

                                border.width: 1
                                border.color: ws.focused
                                    ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.65)
                                    : ws.urgent
                                        ? Qt.rgba(1, 0.35, 0.35, 0.45)
                                        : Qt.rgba(1, 1, 1, 0.10)
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        text: ws.name && ws.name.length > 0 ? ws.name : ("Workspace " + ws.id)
                                        color: ShinColors.fg
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: ShinConfig.fontFamily
                                    }

                                    Text {
                                        text: windowCount + " app" + (windowCount === 1 ? "" : "s")
                                        color: ShinColors.muted
                                        font.pixelSize: 10
                                        font.family: ShinConfig.fontFamily
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Qt.rgba(1, 1, 1, 0.07)
                                }

                                Column {
                                    width: parent.width
                                    height: 34
                                    spacing: 2

                                    Repeater {
                                        model: win.windowsForWs(ws)

                                        delegate: Text {
                                            width: parent.width
                                            height: 14
                                            text: "• " + win.titleOf(modelData)
                                            color: ws.focused ? ShinColors.accent : ShinColors.fg
                                            opacity: ws.focused ? 0.95 : 0.74
                                            font.pixelSize: 9
                                            font.family: ShinConfig.fontFamily
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    text: ws.focused
                                        ? "Atual"
                                        : ws.active
                                            ? "Ativa neste monitor"
                                            : "Clique para ir"
                                    color: ws.focused ? ShinColors.accent : ShinColors.muted
                                    font.pixelSize: 11
                                    font.family: ShinConfig.fontFamily
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ws.activate()
                                    ShinPopup.active = ""
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "Se nada aparecer, provavelmente o Hyprland ainda não devolveu janelas para as workspaces."
                color: ShinColors.muted
                font.pixelSize: 11
                font.family: ShinConfig.fontFamily
                visible: flow.children.length <= 1
            }
        }
    }
}
