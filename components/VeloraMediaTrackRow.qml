pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: track
    required property var modelData
    property bool current: false
    property color ink: "#f4f5f7"
    property color muted: "#b8bec7"
    property string family: "sans-serif"
    property bool reducedMotion: false
    signal playRequested(string uri)
    height: 50
    leftPadding: 6; rightPadding: 6; topPadding: 5; bottomPadding: 5
    hoverEnabled: true
    Accessible.name: String(modelData.title || "") + " · " + String(modelData.artist || "")
    enabled: /^spotify:track:[a-zA-Z0-9]+$/.test(String(modelData.uri || ""))
    onClicked: playRequested(modelData.uri)
    background: Rectangle {
        radius: 9
        color: Qt.rgba(track.ink.r, track.ink.g, track.ink.b, track.current ? .075 : track.hovered ? .04 : 0)
        border.color: Qt.rgba(track.ink.r, track.ink.g, track.ink.b, track.activeFocus ? .45 : 0)
        Behavior on color { ColorAnimation { duration: track.reducedMotion ? 0 : 130 } }
    }
    contentItem: RowLayout {
        spacing: 10
        VeloraMediaArtwork {
            Layout.preferredWidth: 38; Layout.preferredHeight: 38
            source: String(track.modelData.art || ""); radius: 6; ink: track.ink; accent: track.muted
            animated: !track.reducedMotion
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text { Layout.fillWidth: true; text: String(track.modelData.title || ""); textFormat: Text.PlainText; color: track.ink; font.family: track.family; font.pixelSize: 11; font.weight: track.current ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: String(track.modelData.artist || ""); textFormat: Text.PlainText; color: track.muted; font.family: track.family; font.pixelSize: 10; elide: Text.ElideRight }
        }
    }
}
