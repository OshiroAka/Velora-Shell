#!/usr/bin/env bash
set -euo pipefail

APP_NAME="velora-shell"
START_AFTER=0
VALIDATE_AFTER=0
INSTALL_DEPS=0
DEPS_ONLY=0
DEPS_DRY_RUN=0
CHECK_DEPS=1
SKIP_HYPR="${VELORA_SKIP_HYPR:-0}"
INSTALL_DIR="${VELORA_INSTALL_DIR:-}"
HYPR_CONFIG="${VELORA_HYPR_CONFIG:-}"
HYPR_MODE="${VELORA_HYPR_MODE:-include}"
HYPR_INCLUDE="${VELORA_HYPR_INCLUDE:-}"

usage() {
  printf '%s\n' \
    "Velora Shell installer" \
    "" \
    "Usage: ./install.sh [options]" \
    "" \
    "Options:" \
    "  --install-dir PATH   Install to PATH instead of XDG config dir" \
    "  --hypr-config PATH   Hyprland config file to patch" \
    "  --hypr-include PATH  Velora Hyprland snippet path" \
    "  --hypr-mode MODE     include, inline, or file-only (default: include)" \
    "  --deps               Install missing runtime/feature dependencies" \
    "  --deps-only          Only check/install dependencies, then exit" \
    "  --deps-dry-run       Print dependency install plan without installing" \
    "  --no-deps-check      Do not warn about missing dependencies" \
    "  --skip-hypr          Do not edit Hyprland config or add SUPER+K" \
    "  --start              Start Velora Shell after install" \
    "  --validate           Run a short Quickshell load check after install" \
    "  -h, --help           Show this help"
}

log() {
  printf '[velora-shell] %s\n' "$*"
}

warn() {
  printf '[velora-shell] warning: %s\n' "$*" >&2
}

fail() {
  printf '[velora-shell] error: %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --install-dir)
      [ $# -ge 2 ] || fail "--install-dir needs a path"
      INSTALL_DIR="$2"
      shift 2
      ;;
    --hypr-config)
      [ $# -ge 2 ] || fail "--hypr-config needs a path"
      HYPR_CONFIG="$2"
      shift 2
      ;;
    --hypr-include)
      [ $# -ge 2 ] || fail "--hypr-include needs a path"
      HYPR_INCLUDE="$2"
      shift 2
      ;;
    --hypr-mode)
      [ $# -ge 2 ] || fail "--hypr-mode needs include, inline, or file-only"
      HYPR_MODE="$2"
      shift 2
      ;;
    --deps)
      INSTALL_DEPS=1
      shift
      ;;
    --deps-only)
      INSTALL_DEPS=1
      DEPS_ONLY=1
      shift
      ;;
    --deps-dry-run)
      DEPS_DRY_RUN=1
      CHECK_DEPS=1
      shift
      ;;
    --no-deps-check)
      CHECK_DEPS=0
      shift
      ;;
    --skip-hypr)
      SKIP_HYPR=1
      shift
      ;;
    --start)
      START_AFTER=1
      shift
      ;;
    --validate)
      VALIDATE_AFTER=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

[ -n "${HOME:-}" ] || fail "HOME is not set"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${VELORA_SOURCE_DIR:-$SCRIPT_DIR/Velora Shell}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
INSTALL_DIR="${INSTALL_DIR:-$XDG_CONFIG_HOME/quickshell/$APP_NAME}"
HYPR_CONFIG="${HYPR_CONFIG:-$XDG_CONFIG_HOME/hypr/hyprland.conf}"
HYPR_INCLUDE="${HYPR_INCLUDE:-$(dirname "$HYPR_CONFIG")/velora-hyprland.conf}"

[ -f "$SOURCE_DIR/shell.qml" ] || fail "shell.qml not found in: $SOURCE_DIR"
[ -d "$SOURCE_DIR/components" ] || fail "components/ not found in: $SOURCE_DIR"

dedupe_words() {
  local item seen out
  seen=" "
  out=""

  for item in "$@"; do
    [ -n "$item" ] || continue
    case "$seen" in
      *" $item "*) ;;
      *)
        seen="${seen}${item} "
        out="${out}${out:+ }${item}"
        ;;
    esac
  done

  printf '%s\n' "$out"
}

shell_quote() {
  local value="$1"
  printf "'%s'" "$(printf '%s' "$value" | sed "s/'/'\\\\''/g")"
}

detect_pkg_manager() {
  if command -v yay >/dev/null 2>&1; then
    printf 'yay\n'
  elif command -v paru >/dev/null 2>&1; then
    printf 'paru\n'
  elif command -v pacman >/dev/null 2>&1; then
    printf 'pacman\n'
  elif command -v dnf >/dev/null 2>&1; then
    printf 'dnf\n'
  elif command -v apt-get >/dev/null 2>&1; then
    printf 'apt\n'
  elif command -v zypper >/dev/null 2>&1; then
    printf 'zypper\n'
  else
    printf 'manual\n'
  fi
}

pkg_for_command() {
  local manager="$1"
  local cmd="$2"

  case "$manager" in
    yay|paru|pacman)
      case "$cmd" in
        qs) printf 'quickshell' ;;
        hyprctl) printf 'hyprland' ;;
        python3) printf 'python' ;;
        rsync) printf 'rsync' ;;
        playerctl) printf 'playerctl' ;;
        wpctl) printf 'wireplumber' ;;
        nmcli) printf 'networkmanager' ;;
        makoctl) printf 'mako' ;;
        cava) printf 'cava' ;;
        wal) printf 'python-pywal16' ;;
        easyeffects) printf 'easyeffects calf lsp-plugins-lv2 zam-plugins-lv2' ;;
        pipewire-pulse) printf 'pipewire-pulse' ;;
        xdg-open) printf 'xdg-utils' ;;
        awww) printf 'awww' ;;
        linux-wallpaperengine) printf 'linux-wallpaperengine' ;;
        *) printf '%s' "$cmd" ;;
      esac
      ;;
    apt)
      case "$cmd" in
        qs) printf 'quickshell' ;;
        hyprctl) printf 'hyprland' ;;
        python3) printf 'python3' ;;
        rsync) printf 'rsync' ;;
        playerctl) printf 'playerctl' ;;
        wpctl) printf 'wireplumber' ;;
        nmcli) printf 'network-manager' ;;
        makoctl) printf 'mako-notifier' ;;
        cava) printf 'cava' ;;
        wal) printf 'python3-pywal' ;;
        easyeffects) printf 'easyeffects calf lsp-plugins-lv2 zam-plugins-lv2' ;;
        pipewire-pulse) printf 'pipewire-pulse' ;;
        xdg-open) printf 'xdg-utils' ;;
        awww|linux-wallpaperengine) printf '' ;;
        *) printf '%s' "$cmd" ;;
      esac
      ;;
    dnf)
      case "$cmd" in
        qs) printf 'quickshell' ;;
        hyprctl) printf 'hyprland' ;;
        python3) printf 'python3' ;;
        rsync) printf 'rsync' ;;
        playerctl) printf 'playerctl' ;;
        wpctl) printf 'wireplumber' ;;
        nmcli) printf 'NetworkManager' ;;
        makoctl) printf 'mako' ;;
        cava) printf 'cava' ;;
        wal) printf 'python3-pywal' ;;
        easyeffects) printf 'easyeffects calf lsp-plugins-lv2 zam-plugins-lv2' ;;
        pipewire-pulse) printf 'pipewire-pulseaudio' ;;
        xdg-open) printf 'xdg-utils' ;;
        awww|linux-wallpaperengine) printf '' ;;
        *) printf '%s' "$cmd" ;;
      esac
      ;;
    zypper)
      case "$cmd" in
        qs) printf 'quickshell' ;;
        hyprctl) printf 'hyprland' ;;
        python3) printf 'python3' ;;
        rsync) printf 'rsync' ;;
        playerctl) printf 'playerctl' ;;
        wpctl) printf 'wireplumber' ;;
        nmcli) printf 'NetworkManager' ;;
        makoctl) printf 'mako' ;;
        cava) printf 'cava' ;;
        wal) printf 'python3-pywal' ;;
        easyeffects) printf 'easyeffects calf lsp-plugins-lv2 zam-plugins-lv2' ;;
        pipewire-pulse) printf 'pipewire-pulseaudio' ;;
        xdg-open) printf 'xdg-utils' ;;
        awww|linux-wallpaperengine) printf '' ;;
        *) printf '%s' "$cmd" ;;
      esac
      ;;
    *)
      printf ''
      ;;
  esac
}

audio_feature_packages() {
  local manager="$1"

  case "$manager" in
    yay|paru|pacman)
      printf '%s\n' easyeffects pipewire-pulse wireplumber lsp-plugins-lv2 calf zam-plugins-lv2
      ;;
    apt)
      printf '%s\n' easyeffects pipewire-pulse wireplumber lsp-plugins-lv2 calf-plugins zam-plugins
      ;;
    dnf)
      printf '%s\n' easyeffects pipewire-pulseaudio wireplumber lsp-plugins-lv2 calf zam-plugins-lv2
      ;;
    zypper)
      printf '%s\n' easyeffects pipewire-pulseaudio wireplumber lsp-plugins-lv2 calf zam-plugins
      ;;
  esac
}

package_installed() {
  local manager="$1"
  local package="$2"

  case "$manager" in
    yay|paru|pacman)
      pacman -Q "$package" >/dev/null 2>&1
      ;;
    apt)
      dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'
      ;;
    dnf|zypper)
      rpm -q "$package" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

missing_audio_feature_packages() {
  local manager="$1"
  local package

  while IFS= read -r package; do
    [ -n "$package" ] || continue
    package_installed "$manager" "$package" || printf '%s\n' "$package"
  done
}

dependency_commands() {
  printf '%s\n' \
    rsync \
    playerctl \
    wpctl \
    cava \
    wal \
    easyeffects \
    pipewire-pulse \
    awww \
    mpvpaper \
    linux-wallpaperengine
}

missing_dependency_commands() {
  local cmd

  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    command -v "$cmd" >/dev/null 2>&1 || printf '%s\n' "$cmd"
  done
}

install_missing_dependencies() {
  local manager missing missing_audio packages manual cmd pkg sudo_cmd

  if [ "$CHECK_DEPS" != "1" ] && [ "$INSTALL_DEPS" != "1" ] && [ "$DEPS_DRY_RUN" != "1" ]; then
    return 0
  fi

  manager="$(detect_pkg_manager)"
  missing="$(dependency_commands | missing_dependency_commands | tr '\n' ' ')"
  missing="$(dedupe_words $missing)"
  missing_audio="$(missing_audio_feature_packages "$manager" | tr '\n' ' ')"
  missing_audio="$(dedupe_words $missing_audio)"

  if [ -z "$missing" ] && [ -z "$missing_audio" ]; then
    log "all checked dependencies are available"
    return 0
  fi

  packages=""
  manual=""

  for cmd in $missing; do
    pkg="$(pkg_for_command "$manager" "$cmd")"
    if [ -n "$pkg" ]; then
      packages="${packages}${packages:+ }${pkg}"
    else
      manual="${manual}${manual:+ }${cmd}"
    fi
  done

  if [ -n "$missing_audio" ]; then
    packages="${packages}${packages:+ }${missing_audio}"
  fi

  packages="$(dedupe_words $packages)"
  manual="$(dedupe_words $manual)"

  [ -z "$missing" ] || warn "missing commands: $missing"
  [ -z "$missing_audio" ] || warn "missing audio packages: $missing_audio"

  if [ "$INSTALL_DEPS" != "1" ] && [ "$DEPS_DRY_RUN" != "1" ]; then
    warn "run ./install.sh --deps to try installing them automatically"
    [ -z "$manual" ] || warn "manual install still needed for: $manual"
    return 0
  fi

  log "package manager: $manager"
  [ -n "$packages" ] && log "packages: $packages"
  [ -n "$manual" ] && warn "no package mapping for this distro: $manual"

  if [ "$DEPS_DRY_RUN" = "1" ]; then
    log "dependency dry-run complete"
    return 0
  fi

  [ -n "$packages" ] || {
    warn "nothing installable was mapped automatically"
    return 0
  }

  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    sudo_cmd="sudo"
  fi

  case "$manager" in
    yay|paru)
      "$manager" -S --needed $packages
      ;;
    pacman)
      $sudo_cmd pacman -S --needed $packages
      ;;
    apt)
      $sudo_cmd apt-get update
      $sudo_cmd apt-get install -y $packages
      ;;
    dnf)
      $sudo_cmd dnf install -y $packages
      ;;
    zypper)
      $sudo_cmd zypper install -y $packages
      ;;
    *)
      warn "no supported package manager found; install manually: $missing"
      return 0
      ;;
  esac
}

install_runtime() {
  local backup_dir

  if ! command -v rsync >/dev/null 2>&1; then
    fail "rsync is required to install cleanly; run ./install.sh --deps first"
  fi

  if [ "$SOURCE_DIR" = "$INSTALL_DIR" ]; then
    log "source and install dir are the same; skipping copy"
  else
    mkdir -p "$(dirname "$INSTALL_DIR")"

    if [ -d "$INSTALL_DIR" ] && [ -n "$(find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
      backup_dir="${INSTALL_DIR}.bak-$(date +%Y%m%d-%H%M%S)"
      cp -a "$INSTALL_DIR" "$backup_dir"
      log "backup created: $backup_dir"
    fi

    mkdir -p "$INSTALL_DIR"
    rsync -a --delete \
      --exclude='.git' \
      --exclude='.gitignore' \
      --exclude='install.sh' \
      --exclude='backups' \
      --exclude='backups/***' \
      --exclude='*.bak*' \
      --exclude='*.backup' \
      --exclude='*.orig' \
      --exclude='*.rej' \
      --exclude='*~' \
      --exclude='.#*' \
      --exclude='__pycache__' \
      --exclude='__pycache__/***' \
      --exclude='*.pyc' \
      --exclude='*.pyo' \
      --exclude='.pytest_cache' \
      --exclude='.mypy_cache' \
      --exclude='.ruff_cache' \
      --exclude='.qmlcache' \
      --exclude='qmlcache' \
      --exclude='themes/pywal16.json' \
      --exclude='velora-shell-pngs' \
      "$SOURCE_DIR/" "$INSTALL_DIR/"
  fi

  log "runtime installed to: $INSTALL_DIR"

  if [ -d "$INSTALL_DIR/scripts" ]; then
    chmod +x "$INSTALL_DIR"/scripts/velora-* 2>/dev/null || true
  fi
}

patch_hyprland() {
  local tmp_file backup_file include_dir install_dir_quoted

  if [ "$SKIP_HYPR" = "1" ]; then
    log "Hyprland config skipped"
    return 0
  fi

  case "$HYPR_MODE" in
    include|inline|file-only) ;;
    add) HYPR_MODE="include" ;;
    overwrite|replace) HYPR_MODE="inline" ;;
    file|snippet) HYPR_MODE="file-only" ;;
    *) fail "--hypr-mode must be include, inline, or file-only" ;;
  esac

  include_dir="$(dirname "$HYPR_INCLUDE")"
  install_dir_quoted="$(shell_quote "$INSTALL_DIR")"
  mkdir -p "$include_dir"
  cat > "$HYPR_INCLUDE" <<EOF
# Velora Shell Hyprland rules
# Matches velora-shell and every velora-shell-* layer namespace.
layerrule = blur on, match:namespace ^velora-shell($|-.*)
layerrule = blur_popups on, match:namespace ^velora-shell($|-.*)
layerrule = ignore_alpha 0.02, match:namespace ^velora-shell($|-.*)
bind = SUPER, K, exec, qs ipc -p ${install_dir_quoted} call velora wallpaper
EOF
  log "Hyprland snippet written: $HYPR_INCLUDE"

  if [ "$HYPR_MODE" = "file-only" ]; then
    log "Hyprland main config left unchanged"
    return 0
  fi

  if [ ! -f "$HYPR_CONFIG" ]; then
    warn "Hyprland config not found: $HYPR_CONFIG"
    warn "source $HYPR_INCLUDE manually if you want blur"
    return 0
  fi

  backup_file="${HYPR_CONFIG}.bak-velora-shell-$(date +%Y%m%d-%H%M%S)"
  cp "$HYPR_CONFIG" "$backup_file"
  tmp_file="$(mktemp)"

  awk '
    /^# >>> Velora Shell$/ { skip = 1; next }
    /^# <<< Velora Shell$/ { skip = 0; next }
    /^[[:space:]]*source[[:space:]]*=[[:space:]]*.*velora-hyprland\.conf[[:space:]]*$/ { next }
    /^[[:space:]]*#[[:space:]]*Velora Shell[[:space:]]*$/ { legacy = 1; next }
    legacy == 1 && /^[[:space:]]*layerrule[[:space:]]*=.*match:namespace[[:space:]]+\^?velora-shell/ { next }
    legacy == 1 && /^[[:space:]]*bind[[:space:]]*=.*SUPER[[:space:]]*,[[:space:]]*K[[:space:]]*,.*velora.*wallpaper/ { next }
    legacy == 1 && /^[[:space:]]*$/ { legacy = 0; next }
    /^[[:space:]]*layerrule[[:space:]]*=.*match:namespace[[:space:]]+\^?velora-shell/ { next }
    /^[[:space:]]*bind[[:space:]]*=.*SUPER[[:space:]]*,[[:space:]]*K[[:space:]]*,.*velora.*wallpaper/ { next }
    skip != 1 { print }
  ' "$HYPR_CONFIG" > "$tmp_file"

  if [ "$HYPR_MODE" = "inline" ]; then
    {
      cat "$tmp_file"
      printf '\n# >>> Velora Shell\n'
      cat "$HYPR_INCLUDE"
      printf '# <<< Velora Shell\n'
    } > "$HYPR_CONFIG"
    log "compact Velora rules written inline"
  else
    {
      cat "$tmp_file"
      printf '\n# >>> Velora Shell\n'
      printf 'source = %s\n' "$HYPR_INCLUDE"
      printf '# <<< Velora Shell\n'
    } > "$HYPR_CONFIG"
    log "Hyprland config now sources Velora snippet"
  fi

  rm -f "$tmp_file"
  log "Hyprland backup created: $backup_file"

  if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl reload >/dev/null 2>&1; then
      log "Hyprland reloaded"
    else
      warn "hyprctl reload failed; reload Hyprland manually"
    fi
  fi
}

validate_quickshell() {
  local log_file status

  if [ "$VALIDATE_AFTER" != "1" ]; then
    return 0
  fi

  if ! command -v qs >/dev/null 2>&1; then
    warn "qs not found; skipping Quickshell validation"
    return 0
  fi

  log_file="${TMPDIR:-/tmp}/velora-shell-install-validate.log"
  status=0
  timeout 8s qs -p "$INSTALL_DIR" --no-color --log-times >"$log_file" 2>&1 || status=$?

  if grep -q "Configuration Loaded" "$log_file"; then
    log "Quickshell validation passed"
  else
    warn "Quickshell validation did not report Configuration Loaded"
    warn "log: $log_file"
    return "$status"
  fi
}

stop_existing_shell() {
  local config_file pass pids pid

  if ! command -v qs >/dev/null 2>&1; then
    return 0
  fi

  config_file="$INSTALL_DIR/shell.qml"

  for pass in 1 2 3 4 5; do
    pids="$(qs list --all 2>/dev/null | awk -v path="$config_file" '
      /^Instance / { pid = ""; next }
      /^[[:space:]]*Process ID:/ { pid = $3; next }
      /^[[:space:]]*Config path:/ {
        sub(/^[[:space:]]*Config path:[[:space:]]*/, "")
        if ($0 == path && pid != "")
          print pid
      }
    ')"

    [ -n "$pids" ] || break

    for pid in $pids; do
      qs kill --pid "$pid" >/dev/null 2>&1 || true
    done

    sleep 0.2
  done
}

start_shell() {
  if [ "$START_AFTER" != "1" ]; then
    return 0
  fi

  if ! command -v qs >/dev/null 2>&1; then
    warn "qs not found; cannot start Velora Shell"
    return 0
  fi

  stop_existing_shell
  qs -d -p "$INSTALL_DIR"
}

install_missing_dependencies

if [ "$DEPS_ONLY" = "1" ] || [ "$DEPS_DRY_RUN" = "1" ]; then
  log "dependency step finished"
  exit 0
fi

install_runtime
patch_hyprland
validate_quickshell
start_shell

log "installed to: $INSTALL_DIR"
log "run with: qs -p \"$INSTALL_DIR\""
