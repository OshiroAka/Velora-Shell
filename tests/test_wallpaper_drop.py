"""Dropped downloads must survive, appear in the library and stay unapplied."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WallpaperDropTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="velora-wallpaper-drop-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        (self.home / "runtime").mkdir(mode=0o700)
        self.env = dict(os.environ, HOME=str(self.home), QT_QPA_PLATFORM="offscreen",
                        QT_QUICK_BACKEND="software", XDG_RUNTIME_DIR=str(self.home / "runtime"),
                        XDG_CONFIG_HOME=str(self.home / "config"), XDG_STATE_HOME=str(self.home / "state"),
                        XDG_DATA_HOME=str(self.home / "data"), XDG_CACHE_HOME=str(self.home / "cache"),
                        DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent", VELORA_VALIDATE="1")
        for key in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
            self.env.pop(key, None)

    def download(self, name, data=b"downloaded-media"):
        path = self.home / "Downloads" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return path

    def run_import(self, urls):
        result = subprocess.run([sys.executable, str(ROOT / "scripts/velora-wallpaper-import"), json.dumps(urls)],
                                env=self.env, capture_output=True, text=True, timeout=4)
        return result.returncode, json.loads(result.stdout)

    def test_copies_downloads_handles_encoded_names_and_never_overwrites(self):
        source = self.download("paisagem # verão % $(test).JPG")
        code, result = self.run_import([source.as_uri(), source.as_uri()])
        self.assertEqual(code, 0, result)
        self.assertEqual(result["errors"], [])
        self.assertEqual(len(result["entries"]), 1)
        destination = Path(result["entries"][0]["path"])
        self.assertEqual(destination.name, source.name)
        self.assertEqual(destination.parent, self.home / "Pictures/Wallpapers/static")
        self.assertEqual(source.read_bytes(), destination.read_bytes())
        self.assertEqual(self.run_import([source.as_uri()])[1]["entries"], result["entries"])
        source.write_bytes(b"different-download")
        changed = self.run_import([source.as_uri()])[1]["entries"][0]
        self.assertNotEqual(changed["path"], str(destination))
        self.assertEqual(destination.read_bytes(), b"downloaded-media")
        self.assertEqual(Path(changed["path"]).read_bytes(), source.read_bytes())
        source.unlink()
        self.assertTrue(destination.exists(), "Removing a download must not remove its imported wallpaper")
        self.assertEqual(list(destination.parent.glob(".velora-import-*")), [])

    def test_live_media_and_existing_library_files_keep_scanner_identities(self):
        sources = [self.download("video.MP4"), self.download("animated.gif"), self.download("still.webp")]
        code, result = self.run_import([path.as_uri() for path in sources])
        self.assertEqual(code, 0, result)
        self.assertEqual([entry["kind"] for entry in result["entries"]], ["live", "live", "static"])
        library = self.home / "Pictures/Wallpapers"
        existing = library / "other/picture.gif"
        existing.parent.mkdir(); existing.write_bytes(b"gif")
        code, reused = self.run_import([existing.as_uri()])
        self.assertEqual(code, 0)
        self.assertEqual(reused["entries"][0]["path"], str(existing))
        self.assertEqual(reused["entries"][0]["kind"], "static")
        # The scanner keys use ~/Pictures/Wallpapers even when that directory
        # points to storage on another disk.
        storage = self.home / "wallpapers-storage"
        library.rename(storage)
        library.symlink_to(storage, target_is_directory=True)
        code, through_link = self.run_import([p.as_uri() for p in sources] + [existing.as_uri()])
        self.assertEqual(code, 0, through_link)
        self.assertEqual(through_link["entries"], result["entries"] + reused["entries"])
        scan = subprocess.run([sys.executable, str(ROOT / "scripts/velora-wallpaper-index")],
                              env=self.env, text=True, capture_output=True, timeout=3)
        self.assertEqual(scan.returncode, 0, scan.stderr)
        rows = [json.loads(line) for line in scan.stdout.splitlines() if line.startswith("{")]
        self.assertEqual({row["key"] for row in rows}, {entry["key"] for entry in result["entries"] + reused["entries"]})

    def test_invalid_missing_unfinished_and_nonregular_files_do_not_enter_library(self):
        partial = self.download("download.jpg.crdownload")
        empty = self.download("empty.jpg", b"")
        fifo = self.home / "pipe.png"; os.mkfifo(fifo)
        invalid = ["https://example.com/a.jpg", "file://remote/a.mp4", "file:///bad%FF.jpg", "file://[broken",
                   partial.as_uri(), empty.as_uri(), fifo.as_uri(), (self.home / "missing.png").as_uri(),
                   (self.home / "Downloads").as_uri()]
        code, result = self.run_import(invalid)
        self.assertEqual(code, 1)
        self.assertEqual(result["entries"], [])
        self.assertEqual(len(result["errors"]), len(invalid))
        self.assertFalse((self.home / "Pictures/Wallpapers").exists())
        source = self.download("valid.png")
        code, result = self.run_import([source.as_uri(), invalid[0]])
        self.assertEqual(code, 0)
        self.assertEqual(len(result["entries"]), 1)
        self.assertEqual(len(result["errors"]), 1)

    def test_native_external_drag_copy_cancel_rejection_and_disabled_target(self):
        if not shutil.which("c++"):
            self.skipTest("Qt development tools are needed for native drag delivery")
        version = subprocess.check_output(["pkg-config", "--modversion", "Qt6Gui"], text=True).strip()
        include = Path(subprocess.check_output(["pkg-config", "--variable=includedir", "Qt6Gui"], text=True).strip())
        if not (include / "QtGui" / version / "QtGui/qpa/qwindowsysteminterface.h").is_file():
            self.skipTest("Qt platform headers are needed for native drag delivery")
        flags = subprocess.check_output(["pkg-config", "--cflags", "--libs", "Qt6Quick"], text=True).split()
        flags += ["-I" + str(include / module / version) for module in ("QtCore", "QtGui")]
        flags += ["-I" + str(include / "QtGui" / version / "QtGui")]
        binary = self.home / "native-drop"
        subprocess.run(["c++", "-std=c++17", str(ROOT / "tests/fixtures/wallpaper-drop-events.cpp"),
                        "-o", str(binary), *flags], check=True, capture_output=True, text=True, timeout=30)
        result = subprocess.run([str(binary), str(ROOT / "tests/fixtures/wallpaper-drop.qml"), str(self.download("photo # verão.jpg"))],
                                env=self.env, capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("WALLPAPER_DROP_EVENTS_OK", result.stdout)

    def test_service_queues_imports_refreshes_inventory_and_selects_without_applying(self):
        for folder in ("services", "features", "core", "components", "assets", "shaders"):
            (self.home / folder).symlink_to(ROOT / folder, target_is_directory=True)
        (self.home / "scripts").mkdir()
        for name in ("velora-wallpaper-import", "velora-wallpaper-index"):
            (self.home / "scripts" / name).symlink_to(ROOT / "scripts" / name)
        # Use the real quick inventory; keep media decoders out of this fixture.
        scan = self.home / "scripts/velora-wallpaper-scan"
        scan.write_text('#!/bin/sh\nexec python3 "$(dirname "$0")/velora-wallpaper-index"\n')
        scan.chmod(0o755)
        (self.home / "shell.qml").write_text((ROOT / "tests/fixtures/wallpaper-import.qml").read_text().replace('"../../', '"./'))
        sources = [self.download("image.jpg"), self.download("live.mp4")]
        result = subprocess.run(["qs", "-p", str(self.home)], env=dict(self.env, VELORA_IMPORT_URLS=json.dumps([p.as_uri() for p in sources])),
                                text=True, capture_output=True, timeout=13)
        output = result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, output)
        self.assertIn("WALLPAPER_IMPORT_SERVICE_OK", output)
        for error in ("FAILED", "TypeError:", "ReferenceError:", "Invalid write", "Binding loop", "Cannot assign"):
            self.assertNotIn(error, output)


if __name__ == "__main__":
    unittest.main()
