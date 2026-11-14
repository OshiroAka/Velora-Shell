import QtQuick

Item {
    id: root

    property string iconName: "help"
    property color iconColor: "white"
    property bool filled: false
    property bool disabled: false
    property int symbolWeight: filled ? 600 : 400
    property real opticalSize: Math.max(20, Math.min(48, Math.round(Math.min(width, height))))
    property real glyphScale: 1.0

    readonly property var aliases: ({
        "airplane": "airplanemode_active",
        "apps": "apps",
        "battery": "battery_full",
        "bell": "notifications",
        "bluetooth": "bluetooth",
        "box": "apps",
        "brightness": "brightness_6",
        "browser": "language",
        "calendar": "calendar_month",
        "chat": "chat",
        "clock": "schedule",
        "cloud": "cloud",
        "controller": "sports_esports",
        "display": "desktop_windows",
        "discord": "chat",
        "download": "download",
        "drop": "water_drop",
        "drive": "hard_drive",
        "edit": "edit",
        "files": "folder",
        "folder": "folder",
        "globe": "language",
        "grid": "grid_view",
        "headphones": "headphones",
        "heart": "favorite",
        "home": "home",
        "image": "image",
        "keyboard": "keyboard",
        "language": "language",
        "leaf": "eco",
        "lock": "lock",
        "location": "location_on",
        "logout": "logout",
        "mail": "mail",
        "map": "map",
        "memo": "article",
        "mic": "mic",
        "mic-muted": "mic_off",
        "moon": "do_not_disturb_on",
        "mouse": "mouse",
        "music": "music_note",
        "notifications": "notifications",
        "notifications-off": "notifications_off",
        "palette": "palette",
        "paint": "format_paint",
        "partly": "partly_cloudy_day",
        "pause": "pause",
        "pencil": "edit",
        "person": "person",
        "phone": "smartphone",
        "play": "play_arrow",
        "plus": "add",
        "power": "power_settings_new",
        "refresh": "refresh",
        "rotate": "screen_rotation",
        "rain": "water_drop",
        "screenshot": "screenshot",
        "search": "search",
        "settings": "settings",
        "shuffle": "shuffle",
        "skip-next": "skip_next",
        "skip-previous": "skip_previous",
        "speaker": "speaker",
        "spark": "star",
        "sun": "brightness_6",
        "suncloud": "partly_cloudy_day",
        "terminal": "terminal",
        "theme": "palette",
        "tune": "tune",
        "utensils": "restaurant",
        "user": "person",
        "visibility": "visibility",
        "volume": "volume_up",
        "volume-muted": "volume_off",
        "wallpaper": "wallpaper",
        "weather": "partly_cloudy_day",
        "wifi": "wifi",
        "wifi-off": "wifi_off",
        "wind": "air",
        "workspaces": "workspaces"
    })
    readonly property string symbolName: aliases[iconName] || iconName || "help"
    readonly property bool fontReady: symbolFont.status === FontLoader.Ready

    implicitWidth: 24
    implicitHeight: 24

    FontLoader {
        id: symbolFont
        source: Qt.resolvedUrl("../assets/fonts/MaterialSymbolsRounded-subset.ttf")
    }

    Text {
        anchors.centerIn: parent
        visible: root.fontReady
        text: root.symbolName
        color: root.iconColor
        opacity: root.disabled ? 0.38 : 1
        font.family: symbolFont.name
        font.pixelSize: Math.max(1, Math.round(Math.min(root.width, root.height) * root.glyphScale))
        font.weight: root.symbolWeight
        font.variableAxes: ({
            "FILL": root.filled ? 1 : 0,
            "wght": root.symbolWeight,
            "GRAD": 0,
            "opsz": root.opticalSize
        })
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }

    Text {
        anchors.centerIn: parent
        visible: !root.fontReady
        text: "?"
        color: root.iconColor
        opacity: root.disabled ? 0.38 : 0.74
        font.pixelSize: Math.max(10, Math.round(Math.min(root.width, root.height) * 0.62))
        font.weight: Font.DemiBold
    }
}
