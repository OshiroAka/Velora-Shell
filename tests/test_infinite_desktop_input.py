import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InfiniteDesktopInputTests(unittest.TestCase):
    def test_scroll_and_right_drag_flush_motion_even_before_bridge_ready(self):
        with tempfile.TemporaryDirectory(prefix="velora-infinite-input-") as directory:
            base=Path(directory)
            (base/'components').symlink_to(ROOT/'components',target_is_directory=True)
            (base/'shell.qml').write_text((ROOT/'tests/fixtures/infinite-desktop-input.qml').read_text().replace('"../../','"./'))
            helper=base/'bridge'
            helper.write_text('''#!/usr/bin/env python3
import os,time,sys,json
time.sleep(.4)
print("READY",flush=True)
records=[]
for line in sys.stdin:
    records.append(line.strip())
    if line.strip()=="END":break
with open(os.environ["VELORA_INPUT_LOG"],"a") as output:output.write(json.dumps(records)+"\\n")
''')
            helper.chmod(0o755)
            env=dict(os.environ,HOME=directory,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',
                VELORA_VALIDATE='1',VELORA_TEST_BRIDGE=str(helper),VELORA_INPUT_LOG=str(base/'records'),
                XDG_RUNTIME_DIR=directory,XDG_CONFIG_HOME=directory+'/config',XDG_STATE_HOME=directory+'/state',
                XDG_CACHE_HOME=directory+'/cache',DBUS_SESSION_BUS_ADDRESS='unix:path=/nonexistent')
            for name in ('WAYLAND_DISPLAY','DISPLAY','HYPRLAND_INSTANCE_SIGNATURE'):env.pop(name,None)
            result=subprocess.run(['qs','-p',directory],env=env,text=True,capture_output=True,timeout=8)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn('INFINITE_INPUT_OK',output)
            for error in ('FAILED','TypeError','ReferenceError','Binding loop'):self.assertNotIn(error,output)
            records=[json.loads(line) for line in (base/'records').read_text().splitlines()]
            self.assertEqual(records,[['MOVE 15.000 -2.000','END'],['MOVE 30.000 20.000','END']])
