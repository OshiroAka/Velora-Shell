"""Profile menu pointer actions, capture sequencing, morphs and isolated helpers."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ProfileMenuTests(unittest.TestCase):
    def test_real_menu_controls_capture_and_morph(self):
        if not shutil.which("qs"):
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-profile-test-") as temporary:
            base = Path(temporary)
            for name in ("core", "features", "components", "services", "platform", "assets"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            shutil.copy2(ROOT/"tests/fixtures/profile-menu.qml", base/"shell.qml")
            (base/"runtime").mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=str(base/"runtime"), XDG_CONFIG_HOME=str(base/"config"),
                       XDG_CACHE_HOME=str(base/"cache"), XDG_DATA_HOME=str(base/"data"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(["qs", "-p", str(base)], env=env, text=True, capture_output=True, timeout=30)
            output = result.stdout + result.stderr
            if os.environ.get("PROFILE_TEST_LOG"):
                Path(os.environ["PROFILE_TEST_LOG"]).write_text(output)
            self.assertIn("PROFILE_MENU_OK", output, output)
            for error in ("PROFILE_MENU_FAILED", "FAIL!", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign", "is not a type"):
                self.assertNotIn(error, output)

    def test_helpers_use_arguments_and_copy_real_results(self):
        with tempfile.TemporaryDirectory(prefix="velora-profile-tools-") as temporary:
            base=Path(temporary); (base/"bin").mkdir(); log=base/"calls.jsonl"
            mock='''#!/usr/bin/env python3
import json,os,pathlib,signal,sys,time
name=pathlib.Path(sys.argv[0]).name
args=sys.argv[1:]
with open(os.environ['CALL_LOG'],'a') as f:f.write(json.dumps([name,args])+'\\n')
if name=='slurp': print('10,20 300x200')
elif name=='tesseract':
    print('por\\neng' if '--list-langs' in args else 'Texto reconhecido')
elif name=='hyprpicker': print('#abcdef')
elif name=='magick': print('#123456',end='')
elif name=='wl-copy':
    pathlib.Path(os.environ['COPY_FILE']).write_bytes(sys.stdin.buffer.read())
elif name=='wf-recorder':
    signal.signal(signal.SIGINT,lambda *_:sys.exit(0))
    pathlib.Path(os.environ['RECORD_READY']).touch()
    while True:time.sleep(.01)
'''
            for name in ("grim","slurp","wl-copy","tesseract","hyprpicker","magick","wf-recorder","notify-send"):
                file=base/"bin"/name; file.write_text(mock);file.chmod(0o755)
            env=dict(os.environ,HOME=str(base),PATH=str(base/"bin")+":"+os.environ["PATH"],
                     CALL_LOG=str(log),COPY_FILE=str(base/"clipboard"),RECORD_READY=str(base/"ready"))
            helper=["python3",str(ROOT/"scripts/velora-profile-tools")]
            status=subprocess.run(helper+["status"],env=env,text=True,capture_output=True,check=True)
            self.assertTrue(all(item['available'] for item in json.loads(status.stdout).values()))
            for action,value in (("text",b"Texto reconhecido\n"),("eyedropper",b"#abcdef")):
                result=subprocess.run(helper+[action],env=env,text=True,capture_output=True,timeout=8)
                self.assertEqual(result.returncode,0,result.stderr)
                self.assertEqual((base/"clipboard").read_bytes(),value)
            calls=[json.loads(line) for line in log.read_text().splitlines()]
            self.assertTrue(any(name=='grim' and args[:2]==['-g','10,20 300x200'] for name,args in calls))
            self.assertTrue(any(name=='tesseract' and args[-2:]==['-l','por+eng'] for name,args in calls))
            # Exercise the picker fallback used on systems without hyprpicker.
            (base/"bin/hyprpicker").unlink()
            result=subprocess.run(helper+["eyedropper"],env=env,text=True,capture_output=True,timeout=8)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual((base/"clipboard").read_bytes(),b"#123456")
            calls=[json.loads(line) for line in log.read_text().splitlines()]
            self.assertIn(["slurp",["-p"]],calls)
            import signal,time
            process=subprocess.Popen(helper+["record"],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            try:
                deadline=time.monotonic()+3
                while not (base/"ready").exists() and time.monotonic()<deadline:time.sleep(.02)
                self.assertTrue((base/"ready").exists())
                process.send_signal(signal.SIGINT)
                out,error=process.communicate(timeout=4)
                self.assertEqual(process.returncode,0,error)
            finally:
                if process.poll() is None:process.kill();process.wait()

    def test_missing_dependencies_and_cancel_do_not_copy(self):
        import sys
        with tempfile.TemporaryDirectory(prefix="velora-profile-cancel-") as temporary:
            base=Path(temporary)
            (base/"python3").symlink_to(sys.executable)
            for name in ("slurp","grim","wl-copy"):
                file=base/name
                file.write_text("#!/usr/bin/env python3\nimport sys\nraise SystemExit(1)\n")
                file.chmod(0o755)
            env=dict(os.environ,HOME=str(base),PATH=str(base))
            helper=[sys.executable,str(ROOT/"scripts/velora-profile-tools")]
            state=json.loads(subprocess.check_output(helper+["status"],env=env,text=True))
            self.assertFalse(state["text"]["available"])
            self.assertEqual(state["text"]["missing"],["tesseract"])
            failed=subprocess.run(helper+["text"],env=env,capture_output=True,text=True)
            self.assertEqual(failed.returncode,1);self.assertIn("tesseract",failed.stderr)
            # The selection is canceled; neither OCR nor copying may run.
            file=base/"tesseract";file.write_text("#!/usr/bin/env python3\nraise RuntimeError('must not run')\n");file.chmod(0o755)
            canceled=subprocess.run(helper+["text"],env=env,capture_output=True,text=True)
            self.assertEqual(canceled.returncode,0,canceled.stderr)


if __name__ == "__main__":
    unittest.main()
