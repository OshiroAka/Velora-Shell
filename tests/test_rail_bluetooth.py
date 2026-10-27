import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RailBluetoothTests(unittest.TestCase):
    def test_connect_disconnect_and_real_bluez_failure_status(self):
        with tempfile.TemporaryDirectory(prefix="velora-bluetooth-control-") as temporary:
            base=Path(temporary)
            mock=base/"bluetoothctl"
            state=base/"state.json"
            log=base/"commands.jsonl"
            mock.write_text('''#!/usr/bin/env python3
import json,os,pathlib,sys
state=pathlib.Path(os.environ["MOCK_BT_STATE"])
data=json.loads(state.read_text())
args=sys.argv[1:]
with pathlib.Path(os.environ["MOCK_BT_LOG"]).open("a") as stream: stream.write(json.dumps(args)+"\\n")
if args[:1]==["--timeout"]: args=args[2:]
action=args[0]
if action=="show": print("Powered: "+("yes" if data["powered"] else "no"))
elif action=="info":
    print("Device 84:AC:60:25:4E:9C")
    for key in ["paired","bonded","trusted","connected"]: print("\\t"+key.title()+": "+("yes" if data.get(key,False) else "no"))
elif action=="power": data["powered"]=args[1]=="on"
elif action=="trust": data["trusted"]=True
elif action=="connect":
    if data.get("fail"): print("Failed to connect: org.bluez.Error.Failed br-connection-page-timeout")
    else: data["connected"]=True; print("Connection successful")
elif action=="disconnect":
    if data.get("fail"): print("Failed to disconnect: org.bluez.Error.Failed")
    else: data["connected"]=False; print("Disconnection successful")
else: raise RuntimeError("Unexpected operation: "+str(args))
state.write_text(json.dumps(data))
''')
            mock.chmod(0o700)
            env=dict(os.environ,PATH=str(base)+":"+os.environ['PATH'],HOME=str(base),
                     MOCK_BT_STATE=str(state),MOCK_BT_LOG=str(log))
            address="84:AC:60:25:4E:9C"
            def run(action):
                return subprocess.run([str(ROOT/"scripts/velora-bluetooth-control"),action,address],
                                      env=env,text=True,capture_output=True,timeout=8)
            state.write_text(json.dumps(dict(powered=False,paired=True,trusted=False,connected=False)))
            result=run("connect")
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            data=json.loads(state.read_text()); self.assertTrue(data['connected'] and data['trusted'] and data['powered'])
            commands=[json.loads(line) for line in log.read_text().splitlines()]
            self.assertIn(["--timeout","20","connect",address],commands)
            self.assertFalse(any('scan' in command or 'pair' in command for command in commands))
            self.assertEqual(run("connect").returncode,0,"Connected device is an idempotent success")
            result=run("disconnect"); self.assertEqual(result.returncode,0,result.stdout)
            self.assertFalse(json.loads(state.read_text())['connected'])
            data.update(connected=False,fail=True);state.write_text(json.dumps(data))
            result=run("connect");self.assertNotEqual(result.returncode,0)
            self.assertIn("ERR|connect|",result.stdout);self.assertIn("page-timeout",result.stdout)
            data.update(connected=True,fail=True);state.write_text(json.dumps(data))
            result=run("disconnect");self.assertNotEqual(result.returncode,0)
            self.assertIn("ERR|disconnect|",result.stdout)
            data.update(connected=False,paired=False,fail=False);state.write_text(json.dumps(data))
            result=run("connect");self.assertNotEqual(result.returncode,0)
            self.assertIn("device-not-paired",result.stdout)
            data.update(bonded=True);state.write_text(json.dumps(data))
            result=run("connect");self.assertEqual(result.returncode,0,result.stdout)

    def test_hover_management_and_pairing_process_with_isolated_devices(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-rail-bluetooth-") as temporary:
            base = Path(temporary)
            for directory in ("components", "features", "services", "assets", "core"):
                shutil.copytree(ROOT / directory, base / directory)
            shutil.copy2(ROOT / "tests/fixtures/rail-bluetooth.qml", base / "shell.qml")
            helper = base / "mock-bluetooth"
            helper.write_text('''#!/usr/bin/env python3
import sys,pathlib,json,time
with pathlib.Path(__file__).with_name("actions.jsonl").open("a") as log:
    log.write(json.dumps(sys.argv[1:])+"\\n")
if sys.argv[2] == "failure":
    print("Failed to pair: org.bluez.Error.AuthenticationFailed", flush=True)
elif sys.argv[1]=="pair-session":
    print("[agent] Confirm passkey 123456 (yes/no): ", end="", flush=True)
    answer = sys.stdin.readline().strip()
    print("Pairing successful" if answer == "yes" else "Failed to pair", flush=True)
else:
    time.sleep(.08)
    print("OK|"+sys.argv[1]+"|"+sys.argv[2],flush=True)
''')
            helper.chmod(0o700)
            (base / "runtime").mkdir(mode=0o700)
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(base / "runtime"),
                       HOME=str(base), XDG_CONFIG_HOME=str(base / "config"),
                       XDG_CACHE_HOME=str(base / "cache"), XDG_DATA_HOME=str(base / "data"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(base)], env=env,
                                    capture_output=True, text=True, timeout=25)
            output = result.stdout + result.stderr
            self.assertIn("RAIL_BLUETOOTH_OK", output, output)
            self.assertNotIn("RAIL_BLUETOOTH_FAILED", output, output)
            self.assertNotIn("TypeError", output, output)
            self.assertNotIn("ReferenceError", output, output)
            actions=[json.loads(line) for line in (base/"actions.jsonl").read_text().splitlines()]
            self.assertEqual(actions.count(["connect","success"]),1,"Pair success connects once; cancelling must not connect")
            self.assertIn(["disconnect","success"],actions)
