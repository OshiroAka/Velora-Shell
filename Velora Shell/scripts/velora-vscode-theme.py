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
STATE_PATH = STATE_DIR / "vscode-theme.json"
THEME_LABEL = "Velora pywal16"
EXTENSION_NAME = "velora-pywal16-code-theme"
EXTENSION_DIR_NAME = f"velora.{EXTENSION_NAME}-0.0.1"
THEME_JSON_NAME = "velora-pywal16-color-theme.json"


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
        editor = darken(bg, 0.18)
        panel = darken(sidebar, 0.08)
        panel2 = darken(popup, 0.04)
        line = lighten(editor, 0.08)
        selection = alpha(accent, 0.32)
        hover = alpha(accent, 0.18)
        shadow = "#00000066"
        terminal_black = darken(editor, 0.14)
        terminal_white = lighten(text, 0.12)
    else:
        editor = lighten(bg, 0.34)
        panel = lighten(sidebar, 0.16)
        panel2 = lighten(popup, 0.12)
        line = darken(editor, 0.07)
        selection = alpha(accent, 0.24)
        hover = alpha(accent, 0.13)
        shadow = alpha(darken(accent2, 0.36), 0.20)
        terminal_black = darken(text, 0.22)
        terminal_white = lighten(editor, 0.10)

    red = str(colors.get("color1") or "#f38ba8")
    green = str(colors.get("color2") or "#a6e3a1")
    yellow = str(colors.get("color3") or "#f9e2af")
    blue = str(colors.get("color4") or accent3)
    magenta = str(colors.get("color5") or accent2)
    cyan = str(colors.get("color6") or accent3)

    return {
        "mode": mode,
        "dark": dark,
        "wallpaper": theme.get("wallpaper") or wal.get("wallpaper", ""),
        "checksum": theme.get("checksum") or wal.get("checksum", ""),
        "bg": bg,
        "editor": editor,
        "panel": panel,
        "panel2": panel2,
        "card": card,
        "input": input_bg,
        "line": line,
        "text": text,
        "text_soft": text_soft,
        "muted": muted,
        "accent": accent,
        "accent2": accent2,
        "accent3": accent3,
        "border": border,
        "selection": selection,
        "hover": hover,
        "shadow": shadow,
        "button_text": text_on(accent),
        "red": red,
        "green": green,
        "yellow": yellow,
        "blue": blue,
        "magenta": magenta,
        "cyan": cyan,
        "terminal_black": terminal_black,
        "terminal_white": terminal_white,
    }


def build_workbench_colors(p):
    return {
        "focusBorder": p["accent"],
        "foreground": p["text"],
        "descriptionForeground": p["text_soft"],
        "disabledForeground": p["muted"],
        "errorForeground": p["red"],
        "widget.shadow": p["shadow"],
        "selection.background": p["selection"],
        "textLink.foreground": p["accent3"],
        "textLink.activeForeground": p["accent2"],
        "button.background": p["accent"],
        "button.foreground": p["button_text"],
        "button.hoverBackground": lighten(p["accent"], 0.10) if p["dark"] else darken(p["accent"], 0.08),
        "button.secondaryBackground": p["card"],
        "button.secondaryForeground": p["text"],
        "button.secondaryHoverBackground": p["hover"],
        "dropdown.background": p["input"],
        "dropdown.foreground": p["text"],
        "dropdown.border": alpha(p["border"], 0.42),
        "input.background": p["input"],
        "input.foreground": p["text"],
        "input.border": alpha(p["border"], 0.38),
        "input.placeholderForeground": p["muted"],
        "inputOption.activeBackground": p["hover"],
        "inputOption.activeBorder": p["accent"],
        "badge.background": p["accent"],
        "badge.foreground": p["button_text"],
        "progressBar.background": p["accent2"],
        "titleBar.activeBackground": p["panel2"],
        "titleBar.activeForeground": p["text"],
        "titleBar.inactiveBackground": p["panel"],
        "titleBar.inactiveForeground": p["muted"],
        "activityBar.background": p["panel"],
        "activityBar.foreground": p["text"],
        "activityBar.inactiveForeground": p["muted"],
        "activityBarBadge.background": p["accent2"],
        "activityBarBadge.foreground": text_on(p["accent2"]),
        "sideBar.background": p["panel2"],
        "sideBar.foreground": p["text_soft"],
        "sideBar.border": alpha(p["border"], 0.22),
        "sideBarTitle.foreground": p["text"],
        "sideBarSectionHeader.background": p["panel"],
        "sideBarSectionHeader.foreground": p["text"],
        "editorGroupHeader.tabsBackground": p["panel"],
        "editorGroupHeader.tabsBorder": alpha(p["border"], 0.18),
        "editorGroup.border": alpha(p["border"], 0.22),
        "tab.activeBackground": p["editor"],
        "tab.activeForeground": p["text"],
        "tab.inactiveBackground": p["panel"],
        "tab.inactiveForeground": p["muted"],
        "tab.hoverBackground": p["hover"],
        "tab.border": alpha(p["border"], 0.12),
        "tab.activeBorderTop": p["accent"],
        "breadcrumb.background": p["editor"],
        "breadcrumb.foreground": p["text_soft"],
        "breadcrumb.focusForeground": p["text"],
        "editor.background": p["editor"],
        "editor.foreground": p["text"],
        "editorLineNumber.foreground": p["muted"],
        "editorLineNumber.activeForeground": p["accent2"],
        "editorCursor.foreground": p["accent"],
        "editor.selectionBackground": p["selection"],
        "editor.inactiveSelectionBackground": alpha(p["accent"], 0.16),
        "editor.selectionHighlightBackground": alpha(p["accent2"], 0.18),
        "editor.wordHighlightBackground": alpha(p["accent3"], 0.14),
        "editor.wordHighlightStrongBackground": alpha(p["accent2"], 0.18),
        "editor.findMatchBackground": alpha(p["yellow"], 0.40),
        "editor.findMatchHighlightBackground": alpha(p["yellow"], 0.22),
        "editor.lineHighlightBackground": alpha(p["accent"], 0.07),
        "editor.lineHighlightBorder": "#00000000",
        "editorIndentGuide.background1": alpha(p["border"], 0.18),
        "editorIndentGuide.activeBackground1": alpha(p["accent"], 0.45),
        "editorWhitespace.foreground": alpha(p["muted"], 0.38),
        "editorBracketMatch.background": alpha(p["accent"], 0.18),
        "editorBracketMatch.border": alpha(p["accent"], 0.62),
        "editorGutter.background": p["editor"],
        "editorGutter.modifiedBackground": p["blue"],
        "editorGutter.addedBackground": p["green"],
        "editorGutter.deletedBackground": p["red"],
        "editorOverviewRuler.border": "#00000000",
        "editorWidget.background": p["panel2"],
        "editorWidget.foreground": p["text"],
        "editorWidget.border": alpha(p["border"], 0.32),
        "editorSuggestWidget.background": p["panel2"],
        "editorSuggestWidget.foreground": p["text"],
        "editorSuggestWidget.border": alpha(p["border"], 0.30),
        "editorSuggestWidget.selectedBackground": p["hover"],
        "editorSuggestWidget.highlightForeground": p["accent2"],
        "peekView.border": p["accent"],
        "peekViewEditor.background": p["editor"],
        "peekViewResult.background": p["panel2"],
        "peekViewResult.selectionBackground": p["hover"],
        "panel.background": p["panel2"],
        "panel.border": alpha(p["border"], 0.24),
        "panelTitle.activeForeground": p["text"],
        "panelTitle.inactiveForeground": p["muted"],
        "panelTitle.activeBorder": p["accent"],
        "terminal.background": p["editor"],
        "terminal.foreground": p["text"],
        "terminalCursor.foreground": p["accent"],
        "terminal.ansiBlack": p["terminal_black"],
        "terminal.ansiRed": p["red"],
        "terminal.ansiGreen": p["green"],
        "terminal.ansiYellow": p["yellow"],
        "terminal.ansiBlue": p["blue"],
        "terminal.ansiMagenta": p["magenta"],
        "terminal.ansiCyan": p["cyan"],
        "terminal.ansiWhite": p["terminal_white"],
        "terminal.ansiBrightBlack": p["muted"],
        "terminal.ansiBrightRed": lighten(p["red"], 0.16),
        "terminal.ansiBrightGreen": lighten(p["green"], 0.16),
        "terminal.ansiBrightYellow": lighten(p["yellow"], 0.14),
        "terminal.ansiBrightBlue": lighten(p["blue"], 0.16),
        "terminal.ansiBrightMagenta": lighten(p["magenta"], 0.16),
        "terminal.ansiBrightCyan": lighten(p["cyan"], 0.16),
        "terminal.ansiBrightWhite": p["text"],
        "statusBar.background": p["panel"],
        "statusBar.foreground": p["text"],
        "statusBar.border": alpha(p["border"], 0.18),
        "statusBar.debuggingBackground": p["accent2"],
        "statusBar.debuggingForeground": text_on(p["accent2"]),
        "statusBar.noFolderBackground": p["panel"],
        "statusBarItem.hoverBackground": p["hover"],
        "menu.background": p["panel2"],
        "menu.foreground": p["text"],
        "menu.selectionBackground": p["hover"],
        "menu.selectionForeground": p["text"],
        "menu.border": alpha(p["border"], 0.26),
        "quickInput.background": p["panel2"],
        "quickInput.foreground": p["text"],
        "quickInputTitle.background": p["panel"],
        "pickerGroup.foreground": p["accent2"],
        "pickerGroup.border": alpha(p["border"], 0.28),
        "list.activeSelectionBackground": p["selection"],
        "list.activeSelectionForeground": p["text"],
        "list.inactiveSelectionBackground": alpha(p["accent"], 0.18),
        "list.hoverBackground": p["hover"],
        "list.focusBackground": alpha(p["accent"], 0.22),
        "list.highlightForeground": p["accent2"],
        "tree.indentGuidesStroke": alpha(p["border"], 0.32),
        "scrollbar.shadow": "#00000000",
        "scrollbarSlider.background": alpha(p["border"], 0.24),
        "scrollbarSlider.hoverBackground": alpha(p["accent"], 0.34),
        "scrollbarSlider.activeBackground": alpha(p["accent"], 0.50),
        "gitDecoration.addedResourceForeground": p["green"],
        "gitDecoration.modifiedResourceForeground": p["blue"],
        "gitDecoration.deletedResourceForeground": p["red"],
        "gitDecoration.untrackedResourceForeground": p["green"],
        "diffEditor.insertedTextBackground": alpha(p["green"], 0.16),
        "diffEditor.removedTextBackground": alpha(p["red"], 0.16),
        "notifications.background": p["panel2"],
        "notifications.foreground": p["text"],
        "notifications.border": alpha(p["border"], 0.28),
    }


def build_token_colors(p):
    return [
        {"scope": ["comment", "punctuation.definition.comment"], "settings": {"foreground": p["muted"], "fontStyle": "italic"}},
        {"scope": ["keyword", "storage", "storage.type"], "settings": {"foreground": p["accent2"]}},
        {"scope": ["entity.name.function", "support.function", "meta.function-call"], "settings": {"foreground": p["accent"]}},
        {"scope": ["entity.name.type", "support.type", "support.class", "entity.name.class"], "settings": {"foreground": p["accent3"]}},
        {"scope": ["variable", "identifier"], "settings": {"foreground": p["text"]}},
        {"scope": ["variable.parameter", "meta.parameter"], "settings": {"foreground": p["text_soft"]}},
        {"scope": ["constant", "constant.numeric", "constant.language"], "settings": {"foreground": p["yellow"]}},
        {"scope": ["string", "markup.inline.raw.string"], "settings": {"foreground": p["green"]}},
        {"scope": ["string.regexp"], "settings": {"foreground": p["cyan"]}},
        {"scope": ["entity.name.tag", "support.class.component"], "settings": {"foreground": p["accent"]}},
        {"scope": ["entity.other.attribute-name", "meta.object-literal.key"], "settings": {"foreground": p["accent3"]}},
        {"scope": ["punctuation", "meta.brace"], "settings": {"foreground": p["text_soft"]}},
        {"scope": ["invalid", "invalid.illegal"], "settings": {"foreground": p["red"]}},
        {"scope": ["markup.heading"], "settings": {"foreground": p["accent"], "fontStyle": "bold"}},
        {"scope": ["markup.bold"], "settings": {"foreground": p["accent2"], "fontStyle": "bold"}},
        {"scope": ["markup.italic"], "settings": {"foreground": p["accent3"], "fontStyle": "italic"}},
        {"scope": ["markup.inserted"], "settings": {"foreground": p["green"]}},
        {"scope": ["markup.deleted"], "settings": {"foreground": p["red"]}},
        {"scope": ["markup.changed"], "settings": {"foreground": p["blue"]}},
    ]


def build_theme_json(p):
    return {
        "name": THEME_LABEL,
        "type": "dark" if p["dark"] else "light",
        "semanticHighlighting": True,
        "colors": build_workbench_colors(p),
        "tokenColors": build_token_colors(p),
        "semanticTokenColors": {
            "namespace": p["accent3"],
            "type": p["accent3"],
            "class": p["accent3"],
            "enum": p["accent3"],
            "interface": p["accent3"],
            "struct": p["accent3"],
            "typeParameter": p["accent3"],
            "function": p["accent"],
            "method": p["accent"],
            "macro": p["accent2"],
            "variable.readonly": p["yellow"],
            "property": p["text_soft"],
            "enumMember": p["yellow"],
            "event": p["accent2"],
            "operator": p["accent2"],
            "parameter": p["text_soft"],
            "comment": {"foreground": p["muted"], "fontStyle": "italic"},
            "string": p["green"],
            "number": p["yellow"],
            "regexp": p["cyan"],
            "keyword": p["accent2"],
        },
    }


def extension_targets():
    home = Path.home()
    xdg = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    specs = [
        ("Code", xdg / "Code" / "User" / "settings.json", home / ".vscode" / "extensions", "code"),
        ("Code - OSS", xdg / "Code - OSS" / "User" / "settings.json", home / ".vscode-oss" / "extensions", "code-oss"),
        ("VSCodium", xdg / "VSCodium" / "User" / "settings.json", home / ".vscode-oss" / "extensions", "codium"),
    ]
    result = []
    for name, settings_path, extensions_dir, command in specs:
        present = settings_path.exists() or shutil.which(command) is not None
        if present:
            result.append((name, settings_path, extensions_dir))
    return result


def write_extension(extensions_dir, theme_json):
    extension_dir = extensions_dir / EXTENSION_DIR_NAME
    theme_dir = extension_dir / "themes"
    theme_dir.mkdir(parents=True, exist_ok=True)
    package = {
        "name": EXTENSION_NAME,
        "displayName": THEME_LABEL,
        "description": "Generated Velora Shell pywal16 theme for Code, VS Code, Code - OSS, and VSCodium.",
        "version": "0.0.1",
        "publisher": "velora",
        "engines": {"vscode": "^1.70.0"},
        "categories": ["Themes"],
        "contributes": {
            "themes": [
                {
                    "label": THEME_LABEL,
                    "uiTheme": "vs-dark" if theme_json["type"] == "dark" else "vs",
                    "path": f"./themes/{THEME_JSON_NAME}",
                }
            ]
        },
    }
    (extension_dir / "package.json").write_text(json.dumps(package, indent=2) + "\n", encoding="utf-8")
    (theme_dir / THEME_JSON_NAME).write_text(json.dumps(theme_json, indent=2) + "\n", encoding="utf-8")
    return extension_dir


def strip_json_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"(^|[^:])//.*", r"\1", text)
    text = re.sub(r",\s*([}\]])", r"\1", text)
    return text


def load_settings(path):
    if not path.exists() or path.stat().st_size == 0:
        return {}
    raw = path.read_text(encoding="utf-8")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return json.loads(strip_json_comments(raw))


def write_settings(path, palette, colors, token_colors):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        backup = path.with_suffix(path.suffix + ".velora-bak")
        if not backup.exists():
            shutil.copy2(path, backup)

    settings = load_settings(path)
    settings["workbench.colorTheme"] = THEME_LABEL
    settings["workbench.preferredDarkColorTheme"] = THEME_LABEL
    settings["workbench.preferredLightColorTheme"] = THEME_LABEL
    settings["workbench.colorCustomizations"] = {
        **settings.get("workbench.colorCustomizations", {}),
        **colors,
    }
    settings["editor.tokenColorCustomizations"] = {
        **settings.get("editor.tokenColorCustomizations", {}),
        "textMateRules": token_colors,
    }
    settings["terminal.integrated.minimumContrastRatio"] = 1
    settings["velora.pywal16.wallpaper"] = palette["wallpaper"]
    settings["velora.pywal16.checksum"] = palette["checksum"]

    path.write_text(json.dumps(settings, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")


def save_state(palette, targets):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    data = {
        "theme": THEME_LABEL,
        "mode": palette["mode"],
        "wallpaper": palette["wallpaper"],
        "checksum": palette["checksum"],
        "targets": [
            {"app": name, "settings": str(settings), "extensions": str(extensions)}
            for name, settings, extensions in targets
        ],
    }
    STATE_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Generate and apply Velora pywal16 theme for Code/VS Code.")
    parser.add_argument("--quiet", action="store_true", help="suppress normal output")
    parser.add_argument("--status", action="store_true", help="print current generated state")
    parser.add_argument("--no-settings", action="store_true", help="only write the local theme extension")
    parser.add_argument("--no-extension", action="store_true", help="only update user settings")
    args = parser.parse_args()

    if args.status:
        if STATE_PATH.exists():
            print(STATE_PATH.read_text(encoding="utf-8").strip())
        else:
            print("missing")
        return 0

    wal = read_wal()
    theme = load_pywal_theme()
    palette = palette_from_theme(theme, wal)
    theme_json = build_theme_json(palette)
    colors = theme_json["colors"]
    token_colors = theme_json["tokenColors"]
    targets = extension_targets()

    if not targets:
        if not args.quiet:
            print("no Code/VS Code profile found")
        return 0

    for _, settings_path, extensions_dir in targets:
        if not args.no_extension:
            write_extension(extensions_dir, theme_json)
        if not args.no_settings:
            write_settings(settings_path, palette, colors, token_colors)

    save_state(palette, targets)

    if not args.quiet:
        for name, settings_path, extensions_dir in targets:
            print(f"{name}: settings={settings_path} extensions={extensions_dir / EXTENSION_DIR_NAME}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
