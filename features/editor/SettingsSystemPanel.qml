pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import "../../components" as Components
import "../topbar" as TopBar

Item {
    id: root
    required property string kind
    required property var theme
    required property var controller
    required property var motion
    property bool presented: true
    readonly property var shell: controller.shell
    readonly property var composition: shell ? shell.composition : null
    readonly property var status: composition ? composition.networkStatus : null
    readonly property var tools: composition ? composition.topbarTools : null
    readonly property var fan: composition ? composition.fanPlusService : null
    property var audioSink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: !!(audioSink && audioSink.ready && audioSink.audio)
    readonly property var levels: shell && typeof shell.infiniteDesktopLevels === "function" && Hyprland.focusedMonitor
        ? shell.infiniteDesktopLevels(Hyprland.focusedMonitor.name) : null
    readonly property bool servicesAvailable: kind === "battery" ? !!(status && tools && fan)
        : kind === "wifi" ? !!(status && tools) : true
    implicitHeight: kind === "monitor" ? 250+(levels ? 80 : 0) : kind === "volume" ? 120
        : kind === "battery" ? (servicesAvailable ? 170 : 44) : kind === "notifications" ? 340 : 366

    PwObjectTracker { objects: root.audioSink ? [root.audioSink] : [] }
    readonly property var monitorControl: kind === "monitor" && controls.item ? controls.item.monitorControl : null
    readonly property bool busy: !!monitorControl && (monitorControl.busy || monitorControl.awaitingConfirmation)
    function deactivate() { if (monitorControl) monitorControl.opened=false }
    function refresh() {
        if (!presented) return
        if (kind === "battery" && tools) tools.refreshPower()
        if (kind === "battery" && fan) fan.refresh()
        if (kind === "wifi" && tools) tools.refreshNetwork()
    }
    onPresentedChanged: { if (!presented) deactivate(); else refresh() }
    Component.onCompleted: refresh()
    Timer { interval: 10000; repeat: true; running: root.presented && !!root.tools && ["battery","wifi"].includes(root.kind); onTriggered: root.refresh() }

    Text {
        visible: !root.servicesAvailable
        width: parent.width; wrapMode: Text.WordWrap
        text: "Controles indisponíveis nesta sessão."
        color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12
    }
    Loader {
        id: controls
        anchors.fill: parent
        active: root.servicesAvailable
        sourceComponent: root.kind === "monitor" ? displayPanel : root.kind === "volume" ? audioPanel
            : root.kind === "notifications" ? notificationsPanel : root.kind === "battery" ? powerPanel : networkPanel
    }
    Component {
        id: displayPanel
        Column {
            property alias monitorControl: display
            spacing: 12
            Components.VeloraMonitorSettings {
                id: display
                objectName: "settingsInlineMonitor"
                width: parent.width; height: 250
                opened: root.presented
                reducedMotion: root.motion.reduced
                ink: root.theme.textPrimary; uiFont: root.theme.bodyFont
                surfaceColor: root.theme.wallpaperSurfaceTone
            }
            Components.VeloraSettingsSlider {
                visible: !!root.levels; width: parent.width
                theme: root.theme; label: "Brilho"
                enabled: !!root.levels && root.levels.brightnessAvailable
                value: root.levels ? root.levels.brightness : 0
                minimum: .05; maximum: 1
                onEdited: value => { if (root.levels) root.levels.setBrightness(value) }
            }
        }
    }
    Component {
        id: audioPanel
        Column {
            spacing: 8
            Components.VeloraSettingsSlider {
                objectName: "settingsInlineVolume"
                width: parent.width; theme: root.theme; label: "Volume de saída"
                enabled: root.hasAudio
                value: root.hasAudio ? Math.min(1,root.audioSink.audio.volume) : 0
                onEdited: value => {
                    root.audioSink.audio.volume=value
                    if (value>0) root.audioSink.audio.muted=false
                }
            }
            Components.VeloraSettingsSwitch {
                objectName: "settingsInlineMute"
                theme: root.theme; motion: root.motion; label: "Silenciar"
                enabled: root.hasAudio; checked: root.hasAudio && root.audioSink.audio.muted
                onTriggered: root.audioSink.audio.muted=!root.audioSink.audio.muted
            }
        }
    }
    Component {
        id: notificationsPanel
        Components.VeloraRailNotifications {
            objectName: "settingsInlineNotifications"
            embedded: true; contentPadding: 0
            theme: root.theme; motion: root.motion; system: root.tools
            notificationsModel: root.shell ? root.shell.notificationHistory || null : null
            ink: root.theme.textPrimary; accent: root.theme.accent; uiFont: root.theme.bodyFont
            onDismissRequested: id => { if (root.shell) root.shell.dismissNotificationHistory(id) }
            onClearRequested: { if (root.shell) root.shell.clearTrackedNotificationHistory() }
            // Escape belongs to Settings, rather than closing only this embedded panel.
            Keys.onEscapePressed: event => event.accepted=false
        }
    }
    Component {
        id: powerPanel
        TopBar.BarPanelContent {
            objectName: "settingsInlinePower"
            type: "battery"; theme: root.theme; systemStatus: root.status; system: root.tools
            fanPlus: root.fan; motionTokens: root.motion; shell: root.shell; presented: root.presented
            timerService: null; clock: null; calendar: null; media: null; weather: null; controller: null; actions: null
        }
    }
    Component {
        id: networkPanel
        Components.VeloraRailWifi {
            id: network
            objectName: "settingsInlineWifi"
            embedded: true; contentPadding: 0
            theme: root.theme; motion: root.motion; system: root.tools
            ink: root.theme.textPrimary; uiFont: root.theme.bodyFont
            Binding { target: network; property: "opened"; value: root.presented }
            Keys.onEscapePressed: event => event.accepted=false
        }
    }
}
