import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class ManualColorTests(unittest.TestCase):
    def test_inline_picker_cancel_apply_palette_freeze_and_persistence(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-manual-colors-") as directory:
            base = Path(directory)
            for name in ("core", "features", "components", "services", "platform", "assets", "config", "shaders"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "scripts").mkdir()
            for path in (ROOT / "scripts").iterdir():
                if not path.is_file():
                    continue
                helper = base / "scripts" / path.name
                if path.name == "velora-theme-state":
                    helper.symlink_to(path)
                else:
                    helper.write_text('#!/usr/bin/env python3\nprint("{}")\n')
                    helper.chmod(0o755)
            (base / "shell.qml").write_text((ROOT / "tests/fixtures/manual-colors.qml").read_text().replace('"../../', '"./'))
            (base / "runtime").mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       VELORA_VALIDATE="1", XDG_RUNTIME_DIR=str(base / "runtime"),
                       XDG_CONFIG_HOME=str(base / "user-config"), XDG_DATA_HOME=str(base / "data"),
                       XDG_STATE_HOME=str(base / "state"), XDG_CACHE_HOME=str(base / "cache"),
                       VELORA_MANUAL_WHITE_SCREENSHOT=str(base / "white-"))
            env.pop("WAYLAND_DISPLAY", None)
            for reload in ("0", "1"):
                result = subprocess.run([executable, "-p", str(base)], env=dict(env, VELORA_MANUAL_RELOAD=reload),
                                        capture_output=True, text=True, timeout=15)
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("MANUAL_COLORS_OK", output)
                for error in ("MANUAL_COLORS_FAILED", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign"):
                    self.assertNotIn(error, output)

            for scheme in ("dark", "light"):
                with Image.open(base / ("white-" + scheme + ".png")) as picture:
                    self.assertEqual(picture.convert("RGBA").getpixel((25,50)), (255,255,255,255))

    def test_disabled_wallpaper_colours_do_not_queue_or_run_theme_workers(self):
        source = (ROOT / "scripts/velora-wallpaper-apply").read_text()
        functions = []
        for name in ("automatic_wallpaper_colors_enabled", "run_low_priority", "theme_stamp_matches", "apply_theme_async"):
            match = re.search(r"^" + name + r"\(\) \{\n.*?^\}", source, re.M | re.S)
            self.assertIsNotNone(match, name)
            functions.append(match.group())
        with tempfile.TemporaryDirectory(prefix="velora-wallpaper-colours-") as directory:
            base = Path(directory)
            config = base / "velora-shell/config.json"
            config.parent.mkdir()
            env = dict(os.environ, XDG_CONFIG_HOME=str(base))
            config.write_text(json.dumps({"appearance": {"wallpaperColorsEnabled": False}}))
            script = "\n".join(functions) + '''
stop_stale_theme_workers() { exit 91; }
start_theme_worker() { exit 92; }
automatic_wallpaper_colors_enabled && exit 93
apply_theme_async /fixture/wallpaper.png || exit 94
run_low_priority printf SHOULD_NOT_RUN || exit 95
theme_stamp_matches old && exit 96
printf DISABLED_OK
'''
            result = subprocess.run(["bash", "-c", script], env=env, text=True, capture_output=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "DISABLED_OK")
            for value in ({}, {"appearance": {"wallpaperColorsEnabled": True}}):
                config.write_text(json.dumps(value))
                result = subprocess.run(["bash", "-c", functions[0] + "\nautomatic_wallpaper_colors_enabled"],
                                        env=env, text=True, capture_output=True, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
