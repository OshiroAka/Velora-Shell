pragma ComponentBehavior: Bound
import QtQuick

DropArea {
    id: root
    signal filesDropped(var urls)
    signal dragStarted()

    // Downloads from browsers and file managers arrive as text/uri-list. Only
    // completed local media can be copied; web links and partial downloads stay
    // with their source application.
    function mediaUrls(urls) {
        const accepted = []
        for (const value of urls) {
            const url = String(value)
            if (!/^file:\/\/(?:localhost)?\//i.test(url)) continue
            try {
                const path = decodeURIComponent(url.replace(/^file:\/\/(?:localhost)?/i, ""))
                if (/\.(png|jpe?g|webp|gif|mp4|webm|mkv|mov)$/i.test(path)
                        && !accepted.includes(url)) accepted.push(url)
            } catch (error) { /* Invalid URL encoding is not a local media path. */ }
        }
        return accepted
    }
    onEntered: drag => {
        drag.accepted = !!(drag.supportedActions & Qt.CopyAction)
            && mediaUrls(drag.urls).length > 0
        if (drag.accepted) dragStarted()
    }
    onDropped: drop => {
        const urls = mediaUrls(drop.urls)
        if (!(drop.supportedActions & Qt.CopyAction) || !urls.length) {
            drop.accepted = false
            return
        }
        drop.accept(Qt.CopyAction)
        filesDropped(urls)
    }
}
