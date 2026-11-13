#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
PYWAL_SCRIPT = BASE / "scripts" / "velora-pywal-theme.py"
PYWAL_THEME_PATH = BASE / "themes" / "pywal16.json"
WAL_PATH = Path(os.path.expanduser("~/.cache/wal/colors.json"))
CURRENT_WALLPAPER_PATH = Path(os.path.expanduser("~/.cache/velora-shell/current_wallpaper"))
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "velora-shell"
STATE_PATH = STATE_DIR / "obsidian-theme.json"
SNIPPET_NAME = "velora-pywal16"
SNIPPET_FILE = f"{SNIPPET_NAME}.css"
IMAGE_SUFFIXES = {".avif", ".bmp", ".gif", ".jpeg", ".jpg", ".png", ".webp"}
DEFAULT_VAULTS = (
    Path.home() / "Documentos/Obsidian Vault",
    Path.home() / "Documents/Obsidian Vault",
)


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def hex_to_rgb(value):
    value = str(value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("invalid hex color")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*(clamp(v) for v in rgb))


def rgba(color, opacity):
    r, g, b = hex_to_rgb(color)
    return f"rgba({r}, {g}, {b}, {opacity:.3f})"


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


def text_on(color):
    return "#ffffff" if luminance(hex_to_rgb(color)) < 0.42 else "#30283a"


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


def css_quote(value):
    return str(value).replace("\\", "\\\\").replace('"', '\\"')


def read_json(path, fallback):
    if not path.exists():
        return fallback
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return fallback


def read_wal():
    return read_json(WAL_PATH, {})


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


def pick_vaults(args):
    if args.vault:
        vaults = [Path(value).expanduser() for value in args.vault]
    else:
        vaults = [vault for vault in DEFAULT_VAULTS if (vault / ".obsidian").is_dir()]

    if not vaults:
        raise RuntimeError("no Obsidian vault found")

    missing = [str(vault) for vault in vaults if not (vault / ".obsidian").is_dir()]
    if missing:
        raise RuntimeError("not an Obsidian vault: " + ", ".join(missing))

    return vaults


def current_wallpaper(theme, wal):
    for raw in (theme.get("wallpaper"), wal.get("wallpaper")):
        if raw and Path(str(raw)).expanduser().is_file():
            return Path(str(raw)).expanduser()

    if CURRENT_WALLPAPER_PATH.exists():
        try:
            parts = CURRENT_WALLPAPER_PATH.read_text(encoding="utf-8").strip().split("|")
            for raw in reversed(parts[1:3]):
                if raw and Path(raw).expanduser().is_file():
                    return Path(raw).expanduser()
        except Exception:
            pass

    return None


def install_wallpaper_asset(vault, wallpaper):
    if not wallpaper or not wallpaper.is_file() or wallpaper.suffix.lower() not in IMAGE_SUFFIXES:
        return "none", None

    asset_dir = vault / ".obsidian" / "velora-wallpaper"
    asset_dir.mkdir(parents=True, exist_ok=True)
    suffix = wallpaper.suffix.lower()
    target = asset_dir / f"current-wallpaper{suffix}"

    for old in asset_dir.glob("current-wallpaper.*"):
        if old != target:
            try:
                old.unlink()
            except Exception:
                pass

    try:
        if wallpaper.resolve() != target.resolve():
            shutil.copy2(wallpaper, target)
    except Exception:
        shutil.copy2(wallpaper, target)

    return f'url("../velora-wallpaper/{css_quote(target.name)}")', target


def palette_from_theme(theme, wal):
    mode = str(theme.get("themeMode") or "dark")
    dark = mode != "light"
    colors = wal.get("colors", {}) if isinstance(wal, dict) else {}
    special = wal.get("special", {}) if isinstance(wal, dict) else {}
    wal_bg = str(special.get("background") or colors.get("color0") or ("#09070c" if dark else "#f8f2fa"))
    wal_fg = str(special.get("foreground") or colors.get("color7") or ("#f4edf8" if dark else "#483c54"))

    bg = rgba_to_hex(theme.get("surfaceBase"), wal_bg)
    sidebar = rgba_to_hex(theme.get("surfaceSidebar"), darken(bg, 0.05) if dark else lighten(bg, 0.04))
    popup = rgba_to_hex(theme.get("surfacePopup"), darken(bg, 0.02) if dark else lighten(bg, 0.08))
    card = rgba_to_hex(theme.get("surfaceCard"), darken(bg, 0.08) if dark else "#ffffff")
    input_bg = rgba_to_hex(theme.get("surfaceInput"), darken(bg, 0.10) if dark else lighten(bg, 0.12))
    text = rgba_to_hex(theme.get("textPrimary"), wal_fg)
    text_soft = rgba_to_hex(theme.get("textSecondary"), lighten(text, 0.28) if dark else darken(text, 0.18))
    muted = rgba_to_hex(theme.get("textMuted"), darken(text_soft, 0.18) if dark else lighten(text_soft, 0.18))
    accent = rgba_to_hex(theme.get("accentPrimary"), "#c894f2")
    accent2 = rgba_to_hex(theme.get("accentSecondary"), "#e8a6c8")
    accent3 = rgba_to_hex(theme.get("accentTertiary"), "#a8d8ff")
    border = rgba_to_hex(theme.get("borderActive"), accent)

    if dark:
        # Keep Obsidian closer to the Zen/kitty glass balance: tint the dark
        # pywal base instead of burying the wallpaper under an opaque wash.
        glass_tint = hex_to_rgb(accent2)
        app_bg = rgb_to_hex(mix(hex_to_rgb(bg), glass_tint, 0.14))
        main = rgb_to_hex(mix(hex_to_rgb(bg), glass_tint, 0.09))
        panel = rgb_to_hex(mix(hex_to_rgb(sidebar), hex_to_rgb(accent), 0.08))
        panel2 = rgb_to_hex(mix(hex_to_rgb(popup), glass_tint, 0.08))
        card = rgb_to_hex(mix(hex_to_rgb(card), glass_tint, 0.05))
        input_bg = rgb_to_hex(mix(hex_to_rgb(input_bg), glass_tint, 0.06))
        overlay = rgba(app_bg, 0.38)
        overlay_end = rgba(app_bg, 0.48)
        workspace = rgba(main, 0.34)
        panel_alpha = rgba(panel, 0.50)
        editor_alpha = rgba(main, 0.30)
        leaf_alpha = rgba(main, 0.20)
        content_alpha_top = rgba(main, 0.22)
        content_alpha_bottom = rgba(main, 0.34)
        shadow = "rgba(0, 0, 0, 0.30)"
        highlight = rgba(accent, 0.24)
        hover = rgba(accent, 0.12)
    else:
        app_bg = lighten(bg, 0.18)
        main = lighten(bg, 0.24)
        panel = lighten(sidebar, 0.10)
        panel2 = lighten(popup, 0.08)
        card = lighten(card, 0.04)
        input_bg = lighten(input_bg, 0.06)
        overlay = rgba(app_bg, 0.54)
        overlay_end = rgba(app_bg, 0.62)
        workspace = rgba(main, 0.58)
        panel_alpha = rgba(panel, 0.68)
        editor_alpha = rgba(main, 0.48)
        leaf_alpha = rgba(main, 0.28)
        content_alpha_top = rgba(main, 0.30)
        content_alpha_bottom = rgba(main, 0.42)
        shadow = rgba(darken(accent2, 0.44), 0.20)
        highlight = rgba(accent, 0.24)
        hover = rgba(accent, 0.12)

    return {
        "mode": mode,
        "dark": dark,
        "bg": bg,
        "app_bg": app_bg,
        "main": main,
        "panel": panel,
        "panel2": panel2,
        "card": card,
        "input": input_bg,
        "text": text,
        "text_soft": text_soft,
        "muted": muted,
        "accent": accent,
        "accent2": accent2,
        "accent3": accent3,
        "border": border,
        "button_text": text_on(accent),
        "overlay": overlay,
        "overlay_end": overlay_end,
        "workspace": workspace,
        "panel_alpha": panel_alpha,
        "editor_alpha": editor_alpha,
        "leaf_alpha": leaf_alpha,
        "content_alpha_top": content_alpha_top,
        "content_alpha_bottom": content_alpha_bottom,
        "shadow": shadow,
        "highlight": highlight,
        "hover": hover,
        "red": str(colors.get("color1") or "#f38ba8"),
        "green": str(colors.get("color2") or "#a6e3a1"),
        "yellow": str(colors.get("color3") or "#f9e2af"),
        "blue": str(colors.get("color4") or accent3),
        "magenta": str(colors.get("color5") or accent2),
        "cyan": str(colors.get("color6") or accent3),
    }


def build_css(p, wallpaper_url):
    return f"""/*
 * Velora pywal16 for Obsidian.
 * Generated by velora-obsidian-theme.py. Manual edits will be overwritten.
 */

body {{
  --velora-wallpaper-image: {wallpaper_url};
  --velora-bg: {p["app_bg"]};
  --velora-main: {p["main"]};
  --velora-panel: {p["panel"]};
  --velora-panel-2: {p["panel2"]};
  --velora-card: {p["card"]};
  --velora-input: {p["input"]};
  --velora-text: {p["text"]};
  --velora-text-soft: {p["text_soft"]};
  --velora-muted: {p["muted"]};
  --velora-accent: {p["accent"]};
  --velora-accent-2: {p["accent2"]};
  --velora-accent-3: {p["accent3"]};
  --velora-border: {p["border"]};
  --velora-overlay: {p["overlay"]};
  --velora-overlay-end: {p["overlay_end"]};
  --velora-workspace: {p["workspace"]};
  --velora-panel-alpha: {p["panel_alpha"]};
  --velora-editor-alpha: {p["editor_alpha"]};
  --velora-leaf-alpha: {p["leaf_alpha"]};
  --velora-content-alpha-top: {p["content_alpha_top"]};
  --velora-content-alpha-bottom: {p["content_alpha_bottom"]};
  --velora-shadow: {p["shadow"]};
  --velora-highlight: {p["highlight"]};
  --velora-hover: {p["hover"]};

  --background-primary: var(--velora-editor-alpha);
  --background-primary-alt: {rgba(p["main"], 0.68)};
  --background-secondary: var(--velora-panel-alpha);
  --background-secondary-alt: {rgba(p["panel2"], 0.78)};
  --background-modifier-hover: var(--velora-hover);
  --background-modifier-active-hover: var(--velora-highlight);
  --background-modifier-border: {rgba(p["border"], 0.30)};
  --background-modifier-border-hover: {rgba(p["border"], 0.48)};
  --background-modifier-border-focus: var(--velora-accent);
  --background-modifier-form-field: {rgba(p["input"], 0.80)};
  --background-modifier-form-field-highlighted: {rgba(p["input"], 0.92)};
  --background-modifier-success: {rgba(p["green"], 0.20)};
  --background-modifier-error: {rgba(p["red"], 0.20)};
  --background-modifier-error-hover: {rgba(p["red"], 0.26)};
  --text-normal: var(--velora-text);
  --text-muted: var(--velora-muted);
  --text-faint: {rgba(p["muted"], 0.72)};
  --text-accent: var(--velora-accent-3);
  --text-accent-hover: var(--velora-accent-2);
  --text-on-accent: {p["button_text"]};
  --interactive-normal: {rgba(p["card"], 0.74)};
  --interactive-hover: var(--velora-hover);
  --interactive-accent: var(--velora-accent);
  --interactive-accent-hover: var(--velora-accent-2);
  --titlebar-background: {rgba(p["panel"], 0.72)};
  --titlebar-background-focused: {rgba(p["panel2"], 0.82)};
  --tab-container-background: {rgba(p["panel"], 0.48)};
  --tab-outline-color: {rgba(p["border"], 0.22)};
  --ribbon-background: {rgba(p["panel"], 0.62)};
  --nav-item-color: var(--velora-text-soft);
  --nav-item-color-hover: var(--velora-text);
  --nav-item-color-active: var(--velora-text);
  --nav-item-background-hover: var(--velora-hover);
  --nav-item-background-active: var(--velora-highlight);
  --blockquote-border-color: var(--velora-accent-2);
  --link-color: var(--velora-accent-3);
  --link-color-hover: var(--velora-accent-2);
  --link-external-color: var(--velora-accent-2);
  --tag-color: var(--velora-accent-3);
  --tag-background: {rgba(p["accent3"], 0.16)};
  --tag-background-hover: {rgba(p["accent3"], 0.24)};
  --checkbox-color: var(--velora-accent);
  --checkbox-color-hover: var(--velora-accent-2);
  --h1-color: var(--velora-text);
  --h2-color: var(--velora-accent-3);
  --h3-color: var(--velora-accent-2);
  --h4-color: var(--velora-text-soft);
  --h5-color: var(--velora-text-soft);
  --h6-color: var(--velora-muted);
  --graph-line: {rgba(p["border"], 0.30)};
  --graph-node: {rgba(p["text_soft"], 0.92)};
  --graph-node-focused: var(--velora-accent-2);
  --graph-node-tag: var(--velora-accent-3);
  --graph-node-attachment: var(--velora-accent);
  --graph-node-unresolved: {rgba(p["muted"], 0.82)};
}}

body,
.app-container {{
  color: var(--velora-text);
  background:
    radial-gradient(circle at 82% 10%, {rgba(p["accent3"], 0.18)} 0, transparent 28%),
    radial-gradient(circle at 18% 92%, {rgba(p["accent2"], 0.14)} 0, transparent 30%),
    linear-gradient(135deg, var(--velora-overlay), var(--velora-overlay-end)),
    var(--velora-wallpaper-image) center / cover fixed no-repeat !important;
}}

.workspace,
.workspace-split,
.workspace-leaf,
.workspace-leaf-content,
.view-content,
.markdown-source-view,
.markdown-reading-view,
.markdown-preview-view,
.canvas-wrapper,
.graph-view {{
  background: transparent !important;
}}

.workspace {{
  background: var(--velora-workspace) !important;
  backdrop-filter: blur(20px) saturate(1.10);
}}

.workspace-ribbon,
.side-dock-ribbon,
.workspace-sidedock-vault-profile,
.workspace-sidedock-vault-actions,
.mod-left-split,
.mod-right-split {{
  background: var(--velora-panel-alpha) !important;
  border-color: {rgba(p["border"], 0.24)} !important;
  backdrop-filter: blur(24px) saturate(1.12);
}}

.titlebar,
.workspace-tab-header-container,
.workspace-tab-container-before,
.workspace-tab-container-after,
.status-bar {{
  background: {rgba(p["panel"], 0.70)} !important;
  border-color: {rgba(p["border"], 0.22)} !important;
  backdrop-filter: blur(18px) saturate(1.08);
}}

.workspace-leaf-content[data-type="markdown"],
.workspace-leaf-content[data-type="graph"],
.workspace-leaf-content[data-type="canvas"] {{
  background: var(--velora-leaf-alpha) !important;
}}

.markdown-source-view.mod-cm6 .cm-scroller,
.markdown-preview-view,
.graph-view,
.canvas-wrapper {{
  background:
    linear-gradient(180deg, var(--velora-content-alpha-top), var(--velora-content-alpha-bottom)) !important;
}}

.nav-files-container,
.tree-item-children,
.search-result-container,
.backlink-pane,
.outgoing-link-pane,
.tag-container,
.outline {{
  background: transparent !important;
}}

.nav-folder-title,
.nav-file-title,
.tree-item-self,
.search-result-file-title,
.vertical-tab-nav-item,
.suggestion-item {{
  border-radius: 8px;
}}

.nav-folder-title:hover,
.nav-file-title:hover,
.tree-item-self:hover,
.search-result-file-title:hover,
.vertical-tab-nav-item:hover,
.suggestion-item.is-selected {{
  background: var(--velora-hover) !important;
  color: var(--velora-text) !important;
}}

.nav-file-title.is-active,
.tree-item-self.is-active,
.workspace-tab-header.is-active {{
  background: var(--velora-highlight) !important;
  color: var(--velora-text) !important;
  box-shadow: inset 0 0 0 1px {rgba(p["border"], 0.34)};
}}

.workspace-tab-header,
.workspace-tab-header-inner {{
  border-radius: 8px 8px 0 0;
}}

.workspace-tab-header.is-active .workspace-tab-header-inner-title {{
  color: var(--velora-text);
}}

.mod-root .workspace-tab-header.is-active {{
  background: {rgba(p["panel2"], 0.82)} !important;
}}

.modal,
.prompt,
.menu,
.popover,
.suggestion-container,
.notice {{
  background: {rgba(p["panel2"], 0.90)} !important;
  border: 1px solid {rgba(p["border"], 0.34)} !important;
  box-shadow: 0 18px 55px var(--velora-shadow) !important;
  backdrop-filter: blur(24px) saturate(1.14);
}}

input,
textarea,
select,
.search-input-container input,
.prompt-input,
.metadata-property-value,
.cm-search-widget {{
  background: {rgba(p["input"], 0.76)} !important;
  color: var(--velora-text) !important;
  border-color: {rgba(p["border"], 0.30)} !important;
}}

button,
.clickable-icon,
.mod-cta {{
  color: var(--velora-text-soft);
}}

button.mod-cta,
.mod-cta {{
  background: var(--velora-accent) !important;
  color: {p["button_text"]} !important;
}}

.cm-s-obsidian,
.markdown-preview-view {{
  color: var(--velora-text);
}}

.cm-active,
.cm-active.cm-line {{
  background: {rgba(p["accent"], 0.10)} !important;
}}

.cm-selection,
::selection {{
  background: {rgba(p["accent"], 0.32)} !important;
}}

.markdown-rendered blockquote,
.HyperMD-quote {{
  background: {rgba(p["accent2"], 0.10)};
  border-color: var(--velora-accent-2);
}}

.markdown-rendered code,
.cm-inline-code,
pre,
.markdown-rendered pre {{
  background: {rgba(p["input"], 0.74)} !important;
  color: var(--velora-accent-3) !important;
  border: 1px solid {rgba(p["border"], 0.22)};
}}

.graph-view.color-fill,
.graph-view.color-fill-highlight,
.graph-view.color-fill-tag,
.graph-view.color-fill-attachment,
.graph-view.color-arrow {{
  color: var(--velora-accent-3);
}}

.graph-view.color-line {{
  color: {rgba(p["border"], 0.42)};
}}

.graph-view.color-circle {{
  color: var(--velora-text-soft);
}}

.graph-view.color-circle-focused {{
  color: var(--velora-accent-2);
}}

.scrollbar-thumb,
::-webkit-scrollbar-thumb {{
  background: {rgba(p["border"], 0.44)} !important;
  border-radius: 999px;
}}

::-webkit-scrollbar-track {{
  background: transparent !important;
}}
"""


def enable_snippet(vault, p):
    appearance_path = vault / ".obsidian" / "appearance.json"
    data = read_json(appearance_path, {})
    snippets = data.get("enabledCssSnippets")
    if not isinstance(snippets, list):
        snippets = []
    if SNIPPET_NAME not in snippets:
        snippets.append(SNIPPET_NAME)
    data["enabledCssSnippets"] = snippets
    data["baseTheme"] = "dark" if p["dark"] else "light"
    appearance_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def apply_to_vault(vault, theme, wal, quiet=False):
    p = palette_from_theme(theme, wal)
    wallpaper = current_wallpaper(theme, wal)
    wallpaper_url, asset = install_wallpaper_asset(vault, wallpaper)
    snippets_dir = vault / ".obsidian" / "snippets"
    snippets_dir.mkdir(parents=True, exist_ok=True)
    snippet_path = snippets_dir / SNIPPET_FILE
    snippet_path.write_text(build_css(p, wallpaper_url), encoding="utf-8")
    enable_snippet(vault, p)
    return {
        "vault": str(vault),
        "snippet": str(snippet_path),
        "wallpaperAsset": str(asset) if asset else "",
        "mode": p["mode"],
        "accent": p["accent"],
        "accent2": p["accent2"],
        "accent3": p["accent3"],
    }


def main():
    parser = argparse.ArgumentParser(description="Sync Obsidian with Velora pywal16")
    parser.add_argument("--vault", action="append", help="Obsidian vault path; can be passed more than once")
    parser.add_argument("--quiet", action="store_true", help="only print errors")
    args = parser.parse_args()

    try:
        theme = load_pywal_theme()
        wal = read_wal()
        results = [apply_to_vault(vault, theme, wal, quiet=args.quiet) for vault in pick_vaults(args)]
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        STATE_PATH.write_text(json.dumps({"vaults": results}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        if not args.quiet:
            for result in results:
                print(f"obsidian-theme={result['snippet']}")
    except Exception as exc:
        if not args.quiet:
            print(f"velora-obsidian-theme: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
