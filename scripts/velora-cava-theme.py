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
STATE_PATH = STATE_DIR / "cava-theme.json"
CAVA_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "cava"
CAVA_CONFIG = CAVA_DIR / "config"
CAVA_THEME_NAME = "velora-pywal16"
CAVA_THEME_PATH = CAVA_DIR / "themes" / CAVA_THEME_NAME


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


def luminance(color):
    def channel(value):
        value = value / 255
        return value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in hex_to_rgb(color))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(a, b):
    light = max(luminance(a), luminance(b))
    dark = min(luminance(a), luminance(b))
    return (light + 0.05) / (dark + 0.05)


def readable(color, background):
    bg_dark = luminance(background) < 0.42
    target = "#f8f3ec" if bg_dark else "#201b17"
    current = color
    for amount in (0.18, 0.28, 0.38, 0.48, 0.58):
        if contrast_ratio(current, background) >= 2.25:
            break
        current = rgb_to_hex(mix(hex_to_rgb(color), hex_to_rgb(target), amount))
    return current


def soften(color, background, foreground, amount):
    bg_dark = luminance(background) < 0.42
    target = foreground if bg_dark else background
    return readable(rgb_to_hex(mix(hex_to_rgb(color), hex_to_rgb(target), amount)), background)


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


def unique_colors(colors):
    output = []
    seen = set()
    for color in colors:
        color = str(color or "").strip()
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
            continue
        color = color.lower()
        if color in seen:
            continue
        seen.add(color)
        output.append(color)
    return output


def palette_from_theme(theme, wal):
    colors = wal.get("colors", {}) if isinstance(wal, dict) else {}
    special = wal.get("special", {}) if isinstance(wal, dict) else {}

    background = str(special.get("background") or colors.get("color0") or "#161209")
    foreground = str(special.get("foreground") or colors.get("color15") or "#d8d7d6")
    accent = rgba_to_hex(theme.get("accentPrimary"), str(colors.get("color4") or "#8d5736"))
    accent2 = rgba_to_hex(theme.get("accentSecondary"), str(colors.get("color5") or accent))
    accent3 = rgba_to_hex(theme.get("accentTertiary"), str(colors.get("color6") or accent2))
    text = rgba_to_hex(theme.get("textPrimary"), foreground)

    base = unique_colors([
        colors.get("color1"),
        colors.get("color2"),
        colors.get("color3"),
        colors.get("color4"),
        accent,
        colors.get("color5"),
        accent2,
        colors.get("color6"),
        accent3,
        colors.get("color7"),
        colors.get("color15"),
        foreground,
    ])
    if len(base) < 4:
        base = unique_colors([background, accent, accent2, foreground])

    bg_dark = luminance(background) < 0.42
    horizontal = []
    for index in range(8):
        source = base[min(len(base) - 1, round(index * (len(base) - 1) / 7))]
        amount = 0.18 + index * 0.035 if bg_dark else 0.08
        horizontal.append(soften(source, background, foreground, amount))

    vertical = [
        soften(horizontal[0], background, foreground, 0.04),
        soften(accent, background, foreground, 0.14),
        soften(accent2, background, foreground, 0.18),
        soften(foreground, background, foreground, 0.0),
    ]

    return {
        "wallpaper": theme.get("wallpaper") or wal.get("wallpaper", ""),
        "checksum": theme.get("checksum") or wal.get("checksum", ""),
        "background": background,
        "foreground": readable(soften(text, background, foreground, 0.18), background),
        "horizontal": horizontal,
        "vertical": vertical,
    }


def generate_cava_theme(palette):
    lines = [
        "# Generated by Velora Shell from pywal16.",
        "# No background is set here, so terminal transparency stays controlled by Kitty.",
        f"# wallpaper {palette['wallpaper']}",
        "[color]",
        f"foreground = '{palette['foreground']}'",
        "",
        "gradient = 1",
    ]
    for index, color in enumerate(palette["vertical"], start=1):
        lines.append(f"gradient_color_{index} = '{color}'")

    lines.extend(["", "horizontal_gradient = 1"])
    for index, color in enumerate(palette["horizontal"], start=1):
        lines.append(f"horizontal_gradient_color_{index} = '{color}'")

    lines.extend(["", "blend_direction = 'up'"])
    return "\n".join(lines) + "\n"


def section_bounds(lines, section):
    header = f"[{section}]"
    start = None
    for index, line in enumerate(lines):
        if line.strip().lower() == header.lower():
            start = index
            break

    if start is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append(header)
        return len(lines) - 1, len(lines)

    end = len(lines)
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            end = index
            break
    return start, end


def ensure_section_key(lines, section, key, value):
    start, end = section_bounds(lines, section)
    pattern = re.compile(rf"^\s*{re.escape(key)}\s*=")
    desired = f"{key} = {value}"

    for index in range(start + 1, end):
        stripped = lines[index].strip()
        if stripped.startswith("#") or stripped.startswith(";"):
            continue
        if pattern.match(lines[index]):
            if lines[index] != desired:
                lines[index] = desired
            return

    insert_at = start + 1
    while insert_at < end and lines[insert_at].strip().startswith("#"):
        insert_at += 1
    lines.insert(insert_at, desired)


def ensure_cava_config():
    CAVA_DIR.mkdir(parents=True, exist_ok=True)
    if CAVA_CONFIG.exists():
        backup = CAVA_CONFIG.with_name("config.velora-bak")
        if not backup.exists():
            backup.write_bytes(CAVA_CONFIG.read_bytes())
        lines = CAVA_CONFIG.read_text(encoding="utf-8").splitlines()
    else:
        lines = []

    ensure_section_key(lines, "general", "live-config", "1")
    ensure_section_key(lines, "color", "theme", f"'{CAVA_THEME_NAME}'")
    CAVA_CONFIG.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    CAVA_CONFIG.touch()


def sync_cava_theme():
    theme = load_pywal_theme()
    wal = read_json(WAL_PATH)
    palette = palette_from_theme(theme, wal)

    CAVA_THEME_PATH.parent.mkdir(parents=True, exist_ok=True)
    CAVA_THEME_PATH.write_text(generate_cava_theme(palette), encoding="utf-8")
    ensure_cava_config()

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps({
        "theme": CAVA_THEME_NAME,
        "themeFile": str(CAVA_THEME_PATH),
        "configFile": str(CAVA_CONFIG),
        "wallpaper": palette["wallpaper"],
        "checksum": palette["checksum"],
        "foreground": palette["foreground"],
        "horizontal": palette["horizontal"],
    }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return palette


def main():
    parser = argparse.ArgumentParser(description="Sync CAVA terminal visualizer colors with Velora pywal16.")
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()

    try:
        palette = sync_cava_theme()
    except Exception as exc:
        print(f"velora-cava-theme: {exc}", file=sys.stderr)
        return 1

    if not args.quiet:
        colors = ",".join(palette["horizontal"][:4])
        print(f"cava-theme={CAVA_THEME_NAME} foreground={palette['foreground']} gradient={colors}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
