"""Validate production VeLyrics streams with Kitty's installed native parser.

No terminal window, GPU context or desktop connection is opened. Screen exposes
the same parser and graphics manager through its native testing entry points.
"""
import json
from pathlib import Path
import sys

from kitty.fast_data_types import Screen, set_options
from kitty.options.types import defaults


class Callbacks:
    def __init__(self):
        self.replies = bytearray()

    def write(self, value):
        self.replies.extend(value)

    def __getattr__(self, name):
        return lambda *args: None


def consume(screen, payload, fragment_size):
    if fragment_size == -1:
        commands = payload.split(b"\033\\")
        for index, command in enumerate(commands):
            consume(screen, command + (b"\033\\" if index < len(commands) - 1 else b""), None)
        return
    remaining = memoryview(payload)
    while remaining:
        buffer = screen.test_create_write_buffer()
        part = remaining[:fragment_size] if fragment_size else remaining
        used = screen.test_commit_write_buffer(part, buffer)
        remaining = remaining[used:]
        screen.test_parse_written_data()


def require(condition, message):
    # kitty +runpy uses optimized Python: ordinary assert statements are
    # removed. Keep every native-parser check active in that interpreter.
    if not condition:
        raise AssertionError(message)


set_options(defaults)
frames = json.loads(Path(sys.argv[1]).read_text())
for fragment_size in (-1, None, 1, 7, 4096):
    # PTY reads can split controls as well as payload. A correct stream must
    # work when clearing, placing and synchronization arrive in separate reads.
    callback = Callbacks()
    screen = Screen(callback, 16, 64, 0, 10, 22, 0, callback)
    previous = None
    for frame in frames:
        # Enable replies in this isolated parser to expose errors otherwise
        # hidden by q=2 in the UI. The commands and payload are unchanged.
        stream = Path(frame["path"]).read_bytes().replace(b"q=2", b"q=0")
        prepare, commit = stream.split(b"\033[?2026h", 1)
        consume(screen, prepare, fragment_size)
        require(screen.grman.image_count == (2 if previous is not None else 1), "image missing after upload")
        if previous is not None:
            require(screen.grman.image_for_client_id(previous) is not None, "old word removed during upload")
        consume(screen, b"\033[?2026h" + commit, fragment_size)
        require(b"ENOENT" not in callback.replies and b"EINVAL" not in callback.replies, repr(bytes(callback.replies)))
        current = screen.grman.image_for_client_id(frame["id"])
        require(current is not None, "uploaded image was discarded before placement")
        require((current["width"], current["height"]) == (frame["width"], frame["height"]), "incorrect PNG dimensions")
        layers = screen.grman.update_layers(0, -1, 1, 2 / 64, 2 / 16, 64, 16, 10, 22)
        require(len(layers) == 1, "expected one visible word placement")
        require(screen.grman.image_count == 1, "old GPU image not retired")
        require(callback.replies.count(b";OK") >= 2, "missing upload/placement acknowledgements")
        callback.replies.clear()
        previous = frame["id"]
print("KITTY_GRAPHICS_PASS: uploads, placements and fragmented swaps accepted")
