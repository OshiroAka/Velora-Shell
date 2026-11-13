import concurrent.futures
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, call, patch

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def load_script(name="velyrics"):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / "scripts" / name))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class VelyricsTests(unittest.TestCase):
    def setUp(self):
        self.source = load_script()
        self.now = 100.0
        self.canvas = False
        self.workspace = 1
        self.windows = []
        self.settings = dict(mode="line", wordsPerTerminal=2, fontScale=1.0, fontFamily="Pixelon", syncOffsetMs=500)
        self.lyric = dict(ok=True, player="spotify", status="Playing", title="Fixture", artist="Velora",
                          duration=100, lineTime=1.0, line="First line", words=["First", "line"], activeIndex=0)
        patches = [
            patch.object(self.source.time, "monotonic", side_effect=lambda: self.now),
            patch.object(self.source, "canvas_enabled", side_effect=lambda: self.canvas),
            patch.object(self.source, "is_disabled", return_value=False),
            patch.object(self.source, "load_velyrics_settings", side_effect=lambda: self.settings),
            patch.object(self.source, "hyprctl_json", side_effect=lambda command:
                         self.windows if command == "clients" else {"id": self.workspace}),
            patch.object(self.source.subprocess, "Popen"),
        ]
        for item in patches:
            item.start()
            self.addCleanup(item.stop)
        self.coordinator = self.source.Coordinator()
        self.coordinator.executor.shutdown(wait=False)
        self.coordinator.executor = Mock()
        self.coordinator.executor.submit.side_effect = self.submit_lyrics

    def submit_lyrics(self, function):
        future = concurrent.futures.Future()
        future.set_result(dict(self.lyric))
        return future

    def add_terminal(self, address="0x1", workspace=1, floating=False, pinned=False):
        self.windows.append(dict(address=address, workspace={"id": workspace}, floating=floating, pinned=pinned))
        # Registration must accept terminals on different workspaces. Polling is
        # driven separately so asynchronous lyric results remain deterministic.
        with patch.object(self.coordinator, "update"):
            self.coordinator.handle(dict(op="register", address=address, workspace=workspace))

    def poll(self):
        self.now += 0.31
        self.coordinator.update()
        self.coordinator.update()
        return self.coordinator.response()

    def test_one_tiled_terminal_without_infinite_desktop(self):
        self.add_terminal()
        result = self.poll()
        self.assertEqual((result["status"], result["target"], result["word"]), ("active", "0x1", "First line"))
        self.assertEqual(result["sequence"], result["centeredSequence"])
        self.source.subprocess.Popen.assert_not_called()
        # The same line is not rendered repeatedly at the polling frequency.
        self.assertEqual(self.poll()["sequence"], result["sequence"])

    def test_word_groups_work_in_one_terminal_without_camera(self):
        self.add_terminal()
        self.settings["mode"] = "words"
        self.lyric.update(words=["One", "two", "three", "four"], activeIndex=0)
        first = self.poll()
        self.assertEqual(first["word"], "One two")
        self.lyric["activeIndex"] = 1
        self.assertEqual(self.poll()["sequence"], first["sequence"])
        self.lyric["activeIndex"] = 2
        second = self.poll()
        self.assertEqual(second["word"], "three four")
        self.assertEqual(second["sequence"], first["sequence"] + 1)
        self.source.subprocess.Popen.assert_not_called()

    def test_three_terminals_do_not_move_windows_with_canvas_off(self):
        for index in range(3):
            self.add_terminal(f"0x{index + 1}", floating=True)
        for index in range(3):
            self.lyric.update(lineTime=index + 1, line=f"Line {index + 1}")
            result = self.poll()
            self.assertEqual(result["target"], f"0x{index + 1}")
            self.assertEqual(result["word"], f"Line {index + 1}")
            self.assertEqual(result["sequence"], result["centeredSequence"])
        self.source.subprocess.Popen.assert_not_called()

    def test_camera_is_optional_and_stops_when_canvas_is_disabled(self):
        self.canvas = True
        self.add_terminal(floating=True)
        self.poll()
        self.source.subprocess.Popen.assert_not_called()
        self.add_terminal("0x2", floating=True)
        self.add_terminal("0x3", floating=True)
        self.lyric.update(lineTime=2, line="Second line")
        process = self.source.subprocess.Popen.return_value
        process.poll.return_value = None
        result = self.poll()
        self.assertEqual(result["status"], "active")
        self.source.subprocess.Popen.assert_called_once()
        self.assertEqual(self.source.subprocess.Popen.call_args.args[0], ["infinite-desktop", "focus-address", result["target"]])
        self.canvas = False
        self.lyric.update(lineTime=3, line="Third line")
        result = self.poll()
        process.terminate.assert_called_once()
        self.assertEqual(result["word"], "Third line")
        self.assertEqual(result["sequence"], result["centeredSequence"])
        self.source.subprocess.Popen.assert_called_once()

    def test_missing_camera_command_does_not_break_lyrics(self):
        self.canvas = True
        for index in range(3):
            self.add_terminal(f"0x{index + 1}", floating=True)
        self.source.subprocess.Popen.side_effect = FileNotFoundError()
        result = self.poll()
        self.assertEqual(result["status"], "active")
        self.assertEqual(result["word"], "First line")
        self.assertEqual(result["sequence"], result["centeredSequence"])

    def test_workspace_switch_and_moved_terminal_keep_working(self):
        self.add_terminal("0x1", workspace=1)
        self.add_terminal("0x2", workspace=2)
        self.assertEqual(self.poll()["target"], "0x1")
        self.workspace = 2
        self.lyric.update(lineTime=2, line="Workspace two")
        result = self.poll()
        self.assertEqual((result["workspace"], result["target"]), (2, "0x2"))
        # A terminal's live window workspace is authoritative after moving it.
        self.windows[1]["workspace"]["id"] = 3
        self.workspace = 3
        self.lyric.update(lineTime=3, line="Moved terminal")
        result = self.poll()
        self.assertEqual((result["target"], result["word"]), ("0x2", "Moved terminal"))

    def test_departed_target_reassigns_current_line(self):
        self.add_terminal("0x1")
        self.add_terminal("0x2")
        first = self.poll()
        self.assertEqual(first["target"], "0x1")
        self.coordinator.participants.pop("0x1")
        self.windows.pop(0)
        result = self.poll()
        self.assertEqual(result["target"], "0x2")
        self.assertEqual(result["word"], first["word"])
        self.assertEqual(result["sequence"], first["sequence"] + 1)

    def test_client_clears_disabled_text_and_redraws_same_line_after_recovery(self):
        active = dict(status="active", target="0x1", word="Fixture", sequence=1, centeredSequence=1,
                      fontScale=1.0, fontFamily="Pixelon")
        responses = [active, dict(active, status="lyrics"), active,
                     dict(active, status="disabled", fontScale=2.0), dict(active, fontScale=2.0), {}]
        with tempfile.TemporaryDirectory() as temporary, \
             patch.object(self.source, "active_terminal", return_value=dict(address="0x1", workspace=1)), \
             patch.object(self.source, "start_daemon", return_value=True), \
             patch.object(self.source, "request", side_effect=responses), \
             patch.object(self.source, "render") as render, \
             patch.object(self.source, "render_status") as status, \
             patch.object(self.source, "clear_graphics"), \
             patch.object(self.source, "WORD_IMAGE", Path(temporary) / "word.png"), \
             patch.object(self.source.time, "sleep", side_effect=[None, None, None, None, KeyboardInterrupt]), \
             patch.object(self.source.sys, "stdout", io.StringIO()):
            self.assertEqual(self.source.client(), 0)
            self.assertEqual(render.call_args_list, [call("Fixture", 1.0, "Pixelon"),
                                                    call("Fixture", 1.0, "Pixelon"), call("Fixture", 2.0, "Pixelon")])
            self.assertEqual(status.call_args_list, [call("lyrics", "", 1.0, "Pixelon"), call("disabled", "", 2.0, "Pixelon")])

    def test_missing_lyrics_are_not_reported_as_paused(self):
        self.add_terminal()
        self.lyric = dict(ok=False, player="spotify", reason="fetch-failed", words=[])
        result = self.poll()
        self.assertEqual((result["status"], result["reason"]), ("lyrics", "fetch-failed"))
        with patch.object(self.source, "render") as render:
            self.source.render_status(result["status"], result["reason"], 1.2, "FixtureFont")
            self.assertIn("tentando novamente", render.call_args.args[0])
            self.assertEqual(render.call_args.args[1:], (.6, "FixtureFont"))

    def test_status_preserves_font_and_normal_gaps_do_not_show_messages(self):
        with patch.object(self.source, "render_fallback") as fallback, patch.object(self.source, "render") as render:
            for status, reason in [("loading", ""), ("spotify", "no-player"),
                                   ("paused", ""), ("disabled", "")]:
                with self.subTest(status=status, reason=reason):
                    self.source.render_status(status, reason)
                    self.assertTrue(render.call_args.args[0])
            for reason in ["waiting-for-line", "between-lines", "empty-line"]:
                self.source.render_status("lyrics", reason)
                fallback.assert_called_with("")
            self.source.render_status("active")
            fallback.assert_called_with("")

    def test_blank_or_plain_fallback_removes_old_kitty_graphics(self):
        with patch.object(self.source, "clear_graphics") as clear, \
             patch.object(self.source.sys, "stdout", io.StringIO()):
            self.source.render_fallback("")
            clear.assert_called_once()


class LyricsMetadataTests(unittest.TestCase):
    def setUp(self):
        self.source = load_script("velora-lyrics-state")
        self.spotify = "org.mpris.MediaPlayer2.spotify"
        self.properties = {
            self.spotify: {"PlaybackStatus": "Playing", "Position": 12345000,
                           "Metadata": {"xesam:title": "Fixture", "xesam:artist": ["Velora", "Tests"],
                                        "xesam:album": "Test album", "mpris:length": 100000000}},
        }
        self.dbus = Mock()
        bus = self.dbus.SessionBus.return_value
        bus.list_names.side_effect = lambda: ["org.freedesktop.DBus", *self.properties]
        bus.get_object.side_effect = lambda name, path, **kwargs: name
        self.property_calls = []
        def get_all(name, interface, **kwargs):
            self.assertEqual(interface, "org.mpris.MediaPlayer2.Player")
            self.assertEqual(kwargs["timeout"], 2)
            self.property_calls.append(name)
            value = self.properties[name]
            if isinstance(value, Exception):
                raise value
            return value
        self.dbus.Interface.side_effect = lambda name, interface: SimpleNamespace(
            GetAll=lambda player_interface, **kwargs: get_all(name, player_interface, **kwargs))
        for item in [patch.dict("sys.modules", {"dbus": self.dbus}),
                     patch.object(self.source.shutil, "which", return_value=None),
                     patch.object(self.source.subprocess, "check_output", side_effect=AssertionError("playerctl must not be required"))]:
            item.start()
            self.addCleanup(item.stop)

    def test_missing_playerctl_reads_mpris_position_and_track(self):
        player = self.source.pick_player()
        self.assertEqual(player, self.spotify)
        meta = self.source.player_meta(player)
        self.assertEqual((meta["title"], meta["artist"], meta["album"]), ("Fixture", "Velora Tests", "Test album"))
        self.assertEqual((meta["duration"], meta["position"], meta["status"]), (100, 12.345, "Playing"))
        # GetAll is reused within the same status request.
        self.assertEqual(self.property_calls, [self.spotify])

    def test_spotify_is_preferred_and_disappearing_players_are_ignored(self):
        self.properties["org.mpris.MediaPlayer2.closed"] = RuntimeError("player closed")
        self.properties["org.mpris.MediaPlayer2.browser"] = dict(self.properties[self.spotify])
        self.assertEqual(self.source.pick_player(), self.spotify)
        self.assertEqual(self.source.player_meta(self.spotify)["status"], "Playing")
        self.properties[self.spotify]["PlaybackStatus"] = "Paused"
        self.properties["org.mpris.MediaPlayer2.browser"]["PlaybackStatus"] = "Paused"
        self.assertEqual(self.source.pick_player(), self.spotify)

    def test_cached_lyrics_flow_from_dbus_without_playerctl(self):
        self.properties[self.spotify]["Position"] = 1500000
        with tempfile.TemporaryDirectory() as temporary:
            self.source.CACHE_ROOT = temporary
            self.source.pick_player()
            meta = self.source.player_meta(self.spotify)
            self.source.write_cache(meta, dict(ok=True, syncedLyrics="[00:01.00]Original fixture line\n[00:10.00]Another fixture line"))
            with patch.object(self.source, "emit") as emit, \
                 patch("urllib.request.urlopen", side_effect=AssertionError("warm lyrics must not use network")):
                self.assertEqual(self.source.status(["--lead", "0"]), 0)
                result = emit.call_args.args[0]
                self.assertTrue(result["ok"])
                self.assertEqual(result["player"], self.spotify)
                self.assertEqual((result["status"], result["line"]), ("Playing", "Original fixture line"))

    def test_unavailable_bus_and_missing_binding_do_not_crash(self):
        self.dbus.SessionBus.side_effect = PermissionError("unavailable bus")
        self.assertEqual(self.source.pick_player(), "")
        with patch.dict("sys.modules", {"dbus": None}):
            self.assertEqual(self.source.pick_player(), "")

    def test_terminal_holds_real_verse_until_next_timestamp(self):
        self.properties[self.spotify]["Position"] = 59000000
        with tempfile.TemporaryDirectory() as temporary:
            self.source.CACHE_ROOT = temporary
            self.source.pick_player()
            meta = self.source.player_meta(self.spotify)
            self.source.write_cache(meta, dict(ok=True, syncedLyrics="[00:01.00]Original fixture line\n[01:00.00]Next fixture line"))
            with patch.object(self.source, "emit") as emit, \
                 patch("urllib.request.urlopen", side_effect=AssertionError("unexpected network")):
                for args in [["--lead", "0"], ["--hold-line", "--lead", "0"]]:
                    self.source.status(args)
                    result = emit.call_args.args[0]
                    self.assertTrue(result["ok"])
                    self.assertEqual(result["line"], "Original fixture line")
                    self.assertEqual(result["lineTime"], 1)
                # The shell's animated overlay retains its existing gap policy.
                self.source.status(["--hide-between-lines", "--lead", "0"])
                self.assertEqual(emit.call_args.args[0]["reason"], "between-lines")
                self.properties[self.spotify]["Position"] = 60000000
                self.source.status(["--hold-line", "--lead", "0"])
                self.assertEqual(emit.call_args.args[0]["line"], "Next fixture line")


class RenderedLyricsTests(unittest.TestCase):
    def test_real_gradient_graphics_with_missing_pixelon_and_selected_font(self):
        if not shutil.which("magick") or not shutil.which("fc-match"):
            self.skipTest("ImageMagick and Fontconfig required for Kitty image rendering")
        source = load_script()
        images = []
        with tempfile.TemporaryDirectory() as temporary, \
             patch.dict(os.environ, {"KITTY_WINDOW_ID": "1"}), \
             patch.object(source, "RUNTIME_DIR", Path(temporary)), \
             patch.object(source, "WORD_IMAGE", Path(temporary) / "line.png"), \
             patch.object(source, "PIXELON_FONT", Path(temporary) / "missing-pixelon.ttf"), \
             patch.object(source, "USER_PIXELON_FONT", Path(temporary) / "missing-user-pixelon.ttf"), \
             patch.object(source, "terminal_geometry", return_value=(64, 16, 640, 360)), \
             patch.object(source, "cava_lyrics_gradients", return_value=(["#f08000", "#ff4060"], ["#00c0ff", "#2040ff"])), \
             patch.object(source.sys, "stdout", io.StringIO()) as output:
            for family in ["Pixelon", "monospace"]:
                with self.subTest(family=family):
                    output.seek(0); output.truncate(0)
                    source.WORD_IMAGE.unlink(missing_ok=True)
                    source.render("Velora lyrics", 1.0, family)
                    self.assertTrue(source.WORD_IMAGE.is_file(), "must render image instead of plain text")
                    self.assertIn("\033_Ga=t", output.getvalue())
                    self.assertIn("\033_Ga=p", output.getvalue())
                    with Image.open(source.WORD_IMAGE) as image:
                        self.assertEqual(image.size, (640, 360))
                        self.assertEqual(image.getchannel("A").getextrema(), (0, 255))
                        pixels = [pixel[:3] for _, pixel in image.getcolors(640 * 360) if pixel[3] > 240]
                        self.assertGreater(len(set(pixels)), 20, "CAVA gradient must remain visible in the glyphs")
                        images.append(image.tobytes())
            self.assertNotEqual(images[0], images[1], "selected font must affect the rendered glyphs")

    def test_word_swap_uploads_before_one_synchronized_commit(self):
        source = load_script()
        with tempfile.TemporaryDirectory() as temporary, patch.object(source.sys, "stdout", io.StringIO()) as output:
            path = Path(temporary) / "word.png"; path.write_bytes(b"fixture-image-data" * 600)
            self.assertTrue(source.show_kitty_image(path, 64, 16))
            first_id = source._displayed_image_id
            output.seek(0); output.truncate(0)
            self.assertTrue(source.show_kitty_image(path, 64, 16))
            stream = output.getvalue()
            next_id = source._displayed_image_id
            self.assertNotEqual(first_id, next_id)
            prepare, commit = stream.split("\033[?2026h")
            self.assertIn(f"a=t,f=100,t=d,q=2,i={next_id}", prepare)
            self.assertNotIn("a=d", prepare)
            self.assertNotIn("\033[2J", prepare)
            self.assertNotIn("\033[2J", commit)
            self.assertLess(commit.index(f"a=p,i={next_id}"), commit.index(f"a=d,d=I,i={first_id}"))
            self.assertTrue(commit.endswith("\033[?2026l"))

    def test_native_kitty_parser_keeps_uploaded_words_and_visible_placements(self):
        kitty = shutil.which("kitty")
        if not kitty:
            self.skipTest("Kitty is required to validate its actual graphics parser")
        source = load_script()
        with tempfile.TemporaryDirectory() as temporary, patch.object(source.sys, "stdout", io.StringIO()) as output:
            directory = Path(temporary)
            frames = []
            # Noise avoids compressing the PNG to one small chunk, so Kitty
            # must receive and decode the real multi-chunk continuation stream.
            for index in range(3):
                png = directory / f"word-{index}.png"
                with Image.effect_noise((128, 96), 80).convert("RGBA") as image:
                    image.save(png)
                output.seek(0); output.truncate(0)
                source.show_kitty_image(png, 64, 16)
                payload = output.getvalue().encode()
                self.assertGreater(payload.count(b"\033_G"), 3)
                stream = directory / f"word-{index}.stream"; stream.write_bytes(payload)
                frames.append(dict(path=str(stream), id=source._displayed_image_id, width=128, height=96))
            manifest = directory / "frames.json"; manifest.write_text(json.dumps(frames))
            fixture = ROOT / "tests/fixtures/velyrics-kitty-parser.py"
            code = "import sys; sys.argv=" + repr([str(fixture), str(manifest)]) + "; exec(compile(open(" + repr(str(fixture)) + ").read()," + repr(str(fixture)) + ",'exec'),{})"
            result = subprocess.run([kitty, "+runpy", code], capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("KITTY_GRAPHICS_PASS", result.stdout)


if __name__ == "__main__":
    unittest.main()
