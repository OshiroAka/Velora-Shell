pragma ComponentBehavior: Bound
import QtQuick

VeloraRailPopover {
    id: root
    required property var media
    required property var status
    required property var tools
    property string avatarSource: ""
    property string profileName: "Seu perfil"
    property string pendingAction: ""
    preferredWidth: 800
    preferredHeight: 432
    contentMinimumWidth: Math.max(520, targetWidth - 2 * contentPadding)
    contentMinimumHeight: 350
    contentSlideX: -8
    contentSlideY: 0
    closeOnLeave: false
    onMountedChanged: {
        if (mounted) tools.refresh()
        // Capture only after the final frame of the menu has disappeared.
        else if (pendingAction) {
            const action = pendingAction
            pendingAction = ""
            tools.run(action)
        }
    }
    customContent: Component {
        ProfileMenuContent {
            theme: root.theme; media: root.media; status: root.status; tools: root.tools
            avatarSource: root.avatarSource; profileName: root.profileName
            reducedMotion: root.reducedMotion
            onToolRequested: action => { root.pendingAction = action; root.close() }
        }
    }
}
