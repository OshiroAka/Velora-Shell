#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
PYWAL_SCRIPT = BASE / "scripts" / "velora-pywal-theme.py"
PYWAL_THEME_PATH = BASE / "themes" / "pywal16.json"
WAL_PATH = Path(os.path.expanduser("~/.cache/wal/colors.json"))
BD_THEME_DIR = Path(os.path.expanduser("~/.config/BetterDiscord/themes"))
BD_THEME_PATH = BD_THEME_DIR / "VeloraPywal16.theme.css"


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def hex_to_rgb(value):
    value = str(value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("invalid hex color")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*(clamp(v) for v in rgb))


def css_url(path):
    if not path:
        return "none"
    try:
        resolved = Path(path).expanduser().resolve()
    except Exception:
        return "none"
    return f'url("file://{str(resolved).replace(chr(34), "%22")}")'


def color_from_theme(theme, key, fallback):
    value = str(theme.get(key) or fallback).strip()
    if value.startswith("#") and len(value) == 7:
        return value.lower()
    if value.startswith("rgba("):
        return rgb_to_hex(tuple(float(part.strip()) for part in value[5:-1].split(",")[:3]))
    return fallback


def alpha(theme, key, fallback, opacity):
    rgb = hex_to_rgb(color_from_theme(theme, key, fallback))
    return f"rgba({rgb[0]}, {rgb[1]}, {rgb[2]}, {opacity:.2f})"


def read_wal():
    if not WAL_PATH.exists():
        return {}
    try:
        return json.loads(WAL_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_theme():
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


def build_css(theme, wal):
    mode = str(theme.get("themeMode") or "dark")
    dark = mode != "light"
    wallpaper = theme.get("wallpaper") or wal.get("wallpaper") or ""
    bg = color_from_theme(theme, "surfaceBase", "#090404" if dark else "#f7f2f8")
    panel = color_from_theme(theme, "surfaceSidebar", "#151012" if dark else "#f7edf6")
    panel2 = color_from_theme(theme, "surfacePopup", "#1d151a" if dark else "#fff7fd")
    card = color_from_theme(theme, "surfaceCard", "#221a20" if dark else "#ffffff")
    input_bg = color_from_theme(theme, "surfaceInput", "#271f27" if dark else "#ffffff")
    text = color_from_theme(theme, "textPrimary", "#f3edf5" if dark else "#463954")
    text2 = color_from_theme(theme, "textSecondary", "#cfc4d8" if dark else "#725f82")
    muted = color_from_theme(theme, "textMuted", "#95889f" if dark else "#9b8ba8")
    accent = color_from_theme(theme, "accentPrimary", "#c894f2")
    accent2 = color_from_theme(theme, "accentSecondary", "#e8a6c8")
    accent3 = color_from_theme(theme, "accentTertiary", "#a8d8ff")
    border = color_from_theme(theme, "borderActive", accent)
    shadow = "rgba(0, 0, 0, 0.42)" if dark else "rgba(82, 62, 96, 0.18)"

    return f"""/**
 * @name Velora pywal16
 * @author Shira / Velora Shell
 * @version 1.0.0
 * @description Syncs BetterDiscord with the active Velora pywal16 wallpaper palette.
 * @source https://betterdiscord.app
 */

:root,
.theme-dark,
.theme-light,
.visual-refresh,
.visual-refresh.theme-dark,
.visual-refresh.theme-light,
#app-mount,
#app-mount .theme-dark,
#app-mount .theme-light {{
  --velora-wallpaper-image: {css_url(wallpaper)};
  --velora-bg: {bg};
  --velora-panel: {panel};
  --velora-panel-2: {panel2};
  --velora-card: {card};
  --velora-input: {input_bg};
  --velora-text: {text};
  --velora-text-soft: {text2};
  --velora-muted: {muted};
  --velora-accent: {accent};
  --velora-accent-2: {accent2};
  --velora-accent-3: {accent3};
  --velora-link: color-mix(in srgb, var(--velora-accent-2) 72%, white 28%);
  --velora-border: {border};
  --velora-glow: {alpha(theme, "accentPrimary", accent, 0.34)};
  --velora-hover: {alpha(theme, "accentPrimary", accent, 0.16)};
  --velora-active: {alpha(theme, "accentPrimary", accent, 0.26)};
  --velora-shadow: {shadow};
  --velora-chat: color-mix(in srgb, var(--velora-bg) 94%, black 6%);
  --velora-sidebar-solid: color-mix(in srgb, var(--velora-panel) 95%, black 5%);
  --velora-panel-solid: color-mix(in srgb, var(--velora-panel-2) 92%, var(--velora-bg) 8%);
  --velora-card-solid: color-mix(in srgb, var(--velora-card) 92%, var(--velora-bg) 8%);

  --background-primary: color-mix(in srgb, var(--velora-bg) 88%, black 12%) !important;
  --background-secondary: var(--velora-panel) !important;
  --background-secondary-alt: color-mix(in srgb, var(--velora-panel) 88%, black 12%) !important;
  --background-tertiary: color-mix(in srgb, var(--velora-panel) 76%, black 24%) !important;
  --background-accent: var(--velora-active) !important;
  --background-floating: var(--velora-panel-2) !important;
  --background-modifier-hover: var(--velora-hover) !important;
  --background-modifier-active: var(--velora-active) !important;
  --background-modifier-selected: var(--velora-active) !important;
  --background-mentioned: {alpha(theme, "accentSecondary", accent2, 0.15)} !important;
  --background-mentioned-hover: {alpha(theme, "accentSecondary", accent2, 0.22)} !important;
  --channeltextarea-background: var(--velora-input) !important;
  --input-background: var(--velora-input) !important;
  --modal-background: var(--velora-panel-2) !important;
  --modal-footer-background: var(--velora-panel) !important;
  --scrollbar-thin-thumb: var(--velora-border) !important;
  --scrollbar-auto-thumb: var(--velora-border) !important;
  --scrollbar-auto-track: transparent !important;
  --text-normal: var(--velora-text) !important;
  --text-primary: var(--velora-text) !important;
  --text-secondary: var(--velora-text-soft) !important;
  --text-tertiary: var(--velora-muted) !important;
  --text-link: var(--velora-link) !important;
  --text-muted: var(--velora-muted) !important;
  --header-primary: var(--velora-text) !important;
  --header-secondary: var(--velora-text-soft) !important;
  --interactive-normal: var(--velora-text-soft) !important;
  --interactive-hover: var(--velora-text) !important;
  --interactive-active: var(--velora-text) !important;
  --interactive-muted: var(--velora-muted) !important;
  --channels-default: var(--velora-text-soft) !important;
  --channel-icon: var(--velora-text-soft) !important;
  --brand-500: var(--velora-accent) !important;
  --brand-experiment: var(--velora-accent) !important;
  --focus-primary: var(--velora-accent-3) !important;
  --background-base-lowest: var(--velora-chat) !important;
  --background-base-lower: var(--velora-panel-solid) !important;
  --background-base-low: var(--velora-sidebar-solid) !important;
  --background-surface-high: var(--velora-card-solid) !important;
  --background-surface-higher: var(--velora-panel-solid) !important;
  --background-surface-highest: var(--velora-panel-solid) !important;
  --bg-base-primary: var(--velora-chat) !important;
  --bg-base-secondary: var(--velora-sidebar-solid) !important;
  --bg-base-tertiary: var(--velora-panel-solid) !important;
  --bg-surface-overlay: var(--velora-panel-solid) !important;
  --bg-surface-raised: var(--velora-panel-solid) !important;
  --chat-background-default: var(--velora-chat) !important;
  --chat-text-muted: var(--velora-muted) !important;
  --custom-channel-members-bg: var(--velora-sidebar-solid) !important;
  --custom-guild-sidebar-bg: var(--velora-panel-solid) !important;
}}

body,
#app-mount {{
  color: var(--velora-text) !important;
  background:
    linear-gradient(135deg, color-mix(in srgb, var(--velora-bg) 88%, black 12%), color-mix(in srgb, var(--velora-panel-2) 76%, var(--velora-accent) 24%)) !important;
}}

#app-mount::before {{
  content: "";
  position: fixed;
  inset: 0;
  pointer-events: none;
  background:
    linear-gradient(90deg, color-mix(in srgb, var(--velora-bg) 88%, transparent 12%), color-mix(in srgb, var(--velora-panel-2) 72%, transparent 28%)),
    var(--velora-wallpaper-image) center / cover no-repeat fixed;
  opacity: 0.22;
  z-index: 0;
}}

#app-mount > * {{
  position: relative;
  z-index: 1;
}}

.app_a3002d,
.appMount__51fd7,
.bg__960e4,
.container__2637a,
.container_c48ade,
.sidebar_c48ade,
.panels_c48ade,
.chat_f75fb0,
.chatContent_f75fb0,
.container__133bf,
.members_c8ffbb,
.peopleColumn__133bf,
.nowPlayingColumn__133bf,
.contentRegion__23e6b,
.sidebarRegionScroller__23e6b {{
  background: transparent !important;
}}

.container_c48ade,
.sidebar_c48ade,
.panels_c48ade,
.members_c8ffbb,
.nowPlayingColumn__133bf,
.sidebarRegionScroller__23e6b {{
  background: color-mix(in srgb, var(--velora-panel) 86%, transparent 14%) !important;
  border-color: color-mix(in srgb, var(--velora-border) 45%, transparent 55%) !important;
}}

.chatContent_f75fb0,
.peopleColumn__133bf,
.contentRegion__23e6b {{
  background: color-mix(in srgb, var(--velora-bg) 82%, transparent 18%) !important;
}}

.channelTextArea_f75fb0,
.scrollableContainer__74017,
.searchBar__97492,
.searchBarComponent__35e86,
.inner__999f6,
.input__0f084,
.inputWrapper__0f084 input {{
  background: color-mix(in srgb, var(--velora-input) 88%, transparent 12%) !important;
  border-color: color-mix(in srgb, var(--velora-border) 36%, transparent 64%) !important;
}}

.wrapper__2ea32:hover .link__2ea32,
.modeSelected__2ea32 .link__2ea32,
.interactive_bf202d:hover,
.interactiveSelected_bf202d {{
  background: var(--velora-active) !important;
  color: var(--velora-text) !important;
}}

.mentioned__5126c::before,
.replying__5126c::before {{
  background: var(--velora-accent) !important;
}}

.button__201d5.lookFilled__201d5.colorBrand__201d5,
.lookFilled__201d5.colorBrand__201d5,
.barFill_a562c8,
.control__0d850.checked__0d850 {{
  background: linear-gradient(135deg, var(--velora-accent), var(--velora-accent-2)) !important;
  color: white !important;
}}

.botTagRegular__82f07,
.numberBadge__2b1f5,
.unreadImportant__2ea32 {{
  background: var(--velora-accent) !important;
  color: white !important;
}}

.wrapper__44df5.selected__44df5 .childWrapper__44df5,
.circleIconButton__5bc7e.selected__5bc7e {{
  background: var(--velora-accent) !important;
  color: white !important;
  box-shadow: 0 0 22px var(--velora-glow) !important;
}}

.layer__960e4,
.standardSidebarView__23e6b,
.modal__7f8f5,
.root__49fc1,
.menu_c1e9c4,
.autocomplete__13533,
.popout__76f04 {{
  background: color-mix(in srgb, var(--velora-panel-2) 94%, transparent 6%) !important;
  border-color: color-mix(in srgb, var(--velora-border) 38%, transparent 62%) !important;
  box-shadow: 0 20px 60px var(--velora-shadow) !important;
}}

a,
.anchor_edefb8,
.username__0a06e,
.title__9293f,
.name__20a53 {{
  color: var(--velora-link) !important;
}}

#app-mount [class*="chatContent"],
#app-mount [class*="messagesWrapper"],
#app-mount [class*="peopleColumn"],
#app-mount [class*="contentRegion"] {{
  background: var(--velora-chat) !important;
}}

#app-mount [class*="messageContent"],
#app-mount [class*="contents_"] [class*="markup"],
#app-mount [class*="message_"] [class*="markup"],
#app-mount [data-list-item-id*="chat-messages"] {{
  color: var(--velora-text) !important;
  opacity: 1 !important;
}}

#app-mount [class*="messageContent"] *,
#app-mount [class*="markup"] *,
#app-mount [class*="message_"] [class*="contents"] {{
  opacity: 1 !important;
}}

#app-mount [class*="timestamp"],
#app-mount [class*="edited"],
#app-mount [class*="repliedText"],
#app-mount [class*="subText"],
#app-mount [class*="activityText"],
#app-mount [class*="membersGroup"] {{
  color: var(--velora-text-soft) !important;
}}

#app-mount [class*="guilds"],
#app-mount [class*="wrapper_ef3116"],
#app-mount [class*="scroller_ef3116"],
#app-mount [class*="itemsContainer_ef3116"],
#app-mount [class*="tutorialContainer"],
#app-mount [data-list-id="guildsnav"],
#app-mount nav[aria-label*="serv" i],
#app-mount nav[aria-label*="server" i] {{
  background: var(--velora-panel-solid) !important;
}}

#app-mount [class*="sidebarList"],
#app-mount [class*="sidebar_"],
#app-mount [class*="privateChannels"],
#app-mount [class*="channelList"],
#app-mount [class*="scroller__99e7c"],
#app-mount [class*="content__99f8c"],
#app-mount [class*="container__9293f"],
#app-mount [class*="searchBar__35e86"],
#app-mount nav[aria-label*="direct" i],
#app-mount nav[aria-label*="mensagens" i],
#app-mount [class*="container__2637a"],
#app-mount [class*="panels_"] {{
  background: var(--velora-sidebar-solid) !important;
}}

#app-mount [class*="privateChannels"] *,
#app-mount [class*="sidebarList"] *,
#app-mount nav[aria-label*="direct" i] *,
#app-mount nav[aria-label*="mensagens" i] * {{
  color: var(--velora-text-soft) !important;
}}

#app-mount [class*="searchBar"],
#app-mount [class*="searchBarComponent"],
#app-mount [class*="channel_"],
#app-mount [class*="interactive_"],
#app-mount [class*="layout_"],
#app-mount [class*="link_"] {{
  color: var(--velora-text-soft) !important;
}}

#app-mount [class*="selected"] [class*="layout_"],
#app-mount [class*="selected"] [class*="link_"],
#app-mount [class*="modeSelected"] [class*="link_"],
#app-mount [class*="interactiveSelected"] {{
  background: var(--velora-active) !important;
  color: var(--velora-text) !important;
}}

#app-mount [class*="userProfile"],
#app-mount [class*="userPanel"],
#app-mount [class*="userPopout"],
#app-mount [class*="profilePanel"],
#app-mount [class*="asidePanel"],
#app-mount [class*="outer_c0bea0"],
#app-mount [class*="inner_c0bea0"],
#app-mount [class*="overlay_"],
#app-mount [class*="section_"] {{
  background: var(--velora-panel-solid) !important;
  color: var(--velora-text) !important;
  border-color: color-mix(in srgb, var(--velora-border) 34%, transparent 66%) !important;
}}

#app-mount [class*="userProfile"] [class*="card_"],
#app-mount [class*="userProfile"] [class*="body_"],
#app-mount [class*="userProfile"] [class*="footer_"],
#app-mount [class*="profilePanel"] [class*="card_"],
#app-mount [class*="profilePanel"] [class*="body_"],
#app-mount [class*="profilePanel"] [class*="footer_"],
#app-mount [class*="asidePanel"] [class*="card_"],
#app-mount [class*="asidePanel"] [class*="body_"],
#app-mount [class*="asidePanel"] [class*="footer_"] {{
  background-color: color-mix(in srgb, var(--velora-card-solid) 82%, transparent 18%) !important;
  color: var(--velora-text) !important;
}}

html.theme-light,
body.theme-light,
#app-mount.theme-light,
#app-mount .theme-light,
#app-mount.visual-refresh.theme-light,
#app-mount .visual-refresh.theme-light {{
  color-scheme: dark !important;
  --text-normal: var(--velora-text) !important;
  --text-primary: var(--velora-text) !important;
  --text-secondary: var(--velora-text-soft) !important;
  --text-tertiary: var(--velora-muted) !important;
  --text-muted: var(--velora-muted) !important;
  --text-link: var(--velora-link) !important;
  --header-primary: var(--velora-text) !important;
  --header-secondary: var(--velora-text-soft) !important;
  --interactive-normal: var(--velora-text-soft) !important;
  --interactive-hover: var(--velora-text) !important;
  --interactive-active: var(--velora-text) !important;
  --channels-default: var(--velora-text-soft) !important;
  --background-primary: var(--velora-chat) !important;
  --background-secondary: var(--velora-sidebar-solid) !important;
  --background-tertiary: var(--velora-panel-solid) !important;
  --background-base-lowest: var(--velora-chat) !important;
  --background-base-lower: var(--velora-panel-solid) !important;
  --background-base-low: var(--velora-sidebar-solid) !important;
  --bg-base-primary: var(--velora-chat) !important;
  --bg-base-secondary: var(--velora-sidebar-solid) !important;
  --bg-base-tertiary: var(--velora-panel-solid) !important;
}}

#app-mount.theme-light *,
#app-mount .theme-light *,
#app-mount.visual-refresh.theme-light *,
#app-mount .visual-refresh.theme-light * {{
  color: var(--velora-text) !important;
  opacity: 1 !important;
  text-shadow: none !important;
}}

#app-mount.theme-light a,
#app-mount .theme-light a,
#app-mount.theme-light [class*="anchor"],
#app-mount .theme-light [class*="anchor"],
#app-mount.theme-light [class*="username"],
#app-mount .theme-light [class*="username"],
#app-mount.theme-light [class*="name_"],
#app-mount .theme-light [class*="name_"] {{
  color: var(--velora-link) !important;
}}

#app-mount.theme-light [class*="timestamp"],
#app-mount .theme-light [class*="timestamp"],
#app-mount.theme-light [class*="subText"],
#app-mount .theme-light [class*="subText"],
#app-mount.theme-light [class*="activityText"],
#app-mount .theme-light [class*="activityText"],
#app-mount.theme-light [class*="membersGroup"],
#app-mount .theme-light [class*="membersGroup"],
#app-mount.theme-light [class*="text-xs"],
#app-mount .theme-light [class*="text-xs"] {{
  color: var(--velora-text-soft) !important;
}}
"""


def write_css(css):
    BD_THEME_DIR.mkdir(parents=True, exist_ok=True)
    BD_THEME_PATH.write_text(css, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Generate a BetterDiscord theme from Velora pywal16.")
    parser.add_argument("--emit", action="store_true", help="print CSS instead of writing the theme file")
    parser.add_argument("--path", action="store_true", help="print the target theme path")
    args = parser.parse_args()

    theme = load_theme()
    wal = read_wal()
    css = build_css(theme, wal)

    if args.emit:
        print(css)
    else:
        write_css(css)
        if args.path:
            print(BD_THEME_PATH)

    return 0


if __name__ == "__main__":
    sys.exit(main())
