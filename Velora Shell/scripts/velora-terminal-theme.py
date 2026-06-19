#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
PYWAL_SCRIPT = BASE / "scripts" / "velora-pywal-theme.py"
PYWAL_THEME_PATH = BASE / "themes" / "pywal16.json"
WAL_PATH = Path(os.path.expanduser("~/.cache/wal/colors.json"))
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "velora-shell"
STATE_PATH = STATE_DIR / "terminal-theme.json"
KITTY_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "kitty"
KITTY_CONF = KITTY_DIR / "kitty.conf"
KITTY_THEME = KITTY_DIR / "velora-pywal.conf"

MANAGED_KEYS = {
    "foreground",
    "background",
    "cursor",
    "cursor_text_color",
    "selection_background",
    "selection_foreground",
    "active_tab_foreground",
    "active_tab_background",
    "inactive_tab_foreground",
    "inactive_tab_background",
    "active_border_color",
    "inactive_border_color",
    "bell_border_color",
}


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def hex_to_rgb(value):
    value = str(value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("invalid hex color")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*(clamp(v) for v in rgb))


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


def lighten(color, amount):
    return rgb_to_hex(mix(hex_to_rgb(color), (255, 255, 255), amount))


def darken(color, amount):
    return rgb_to_hex(mix(hex_to_rgb(color), (0, 0, 0), amount))


def luminance(color):
    def channel(value):
        value = value / 255
        return value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in hex_to_rgb(color))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def text_on(color):
    return "#ffffff" if luminance(color) < 0.42 else "#202124"


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
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


def palette_from_theme(theme, wal):
    colors = wal.get("colors", {}) if isinstance(wal, dict) else {}
    special = wal.get("special", {}) if isinstance(wal, dict) else {}
    mode = str(theme.get("themeMode") or "dark")
    dark = mode == "dark"
    wal_bg = str(special.get("background") or colors.get("color0") or ("#101010" if dark else "#f7f7f7"))
    wal_fg = str(special.get("foreground") or colors.get("color7") or ("#f2edf7" if dark else "#202124"))

    background = rgba_to_hex(
        theme.get("surfaceCard") or theme.get("surfaceBase"),
        darken(wal_bg, 0.04) if dark else lighten(wal_bg, 0.20),
    )
    foreground = rgba_to_hex(theme.get("textPrimary"), wal_fg)
    secondary = rgba_to_hex(theme.get("textSecondary"), lighten(foreground, 0.28) if dark else darken(foreground, 0.18))
    accent = rgba_to_hex(theme.get("accentPrimary"), str(colors.get("color4") or "#8da3ff"))
    accent2 = rgba_to_hex(theme.get("accentSecondary"), str(colors.get("color5") or accent))

    ansi = {
        "color0": darken(background, 0.68) if not dark else darken(background, 0.30),
        "color1": str(colors.get("color1") or "#d93025"),
        "color2": str(colors.get("color2") or "#188038"),
        "color3": str(colors.get("color3") or "#b06000"),
        "color4": str(colors.get("color4") or accent),
        "color5": str(colors.get("color5") or accent2),
        "color6": str(colors.get("color6") or "#007b83"),
        "color7": lighten(background, 0.60) if dark else darken(background, 0.05),
    }
    ansi.update({
        "color8": lighten(ansi["color0"], 0.32),
        "color9": lighten(ansi["color1"], 0.16),
        "color10": lighten(ansi["color2"], 0.16),
        "color11": lighten(ansi["color3"], 0.16),
        "color12": lighten(ansi["color4"], 0.16),
        "color13": lighten(ansi["color5"], 0.16),
        "color14": lighten(ansi["color6"], 0.16),
        "color15": "#ffffff" if not dark else lighten(foreground, 0.12),
    })

    selection = lighten(accent, 0.44) if luminance(accent) < 0.52 else darken(accent, 0.18)
    return {
        "mode": mode,
        "wallpaper": theme.get("wallpaper") or wal.get("wallpaper", ""),
        "checksum": theme.get("checksum") or wal.get("checksum", ""),
        "background": background,
        "foreground": foreground,
        "secondary": secondary,
        "accent": accent,
        "selection": selection,
        "selection_text": text_on(selection),
        **ansi,
    }


def generate_kitty_theme(palette):
    lines = [
        "# Generated by Velora Shell from pywal16.",
        "# This file intentionally does not set background_opacity.",
        f"# wallpaper {palette['wallpaper']}",
        f"foreground {palette['foreground']}",
        f"background {palette['background']}",
        f"cursor {palette['foreground']}",
        f"cursor_text_color {palette['background']}",
        f"selection_background {palette['selection']}",
        f"selection_foreground {palette['selection_text']}",
        "",
        f"active_tab_foreground {palette['background']}",
        f"active_tab_background {palette['accent']}",
        f"inactive_tab_foreground {palette['secondary']}",
        f"inactive_tab_background {palette['background']}",
        f"active_border_color {palette['accent']}",
        f"inactive_border_color {palette['background']}",
        f"bell_border_color {palette['accent']}",
        "",
    ]
    for index in range(16):
        lines.append(f"color{index} {palette[f'color{index}']}")
    return "\n".join(lines) + "\n"


def is_managed_color_line(line):
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return False
    key = re.split(r"\s+", stripped, maxsplit=1)[0]
    return key in MANAGED_KEYS or re.fullmatch(r"color(?:[0-9]|1[0-5])", key or "") is not None


def ensure_kitty_include():
    KITTY_DIR.mkdir(parents=True, exist_ok=True)
    lines = KITTY_CONF.read_text(encoding="utf-8").splitlines() if KITTY_CONF.exists() else []
    output = []
    include_seen = False
    inserted = False

    for line in lines:
        stripped = line.strip()
        if stripped == "include velora-pywal.conf":
            if not include_seen:
                output.append(line)
                include_seen = True
                inserted = True
            continue
        if is_managed_color_line(line):
            continue
        output.append(line)
        if stripped.startswith("background_opacity") and not include_seen and not inserted:
            output.append("include velora-pywal.conf")
            include_seen = True
            inserted = True

    if not include_seen:
        if output and output[-1].strip():
            output.append("")
        output.insert(0, "include velora-pywal.conf")

    KITTY_CONF.write_text("\n".join(output).rstrip() + "\n", encoding="utf-8")


def sync_terminal_theme():
    theme = load_pywal_theme()
    wal = read_json(WAL_PATH)
    palette = palette_from_theme(theme, wal)
    KITTY_DIR.mkdir(parents=True, exist_ok=True)
    KITTY_THEME.write_text(generate_kitty_theme(palette), encoding="utf-8")
    ensure_kitty_include()
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps({
        "terminal": "kitty",
        "themeFile": str(KITTY_THEME),
        "configFile": str(KITTY_CONF),
        "wallpaper": palette["wallpaper"],
        "checksum": palette["checksum"],
        "opacityManaged": False,
    }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return palette


def main():
    parser = argparse.ArgumentParser(description="Sync Kitty terminal colors with Velora pywal16 without changing opacity.")
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()

    try:
        palette = sync_terminal_theme()
    except Exception as exc:
        print(f"velora-terminal-theme: {exc}", file=sys.stderr)
        return 1

    if not args.quiet:
        print(f"terminal-theme=kitty background={palette['background']} foreground={palette['foreground']} opacity=preserved")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
