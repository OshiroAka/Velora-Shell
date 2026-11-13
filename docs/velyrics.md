# VeLyrics

Run `velyrics` in a Kitty terminal while the Spotify application plays music.
One terminal is sufficient, tiled or floating. Infinite Desk can stay off.
Multiple terminals on the current workspace receive successive verses or word
groups in registration order. Moving a terminal or switching workspaces uses
the current window workspace rather than its startup position.

```sh
velyrics
```

The media settings page configures full lines or word groups, words per group,
font, scale and synchronization offset. Spotify/LRCLIB polling is shared by a
local coordinator. The existing CAVA/pywal gradient and Kitty image rendering
remain in use. Fontconfig resolves the selected family to its actual file. If
Pixelon is unavailable during an update, the bundled Orbitron preserves image
rendering instead of discarding the font and gradient. Plain text remains a
fallback when graphical rendering itself cannot be used.

Word changes use two Kitty image slots. The new word is uploaded while the old
one remains visible, then placement and retirement happen inside one synchronized
screen update. Screen clearing occurs before the first upload, never between
upload and placement: Kitty discards unplaced images when the screen is erased.
Only the old image slot is freed on a word change. Continuation chunks contain
only m/q fields as specified by the [Kitty protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/).
The cursor is hidden during playback and restored on exit.

Camera following only runs if Infinite Desk is already enabled and at least
three floating, unpinned terminals participate. VeLyrics never enables it.
Disabling Infinite Desk stops pending camera movement and leaves lyrics running.

The terminal holds the current verse, in the configured font and CAVA gradient,
until the next lyric timestamp. Normal musical intervals do not replace it with
status messages. Loading, missing player, pause and unavailable lyrics can show
a smaller notice using the configured font. Recovery restores the current line.

The lyrics helper uses playerctl when available, or direct MPRIS reads through
python-dbus when it is absent. On Arch this alternative is the `python-dbus`
package. LRCLIB uses the same track metadata, position and local cache. No
Spotify login or Spicetify installation is needed for this lyrics path.

The helper's default status keeps the verse until the next timestamp;
`--hold-line` names this terminal policy explicitly. The shell overlay requests
`--hide-between-lines` to preserve its existing speech/gap animation.

```sh
velyrics status
velyrics toggle
```

`status` reports whether synchronization is enabled; it is not a Spotify health
probe. `toggle` enables or disables synchronization explicitly.

After updating an already running VeLyrics, press Ctrl+C in its terminal and
run `velyrics` again. The updated client uses `velyrics-v2.sock` and a matching
lock, so an older idle coordinator cannot restore the Infinite Desk requirement.
No Velora Shell restart is needed.

Pixelon is required by the normal installer. It downloads the author's archive,
validates the font family with fc-scan, installs under the user's XDG font
directory and refreshes Fontconfig. Existing Pixelon installations are reused.
A failed download does not publish a partial font or report installation ready.
The third-party font binary is downloaded per user, not bundled in the checkout.
The [author's page](https://www.dafont.com/pixelon.font) specifies personal,
non-profit and charity use; commercial licensing is available at that source.

To install only this requirement without changing the desktop session:

```sh
./scripts/install-velyrics-font
```

After loading the updated image renderer or installing Pixelon, reexecute
`velyrics` in its terminal. No shell restart is required.

Validation:

```sh
python3 -m unittest discover -s tests -p test_velyrics.py -v
python3 -m unittest discover -s tests -p test_velyrics_font_install.py -v
python3 -m unittest discover -s tests -p test_installer_preflight.py -v
```
