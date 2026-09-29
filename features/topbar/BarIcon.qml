import QtQuick

// Optical sizes and silhouettes follow the supplied menu-bar references.
// Vector drawing keeps the small strokes crisp at fractional desktop scales.
Canvas {
    id: root
    property string name: "controls"
    property color color: "white"
    property real level: 1
    property bool muted: false
    property bool connected: false
    property int frame: 0
    implicitWidth: 20; implicitHeight: 20
    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onLevelChanged: requestPaint()
    onMutedChanged: requestPaint()
    onConnectedChanged: requestPaint()
    onFrameChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset()
        c.scale(width / 24, height / 24)
        c.strokeStyle = color; c.fillStyle = color
        c.lineWidth = 1.8; c.lineCap = "round"; c.lineJoin = "round"
        function line(x,y,x2,y2) { c.beginPath();c.moveTo(x,y);c.lineTo(x2,y2);c.stroke() }
        function oval(x,y,rx,ry,fill) { c.beginPath();c.ellipse(x-rx,y-ry,rx*2,ry*2);fill?c.fill():c.stroke() }
        function round(x,y,w,h,r) { c.beginPath();c.roundedRect(x,y,w,h,r,r);c.stroke() }
        if (name === "wifi") {
            c.lineWidth = 2.5
            for (let i=0;i<3;i++) {
                c.globalAlpha = connected && level >= (i+1)/4 ? 1 : 0.25
                c.beginPath();c.arc(12,20,5+i*4,-2.35,-0.79);c.stroke()
            }
            c.globalAlpha=1;oval(12,19,1.5,1.5,true)
            if(muted) line(3,3,21,21)
        } else if(name === "monitor") {
            round(2,3,20,14,2);line(12,17,12,21);line(7,21,17,21)
        } else if(name === "paint") {
            c.beginPath();c.moveTo(10,14);c.lineTo(18,3);c.quadraticCurveTo(22,0,22,5);c.lineTo(14,17);c.closePath();c.stroke()
            c.beginPath();c.moveTo(11,15);c.bezierCurveTo(3,12,7,21,2,21);c.bezierCurveTo(10,24,15,21,13,17);c.stroke()
        } else if(name === "search") {
            oval(10,10,6,6,false);line(14.6,14.6,20,20)
        } else if(name === "controls") {
            round(3,3,18,7,3.5); round(3,14,18,7,3.5)
            oval(7,6.5,1.9,1.9,true);oval(17,17.5,1.9,1.9,true)
        } else if(name === "caffeine") {
            c.lineWidth=1.3
            c.beginPath();c.moveTo(3,10);c.bezierCurveTo(3,20,17,21,18,10);c.stroke()
            oval(10.5,9,7.5,3.6,false);oval(10.5,9,5.6,2.1,true)
            c.beginPath();c.moveTo(18,10);c.bezierCurveTo(24,7,23,17,17,16);c.stroke()
            c.beginPath();c.moveTo(1,17);c.bezierCurveTo(6,23,19,23,22,16);c.stroke()
        } else if(name === "notes" || name === "thing") {
            c.lineWidth=1.45
            c.beginPath();c.moveTo(6,3);c.lineTo(14,3);c.lineTo(20,9);c.lineTo(20,21);c.lineTo(6,21);c.closePath();c.stroke()
            c.beginPath();c.moveTo(14,3);c.lineTo(14,9);c.lineTo(20,9);c.stroke()
        } else if(name === "usb") {
            // Small outlined device, as in the USB Status device rows.
            round(7,2,10,20,2);line(10,18.5,14,18.5)
        } else if(name === "cat") {
            c.scale(24/34,1)
            const p = Math.sin(frame*Math.PI/2)
            c.lineWidth=2
            c.beginPath();c.moveTo(11,13);c.bezierCurveTo(6,10,5,17,1,15);c.stroke()
            c.beginPath();c.moveTo(9,13);c.bezierCurveTo(12,7,19,9,23,7)
            c.lineTo(25,3);c.lineTo(27,6);c.lineTo(30,3);c.lineTo(30,8)
            c.bezierCurveTo(34,11,29,14,25,12);c.bezierCurveTo(21,16,16,16,10,16);c.closePath();c.fill()
            c.lineWidth=2.3
            line(12,15,10-p*3,20);line(15,15,17+p*3,20)
            line(23,12,22+p*3,18);line(25,12,28-p*2,17)
            c.globalCompositeOperation="destination-out";oval(28,8,0.7,0.8,true)
        } else if(name === "clock") {
            oval(12,12,9,9,false);line(12,6,12,12);line(12,12,16,14)
        } else if(name === "close") { line(6,6,18,18);line(18,6,6,18) }
    }
}
