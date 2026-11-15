import QtQuick

// Demand follows visible consumers, never analyzer.running (which would make
// a stopped analyzer unable to restart).
QtObject {
    property bool desktopEnabled: false
    property bool editingDesktop: false
    property bool lockOccluding: false
    property bool railVisible: false
    property bool mediaPlaying: false
    property bool edgeMediaVisible: false
    property bool dockVisible: false
    readonly property bool active: ((desktopEnabled || dockVisible) && !lockOccluding && !editingDesktop)
        || lockOccluding || ((railVisible || edgeMediaVisible) && !lockOccluding && mediaPlaying)
}
