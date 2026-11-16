.pragma library

function localFileUrl(path) {
    const value = String(path || "")
    if (!value.startsWith("/") || value.indexOf("\u0000") >= 0)
        return ""
    return "file://" + value.split("/").map(encodeURIComponent).join("/")
}

function attachment(notification) {
    const hints = notification && notification.hints ? notification.hints : {}
    // Keep the saved capture usable from history after the sender has exited.
    const openUrl = localFileUrl(hints["x-velora-screenshot-path"])
    return {
        imageSource: openUrl || String(notification && notification.image || ""),
        openUrl: openUrl
    }
}
