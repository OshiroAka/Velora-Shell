pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property color accent:   "#7aa2f7"
    property color bg:       "#1a1b2e"
    property color fg:       "#c0caf5"
    property color surface:  "#24283b"
    property color muted:    "#565f89"
    property color warn:     "#f7768e"

    property bool pywalActive: true
    property string walPath: "/home/shira/.cache/wal/colors.json"
    property string walSignature: ""
    property string walLastError: ""

    property color pillBg:     Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
    property color pillBorder: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
    property color textMain:   root.fg
    property color textSub:    root.muted
    property color text:       root.fg

    Behavior on accent  { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on bg      { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on fg      { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on surface { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on muted   { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on warn    { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }

    function normalizeHex(hex, fallback) {
        var h = (hex || "").replace("#", "")
        if (h.length !== 6)
            return fallback

        var r = parseInt(h.substr(0, 2), 16)
        var g = parseInt(h.substr(2, 2), 16)
        var b = parseInt(h.substr(4, 2), 16)
        if (isNaN(r) || isNaN(g) || isNaN(b))
            return fallback

        return "#" + h
    }

    function toColor(hex, fallback) {
        var h = root.normalizeHex(hex, fallback || "#ffffff").replace("#", "")
        return Qt.rgba(
            parseInt(h.substr(0, 2), 16) / 255,
            parseInt(h.substr(2, 2), 16) / 255,
            parseInt(h.substr(4, 2), 16) / 255,
            1.0
        )
    }

    function applyPalette(bgHex, fgHex, accentHex, surfaceHex, mutedHex, warnHex, signature) {
        var sig = signature || [bgHex, fgHex, accentHex, surfaceHex, mutedHex, warnHex].join(":")
        if (root.walSignature !== sig)
            console.log("[shinbar-colors] live palette", sig)

        root.walSignature = sig
        root.walLastError = ""

        root.bg = root.toColor(bgHex, "#1a1b2e")
        root.fg = root.toColor(fgHex, "#c0caf5")
        root.accent = root.toColor(accentHex, "#7aa2f7")
        root.surface = root.toColor(surfaceHex, "#24283b")
        root.muted = root.toColor(mutedHex, "#565f89")
        root.warn = root.toColor(warnHex, "#f7768e")
    }

    function applyBridgeLine(line) {
        var s = (line || "").trim()
        if (s.length === 0)
            return

        if (s.startsWith("ERR=")) {
            root.walLastError = s.slice(4)
            console.log("[shinbar-colors] bridge error", root.walLastError)
            return
        }

        if (!s.startsWith("PAL="))
            return

        var parts = s.slice(4).split("|")
        if (parts.length < 7) {
            root.walLastError = "paleta incompleta: " + s
            return
        }

        root.applyPalette(parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[0])
    }

    function refreshWalColors() {
        if (!root.pywalActive || readOnceProc.running)
            return
        readOnceProc.running = true
    }

    Component.onCompleted: {
        console.log("[shinbar-colors] ready")
        root.refreshWalColors()
    }

    property Process readOnceProc: Process {
        running: false
        command: [
            "/home/shira/.config/quickshell/shinbar/scripts/shinbar-pywal-bridge",
            "--emit"
        ]

        stdout: SplitParser {
            onRead: function(data) {
                root.applyBridgeLine(data)
            }
        }

        onExited: running = false
    }
}
