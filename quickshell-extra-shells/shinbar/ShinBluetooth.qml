import Quickshell
import QtQuick
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: 42
    implicitHeight: ShinConfig.barH

    property bool opened: ShinPopup.active === "bluetooth"
    property bool popupVisible: false
    property bool hoverRoot: false
    property bool hoverPopup: false
    property real reveal: opened ? 1.0 : 0.0
    property real pulse: 0.0

    property bool btOn: false
    property string localName: "ShiraOS Machine"
    property string actionAddress: ""
    property string actionKind: "connect"
    property int navIndex: 0

    readonly property int popupW: 620
    readonly property int popupH: 470
    readonly property int deviceCount: connectedModel.count + availableModel.count

    function openPopup() {
        closeTimer.stop()
        hideTimer.stop()
        popupVisible = true
        ShinPopup.open("bluetooth")
        refresh()
    }

    function closePopup() {
        ShinPopup.close("bluetooth")
    }

    function scheduleClose() {
        closeTimer.restart()
    }

    function refresh() {
        if (!btQuery.running)
            btQuery.running = true
    }

    function clampNav() {
        navIndex = Math.max(0, Math.min(navIndex, deviceCount))
    }

    function isDeviceSelected(globalIndex) {
        return opened && ShinPopup.focusMode && navIndex === globalIndex
    }

    function moveNav(delta) {
        if (deviceCount <= 0) {
            navIndex = 0
            return
        }

        navIndex = Math.max(0, Math.min(navIndex + delta, deviceCount))
        ensureNavVisible()
    }

    function ensureNavVisible() {
        var deviceIndex = navIndex

        if (deviceIndex < 0 || deviceIndex >= deviceCount)
            return

        if (deviceIndex < connectedModel.count)
            connectedList.positionViewAtIndex(deviceIndex, ListView.Contain)
        else
            availableList.positionViewAtIndex(deviceIndex - connectedModel.count, ListView.Contain)
    }

    function activateNav() {
        if (navIndex >= deviceCount) {
            resetConnections()
            return
        }

        var deviceIndex = navIndex

        if (deviceIndex < connectedModel.count) {
            var connected = connectedModel.get(deviceIndex)
            setDeviceAction(connected.addr, true)
            return
        }

        var availableIndex = deviceIndex - connectedModel.count

        if (availableIndex >= 0 && availableIndex < availableModel.count) {
            var available = availableModel.get(availableIndex)
            setDeviceAction(available.addr, false)
        }
    }

    function resetConnections() {
        if (connectedModel.count <= 0) {
            refresh()
            return
        }

        var addrs = []

        for (var i = 0; i < connectedModel.count; ++i)
            addrs.push(connectedModel.get(i).addr)

        btReset.command = [
            "bash",
            "-lc",
            "for addr in \"$@\"; do bluetoothctl disconnect \"$addr\" >/dev/null 2>&1 || true; done",
            "shinbar-bt-reset"
        ].concat(addrs)
        btReset.running = true
    }

    function setDeviceAction(addr, connected) {
        actionAddress = addr
        actionKind = connected ? "disconnect" : "connect"
        btAction.command = ["bluetoothctl", actionKind, actionAddress]
        btAction.running = true
    }

    function togglePower() {
        btToggle.command = ["bluetoothctl", "power", root.btOn ? "off" : "on"]
        btToggle.running = true
    }

    function parseLine(line) {
        if (line.indexOf("POWERED=") === 0) {
            btOn = line.slice(8) === "yes"
            return
        }

        if (line.indexOf("LOCAL=") === 0) {
            var local = line.slice(6).split("|")
            localName = local[0] || "ShiraOS Machine"
            return
        }

        if (line.indexOf("DEVICE=") !== 0)
            return

        var parts = line.slice(7).split("|")
        if (parts.length < 6)
            return

        var item = {
            group: parts[0],
            addr: parts[1],
            name: parts[2],
            kind: parts[3],
            connected: parts[4] === "yes",
            battery: parts[5]
        }

        if (item.group === "connected")
            connectedModel.append(item)
        else
            availableModel.append(item)
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            popupVisible = true
            navIndex = 0
            pulseAnim.restart()
            refresh()
        } else {
            hideTimer.restart()
        }
    }

    Behavior on reveal {
        NumberAnimation { duration: ShinData.popupAnim(300); easing.type: Easing.OutBack }
    }

    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: root; property: "pulse"; from: 0.0; to: 1.0; duration: ShinData.popupAnim(160); easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "pulse"; from: 1.0; to: 0.0; duration: ShinData.popupAnim(420); easing.type: Easing.OutCubic }
    }

    Process {
        id: btQuery
        running: false
        command: ["/home/shira/.config/quickshell/shinbar/scripts/shinbar-bluetooth"]
        onStarted: {
            connectedModel.clear()
            availableModel.clear()
        }
        stdout: SplitParser {
            onRead: function(data) {
                root.parseLine(data.trim())
            }
        }
        onExited: running = false
    }

    Process {
        id: btToggle
        running: false
        command: ["true"]
        onExited: {
            running = false
            root.refresh()
        }
    }

    Process {
        id: btAction
        running: false
        command: ["true"]
        onExited: {
            running = false
            root.refresh()
        }
    }

    Process {
        id: btReset
        running: false
        command: ["true"]
        onExited: {
            running = false
            root.refresh()
        }
    }

    Connections {
        target: ShinPopup

        function onInsideNonceChanged() {
            if (ShinPopup.active !== "bluetooth")
                return

            if (ShinPopup.insideY !== 0)
                root.moveNav(ShinPopup.insideY)
            else if (ShinPopup.insideX !== 0)
                root.moveNav(ShinPopup.insideX)
        }

        function onActivateNonceChanged() {
            if (ShinPopup.active === "bluetooth")
                root.activateNav()
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: closeTimer
        interval: 240
        repeat: false
        onTriggered: {
            if (!root.hoverRoot && !root.hoverPopup)
                root.closePopup()
        }
    }

    Timer {
        id: hideTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.popupVisible = false
        }
    }

    ListModel {
        id: connectedModel
        onCountChanged: root.clampNav()
    }

    ListModel {
        id: availableModel
        onCountChanged: root.clampNav()
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        clickable: false
        active: root.opened
        hovered: root.hoverRoot
    }

    BluetoothSignalGlyph {
        anchors.centerIn: parent
        size: 15
        active: root.btOn || root.opened || root.hoverRoot
        glyphColor: root.opened ? ShinColors.accent : root.btOn ? ShinColors.fg : ShinColors.muted
        scale: root.opened ? 1.12 : root.hoverRoot ? 1.06 : 1.0
        Behavior on scale { NumberAnimation { duration: ShinData.anim(150); easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            root.hoverRoot = true
            root.openPopup()
        }
        onExited: {
            root.hoverRoot = false
            root.scheduleClose()
        }
        onClicked: ShinPopup.toggle("bluetooth")
    }

    PopupWindow {
        id: btPopup
        visible: root.popupVisible
        color: "transparent"
        implicitWidth: root.popupW
        implicitHeight: root.popupH

        anchor.item: root
        anchor.rect.x: Math.round(root.implicitWidth / 2 - btPopup.implicitWidth / 2)
        anchor.rect.y: root.implicitHeight + 18
        anchor.rect.width: 1
        anchor.rect.height: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 50
            onEntered: {
                root.hoverPopup = true
                root.openPopup()
            }
            onExited: {
                root.hoverPopup = false
                root.scheduleClose()
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.popupW * (0.94 + root.reveal * 0.06)
            height: root.popupH * (0.94 + root.reveal * 0.06)
            radius: 24
            antialiasing: true
            clip: true
            opacity: root.reveal
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, Math.max(0.66, ShinConfig.popupOpacity))
            border.width: 2
            border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.14 + 0.08 * root.reveal)
            transform: Translate {
                x: 18 * (1.0 - root.reveal)
                y: -14 * (1.0 - root.reveal)
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 18 + root.pulse * 28
                height: parent.height + 18 + root.pulse * 28
                radius: parent.radius + 12
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.26 * root.pulse)
                z: -1
            }

            Text {
                x: 22
                y: 16
                text: "⌄"
                color: ShinColors.fg
                font.pixelSize: 24
                font.family: ShinConfig.fontFamily
            }

            Row {
                x: 44
                y: 42
                spacing: 18
                height: 62

                BluetoothSignalGlyph {
                    width: 76
                    height: 56
                    size: 42
                    active: root.btOn || root.opened
                    glyphColor: ShinColors.fg
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "Bluetooth"
                        color: ShinColors.fg
                        font.pixelSize: 24
                        font.bold: true
                        font.family: ShinConfig.fontFamily
                    }

                    Text {
                        text: "Conecte e gerencie seus dispositivos"
                        color: ShinColors.muted
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                    }
                }
            }

            Rectangle {
                x: parent.width - 238
                y: 50
                width: 82
                height: 32
                radius: 12
                opacity: connectedModel.count > 0 ? 1.0 : 0.52
                color: resetArea.containsMouse || (root.opened && ShinPopup.focusMode && root.navIndex === root.deviceCount)
                    ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)
                    : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.07)
                border.width: root.opened && ShinPopup.focusMode && root.navIndex === root.deviceCount ? 2 : 1
                border.color: root.opened && ShinPopup.focusMode && root.navIndex === root.deviceCount
                    ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.58)
                    : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: "Zerar"
                    color: connectedModel.count > 0 ? ShinColors.fg : ShinColors.muted
                    font.pixelSize: 10
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                }

                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.navIndex = root.deviceCount
                    onClicked: root.resetConnections()
                }

                Behavior on color { ColorAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }
            }

            Rectangle {
                x: parent.width - 146
                y: 50
                width: 64
                height: 32
                radius: 16
                color: root.btOn ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.26) : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.07)
                border.width: 2
                border.color: root.btOn ? ShinColors.accent : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.14)

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    x: root.btOn ? parent.width - width - 6 : 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.btOn ? ShinColors.fg : ShinColors.muted
                    Behavior on x { NumberAnimation { duration: ShinData.anim(180); easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.togglePower()
                }
            }

            Rectangle {
                x: parent.width - 70
                y: 50
                width: 42
                height: 32
                radius: 12
                color: refreshArea.containsMouse ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18) : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.07)
                border.width: 1
                border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: "⋯"
                    color: ShinColors.fg
                    font.pixelSize: 18
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.refresh()
                }
            }

            Column {
                x: 26
                y: 124
                width: parent.width - 64
                spacing: 12

                Text {
                    text: "Este dispositivo"
                    color: ShinColors.fg
                    font.pixelSize: 13
                    font.family: ShinConfig.fontFamily
                }

                DeviceRow {
                    width: parent.width
                    name: root.localName
                    sub: root.btOn ? "Visivel para outros dispositivos" : "Bluetooth desligado"
                    kind: "computer"
                    connected: root.btOn
                    showButton: false
                }

                Text {
                    text: "Dispositivos conectados"
                    color: ShinColors.fg
                    font.pixelSize: 13
                    font.family: ShinConfig.fontFamily
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(54, Math.min(116, connectedList.contentHeight))
                    radius: 18
                    color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.40)
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.09)
                    clip: true

                    ListView {
                        id: connectedList
                        anchors.fill: parent
                        interactive: false
                        model: connectedModel
                        delegate: DeviceRow {
                            width: ListView.view.width
                            name: model.name
                            sub: root.kindLabel(model.kind)
                            kind: model.kind
                            connected: true
                            battery: model.battery
                            globalIndex: index
                            selected: root.isDeviceSelected(index)
                            onAction: root.setDeviceAction(model.addr, true)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: connectedModel.count === 0
                        text: root.btOn ? "Nenhum dispositivo conectado" : "Bluetooth desligado"
                        color: ShinColors.muted
                        font.pixelSize: 11
                        font.family: ShinConfig.fontFamily
                    }
                }

                Text {
                    text: "Dispositivos disponiveis"
                    color: ShinColors.fg
                    font.pixelSize: 13
                    font.family: ShinConfig.fontFamily
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(54, Math.min(128, availableList.contentHeight))
                    radius: 18
                    color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.36)
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.09)
                    clip: true

                    ListView {
                        id: availableList
                        anchors.fill: parent
                        interactive: contentHeight > height
                        model: availableModel
                        delegate: DeviceRow {
                            width: ListView.view.width
                            name: model.name
                            sub: root.kindLabel(model.kind)
                            kind: model.kind
                            connected: false
                            battery: model.battery
                            globalIndex: connectedModel.count + index
                            selected: root.isDeviceSelected(connectedModel.count + index)
                            onAction: root.setDeviceAction(model.addr, false)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: availableModel.count === 0
                        text: root.btOn ? "Nenhum dispositivo conhecido" : "Ligue o Bluetooth para conectar"
                        color: ShinColors.muted
                        font.pixelSize: 11
                        font.family: ShinConfig.fontFamily
                    }
                }
            }
        }
    }

    function kindLabel(kind) {
        if (kind === "headphones") return "Fone de ouvido"
        if (kind === "keyboard") return "Teclado"
        if (kind === "mouse") return "Mouse"
        if (kind === "gamepad") return "Controle"
        if (kind === "speaker") return "Alto-falante"
        if (kind === "phone") return "Smartphone"
        if (kind === "computer") return "Este computador"
        return "Dispositivo"
    }

    component DeviceRow: Rectangle {
        id: row
        property string name: ""
        property string sub: ""
        property string kind: "device"
        property bool connected: false
        property string battery: ""
        property bool showButton: true
        property int globalIndex: -1
        property bool selected: false
        signal action()

        height: 54
        radius: 14
        color: row.selected
            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.12)
            : rowArea.containsMouse ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.07) : "transparent"
        border.width: row.selected ? 2 : 0
        border.color: row.selected
            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.52)
            : "transparent"
        scale: row.selected ? 1.012 : 1.0

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, row.connected ? 0.18 : 0.08)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.16)

                Text {
                    anchors.centerIn: parent
                    text: row.kind === "headphones" ? "󰋋" : row.kind === "keyboard" ? "󰌌" : row.kind === "mouse" ? "󰍽" : row.kind === "gamepad" ? "󰊴" : row.kind === "phone" ? "󰏲" : row.kind === "computer" ? "󰍹" : "󰂱"
                    color: ShinColors.fg
                    font.pixelSize: 19
                    font.family: ShinConfig.fontFamily
                }
            }

            Column {
                width: parent.width - 36 - 198
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    width: parent.width
                    text: row.name
                    color: ShinColors.fg
                    font.pixelSize: 11
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: row.sub
                    color: ShinColors.muted
                    font.pixelSize: 9
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }
            }

            Row {
                width: 150
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                Row {
                    visible: row.connected
                    spacing: 9
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 9
                        height: 9
                        radius: 5
                        color: "#45d483"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Conectado"
                        color: ShinColors.muted
                        font.pixelSize: 11
                        font.family: ShinConfig.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    visible: row.battery.length > 0
                    text: row.battery + "%"
                    color: ShinColors.fg
                    font.pixelSize: 11
                    font.family: ShinConfig.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    visible: row.showButton && !row.connected
                    width: 78
                    height: 26
                    radius: 9
                    color: connectArea.containsMouse ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18) : Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.24)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Conectar"
                        color: ShinColors.fg
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                    }

                    MouseArea {
                        id: connectArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: row.action()
                    }
                }

                Text {
                    text: "›"
                    color: ShinColors.fg
                    font.pixelSize: 22
                    font.family: ShinConfig.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                if (row.showButton && row.globalIndex >= 0)
                    root.navIndex = row.globalIndex
            }
            onClicked: {
                if (row.showButton)
                    row.action()
            }
        }

        Behavior on color { ColorAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: ShinData.anim(140); easing.type: Easing.OutCubic } }
    }

    component BluetoothSignalGlyph: Item {
        id: glyph

        property color glyphColor: ShinColors.fg
        property bool active: true
        property real size: 16
        property real wave: 0.0

        width: size + 28
        height: Math.max(size + 8, 22)

        NumberAnimation {
            target: glyph
            property: "wave"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(1450)
            loops: Animation.Infinite
            running: ShinData.effectsEnabled && glyph.active
        }

        Text {
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            text: "󰂯"
            color: glyph.glyphColor
            opacity: glyph.active ? 1.0 : 0.72
            font.pixelSize: glyph.size
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
        }

        Repeater {
            model: 3

            Text {
                property real phase: (glyph.wave + index * 0.24) % 1.0

                x: glyph.size * 0.58 + index * glyph.size * 0.22
                y: Math.round((glyph.height - height) / 2)
                text: ")"
                color: glyph.glyphColor
                opacity: glyph.active ? Math.max(0.10, 0.62 * (1.0 - phase)) : 0.0
                scale: 0.78 + phase * 0.42
                font.pixelSize: glyph.size * (0.78 + index * 0.13)
                font.family: ShinConfig.fontFamily
                transformOrigin: Item.Left
            }
        }
    }
}
