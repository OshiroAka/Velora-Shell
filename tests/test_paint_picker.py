import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class PaintPickerTests(unittest.TestCase):
    def test_pixels_and_cancellation(self):
        with tempfile.TemporaryDirectory(prefix="velora-paint-test-") as directory:
            env = dict(os.environ, HOME=directory, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=directory, XDG_CONFIG_HOME=directory+"/xdg-config", XDG_CACHE_HOME=directory+"/cache",
                       XDG_DATA_HOME=directory+"/data", XDG_STATE_HOME=directory+"/state",
                       DBUS_SESSION_BUS_ADDRESS="unix:path="+directory+"/no-bus")
            for key in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(key, None)
            result = subprocess.run(["/usr/lib/qt6/bin/qmltestrunner", "-input", str(ROOT/"tests/fixtures/tst_paint_picker.qml")], env=env, capture_output=True, text=True, timeout=15)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertNotIn("QWARN", output)

    def test_material_slider_keeps_menu_and_layout(self):
        with tempfile.TemporaryDirectory(prefix="velora-paint-material-") as directory:
            base = Path(directory)
            for name in ("core", "features", "components", "platform", "services", "assets", "config"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            (base/"shell.qml").write_text((ROOT/"tests/fixtures/paint-material.qml").read_text().replace('"../../', '"./'))
            (base/"runtime").mkdir(mode=0o700)
            env = dict(os.environ, HOME=directory, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=str(base/"runtime"), XDG_CONFIG_HOME=directory+"/xdg-config", XDG_CACHE_HOME=directory+"/cache",
                       XDG_DATA_HOME=directory+"/data", XDG_STATE_HOME=directory+"/state",
                       DBUS_SESSION_BUS_ADDRESS="unix:path="+directory+"/no-bus")
            for key in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(key, None)
            result = subprocess.run(["qs", "-p", directory], env=env, capture_output=True, text=True, timeout=12)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("PAINT_MATERIAL_OK", output)
            for error in ("ReferenceError", "TypeError", "Binding loop", "Cannot assign"):
                self.assertNotIn(error, output)
