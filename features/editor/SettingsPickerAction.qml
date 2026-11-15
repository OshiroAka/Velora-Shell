import QtQuick
import QtQuick.Controls

Button {
        id: action
        required property var theme
        property bool primary: false
        implicitWidth: 110; implicitHeight: 36
        opacity: enabled ? 1 : .45
        contentItem: Text {
            text: action.text; color: action.theme.textPrimary
            font.family: action.theme.bodyFont; font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 10
            color: action.primary ? action.theme.withAlpha(action.theme.accent, action.down ? .35 : .22)
                : action.down ? action.theme.surfaceHover : action.theme.surfaceSoft
            border.width: 1
            border.color: action.activeFocus ? action.theme.accent : action.theme.borderSubtle
        }
    }
