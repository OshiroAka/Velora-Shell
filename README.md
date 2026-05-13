# Velora Shell

Velora Shell is a pastel soft-glass desktop shell for Quickshell/Hyprland.

## Structure

```text
Velora-Shell/
├── Velora Shell/   # shell source files
├── install.sh      # installer
└── README.md
```

The folder `Velora Shell/` contains the Quickshell config:

```text
assets/
components/
scripts/
themes/
shell.qml
```

## Install

```bash
git clone <repo-url> Velora-Shell
cd Velora-Shell
./install.sh
```

The installer copies `Velora Shell/` to:

```text
~/.config/quickshell/velora-shell
```

It writes Velora's Hyprland rules to:

```text
~/.config/hypr/velora-hyprland.conf
```

By default, the installer only adds a small source block to `hyprland.conf`:

```text
# >>> Velora Shell
source = ~/.config/hypr/velora-hyprland.conf
# <<< Velora Shell
```

Use `--skip-hypr` if you do not want the installer to edit Hyprland config.

## Run

```bash
qs -p ~/.config/quickshell/velora-shell
```

Or start it by config name after installing:

```bash
qs -d -c velora-shell
```

## Useful Installer Options

```bash
./install.sh --validate
./install.sh --start
./install.sh --deps
./install.sh --deps-dry-run
./install.sh --skip-hypr
./install.sh --hypr-mode include
./install.sh --hypr-mode inline
./install.sh --hypr-mode file-only
./install.sh --install-dir "$HOME/.config/quickshell/velora-shell"
```

For isolated testing:

```bash
./install.sh --install-dir /tmp/velora-shell-test --skip-hypr --validate
```

## Install Feature Dependencies

The installer can install the main wallpaper/theme backends:

```bash
./install.sh --deps
```

On Arch-based systems this maps to:

```bash
yay -S linux-wallpaperengine pywal16 awww mpvpaper
```

Supported managers are `yay`, `paru`, `pacman`, `dnf`, `apt-get`, and `zypper`.
On non-Arch distros, some wallpaper backends may still need manual install.

## Base Dependencies

Required:

- `quickshell`
- `hyprland`
- `rsync`
- `bash`
- `python3`

Optional but used by features:

- `playerctl`
- `wpctl`
- `brightnessctl`
- `nmcli`
- `makoctl`
- `pywal16`
- `awww`
- `mpvpaper`
- `linux-wallpaperengine`
- `cava`
- `ffmpeg`

## Hyprland Blur Rules

If you skip the Hyprland step, add this to a Hyprland config file:

```conf
layerrule = blur on, match:namespace ^velora-shell($|-.*)
layerrule = blur_popups on, match:namespace ^velora-shell($|-.*)
layerrule = ignore_alpha 0.12, match:namespace ^velora-shell($|-.*)
```

`^velora-shell($|-.*)` matches the main namespace and every Velora layer that
starts with `velora-shell-`, such as `velora-shell-frame` and
`velora-shell-drawers`.

## Notes

- User-specific backups, generated pywal data, `.codex`, `.agents`, `__pycache__`, and old `.bak` QML files are intentionally excluded.
- `Velora Shell/themes/pywal16.json` is generated locally from `~/.cache/wal/colors.json` and is ignored by Git.
