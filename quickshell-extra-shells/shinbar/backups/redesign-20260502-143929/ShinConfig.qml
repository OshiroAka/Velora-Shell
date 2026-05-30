pragma Singleton
import QtQuick

QtObject {
    property int  barH:        38
    property int  pillH:       28
    property int  pillR:       9
    property int  pillPadH:    12
    property int  pillSpacing: 6
    property int  barMarginT:  8
    property int  barMarginH:  10

    property real pillOpacity:  0.72
    property real popupOpacity: 0.58

    property int    fontSize:   12
    property int    fontSizeSm: 10
    property string fontFamily: "JetBrainsMono Nerd Font"

    property string namespace:   "shinbar"
    property string weatherCity: "Guarulhos"

    property bool searchEnabled: true
    property int searchPanelWidth: 560
    property int searchMaxResults: 8
    property int searchIconSize: 28
    property real searchOpacity: 0.74
    property bool searchShowIcons: true
    property bool searchCompact: false
    property int searchPosition: 1

    property int clockStyle: 0
    property int clockPopupStyle: 0
    property bool clockShowSeconds: true
    property bool clockUse24h: false
    property bool clockShowDate: true

    property bool mediaAlwaysVisible: false
    property bool mediaShowVisualizer: true
    property int mediaPanelWidth: 246
    property int mediaPanelHeight: 560

    property int animationSpeed: 100
    property bool trailEnabled: true
    property real glowStrength: 0.70
    property real hoverScale: 1.025
    property int pywalPollMs: 350
}
