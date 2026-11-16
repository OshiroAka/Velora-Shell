import QtQuick

Image {
    objectName: "notificationImage"
    property real maximumHeight: 156
    visible: source.toString().length > 0 && status !== Image.Error
    height: visible ? maximumHeight : 0
    // A fixed decode size avoids reloading the file on every morph frame.
    sourceSize: Qt.size(720, 400)
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    mipmap: true
    cache: false
    Accessible.ignored: true
}
