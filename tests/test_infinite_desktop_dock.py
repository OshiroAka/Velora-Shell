import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InfiniteDockTests(unittest.TestCase):
    def test_settings_pin_reorder_remove_persist_and_render_curved_workspaces(self):
        with tempfile.TemporaryDirectory(prefix="velora-dock-test-") as temporary:
            directory = Path(temporary)
            for name in ("core", "config", "components", "features", "platform", "services", "assets"):
                (directory / name).symlink_to(ROOT / name, target_is_directory=True)
            (directory / "shell.qml").write_text((ROOT / "tests/fixtures/infinite-dock.qml").read_text().replace('"../../', '"./'))
            applications = directory / "data/applications"
            applications.mkdir(parents=True)
            (applications / "dock-test.desktop").write_text("[Desktop Entry]\nType=Application\nName=Dock Test\nExec=true\nIcon=application-x-executable\n")
            env = dict(os.environ, HOME=temporary, XDG_CONFIG_HOME=str(directory / "preferences"),
                       XDG_DATA_HOME=str(directory / "data"), XDG_DATA_DIRS=str(directory / "data"),
                       XDG_CACHE_HOME=str(directory / "cache"), XDG_STATE_HOME=str(directory / "state"),
                       XDG_RUNTIME_DIR=str(directory / "runtime"), QT_QPA_PLATFORM="offscreen",
                       QT_QUICK_BACKEND="software", VELORA_VALIDATE="1", DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent")
            for key in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(key, None)
            for reload in ("0", "1"):
                process = subprocess.run(["qs", "-p", str(directory)], env=dict(env, VELORA_DOCK_RELOAD=reload),
                                         text=True, capture_output=True, timeout=12)
                output = process.stdout + process.stderr
                self.assertEqual(process.returncode, 0, output)
                self.assertIn("INFINITE_DOCK_OK", output)
                for message in ("FAIL!", "INFINITE_DOCK_FAILED", "TypeError", "ReferenceError", "Binding loop", "Cannot assign"):
                    self.assertNotIn(message, output)


if __name__ == "__main__":
    unittest.main()
