import QtQuick
import "../widgets" as Widgets
import "../../core/WidgetCatalog.js" as Catalog

Item {
    id: root
    enabled: false
    required property var theme
    property string kind: "clock"
    property string variantId: "editorial"
    property string visualizerMode: "wave"
    property bool solid: true
    readonly property var design: Catalog.resolve(kind, variantId)
    readonly property var previewStyle: ({material: "solid", solidColor: String(theme.moduleSurface), surfaceOpacity: 1, radius: 24})
    implicitWidth: 190; implicitHeight: 100
    // Sample data is confined to Settings; desktop cards receive real services.
    QtObject {
        id: sampleClock
        property date now: new Date(2026, 10, 16, 9, 35)
        property string timeText: "09:35"
        property string dateText: "segunda-feira, 16 de novembro"
        function locale() { return Qt.locale("pt_BR") }
    }
    QtObject {
        id: sampleWeather
        property string temperature: "28"
        property string maximum: "30"
        property string minimum: "21"
        property string location: "São Paulo"
        property string description: "Parcialmente nublado"
        property string iconName: "partly"
        property var forecast: [{date: "2026-11-17", max: 30, min: 21, icon: "sun"}, {date: "2026-11-18", max: 27, min: 20, icon: "cloud"}, {date: "2026-11-19", max: 25, min: 19, icon: "rain"}, {date: "2026-11-20", max: 28, min: 20, icon: "partly"}]
    }
    QtObject {
        id: sampleStatus
        property bool performanceAvailable: true
        property real networkDownKbps: 128
        property real networkUpKbps: 16
        property bool hasAudio: false
        property real volume: 0
        property int volumePercent: 0
        property real cpuPercent: 24
        property real ramPercent: 52
        property real storagePercent: 61
        property bool hasBattery: true
        property real batteryLevel: .74
        property int batteryPercent: 74
        property bool batteryCharging: false
    }
    QtObject {
        id: sampleGallery
        property var galleryOrder: [0,1,2]
        property var galleryPaths: [Qt.resolvedUrl("../../assets/dashboard-cover.svg"), Qt.resolvedUrl("../../assets/profile-avatar.svg"), Qt.resolvedUrl("../../assets/dashboard-cover.svg")]
        property var galleryScales: [1,1,1]
        property var galleryOffsetsX: [0,0,0]
        property var galleryOffsetsY: [0,0,0]
        property var galleryFlipX: [false,false,false]
    }
    QtObject {
        id: sampleMotion
        property bool reduced: true
        property int depth: 0
        property int hover: 0
    }
    QtObject {
        id: sampleMedia
        property bool hasPlayer: true
        property string title: "Sua música"
        property string artist: "Artista · álbum"
        property string artUrl: ""
        property real progress: .35
        property bool playing: false
        property bool canToggle: false
        property bool canPrevious: false
        property bool canNext: false
    }
    Item {
        width: root.design ? root.design.width : 190
        height: root.design ? root.design.height : 92
        anchors.centerIn: parent
        scale: Math.min(root.width / width, root.height / height)
        Loader {
            anchors.fill: parent
            sourceComponent: root.kind === "clock" ? clockCard : root.kind === "weather" ? weatherCard
                : root.kind === "system" ? systemCard : root.kind === "battery" ? batteryCard
                : root.kind === "media" ? mediaCard : root.kind === "gallery" ? galleryCard : illustration
        }
    }
    Component { id: clockCard; Widgets.ClockCard { theme: root.theme; clock: sampleClock; itemStyle: root.previewStyle; variantId: root.variantId } }
    Component { id: weatherCard; Widgets.WeatherCard { theme: root.theme; clock: sampleClock; weather: sampleWeather; motion: null; itemStyle: root.previewStyle; variantId: root.variantId } }
    Component { id: systemCard; Widgets.SystemPanel { theme: root.theme; status: sampleStatus; motion: null; itemStyle: root.previewStyle; variantId: root.variantId } }
    Component { id: batteryCard; Widgets.BatteryCard { theme: root.theme; status: sampleStatus; itemStyle: root.previewStyle; variantId: root.variantId } }
    Component { id: mediaCard; Widgets.MediaCard { theme: root.theme; media: sampleMedia; motion: null; itemStyle: root.previewStyle; variantId: root.variantId } }
    Component { id: galleryCard; Widgets.GalleryPanel { theme: root.theme; config: sampleGallery; motion: sampleMotion; interactionsEnabled: false; itemStyle: root.previewStyle; variantId: root.variantId } }
    Component {
        id: illustration
        Item {
            Row {
                anchors.centerIn: parent; spacing: 3
                Repeater {
                    model: root.kind === "visualizer" ? 27 : 0
                    Rectangle {
                        required property int index
                        width: 4; height: 8 + 48 * Math.pow(Math.sin((index + 2) * .27), 2)
                        y: 60 - height; radius: root.visualizerMode === "wave" ? 3 : 0
                        color: root.theme.accentSoft
                    }
                }
            }
        }
    }
}
