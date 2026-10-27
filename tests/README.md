# Validation

Run the suite from the checkout:

```sh
./tests/run
```

The suite uses Python 3, Node.js, Quickshell, Qt 6 Quick Test, a C++20 compiler,
`pkg-config`, EGL and OpenGL ES development libraries. Installation and helper
checks use temporary homes and mocked commands. The Spotify bridge tests bind
to an ephemeral port on `127.0.0.1`; a sandbox must permit local sockets.
QML tests use offscreen rendering. GPU/material checks exercise the native
shader independently of the active desktop.

Focused checks:

```sh
python3 -m unittest discover -s tests -p test_topbar.py
python3 -m unittest discover -s tests -p test_surface_geometry.py
python3 -m unittest discover -s tests -p test_bar_material.py
python3 -m unittest discover -s tests -p test_edge_media.py
python3 -m unittest discover -s tests -p test_rail_system.py
python3 -m unittest discover -s tests -p test_infinite_desktop_morph.py
python3 -m unittest discover -s tests -p test_settings_rebuild.py
python3 -m unittest discover -s tests -p test_whatsapp_bridge.py
python3 -m unittest discover -s tests -p test_wallpaper_transition.py -v
python3 -m unittest discover -s tests -p test_velyrics.py -v
python3 -m unittest discover -s tests -p test_velyrics_font_install.py -v
python3 -m unittest discover -s tests -p test_terminal_glass.py -v
```

Edge media coverage includes transport controls, curved lyrics, the bundled
serif font, smooth verse scrolling, glow handoff, audio demand, reduced motion,
full-height closing, reentry during closing and volume/brightness coexistence.
Disabling the desktop visualizer must stop migration into the left rail, including
an immediate stop during an active docking animation, while the right panel
retains its own contour and audio demand.
Spotify opening is checked at intermediate poses beyond one second. Quiet
audio must visibly displace the contours, and a synced verse change must update
both the right and left Lyrics contours together.
Rendered spline peaks and valleys must retain their default contrast even with
uniform full-volume input, preventing amplification from flattening the waves.
It also checks header search results and playback actions, keyboard states,
responsive controls, dynamic artwork and missing-artwork fallback. An offscreen
OpenGL/RHI pixel check verifies that the artwork preserves transparency below
the fade and outside the organic contour, leaving the native liquid visible.
WhatsApp coverage includes opening from the edge icon, local contact/group
selection, unsent drafts, responsive layout and unchanged Spotify capture demand.
Material rendering checks the attached contacts shelf's interior distance to
prevent an optical seam at the join without shifting its external boundary.
The real WhatsApp client tests use isolated SQLite sessions and mocked sockets,
covering QR/phone pairing, session resume, cached profile photos, community
covers, group sender identities, clipboard, manual sends and media downloads.
The socket fixture uses Baileys' real event buffer. A generic WebSocket failure
mapped to 500 must reconnect with identical credentials and Signal keys while
keeping cached conversations/media; actual server revocation and stale updates
are checked separately. A worker exits without closing SQLite and two fresh
Node processes must then resume that QR session, selection and history without
requesting another QR code or exporting credentials.
The QML fixture also checks scroll preservation, the jump-to-bottom button,
editable composition, Ctrl+V and actual Qt decoding/playback of generated audio
and video. Node-dependent checks require `./scripts/install-whatsapp-bridge`;
the media fixture requires ffmpeg and Pillow. It also checks color emoji pixels
in the picker/composer, caret insertion, real sticker selection, intermediate
popup and incoming/outgoing animations, hover, scroll reversal, send feedback
and reduced motion. Node tests preserve Unicode sequences, prepare private
512px WebP stickers through the actual Baileys media builder and retain animated
WebP bytes, convert animated GIFs and cache PNG/GIF display copies for Qt builds
without the WebP image plugin. A delayed sticker import must preserve the new
chat's pending files. Tests do not use the logged-in account or send to real contacts.
Topbar checks use the actual controller and morph to verify immediate hot hover,
continuous pose retargeting, preserved content/interactivity, close/reopen and
reduced motion. Compact focus/battery tests verify control bounds and real
mouse clicks on all power choices and Fan+, without changing real hardware.
The bar GLSL check includes high-wave rail/right-panel coverage and colour,
raster antialias fringes and intentionally different backdrop snapshots across
the upper/lower hosts; silence must not create a permanent raised wave.

Rail coverage includes geometry handoff, rapid reversal, delayed slider content,
closing and reduced motion. Embedded notification history is checked at two narrower
widths so clear/dismiss controls stay inside the topbar viewport.

Infinite Desktop coverage checks that source icons disappear before the layout
moves and destination icons reveal only after layout/frame arrival. OpenGL/RHI
pixels verify the live glyph's blur halo, fade and sharp final ink without
resizing its hit area. It also covers registered controls, rapid reversal,
reduced motion and corner-based frame folding/restoration. The native material
fixture checks intermediate and reversed folds, an empty screen centre and the
preserved topbar.

Offscreen tests do not replace visual review on a compositor or physical
multi-monitor and hardware checks.

Wallpaper transition coverage exercises the picker and complete profile helper
for every image/video handoff, direct native Wave for static images, player
reuse, failed application/preparation, cancellation, unsupported plugins and
identical profile assets. Native and Lua dispatch must acknowledge preparation
before applying; a three-second effect must not delay request completion. The
production C++ clock is tested deterministically. Surfaceless EGL compiles the
exact compositor GLSL, checking wave crests, physical aspect, alpha endpoints
and blending without holes for five modes/eight directions on wide/tall screens.

VeLyrics coverage exercises single tiled terminals and word groups with Infinite
Desk off, multiple terminals without camera movement, optional camera following,
disabling it mid-line, missing camera commands, workspace changes and departed
targets. Client tests check configured fonts, recovery without waiting for a new
verse and removal of old Kitty graphics. Missing lyrics must not be reported
as a paused Spotify. Direct D-Bus metadata and cached lyrics are tested with
playerctl absent. A long musical interval must keep the actual verse until the
next timestamp, while the overlay's opt-in hiding policy remains intact. Tests
mock desktop/player data without local sockets or network access.

Real ImageMagick rendering checks transparent styled glyphs, CAVA color variation
and different selected fonts with Pixelon's original system path absent. Kitty
protocol tests require complete upload before the synchronized placement/removal
commit, without clearing the old word during transmission. Font installer tests
cover user-local installation, repeatability, family validation, no partial font
after network errors and automatic installation/recheck before the shell build.

The VeLyrics Kitty fixture feeds the production stream into the installed native
Screen parser through `kitty +runpy`, without opening a desktop window. It checks
PNG decode, acknowledged placement, one visible layer and old-image retirement
through three swaps, including fragmented input. Checks use explicit exceptions
because Kitty's embedded Python runs optimized and removes `assert` statements.
The prior upload/erase/placement stream reproduces `ENOENT` in this fixture.

The bar material EGL fixture renders both Liquid Ass and the new Liquid Glass,
including real connected joins, independent refraction/brightness, static grain
and partial-damage source halos. It also renders the production Gaussian shader
in both directions and compares delta stripes to the analytical Gaussian profile,
checking constant channels and alpha. Settings fixtures cover both choices,
separate persisted refraction values and restoration after Kitty matching.

Kitty liquid glass coverage compiles the production backdrop GLSL and the
installed Hyprland surface shader with real blur/rounding composition. It checks
body and rim refraction, a stable focal point, opaque glyph pixels, rounded corners,
output transformation, zero-strength composition during fades, target reuse,
resize and partial damage. The material uses the compositor's existing blur;
these EGL checks do not connect to the desktop or change any terminal settings.
The sharp-scene case checks visible contrast after 56% Kitty background opacity
and preserves opaque glyph pixels. A negative control with only the blurred
source reproduces the visually ineffective material. A real GPU blit caches
the pre-window scene; later stale client pixels in the working target must not
enter the lens.
Floating-point coordinate textures expose the actual shader rays in 40
geometry/scale/intensity combinations. Checks reject inverted sampling maps,
discontinuities and excessive stretching in wide, tall and compact windows,
and require displacement in the body beyond the rim. Both scene inputs follow
the ray. Optional desktop-size preview output is described in
`docs/kitty-liquid-glass.md`.
Terminal controls also cover native argument validation, bounded default rim
pixels, CLI routing, on/off/toggle, preserved intensity and invalid requests
without writes. The real settings fixture exercises the system-page switch and
slider, their search targets and preference persistence across shell reloads.

Weather panel coverage checks staged entrance, interrupted exit/reopening,
reduced motion, responsive two-column/stacked layouts and forecast scrolling.
It exercises metric retargeting without a curve jump, missing observations,
zero values, Celsius/Fahrenheit, refresh locking and keyboard hour selection.
The isolated fixture uses no network requests or real session weather data.
Run `python3 -m unittest discover -s tests -p test_weather_panel.py`.

Kitty/bar matching compiles the shared GLSL optics for both real shaders and
compares their pixels after the Kitty background tint/opacity, at five
intensities. Matching bars must stay static when shader time changes. The
settings fixture reads an isolated Kitty theme, verifies matching/restore,
search targets and saved preferences across process reload. Infinite Desk
transition tests also cover a live canvas with its special toolbar disabled:
regular bars and frame remain fully visible. Its older MultiEffect fade check
requires a GPU scene graph and skips when Qt reports the software renderer;
state and Canvas checks still run there. Native GLSL tests use EGL separately.

Independent bar refraction renders the production shader at 0/1/5/10x on a
horizontal bar, a vertical bar and the attached Settings shape, with 8% tint.
Higher strengths must visibly move the backdrop without saturating early or
changing coverage. Translucent material and matching Kitty optics stay unchanged.
Native arguments reject invalid/non-finite/out-of-range values. The real Settings
fixture checks the separate 0–10 control, reset to 1x, zero, search, preserved Kitty
strength, shared-mode disable/restore and persistence after a new process.

O modo **Kitty acompanha a barra** é exercitado por `test_terminal_glass.py`
com o GLSL de produção e o shader de cliente instalado do Hyprland. São 96
combinações de material, opacidade, refração e brilho, com tolerância de 1 RGB
na saída final. Os controles negativos retiram a compensação do cliente ou
reduzem o intermediário a 8 bits e precisam falhar. `test_terminal_theme.py`
confere alpha sem arredondamento para 8 bits, bypass dos limites de opacidade
e restauração do tratamento independente. `test_settings_rebuild.py` exercita
a direção exclusiva de herança, brilho/redefinir, preservação da barra e
persistência após reabrir a instância isolada.
