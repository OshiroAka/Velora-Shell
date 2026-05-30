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
}
