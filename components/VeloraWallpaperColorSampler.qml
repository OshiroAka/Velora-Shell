pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    required property url source
    property string fit: "cover"
    readonly property bool ready: pixels.ready
    readonly property int imageStatus: wallpaper.status
    signal selected(string color)
    signal cancelled()
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.cancelled()
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.source
        fillMode: root.fit === "contain" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        visible: true
        onStatusChanged: { if (status === Image.Ready) pixels.loadImage(source) }
    }
    Canvas {
        id: pixels
        anchors.fill: parent
        property bool ready: false
        Component.onCompleted: loadImage(root.source)
        onImageLoaded: { ready = true; requestPaint() }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d")
            c.fillStyle = "black"; c.fillRect(0, 0, width, height)
            if (!ready || wallpaper.sourceSize.width <= 0 || wallpaper.sourceSize.height <= 0) return
            const sx = width / wallpaper.sourceSize.width
            const sy = height / wallpaper.sourceSize.height
            const scale = root.fit === "contain" ? Math.min(sx, sy) : Math.max(sx, sy)
            const w = wallpaper.sourceSize.width * scale
            const h = wallpaper.sourceSize.height * scale
            c.drawImage(root.source, (width-w)/2, (height-h)/2, w, h)
        }
        function sample(x, y) {
            if (!ready) return ""
            const p = getContext("2d").getImageData(Math.floor(x), Math.floor(y), 1, 1).data
            return "#" + [p[0], p[1], p[2]].map(v => Number(v).toString(16).padStart(2, "0")).join("")
        }
    }
    Canvas {
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d"); c.reset()
            c.lineWidth = 1
            for (let offset = 0; offset < 2; offset++) {
                c.strokeStyle = offset ? "#50ffffff" : "#70000000"
                c.beginPath()
                for (let x = 0; x < width; x += 32) { c.moveTo(x+offset, 0); c.lineTo(x+offset, height) }
                for (let y = 0; y < height; y += 32) { c.moveTo(0, y+offset); c.lineTo(width, y+offset) }
                c.stroke()
            }
        }
    }
    Rectangle {
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 60
        width: instructions.implicitWidth + 32; height: 42; radius: 14
        color: "#dc171a22"
        Text {
            id: instructions
            anchors.centerIn: parent; color: "white"; font.pixelSize: 14
            text: wallpaper.status === Image.Error ? "Wallpaper indisponível · Escape para cancelar"
                : !pixels.ready ? "Carregando wallpaper · Escape para cancelar"
                : "Escolha a cor da barra e dos destaques · Escape para cancelar"
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) { root.cancelled(); return }
            const color = pixels.sample(mouse.x, mouse.y)
            if (color) root.selected(color)
        }
    }
        }
