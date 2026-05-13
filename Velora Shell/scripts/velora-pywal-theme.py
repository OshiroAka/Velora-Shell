#!/usr/bin/env python3
import argparse
import colorsys
import json
import os
import subprocess
import sys
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
WAL_PATH = Path(os.path.expanduser("~/.cache/wal/colors.json"))
THEME_PATH = BASE / "themes" / "pywal16.json"
DEFAULT_PATH = BASE / "themes" / "default.json"


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def hex_to_rgb(value):
    value = str(value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("invalid hex color")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*(clamp(v) for v in rgb))


def rgba(rgb, alpha):
    r, g, b = (clamp(v) for v in rgb)
    return f"rgba({r}, {g}, {b}, {alpha:.2f})"


def mix(a, b, amount):
    return tuple(a[i] + (b[i] - a[i]) * amount for i in range(3))


def luminance(rgb):
    def channel(v):
        v = v / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hsv(rgb):
    r, g, b = (max(0, min(255, v)) / 255 for v in rgb)
    return colorsys.rgb_to_hsv(r, g, b)


def hue_distance(a, b):
    diff = abs(a - b) % 1.0
    return min(diff, 1.0 - diff)


def rgb_distance(a, b):
    return sum((a[i] - b[i]) ** 2 for i in range(3)) ** 0.5


def palette_candidates(palette):
    preferred = [9, 10, 11, 12, 13, 14, 1, 2, 3, 4, 5, 6, 8]
    seen = set()
    result = []

    for index in preferred:
        if index < len(palette):
            color = palette[index]
            if color not in seen:
                seen.add(color)
                result.append(color)

    for index, color in enumerate(palette):
        if index in (0, 7, 15):
            continue
        if color not in seen:
            seen.add(color)
            result.append(color)

    return result


def palette_score(color, background):
    h, s, v = hsv(color)
    contrast = abs(luminance(color) - luminance(background))
    distance = min(1.0, rgb_distance(color, background) / 255)
    neutral_penalty = 0.35 if s < 0.10 else 0.0
    return s * 0.46 + v * 0.22 + contrast * 0.20 + distance * 0.12 - neutral_penalty


def sorted_palette(palette, background):
    return sorted(palette_candidates(palette), key=lambda color: palette_score(color, background), reverse=True)


def pick_palette_accent(palette, background, used=None, fallback=None):
    used = used or []
    ranked = sorted_palette(palette, background)

    for color in ranked:
        if rgb_distance(color, background) < 30:
            continue
        if all(hue_distance(hsv(color)[0], hsv(other)[0]) >= 0.10 or rgb_distance(color, other) >= 46 for other in used):
            return color

    for color in ranked:
        if rgb_distance(color, background) >= 30:
            return color

    if ranked:
        return ranked[0]
    if fallback:
        return hex_to_rgb(fallback)
    return background


def text_on(color):
    return "#ffffff" if luminance(color) < 0.42 else "#45384f"


def contrast_text(background):
    return "#f7f0fa" if luminance(background) < 0.42 else "#463954"


def readable_muted(background):
    return "#cfc4d8" if luminance(background) < 0.42 else "#8d7ca3"


def classify(background, palette):
    values = [luminance(background)] + [luminance(c) for c in palette]
    avg = sum(values) / len(values)
    bg_luma = values[0]
    if bg_luma > 0.62 and avg > 0.52:
        return "light"
    if bg_luma < 0.26 and avg < 0.44:
        return "dark"
    return "balanced"


def load_default(reason):
    with DEFAULT_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    data["themeName"] = "pywal16"
    data["themeMode"] = "fallback"
    data["fallback"] = True
    data["fallbackReason"] = reason
    data["source"] = str(WAL_PATH)
    return data


def build_theme():
    if not WAL_PATH.exists():
        return load_default("~/.cache/wal/colors.json not found")

    try:
        raw = json.loads(WAL_PATH.read_text(encoding="utf-8"))
        colors = raw.get("colors", {})
        special = raw.get("special", {})
        background = hex_to_rgb(special.get("background") or colors.get("color0"))
        foreground = hex_to_rgb(special.get("foreground") or colors.get("color7"))
        palette = [hex_to_rgb(colors[f"color{i}"]) for i in range(16) if f"color{i}" in colors]
        if len(palette) < 8:
            raise ValueError("incomplete pywal palette")
    except Exception as exc:
        return load_default(str(exc))

    mode = classify(background, palette)
    accent_primary = pick_palette_accent(palette, background, fallback="#e8a6c8")
    accent_secondary = pick_palette_accent(palette, background, [accent_primary], "#c894f2")
    accent_tertiary = pick_palette_accent(palette, background, [accent_primary, accent_secondary], "#a8d8ff")

    if mode == "dark":
        dark_base = mix(background, (0, 0, 0), 0.18)
        surface_base = mix(dark_base, accent_primary, 0.10)
        surface_sidebar = mix(dark_base, accent_primary, 0.13)
        surface_popup = mix(dark_base, accent_secondary, 0.12)
        surface_card = mix(dark_base, accent_primary, 0.18)
        surface_input = mix(dark_base, accent_secondary, 0.16)
        surface_button = mix(dark_base, accent_primary, 0.20)
        text_primary = rgb_to_hex(mix(foreground, (255, 255, 255), 0.34))
        text_secondary = rgb_to_hex(mix(foreground, accent_tertiary, 0.22))
        text_muted = rgb_to_hex(mix(foreground, background, 0.42))
        border_alpha = 0.10
        active_alpha = 0.28
        hover_alpha = 0.14
        shadow = (0, 0, 0)
        shadow_alpha = 0.38
    else:
        light_base = mix(background, (255, 255, 255), 0.78)
        tint = mix(accent_secondary, (255, 255, 255), 0.64)
        surface_base = mix(light_base, tint, 0.36)
        surface_sidebar = mix(light_base, accent_primary, 0.18)
        surface_popup = mix(light_base, accent_secondary, 0.16)
        surface_card = mix((255, 255, 255), accent_primary, 0.05)
        surface_input = mix((255, 255, 255), accent_secondary, 0.04)
        surface_button = mix((255, 255, 255), accent_primary, 0.06)
        text_primary = contrast_text(surface_popup)
        text_secondary = readable_muted(surface_popup)
        text_muted = rgb_to_hex(mix(hex_to_rgb(text_secondary), (255, 255, 255), 0.35))
        border_alpha = 0.66
        active_alpha = 0.34
        hover_alpha = 0.16
        shadow = mix(accent_secondary, background, 0.55)
        shadow_alpha = 0.13

    return {
        "themeName": "pywal16",
        "themeMode": mode,
        "source": str(WAL_PATH),
        "wallpaper": raw.get("wallpaper", ""),
        "checksum": raw.get("checksum", ""),
        "fallback": False,
        "surfaceBase": rgba(surface_base, 0.66 if mode != "dark" else 0.58),
        "surfaceSidebar": rgba(surface_sidebar, 0.70 if mode != "dark" else 0.62),
        "surfacePopup": rgba(surface_popup, 0.76 if mode != "dark" else 0.66),
        "surfaceCard": rgba(surface_card, 0.58 if mode != "dark" else 0.52),
        "surfaceInput": rgba(surface_input, 0.48 if mode != "dark" else 0.44),
        "surfaceButton": rgba(surface_button, 0.50 if mode != "dark" else 0.46),
        "textPrimary": text_primary,
        "textSecondary": text_secondary,
        "textMuted": text_muted,
        "accentPrimary": rgb_to_hex(accent_primary),
        "accentSecondary": rgb_to_hex(accent_secondary),
        "accentTertiary": rgb_to_hex(accent_tertiary),
        "borderSoft": rgba((255, 255, 255), border_alpha),
        "borderActive": rgba(accent_primary, 0.78 if mode != "dark" else 0.48),
        "borderGlow": rgba(accent_primary, 0.26 if mode != "dark" else 0.46),
        "sidebarBorderGlow": rgba(accent_primary, 0.26 if mode != "dark" else 0.50),
        "popupBorderGlow": rgba(accent_primary, 0.24 if mode != "dark" else 0.42),
        "buttonPrimaryBg": rgb_to_hex(accent_primary),
        "buttonPrimaryText": text_on(accent_primary),
        "buttonPrimaryGlow": rgba(accent_primary, 0.22 if mode != "dark" else 0.28),
        "buttonSecondaryBg": rgba((255, 255, 255), 0.58 if mode != "dark" else 0.12),
        "buttonSecondaryText": text_secondary,
        "activeBg": rgba(accent_primary, active_alpha),
        "activeText": text_on(accent_primary),
        "hoverBg": rgba(accent_primary, hover_alpha),
        "shadowColor": rgba(shadow, shadow_alpha),
        "sidebarGlow": rgba(accent_primary, 0.15 if mode != "dark" else 0.30),
        "popupGlow": rgba(accent_primary, 0.13 if mode != "dark" else 0.22),
        "textGlow": rgba(accent_primary, 0.10 if mode != "dark" else 0.22),
        "iconGlow": rgba(accent_secondary, 0.16 if mode != "dark" else 0.26),
        "glassBlur": 18 if mode != "dark" else 28
    }


def write_theme(data):
    THEME_PATH.parent.mkdir(parents=True, exist_ok=True)
    THEME_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def notify_quickshell():
    try:
        subprocess.run(
            ["qs", "ipc", "-p", str(BASE), "call", "velora", "reloadPywal16"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=1.5,
            check=False,
        )
    except Exception:
        pass


def main():
    parser = argparse.ArgumentParser(description="Generate Velora Shell pywal16 theme.")
    parser.add_argument("--status", action="store_true", help="print generated, wal, or missing without writing")
    parser.add_argument("--emit", action="store_true", help="print the current generated pywal16 JSON")
    parser.add_argument("--emit-or-generate", action="store_true", help="generate from pywal if needed and print JSON")
    parser.add_argument("--no-ipc", action="store_true", help="do not notify the running Quickshell instance")
    args = parser.parse_args()

    if args.status:
        if THEME_PATH.exists() and THEME_PATH.stat().st_size > 0:
            print("generated")
        elif WAL_PATH.exists() and WAL_PATH.stat().st_size > 0:
            print("wal")
        else:
            print("missing")
        return 0

    if args.emit and THEME_PATH.exists():
        print(THEME_PATH.read_text(encoding="utf-8").strip())
        return 0

    data = build_theme()
    write_theme(data)

    if args.emit or args.emit_or_generate:
        print(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    elif not args.no_ipc:
        notify_quickshell()

    return 0


if __name__ == "__main__":
    sys.exit(main())
