#!/usr/bin/env python3
"""Generate a dark aurora Telegram Desktop theme from the active pywal palette."""

import argparse
import colorsys
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
import zipfile
from pathlib import Path


WAL_PATH = Path.home() / ".cache/wal/colors.json"
OUTPUT_DIR = Path.home() / ".local/share/velora-shell/telegram"
OUTPUT_PATH = OUTPUT_DIR / "velora-pywal.tdesktop-theme"
STATE_PATH = Path.home() / ".local/state/velora-shell/telegram-pywal.sha256"
GRADIENT_SIZE = (1600, 900)
THEME_VERSION = "3"


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def hex_to_rgb(value):
    value = str(value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("invalid hex color")
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*(clamp(channel) for channel in rgb))


def mix(first, second, amount):
    return tuple(first[index] + (second[index] - first[index]) * amount for index in range(3))


def luminance(rgb):
    def linear(channel):
        channel /= 255
        return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4

    red, green, blue = (linear(channel) for channel in rgb)
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def hsv(rgb):
    return colorsys.rgb_to_hsv(*(channel / 255 for channel in rgb))


def accent_with_hue_shift(rgb, shift):
    hue, saturation, value = hsv(rgb)
    red, green, blue = colorsys.hsv_to_rgb(
        (hue + shift) % 1.0,
        max(0.58, saturation),
        max(0.68, value),
    )
    return red * 255, green * 255, blue * 255


def hue_distance(first, second):
    distance = abs(hsv(first)[0] - hsv(second)[0]) % 1.0
    return min(distance, 1.0 - distance)


def read_wal():
    try:
        payload = json.loads(WAL_PATH.read_text(encoding="utf-8"))
        colors = payload.get("colors") or {}
        background = hex_to_rgb((payload.get("special") or {}).get("background"))
        palette = [hex_to_rgb(colors[f"color{index}"]) for index in range(16)]
        return background, palette
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        raise RuntimeError(f"pywal palette unavailable: {error}") from error


def unique_accents(palette, background):
    selected = []
    for index in (13, 12, 14, 9, 10, 11, 5, 4, 6, 1, 2, 3):
        candidate = palette[index]
        if sum((candidate[channel] - background[channel]) ** 2 for channel in range(3)) < 1300:
            continue
        if all(sum((candidate[channel] - item[channel]) ** 2 for channel in range(3)) > 750 for item in selected):
            selected.append(candidate)
        if len(selected) == 3:
            break

    while len(selected) < 3:
        selected.append(palette[(9 + len(selected)) % len(palette)])

    if max(hue_distance(selected[0], selected[1]), hue_distance(selected[0], selected[2]), hue_distance(selected[1], selected[2])) < 0.08:
        seed = max(selected, key=lambda color: hsv(color)[1] * 0.55 + hsv(color)[2] * 0.45)
        selected = [
            accent_with_hue_shift(seed, 0.0),
            accent_with_hue_shift(seed, 0.12),
            accent_with_hue_shift(seed, -0.12),
        ]
    return tuple(selected[:3])


def theme_colors(background, palette):
    accents = unique_accents(palette, background)
    base = mix(background, (0, 0, 0), 0.50)
    panel = mix(base, accents[2], 0.10)
    panel_over = mix(base, accents[1], 0.20)
    input_bg = mix(base, accents[0], 0.13)
    incoming = mix(base, accents[1], 0.16)
    outgoing = mix(accents[0], base, 0.18)
    outgoing_selected = mix(accents[1], base, 0.16)
    foreground = (248, 245, 250) if luminance(base) < 0.42 else (31, 25, 35)
    soft_foreground = mix(foreground, base, 0.30)
    muted_foreground = mix(foreground, base, 0.50)
    accent = mix(accents[0], (255, 255, 255), 0.08)
    accent_soft = mix(accents[1], (255, 255, 255), 0.06)
    link = mix(accents[2], (255, 255, 255), 0.20)
    gradient_base = mix(background, (0, 0, 0), 0.18)

    return {
        "base": base,
        "panel": panel,
        "panelOver": panel_over,
        "input": input_bg,
        "incoming": incoming,
        "outgoing": outgoing,
        "outgoingSelected": outgoing_selected,
        "foreground": foreground,
        "softForeground": soft_foreground,
        "mutedForeground": muted_foreground,
        "accent": accent,
        "accentSoft": accent_soft,
        "link": link,
        "gradientBase": gradient_base,
        "accents": accents,
    }


def colors_tdesktop_theme(colors):
    value = {
        name: rgb_to_hex(color)
        for name, color in colors.items()
        if isinstance(color, tuple)
        and len(color) == 3
        and all(isinstance(channel, (int, float)) for channel in color)
    }
    return f"""windowBg: {value['base']};
windowFg: {value['foreground']};
windowSubTextFg: {value['softForeground']};
windowBoldFg: {value['foreground']};
windowBgOver: {value['panelOver']};
windowFgOver: {value['foreground']};
windowActiveTextFg: {value['foreground']};
activeButtonBg: {value['accent']};
activeButtonFg: {value['base']};
dialogsBg: {value['base']};
dialogsBgOver: {value['panelOver']};
dialogsBgActive: {value['accentSoft']};
dialogsTextFg: {value['softForeground']};
dialogsTextFgOver: {value['foreground']};
dialogsTextFgActive: {value['foreground']};
dialogsNameFg: {value['foreground']};
dialogsNameFgOver: {value['foreground']};
dialogsNameFgActive: {value['foreground']};
dialogsDateFg: {value['mutedForeground']};
dialogsDateFgOver: {value['softForeground']};
dialogsDateFgActive: {value['foreground']};
dialogsUnreadBg: {value['accent']};
dialogsUnreadBgMuted: {value['mutedForeground']};
dialogsUnreadFg: {value['base']};
historyBg: {value['base']};
historyComposeAreaBg: {value['panel']};
historyComposeAreaFg: {value['foreground']};
historyComposeAreaBgOver: {value['panelOver']};
historySendIconFg: {value['accent']};
historySendIconFgOver: {value['accentSoft']};
historyTextInFg: {value['foreground']};
historyTextOutFg: {value['foreground']};
historyLinkInFg: {value['link']};
historyLinkOutFg: {value['link']};
historyUnreadBarBg: {value['accentSoft']};
historyUnreadBarBorder: {value['accent']};
historyUnreadBarFg: {value['foreground']};
historyScrollBg: {value['panel']};
historyScrollBgOver: {value['panelOver']};
msgInBg: {value['incoming']};
msgInBgSelected: {value['panelOver']};
msgInFg: {value['foreground']};
msgInDateFg: {value['mutedForeground']};
msgInServiceFg: {value['softForeground']};
msgOutBg: {value['outgoing']};
msgOutBgSelected: {value['outgoingSelected']};
msgOutFg: {value['foreground']};
msgOutDateFg: {value['softForeground']};
msgOutServiceFg: {value['foreground']};
overviewCheckBg: {value['accent']};
overviewCheckFg: {value['base']};
profileVerifiedCheckBg: {value['accent']};
profileVerifiedCheckFg: {value['base']};
"""


def write_png(path, colors):
    width, height = GRADIENT_SIZE
    base = colors["gradientBase"]
    first, second, third = colors["accents"]
    centers = ((0.08, 0.12, first, 0.30), (0.52, 0.48, second, 0.27), (0.94, 0.82, third, 0.32))

    compressor = zlib.compressobj(level=9)
    with path.open("wb") as output:
        output.write(b"\x89PNG\r\n\x1a\n")

        def chunk(kind, data):
            output.write(struct.pack(">I", len(data)))
            output.write(kind)
            output.write(data)
            output.write(struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

        chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        compressed_rows = []
        for y in range(height):
            row = bytearray(b"\0")
            yn = y / max(1, height - 1)
            for x in range(width):
                xn = x / max(1, width - 1)
                diagonal = xn * 0.64 + yn * 0.36
                if diagonal < 0.5:
                    spectral = mix(first, second, diagonal / 0.5)
                else:
                    spectral = mix(second, third, (diagonal - 0.5) / 0.5)
                pixel = mix(base, spectral, 0.58)
                for cx, cy, accent, strength in centers:
                    distance = ((xn - cx) ** 2 * 0.84) + ((yn - cy) ** 2 * 1.18)
                    glow = max(0.0, 1.0 - distance * 2.15) ** 2
                    pixel = mix(pixel, accent, strength * glow)
                pixel = mix(pixel, (0, 0, 0), 0.05 + yn * 0.13)
                row.extend(clamp(channel) for channel in pixel)
            compressed = compressor.compress(row)
            if compressed:
                compressed_rows.append(compressed)
        compressed_rows.append(compressor.flush())
        chunk(b"IDAT", b"".join(compressed_rows))
        chunk(b"IEND", b"")


def theme_digest(background, palette):
    payload = json.dumps({"version": THEME_VERSION, "background": background, "palette": palette}, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def write_theme(background, palette, quiet):
    digest = theme_digest(background, palette)
    previous = ""
    try:
        previous = STATE_PATH.read_text(encoding="utf-8").strip()
    except OSError:
        pass

    if previous == digest and OUTPUT_PATH.is_file():
        if not quiet:
            print(OUTPUT_PATH)
        return False

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    colors = theme_colors(background, palette)
    with tempfile.TemporaryDirectory(prefix=".velora-telegram-", dir=OUTPUT_DIR) as temporary:
        temporary_path = Path(temporary)
        colors_path = temporary_path / "colors.tdesktop-theme"
        gradient_path = temporary_path / "background.png"
        archive_path = temporary_path / OUTPUT_PATH.name
        colors_path.write_text(colors_tdesktop_theme(colors), encoding="utf-8")
        write_png(gradient_path, colors)
        with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            archive.write(colors_path, colors_path.name)
            archive.write(gradient_path, gradient_path.name)
        os.replace(archive_path, OUTPUT_PATH)

    temporary_state = STATE_PATH.with_suffix(".tmp")
    temporary_state.write_text(f"{digest}\n", encoding="utf-8")
    os.replace(temporary_state, STATE_PATH)
    if not quiet:
        print(OUTPUT_PATH)
    return True


def open_telegram_preview(theme_path, quiet):
    gdbus = shutil.which("gdbus")
    if gdbus:
        uri = theme_path.resolve().as_uri()
        try:
            result = subprocess.run(
                [
                    gdbus,
                    "call",
                    "--session",
                    "--dest",
                    "org.telegram.desktop",
                    "--object-path",
                    "/org/telegram/desktop",
                    "--method",
                    "org.freedesktop.Application.Open",
                    f"['{uri}']",
                    "{}",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=5.0,
                check=False,
            )
            if result.returncode == 0:
                if not quiet:
                    print("Telegram opened the generated theme preview.", file=sys.stderr)
                return
        except (OSError, subprocess.TimeoutExpired):
            pass

    executable = shutil.which("Telegram")
    if not executable:
        return
    try:
        subprocess.Popen([executable, "--", str(theme_path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        if not quiet:
            print("Telegram opened the generated theme preview.", file=sys.stderr)
    except OSError as error:
        if not quiet:
            print(f"could not reopen Telegram: {error}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quiet", action="store_true", help="suppress normal output")
    parser.add_argument(
        "--open-preview",
        "--reopen",
        dest="open_preview",
        action="store_true",
        help="open the generated theme preview without closing Telegram",
    )
    args = parser.parse_args()
    try:
        background, palette = read_wal()
        changed = write_theme(background, palette, args.quiet)
        if changed and args.open_preview:
            open_telegram_preview(OUTPUT_PATH, args.quiet)
    except RuntimeError as error:
        if not args.quiet:
            print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
