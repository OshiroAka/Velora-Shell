import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FirstRunTests(unittest.TestCase):
    def test_global_configuration_initializes_without_legacy_profiles(self):
        runtime = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "velora-shell/runtime/quickshell/bin/qs"
        executable = str(runtime) if runtime.is_file() else shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required for the first-run integration test")
        with tempfile.TemporaryDirectory(prefix="velora-first-run-") as temporary:
            home = Path(temporary)
            checkout = home / "source"
            checkout.mkdir()
            for directory in ("core", "services", "scripts", "config", "assets", "features", "components", "platform"):
                shutil.copytree(ROOT / directory, checkout / directory)
            shutil.copy2(ROOT / "tests/fixtures/first-run.qml", checkout / "shell.qml")
            runtime_dir = home / "runtime"
            runtime_dir.mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / "config"),
                       XDG_DATA_HOME=str(home / "data"), XDG_STATE_HOME=str(home / "state"),
                       XDG_CACHE_HOME=str(home / "cache"), XDG_RUNTIME_DIR=str(runtime_dir),
                       QT_QPA_PLATFORM="offscreen", PYTHONDONTWRITEBYTECODE="1")
            env.pop("WAYLAND_DISPLAY", None)
            env.pop("QML_IMPORT_PATH", None)
            subprocess.run([str(checkout / "scripts/init-config")], env=env, check=True)
            config_dir = home / "config/velora-shell"
            marker = config_dir / "first-wallpaper.pending"
            state = home / "cache/velora-shell/current_wallpaper"
            self.assertTrue(marker.is_file())
            mock_bin = home / "bin"
            mock_bin.mkdir()
            mocks = {
                "pgrep": 'test "$*" = "-x awww-daemon"',
                "pkill": "exit 1",
                "hyprctl": """printf '%s\\n' '[{"width": 4000, "height": 3000}]'""",
                "awww": """[ "$1" = img ] && [ -r "$2" ] && [ "${VELORA_TEST_FAIL_BACKEND:-0}" != 1 ]""",
            }
            for name, body in mocks.items():
                mock = mock_bin / name
                mock.write_text("#!/bin/sh\n" + body + "\n")
                mock.chmod(0o755)
            wallpaper = checkout / "assets/wallpapers/velora.png"
            first_wallpaper = [str(checkout / "scripts/velora-wallpaper-apply"), "--first-run"]
            backend_env = dict(env, PATH=str(mock_bin) + os.pathsep + env["PATH"], VELORA_WALLPAPER_FIT_ONLY="1")
            failed = subprocess.run(first_wallpaper, env=dict(backend_env, VELORA_TEST_FAIL_BACKEND="1"), timeout=12)
            self.assertNotEqual(failed.returncode, 0)
            self.assertTrue(marker.is_file())
            self.assertFalse(state.exists())
            subprocess.run(first_wallpaper, env=backend_env, check=True, timeout=12)
            self.assertFalse(marker.exists())
            self.assertEqual(state.read_text(), f"static|{wallpaper}|{wallpaper}\n")
            subprocess.run([str(checkout / "scripts/generate-pywal-palette"), str(wallpaper), "dark"],
                           env=env, check=True, capture_output=True, text=True, timeout=12)
            cached_palette = json.loads((home / "cache/velora-shell/pywal/colors.json").read_text())
            self.assertEqual(cached_palette["special"]["background"], "#131d26")
            self.assertEqual(cached_palette["velora"]["primary"], "#626868")

            result = subprocess.run([executable, "-p", str(checkout)], env=env,
                                    capture_output=True, text=True, timeout=15)
            self.assertIn("VELORA_FIRST_RUN_READY", result.stdout + result.stderr)
            self.assertNotIn("TypeError", result.stdout + result.stderr)
            self.assertNotIn("Unable to assign [undefined]", result.stdout + result.stderr)
            self.assertFalse((home / "config/velora-shell/profiles.json").exists())
            self.assertFalse((home / "config/velora-shell/wallpaper-compositions.json").exists())
            current = config_dir / "config.json"
            document = json.loads(current.read_text())
            document["lockPreview"]["sharedWidgets"]["items"][0]["desktop"]["x"] = 311
            current.write_text(json.dumps(document))
            saved_wallpaper = "static|/existing/custom.png|/existing/custom.png\n"
            state.write_text(saved_wallpaper)
            subprocess.run([str(checkout / "scripts/init-config")], env=env, check=True)
            self.assertFalse(marker.exists())
            marker.touch()
            subprocess.run(first_wallpaper, env=backend_env, check=True, timeout=12)
            self.assertFalse(marker.exists())
            self.assertEqual(state.read_text(), saved_wallpaper)
            self.assertEqual(json.loads(current.read_text())["lockPreview"]["sharedWidgets"]["items"][0]["desktop"]["x"], 311)
