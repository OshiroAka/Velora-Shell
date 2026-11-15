import QtQuick
import QtQuick.Window
import Quickshell
import "../../components" as Components

ShellRoot {
    Window {
        id: window
        visible: true; width: 620; height: 180; color: "#16191e"
        Text { x: 20; y: 8; text: "Apps da barra inferior"; color: "#bbbbbb"; font.pixelSize: 11 }
        Text { x: 356; y: 8; text: "Menu da direita"; color: "#bbbbbb"; font.pixelSize: 11 }
        Repeater {
            model: ["steam", "zen", "brave-browser", "Wallpaper Engine", "spotify", "discord", "whatsapp"]
            Item {
                required property int index
                required property string modelData
                x: 20 + index*84; width: 80; height: 180
                Components.VeloraDockAppIcon {
                    visible: parent.index < 4
                    id: small
                    x: 26; y: 34; width: 28; height: 28
                    identifier: parent.modelData
                    ink: "white"
                }
                Components.VeloraEdgeAppIcon {
                    x: 26; y: 34; width: 28; height: 28
                    visible: parent.index >= 4
                    iconName: ({spotify:"Spotify",discord:"Discord",whatsapp:"WhatsApp"})[parent.modelData] || "Spotify"
                    ink: "white"
                }
                Text { y: 70; width: 80; text: parent.modelData; color: "#bbbbbb"; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter }
                Components.VeloraDockAppIcon { visible: parent.index < 4; x: 12; y: 98; width: 56; height: 56; identifier: parent.modelData; ink: "white" }
                Components.VeloraEdgeAppIcon {
                    x: 12; y: 98; width: 56; height: 56; visible: parent.index >= 4
                    iconName: ({spotify:"Spotify",discord:"Discord",whatsapp:"WhatsApp"})[parent.modelData] || "Spotify"
                    ink: "white"
                }
            }
        }
        Components.VeloraDockAppIcon { id: probe; visible: false; identifier: "steam" }
        Timer {
            interval: 500; running: true
            onTriggered: {
                if (!probe.useGlyph) { console.error("GLYPHS_FAILED: Steam must use the shared drawing"); Qt.quit(); return }
                probe.outline = false
                if (probe.useGlyph) { console.error("GLYPHS_FAILED: toggle must restore original artwork"); Qt.quit(); return }
                probe.outline = true
                probe.identifier = "unlisted-app"
                if (probe.useGlyph || probe.useSymbolic) { console.error("GLYPHS_FAILED: unknown app must keep its original icon"); Qt.quit(); return }
                window.contentItem.grabToImage(result => {
                    if (!result.saveToFile(Quickshell.env("VELORA_GLYPHS_PREVIEW"))) console.error("GLYPHS_FAILED: capture")
                    else console.info("GLYPHS_OK")
                    Qt.quit()
                })
            }
        }
    }
    Timer { interval: 5000; running: true; onTriggered: { console.error("GLYPHS_FAILED: timeout"); Qt.quit() } }
}
