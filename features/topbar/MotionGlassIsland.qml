import QtQuick

GlassIsland {
    id: root

    required property var motion
    property int revealOrder: 0
    property bool revealed: false

    opacity: revealed ? 1 : 0
    scale: revealed ? 1 : 0.94
    transformOrigin: Item.Center

    transform: Translate {
        y: root.revealed ? 0 : -7

        Behavior on y {
            NumberAnimation {
                duration: root.motion.morph
                easing.type: Easing.OutCubic
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.motion.selection
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.motion.morph
            easing.type: Easing.OutBack
            easing.overshoot: 1.08
        }
    }

    Timer {
        interval: Math.max(1, root.motion.stagger * root.revealOrder + 18)
        running: true
        repeat: false
        onTriggered: root.revealed = true
    }
}
