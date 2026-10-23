# 3D Spatial Parallax Wallpaper Setup for Wayland

Interactive 3D spatial mouse-tilt wallpaper setup for any Wayland compositor supporting wlr-layer-shell (Niri, Hyprland, Sway, River, Wayfire, Labwc).

---

## Overview

This setup uses [shiftpaper](https://github.com/CPritch/shiftpaper) powered by the MoGe-2 depth estimation model to generate metric 3D depth maps for wallpapers. As you move your mouse cursor across the desktop, the background tilts in perspective real-time (60 FPS) with low resource overhead.

### Key Features
* Universal Wayland support across any window manager or desktop shell.
* Automatic screen resolution detection and Lanczos scaling (no image distortion).
* Tuned parallax intensity (0.004) preventing edge-stretching artifacts while preserving depth.
* Lightweight systemd user service integration (`shiftpaperd.service`).

---

## Dependencies

* shiftpaper (AUR: `shiftpaper` or `shiftpaper-git`)
* python
* python-pillow (for auto-scaling wallpapers to screen resolution)

---

## Installation

```bash
git clone https://github.com/LawrenceTanny/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your active monitor resolution.
2. Check dependencies and prompt to install missing packages via paru/yay/pacman.
3. Present available wallpapers and automatically scale the selected image to your resolution.
4. Apply the tuned parallax intensity configuration (`0.004`) to `~/.config/shiftpaper/config.toml`.
5. Bake the 3D depth map and enable `shiftpaperd.service`.

---

## Manual Usage

To change wallpaper manually with shiftpaper:

```bash
shiftpaper set /path/to/your/image.png
```

To adjust 3D tilt strength, edit `~/.config/shiftpaper/config.toml`:

```toml
[daemon]
parallax_intensity = 0.004
cursor_poll_hz = 60
```

Then reload the daemon:

```bash
pkill -HUP shiftpaperd
```

---

## Special Thanks and Artwork Credits

Artwork by Zheng Wei Gu (GUWEIZ). Please support the original artist:

* ArtStation: https://www.artstation.com/guweiz
* X (Twitter): https://x.com/ttguweiz
* Instagram: https://www.instagram.com/guweiz/
* Patreon: https://www.patreon.com/guweiz
* YouTube: https://www.youtube.com/@GUWEIZ
