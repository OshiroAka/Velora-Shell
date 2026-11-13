# Wallpaper transitions

Images use the existing awww/swww transition directly, including native Wave.
The picker and composition/profile helper both respect the saved effect and
duration. Switching static wallpapers does not prepare an additional surface.

With the live shader preference, video handoffs use the optional Hyprland
plugin's `wallpaper-transition` capability. The compositor snapshots the
outgoing wallpaper into GPU memory, then blends its wave mask over the new
background in the same render pass. The old video frame remains frozen during
the short reveal. No pixels are exported to PNG or decoded by Qt, and no extra
QML window, hidden player or second video decoder is created.

`scripts/wallpaper-transition.sh` queries the shell's capability/motion policy,
then waits only for the compositor's snapshot acknowledgement through a bounded
native IPC call. This prevents replacement from racing an asynchronous QML
dispatch. Reveal starts after the incoming video is ready. Wallpaper application
does not wait for the animation duration; the compositor owns its clock, damage
and texture cleanup. Prepared frames expire after five seconds if abandoned.
Stale cancellation tokens cannot remove a newer transition.

Wave has broad moving crests, a subtle harmonic and refraction restricted to
its front. Grow and Outer account for physical aspect ratio. Five modes have
exact alpha endpoints, and eight directions avoid immediate repetition. The
snapshot already contains the actual outgoing crop and colour conversion.
There is one temporary outgoing GPU framebuffer per available display and one
blend draw per damaged wallpaper region during the effect; there is no incoming
framebuffer copy each animation frame.

Both helpers share the wallpaper request lock. The persistent mpvpaper player
is reused when possible. The picker publishes state only after successful
application. If the plugin, shell or snapshot is unavailable, videos load
directly. Static wallpapers retain the backend effect. The live `native`
preference retains its existing backend path. Shader mode no longer inserts
an intermediate still-image preview on a cold video start.

Build and load the compositor plugin using the existing ABI-verified workflow:

```sh
./scripts/build
./scripts/load-native-blur /path/to/verified/velora-blur.so
```

Focused validation:

```sh
python3 -m unittest discover -s tests -p test_wallpaper_transition.py -v
```

Four tests exercise both helpers and all image/video handoffs, native static
Wave, player reuse, failed application/preparation, cancellation, unsupported
plugins and identical profile assets. They verify native and Lua dispatch,
including acknowledgement errors, and that a three-second reveal does not hold
the application request. A deterministic C++ test checks the production clock,
expiry and tokens. Surfaceless EGL compiles the exact production GLSL and checks
pixels for all modes, eight directions, landscape/portrait, wave crests, alpha
endpoints and source-over blending without holes.

These checks do not replace live compositor review or measure hardware speed.
