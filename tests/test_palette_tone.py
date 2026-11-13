"""The paint menu changes and persists the real Pywal tone preference."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PaletteToneTests(unittest.TestCase):
    def test_sun_moon_auto_fit_and_persist_across_processes(self):
        if not shutil.which("qs"):
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-paint-tone-") as directory:
            base = Path(directory)
            for name in ("core", "features", "components", "services", "platform", "assets", "config", "shaders"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "runtime").mkdir(mode=0o700)
            (base / "shell.qml").write_text((ROOT / "tests/fixtures/paint-tone.qml").read_text().replace('"../../', '"./'))
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       VELORA_VALIDATE="1", XDG_RUNTIME_DIR=str(base / "runtime"), XDG_CONFIG_HOME=str(base / "user-config"),
                       XDG_STATE_HOME=str(base / "state"), XDG_CACHE_HOME=str(base / "cache"), XDG_DATA_HOME=str(base / "data"))
            env.pop("WAYLAND_DISPLAY", None)
            for mode in ("light", "dark", "auto"):
                result = subprocess.run(["qs", "-p", str(base)], env=dict(env, VELORA_PAINT_MODE=mode),
                                        capture_output=True, text=True, timeout=6)
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("PAINT_TONE_OK " + mode, output)
                for error in ("PAINT_TONE_FAILED", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign"):
                    self.assertNotIn(error, output)
                config = json.loads((base / "user-config/velora-shell/config.json").read_text())
                self.assertEqual(config["appearance"]["pywalTone"], mode)
