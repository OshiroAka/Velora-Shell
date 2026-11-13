"""Exercise the media page, lazy groups, real setters and search in isolation."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MediaSettingsTests(unittest.TestCase):
    def test_bundled_icons_shape_as_glyphs(self):
        # Missing ligatures display their names over the button labels.
        import ctypes as c
        import ctypes.util
        import re
        library = ctypes.util.find_library("harfbuzz")
        if not library:
            self.skipTest("HarfBuzz unavailable")
        hb = c.CDLL(library)
        declarations = {
            "hb_blob_create_from_file_or_fail": ([c.c_char_p], c.c_void_p),
            "hb_face_create": ([c.c_void_p, c.c_uint], c.c_void_p),
            "hb_font_create": ([c.c_void_p], c.c_void_p),
            "hb_buffer_create": ([], c.c_void_p),
            "hb_buffer_add_utf8": ([c.c_void_p, c.c_char_p, c.c_int, c.c_uint, c.c_int], None),
            "hb_buffer_guess_segment_properties": ([c.c_void_p], None),
            "hb_shape": ([c.c_void_p, c.c_void_p, c.c_void_p, c.c_uint], None),
            "hb_buffer_get_length": ([c.c_void_p], c.c_uint),
        }
        for name in ("blob", "face", "font", "buffer"):
            declarations[f"hb_{name}_destroy"] = ([c.c_void_p], None)
        for name, (arguments, result) in declarations.items():
            function = getattr(hb, name)
            function.argtypes, function.restype = arguments, result
        aliases = dict(re.findall(r'"([^"]+)": "([^"]+)"', (ROOT / "components/VeloraMaterialIcon.qml").read_text()))
        symbols = set()
        for name in ("components/VeloraMediaSettings.qml", "components/VeloraSettingsChoice.qml", "features/editor/SettingsMedia.qml"):
            symbols.update(re.findall(r'\b(?:icon|iconName): "([^"]+)"', (ROOT / name).read_text()))
        blob = hb.hb_blob_create_from_file_or_fail(os.fsencode(ROOT / "assets/fonts/MaterialSymbolsRounded-subset.ttf"))
        self.assertTrue(blob)
        face = hb.hb_face_create(blob, 0)
        font = hb.hb_font_create(face)
        try:
            for symbol in sorted(symbols):
                with self.subTest(symbol=symbol):
                    buffer = hb.hb_buffer_create()
                    try:
                        value = aliases.get(symbol, symbol).encode()
                        hb.hb_buffer_add_utf8(buffer, value, len(value), 0, len(value))
                        hb.hb_buffer_guess_segment_properties(buffer)
                        hb.hb_shape(font, buffer, None, 0)
                        self.assertEqual(hb.hb_buffer_get_length(buffer), 1, f"Missing icon: {symbol}")
                    finally:
                        hb.hb_buffer_destroy(buffer)
        finally:
            hb.hb_font_destroy(font)
            hb.hb_face_destroy(face)
            hb.hb_blob_destroy(blob)

    def test_groups_controls_search_responsiveness_and_reversal(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-media-settings-") as directory:
            base = Path(directory)
            for name in ("core", "features", "components", "services", "platform", "assets", "config", "shaders"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "scripts").mkdir()
            (base / "runtime").mkdir(mode=0o700)
            for source in (ROOT / "scripts").iterdir():
                if not source.is_file():
                    continue
                target = base / "scripts" / source.name
                if source.name in ("velora-theme-state", "velora-velyrics-state"):
                    target.symlink_to(source)
                else:
                    target.write_text('#!/usr/bin/env python3\nprint("{}")\n')
                    target.chmod(0o755)
            fixture = (ROOT / "tests/fixtures/settings-media.qml").read_text().replace('"../../', '"./')
            (base / "shell.qml").write_text(fixture)
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       VELORA_VALIDATE="1", XDG_RUNTIME_DIR=str(base / "runtime"),
                       XDG_CONFIG_HOME=str(base / "user-config"), XDG_STATE_HOME=str(base / "state"),
                       XDG_CACHE_HOME=str(base / "cache"), XDG_DATA_HOME=str(base / "data"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(base)], env=env, capture_output=True, text=True, timeout=26)
            output = result.stdout + result.stderr
            if os.environ.get("VELORA_MEDIA_TEST_LOG"):
                Path(os.environ["VELORA_MEDIA_TEST_LOG"]).write_text(output)
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("MEDIA_SETTINGS_OK", output)
            for error in ("MEDIA_SETTINGS_FAILED", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign"):
                self.assertNotIn(error, output)


if __name__ == "__main__":
    unittest.main()
