"""Real hover, focus, profile initials and navigation signals for Credits."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CreditsTests(unittest.TestCase):
    def test_supplied_names_and_biography_have_bundled_glyphs(self):
        import ctypes as c
        import ctypes.util
        hb = c.CDLL(ctypes.util.find_library("harfbuzz"))
        declarations = {
            "hb_blob_create_from_file_or_fail": ([c.c_char_p], c.c_void_p),
            "hb_face_create": ([c.c_void_p, c.c_uint], c.c_void_p),
            "hb_font_create": ([c.c_void_p], c.c_void_p),
            "hb_font_get_nominal_glyph": ([c.c_void_p, c.c_uint, c.POINTER(c.c_uint)], c.c_int),
        }
        for name in ("blob", "face", "font"):
            declarations[f"hb_{name}_destroy"] = ([c.c_void_p], None)
        for name, (arguments, result) in declarations.items():
            function = getattr(hb, name)
            function.argtypes, function.restype = arguments, result
        text = "𝕆𝕤𝕙𝕚𝕣𝕠_なかの|𝘏𝘈𝘙𝘜✩°｡⋆ 💞🪽⋆｡°✩𝘛𝘦𝘤𝘩 𝘦𝘥𝘪𝘵𝘰𝘳 𝘸𝘪𝘵𝘩 𝘙𝘰𝘹𝘺 𝘵𝘦𝘢𝘮✩°｡⋆📱💻"
        groups = {
            "CreditsKana.ttf": "なかの｡|",
            "NotoColorEmoji.ttf": "💞🪽📱💻",
            "CreditsSymbols.otf": "".join(character for character in text
                if 0x1d400 <= ord(character) <= 0x1d7ff or character in "✩°⋆"),
        }
        for filename, characters in groups.items():
            blob = hb.hb_blob_create_from_file_or_fail(os.fsencode(ROOT/"assets/fonts"/filename))
            self.assertTrue(blob, filename)
            face = hb.hb_face_create(blob, 0)
            font = hb.hb_font_create(face)
            try:
                for character in set(characters):
                    with self.subTest(font=filename, character=character):
                        glyph = c.c_uint()
                        self.assertTrue(hb.hb_font_get_nominal_glyph(font, ord(character), c.byref(glyph)))
                        self.assertNotEqual(glyph.value, 0)
            finally:
                hb.hb_font_destroy(font);hb.hb_face_destroy(face);hb.hb_blob_destroy(blob)

    def test_profiles_slide_focus_reduced_motion_and_compact_layout(self):
        with tempfile.TemporaryDirectory(prefix="velora-credits-") as directory:
            env = dict(os.environ, HOME=directory, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=directory, XDG_CONFIG_HOME=directory+"/config",
                       XDG_DATA_HOME=directory+"/data", XDG_STATE_HOME=directory+"/state",
                       XDG_CACHE_HOME=directory+"/cache", DBUS_SESSION_BUS_ADDRESS="unix:path="+directory+"/no-bus")
            for key in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(key, None)
            fixture = (ROOT/"tests/fixtures/tst_credits.qml").read_text().replace('"../../', '"'+ROOT.as_uri()+'/')
            if os.environ.get("VELORA_CREDITS_EVIDENCE"):
                import json
                fixture = fixture.replace('property string evidenceDirectory: ""',
                    'property string evidenceDirectory: '+json.dumps(os.environ["VELORA_CREDITS_EVIDENCE"]))
            test_file = Path(directory)/"tst_credits.qml"
            test_file.write_text(fixture)
            command = ["/usr/lib/qt6/bin/qmltestrunner", "-input", str(test_file)]
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=18)
            output = result.stdout+result.stderr
            if os.environ.get("VELORA_CREDITS_TEST_LOG"):
                Path(os.environ["VELORA_CREDITS_TEST_LOG"]).write_text(output)
            self.assertEqual(result.returncode, 0, output)
            for error in ("QWARN", "FAIL!", "TypeError:", "ReferenceError:", "Binding loop"):
                self.assertNotIn(error, output)
