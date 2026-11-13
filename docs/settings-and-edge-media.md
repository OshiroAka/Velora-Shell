# Settings, edge media and motion

Settings now group controls into eight searchable categories and load pages on
demand. Widget previews, material choices, wallpaper comparisons and finite
motion previews keep related adjustments together. Settings open from the right wall with zero lateral margin, a vertical category
rail, global search and a separate scrolling content column. System opens with
an image preview of the current wallpaper and functional display, sound,
notification, power and network cards. Each card expands its controls in Settings;
its chevron rotates down and the Settings window remains open. Display uses the
existing resolution/scale/refresh controls and confirmation timeout. Collapsing a
pending display change restores it before releasing the controls, including when
reduced motion skips the expansion. Audio uses the tracked PipeWire sink; history,
Wi-Fi, power profiles and Fan+ use their existing services, without a second popup.
Controls are mounted on expansion and released on collapse once pending display
operations finish. Network scanning and section polling stop when collapsed.

The surface shares the bar's material and joins the right frame through open
concave shoulders, without an internal border or a second layer of glass.
Native support uses `settings-side-connected` and the existing
`settings-connected` dispatcher with an optional `right` attachment. All frame
passes evaluate the same contour before partitioning ownership, so refraction,
alpha and tint stay continuous at the right wall. The fallback uses the open
QML contour. The animated surface reveals a content frame laid out at its final
width and height, anchored to its final screen position. Navigation breakpoints,
scroll viewports and the wallpaper preview do not reflow with the growing contour.
The decorative wallpaper header retains the animated surface mask. Geometry
enters over 220 ms; controls begin their single 150 ms fade after 120 ms, overlapping
the expansion like the sidebar menus. Closing fades content over 65 ms and retracts
the surface over 125 ms. Interrupted motion resumes from the current pose and
reduced motion changes the layout immediately. Pages load asynchronously during
normal motion; initial page loading does not add another entrance animation.
Category fades and local section transitions remain available.

The editor, topbar menus and primary wallpaper grid publish native contours on
consecutive animation ticks. They share `core/FramePublisher.qml`: a dirty burst
keeps the frame driver active until one trailing tick finds no new geometry,
then stops completely at rest. This avoids restarting `FrameAnimation` for every
pose, which skipped alternate ticks even while the QML animation ran smoothly.
The alternative wallpaper carousel uses the same publisher. Invalidations raised
during publication are preserved for the next tick; unchanged editor shapes are
not dispatched repeatedly.

Appearance now contains the bar material, bar organization, sidebar/menu and
desktop/widget groups. They retain their category icons and glyph-only hover/focus
zoom, lift and glow. Groups load controls on expansion; global search expands the
matching group before locating and focusing the setting. The former bar/desktop
category IDs resolve to Appearance for compatibility, with eight navigation entries.

Wallpaper is a single scrolling settings page for framing, effects, transitions
and the alternative selector. Framing is persisted as `desktop.wallpaperFit`:
`cover` fills the output with aspect-preserving cropping (the existing default),
while `contain` keeps the complete image/video with opaque black borders.
The setting reaches awww/swww, new/reused mpvpaper instances and profile apply.
Live changes use mpv properties without seeking/reloading the video; selecting
an already selected framing option reapplies it. Static changes use the original
asset, bypassing the cover-only image cache. Engine scaling maps to fill/fit,
consistent with [upstream usage](https://github.com/Almamu/linux-wallpaperengine#-common-options). Its library grid, filters and upper section tabs are removed;
the primary wallpaper picker and the alternative carousel remain available.

The paint menu owns the three Pywal tone controls: sun (light), crescent moon
(dark) and AUTO. They write the same persisted `appearance.pywalTone` preference;
selected state follows that preference. Tone controls are removed from Appearance.
Palette swatches and shuffle remain in the paint menu.

The old System block and its energy/integration/world-clock controls are removed,
as are their exclusive backend queries and the world-clock and Code opacity helpers.
Shared terminal/browser theme helpers remain with their other runtime consumers.

Application search (Super+W) retains its connected bottom host. Configuration
continues through the existing controllers and persistence services.

The primary wallpaper picker reserves its complete grid surface while the first
inventory loads. The thumbnail layout remains at its final dimensions during
morphs, clipped by the growing surface. A stable ListModel reconciles rows by
wallpaper identity: insertions and preview updates retain other delegates,
selection, scroll anchor and the ongoing diagonal entrance. New rows alone
receive a short entrance. Four visible rows are used when the output allows it.

The fast inventory reads paths and cached metadata without running media tools.
It publishes before the existing scanner generates new previews in the background.
A recursive inotify watcher is active only while the picker is open, debouncing
completed writes, moves and removals over 160 ms. A new file can appear while
another thumbnail is still being generated. Discovery timestamps persist in the
user cache; discoveries from the past 30 minutes receive a soft accent glow,
with one shared expiry clock and no perpetual per-thumbnail animation. Closing
unmounts the grid, stops watching, and preserves existing apply/transition helpers.

Media and audio uses three expandable groups: Audio, Lyrics on the wallpaper,
and VeLyrics in terminals. Audio volume and mute operate on the tracked output
without changing pages. Wallpaper lyrics contain display/sync, layout, position,
text/color, material/mask and movement sections. Block position and block styling
share a selected block while their sections unload. Global search expands the
required groups and focuses each of the 50 media targets or its conditional
fallback. Opening VeLyrics loads its persisted settings and font list on demand.

Media choice buttons use the bundled symbol font, keyboard activation and the
same glyph hover/focus motion as the category rail. Icons are validated with
HarfBuzz so absent ligatures cannot render as words over labels. Position and
text fields use two columns when space allows, short tracks (at most 184 px),
local value labels and smaller handles. Reduced motion settles immediately.
The ineffective Fade/Slide lyrics animation choices and ambiguous global reset
are removed from this page. Transform reset affects only transforms; VeLyrics
has its own reset. Saved values remain in their existing backends.

The right edge contains Spotify, Discord and WhatsApp icons. Spotify opens a
full-height media panel; Discord remains a visual placeholder. WhatsApp opens
a local client with QR/phone pairing, real contacts, groups, messages and media;
see [WhatsApp client](whatsapp-preview.md). During
Spotify playback, hovering its icon exposes Lyrics. Media contours consume the
shared audio analyzer; Lyrics contours follow verse timestamps. Lyrics use the
bundled Liberation Serif font, glow on the active verse and smooth scrolling.
Dragging the lyrics pauses following until it is resumed.
Audio-driven contours amplify quiet passages while preserving zero-input rest,
fixed frame joins and the control inset. Audio amplifies the original lobes
instead of filling their valleys toward a shared ceiling; both sides keep their
default proportions. Both Lyrics contours share the same verse-driven samples: each new
verse selects a distinct phase, interpolated over 900 ms, with gentle drift
within the verse. Lyrics movement remains independent of the audio spectrum.

Media artwork is a reactive background, with a small GPU blur and a single mask
combining the organic contour with an alpha fade. The image disappears into the
existing native liquid material; no opaque rectangle covers the lower panel.
Missing artwork exposes the original neutral surface. A matching slice extends
behind the topbar without covering its controls. Its top fade keeps the header
mostly neutral, with album color increasing below it. Image decoding is bounded to
1024 pixels and no extra image-processing dependency is used.
The entrance now uses a smooth opacity curve with a transparent header and a
longer fade below it. This keeps hard letterbox margins embedded in album art
from cutting across the header. Both slices use the same artwork coordinates;
the rendered test checks the neutral header, gradual entrance and alignment.

Lyrics also emits short color waves on percussion onsets while Spotify plays.
Only the Lyrics page enables this consumer of the existing 96-band FFT; the
Spotify music view and WhatsApp do not trigger it. The detector uses positive
spectral flux between 40 and 320 Hz, weighting 40–180 Hz most strongly. It
rejects steady bass, slow swells, low noise and attacks confined to higher
bands. This selects a frequency range, not isolated instrument stems: bass
instruments and low voices with similar attacks can also trigger it.

Each beat starts a 1.6-second wave inside the right Lyrics body, using two
representative colors from the current album cover and the charging wave's
spatial field and fading envelope. The cover is sampled at up to 64×64 pixels;
black/white margins are excluded when other colors are available. Monochrome
covers keep their neutral colors. Pillow is already a shell dependency.
The small palette is cached per source and local modification time under
`velora-shell/album-palettes` in the user cache, separate from the wallpaper
palette. Failed or stale cover loads cannot reuse the previous album's colors;
new pulses wait for the current palette. Each emitted pulse retains its own
colors through a track change. Up to eight waves
can finish independently, with a 200 ms minimum interval; overlapping waves
use the strongest local contribution instead of accumulating brightness.
All native bar/frame passes share the origin in monitor coordinates, so no
line appears between the panel and topbar. Pausing, closing or changing pages
stops new beats and lets existing waves dissipate. Reduced motion disables
and clears the effect. The bottom visualizer preference remains unchanged.
The native capabilities are `lyrics-beat` and `lyrics-beat-palette`
(plugin 0.17.18); older plugins leave this consumer inactive.
No extra capture stream, idle poller, background or
foreground overlay is added.

The media view keeps seeking and three transport controls: previous, play/pause
and next. Their neutral outline glyphs reuse the sidebar's stroke and hover
motion, with wider spacing and no button backgrounds. Keyboard focus retains a
small underline. Player selection, volume, shuffle/repeat and queue controls are
hidden only in this view; the media services are preserved. A header search icon
opens Spotify search and real selectable results in a small popover. Escape
closes it and returns focus to the icon. Short screens use the existing scroll
viewport.

Opening Spotify morphs the panel width, height and contour over 1.8 seconds
with cubic easing, then fades its content in over 600 ms. This transition owns
the content entrance so the generic rail timer cannot reveal controls early.
Reduced motion bypasses the sequence.

Opening edge media morphs the bottom visualizer into the left rail over 2.2
seconds. Closing starts the reverse movement, fades content for 180 ms and
retracts the surface over 760 ms while retaining its height and last contour.
Repeated closing requests do not restart the exit; reopening reverses it.
Volume and brightness feedback preserve the media panel.

Topbar and sidebar glyphs share the right-edge hover motion without moving their
input areas. Volume and brightness use the same geometry/content sequence and
handoff as the other sidebar panels. Reduced motion bypasses these transitions.

Infinite Desktop temporarily reorganizes the existing topbar. Sidebar content
fades out in place with blur over 160 ms. Only then do the launcher/workspaces
slide enough to reserve space for volume, brightness, notifications, Bluetooth,
Wi-Fi and the profile. Spotify and WhatsApp retain the right edge. The sidebar
clock stays hidden; the existing topbar date/time keeps its normal component.
The bottom frame retracts into both corners before folding up its own edges,
while the side rails remain until the final part of the fold. The layout slide
and frame fold run for 240/430 ms, followed by a 180 ms blur fade in that reveals
sharp live icons. Disabling reverses the sequence and restores the normal bar
without changing the saved layout. Reduced motion settles immediately, and
switching directions during a transition resumes from the current values.

The desktop spectrum occupies 9.2%–93% of the output width and the bottom
14% of the screen (capped at 170 logical pixels). Only the peaks are narrowed;
the existing frame keeps its full width and single material. Smooth endpoint
fades return the wave to the fixed bottom strip with zero endpoint slope.
Native and fallback paths use the same horizontal bounds and lower region.

Desktop audio uses absolute per-band levels from a 64 ms Hann window, with
fast attack and a slower decay. It averages stereo channel energy to preserve
opposite-phase material and gates very quiet input instead of renormalizing it
to the tallest peak in each frame. Its independent 96-band snapshot leaves
media contours and the percussion detector's existing input unchanged. Capture
is still shared. Desktop publication follows display ticks, capped at 60 sends
per second, and stops once there is no new audio or material change. Presented
GPU FPS and actual device latency require measurement in the live session.

The desktop visualizer toggle also governs its migration onto the left frame
when Spotify or Lyrics opens. Disabled, the wave stays out of the left frame;
disabling it during migration removes that wave immediately. The media panel
and its own audio/lyric contour remain available. Enabled, the existing dock
and undock animations remain active.

The compact Bluetooth device icons now connect or disconnect on click, Enter,
Space or the accessible action. They no longer open hover name labels. A small
activity indicator marks the pending device and blocks duplicate actions; the
connected dot follows BlueZ's actual state. The expanded manager offers a
separate connection action alongside confirmed removal. Pairing confirmations
and PIN entry stay inside the menu; successful pairing connects automatically.
Leaving or closing the menu does not cancel a pending connection/disconnection.
Closing an interactive pairing session still cancels its unanswered request.

Known paired/bonded devices connect directly without starting discovery or
silently pairing again. The helper bounds connect/disconnect commands, verifies
the actual device state and reports BlueZ failures even when bluetoothctl exits
with status zero. Errors appear inside the Bluetooth menu. Neither this path
nor pairing launches Blueman. The `velora.bluetoothConnect(address)` IPC uses
the same backend; `bluetoothState` reports device states and the pending action.

The sidebar media card is temporarily disabled. Existing media services and
transport functions remain available. Settings, power profiles and monitor
controls retain their backend operations, including monitor rollback.

The test suite is included in the repository; see [validation](../tests/README.md).
Compositor visual approval, tests and measured performance are distinct: no
performance improvement percentage is claimed. Physical multi-monitor coverage
and a new controlled performance comparison remain outside this release check.
