import io
import json
import os
from pathlib import Path
import runpy
import signal
import subprocess
import shutil
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/velora-monitor-control"


class MonitorControlTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(sys, "path", [str(ROOT / "scripts"), *sys.path]))

    def test_compact_panel_keeps_controls_and_loops_without_hover(self):
        if not shutil.which("qs"):
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-monitor-compact-") as directory:
            base=Path(directory)
            for name in ("components","core","features","platform","services","assets"):
                (base/name).symlink_to(ROOT/name,target_is_directory=True)
            (base/"scripts").mkdir()
            helper = base/"scripts/velora-monitor-control"
            helper.write_text('''#!/bin/sh
case "$1" in
    probe) exec hyprctl -j monitors all ;;
    wireless-status)
        if [ -f "$XDG_RUNTIME_DIR/cast-status" ]; then cat "$XDG_RUNTIME_DIR/cast-status";
        else printf '%s\\n' '{"phase":"idle"}'; fi ;;
    wireless-scan) printf '%s\\n' '{"available":true,"networkAvailable":true,"devices":[{"id":"01:23:45:67:89:ab","address":"01:23:45:67:89:ab","name":"TV Sala","label":"Miracast","protocol":"wfd","canConnect":true},{"id":"01:23:45:67:89:ac","address":"01:23:45:67:89:ac","name":"TV Quarto","label":"Miracast","protocol":"wfd","canConnect":true},{"id":"lan:192.0.2.1","address":"192.0.2.1","name":"Impressora","label":"Rede local","protocol":"lan","canConnect":false}]}' ;;
    wireless-start)
        [ "$2" = extend ] && [ "$3" = wfd ] && [ "$4" = 01:23:45:67:89:ac ] || exit 2
        printf '%s\\n' '{"phase":"streaming","device":"TV Quarto","mode":"extend"}' > "$XDG_RUNTIME_DIR/cast-status"
        printf '%s\\n' '{"phase":"connecting","device":"TV Quarto","mode":"extend"}' ;;
    wireless-stop)
        rm -f "$XDG_RUNTIME_DIR/cast-status"
        printf '%s\\n' '{"phase":"idle"}' ;;
    *) exit 2 ;;
esac
''')
            helper.chmod(0o700)
            (base/"bin").mkdir()
            fake=base/"bin/hyprctl"
            data=[{"name":"eDP-1","width":1920,"height":1200,"refreshRate":60,"scale":1,"availableModes":["1920x1200@60.00Hz"]},
                  {"name":"HDMI-A-1","width":1920,"height":1080,"refreshRate":60,"scale":1,"availableModes":["1920x1080@60.00Hz"]}]
            fake.write_text("#!/usr/bin/env python3\nprint("+repr(json.dumps(data))+")\n")
            fake.chmod(0o700)
            (base/"runtime").mkdir(mode=0o700)
            (base/"shell.qml").write_text((ROOT/"tests/fixtures/monitor-compact.qml").read_text().replace('"../../','"./'))
            env=dict(os.environ,QT_QPA_PLATFORM="offscreen",QT_QUICK_BACKEND="software",VELORA_VALIDATE="1",
                XDG_RUNTIME_DIR=str(base/"runtime"),XDG_CONFIG_HOME=str(base/"config"),XDG_STATE_HOME=str(base/"state"),
                XDG_CACHE_HOME=str(base/"cache"),PATH=str(base/"bin")+os.pathsep+os.environ["PATH"])
            env.pop("WAYLAND_DISPLAY",None)
            result=subprocess.run(["qs","-p",str(base)],env=env,text=True,capture_output=True,timeout=12)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("MONITOR_COMPACT_OK",output)
            for error in ("FAILED","TypeError","ReferenceError","Binding loop","Cannot assign"):
                self.assertNotIn(error,output)

    def test_mirror_confirm_and_revert_with_fake_hyprland(self):
        with tempfile.TemporaryDirectory(prefix="velora-monitor-") as temporary:
            base = Path(temporary)
            fake = base / "hyprctl"
            fake.write_text('''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
if sys.argv[1:4] == ["-j", "monitors", "all"]:
    print(json.dumps([
        {"name":"eDP-1","width":1920,"height":1200,"refreshRate":60,"x":0,"y":0,"scale":1,"availableModes":["1920x1200@60.00Hz"],"mirrorOf":"none"},
        {"name":"HDMI-A-1","width":1920,"height":1080,"refreshRate":60,"x":1920,"y":0,"scale":1,"availableModes":["1920x1080@60.00Hz"],"mirrorOf":"none"}]))
elif sys.argv[1:3] == ["keyword", "monitor"]:
    with open(os.environ["MONITOR_LOG"], "a") as stream: stream.write(sys.argv[3] + "\\n")
    print("ok")
else: sys.exit(2)
''')
            fake.chmod(0o700)
            log = base / "commands.log"
            env = dict(os.environ, PATH=str(base) + os.pathsep + os.environ["PATH"],
                       XDG_RUNTIME_DIR=str(base), MONITOR_LOG=str(log))

            def run(*args):
                return subprocess.run([str(SCRIPT), *args], env=env, text=True,
                                      capture_output=True, timeout=8, check=True).stdout.strip()

            token = run("apply", "mirror", "eDP-1", "1920x1200@60.00", "1.25")
            self.assertTrue(token.startswith("monitor-"))
            self.assertIn("HDMI-A-1,preferred,auto,1,mirror,eDP-1", log.read_text())
            run("revert", token)
            self.assertIn("HDMI-A-1,1920x1080@60.00,1920x0,1", log.read_text())
            token = run("apply", "extend", "eDP-1", "1920x1200@60.00", "1.00")
            run("confirm", token)
            self.assertFalse((base / "velora-shell/monitor-pending" / token).exists())

    def test_wireless_scan_retains_non_display_peers_and_reports_scan_errors(self):
        scan = runpy.run_path(str(SCRIPT))["scan_wifi_direct"]
        log = """[FluxCast WFD] Wi-Fi Direct peer(s):
 [0] AA:bb:cc:dd:ee:01 TV Sala via NetworkManager
     WFD capability data detected
 [1] aa:bb:cc:dd:ee:02 Notebook via wpa_cli
     not advertising Wi-Fi Display; if this is a TV, put it into Screen Share mode first
 [2] aa:bb:cc:dd:ee:01 TV Sala via NetworkManager
 [3] invalid
"""
        with patch.dict(scan.__globals__, {"wifi_direct_arguments": lambda: []}):
            with patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0, log, "")) as backend:
                peers, error = scan("/fake/fluxcast")
                self.assertEqual(error, "")
                self.assertEqual([(item["name"], item["canConnect"]) for item in peers],
                                 [("TV Sala", True), ("Notebook", False)])
                self.assertEqual(backend.call_args.args[0], ["/fake/fluxcast", "--wfd-scan", "--wfd-timeout", "8"])
            with patch("subprocess.run", return_value=subprocess.CompletedProcess(
                    [], 1, "[FluxCast WFD] ERROR: NetworkManager P2P missing", "")):
                self.assertEqual(scan("/fake/fluxcast"), ([], "NetworkManager P2P missing"))

    def test_network_discovery_combines_dns_sd_upnp_and_all_known_neighbors(self):
        import velora_wireless_network as network

        browse = '''=;wlan0;IPv4;Speaker;_googlecast._tcp;local;speaker.local;192.0.2.4;8009;"ca=4"
=;wlan0;IPv4;TV;_googlecast._tcp;local;tv.local;192.0.2.2;8009;"ca=5" "fn=TV Sala"
'''
        with patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0, browse, "")):
            dns = network.dns_sd()
        self.assertEqual([(item["name"], item["protocol"]) for item in dns[0]], [("Speaker", "lan"), ("TV Sala", "cast")])
        upnp = ([{"address": "192.0.2.3", "name": "Projetor", "protocol": "dlna", "label": "DLNA"}], True)
        neighbors = ([{"address": host, "name": host, "protocol": "lan", "label": "Rede local"}
                      for host in ("192.0.2.2", "192.0.2.5", "192.0.2.10")], True)
        with patch.multiple(network, dns_sd=lambda: dns, ssdp_devices=lambda _: upnp,
                            neighbor_devices=lambda _: neighbors, interface_addresses=lambda: {"192.0.2.10": 24}):
            devices, available = network.discover_network({"cast"})
        self.assertTrue(available)
        self.assertEqual([(item["name"], item["label"], item["canConnect"]) for item in devices], [
            ("Speaker", "Google Cast", False), ("TV Sala", "Google Cast", True),
            ("Projetor", "DLNA", False), ("192.0.2.5", "Rede local", False),
        ])

    def test_lan_probe_uses_only_other_addresses_on_the_connected_private_subnet(self):
        import velora_wireless_network as network

        with patch("socket.socket") as socket, patch("time.monotonic", side_effect=(0, 0, 2)):
            ping = socket.return_value.__enter__.return_value
            ping.recvfrom.return_value = (b"\x00\x00", ("192.168.1.2", 0))
            self.assertEqual(network.probe_link_neighbors({"192.168.1.1": 30, "203.0.113.1": 30}), {"192.168.1.2"})
            self.assertEqual([call.args[1] for call in ping.sendto.call_args_list], [("192.168.1.2", 0)])

    def test_lan_discovery_still_lists_devices_when_wifi_direct_fails(self):
        scan = runpy.run_path(str(SCRIPT))["scan_wireless"]
        phone = {"id": "lan:192.0.2.5", "address": "192.0.2.5", "name": "Celular",
                 "label": "Rede local", "protocol": "lan", "canConnect": False}
        with patch("shutil.which", return_value="/fake/fluxcast"), patch.dict(scan.__globals__, {
            "scan_wifi_direct": lambda _: ([], "Wi-Fi Direct indisponível"),
            "discover_network": lambda _: ([phone], True),
        }):
            self.assertEqual(scan(), {"available": True, "networkAvailable": True,
                                     "directError": "Wi-Fi Direct indisponível", "devices": [phone]})

    def test_start_runs_fluxcast_worker_as_a_session_specific_service(self):
        start = runpy.run_path(str(SCRIPT))["wireless_start"]
        with tempfile.TemporaryDirectory(prefix="velora-wireless-") as directory, \
             patch.dict(os.environ, XDG_RUNTIME_DIR=directory, HYPRLAND_INSTANCE_SIGNATURE="fixture"), \
             patch("shutil.which", return_value="/fake/fluxcast"), \
             patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0)) as execute:
            self.assertEqual(start("mirror", "wfd", "aa:bb:cc:dd:ee:01", "eDP-1", "TV Sala"),
                             {"phase": "connecting", "device": "TV Sala", "mode": "mirror"})
            command = execute.call_args.args[0]
            self.assertEqual(command[:2], ["systemd-run", "--user"])
            self.assertEqual(command[-6:], ["wireless-run", "mirror", "wfd", "aa:bb:cc:dd:ee:01", "eDP-1", "TV Sala"])
            self.assertIn("--setenv=HYPRLAND_INSTANCE_SIGNATURE=fixture", command)
            self.assertTrue(any(argument.startswith("--unit=velora-wireless-display-") for argument in command))
            with self.assertRaises(ValueError):
                start("mirror", "wfd", "--tray", "eDP-1", "TV Sala")
            self.assertEqual(execute.call_count, 1)

    def test_wireless_worker_streams_named_outputs_and_removes_only_its_extension(self):
        run = runpy.run_path(str(SCRIPT))["run_wireless"]
        module = run.__globals__
        outputs = [{"name": "eDP-1", "width": 1920}, {"name": "HEADLESS-2", "width": 1920}]
        changes = []

        def compositor(*args):
            if args[:2] == ("-j", "monitors"):
                return json.dumps(outputs)
            changes.append(args)
            if args[:3] == ("output", "create", "headless"):
                outputs.append({"name": args[-1], "width": 1920})
            elif args[:2] == ("output", "remove"):
                outputs[:] = [item for item in outputs if item["name"] != args[-1]]
            else:
                self.fail(f"Unexpected compositor command: {args}")
            return "ok"

        def stream(process, stop, state, details):
            self.assertEqual(details["device"], "TV Sala")
            if details["mode"] == "extend":
                self.assertEqual(len(outputs), 3)
                self.assertEqual([item["name"] for item in module["monitors"]()], ["eDP-1", "HEADLESS-2"])
            stop.set()
            return ""

        with tempfile.TemporaryDirectory(prefix="velora-wireless-") as directory, \
             patch.dict(os.environ, XDG_RUNTIME_DIR=directory, HYPRLAND_INSTANCE_SIGNATURE="fixture"), \
             patch.dict(module, {"hyprctl": compositor, "watch_transmission": stream, "wifi_direct_arguments": lambda: []}), \
             patch("shutil.which", return_value="/fake/fluxcast"), patch("signal.signal"), \
             patch("subprocess.Popen") as launch:
            launch.return_value.poll.return_value = None
            run("mirror", "wfd", "aa:bb:cc:dd:ee:01", "eDP-1", "TV Sala")
            self.assertEqual(changes, [])
            self.assertIn("eDP-1", launch.call_args.args[0])
            run("extend", "wfd", "aa:bb:cc:dd:ee:01", "", "TV Sala")
            output = changes[0][-1]
            self.assertRegex(output, r"^VELORA-TV-[0-9a-f]{8}$")
            self.assertEqual(changes, [("output", "create", "headless", output), ("output", "remove", output)])
            self.assertEqual(launch.call_args.args[0], [
                "/fake/fluxcast", "--protocol", "wfd", "--monitor", output, "--wfd-peer", "aa:bb:cc:dd:ee:01", "--wfd-capture-backend", "wf-recorder", "--wfd-no-firewall",
            ])
            launch.return_value.send_signal.assert_called_with(signal.SIGINT)
            self.assertEqual(module["wireless_status"](), {"phase": "idle"})

            launch.side_effect = OSError("Launch failed")
            run("extend", "wfd", "aa:bb:cc:dd:ee:01", "", "TV Sala")
            self.assertEqual(changes[-2][-1], changes[-1][-1])
            self.assertEqual(changes[-1][:2], ("output", "remove"))
            self.assertEqual([item["name"] for item in outputs], ["eDP-1", "HEADLESS-2"])
            self.assertEqual(module["wireless_status"]()["error"], "Launch failed")

    def test_fluxcast_play_and_disconnect_drive_status(self):
        watch = runpy.run_path(str(SCRIPT))["watch_transmission"]
        process = Mock(stdout=io.StringIO(
            "[FluxCast WFD RTSP] PLAY accepted; media stream started.\n"
            "[FluxCast WFD Media] Stopping RTP stream...\n"))
        with patch.dict(watch.__globals__, {"write_wireless_status": Mock()}), patch("sys.stderr", new=io.StringIO()):
            result = watch(process, Mock(is_set=lambda: False), Path("fixture"), {"device": "TV Sala"})
            watch.__globals__["write_wireless_status"].assert_called_once_with(
                Path("fixture"), "streaming", device="TV Sala")
        self.assertIn("TV encerrou", result)


if __name__ == "__main__":
    unittest.main()
