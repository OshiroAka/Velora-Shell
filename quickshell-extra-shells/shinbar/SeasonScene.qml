import QtQuick
import "."

Item {
    id: root

    width: 150
    height: 160
    clip: false

    property string season: "autumn"
    property bool active: true
    property bool preferGif: false
    property int px: 3

    function leafPalette() {
        if (season === "autumn")
            return ["#f5b322", "#ef9800", "#db7a10", "#c45f0b", "#ffd35b", "#a94414"]

        if (season === "winter")
            return ["#dfe8ef", "#eef5fb", "#c3d0d9", "#9ba9b2", "#ffffff"]

        if (season === "spring")
            return ["#ffbfd1", "#ff9db8", "#ffd8e5", "#9adf92", "#6ec56c", "#f5a8c5"]

        return ["#39c84c", "#51d45f", "#7ce872", "#2eaa43", "#95f16b", "#2f8f45"]
    }

    function trunkPalette() {
        return ["#8f572f", "#7a4726", "#6e3f22", "#9e6538", "#5e341b"]
    }

    function particlePalette() {
        if (season === "autumn")
            return ["#f5b322", "#ef9800", "#db7a10", "#ffd35b", "#c45f0b"]

        if (season === "winter")
            return ["#ffffff", "#dfeef8", "#c9d9e6", "#eef7ff"]

        if (season === "spring")
            return ["#ffbfd1", "#ffd9e7", "#f7a7c3", "#e1ffd6", "#ffc0d4"]

        return ["#fff39a", "#fff0b8", "#d2ff9b", "#ffe37c"]
    }

    function leafColor(i) {
        const p = leafPalette()
        return p[i % p.length]
    }

    function trunkColor(i) {
        const p = trunkPalette()
        return p[i % p.length]
    }

    function particleColor(i) {
        const p = particlePalette()
        return p[i % p.length]
    }

    // Se você no futuro adicionar um GIF melhor:
    AnimatedImage {
        id: gifTree
        anchors.fill: parent
        source: root.preferGif ? Qt.resolvedUrl("assets/seasons/" + root.season + "/tree.gif") : ""
        playing: root.active
        visible: root.preferGif && status === Image.Ready
        fillMode: Image.PreserveAspectFit
        cache: false
    }

    Item {
        id: painter
        anchors.fill: parent
        visible: !gifTree.visible

        Rectangle {
            id: aura
            width: 92
            height: 92
            radius: 46
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            color: season === "winter"
                ? Qt.rgba(0.84, 0.93, 1.0, 0.10)
                : season === "autumn"
                    ? Qt.rgba(1.0, 0.62, 0.08, 0.08)
                    : season === "spring"
                        ? Qt.rgba(1.0, 0.70, 0.82, 0.08)
                        : Qt.rgba(0.40, 0.95, 0.45, 0.07)

            SequentialAnimation on opacity {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation { from: 0.55; to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.0; to: 0.55; duration: 1500; easing.type: Easing.InOutSine }
            }
        }

        Item {
            id: treeWrap
            width: 112
            height: 138
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            // copa mais "redonda" e bonita, inspirada na referência
            property var canopyPixels: [
                [17,1],[18,1],[19,1],[20,1],[21,1],
                [14,2],[15,2],[16,2],[17,2],[18,2],[19,2],[20,2],[21,2],[22,2],[23,2],[24,2],
                [12,3],[13,3],[14,3],[15,3],[16,3],[17,3],[18,3],[19,3],[20,3],[21,3],[22,3],[23,3],[24,3],[25,3],[26,3],
                [10,4],[11,4],[12,4],[13,4],[14,4],[15,4],[16,4],[17,4],[18,4],[19,4],[20,4],[21,4],[22,4],[23,4],[24,4],[25,4],[26,4],[27,4],
                [9,5],[10,5],[11,5],[12,5],[13,5],[14,5],[15,5],[16,5],[17,5],[18,5],[19,5],[20,5],[21,5],[22,5],[23,5],[24,5],[25,5],[26,5],[27,5],[28,5],
                [8,6],[9,6],[10,6],[11,6],[12,6],[13,6],[14,6],[15,6],[16,6],[17,6],[18,6],[19,6],[20,6],[21,6],[22,6],[23,6],[24,6],[25,6],[26,6],[27,6],
                [8,7],[9,7],[10,7],[11,7],[12,7],[13,7],[14,7],[15,7],[16,7],[17,7],[18,7],[19,7],[20,7],[21,7],[22,7],[23,7],[24,7],[25,7],[26,7],[27,7],
                [9,8],[10,8],[11,8],[12,8],[13,8],[14,8],[15,8],[16,8],[17,8],[18,8],[19,8],[20,8],[21,8],[22,8],[23,8],[24,8],[25,8],[26,8],
                [11,9],[12,9],[13,9],[14,9],[15,9],[16,9],[17,9],[18,9],[19,9],[20,9],[21,9],[22,9],[23,9],[24,9],[25,9],
                [13,10],[14,10],[15,10],[16,10],[17,10],[18,10],[19,10],[20,10],[21,10],[22,10],[23,10],
                [16,11],[17,11],[18,11],[19,11],[20,11]
            ]

            // "almofadas" laterais para deixar mais orgânica, parecida com a referência
            property var leftCanopy: [
                [7,8],[8,8],[9,8],[10,8],
                [5,9],[6,9],[7,9],[8,9],[9,9],[10,9],
                [4,10],[5,10],[6,10],[7,10],[8,10],[9,10],[10,10],[11,10],
                [4,11],[5,11],[6,11],[7,11],[8,11],[9,11],[10,11],[11,11],
                [5,12],[6,12],[7,12],[8,12],[9,12],[10,12],
                [7,13],[8,13],[9,13]
            ]

            property var rightCanopy: [
                [24,8],[25,8],[26,8],[27,8],
                [24,9],[25,9],[26,9],[27,9],[28,9],[29,9],
                [24,10],[25,10],[26,10],[27,10],[28,10],[29,10],[30,10],[31,10],
                [25,11],[26,11],[27,11],[28,11],[29,11],[30,11],[31,11],
                [26,12],[27,12],[28,12],[29,12],[30,12],
                [27,13],[28,13],[29,13]
            ]

            property var trunkBlocks: [
                [17,12,1,3],[18,12,1,4],[19,12,1,4],
                [16,15,1,4],[17,15,1,5],[18,15,1,6],[19,15,1,6],[20,15,1,5],
                [15,19,1,3],[16,19,1,5],[17,19,1,7],[18,19,1,7],[19,19,1,7],[20,19,1,5],[21,19,1,3],
                [16,26,1,4],[17,26,1,4],[18,26,1,4],[19,26,1,4]
            ]

            property var leftBranchBlocks: [
                [15,15,2,1],[13,16,2,1],[12,17,2,1],[11,18,2,1],
                [14,17,2,1],[13,18,1,1]
            ]

            property var rightBranchBlocks: [
                [20,15,2,1],[22,16,2,1],[23,17,2,1],[24,18,2,1],
                [21,17,2,1],[23,18,1,1]
            ]

            // sem "terra", apenas raízes leves
            property var rootsBlocks: [
                [14,30,2,1],[13,31,1,1],[12,32,1,1],
                [16,30,2,1],[18,30,2,1],
                [20,30,2,1],[22,31,1,1],[23,32,1,1],
                [15,31,1,1],[19,31,1,1],[17,32,1,1],[18,32,1,1]
            ]

            Repeater {
                model: treeWrap.canopyPixels
                delegate: Rectangle {
                    x: modelData[0] * root.px
                    y: modelData[1] * root.px
                    width: root.px
                    height: root.px
                    radius: root.season === "winter" ? 1 : 0
                    color: root.leafColor(index)
                    opacity: root.season === "winter" ? 0.82 : 1

                    Behavior on color {
                        ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }
            }

            Repeater {
                model: treeWrap.leftCanopy
                delegate: Rectangle {
                    x: modelData[0] * root.px
                    y: modelData[1] * root.px
                    width: root.px
                    height: root.px
                    radius: root.season === "winter" ? 1 : 0
                    color: root.leafColor(index + 2)
                    opacity: root.season === "winter" ? 0.78 : 0.98
                }
            }

            Repeater {
                model: treeWrap.rightCanopy
                delegate: Rectangle {
                    x: modelData[0] * root.px
                    y: modelData[1] * root.px
                    width: root.px
                    height: root.px
                    radius: root.season === "winter" ? 1 : 0
                    color: root.leafColor(index + 3)
                    opacity: root.season === "winter" ? 0.78 : 0.98
                }
            }

            Repeater {
                model: treeWrap.leftBranchBlocks
                delegate: Rectangle {
                    x: modelData[0] * root.px
                    y: modelData[1] * root.px
                    width: modelData[2] * root.px
                    height: modelData[3] * root.px
                    color: root.trunkColor(index + 1)
                }
            }

            Repeater {
                model: treeWrap.rightBranchBlocks
                delegate: Rectangle {
                    x: modelData[0] * root.px
                    y: modelData[1] * root.px
                    width: modelData[2] * root.px
                    height: modelData[3] * root.px
                    color: root.trunkColor(index + 2)
                }
            }

            Repeater {
                model: treeWrap.trunkBlocks
                delegate: Rectangle {
                    x: modelData[0] * root.px
                    y: modelData[1] * root.px
                    width: modelData[2] * root.px
                    height: modelData[3] * root.px
                    color: root.trunkColor(index)
                }
            }

            Repeater {
                model: treeWrap.rootsBlocks
                delegate: Rectangle {
                    x: modelData[0] * root.px
                    y: modelData[1] * root.px
                    width: modelData[2] * root.px
                    height: modelData[3] * root.px
                    color: root.trunkColor(index + 1)
                    opacity: 0.92
                }
            }
        }

        // partículas sazonais discretas
        Repeater {
            model: root.season === "summer" ? 12 : 16

            delegate: Rectangle {
                id: particle

                property real baseX: 16 + ((index * 31) % (root.width - 32))
                property real sway: root.season === "winter" ? 14 : 20

                width: root.season === "winter" ? 3 : root.season === "summer" ? 3 : 4
                height: width
                radius: root.season === "winter" || root.season === "summer" ? width / 2 : 1

                x: baseX
                y: -10 - (index % 6) * 12
                color: root.particleColor(index)
                opacity: root.season === "summer" ? 0.75 : 0.90
                rotation: root.season === "winter" || root.season === "summer" ? 0 : 45

                SequentialAnimation on y {
                    running: root.active
                    loops: Animation.Infinite
                    PauseAnimation { duration: (index % 8) * 120 }

                    NumberAnimation {
                        from: -12 - (index % 5) * 10
                        to: root.height + 10
                        duration: root.season === "winter"
                            ? 3800 + (index % 4) * 240
                            : root.season === "summer"
                                ? 2500 + (index % 4) * 180
                                : 2900 + (index % 4) * 210
                        easing.type: Easing.Linear
                    }
                }

                SequentialAnimation on x {
                    running: root.active
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: particle.baseX
                        to: particle.baseX + particle.sway
                        duration: 1500 + (index % 4) * 180
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: particle.baseX + particle.sway
                        to: particle.baseX - particle.sway * 0.45
                        duration: 1500 + (index % 4) * 180
                        easing.type: Easing.InOutSine
                    }
                }

                RotationAnimation on rotation {
                    running: root.active && root.season !== "winter" && root.season !== "summer"
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 2100 + (index % 4) * 240
                }

                SequentialAnimation on opacity {
                    running: root.active && root.season === "summer"
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.25; to: 1.0; duration: 600 + (index % 3) * 80; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.25; duration: 600 + (index % 3) * 80; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
