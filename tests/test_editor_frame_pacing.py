"""The production native shape publisher must send consecutive animation poses."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EditorFramePacingTests(unittest.TestCase):
    def test_native_geometry_follows_every_pose_and_stops_at_rest(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        fixture = (ROOT / "tests/fixtures/editor-frame-pacing.qml").read_text()
        with tempfile.TemporaryDirectory(prefix="velora-editor-frames-") as temporary:
            base = Path(temporary)
            (base / "runtime").mkdir(mode=0o700)
            (base / "core").symlink_to(ROOT / "core", target_is_directory=True)
            (base / "shell.qml").write_text(fixture.replace('"../../core"', '"./core"'))
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       VELORA_VALIDATE="1", XDG_RUNTIME_DIR=str(base / "runtime"),
                       XDG_CACHE_HOME=str(base / "cache"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(base)], env=env, capture_output=True,
                                    text=True, timeout=8)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("EDITOR_FRAME_PACING_OK", output)
            for error in ("EDITOR_FRAME_PACING_FAILED", "TypeError:", "ReferenceError:", "Binding loop"):
                self.assertNotIn(error, output)
