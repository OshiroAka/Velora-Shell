import QtQuick
import "../../features/topbar" as Topbar

Topbar.WallpaperDropArea {
    width: 200; height: 40
    property int dropCount: 0
    property var received: []
    onFilesDropped: urls => { received = urls; dropCount++ }
}
