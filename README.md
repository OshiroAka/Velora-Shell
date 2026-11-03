# Velora Shell

**A customizable desktop experience for Linux.**

**Velora Shell** is a visual interface built with **Quickshell** for **Hyprland**, designed to bring customization, animations, and everyday tools together in one place.

You can customize the top bar, widgets, panels, colors, and wallpapers. The project also includes audio, brightness, network, and Bluetooth controls, media features, and optional Spotify and WhatsApp integrations.

## Installation

Open a terminal **inside an active Hyprland session** and run:

```bash
git clone https://github.com/OshiroAka/Velora-Shell.git
cd Velora-Shell
./install.sh
```

Follow the instructions in the terminal and review any proposed changes before approving them. The installer checks the requirements, prepares the components, and attempts to start Velora Shell.

After installation, you can use:

```bash
velora start
velora stop
velora restart
velora status
```

If the `velora` command is not found, make sure `~/.local/bin` is included in your `PATH`.

## Dependencies

The installer is designed for **Arch Linux and CachyOS**, with an active **Hyprland/Wayland** session.

Main requirements:

- **Hyprland**, **Quickshell 0.3 or later**, and **Qt 6.8 or later**;
- **Python 3**, **Git**, **CMake**, **pkg-config**, and a compiler supporting **C++23**;
- **awww** or **swww** wallpaper backend, **Pillow**, and **pywal16**;
- **Zen Browser**, used by the browser shortcut, and the **Pixelon** font, used by VeLyrics;
- Additional system, audio, and image utilities checked by the installer.

**Optional features:** WhatsApp integration requires **Node.js 22.13 or later** and **npm**. Spotify integration can use **Spicetify**. Some effects and controls may require additional hardware or components.

> The installer identifies missing dependencies and prompts for authorization when package installation or session configuration changes are needed.
