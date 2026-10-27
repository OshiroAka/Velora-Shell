# Settings, edge media and motion

Settings now group controls into ten searchable categories and load pages on
demand. Widget previews, material choices, wallpaper comparisons and finite
motion previews keep related adjustments together. Settings share the bar's
material and form a continuous surface with the bottom frame. Configuration
continues through the existing controllers and persistence services.

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
