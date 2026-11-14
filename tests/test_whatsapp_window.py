"""Native WhatsApp window and drawer handoff, with a disabled bridge and fake state."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WhatsAppWindowTests(unittest.TestCase):
    def test_window_handoff_search_responsive_layout_and_account_lifecycle(self):
        with tempfile.TemporaryDirectory(prefix="velora-whatsapp-window-") as temporary:
            base = Path(temporary)
            for name in ("components", "services", "surfaces", "core", "features", "assets", "platform"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "runtime").mkdir(mode=0o700)
            source = (ROOT / "tests/fixtures/whatsapp-window.qml").read_text()
            source = source.replace('"../../', '"./').replace("@PREVIEW@", str(base / "preview.png"))
            (base / "shell.qml").write_text(source)
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=str(base / "runtime"), XDG_CONFIG_HOME=str(base / "config"),
                       XDG_DATA_HOME=str(base / "data"), XDG_STATE_HOME=str(base / "state"),
                       XDG_CACHE_HOME=str(base / "cache"), DBUS_SESSION_BUS_ADDRESS="unix:path="+str(base / "no-bus"),
                       VELORA_VALIDATE="1")
            for name in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE", "SWAYSOCK"):
                env.pop(name, None)
            result = subprocess.run(["qs", "-p", str(base)], env=env, text=True, capture_output=True, timeout=25)
            output = result.stdout + result.stderr
            if evidence := os.environ.get("VELORA_WHATSAPP_EVIDENCE"):
                directory = Path(evidence); directory.mkdir(parents=True, exist_ok=True)
                (directory / "window-tests.log").write_text(output)
                if (base / "preview.png").is_file():
                    shutil.copyfile(base / "preview.png", directory / "whatsapp-window.png")
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("WHATSAPP_WINDOW_OK", output)
            self.assertTrue((base / "preview.png").is_file(), output)
            for error in ("FAILED", "FAIL!", "TypeError", "ReferenceError", "Binding loop", "Cannot assign", "QWARN"):
                self.assertNotIn(error, output)


if __name__ == "__main__":
    unittest.main()
