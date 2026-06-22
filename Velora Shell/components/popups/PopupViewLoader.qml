import QtQuick

Loader {
    id: root

    property var popup: null
    property string viewType: ""
    property int viewMargins: 0

    anchors.fill: parent
    anchors.margins: viewMargins
    active: popup && popup.popupType === viewType
    visible: active
    asynchronous: false
}
