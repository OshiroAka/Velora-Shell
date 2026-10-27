#!/usr/bin/env python3

import argparse
import json
import os
import select
import socket
import sys
import time


def connect(path: str, deadline: float) -> socket.socket | None:
    while time.monotonic() < deadline:
        connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        connection.settimeout(0.25)
        try:
            connection.connect(path)
            return connection
        except OSError:
            connection.close()
            time.sleep(0.025)
    return None


def send_request(connection: socket.socket, request_id: int, command: list[object]) -> bool:
    payload = {
        "command": command,
        "request_id": request_id,
    }
    try:
        connection.sendall((json.dumps(payload, separators=(",", ":")) + "\n").encode())
        return True
    except OSError:
        return False


def read_lines(connection: socket.socket, buffer: bytes) -> tuple[list[dict], bytes, bool]:
    try:
        chunk = connection.recv(65536)
    except OSError:
        return [], buffer, False

    if not chunk:
        return [], buffer, False

    buffer += chunk
    messages: list[dict] = []
    while b"\n" in buffer:
        line, buffer = buffer.split(b"\n", 1)
        try:
            value = json.loads(line)
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        if isinstance(value, dict):
            messages.append(value)
    return messages, buffer, True


def query_properties(socket_path: str, names: list[str], timeout: float) -> dict[str, object]:
    deadline = time.monotonic() + timeout
    connection = connect(socket_path, deadline)
    if connection is None:
        return {}

    request_names = {6400 + index: name for index, name in enumerate(names)}
    for request_id, name in request_names.items():
        if not send_request(connection, request_id, ["get_property", name]):
            connection.close()
            return {}

    results: dict[str, object] = {}
    buffer = b""
    pending = set(request_names)
    try:
        while pending and time.monotonic() < deadline:
            readable, _, _ = select.select([connection], [], [], 0.08)
            if not readable:
                continue
            messages, buffer, alive = read_lines(connection, buffer)
            if not alive:
                break
            for message in messages:
                request_id = message.get("request_id")
                if request_id not in pending:
                    continue
                pending.discard(request_id)
                if message.get("error") == "success":
                    results[request_names[request_id]] = message.get("data")
    finally:
        connection.close()
    return results


def describe_wallpaper(socket_path: str, timeout: float) -> bool:
    properties = query_properties(socket_path, ["path", "time-pos", "duration", "container-fps", "estimated-vf-fps"], timeout)
    source = properties.get("path")
    position = properties.get("time-pos")
    if not isinstance(source, str) or not source:
        return False

    if source.startswith("file://"):
        source = source[7:]
    if not os.path.isfile(source):
        return False

    try:
        position_ms = max(0, round(float(position or 0.0) * 1000))
    except (TypeError, ValueError):
        position_ms = 0

    try:
        duration = float(properties.get("duration") or 0.0)
    except (TypeError, ValueError):
        duration = 0.0

    image_extensions = {".avif", ".bmp", ".gif", ".heic", ".jpeg", ".jpg", ".jxl", ".png", ".svg", ".webp"}
    extension = os.path.splitext(source)[1].lower()
    is_live = duration > 0.0 and extension not in image_extensions

    fps = properties.get("container-fps") or properties.get("estimated-vf-fps") or 60.0
    try:
        fps = min(240.0, max(10.0, float(fps)))
    except (TypeError, ValueError):
        fps = 60.0

    print(f"SOURCE={source}")
    print(f"POSITION_MS={position_ms}")
    print(f"LIVE={1 if is_live else 0}")
    print(f"FPS={fps:.3f}")
    return True


def load_file(socket_paths: list[str], path: str, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    connections: list[socket.socket] = []
    buffers: dict[socket.socket, bytes] = {}
    pending: set[socket.socket] = set()

    for socket_path in socket_paths:
        connection = connect(socket_path, deadline)
        if connection is None:
            for active in connections:
                active.close()
            return False
        connections.append(connection)
        buffers[connection] = b""
        if not send_request(connection, 6201, ["loadfile", path, "replace"]):
            for active in connections:
                active.close()
            return False
        pending.add(connection)

    loaded: set[socket.socket] = set()
    try:
        while pending and time.monotonic() < deadline:
            readable, _, _ = select.select(list(pending), [], [], 0.08)
            for connection in readable:
                messages, buffers[connection], alive = read_lines(connection, buffers[connection])
                if not alive:
                    pending.discard(connection)
                    continue
                for message in messages:
                    if message.get("event") == "file-loaded":
                        loaded.add(connection)
                        pending.discard(connection)
                        break
                    if message.get("request_id") == 6201 and message.get("error") not in (None, "success"):
                        pending.discard(connection)
                        break
    finally:
        for connection in connections:
            connection.close()

    if len(loaded) != len(connections):
        return False

    expected_path = os.path.realpath(path)
    pending_paths = set(socket_paths)
    stable_samples: dict[str, int] = {socket_path: 0 for socket_path in socket_paths}

    while pending_paths and time.monotonic() < deadline:
        for socket_path in list(pending_paths):
            remaining = max(0.05, min(0.25, deadline - time.monotonic()))
            properties = query_properties(
                socket_path,
                ["path", "video-out-params", "vo-configured", "video-frame-info"],
                remaining,
            )
            source = properties.get("path")
            if isinstance(source, str) and source.startswith("file://"):
                source = source[7:]
            params = properties.get("video-out-params")
            configured = properties.get("vo-configured")
            frame_info = properties.get("video-frame-info")
            source_ready = isinstance(source, str) and os.path.realpath(source) == expected_path
            video_ready = (
                isinstance(params, dict)
                and bool(params.get("w"))
                and bool(params.get("h"))
                and configured is not False
            )
            frame_ready = frame_info is None or isinstance(frame_info, dict)

            if source_ready and video_ready and frame_ready:
                stable_samples[socket_path] += 1
                if stable_samples[socket_path] >= 2:
                    pending_paths.discard(socket_path)
            else:
                stable_samples[socket_path] = 0
        if pending_paths:
            time.sleep(0.035)

    if pending_paths:
        return False

    time.sleep(0.035)
    return True


def wait_ready(socket_paths: list[str], timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    pending = set(socket_paths)

    while pending and time.monotonic() < deadline:
        for socket_path in list(pending):
            connection = connect(socket_path, min(deadline, time.monotonic() + 0.15))
            if connection is None:
                continue
            try:
                if not send_request(connection, 6301, ["get_property", "video-out-params"]):
                    continue
                buffer = b""
                request_deadline = min(deadline, time.monotonic() + 0.20)
                while time.monotonic() < request_deadline:
                    readable, _, _ = select.select([connection], [], [], 0.05)
                    if not readable:
                        continue
                    messages, buffer, alive = read_lines(connection, buffer)
                    if not alive:
                        break
                    ready = False
                    for message in messages:
                        if message.get("request_id") != 6301:
                            continue
                        data = message.get("data")
                        ready = message.get("error") == "success" and isinstance(data, dict) and bool(data.get("w")) and bool(data.get("h"))
                        break
                    if ready:
                        pending.discard(socket_path)
                        break
            finally:
                connection.close()
        if pending:
            time.sleep(0.025)

    if pending:
        return False

    time.sleep(0.04)
    return True


def set_pause(socket_paths: list[str], paused: bool, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    success = True

    for socket_path in socket_paths:
        connection = connect(socket_path, deadline)
        if connection is None:
            success = False
            continue
        try:
            if not send_request(connection, 6501, ["set_property", "pause", paused]):
                success = False
                continue

            buffer = b""
            acknowledged = False
            while time.monotonic() < deadline:
                readable, _, _ = select.select([connection], [], [], 0.05)
                if not readable:
                    continue
                messages, buffer, alive = read_lines(connection, buffer)
                if not alive:
                    break
                for message in messages:
                    if message.get("request_id") != 6501:
                        continue
                    acknowledged = message.get("error") == "success"
                    break
                if acknowledged:
                    break
            success = success and acknowledged
        finally:
            connection.close()
    return success


def set_property(socket_paths: list[str], name: str, value: object, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    success = True

    for index, socket_path in enumerate(socket_paths):
        connection = connect(socket_path, deadline)
        if connection is None:
            success = False
            continue
        request_id = 6700 + index
        try:
            if not send_request(connection, request_id, ["set_property", name, value]):
                success = False
                continue
            buffer = b""
            acknowledged = False
            while time.monotonic() < deadline:
                readable, _, _ = select.select([connection], [], [], 0.04)
                if not readable:
                    continue
                messages, buffer, alive = read_lines(connection, buffer)
                if not alive:
                    break
                for message in messages:
                    if message.get("request_id") == request_id:
                        acknowledged = message.get("error") == "success"
                        break
                if acknowledged:
                    break
            success = success and acknowledged
        finally:
            connection.close()
    return success


def main() -> int:
    parser = argparse.ArgumentParser(description="Coordinate persistent mpvpaper instances for Velora Shell.")
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--describe", action="store_true", help="describe the current wallpaper and playback position")
    action.add_argument("--load", metavar="PATH", help="load a wallpaper in the existing mpv instances")
    action.add_argument("--wait-ready", action="store_true", help="wait until every mpv output has video parameters")
    action.add_argument("--play", action="store_true", help="unpause every mpv instance")
    parser.add_argument("--timeout", type=float, default=2.5)
    parser.add_argument("socket", nargs="*", help="mpv IPC socket paths")
    args = parser.parse_args()

    timeout = min(8.0, max(0.25, args.timeout))
    if not args.socket:
        parser.error("at least one socket is required for this action")
    if args.describe:
        return 0 if describe_wallpaper(args.socket[0], timeout) else 1
    if args.load:
        return 0 if load_file(args.socket, os.path.abspath(args.load), timeout) else 2
    if args.play:
        return 0 if set_pause(args.socket, False, timeout) else 5
    return 0 if wait_ready(args.socket, timeout) else 3


if __name__ == "__main__":
    sys.exit(main())
