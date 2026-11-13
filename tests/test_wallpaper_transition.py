import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class WallpaperTransitionTests(unittest.TestCase):
    def shell_function(self, name):
        source = (ROOT / "scripts/velora-wallpaper-apply").read_text()
        match = re.search(r"^" + name + r"\(\) \{.*?^\}", source, re.M | re.S)
        self.assertIsNotNone(match, name)
        return match.group(0)

    def test_picker_and_profiles_apply_directly_without_captures(self):
        with tempfile.TemporaryDirectory(prefix="velora-wallpaper-direct-") as temporary:
            base = Path(temporary)
            commands = base / "bin"; commands.mkdir()
            log = base / "events"
            image = base / "old.png"; Image.new("RGB", (32, 32), "red").save(image)
            video = base / "old.mp4"; video.write_bytes(b"fixture-video")
            shims = {
                "qs": '''printf '%s\\n' "$*" >> "$TEST_EVENTS"
printf '%s\\n' "${TEST_AVAILABLE:-native}"''',
                "hyprctl": '''if [ "$1" = dispatch ]; then
  printf '%s\\n' "$*" >> "$TEST_EVENTS"
  printf '%s\\n' "${TEST_NATIVE_RESULT:-ok}"
else printf '[{"name":"eDP-1"}]\\n'; fi''',
                "awww": '''printf 'backend %s\\n' "$*" >> "$TEST_EVENTS"
exit "${TEST_BACKEND_FAIL:-0}"''',
                "awww-daemon": "exit 0",
                "python3": '''if [ "${2:-}" = --capture-frame ]; then exit 99
elif [ "${2:-}" = --wait-ready ]; then printf 'frame_ready\\n' >> "$TEST_EVENTS"
else exec /usr/bin/python3 "$@"; fi''',
                "systemctl": "exit 0",
                "systemd-run": '''printf 'new_player %s\\n' "$*" >> "$TEST_EVENTS"''',
                "mpvpaper": "exit 0", "pgrep": "exit 0",
            }
            for name, body in shims.items():
                path = commands / name
                path.write_text("#!/usr/bin/env bash\n" + body + "\n"); path.chmod(0o755)
            env = dict(os.environ, HOME=temporary, XDG_CACHE_HOME=str(base / "cache"),
                       XDG_RUNTIME_DIR=str(base / "runtime"), TEST_EVENTS=str(log),
                       PATH=str(commands) + os.pathsep + os.environ["PATH"])
            functions = "\n".join(self.shell_function(name) for name in
                                  ("prepare_wallpaper_wave", "static_wallpaper", "live_wallpaper"))
            script = '''set -euo pipefail
source "$1"
event() { printf '%s\\n' "$*" >> "$TEST_EVENTS"; }
static_display_image() { printf '%s' "$1"; }
for name in stop_engine_wallpapers stop_transition_preloader stop_static_wallpapers stop_swww_wallpapers stop_mpv_wallpapers start_awww_daemon apply_theme_async; do
  eval "$name() { event $name; }"
done
reuse_mpv_wallpapers() { event load_new; [ "$previous_wallpaper_kind" = live ]; }
start_mpv_wallpaper() { event start_new; }
wait_mpv_wallpapers_ready() { event frame_ready; }
wait_for_wallpaper_process() { return 0; }
show_static_fallback() { event unwanted_preview; return 1; }
cancel_wallpaper_wave() { wallpaper_transition_cancel; }
reveal_wallpaper_wave() { wallpaper_transition_reveal; }
restore_mode=0; live_transition_mode=shader; transition=wave; transition_duration=3
static_apply_delay=0; live_fallback_duration=.15; live_fallback_ready_delay=0; live_reveal_delay=0
kind=$2; previous_wallpaper_kind=$3; previous_wallpaper_path=$4; theme_path=$4
trap wallpaper_transition_cancel EXIT
''' + functions + '''
if [ "$kind" = static ]; then static_wallpaper "$4"; else live_wallpaper "$4"; fi
event committed
'''
            scenarios = [("static", "static", image), ("live", "static", image),
                         ("live", "live", video), ("static", "live", video)]
            for target, old_kind, outgoing in scenarios:
                with self.subTest(target=target, old_kind=old_kind):
                    log.write_text("")
                    result = subprocess.run(["bash", "-c", script, "test", str(ROOT / "scripts/wallpaper-transition.sh"),
                                             target, old_kind, str(outgoing)], env=env, text=True, capture_output=True, timeout=1)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    events = log.read_text()
                    uses_gpu = target == "live" or old_kind == "live"
                    backend = "backend img" if target == "static" else "load_new"
                    self.assertNotIn("capture", events)
                    self.assertNotIn("unwanted_preview", events)
                    if uses_gpu:
                        self.assertLess(events.index("velora-blur:wallpaper-transition prepare"), events.index(backend))
                        self.assertLess(events.index(backend), events.index("velora-blur:wallpaper-transition reveal"))
                    else:
                        self.assertNotIn("wallpaperNativeTransition", events)
                    if target == "static":
                        self.assertIn("--transition-type " + ("none" if uses_gpu else "wave"), events)
                    if target == "live" and old_kind == "static":
                        self.assertLess(events.index("frame_ready"), events.index("stop_static_wallpapers"))
                    if target == "live" and old_kind == "live": self.assertNotIn("start_new", events)
                    self.assertIn("committed", events)
            log.write_text(""); env["TEST_BACKEND_FAIL"] = "1"
            result = subprocess.run(["bash", "-c", script, "test", str(ROOT / "scripts/wallpaper-transition.sh"),
                                     "static", "live", str(video)], env=env, text=True, capture_output=True, timeout=1)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("committed", log.read_text())
            self.assertIn("velora-blur:wallpaper-transition cancel", log.read_text())
            env.pop("TEST_BACKEND_FAIL"); env["TEST_AVAILABLE"] = "false"; log.write_text("")
            result = subprocess.run(["bash", "-c", script, "test", str(ROOT / "scripts/wallpaper-transition.sh"),
                                     "live", "live", str(video)], env=env, text=True, capture_output=True, timeout=1)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("committed", log.read_text())
            self.assertNotIn("unwanted_preview", log.read_text())
            self.assertNotIn("velora-blur:wallpaper-transition reveal", log.read_text())
            env.pop("TEST_AVAILABLE")
            subprocess.run([str(ROOT / "scripts/velora-theme-state"), "wallpaper-transition", "set", "wave", "0.15", "0"],
                           env=env, check=True, text=True, capture_output=True)
            next_image = base / "next.png"; Image.new("RGB", (32, 32), "blue").save(next_image)
            next_video = base / "next.mp4"; next_video.write_bytes(b"different-fixture-video")
            state = base / "cache/velora-shell/current_wallpaper"
            state.parent.mkdir(parents=True, exist_ok=True)
            for target, old_kind, outgoing in scenarios:
                with self.subTest(profile_target=target, old_kind=old_kind):
                    log.write_text(""); state.write_text(f"{old_kind}|{outgoing}|{outgoing}\n")
                    target_path = next_image if target == "static" else next_video
                    result = subprocess.run([str(ROOT / "scripts/velora-composition-wallpaper-apply"), str(target_path)],
                                            env=env, text=True, capture_output=True, timeout=2)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    events = log.read_text(); uses_gpu = target == "live" or old_kind == "live"
                    if uses_gpu:
                        self.assertIn("velora-blur:wallpaper-transition prepare", events)
                        self.assertIn("velora-blur:wallpaper-transition reveal", events)
                    else: self.assertNotIn("wallpaperNativeTransition", events)
                    self.assertIn(str(target_path), state.read_text())
                    if target == "static": self.assertIn("--transition-type " + ("none" if uses_gpu else "wave"), events)
                    else: self.assertLess(events.index("frame_ready"), events.index("velora-blur:wallpaper-transition reveal"))
                    self.assertNotIn("capture", events); self.assertNotIn("preload", events)
            alias = base / "alias.mp4"; shutil.copy(next_video, alias)
            state.write_text(f"live|{next_video}|{next_video}\n"); log.write_text("")
            result = subprocess.run([str(ROOT / "scripts/velora-composition-wallpaper-apply"), str(alias)],
                                    env=env, text=True, capture_output=True, timeout=2)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("wallpaperNativeTransition", log.read_text()); self.assertNotIn("new_player", log.read_text())

    def test_native_handoff_returns_without_waiting_for_animation(self):
        with tempfile.TemporaryDirectory(prefix="velora-wallpaper-native-") as temporary:
            base = Path(temporary); commands = base / "bin"; commands.mkdir()
            image = base / "old.png"; Image.new("RGB", (32, 32), "red").save(image)
            log = base / "events"; qs = commands / "qs"
            qs.write_text('''#!/usr/bin/env bash
printf '%s\\n' "$*" >> "$TEST_EVENTS"
printf '%s\\n' "${TEST_AVAILABLE:-native}"
'''); qs.chmod(0o755)
            hyprctl = commands / "hyprctl"
            hyprctl.write_text('''#!/usr/bin/env bash
printf '%s\\n' "$*" >> "$TEST_EVENTS"
printf '%s\\n' "${TEST_NATIVE_RESULT:-ok}"
'''); hyprctl.chmod(0o755)
            env = dict(os.environ, HOME=temporary, TEST_EVENTS=str(log), PATH=str(commands) + os.pathsep + os.environ["PATH"])
            script = 'source "$1"\nwallpaper_transition_prepare static "$2" wave 3 && wallpaper_transition_reveal'
            started = time.monotonic()
            result = subprocess.run(["bash", "-c", script, "test", str(ROOT / "scripts/wallpaper-transition.sh"), str(image)],
                                    env=env, text=True, capture_output=True, timeout=1)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertLess(time.monotonic() - started, .75)
            self.assertIn("velora-blur:wallpaper-transition reveal", log.read_text()); self.assertNotIn("cancel", log.read_text())
            self.assertEqual(list(base.glob("**/*.ready")), [])
            self.assertEqual(list(base.glob("**/*-static.png")), [])
            log.write_text(""); env["TEST_AVAILABLE"] = "false"
            result = subprocess.run(["bash", "-c", script, "test", str(ROOT / "scripts/wallpaper-transition.sh"), str(image)],
                                    env=env, text=True, capture_output=True, timeout=1)
            self.assertNotEqual(result.returncode, 0); self.assertNotIn("reveal", log.read_text())
            # An IPC command can exit successfully yet report a native error.
            # Cancel any late preparation and apply the real wallpaper directly.
            env.pop("TEST_AVAILABLE"); env["TEST_NATIVE_RESULT"] = "snapshot failed"; log.write_text("")
            result = subprocess.run(["bash", "-c", script, "test", str(ROOT / "scripts/wallpaper-transition.sh"), str(image)],
                                    env=env, text=True, capture_output=True, timeout=1)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("velora-blur:wallpaper-transition cancel", log.read_text())
            self.assertNotIn("velora-blur:wallpaper-transition reveal", log.read_text())
            env.pop("TEST_NATIVE_RESULT"); env["TEST_AVAILABLE"] = "lua"; log.write_text("")
            result = subprocess.run(["bash", "-c", script, "test", str(ROOT / "scripts/wallpaper-transition.sh"), str(image)],
                                    env=env, text=True, capture_output=True, timeout=1)
            self.assertEqual(result.returncode, 0, result.stderr)
            events = log.read_text()
            self.assertIn('hl.plugin.velora.dispatch("wallpaper-transition","prepare ', events)
            self.assertIn('wave 3000") end', events)
            self.assertIn('hl.plugin.velora.dispatch("wallpaper-transition","reveal ', events)

    def test_compositor_timing_does_not_depend_on_video_frames(self):
        source = '''#include "WallpaperTransition.hpp"
#include <cassert>
int main() {
    using T = SWallpaperTransitionTiming;
    const auto start = T::Clock::now(); T transition;
    transition.token = "123-1"; transition.duration = .5F; transition.prepared = start;
    assert(transition.progress(start) == 0.F);
    assert(!transition.expired(start + std::chrono::seconds(4)));
    assert(transition.expired(start + std::chrono::seconds(5)));
    transition.revealing = true; transition.started = start;
    const auto middle = transition.progress(start + std::chrono::milliseconds(250));
    assert(middle > .49F && middle < .51F);
    assert(transition.progress(start + std::chrono::milliseconds(500)) == 1.F);
    assert(transition.expired(start + std::chrono::milliseconds(500)));
    assert(transition.matches("123-1")); transition.token = "456-1";
    assert(!transition.matches("123-1")); assert(transition.matches("456-1"));
}
'''
        with tempfile.TemporaryDirectory(prefix="velora-wallpaper-clock-") as temporary:
            path = Path(temporary); (path / "clock.cpp").write_text(source)
            subprocess.run(["c++", "-std=c++20", "-I", str(ROOT / "native/hyprland"), str(path / "clock.cpp"),
                            "-o", str(path / "clock")], check=True, capture_output=True, text=True)
            subprocess.run([str(path / "clock")], check=True, capture_output=True, text=True)

    def test_native_shader_pixels_and_compositing(self):
        flags = subprocess.run(["pkg-config", "--cflags", "--libs", "egl", "glesv2"], text=True, capture_output=True, check=True)
        with tempfile.TemporaryDirectory(prefix="velora-wallpaper-egl-") as temporary:
            binary = Path(temporary) / "wallpaper-render"
            result = subprocess.run(["c++", "-std=c++20", str(ROOT / "tests/fixtures/wallpaper-transition.cpp"), "-o", str(binary),
                                     *flags.stdout.split()], text=True, capture_output=True, timeout=60)
            self.assertEqual(result.returncode, 0, result.stderr)
            header = (ROOT / "native/hyprland/WallpaperTransition.hpp").read_text()
            fragment = re.search(r'WALLPAPER_TRANSITION_FRAGMENT = R"GLSL\((.*?)\)GLSL";', header, re.S).group(1)
            shader = Path(temporary) / "wallpaper.frag"; shader.write_text(fragment)
            env = dict(os.environ, EGL_PLATFORM="surfaceless", LIBGL_ALWAYS_SOFTWARE="1")
            result = subprocess.run([str(binary), str(shader)], env=env, text=True, capture_output=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__": unittest.main()
