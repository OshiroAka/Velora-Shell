import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import wave
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class WhatsAppBridgeTests(unittest.TestCase):
    def test_session_survives_process_exit_and_resumes_without_pairing(self):
        if not (ROOT / "integrations/whatsapp/node_modules/baileys").is_dir():
            self.skipTest("Install the optional WhatsApp bridge dependencies first")
        with tempfile.TemporaryDirectory(prefix="velora-whatsapp-resume-") as temporary:
            worker = ROOT / "integrations/whatsapp/test/session-worker.mjs"
            for mode in ("seed", "resume", "resume"):
                result = subprocess.run(["node", "--disable-warning=ExperimentalWarning", str(worker), mode, temporary],
                                        capture_output=True, text=True, timeout=15)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("SESSION_" + mode.upper() + "_OK", result.stdout)

    def test_pairing_receiving_and_sqlite_session_persistence(self):
        if not (ROOT / "integrations/whatsapp/node_modules/baileys").is_dir():
            self.skipTest("Install the optional WhatsApp bridge dependencies first")
        result = subprocess.run(["node", "--disable-warning=ExperimentalWarning", "--test",
                                 str(ROOT / "integrations/whatsapp/test/client.test.mjs")],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_bridge_starts_without_pairing_and_never_exports_auth_keys(self):
        if not (ROOT / "integrations/whatsapp/node_modules/baileys").is_dir():
            self.skipTest("Install the optional WhatsApp bridge dependencies first")
        with tempfile.TemporaryDirectory(prefix="velora-whatsapp-state-") as temporary:
            environment = dict(os.environ, XDG_STATE_HOME=temporary)
            result = subprocess.run([str(ROOT / "scripts/velora-whatsapp")],
                                    input='{"action":"status"}\n', capture_output=True,
                                    text=True, env=environment, timeout=20)
            self.assertEqual(result.returncode, 0, result.stderr)
            events = [json.loads(line) for line in result.stdout.splitlines()]
            self.assertGreaterEqual(len(events), 2)
            self.assertTrue(all(event["state"] == "idle" and not event["hasSession"] for event in events))
            for secret in ("noiseKey", "signedIdentityKey", "advSecretKey", "signedPreKey"):
                self.assertNotIn(secret, result.stdout)
            self.assertFalse((Path(temporary) / "velora-shell/whatsapp/client.lock").exists())

    def test_pairing_interface_and_received_messages(self):
        with tempfile.TemporaryDirectory(prefix="velora-whatsapp-qml-") as temporary:
            base = Path(temporary)
            Image.new('RGBA',(512,512),(240,130,40,255)).save(base/'sticker.webp','WEBP',save_all=True,
                append_images=[Image.new('RGBA',(512,512),(40,130,240,255))],duration=[100,100],loop=0)
            Image.new('RGBA',(256,256),(240,130,40,255)).save(base/'sticker.gif','GIF',save_all=True,
                append_images=[Image.new('RGBA',(256,256),(40,130,240,255))],duration=[100,100],loop=0)
            for name in ("components", "services", "core", "assets", "platform", "features"):
                shutil.copytree(ROOT / name, base / name)
            source = (ROOT / "tests/fixtures/whatsapp-service.qml").read_text().replace('"../../', '"./')
            with wave.open(str(base / "audio.wav"), "wb") as audio:
                audio.setnchannels(1); audio.setsampwidth(2); audio.setframerate(8000)
                audio.writeframes(b'\0\0' * 8000 * 3)
            video = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", "lavfi", "-i",
                                    "color=c=black:s=160x90:d=3", "-c:v", "libx264", "-pix_fmt", "yuv420p",
                                    str(base / "video.mp4")], capture_output=True, text=True, timeout=15)
            self.assertEqual(video.returncode, 0, video.stderr)
            source = source.replace("AUDIO_FIXTURE_URL", (base / "audio.wav").as_uri()).replace("VIDEO_FIXTURE_URL", (base / "video.mp4").as_uri())
            source = source.replace("STICKER_FIXTURE_URL",(base/'sticker.webp').as_uri())
            source = source.replace("STICKER_PREVIEW_URL",(base/'sticker.gif').as_uri())
            (base / "shell.qml").write_text(source)
            environment = dict(os.environ, HOME=temporary, XDG_RUNTIME_DIR=temporary,
                               XDG_STATE_HOME=temporary + "/state", XDG_CONFIG_HOME=temporary + "/config",
                               XDG_DATA_HOME=temporary + "/data", XDG_CACHE_HOME=temporary + "/cache",
                               QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
            environment.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(["qs", "-p", str(base)], capture_output=True, text=True,
                                    env=environment, timeout=30)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("WHATSAPP_CONNECTION_OK", output)
            for error in ("FAILED", "TypeError", "ReferenceError", "Binding loop", "QWARN"):
                self.assertNotIn(error, output)

    def test_a_second_instance_cannot_replace_the_active_session(self):
        if not (ROOT / "integrations/whatsapp/node_modules/baileys").is_dir():
            self.skipTest("Install the optional WhatsApp bridge dependencies first")
        with tempfile.TemporaryDirectory(prefix="velora-whatsapp-owner-") as temporary:
            environment = dict(os.environ, XDG_STATE_HOME=temporary)
            first = subprocess.Popen([str(ROOT / "scripts/velora-whatsapp")],
                                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                     text=True, env=environment)
            try:
                import select
                readable, _, _ = select.select([first.stdout], [], [], 10)
                self.assertTrue(readable, "The first client did not start")
                self.assertEqual(json.loads(first.stdout.readline())["state"], "idle")
                second = subprocess.run([str(ROOT / "scripts/velora-whatsapp")],
                                        input='{"action":"status"}\n', capture_output=True, text=True,
                                        env=environment, timeout=10)
                self.assertEqual(second.returncode, 1)
                self.assertEqual(json.loads(second.stdout)["code"], "client_running")
                self.assertIsNone(first.poll(), "The second client must preserve the first")
            finally:
                first.communicate(input="", timeout=10)


if __name__ == "__main__":
    unittest.main()
