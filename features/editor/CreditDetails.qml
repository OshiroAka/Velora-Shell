pragma ComponentBehavior: Bound
import QtQuick

FocusScope {
    id: root; objectName: "creditDetails"
    required property var profile
    readonly property var theme: profile.theme
    width: parent ? parent.width : 600
    implicitHeight: detailsBody.implicitHeight*profile.detailReveal
    visible: profile.hasDetails && profile.visible && profile.detailReveal>0; clip: true
    enabled: profile.reveal>.98
    Column {
        id: detailsBody; objectName: "creditDetailsBody"
        width: parent.width; spacing: 12
        opacity: root.profile.detailReveal
        y: -8*(1-root.profile.detailReveal)
        Text {
            objectName: "creditRecognition"; width: parent.width
            visible: root.profile.recognition.length>0; text: root.profile.recognition
            wrapMode: Text.WordWrap; color: root.theme.accentSoft
            font.family: root.theme.bodyFont; font.pixelSize: 12
        }
        Flow {
            id: statsFlow
            width: parent.width; spacing: 12; visible: root.profile.statistics.length>0
            readonly property bool stacked: width<220
            Repeater {
                model: root.profile.statistics
                Column {
                    required property var modelData
                    width: statsFlow.stacked ? statsFlow.width : (statsFlow.width-24)/3; spacing: 4
                    Text {
                        objectName: "creditStat-"+parent.modelData.id
                        text: parent.modelData.value; color: root.theme.textPrimary
                        font.family: root.theme.bodyFont; font.pixelSize: root.width<300 ? 17 : 20; font.weight: Font.DemiBold
                    }
                    Text {
                        text: parent.modelData.label; color: root.theme.textSecondary
                        font.family: root.theme.bodyFont; font.pixelSize: 12
                    }
                }
            }
        }
        Text {
            objectName: "creditBioLead"; width: parent.width
            visible: root.profile.biographyLead.length>0
            text: root.profile.formatProfileText ? root.profile.formatProfileText(root.profile.biographyLead) : root.profile.biographyLead
            textFormat: root.profile.formatProfileText ? Text.RichText : Text.PlainText
            wrapMode: Text.WordWrap
            color: root.theme.textSecondary
            font.family: root.profile.nameFamilies.length ? root.profile.nameFamilies[0] : root.theme.bodyFont
            font.pixelSize: 14
        }
        Text {
            objectName: "creditBio"; width: parent.width
            visible: root.profile.biography.length>0
            text: root.profile.formatProfileText ? root.profile.formatProfileText(root.profile.biography) : root.profile.biography
            textFormat: root.profile.formatProfileText ? Text.RichText : Text.PlainText
            wrapMode: Text.WordWrap
            color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 13
        }
        Text {
            id: contactLink; objectName: "creditContact"
            width: parent.width; visible: root.profile.contactUrl.length>0
            text: root.profile.contactLabel; wrapMode: Text.Wrap
            color: root.theme.accentSoft; font.family: root.theme.bodyFont; font.pixelSize: 13
            activeFocusOnTab: visible && root.profile.reveal>.99
            Accessible.role: Accessible.Link; Accessible.name: root.profile.contactLabel
            Accessible.onPressAction: root.profile.profileLinkRequested(root.profile.contactUrl)
            Keys.onReturnPressed: root.profile.profileLinkRequested(root.profile.contactUrl)
            Keys.onSpacePressed: root.profile.profileLinkRequested(root.profile.contactUrl)
            Rectangle {
                anchors.fill: parent; anchors.margins: -3; radius: 5; color: "transparent"
                border.width: contactLink.activeFocus ? 1 : 0; border.color: root.theme.accentSoft
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: root.profile.profileLinkRequested(root.profile.contactUrl)
            }
        }
    }
}
