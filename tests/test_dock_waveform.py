import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DockWaveformTests(unittest.TestCase):
    def test_audio_trace_placement_silence_and_visible_consumer_lifecycle(self):
        with tempfile.TemporaryDirectory(prefix="velora-dock-waveform-") as temporary:
            base = Path(temporary)
            for name in ("core", "components", "features", "services", "platform", "assets", "shaders"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "shell.qml").write_text((ROOT / "tests/fixtures/dock-waveform.qml").read_text().replace('"../../', '"./'))
            env = dict(os.environ, HOME=temporary, XDG_CONFIG_HOME=str(base / "config"),
                XDG_DATA_HOME=str(base / "data"), XDG_CACHE_HOME=str(base / "cache"),
                XDG_STATE_HOME=str(base / "state"), XDG_RUNTIME_DIR=str(base / "runtime"),
                QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", VELORA_VALIDATE="1",
                DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent")
            for name in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(name, None)
            process = subprocess.run(["qs", "-p", str(base)], env=env,
                capture_output=True, text=True, timeout=10)
            output = process.stdout + process.stderr
            self.assertEqual(process.returncode, 0, output)
            self.assertIn("DOCK_WAVEFORM_OK", output)
            for message in ("FAILED", "TypeError", "ReferenceError", "Binding loop", "Cannot assign"):
                self.assertNotIn(message, output)
