import QtQuick

WidgetSurface {
    id: root
    required property var clock
    readonly property bool analog: variantId === "analog"
    readonly property bool dotted: variantId === "dots"
    readonly property bool minimal: variantId === "minimal"
    readonly property string displayFont: String(itemStyle.displayFontFamily || "").length
        ? itemStyle.displayFontFamily : orbitron.name
    FontLoader { id: orbitron; source: "../../assets/fonts/Orbitron-Variable.ttf" }
    width: 350; height: 140

    Item {
        id: face
        visible: root.analog
        width: Math.min(root.width - 42, root.height - 60); height: width
        anchors.horizontalCenter: parent.horizontalCenter; y: 18
        Repeater {
            model: 60
            Item {
                required property int index
                anchors.centerIn: parent; width: 1; height: face.height
                rotation: index * 6
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 0
                    width: parent.index % 5 === 0 ? 3 : 1
                    height: parent.index % 5 === 0 ? 10 : 4
                    radius: 1; color: root.contentColor
                    opacity: parent.index % 5 === 0 ? .8 : .25
                }
            }
        }
        Repeater {
            model: [{length: .25, thickness: 5, angle: (root.clock.now.getHours() % 12 + root.clock.now.getMinutes() / 60) * 30},
                {length: .36, thickness: 3, angle: root.clock.now.getMinutes() * 6}]
            Item {
                required property var modelData
                anchors.centerIn: parent; width: 1; height: 1
                rotation: modelData.angle
                Behavior on rotation {
                    RotationAnimation { duration: root.motionDuration; direction: RotationAnimation.Shortest; easing.type: Easing.OutCubic }
                }
                Rectangle {
                    x: -parent.modelData.thickness / 2
                    y: -face.height * parent.modelData.length
                    width: parent.modelData.thickness; height: face.height * parent.modelData.length + 9
                    radius: width / 2; color: root.contentColor
                }
            }
        }
        Rectangle { anchors.centerIn: parent; width: 9; height: 9; radius: 5; color: root.contentColor }
    }
    Text {
        visible: root.dotted; x: 24; y: 17; width: parent.width - 48
        text: root.clock.locale().toString(root.clock.now, "dddd · dd MMM yyyy").toUpperCase()
        font.family: root.contentFont; font.pixelSize: 10 * root.fontScale
        font.letterSpacing: 1; color: root.mutedColor; elide: Text.ElideRight
    }
    DotMatrixText {
        objectName: "clock.dots"; visible: root.dotted
        x: 24; y: 47; width: parent.width - 48; height: parent.height - 94
        text: root.clock.timeText; color: root.contentColor
        duration: root.motionDuration; pulseColon: true
    }
    Text {
        visible: !root.analog && !root.dotted
        x: 20; y: 12; width: parent.width - 40; height: parent.height * .61
        text: root.clock.timeText; color: root.contentColor
        font.family: root.minimal ? root.contentFont : root.displayFont
        font.pixelSize: Math.min(root.width * .18, root.height * .47) * root.fontScale
        font.weight: root.minimal ? Font.Light : Font.Medium
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.Fit; minimumPixelSize: 10
    }
    Text {
        x: 18; width: parent.width - 36
        y: root.analog ? face.y + face.height + 15 : parent.height - (root.dotted ? 33 : 35)
        text: root.dotted ? "HORA LOCAL" : root.clock.dateText
        color: root.mutedColor; font.family: root.contentFont
        font.pixelSize: (root.dotted ? 9 : 11) * root.fontScale
        font.letterSpacing: root.dotted ? 3 : 0
        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
    }
}
