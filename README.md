# 3D Spatial Parallax Wallpaper Setup

Interactive 3D spatial mouse-tilt wallpaper setup for Linux (Wayland) and Windows (10/11).

---

## Overview

This setup generates metric 3D depth maps for wallpapers, creating a real-time perspective tilt reacting to your cursor movement at 60 FPS with low resource usage.

### Platform Support
* Linux (Wayland): Native OpenGL/Vulkan rendering on wlr-layer-shell via shiftpaper.
* Windows (10/11): Hardware-accelerated WebGL depth shader via Lively Wallpaper.

### Key Features
* Auto-OS detection: Single installer detects Linux or Windows automatically.
* Automatic screen resolution detection and Lanczos scaling.
* Tuned parallax intensity preventing edge-stretching artifacts while preserving depth.
* Includes 5 curated wallpapers by GUWEIZ with matching pre-baked 3D depth maps.

---

## Dependencies

### Linux (Wayland)
* shiftpaper (AUR: `shiftpaper` or `shiftpaper-git`)
* python & python-pillow

### Windows (10/11)
* Lively Wallpaper (Free & Open Source, installable via `winget`)
* Git for Windows (to run Git Bash)

---

## Installation

### Linux
```bash
git clone https://github.com/LawrenceTanny/Noctalia-Desktop-Rice.git ~/TannyRice
cd ~/TannyRice
chmod +x install.sh
./install.sh
```

### Windows
1. Open Git Bash in your terminal:
```bash
git clone https://github.com/LawrenceTanny/Noctalia-Desktop-Rice.git
cd Noctalia-Desktop-Rice
./install.sh
```
*(Or double-click `install.bat`)*

The installer automatically detects whether you are on Linux or Windows:
1. Detects your active screen resolution.
2. Verifies dependencies and offers to install them automatically.
3. Lets you pick your preferred wallpaper from the collection.
4. Auto-scales the wallpaper and depth map to your screen resolution.
5. Activates the 3D parallax spatial effect.

---

## Manual Usage

### Linux (Wayland)
```bash
shiftpaper set /path/to/your/image.png
```

To adjust 3D tilt strength, edit `~/.config/shiftpaper/config.toml`:
```toml
[daemon]
parallax_intensity = 0.0055
cursor_poll_hz = 60
```
Reload daemon:
```bash
pkill -HUP shiftpaperd
```

### Windows
To load in Lively Wallpaper manually:
1. Open Lively Wallpaper.
2. Drag and drop the `assets/lively-parallax` folder into Lively.

---

## Special Thanks and Artwork Credits

Artwork by Zheng Wei Gu (GUWEIZ). Please support the original artist:

* ArtStation: https://www.artstation.com/guweiz
* X (Twitter): https://x.com/ttguweiz
* Instagram: https://www.instagram.com/guweiz/
* Patreon: https://www.patreon.com/guweiz
* YouTube: https://www.youtube.com/@GUWEIZ
