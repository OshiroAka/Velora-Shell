"""Camera events exercise the real widget scene and transformed media controls."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WidgetParallaxTests(unittest.TestCase):
    def test_camera_scene_layers_input_editing_and_persistence(self):
        with tempfile.TemporaryDirectory(prefix="velora-widget-parallax-") as temporary:
            base = Path(temporary)
            for name in ("core", "features", "components", "services", "platform", "assets", "config", "shaders"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            (base/"scripts").mkdir()
            (base/"scripts/velora-theme-state").symlink_to(ROOT/"scripts/velora-theme-state")
            host = (ROOT/"surfaces/SharedWidgetsHost.qml").read_text()
            native_shape = host[host.index("        function nativeShape("):host.index("\n        function queueNativeShapes(")]
            fixture = (ROOT/"tests/fixtures/widget-parallax.qml").read_text()
            fixture = fixture.replace("// NATIVE_SHAPE_FIXTURE", native_shape.replace("sharedScene", "scene"))
            (base/"shell.qml").write_text(fixture.replace('"../../', '"./'))
            (base/"runtime").mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(base), VELORA_VALIDATE="1", QT_QPA_PLATFORM="offscreen",
                       QT_QUICK_BACKEND="software", XDG_CONFIG_HOME=str(base/"user-config"),
                       XDG_RUNTIME_DIR=str(base/"runtime"), XDG_CACHE_HOME=str(base/"cache"),
                       XDG_DATA_HOME=str(base/"data"), XDG_STATE_HOME=str(base/"state"),
                       DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent")
            for name in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(name, None)
            result = subprocess.run(["qs", "-p", str(base)], env=env, capture_output=True, text=True, timeout=18)
            output = result.stdout+result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("WIDGET_PARALLAX_OK", output)
            for error in ("WIDGET_PARALLAX_FAILED", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign"):
                self.assertNotIn(error, output)
