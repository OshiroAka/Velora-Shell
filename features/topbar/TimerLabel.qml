import QtQuick

// Two text layers only during a state transition; ordinary ticks replace the
// live digits in place. Font, colors and settled alignment belong to the caller.
Item {
    id: root
    property string text: ""
    property string transitionKey: text
    property color color: "white"
    property string family: "Poppins"
    property real pixelSize: 12
    property int weight: Font.Normal
    property bool tabular: false
    property bool animate: true
    property bool ready: false
    property string currentText: ""
    property string previousText: ""
    property string previousKey: ""
    property real blend: 1
    implicitWidth: current.implicitWidth
    implicitHeight: current.implicitHeight

    function synchronize() {
        const morph = ready && animate && previousKey !== transitionKey && currentText !== text
        change.stop()
        previousText = currentText
        currentText = text
        previousKey = transitionKey
        blend = morph ? 0 : 1
        if (morph) change.start()
    }
    onTextChanged: Qt.callLater(synchronize)
    onTransitionKeyChanged: Qt.callLater(synchronize)
    Component.onCompleted: { synchronize(); ready = true }
    NumberAnimation { id: change; target: root; property: "blend"; to: 1; duration: 180; easing.type: Easing.OutCubic }
    Text {
        anchors.centerIn: parent
        text: root.previousText
        color: root.color
        font.family: root.family; font.pixelSize: root.pixelSize; font.weight: root.weight
        font.features: root.tabular ? ({ "tnum": 1 }) : ({})
        opacity: 1 - root.blend
        visible: opacity > 0
        transform: Translate { y: -3 * root.blend }
    }
    Text {
        id: current
        anchors.centerIn: parent
        text: root.currentText
        color: root.color
        font.family: root.family; font.pixelSize: root.pixelSize; font.weight: root.weight
        font.features: root.tabular ? ({ "tnum": 1 }) : ({})
        opacity: root.blend
        transform: Translate { y: 3 * (1 - root.blend) }
    }
}
