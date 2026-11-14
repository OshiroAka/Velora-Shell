"""New visual lockscreen in an isolated Qt process; fake authentication only."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class LockSceneTests(unittest.TestCase):
    def test_isolated_interaction_morphs_fake_authentication_and_layout(self):
        runner = str(Path("/usr/lib/qt6/bin/qmltestrunner")) if Path("/usr/lib/qt6/bin/qmltestrunner").is_file() else shutil.which("qmltestrunner")
        if not runner:
            self.skipTest("Qt Quick Test unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-new-lock-") as temporary:
            base = Path(temporary)
            for name in ("features", "components", "assets", "core"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            (base/"runtime").mkdir(mode=0o700)
            fixture = (ROOT/"tests/fixtures/tst_lock_scene.qml").read_text()
            fixture = fixture.replace('"../../', '"./').replace('@PREVIEW@', str(base/'preview.png'))
            (base/"tst_lock.qml").write_text(fixture)
            shutil.copyfile(ROOT/"tests/fixtures/fixture-landscape.svg", base/"fixture-landscape.svg")
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=str(base/"runtime"), XDG_CONFIG_HOME=str(base/"config"),
                       XDG_DATA_HOME=str(base/"data"), XDG_STATE_HOME=str(base/"state"), XDG_CACHE_HOME=str(base/"cache"),
                       DBUS_SESSION_BUS_ADDRESS="unix:path="+str(base/"no-session-bus"))
            if os.environ.get("VELORA_LOCK_RENDERER") == "opengl":
                env.pop("QT_QUICK_BACKEND", None)
                env.update(QSG_RHI_BACKEND="opengl", LIBGL_ALWAYS_SOFTWARE="1")
            for name in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE", "SWAYSOCK"):
                env.pop(name, None)
            result = subprocess.run([runner, "-input", str(base/"tst_lock.qml")], env=env,
                                    text=True, capture_output=True, timeout=25)
            output = result.stdout + result.stderr
            evidence = os.environ.get("VELORA_LOCK_EVIDENCE")
            if evidence:
                directory = Path(evidence); directory.mkdir(parents=True, exist_ok=True)
                (directory/"lock-tests.log").write_text(output)
                if (base/"preview.png").is_file():
                    shutil.copyfile(base/"preview.png", directory/"lock-preview.png")
            self.assertEqual(result.returncode, 0, output)
            for error in ("QWARN", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign"):
                self.assertNotIn(error, output)
            self.assertTrue((base/"preview.png").is_file(), output)

if __name__ == "__main__":
    unittest.main()
