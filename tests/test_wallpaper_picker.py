"""Exercise the principal wallpaper picker with real Qt input and animation."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WallpaperPickerTests(unittest.TestCase):
    def test_input_morph_reversal_and_bounded_thumbnail_lifecycle(self):
        with tempfile.TemporaryDirectory(prefix="velora-wallpaper-picker-") as directory:
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=directory)
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([
                "/usr/lib/qt6/bin/qmltestrunner", "-input",
                str(ROOT / "tests/fixtures/tst_wallpaper_picker.qml")
            ], env=env, capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertNotIn("QWARN", output)
            self.assertNotIn("Binding loop", output)
