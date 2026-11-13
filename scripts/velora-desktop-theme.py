#!/usr/bin/env python3
import argparse
import configparser
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
PYWAL_SCRIPT = BASE / "scripts" / "velora-pywal-theme.py"
PYWAL_THEME_PATH = BASE / "themes" / "pywal16.json"
WAL_PATH = Path(os.path.expanduser("~/.cache/wal/colors.json"))
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "velora-shell"
STATE_PATH = STATE_DIR / "desktop-theme.json"
CURSOR_THEME = "VeloraPywalCursor"
GTK_THEME = "VeloraPywal16"
KDE_SCHEME = "VeloraPywal16"
CURSOR_SIZE = 24
GTK_GLOBAL_FALLBACKS = ("Default", "Adwaita-dark", "Adwaita", "Breeze")
THUNAR_WRAPPER = Path.home() / ".local/bin/velora-thunar"
THUNAR_DESKTOP = Path.home() / ".local/share/applications/thunar.desktop"


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
    return f"#{r:02x}{g:02x}{b:02x}{clamp(opacity * 255):02x}"


def text_on(color):
    return "#ffffff" if luminance(hex_to_rgb(color)) < 0.42 else "#30283a"


def kde_rgb(color):
    return ",".join(str(clamp(v)) for v in hex_to_rgb(color))


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
        window = darken(bg, 0.14)
        view = darken(bg, 0.20)
        panel = darken(sidebar, 0.08)
        toolbar = darken(popup, 0.06)
        button = darken(card, 0.08)
        input_bg = darken(input_bg, 0.06)
        selection = alpha(accent, 0.36)
        hover = alpha(accent, 0.18)
        border_soft = lighten(window, 0.12)
    else:
        window = lighten(bg, 0.26)
        view = lighten(bg, 0.34)
        panel = lighten(sidebar, 0.12)
        toolbar = lighten(popup, 0.10)
        button = lighten(card, 0.04)
        input_bg = lighten(input_bg, 0.08)
        selection = alpha(accent, 0.28)
        hover = alpha(accent, 0.14)
        border_soft = darken(window, 0.08)

    return {
        "mode": mode,
        "dark": dark,
        "wallpaper": theme.get("wallpaper") or wal.get("wallpaper", ""),
        "checksum": theme.get("checksum") or wal.get("checksum", ""),
        "window": window,
        "view": view,
        "panel": panel,
        "toolbar": toolbar,
        "card": button,
        "input": input_bg,
        "text": text,
        "text_soft": text_soft,
        "muted": muted,
        "accent": accent,
        "accent2": accent2,
        "accent3": accent3,
        "border": border,
        "border_soft": border_soft,
        "selection": selection,
        "hover": hover,
        "button_text": text_on(accent),
        "red": str(colors.get("color1") or "#f38ba8"),
        "green": str(colors.get("color2") or "#a6e3a1"),
        "yellow": str(colors.get("color3") or "#f9e2af"),
        "blue": str(colors.get("color4") or accent3),
        "magenta": str(colors.get("color5") or accent2),
        "cyan": str(colors.get("color6") or accent3),
    }


def run(cmd, quiet=False, timeout=2.0):
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL if quiet else subprocess.PIPE,
            stderr=subprocess.DEVNULL if quiet else subprocess.PIPE,
            text=True,
            timeout=timeout,
            check=False,
        )
        return result.returncode == 0
    except Exception:
        return False


def xfconf_set(path, value, value_type="string"):
    value = str(value)
    if run(["xfconf-query", "-c", "xsettings", "-p", path, "-s", value], quiet=True):
        return True
    return run(["xfconf-query", "-c", "xsettings", "-p", path, "--create", "-t", value_type, "-s", value], quiet=True)


def backup_once(path):
    if not path.exists():
        return
    backup = path.with_name(f"{path.name}.velora-bak")
    if backup.exists():
        return
    try:
        shutil.copy2(path, backup)
    except Exception:
        pass


def update_ini_settings(path, section, values):
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    out = []
    in_section = False
    seen_section = False
    written = set()

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if in_section:
                for key, value in values.items():
                    if key not in written:
                        out.append(f"{key}={value}")
                        written.add(key)
            current = stripped[1:-1]
            in_section = current == section
            seen_section = seen_section or in_section
            out.append(line)
            continue

        if in_section and "=" in line and not stripped.startswith(("#", ";")):
            key = line.split("=", 1)[0].strip()
            if key in values:
                if values[key] is not None:
                    out.append(f"{key}={values[key]}")
                written.add(key)
                continue

        out.append(line)

    if not seen_section:
        if out and out[-1].strip():
            out.append("")
        out.append(f"[{section}]")
        in_section = True

    if in_section or not lines:
        for key, value in values.items():
            if key not in written and value is not None:
                out.append(f"{key}={value}")

    backup_once(path)
    path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")


def write_cursor_svg(path, kind, p):
    accent = p["accent"]
    accent2 = p["accent2"]
    accent3 = p["accent3"]
    outline = "#ffffff" if p["dark"] else darken(p["text"], 0.08)
    shadow = "#00000044" if p["dark"] else "#8f789833"
    fill = accent

    if kind == "hand":
        body = f"""
<path d="M8 21 C6.8 18.7 6 16.9 5.3 14.7 L4.5 12.3 C4.1 11 4.8 10.1 5.8 10.1 C6.4 10.1 6.9 10.5 7.2 11.1 L7.8 12.4 V5.6 C7.8 4.6 8.5 4 9.4 4 C10.2 4 10.8 4.6 10.8 5.6 V11.1 L11.5 8.7 C11.8 7.9 12.4 7.5 13.1 7.6 C13.8 7.8 14.2 8.4 14.1 9.2 L13.8 11.4 L14.9 9.7 C15.4 9 16.1 8.9 16.7 9.3 C17.3 9.7 17.5 10.5 17.1 11.2 L16.1 13.2 L17.4 12.2 C18.1 11.7 18.9 11.9 19.3 12.5 C19.7 13.1 19.6 13.8 19.1 14.4 L15.9 18.4 C14.7 19.9 13.1 21 10.7 21 Z" fill="{fill}" stroke="{outline}" stroke-width="1.25" stroke-linejoin="round"/>
"""
    elif kind == "ibeam":
        body = f"""
<path d="M8 4 H16 M8 20 H16 M12 4 V20" fill="none" stroke="{outline}" stroke-width="4" stroke-linecap="round"/>
<path d="M8 4 H16 M8 20 H16 M12 4 V20" fill="none" stroke="{accent}" stroke-width="2" stroke-linecap="round"/>
"""
    elif kind == "wait":
        body = f"""
<circle cx="12" cy="12" r="7.2" fill="none" stroke="{outline}" stroke-width="3.2" opacity="0.72"/>
<path d="M12 4.8 A7.2 7.2 0 0 1 19.2 12" fill="none" stroke="{accent}" stroke-width="3.2" stroke-linecap="round"/>
<circle cx="12" cy="12" r="2.1" fill="{accent2}"/>
"""
    elif kind == "cross":
        body = f"""
<path d="M12 3 V21 M3 12 H21" fill="none" stroke="{outline}" stroke-width="4" stroke-linecap="round"/>
<path d="M12 4.5 V19.5 M4.5 12 H19.5" fill="none" stroke="{accent}" stroke-width="2" stroke-linecap="round"/>
"""
    elif kind == "move":
        body = f"""
<path d="M12 3 L8.7 6.3 H11 V11 H6.3 V8.7 L3 12 L6.3 15.3 V13 H11 V17.7 H8.7 L12 21 L15.3 17.7 H13 V13 H17.7 V15.3 L21 12 L17.7 8.7 V11 H13 V6.3 H15.3 Z" fill="{fill}" stroke="{outline}" stroke-width="1.2" stroke-linejoin="round"/>
"""
    elif kind == "resize-ew":
        body = f"""
<path d="M3 12 L8 7 V10 H16 V7 L21 12 L16 17 V14 H8 V17 Z" fill="{fill}" stroke="{outline}" stroke-width="1.2" stroke-linejoin="round"/>
"""
    elif kind == "resize-ns":
        body = f"""
<path d="M12 3 L17 8 H14 V16 H17 L12 21 L7 16 H10 V8 H7 Z" fill="{fill}" stroke="{outline}" stroke-width="1.2" stroke-linejoin="round"/>
"""
    elif kind == "resize-nesw":
        body = f"""
<path d="M18.5 4.5 V11 H16.1 V8.6 L8.6 16.1 H11 V18.5 H4.5 V12 H6.9 V14.4 L14.4 6.9 H12 V4.5 Z" fill="{fill}" stroke="{outline}" stroke-width="1.1" stroke-linejoin="round"/>
"""
    elif kind == "resize-nwse":
        body = f"""
<path d="M5.5 4.5 H12 V6.9 H9.6 L17.1 14.4 V12 H19.5 V18.5 H13 V16.1 H15.4 L7.9 8.6 V11 H5.5 Z" fill="{fill}" stroke="{outline}" stroke-width="1.1" stroke-linejoin="round"/>
"""
    elif kind == "not-allowed":
        body = f"""
<circle cx="12" cy="12" r="8" fill="none" stroke="{outline}" stroke-width="4"/>
<circle cx="12" cy="12" r="8" fill="none" stroke="{accent}" stroke-width="2.5"/>
<path d="M6.8 17.2 L17.2 6.8" stroke="{accent2}" stroke-width="3" stroke-linecap="round"/>
"""
    elif kind == "zoom":
        body = f"""
<circle cx="10" cy="10" r="6" fill="{accent3}" fill-opacity="0.42" stroke="{outline}" stroke-width="3"/>
<circle cx="10" cy="10" r="6" fill="none" stroke="{accent}" stroke-width="1.8"/>
<path d="M15 15 L21 21" stroke="{outline}" stroke-width="4" stroke-linecap="round"/>
<path d="M15 15 L21 21" stroke="{accent}" stroke-width="2.2" stroke-linecap="round"/>
<path d="M10 7 V13 M7 10 H13" stroke="{outline}" stroke-width="1.8" stroke-linecap="round"/>
"""
    elif kind == "copy":
        body = f"""
<rect x="7" y="6" width="10" height="12" rx="2.2" fill="{accent2}" stroke="{outline}" stroke-width="1.2"/>
<rect x="4" y="3" width="10" height="12" rx="2.2" fill="{accent}" stroke="{outline}" stroke-width="1.2"/>
"""
    else:
        body = f"""
<path d="M5 2.5 L5 20.5 L10 15.5 L13.1 22 L16 20.6 L12.9 14.4 H20 Z" fill="{fill}" stroke="{outline}" stroke-width="1.25" stroke-linejoin="round"/>
<path d="M7 6.2 V15.7 L9.9 12.9 L12.7 18.6" fill="none" stroke="{accent3}" stroke-width="1.1" stroke-linecap="round" opacity="0.95"/>
"""

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
<path d="M5 3 L20 14" stroke="{shadow}" stroke-width="4.6" stroke-linecap="round" opacity="0.45"/>
{body.strip()}
</svg>
"""
    path.write_text(svg, encoding="utf-8")


CURSOR_SHAPES = {
    "left_ptr": ("arrow", 4, 2),
    "default": ("arrow", 4, 2),
    "arrow": ("arrow", 4, 2),
    "top_left_arrow": ("arrow", 4, 2),
    "pointer": ("hand", 8, 3),
    "hand1": ("hand", 8, 3),
    "hand2": ("hand", 8, 3),
    "text": ("ibeam", 12, 12),
    "xterm": ("ibeam", 12, 12),
    "vertical-text": ("ibeam", 12, 12),
    "wait": ("wait", 12, 12),
    "watch": ("wait", 12, 12),
    "progress": ("wait", 12, 12),
    "crosshair": ("cross", 12, 12),
    "cross": ("cross", 12, 12),
    "tcross": ("cross", 12, 12),
    "cell": ("cross", 12, 12),
    "move": ("move", 12, 12),
    "all-scroll": ("move", 12, 12),
    "all-resize": ("move", 12, 12),
    "fleur": ("move", 12, 12),
    "grab": ("hand", 8, 3),
    "grabbing": ("hand", 8, 3),
    "dnd-move": ("move", 12, 12),
    "e-resize": ("resize-ew", 12, 12),
    "w-resize": ("resize-ew", 12, 12),
    "ew-resize": ("resize-ew", 12, 12),
    "col-resize": ("resize-ew", 12, 12),
    "sb_h_double_arrow": ("resize-ew", 12, 12),
    "left_side": ("resize-ew", 12, 12),
    "right_side": ("resize-ew", 12, 12),
    "n-resize": ("resize-ns", 12, 12),
    "s-resize": ("resize-ns", 12, 12),
    "ns-resize": ("resize-ns", 12, 12),
    "row-resize": ("resize-ns", 12, 12),
    "sb_v_double_arrow": ("resize-ns", 12, 12),
    "top_side": ("resize-ns", 12, 12),
    "bottom_side": ("resize-ns", 12, 12),
    "ne-resize": ("resize-nesw", 12, 12),
    "sw-resize": ("resize-nesw", 12, 12),
    "nesw-resize": ("resize-nesw", 12, 12),
    "top_right_corner": ("resize-nesw", 12, 12),
    "bottom_left_corner": ("resize-nesw", 12, 12),
    "fd_double_arrow": ("resize-nesw", 12, 12),
    "nw-resize": ("resize-nwse", 12, 12),
    "se-resize": ("resize-nwse", 12, 12),
    "nwse-resize": ("resize-nwse", 12, 12),
    "top_left_corner": ("resize-nwse", 12, 12),
    "bottom_right_corner": ("resize-nwse", 12, 12),
    "bd_double_arrow": ("resize-nwse", 12, 12),
    "not-allowed": ("not-allowed", 12, 12),
    "no-drop": ("not-allowed", 12, 12),
    "copy": ("copy", 9, 7),
    "alias": ("copy", 9, 7),
    "context-menu": ("arrow", 4, 2),
    "help": ("arrow", 4, 2),
    "question_arrow": ("arrow", 4, 2),
    "zoom-in": ("zoom", 10, 10),
    "zoom-out": ("zoom", 10, 10),
}


def install_hyprcursor_theme(p, quiet=False):
    target = Path.home() / ".local/share/icons" / CURSOR_THEME
    target.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="velora-cursor-") as tmp_name:
        tmp = Path(tmp_name)
        source = tmp / "source"
        cursors = source / "cursors"
        cursors.mkdir(parents=True)
        (source / "manifest.hl").write_text(
            "\n".join([
                f"name = {CURSOR_THEME}",
                "description = Velora pywal16 cursor theme",
                "version = 1.0",
                "cursors_directory = cursors",
                "",
            ]),
            encoding="utf-8",
        )

        for shape, (kind, hotspot_x, hotspot_y) in CURSOR_SHAPES.items():
            shape_dir = cursors / shape
            shape_dir.mkdir()
            svg_name = f"{shape}.svg"
            write_cursor_svg(shape_dir / svg_name, kind, p)
            normalized_hotspot_x = max(0, min(1, hotspot_x / CURSOR_SIZE))
            normalized_hotspot_y = max(0, min(1, hotspot_y / CURSOR_SIZE))
            (shape_dir / "meta.hl").write_text(
                "\n".join([
                    f"hotspot_x = {normalized_hotspot_x:.4f}",
                    f"hotspot_y = {normalized_hotspot_y:.4f}",
                    "resize_algorithm = bilinear",
                    f"define_size = {CURSOR_SIZE}, {svg_name}, 200",
                    "",
                ]),
                encoding="utf-8",
            )

        generated = tmp / f"theme_{CURSOR_THEME}"
        if shutil.which("hyprcursor-util"):
            result = subprocess.run(
                ["hyprcursor-util", "--create", str(source)],
                cwd=str(tmp),
                stdout=subprocess.DEVNULL if quiet else subprocess.PIPE,
                stderr=subprocess.DEVNULL if quiet else subprocess.PIPE,
                text=True,
                timeout=5.0,
                check=False,
            )
            if result.returncode != 0 or not generated.exists():
                raise RuntimeError("hyprcursor-util failed to create the cursor theme")

            tmp_target = target.with_name(f".{target.name}.tmp")
            shutil.rmtree(tmp_target, ignore_errors=True)
            shutil.copytree(generated, tmp_target)
            shutil.rmtree(target, ignore_errors=True)
            tmp_target.rename(target)
        else:
            target.mkdir(parents=True, exist_ok=True)

    (target / "index.theme").write_text(
        "\n".join([
            "[Icon Theme]",
            "Name=VeloraPywalCursor",
            "Comment=Velora pywal16 cursor theme with Adwaita Xcursor fallback",
            "Inherits=Adwaita",
            "",
        ]),
        encoding="utf-8",
    )
    return target


def apply_cursor(p, quiet=False):
    target = install_hyprcursor_theme(p, quiet=quiet)

    for default_dir in (Path.home() / ".icons/default", Path.home() / ".local/share/icons/default"):
        default_dir.mkdir(parents=True, exist_ok=True)
        default_index = default_dir / "index.theme"
        backup_once(default_index)
        default_index.write_text(
            "\n".join([
                "[Icon Theme]",
                "Name=Default",
                f"Inherits={CURSOR_THEME}",
                "",
            ]),
            encoding="utf-8",
        )

    for path in (Path.home() / ".config/gtk-3.0/settings.ini", Path.home() / ".config/gtk-4.0/settings.ini"):
        update_ini_settings(path, "Settings", {
            "gtk-cursor-theme-name": CURSOR_THEME,
            "gtk-cursor-theme-size": str(CURSOR_SIZE),
        })

    run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", CURSOR_THEME], quiet=True)
    run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", str(CURSOR_SIZE)], quiet=True)
    xfconf_set("/Gtk/CursorThemeName", CURSOR_THEME)
    xfconf_set("/Gtk/CursorThemeSize", CURSOR_SIZE, "int")
    run(["hyprctl", "setcursor", CURSOR_THEME, str(CURSOR_SIZE)], quiet=True)
    return target


def build_kde_colors(p):
    selection_bg = rgba_to_hex(p["selection"], p["accent"])
    hover_bg = rgba_to_hex(p["hover"], p["accent"])
    inactive = p["muted"]
    neutral = p["border_soft"]
    positive = p["green"]
    negative = p["red"]
    neutral_text = p["text"]

    sections = {
        "General": {
            "Name": KDE_SCHEME,
            "ColorScheme": KDE_SCHEME,
            "shadeSortColumn": "true",
        },
        "Colors:Window": {
            "BackgroundNormal": kde_rgb(p["window"]),
            "BackgroundAlternate": kde_rgb(p["panel"]),
            "ForegroundNormal": kde_rgb(p["text"]),
            "ForegroundInactive": kde_rgb(inactive),
            "ForegroundLink": kde_rgb(p["accent3"]),
            "ForegroundVisited": kde_rgb(p["accent2"]),
            "ForegroundNegative": kde_rgb(negative),
            "ForegroundNeutral": kde_rgb(neutral_text),
            "ForegroundPositive": kde_rgb(positive),
        },
        "Colors:View": {
            "BackgroundNormal": kde_rgb(p["view"]),
            "BackgroundAlternate": kde_rgb(p["panel"]),
            "DecorationFocus": kde_rgb(p["accent"]),
            "DecorationHover": kde_rgb(hover_bg),
            "ForegroundNormal": kde_rgb(p["text"]),
            "ForegroundInactive": kde_rgb(inactive),
            "ForegroundLink": kde_rgb(p["accent3"]),
            "ForegroundVisited": kde_rgb(p["accent2"]),
            "ForegroundNegative": kde_rgb(negative),
            "ForegroundNeutral": kde_rgb(neutral_text),
            "ForegroundPositive": kde_rgb(positive),
        },
        "Colors:Button": {
            "BackgroundNormal": kde_rgb(p["card"]),
            "BackgroundAlternate": kde_rgb(p["panel"]),
            "DecorationFocus": kde_rgb(p["accent"]),
            "DecorationHover": kde_rgb(hover_bg),
            "ForegroundNormal": kde_rgb(p["text"]),
            "ForegroundInactive": kde_rgb(inactive),
            "ForegroundLink": kde_rgb(p["accent3"]),
            "ForegroundVisited": kde_rgb(p["accent2"]),
            "ForegroundNegative": kde_rgb(negative),
            "ForegroundNeutral": kde_rgb(neutral_text),
            "ForegroundPositive": kde_rgb(positive),
        },
        "Colors:Selection": {
            "BackgroundNormal": kde_rgb(selection_bg),
            "BackgroundAlternate": kde_rgb(hover_bg),
            "DecorationFocus": kde_rgb(p["accent"]),
            "DecorationHover": kde_rgb(p["accent2"]),
            "ForegroundNormal": kde_rgb(p["button_text"]),
            "ForegroundInactive": kde_rgb(p["button_text"]),
            "ForegroundLink": kde_rgb(p["button_text"]),
            "ForegroundVisited": kde_rgb(p["button_text"]),
            "ForegroundNegative": kde_rgb(p["button_text"]),
            "ForegroundNeutral": kde_rgb(p["button_text"]),
            "ForegroundPositive": kde_rgb(p["button_text"]),
        },
        "Colors:Tooltip": {
            "BackgroundNormal": kde_rgb(p["toolbar"]),
            "ForegroundNormal": kde_rgb(p["text"]),
            "ForegroundInactive": kde_rgb(inactive),
            "ForegroundLink": kde_rgb(p["accent3"]),
            "ForegroundVisited": kde_rgb(p["accent2"]),
        },
        "WM": {
            "activeBackground": kde_rgb(p["toolbar"]),
            "activeBlend": kde_rgb(p["accent"]),
            "activeForeground": kde_rgb(p["text"]),
            "inactiveBackground": kde_rgb(p["panel"]),
            "inactiveBlend": kde_rgb(neutral),
            "inactiveForeground": kde_rgb(inactive),
        },
    }
    return sections


def apply_dolphin(p, quiet=False):
    scheme_dir = Path.home() / ".local/share/color-schemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    scheme_path = scheme_dir / f"{KDE_SCHEME}.colors"
    sections = build_kde_colors(p)
    lines = ["# Generated by Velora Shell from pywal16."]
    for section, values in sections.items():
        lines.append(f"[{section}]")
        for key, value in values.items():
            lines.append(f"{key}={value}")
        lines.append("")
    scheme_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

    backup_once(Path.home() / ".config/kdeglobals")
    if shutil.which("kwriteconfig6"):
        run(["kwriteconfig6", "--file", "kdeglobals", "--group", "General", "--key", "ColorScheme", KDE_SCHEME], quiet=True)
        run(["kwriteconfig6", "--file", "kdeglobals", "--group", "General", "--key", "Name", KDE_SCHEME], quiet=True)
    else:
        update_ini_settings(Path.home() / ".config/kdeglobals", "General", {
            "ColorScheme": KDE_SCHEME,
            "Name": KDE_SCHEME,
        })

    run(["qdbus6", "org.kde.KWin", "/KWin", "reconfigure"], quiet=True)
    return scheme_path


def gtk_css(p):
    return f"""/* Generated by Velora Shell from pywal16. */
@define-color accent_color {p["accent"]};
@define-color accent_bg_color {p["accent"]};
@define-color accent_fg_color {p["button_text"]};
@define-color destructive_color {p["red"]};
@define-color success_color {p["green"]};
@define-color warning_color {p["yellow"]};
@define-color window_bg_color {p["window"]};
@define-color window_fg_color {p["text"]};
@define-color view_bg_color {p["view"]};
@define-color view_fg_color {p["text"]};
@define-color headerbar_bg_color {p["toolbar"]};
@define-color headerbar_fg_color {p["text"]};
@define-color card_bg_color {p["card"]};
@define-color sidebar_bg_color {p["panel"]};
@define-color borders {p["border_soft"]};
@define-color insensitive_fg_color {p["muted"]};
@define-color theme_bg_color {p["window"]};
@define-color theme_fg_color {p["text"]};
@define-color theme_base_color {p["view"]};
@define-color theme_text_color {p["text"]};
@define-color theme_selected_bg_color {p["selection"]};
@define-color theme_selected_fg_color {p["text"]};

* {{
  outline-color: alpha(@accent_color, 0.58);
  -gtk-icon-shadow: none;
}}

window,
dialog,
.background {{
  background-color: @window_bg_color;
  color: @window_fg_color;
}}

label,
cell,
text,
window label,
row label,
treeview.view {{
  color: @window_fg_color;
}}

headerbar,
toolbar,
menubar,
.toolbar {{
  background: @headerbar_bg_color;
  color: @headerbar_fg_color;
  border-color: alpha(@borders, 0.55);
}}

.sidebar,
placessidebar,
placessidebar list,
window.thunar .sidebar {{
  background: @sidebar_bg_color;
  color: @window_fg_color;
}}

treeview.view,
iconview,
list,
.view,
textview text,
window.thunar treeview.view,
window.thunar .view {{
  background-color: @view_bg_color;
  color: @view_fg_color;
}}

entry,
spinbutton,
searchentry {{
  background: alpha(@card_bg_color, 0.86);
  color: @window_fg_color;
  border: 1px solid alpha(@borders, 0.72);
  border-radius: 8px;
  caret-color: @accent_color;
}}

button {{
  background-image: none;
  background-color: alpha(@card_bg_color, 0.78);
  color: @window_fg_color;
  border: 1px solid alpha(@borders, 0.68);
  border-radius: 8px;
  padding: 5px 9px;
}}

button:hover,
row:hover,
treeview.view:hover,
iconview:hover {{
  background-color: alpha(@accent_bg_color, 0.14);
}}

button:checked,
button:active,
row:selected,
treeview.view:selected,
iconview:selected,
.view:selected {{
  background-color: alpha(@accent_bg_color, 0.28);
  color: @window_fg_color;
}}

row:selected label,
treeview.view:selected,
iconview:selected,
.view:selected label {{
  color: @window_fg_color;
}}

scrollbar slider {{
  background-color: alpha(@accent_bg_color, 0.48);
  border-radius: 999px;
  min-width: 6px;
  min-height: 6px;
}}

separator,
.separator {{
  background-color: alpha(@borders, 0.46);
}}

tooltip {{
  background-color: @headerbar_bg_color;
  color: @window_fg_color;
  border: 1px solid alpha(@borders, 0.75);
}}
"""


def theme_exists(name):
    if not name:
        return False
    for root in (Path.home() / ".local/share/themes", Path.home() / ".themes", Path("/usr/share/themes")):
        if (root / name).is_dir():
            return True
    return False


def select_global_gtk_theme():
    configured = os.environ.get("VELORA_GTK_GLOBAL_THEME", "").strip()
    if configured and configured != GTK_THEME and theme_exists(configured):
        return configured
    for name in GTK_GLOBAL_FALLBACKS:
        if theme_exists(name):
            return name
    return None


def write_thunar_launcher():
    THUNAR_WRAPPER.parent.mkdir(parents=True, exist_ok=True)
    THUNAR_WRAPPER.write_text(
        "\n".join([
            "#!/usr/bin/env bash",
            f"export GTK_THEME={GTK_THEME}",
            'exec thunar "$@"',
            "",
        ]),
        encoding="utf-8",
    )
    THUNAR_WRAPPER.chmod(0o755)

    src = Path("/usr/share/applications/thunar.desktop")
    THUNAR_DESKTOP.parent.mkdir(parents=True, exist_ok=True)
    if src.exists():
        lines = []
        for line in src.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("Exec=thunar"):
                args = line[len("Exec=thunar"):].strip()
                line = f"Exec={THUNAR_WRAPPER}" + (f" {args}" if args else "")
            lines.append(line)
        THUNAR_DESKTOP.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    else:
        THUNAR_DESKTOP.write_text(
            "\n".join([
                "[Desktop Entry]",
                "Type=Application",
                "Name=Thunar File Manager",
                f"Exec={THUNAR_WRAPPER} %U",
                "Icon=org.xfce.thunar",
                "Categories=System;FileTools;FileManager;",
                "MimeType=inode/directory;",
                "",
            ]),
            encoding="utf-8",
        )

    run(["update-desktop-database", str(THUNAR_DESKTOP.parent)], quiet=True, timeout=3.0)
    return THUNAR_DESKTOP


def apply_thunar(p, quiet=False):
    theme_root = Path.home() / ".local/share/themes" / GTK_THEME
    for version in ("gtk-3.0", "gtk-4.0"):
        theme_dir = theme_root / version
        theme_dir.mkdir(parents=True, exist_ok=True)
        (theme_dir / "gtk.css").write_text(gtk_css(p), encoding="utf-8")

    (theme_root / "index.theme").write_text(
        "\n".join([
            "[Desktop Entry]",
            f"Name={GTK_THEME}",
            "Type=X-GNOME-Metatheme",
            "Comment=Velora Shell pywal16 GTK theme",
            "",
            "[X-GNOME-Metatheme]",
            f"GtkTheme={GTK_THEME}",
            "IconTheme=breeze",
            f"CursorTheme={CURSOR_THEME}",
            "",
        ]),
        encoding="utf-8",
    )

    prefer_dark = "1" if p["dark"] else "0"
    global_theme = select_global_gtk_theme()
    gtk_settings = {
        "gtk-theme-name": global_theme,
        "gtk-application-prefer-dark-theme": prefer_dark,
        "gtk-cursor-theme-name": CURSOR_THEME,
        "gtk-cursor-theme-size": str(CURSOR_SIZE),
    }
    for path in (Path.home() / ".config/gtk-3.0/settings.ini", Path.home() / ".config/gtk-4.0/settings.ini"):
        update_ini_settings(path, "Settings", gtk_settings)

    if global_theme:
        run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", global_theme], quiet=True)
        xfconf_set("/Net/ThemeName", global_theme)
    run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark" if p["dark"] else "default"], quiet=True)
    write_thunar_launcher()
    return theme_root


def write_state(p, results):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps({
        "checksum": p.get("checksum", ""),
        "wallpaper": p.get("wallpaper", ""),
        "mode": p.get("mode", ""),
        "cursorTheme": CURSOR_THEME,
        "gtkTheme": GTK_THEME,
        "gtkGlobalTheme": select_global_gtk_theme(),
        "thunarDesktop": str(THUNAR_DESKTOP),
        "thunarWrapper": str(THUNAR_WRAPPER),
        "kdeScheme": KDE_SCHEME,
        "results": {name: str(path) for name, path in results.items()},
    }, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Sync desktop apps and cursor with Velora pywal16.")
    parser.add_argument("targets", nargs="*", choices=["all", "cursor", "dolphin", "thunar"], help="targets to sync; default is all")
    parser.add_argument("--quiet", action="store_true", help="only report fatal errors")
    parser.add_argument("--status", action="store_true", help="print the last sync state")
    args = parser.parse_args()

    if args.status:
        if STATE_PATH.exists():
            print(STATE_PATH.read_text(encoding="utf-8").strip())
        else:
            print("missing")
        return 0

    targets = set(args.targets or ["all"])
    if "all" in targets:
        targets = {"cursor", "dolphin", "thunar"}

    theme = load_pywal_theme()
    wal = read_wal()
    palette = palette_from_theme(theme, wal)
    results = {}

    if "cursor" in targets:
        results["cursor"] = apply_cursor(palette, quiet=args.quiet)
    if "dolphin" in targets:
        results["dolphin"] = apply_dolphin(palette, quiet=args.quiet)
    if "thunar" in targets:
        results["thunar"] = apply_thunar(palette, quiet=args.quiet)

    write_state(palette, results)

    if not args.quiet:
        for name, path in results.items():
            print(f"{name}: {path}")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"velora-desktop-theme: {exc}", file=sys.stderr)
        sys.exit(1)
