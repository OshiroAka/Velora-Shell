import QtQuick
import QtQuick.Controls
import "TimerGeometry.js" as Geometry

Item {
    id: root
    required property var theme
    required property var timerService
    property bool customOpen: false
    property bool presented: true
    property real customReveal: customOpen ? 1 : 0
    Behavior on customReveal { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
    readonly property bool paused: !timerService.countdown.running && !timerService.finished
        && timerService.engaged

    component TextButton: Button {
        id: button
        implicitWidth: Math.max(30, contentItem.implicitWidth + 10)
        implicitHeight: 26
        padding: 3
        hoverEnabled: true
        Accessible.name: text
        Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.InOutCubic } }
        background: Rectangle {
            radius: 5
            color: button.hovered || button.down || button.activeFocus
                ? root.theme.withAlpha(root.theme.textPrimary, 0.08) : "transparent"
            border.width: button.activeFocus ? 1 : 0
            border.color: root.theme.accentSoft
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        contentItem: TimerLabel {
            text: button.text
            color: root.theme.textPrimary
            family: root.theme.bodyFont
            pixelSize: 12
            animate: root.presented
        }
    }

    Item {
        id: ruler
        anchors.left: parent.left; anchors.right: parent.right
        height: 18
        property real overdrag: 0
        Behavior on overdrag {
            enabled: !rulerPointer.pressed
            NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
        }
        property real previewMinutes: root.timerService.duration / 60000
        readonly property real markerMinutes: rulerPointer.pressed ? previewMinutes
            : root.timerService.remaining / 60000
        Item {
            id: rulerVisual
            objectName: "timerRulerVisual"
            x: Math.min(0, ruler.overdrag)
            width: ruler.width + Math.abs(ruler.overdrag)
            height: ruler.height
        Repeater {
            model: 101
            Rectangle {
                required property int index
                x: index * (rulerVisual.width - 1) / 100
                y: 1
                width: 1; height: index % 5 === 0 ? 17 : 14
                color: root.theme.withAlpha(root.theme.textPrimary, index % 5 === 0 ? 0.30 : 0.14)
            }
        }
        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, ruler.markerMinutes / 60 * parent.width))
            Behavior on x { enabled: !rulerPointer.pressed; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            width: 2; height: parent.height
            color: root.theme.textPrimary
        }
        }
        MouseArea {
            id: rulerPointer
            objectName: "timerRulerInput"
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            preventStealing: true
            function preview(mouseX) {
                ruler.previewMinutes = Math.max(1, Math.min(60, Math.round(mouseX / width * 60)))
                const overflow = mouseX < 0 ? mouseX : mouseX > width ? mouseX - width : 0
                ruler.overdrag = Geometry.resistance(overflow)
            }
            onPressed: mouse => preview(mouse.x)
            onPositionChanged: mouse => { if (pressed) preview(mouse.x) }
            onReleased: {
                root.timerService.setDuration(ruler.previewMinutes * 60)
                ruler.overdrag = 0
            }
            onCanceled: ruler.overdrag = 0
        }
    }
    onPresentedChanged: if (!presented) ruler.overdrag = 0

    Row {
        y: 24 - 4 * root.customReveal
        spacing: 6
        visible: opacity > 0
        enabled: !root.customOpen
        opacity: 1 - root.customReveal
        Repeater {
            model: [5, 10, 25]
            TextButton {
                required property int modelData
                objectName: "timerPreset" + modelData
                text: modelData + "m"
                onClicked: root.timerService.setDuration(modelData * 60)
            }
        }
    }
    TextField {
        id: customMinutes
        objectName: "timerCustomMinutes"
        x: 0; y: 24 + 4 * (1 - root.customReveal); width: parent.width - 45; height: 28
        visible: opacity > 0
        enabled: root.customOpen
        opacity: root.customReveal
        placeholderText: "Duração em minutos"
        color: root.theme.textPrimary; placeholderTextColor: root.theme.textMuted
        font.family: root.theme.bodyFont; font.pixelSize: 12
        validator: IntValidator { bottom: 1; top: 1440 }
        selectByMouse: true
        Accessible.name: "Duração personalizada em minutos"
        background: Rectangle { color: "transparent"; radius: 5; border.color: root.theme.borderSubtle }
        onAccepted: if (acceptableInput) {
            root.timerService.setDuration(Number(text) * 60)
            root.customOpen = false; text = ""
        }
    }
    TextButton {
        objectName: "timerCustomButton"
        anchors.right: parent.right; y: 24
        text: root.customOpen ? "✓" : "···"
        Accessible.name: "Personalizar duração"
        onClicked: {
            if (root.customOpen && customMinutes.acceptableInput) {
                root.timerService.setDuration(Number(customMinutes.text) * 60)
                customMinutes.text = ""
            }
            root.customOpen = !root.customOpen
            if (root.customOpen) customMinutes.forceActiveFocus()
        }
    }
    Row {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        spacing: 5
        TextButton {
            objectName: "timerStartButton"
            text: root.timerService.countdown.running ? "Pausar" : root.paused ? "Continuar" : "Iniciar"
            onClicked: root.timerService.toggleTimer()
        }
        TextButton {
            id: resetButton
            objectName: "timerResetButton"
            text: "↺"
            property bool shown: root.timerService.countdown.running || root.paused || root.timerService.finished
            opacity: shown ? 1 : 0
            visible: opacity > 0
            enabled: shown
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            transform: Translate { x: (1 - resetButton.opacity) * -5 }
            Accessible.name: "Reiniciar timer"
            onClicked: root.timerService.resetTimer()
        }
    }
    TimerLabel {
        id: counter
        objectName: "timerCountdown"
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.bottomMargin: -3
        text: rulerPointer.pressed ? Math.round(ruler.previewMinutes) + ":00" : root.timerService.timerText
        color: root.theme.textPrimary
        family: root.theme.bodyFont; pixelSize: 36; weight: Font.Light
        tabular: true
        transitionKey: root.timerService.duration + ":" + root.timerService.engaged
        // Only a change of duration/reset morphs the digits. Seconds remain crisp.
        animate: root.presented && !rulerPointer.pressed
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter; y: 58
        visible: text.length > 0
        text: root.timerService.saveError
        color: root.theme.warning; font.pixelSize: 10
    }
}
