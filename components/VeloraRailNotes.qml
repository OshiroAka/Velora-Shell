import QtQuick

// A sidebar editor stays open while typing, until Escape or a click outside.
VeloraRailPopover {
    toolType: "notes"
    preferredWidth: 380
    preferredHeight: 420
    closeOnLeave: false
}
