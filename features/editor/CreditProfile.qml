pragma ComponentBehavior: Bound
import QtQuick

FocusScope {
    id: root
    required property var theme
    required property var motion
    required property string profileName
    property string role: ""
    property string tiktok: ""
    property string displayName: profileName
    property var nameFamilies: []
    property var formatProfileText: null
    property int nameWeight: Font.Normal
    property real nameLetterSpacing: 0
    property bool wrapName: false
    property var statistics: []
    property string biographyLead: ""
    property string biography: ""
    property string contactLabel: ""
    property string contactUrl: ""
    property string recognition: ""
    property bool pinned: false
    property real reveal: 0
    property bool expanded: false
    readonly property bool hovered: visible && pointer.hovered
    readonly property bool highlighted: visible && expanded
    readonly property bool animating: slide.running
    readonly property real avatarSize: 88
    readonly property string profileUrl: tiktok.length ? "https://www.tiktok.com/@"+tiktok : ""
    signal profileLinkRequested(string url)
    readonly property real detailReveal: Math.max(0,Math.min(1,(reveal-.2)/.8))
    readonly property real identityHeight: identity.y+identity.implicitHeight+12
    readonly property bool hasDetails: recognition.length>0 || statistics.length>0
        || biographyLead.length>0 || biography.length>0 || contactUrl.length>0
    implicitHeight: Math.max(avatarSize+16,identityHeight+details.implicitHeight+(hasDetails ? 12*detailReveal : 0))
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: (role.length ? role+" · " : "")+profileName
    Accessible.description: recognition+(tiktok.length ? " · TikTok @"+tiktok : "")
    Accessible.expandable: true
    Accessible.expanded: reveal>.99
    Accessible.onPressAction: root.pinned=!root.pinned
    Keys.onSpacePressed: root.pinned=!root.pinned
    Keys.onReturnPressed: if (profileUrl.length) profileLinkRequested(profileUrl)
    Keys.onEscapePressed: dismiss()

    function refreshExpansion() {
        expanded=visible && (pointer.hovered || activeFocus || socialLink.activeFocus || pinned)
    }
    function dismiss() {
        pinned=false;focus=false;expanded=false
    }
    onHoveredChanged: refreshExpansion()
    onActiveFocusChanged: refreshExpansion()
    onPinnedChanged: refreshExpansion()
    function synchronize() {
        slide.stop()
        const target=highlighted ? 1 : 0
        if (motion.reduced || !visible) reveal=target
        else if (reveal!==target) { slide.to=target;slide.start() }
    }
    onHighlightedChanged: synchronize()
    onVisibleChanged: if (!visible) { dismiss();synchronize() }
    Component.onCompleted: { refreshExpansion();synchronize() }
    Connections { target: root.motion; function onReducedChanged() { root.synchronize() } }
    NumberAnimation {
        id: slide; target: root; property: "reveal"
        duration: root.motion.accordionDuration; easing.type: Easing.OutCubic
    }
    Rectangle {
        x: root.avatarSize/2; y: 8
        width: Math.max(0,root.width-x)*root.reveal
        height: Math.max(72,root.identityHeight-y)+details.implicitHeight+(root.hasDetails ? 12*root.detailReveal : 0); radius: 18
        color: root.theme.withAlpha(root.theme.accentSoft,.07)
        opacity: root.reveal
    }
    Item {
        id: nameWindow
        x: root.avatarSize/2; y: 0
        width: Math.max(0,root.width-x)*root.reveal; height: root.avatarSize
        clip: true
        Column {
            id: identity
            x: root.avatarSize/2+18-(1-root.reveal)*56
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0,root.width-root.avatarSize-30)
            spacing: 7; opacity: Math.min(1,root.reveal*1.8)
            Text {
                objectName: "creditName"
                width: parent.width
                text: root.formatProfileText ? root.formatProfileText(root.displayName) : root.displayName
                textFormat: root.formatProfileText ? Text.RichText : Text.PlainText
                elide: Text.ElideRight
                wrapMode: root.wrapName ? Text.WrapAnywhere : Text.NoWrap
                maximumLineCount: root.wrapName ? 2 : 1
                color: root.theme.textPrimary
                font.family: root.nameFamilies.length ? root.nameFamilies[0] : root.theme.bodyFont
                font.pixelSize: 21; font.weight: root.nameWeight; font.letterSpacing: root.nameLetterSpacing
            }
            Text {
                id: socialLink; objectName: "creditTikTok"
                onActiveFocusChanged: root.refreshExpansion()
                width: parent.width; visible: root.tiktok.length>0
                text: "TikTok · @"+root.tiktok
                wrapMode: Text.WrapAnywhere
                color: root.theme.accentSoft; font.family: root.theme.bodyFont; font.pixelSize: 12
                opacity: Math.max(0,Math.min(1,(root.reveal-.25)/.75))
                activeFocusOnTab: visible && root.reveal>.99
                Accessible.role: Accessible.Link; Accessible.name: "TikTok de "+root.profileName
                Accessible.onPressAction: root.profileLinkRequested(root.profileUrl)
                Keys.onReturnPressed: root.profileLinkRequested(root.profileUrl)
                Keys.onSpacePressed: root.profileLinkRequested(root.profileUrl)
                Rectangle {
                    anchors.fill: parent; anchors.margins: -3; radius: 5; color: "transparent"
                    border.width: socialLink.activeFocus ? 1 : 0; border.color: root.theme.accentSoft
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: root.reveal>.98
                    onClicked: root.profileLinkRequested(root.profileUrl)
                }
            }
        }
    }
    Rectangle {
        id: avatar; x: 0; y: 0; z: 2
        width: root.avatarSize; height: width; radius: width/2
        color: root.theme.moduleSurface
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? root.theme.accentSoft : root.theme.borderSubtle
        Text {
            objectName: "creditInitial"
            anchors.centerIn: parent
            readonly property string initial: Array.from(root.profileName.trim())[0] || ""
            text: root.formatProfileText ? root.formatProfileText(initial.toUpperCase()) : initial.toUpperCase()
            textFormat: root.formatProfileText ? Text.RichText : Text.PlainText
            color: root.theme.accentSoft
            font.family: root.theme.bodyFont
            font.pixelSize: 30
            font.weight: Font.DemiBold
        }
    }

    CreditDetails {
        id: details
        x: root.avatarSize+18; y: root.identityHeight
        width: Math.max(0,parent.width-x-12); profile: root
    }
    MouseArea {
        anchors.fill: parent; z: -1
        onClicked: root.pinned=!root.pinned
    }
    HoverHandler { id: pointer }
}
