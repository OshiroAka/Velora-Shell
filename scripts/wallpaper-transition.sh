#!/usr/bin/env bash
# A short IPC arms GPU-only wallpaper rendering. Animation runs independently
# in the compositor; applying a wallpaper never waits for its duration.
wallpaper_transition_shell=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
wallpaper_transition_token=""
wallpaper_transition_backend=""
wallpaper_wave_prepared=0

wallpaper_transition_dispatch() {
  local arguments="$*" result
  case "$wallpaper_transition_backend" in
    native) result=$(timeout .25 hyprctl dispatch velora-blur:wallpaper-transition "$arguments" 2>/dev/null) || return 1 ;;
    lua) result=$(timeout .25 hyprctl dispatch "function() hl.plugin.velora.dispatch(\"wallpaper-transition\",\"$arguments\") end" 2>/dev/null) || return 1 ;;
    *) return 1 ;;
  esac
  [ "$result" = ok ]
}

wallpaper_transition_cancel() {
  if [ -n "$wallpaper_transition_token" ]; then
    wallpaper_transition_dispatch cancel "$wallpaper_transition_token" >/dev/null 2>&1 || true
  fi
  wallpaper_transition_token=""
  wallpaper_transition_backend=""
  wallpaper_wave_prepared=0
}

wallpaper_transition_prepare() {
  local old_kind=$1 old_path=$2 effect=$3 duration=$4
  [ -f "$old_path" ] || return 1
  case "$old_kind" in static|bg|live|mpv) ;; *) return 1 ;; esac
  case "$effect" in fade|wave|wipe|grow|outer) ;; *) return 1 ;; esac
  command -v qs >/dev/null 2>&1 || return 1
  command -v hyprctl >/dev/null 2>&1 || return 1
  wallpaper_transition_cancel
  local duration_ms
  wallpaper_transition_backend=$(timeout .25 qs ipc -p "$wallpaper_transition_shell" call velora \
    wallpaperNativeTransitionBackend prepare 2>/dev/null) || wallpaper_transition_backend=""
  case "$wallpaper_transition_backend" in native|lua) ;; *) return 1 ;; esac
  wallpaper_transition_token="$(date +%s%N)-$$"
  duration_ms=$(awk -v duration="$duration" 'BEGIN {
    if (duration !~ /^[0-9]+([.][0-9]+)?$/) duration=.42;
    if (duration<.15) duration=.15; if (duration>3) duration=3;
    printf "%d", duration * 1000;
  }')
  # This reply acknowledges the GPU snapshot itself. An asynchronous QML
  # dispatch could let the wallpaper replacement race ahead of preparation.
  wallpaper_transition_dispatch prepare "$wallpaper_transition_token" "$effect" "$duration_ms" \
    || { wallpaper_transition_cancel; return 1; }
  wallpaper_wave_prepared=1
}

wallpaper_transition_reveal() {
  [ "$wallpaper_wave_prepared" -eq 1 ] || return 1
  if ! wallpaper_transition_dispatch reveal "$wallpaper_transition_token"; then
    wallpaper_transition_cancel
    return 1
  fi
  # Ownership is now in the compositor. Its timer releases the GPU frame.
  wallpaper_transition_token=""
  wallpaper_transition_backend=""
  wallpaper_wave_prepared=0
}
