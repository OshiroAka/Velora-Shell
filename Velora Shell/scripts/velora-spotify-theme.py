#!/usr/bin/env python3
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
PYWAL_SCRIPT = BASE / "scripts" / "velora-pywal-theme.py"
PYWAL_THEME_PATH = BASE / "themes" / "pywal16.json"
WAL_PATH = Path(os.path.expanduser("~/.cache/wal/colors.json"))
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "velora-shell"
STATE_PATH = STATE_DIR / "spotify-theme.json"
RESTART_STAMP = STATE_DIR / "spotify-restart.stamp"
MODE_PATH = STATE_DIR / "spotify-restart-mode"
THEME_NAME = "VeloraPywal16"
COLOR_SCHEME = "Base"


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def hex_to_rgb(value):
    value = str(value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("invalid hex color")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*(clamp(v) for v in rgb))


def bare_hex(color):
    return str(color).strip().lstrip("#").lower()


def rgba_to_hex(value, fallback):
    value = str(value or "").strip()
    if value.startswith("#") and len(value) == 7:
        return value.lower()
    if value.startswith("rgba("):
        try:
            return rgb_to_hex(tuple(float(part.strip()) for part in value[5:-1].split(",")[:3]))
        except Exception:
            return fallback
    return fallback


def mix(a, b, amount):
    return tuple(a[i] + (b[i] - a[i]) * amount for i in range(3))


def luminance(rgb):
    def channel(value):
        value = value / 255
        return value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def darken(color, amount):
    return rgb_to_hex(mix(hex_to_rgb(color), (0, 0, 0), amount))


def lighten(color, amount):
    return rgb_to_hex(mix(hex_to_rgb(color), (255, 255, 255), amount))


def alpha(color, opacity):
    r, g, b = hex_to_rgb(color)
    return f"rgba({r}, {g}, {b}, {opacity:.2f})"


def text_on(color):
    return "#ffffff" if luminance(hex_to_rgb(color)) < 0.42 else "#241d28"


def read_wal():
    if not WAL_PATH.exists():
        return {}
    try:
        return json.loads(WAL_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_pywal_theme():
    if PYWAL_SCRIPT.exists():
        try:
            result = subprocess.run(
                [str(PYWAL_SCRIPT), "--emit-or-generate", "--no-ipc"],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                timeout=2.0,
                check=False,
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.loads(result.stdout.strip())
        except Exception:
            pass

    if PYWAL_THEME_PATH.exists():
        return json.loads(PYWAL_THEME_PATH.read_text(encoding="utf-8"))

    raise RuntimeError("pywal16 theme is not available")


def build_palette(theme, wal):
    mode = str(theme.get("themeMode") or "dark")
    dark = mode != "light"
    colors = wal.get("colors", {}) if isinstance(wal, dict) else {}
    special = wal.get("special", {}) if isinstance(wal, dict) else {}
    wal_bg = str(special.get("background") or colors.get("color0") or ("#08070b" if dark else "#faf4fb"))
    wal_fg = str(special.get("foreground") or colors.get("color7") or ("#f5eef8" if dark else "#44384f"))

    base = rgba_to_hex(theme.get("surfaceBase"), wal_bg)
    sidebar = rgba_to_hex(theme.get("surfaceSidebar"), darken(base, 0.08) if dark else lighten(base, 0.04))
    player = rgba_to_hex(theme.get("surfacePopup"), darken(base, 0.04) if dark else lighten(base, 0.08))
    card = rgba_to_hex(theme.get("surfaceCard"), darken(base, 0.10) if dark else "#ffffff")
    text = rgba_to_hex(theme.get("textPrimary"), wal_fg)
    subtext = rgba_to_hex(theme.get("textSecondary"), lighten(text, 0.24) if dark else darken(text, 0.18))
    muted = rgba_to_hex(theme.get("textMuted"), darken(subtext, 0.18) if dark else lighten(subtext, 0.18))
    accent = rgba_to_hex(theme.get("accentPrimary"), "#c894f2")
    accent2 = rgba_to_hex(theme.get("accentSecondary"), "#e8a6c8")
    accent3 = rgba_to_hex(theme.get("accentTertiary"), "#a8d8ff")
    red = str(colors.get("color1") or "#f38ba8")

    if dark:
        main = darken(base, 0.20)
        sidebar = darken(sidebar, 0.10)
        player = darken(player, 0.08)
        card = darken(card, 0.05)
        hover = alpha(accent, 0.18)
        active = alpha(accent, 0.30)
        border = alpha(accent, 0.30)
        shadow = "000000"
    else:
        main = lighten(base, 0.28)
        sidebar = lighten(sidebar, 0.12)
        player = lighten(player, 0.10)
        card = lighten(card, 0.02)
        hover = alpha(accent, 0.13)
        active = alpha(accent, 0.24)
        border = alpha(accent, 0.36)
        shadow = bare_hex(darken(accent2, 0.48))

    return {
        "mode": mode,
        "dark": dark,
        "wallpaper": theme.get("wallpaper") or wal.get("wallpaper", ""),
        "checksum": theme.get("checksum") or wal.get("checksum", ""),
        "main": main,
        "sidebar": sidebar,
        "player": player,
        "card": card,
        "text": text,
        "subtext": subtext,
        "muted": muted,
        "accent": accent,
        "accent2": accent2,
        "accent3": accent3,
        "red": red,
        "hover": hover,
        "active": active,
        "border": border,
        "shadow": shadow,
        "button_text": text_on(accent),
    }


def spicetify_bin():
    path = shutil.which("spicetify")
    if path:
        return path
    fallback = Path.home() / ".spicetify" / "spicetify"
    return str(fallback) if fallback.exists() else ""


def spicetify_userdata(spice):
    if not spice:
        return Path.home() / ".config" / "spicetify"
    try:
        result = subprocess.run(
            [spice, "path", "userdata"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2.0,
            check=False,
        )
        if result.returncode == 0 and result.stdout.strip():
            return Path(result.stdout.strip())
    except Exception:
        pass
    return Path.home() / ".config" / "spicetify"


def restart_mode():
    try:
        value = MODE_PATH.read_text(encoding="utf-8").strip()
    except Exception:
        value = "restart"
    return "off" if value == "off" else "restart"


def set_restart_mode(value):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    value = "off" if str(value).strip() == "off" else "restart"
    MODE_PATH.write_text(value + "\n", encoding="utf-8")
    return value


def handle_mode_command(args):
    subcommand = args[0] if args else "get"
    if subcommand == "get":
        print(restart_mode())
        return 0
    if subcommand == "set":
        print(set_restart_mode(args[1] if len(args) > 1 else "restart"))
        return 0
    print("usage: velora-spotify-theme.py mode get|set [restart|off]", file=sys.stderr)
    return 2


def write_color_ini(path, p):
    path.write_text(f"""[Base]
main               = {bare_hex(p["main"])}
sidebar            = {bare_hex(p["sidebar"])}
player             = {bare_hex(p["player"])}
card               = {bare_hex(p["card"])}
shadow             = {p["shadow"]}
selected-row       = {bare_hex(p["accent"])}
button             = {bare_hex(p["accent"])}
button-active      = {bare_hex(p["accent2"])}
button-disabled    = {bare_hex(p["muted"])}
tab-active         = {bare_hex(p["accent2"])}
notification       = {bare_hex(p["accent3"])}
notification-error = {bare_hex(p["red"])}
misc               = {bare_hex(p["muted"])}
text               = {bare_hex(p["text"])}
subtext            = {bare_hex(p["subtext"])}
""", encoding="utf-8")


def write_user_css(path, p):
    path.write_text(f""":root,
.encore-dark-theme,
.encore-light-theme {{
  --velora-main: {p["main"]};
  --velora-sidebar: {p["sidebar"]};
  --velora-player: {p["player"]};
  --velora-card: {p["card"]};
  --velora-text: {p["text"]};
  --velora-subtext: {p["subtext"]};
  --velora-muted: {p["muted"]};
  --velora-accent: {p["accent"]};
  --velora-accent-2: {p["accent2"]};
  --velora-accent-3: {p["accent3"]};
  --velora-hover: {p["hover"]};
  --velora-active: {p["active"]};
  --velora-border: {p["border"]};
  --velora-button-text: {p["button_text"]};
  --velora-radius: 18px;
  --velora-left-width: clamp(236px, 16vw, 312px);
  --velora-player-height: 104px;

  --spice-main: {p["main"]};
  --spice-sidebar: {p["sidebar"]};
  --spice-player: {p["player"]};
  --spice-card: {p["card"]};
  --spice-button: {p["accent"]};
  --spice-button-active: {p["accent2"]};
  --spice-selected-row: {p["accent"]};
  --spice-tab-active: {p["accent2"]};
  --spice-text: {p["text"]};
  --spice-subtext: {p["subtext"]};

  --background-base: var(--velora-main) !important;
  --background-highlight: var(--velora-hover) !important;
  --background-press: var(--velora-active) !important;
  --background-elevated-base: var(--velora-card) !important;
  --background-elevated-highlight: var(--velora-hover) !important;
  --background-tinted-base: var(--velora-player) !important;
  --background-tinted-highlight: var(--velora-hover) !important;
  --text-base: var(--velora-text) !important;
  --text-subdued: var(--velora-subtext) !important;
  --text-bright-accent: var(--velora-accent-2) !important;
  --essential-base: var(--velora-text) !important;
  --essential-subdued: var(--velora-muted) !important;
  --essential-bright-accent: var(--velora-accent) !important;
  --decorative-base: var(--velora-accent) !important;
  --decorative-subdued: var(--velora-border) !important;
}}

body {{
  background: linear-gradient(135deg, color-mix(in srgb, var(--velora-sidebar) 88%, black 12%), var(--velora-main)) !important;
}}

:root,
.Root__top-container {{
  --left-sidebar-width: 276 !important;
  --right-sidebar-width: 0 !important;
}}

.Root,
.Root__top-container {{
  background: transparent !important;
}}

.Root__top-container {{
  display: grid !important;
  grid-template-areas:
    "top-banner top-banner"
    "global-nav global-nav"
    "left-sidebar main-view"
    "now-playing-bar now-playing-bar" !important;
  grid-template-columns: var(--velora-left-width) minmax(0, 1fr) !important;
  grid-template-rows: auto auto minmax(0, 1fr) var(--velora-player-height) !important;
  gap: 8px !important;
  padding: 8px !important;
  min-width: 0 !important;
}}

.Root__nav-bar,
[data-testid="left-sidebar"] {{
  grid-area: left-sidebar !important;
  width: var(--velora-left-width) !important;
  min-width: var(--velora-left-width) !important;
  max-width: var(--velora-left-width) !important;
  overflow: hidden !important;
}}

.Root__main-view {{
  grid-area: main-view !important;
  min-width: 0 !important;
  width: 100% !important;
}}

.Root__now-playing-bar,
[data-testid="now-playing-bar"] {{
  grid-area: now-playing-bar !important;
  min-width: 0 !important;
  width: 100% !important;
}}

.Root__right-sidebar,
[data-testid="right-sidebar"],
[data-testid="now-playing-view"],
[data-testid="NPV_Panel_OpenDiv"],
aside[aria-label*="Now playing"],
aside[aria-label*="now playing"],
aside[aria-label*="Tocando"],
aside[aria-label*="tocando"] {{
  display: none !important;
  visibility: hidden !important;
  width: 0 !important;
  min-width: 0 !important;
  max-width: 0 !important;
  flex: 0 0 0 !important;
  grid-area: unset !important;
  pointer-events: none !important;
}}

.Root__main-view,
.Root__nav-bar,
.Root__now-playing-bar,
[data-testid="left-sidebar"],
[data-testid="now-playing-bar"] {{
  background: color-mix(in srgb, var(--velora-sidebar) 88%, transparent 12%) !important;
  border: 1px solid color-mix(in srgb, var(--velora-border) 48%, transparent 52%) !important;
  border-radius: 14px !important;
  overflow: hidden !important;
}}

.Root__top-container,
.main-view-container,
.main-home-homeHeader,
.main-topBar-background,
.main-topBar-overlay,
[data-testid="topbar-background"] {{
  background: transparent !important;
}}

.main-topBar-container,
[data-testid="topbar"] {{
  max-width: 100% !important;
}}

.main-topBar-searchBar,
[data-testid="search-input"],
[data-testid="search-input-container"] {{
  min-width: min(360px, 58vw) !important;
  max-width: 620px !important;
}}

.main-view-container__scroll-node,
.main-view-container,
[data-testid="home-page"],
[data-testid="playlist-page"] {{
  background:
    radial-gradient(circle at 16% 0%, color-mix(in srgb, var(--velora-accent) 18%, transparent 82%), transparent 34rem),
    radial-gradient(circle at 88% 4%, color-mix(in srgb, var(--velora-accent-3) 18%, transparent 82%), transparent 32rem),
    linear-gradient(145deg, color-mix(in srgb, var(--velora-main) 92%, black 8%), var(--velora-main)) !important;
}}

.main-home-homeHeader,
[data-testid="home-page"] section {{
  max-width: none !important;
}}

.main-gridContainer-gridContainer,
.main-shelf-grid,
[data-testid="grid-container"] {{
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)) !important;
  column-gap: 24px !important;
  row-gap: 28px !important;
}}

.main-card-card,
[data-testid="card"] {{
  min-width: 0 !important;
}}

.main-card-card,
.main-trackList-trackListRow,
.main-nowPlayingWidget-nowPlaying,
.main-yourLibraryX-listItem,
.main-entityHeader-container,
[data-testid="card"],
[data-testid="tracklist-row"],
[data-testid="now-playing-widget"],
[data-testid="herocard-click-handler"] {{
  border-radius: var(--velora-radius) !important;
}}

.Root__nav-bar nav,
[data-testid="left-sidebar"] nav,
.main-yourLibraryX-library,
.main-yourLibraryX-list,
.main-yourLibraryX-listItem {{
  min-width: 0 !important;
}}

.Root__nav-bar a,
.Root__nav-bar button,
[data-testid="left-sidebar"] a,
[data-testid="left-sidebar"] button {{
  border-radius: 10px !important;
}}

.main-yourLibraryX-listItem,
[data-testid="left-sidebar"] [role="listitem"] {{
  min-height: 48px !important;
}}

.Root__nav-bar img,
[data-testid="left-sidebar"] img {{
  border-radius: 8px !important;
}}

.main-card-card,
.main-nowPlayingWidget-nowPlaying,
.main-yourLibraryX-listItem,
[data-testid="card"],
[data-testid="now-playing-widget"] {{
  background: color-mix(in srgb, var(--velora-card) 82%, transparent 18%) !important;
  box-shadow: 0 16px 36px rgba(0, 0, 0, 0.24) !important;
}}

.main-trackList-trackListRow:hover,
.main-card-card:hover,
.main-yourLibraryX-listItem:hover,
[data-testid="tracklist-row"]:hover,
[data-testid="card"]:hover {{
  background: var(--velora-hover) !important;
}}

.main-trackList-selected,
[aria-selected="true"] {{
  background: var(--velora-active) !important;
}}

.main-playButton-PlayButton,
.main-playButton-primary,
button[data-testid="play-button"],
button[data-testid="control-button-playpause"] {{
  background: linear-gradient(135deg, var(--velora-accent), var(--velora-accent-2)) !important;
  color: var(--velora-button-text) !important;
  border-radius: 999px !important;
  box-shadow: 0 0 24px color-mix(in srgb, var(--velora-accent) 42%, transparent 58%) !important;
}}

.main-coverSlotExpanded-container,
.cover-art,
.main-image-image,
img {{
  border-radius: 14px !important;
}}

.main-nowPlayingBar-container,
[data-testid="now-playing-bar"] {{
  background: color-mix(in srgb, var(--velora-player) 90%, transparent 10%) !important;
  border-top: 1px solid var(--velora-border) !important;
  min-height: var(--velora-player-height) !important;
  padding: 8px 16px !important;
}}

.main-nowPlayingBar-left,
[data-testid="now-playing-widget"] {{
  min-width: 240px !important;
}}

.main-nowPlayingBar-center {{
  min-width: min(520px, 44vw) !important;
}}

.main-type-ballad,
.main-type-mesto,
.main-type-canon,
.main-type-alto,
.main-type-cello,
.main-type-finale,
.main-type-mestoBold,
.main-type-balladBold,
a,
span,
button {{
  color: var(--velora-text) !important;
}}

.main-type-mesto,
.main-type-canon,
[data-testid="context-item-info-subtitles"],
.main-trackInfo-artists,
.main-trackList-rowSubTitle {{
  color: var(--velora-subtext) !important;
}}

.progress-bar,
.playback-bar__progress-time,
.main-playbackBarRemainingTime-container,
.main-playbackBarTime-container {{
  color: var(--velora-subtext) !important;
}}

.progress-bar__fg,
.x-progressBar-fillColor {{
  background-color: var(--velora-accent) !important;
}}
""", encoding="utf-8")


def write_theme_js(path):
    path.write_text("""(() => {
  const root = document.documentElement;
  const bodyClass = "velora-spotify-reference-layout";

  function mark() {
    root.classList.add(bodyClass);
    root.setAttribute("data-right-sidebar-hidden", "true");
    document.body?.classList.add(bodyClass);
    document.querySelector(".Root__top-container")?.setAttribute("data-right-sidebar-hidden", "true");
  }

  function closeRightPanel() {
    const sidebar =
      document.querySelector(".Root__right-sidebar") ||
      document.querySelector('[data-testid="right-sidebar"]') ||
      document.querySelector('[data-testid="now-playing-view"]');

    if (!sidebar) return;

    const buttons = [...sidebar.querySelectorAll("button")];
    const closeButton = buttons.find((button) => {
      const label = (button.getAttribute("aria-label") || button.title || "").toLowerCase();
      return label.includes("close") || label.includes("fechar");
    });

    closeButton?.click();
  }

  function apply() {
    mark();
    closeRightPanel();
    localStorage.setItem("velora:spotify-reference-layout", "1");
  }

  apply();
  window.addEventListener("load", apply, { once: true });
  setTimeout(apply, 700);
  setTimeout(apply, 1800);
})();
""", encoding="utf-8")


def patch_index_html(index_path):
    text = index_path.read_text(encoding="utf-8", errors="ignore")

    if "href='user.css'" not in text and 'href="user.css"' not in text:
        text = text.replace(
            "<link rel='stylesheet' class='userCSS' href='colors.css'>",
            "<link rel='stylesheet' class='userCSS' href='colors.css'>\n<link rel='stylesheet' class='userCSS' href='user.css'>",
        )

    if "src='theme.js'" not in text and 'src="theme.js"' not in text:
        marker = "<script defer=\"defer\" src=\"/xpui-modules.js\"></script>"
        if marker in text:
            text = text.replace(marker, "<script defer src='theme.js'></script>\n" + marker)
        else:
            text = text.replace("<script defer=\"defer\" src=\"/xpui-snapshot.js\"></script>", "<script defer src='theme.js'></script>\n<script defer=\"defer\" src=\"/xpui-snapshot.js\"></script>")

    replacements = {
        "current_theme": THEME_NAME,
        "color_scheme": COLOR_SCHEME,
        "check_spicetify_update": "false",
    }

    for key, value in replacements.items():
        if value in ("true", "false"):
            repl = f'Spicetify.Config["{key}"]={value};'
        else:
            repl = f'Spicetify.Config["{key}"]="{value}";'
        pattern = rf'Spicetify\.Config\["{re.escape(key)}"\]\s*=\s*(?:"[^"]*"|true|false);'
        text = re.sub(pattern, repl, text)

    index_path.write_text(text, encoding="utf-8")


def patch_xpui_direct(spice, theme_dir, quiet):
    if not spice:
        return False

    spotify_path = ""
    try:
        path_result = subprocess.run(
            [spice, "config", "spotify_path"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2.0,
            check=False,
        )
        spotify_path = path_result.stdout.strip() if path_result.returncode == 0 else ""
    except Exception:
        spotify_path = ""

    xpui_dir = Path(spotify_path) / "Apps" / "xpui" if spotify_path else None
    if not xpui_dir or not xpui_dir.is_dir():
        return False

    try:
        shutil.copy2(theme_dir / "user.css", xpui_dir / "user.css")
        shutil.copy2(theme_dir / "theme.js", xpui_dir / "theme.js")
        index_path = xpui_dir / "index.html"
        if index_path.exists():
            patch_index_html(index_path)
        return True
    except Exception as exc:
        if not quiet:
            print(f"direct xpui patch failed: {exc}", file=sys.stderr)
        return False


def apply_spicetify(spice, theme_dir, quiet):
    if not spice:
        return False

    config_cmd = [
        spice,
        "config",
        "current_theme", THEME_NAME,
        "color_scheme", COLOR_SCHEME,
        "inject_css", "1",
        "inject_theme_js", "1",
        "replace_colors", "0",
        "check_spicetify_update", "0",
    ]
    subprocess.run(config_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

    direct_patched = patch_xpui_direct(spice, theme_dir, quiet)
    if direct_patched:
        return True

    spotify_path = ""
    try:
        path_result = subprocess.run(
            [spice, "config", "spotify_path"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2.0,
            check=False,
        )
        spotify_path = path_result.stdout.strip() if path_result.returncode == 0 else ""
    except Exception:
        spotify_path = ""

    xpui_colors = Path(spotify_path) / "Apps" / "xpui" / "colors.css" if spotify_path else None
    if xpui_colors and xpui_colors.exists() and not os.access(xpui_colors, os.W_OK):
        return False

    for cmd in ([spice, "refresh", "-s", "-q"], [spice, "apply", "-q"]):
        try:
            result = subprocess.run(
                cmd,
                stdout=subprocess.DEVNULL if quiet else None,
                stderr=subprocess.DEVNULL if quiet else None,
                timeout=12.0,
                check=False,
            )
            if result.returncode == 0:
                return True
        except Exception:
            pass
    return False


def spotify_running():
    try:
        result = subprocess.run(
            ["pgrep", "-f", "(^|/)(spotify|spotify-launcher)( |$)|/app/extra/share/spotify/spotify"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=1.0,
            check=False,
        )
        return result.returncode == 0 and bool(result.stdout.strip())
    except Exception:
        return False


def restart_spotify():
    if not spotify_running():
        return "not-running"

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        last = float(RESTART_STAMP.read_text(encoding="utf-8").strip())
    except Exception:
        last = 0.0

    try:
        import time
        now = time.time()
        if now - last < 1.5:
            return "debounced"
        RESTART_STAMP.write_text(str(now), encoding="utf-8")
    except Exception:
        pass

    flatpak = shutil.which("flatpak")
    if flatpak:
        subprocess.run([flatpak, "kill", "com.spotify.Client"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
        unit = f"velora-spotify-{os.getpid()}"
        systemd_run = shutil.which("systemd-run")
        if systemd_run:
            result = subprocess.run(
                [systemd_run, "--user", f"--unit={unit}", "--collect", flatpak, "run", "com.spotify.Client"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=2.0,
                check=False,
            )
            return "flatpak-systemd" if result.returncode == 0 else "flatpak-systemd-failed"

        subprocess.Popen([flatpak, "run", "com.spotify.Client"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return "flatpak"

    spice = spicetify_bin()
    if spice:
        result = subprocess.run([spice, "restart"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=4.0, check=False)
        return "spicetify" if result.returncode == 0 else "spicetify-failed"

    return "unavailable"


def inject_runtime_theme(theme_dir, quiet):
    node = shutil.which("node")
    if not node or not spotify_running():
        return False

    node_code = r"""
const fs = require("node:fs");
const cssPath = process.argv[1];
const jsPath = process.argv[2];
const css = fs.readFileSync(cssPath, "utf8");
const themeJs = fs.existsSync(jsPath) ? fs.readFileSync(jsPath, "utf8") : "";

async function main() {
  const targets = await (await fetch("http://127.0.0.1:8088/json/list")).json();
  const page = targets.find((target) => target.type === "page");
  if (!page) throw new Error("Spotify DevTools page not found");

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let nextId = 1;
  const pending = new Map();

  ws.onmessage = (event) => {
    const message = JSON.parse(event.data);
    if (!message.id || !pending.has(message.id)) return;
    const { resolve, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) reject(new Error(message.error.message || "CDP error"));
    else resolve(message.result);
  };

  await new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = () => reject(new Error("WebSocket failed"));
    setTimeout(() => reject(new Error("WebSocket timeout")), 1800);
  });

  function send(method, params) {
    const id = nextId++;
    const payload = { id, method, params };
    return new Promise((resolve, reject) => {
      pending.set(id, { resolve, reject });
      ws.send(JSON.stringify(payload));
    });
  }

  const expression = `(() => {
    const css = ${JSON.stringify(css)};
    const themeJs = ${JSON.stringify(themeJs)};
    let style = document.getElementById("velora-runtime-theme");
    if (!style) {
      style = document.createElement("style");
      style.id = "velora-runtime-theme";
      document.head.appendChild(style);
    }
    style.textContent = css;
    try {
      (0, eval)(themeJs);
    } catch (error) {
      console.error("Velora Spotify theme.js failed", error);
    }
    return {
      injected: true,
      hasRightSidebar: Boolean(document.querySelector(".Root__right-sidebar")),
      leftWidth: getComputedStyle(document.documentElement).getPropertyValue("--velora-left-width").trim()
    };
  })()`;

  const result = await send("Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: false,
  });
  console.log(JSON.stringify(result.result.value || {}, null, 2));
  ws.close();
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
"""

    try:
        result = subprocess.run(
            [node, "-e", node_code, str(theme_dir / "user.css"), str(theme_dir / "theme.js")],
            text=True,
            stdout=subprocess.DEVNULL if quiet else subprocess.PIPE,
            stderr=subprocess.DEVNULL if quiet else subprocess.PIPE,
            timeout=5.0,
            check=False,
        )
        if not quiet and result.stdout:
            print(result.stdout.strip())
        if not quiet and result.stderr:
            print(result.stderr.strip(), file=sys.stderr)
        return result.returncode == 0
    except Exception as exc:
        if not quiet:
            print(f"runtime inject failed: {exc}", file=sys.stderr)
        return False


def save_state(p, theme_dir, direct_applied, runtime_injected, restart_status):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    data = {
        "theme": THEME_NAME,
        "scheme": COLOR_SCHEME,
        "mode": p["mode"],
        "wallpaper": p["wallpaper"],
        "checksum": p["checksum"],
        "themeDir": str(theme_dir),
        "modeSetting": restart_mode(),
        "directApply": direct_applied,
        "runtimeInject": runtime_injected,
        "restart": restart_status,
        "reloadPath": "direct" if direct_applied else ("runtime-inject" if runtime_injected else ("spotify-restart" if restart_status not in ("disabled", "not-running", "unavailable") else "next-launch")),
    }
    STATE_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Generate and apply Velora pywal16 theme for Spotify/Spicetify.")
    parser.add_argument("--quiet", action="store_true", help="suppress normal output")
    parser.add_argument("--status", action="store_true", help="print current generated state")
    parser.add_argument("--no-apply", action="store_true", help="write the theme but do not run spicetify refresh/apply")
    parser.add_argument("--no-restart", action="store_true", help="do not restart Spotify when it is already running")
    parser.add_argument("command", nargs="*", help="optional command: mode get|set [restart|off]")
    args = parser.parse_args()

    if args.command:
        if args.command[0] == "mode":
            return handle_mode_command(args.command[1:])
        print("unknown command: " + args.command[0], file=sys.stderr)
        return 2

    if args.status:
        if STATE_PATH.exists():
            print(STATE_PATH.read_text(encoding="utf-8").strip())
        else:
            print("missing")
        return 0

    spice = spicetify_bin()
    wal = read_wal()
    theme = load_pywal_theme()
    palette = build_palette(theme, wal)
    userdata = spicetify_userdata(spice)
    theme_dir = userdata / "Themes" / THEME_NAME
    theme_dir.mkdir(parents=True, exist_ok=True)

    write_color_ini(theme_dir / "color.ini", palette)
    write_user_css(theme_dir / "user.css", palette)
    write_theme_js(theme_dir / "theme.js")
    applied = False if args.no_apply else apply_spicetify(spice, theme_dir, args.quiet)
    runtime_injected = False if args.no_apply else inject_runtime_theme(theme_dir, args.quiet)
    restart_status = "disabled" if args.no_restart or restart_mode() == "off" else restart_spotify()
    save_state(palette, theme_dir, applied, runtime_injected, restart_status)

    if not args.quiet:
        print(f"Spotify theme={theme_dir}")
        print(f"Spicetify applied={applied}")
        print(f"Runtime injected={runtime_injected}")
        print(f"Spotify restart={restart_status}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
