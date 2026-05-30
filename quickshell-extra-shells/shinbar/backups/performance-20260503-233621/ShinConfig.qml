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

    property int lockTheme: 0
    property bool lockEnabled: true
    property bool lockShowImage: true
    property bool lockShowDate: true
    property bool lockShowUser: true
    property bool lockClock24h: false
    property string lockWallpaper: ""
    property string lockImage: ""
    property real lockBlur: 0.68
    property real lockDim: 0.22
    property real lockGlow: 0.86
    property real lockPanelOpacity: 0.18
    property int lockLineStyle: 0
    property int lockAnimStyle: 0
    property real lockAnimStrength: 1.0

    property bool mediaAlwaysVisible: false
    property bool mediaShowVisualizer: true
    property int mediaPanelWidth: 246
    property int mediaPanelHeight: 560

    property bool wallpaperSelectorEnabled: true
    property int wallpaperModel: 2
    property int wallpaperPanelPosition: 0
    property int wallpaperOpenStyle: 0
    property int wallpaperMoveStyle: 0
    property int wallpaperTransition: 0
    property int wallpaperPanelThick: 235
    property real wallpaperPanelSpan: 1.0
    property bool wallpaperFillEdges: true
    property bool wallpaperApplyPywal: true

    property int animationSpeed: 100
    property bool trailEnabled: true
    property real glowStrength: 0.70
    property real hoverScale: 1.025
    property int pywalPollMs: 350
}
