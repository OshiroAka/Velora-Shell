.pragma library

// Desktop IDs and icon names vary between native packages and Flatpak.
// Resolve exact names, never substrings such as 'steam-game-123'.
function resolve(identifier, iconName) {
    const aliases = {
        spotify: "Spotify", discord: "Discord", whatsapp: "WhatsApp", whatsappdesktop: "WhatsApp",
        steam: "Steam", "steam-native": "Steam", "steam-runtime": "Steam",
        zen: "Zen", "zen-browser": "Zen", brave: "Brave", "brave-browser": "Brave",
        "brave-browser-stable": "Brave", "wallpaper-engine": "WallpaperEngine",
        wallpaperengine: "WallpaperEngine", "linux-wallpaperengine": "WallpaperEngine"
    }
    for (const value of [identifier, iconName]) {
        const name = String(value || "").toLowerCase().split("/").pop()
            .replace(/\.(desktop|svg|png|xpm)$/, "").replace(/[ _]+/g, "-")
        if (aliases[name]) return aliases[name]
        for (const part of name.split(".")) if (aliases[part]) return aliases[part]
    }
    return ""
}
