pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // ── Cores expostas ───────────────────────────────────────────────────
    property color accent:   "#7aa2f7"
    property color bg:       "#1a1b2e"
    property color fg:       "#c0caf5"
    property color surface:  "#24283b"
    property color muted:    "#565f89"
    property color warn:     "#f7768e"
    property bool pywalActive: true
    property string walPath: "/home/shira/.cache/wal/colors.json"
    property string walSignature: ""

    // ── Cores derivadas ─────────────────────────────────────────────────
    property color pillBg:     Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
    property color pillBorder: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
    property color textMain:   root.fg
    property color textSub:    root.muted
    property color text:       root.fg

    // ── Fade suave quando o pywal16 troca as cores ───────────────────────
    Behavior on accent  { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on bg      { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on fg      { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on surface { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on muted   { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on warn    { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }

    function toColor(hex) {
        hex = (hex || "").replace("#", "")
        if (hex.length !== 6)
            return null

        var r = parseInt(hex.substr(0, 2), 16) / 255
        var g = parseInt(hex.substr(2, 2), 16) / 255
        var b = parseInt(hex.substr(4, 2), 16) / 255

        if (isNaN(r) || isNaN(g) || isNaN(b))
            return null
        return Qt.rgba(r, g, b, 1.0)
    }

    function applyWalJson(raw) {
        if (!raw)
            return

        try {
            var data = JSON.parse(raw)
            var special = data.special || {}
            var colors = data.colors || {}
            var nextSig = (data.checksum || "") + ":" + (data.wallpaper || "")
            if (root.walSignature !== nextSig)
                console.log("[shinbar-colors] pywal changed", nextSig)
            root.walSignature = nextSig

            var c1 = root.toColor(special.background || "#1a1b2e")
            if (c1) root.bg = c1

            var c2 = root.toColor(special.foreground || "#c0caf5")
            if (c2) root.fg = c2

            var c3 = root.toColor(colors.color4 || "#7aa2f7")
            if (c3) root.accent = c3

            var c4 = root.toColor(colors.color0 || "#24283b")
            if (c4) root.surface = c4

            var c5 = root.toColor(colors.color8 || "#565f89")
            if (c5) root.muted = c5

            var c6 = root.toColor(colors.color1 || "#f7768e")
            if (c6) root.warn = c6
        } catch (e) {
            console.log("[shinbar-colors] pywal parse failed", e)
        }
    }

    function refreshWalColors() {
        if (!root.pywalActive || root.walReadProc.running)
            return

        root.walReadProc.exec([
            "python3",
            "-c",
            "import json, os; p=os.path.expanduser('~/.cache/wal/colors.json'); d=json.load(open(p)); print('JSON=' + json.dumps(d, separators=(',', ':')))"
        ])
    }

    onPywalActiveChanged: {
        if (root.pywalActive)
            root.refreshWalColors()
    }

    Component.onCompleted: {
        console.log("[shinbar-colors] started")
        root.refreshWalColors()
    }

    property Process walReadProc: Process {
        running: false

        stdout: SplitParser {
            onRead: function(data) {
                var s = data.trim()
                if (s.startsWith("JSON="))
                    root.applyWalJson(s.slice(5))
            }
        }

        onExited: {
            running = false
        }
    }
}
