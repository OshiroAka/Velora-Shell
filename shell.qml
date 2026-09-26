import QtQuick
import Quickshell

ShellRoot {
    Loader {
        id: shellLoader
        active: Quickshell.env("VELORA_VALIDATE") !== "1"
        sourceComponent: ShellController { composition: compositionLoader.item }
    }
    Loader {
        id: compositionLoader
        active: Quickshell.env("VELORA_VALIDATE") !== "1"
        sourceComponent: CompositionController { shell: shellLoader.item }
    }
}
