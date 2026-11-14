"""Shared wallpaper framing preference for static, video and profile backends."""
import argparse
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess


def mode():
    override=os.environ.get("VELORA_WALLPAPER_FIT")
    if override in ("cover","contain"):
        return override
    config=Path(os.environ.get("XDG_CONFIG_HOME",Path.home()/".config"))/"velora-shell/config.json"
    try:
        value=json.loads(config.read_text()).get("desktop",{}).get("wallpaperFit","cover")
    except (OSError,ValueError,AttributeError):
        value="cover"
    return value if value in ("cover","contain") else "cover"


def mpv_properties(value=None):
    return (("keepaspect",True),("panscan",0.0 if (value or mode())=="contain" else 1.0),
            ("background","color"),("border-background","color"),("background-color","#FF000000"))


def update_video(socket_path,value):
    with socket.socket(socket.AF_UNIX,socket.SOCK_STREAM) as connection:
        connection.settimeout(1)
        connection.connect(str(socket_path))
        reader=connection.makefile("rb")
        for request_id,(name,setting) in enumerate(mpv_properties(value),1):
            connection.sendall((json.dumps({"command":["set_property",name,setting],"request_id":request_id})+"\n").encode())
            while True:
                line=reader.readline()
                if not line:raise OSError("Wallpaper player disconnected")
                response=json.loads(line)
                if response.get("request_id")==request_id:
                    if response.get("error")!="success":raise OSError(f"Cannot set {name}")
                    break


def apply(value):
    cache=Path.home()/".cache/velora-shell/current_wallpaper"
    try:
        kind,path,_=cache.read_text().strip().split("|",2)
    except (OSError,ValueError):
        return
    if kind in ("live","mpv"):
        runtime=Path(os.environ.get("XDG_RUNTIME_DIR",f"/run/user/{os.getuid()}"))/"velora-shell"
        for endpoint in runtime.glob("mpvpaper-*.sock"):
            if "-preload-" not in endpoint.name:
                update_video(endpoint,value)
    elif kind in ("static","bg") and Path(path).is_file():
        backend=shutil.which("awww") or shutil.which("swww")
        if backend:
            subprocess.run([backend,"img",path,"--resize","fit" if value=="contain" else "crop","--fill-color","000000",
                            "--transition-type","fade","--transition-duration","0.2"],check=True,timeout=10)
    elif kind=="engine":
        env=dict(os.environ,VELORA_WALLPAPER_FIT=value,VELORA_WALLPAPER_FIT_ONLY="1")
        subprocess.run([str(Path(__file__).with_name("velora-wallpaper-apply")),"restore"],env=env,check=True,timeout=20)


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply",choices=("cover","contain"))
    args=parser.parse_args()
    if args.apply:
        apply(args.apply)
    else:
        print(mode())
