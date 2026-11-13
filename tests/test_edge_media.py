import os
from pathlib import Path
import subprocess
import shutil
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EdgeMediaTests(unittest.TestCase):
    def run_fixture(self, command, backend="software", extra_env=None):
        with tempfile.TemporaryDirectory(prefix="velora-edge-media-") as temporary:
            env = dict(os.environ, HOME=temporary, XDG_RUNTIME_DIR=temporary,
                       XDG_CONFIG_HOME=temporary + "/config", XDG_CACHE_HOME=temporary + "/cache",
                       XDG_STATE_HOME=temporary + "/state", XDG_DATA_HOME=temporary + "/data",
                       QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND=backend,
                       QSG_RHI_BACKEND="opengl")
            env.pop("WAYLAND_DISPLAY", None)
            env.update(extra_env or {})
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            for error in ("TypeError", "ReferenceError", "Binding loop", "QWARN", "FAILED"):
                self.assertNotIn(error, output, output)
            return output

    def test_transport_search_curved_lyrics_and_icons(self):
        self.run_fixture(["/usr/lib/qt6/bin/qmltestrunner", "-input",
                          str(ROOT / "tests/fixtures/tst_edge_media.qml")])

    def test_audio_waves_lyric_timing_and_capture_demand(self):
        self.run_fixture(["/usr/lib/qt6/bin/qmltestrunner", "-input",
                          str(ROOT / "tests/fixtures/tst_edge_waves.qml")])

    def test_whatsapp_preview_contacts_draft_and_layout(self):
        self.run_fixture(["/usr/lib/qt6/bin/qmltestrunner", "-input",
                          str(ROOT / "tests/fixtures/tst_edge_whatsapp.qml")])

    def test_rendered_artwork_preserves_native_material(self):
        self.run_fixture(["/usr/lib/qt6/bin/qmltestrunner", "-input",
                          str(ROOT / "tests/fixtures/tst_edge_media.qml"),
                          "EdgeMedia::test_backdrop_preserves_liquid_transparency",
                          "EdgeMedia::test_backdrop_top_fade_and_alignment"], backend="rhi")

    def test_hover_extension_full_height_and_demand_lifecycle(self):
        self.run_popover_fixture("EDGE_POPOVER_OK")

    def test_whatsapp_outside_input_and_contacts_drag(self):
        self.run_popover_fixture("WHATSAPP_DRAWER_OK", {"VELORA_WHATSAPP_DRAWER_CHECK": "1"})

    def run_popover_fixture(self, marker, extra_env=None):
        with tempfile.TemporaryDirectory(prefix="velora-edge-config-") as temporary:
            base = Path(temporary)
            for name in ("components", "core", "features", "services", "assets", "platform"):
                shutil.copytree(ROOT / name, base / name)
            source = (ROOT / "tests/fixtures/edge-media-popover.qml").read_text().replace('"../../', '"./')
            shell = (ROOT / "ShellController.qml").read_text()
            handlers = []
            for name in ("onActiveRailControlChanged", "onQuickPopupTypeChanged"):
                match = re.search(r"function " + name + r"\(\)\s*\{", shell)
                self.assertIsNotNone(match)
                end, depth = match.end(), 1
                while depth:
                    depth += (shell[end] == "{") - (shell[end] == "}")
                    end += 1
                handler = shell[match.start():end].replace("root.", "fixture.").replace("edgePopover.", "edge.")
                for other in ("coffee", "notes", "bluetooth", "notifications", "wifi", "media"):
                    handler = handler.replace(other + "Popover.", "otherPopover.")
                # Avoid colliding with property change signal names.
                handler = handler.replace("function on", "function handle")
                handlers.append(handler)
            source = source.replace("// SHELL_CONTROL_HANDLERS", "\n".join(handlers))
            # Exercise the production outside-click catcher above an application
            # input target, so persistence also verifies that clicks pass through.
            match = re.search(r"MouseArea\s*\{\s*id: railToolOutsideInput", shell)
            self.assertIsNotNone(match)
            end, depth = match.end(), 1
            while depth:
                depth += (shell[end] == "{") - (shell[end] == "}")
                end += 1
            outside = shell[match.start():end].replace("root.", "fixture.").replace("panel.", "win.").replace("edgePopover.", "edge.")
            outside = outside.replace("railControls.", "otherPopover.")
            for other in ("coffee", "notes", "bluetooth", "notifications", "wifi"):
                outside = outside.replace(other + "Popover.", "otherPopover.")
            source = source.replace("// SHELL_OUTSIDE_INPUT", outside)
            source = source.replace("fixture.onActiveRailControlChanged()", "fixture.handleActiveRailControlChanged()")
            source = source.replace("fixture.onQuickPopupTypeChanged()", "fixture.handleQuickPopupTypeChanged()")
            (base / "shell.qml").write_text(source)
            output = self.run_fixture(["qs", "-p", str(base)], extra_env=extra_env)
            self.assertIn(marker, output, output)


if __name__ == "__main__":
    unittest.main()
