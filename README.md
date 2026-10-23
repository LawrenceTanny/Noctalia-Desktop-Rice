<div align="center">

# ⛩️ CachyOS + Wayland 3D Spatial Wallpaper
### *Interactive 3D Mouse Parallax Wallpaper powered by Shiftpaper & MoGe-2*

![OS](https://img.shields.io/badge/OS-CachyOS%20Linux-blue?style=for-the-badge&logo=archlinux)
![Compositor](https://img.shields.io/badge/Compositor-Wayland%20(Niri%20/%20Hyprland%20/%20Sway)-teal?style=for-the-badge)
![Engine](https://img.shields.io/badge/Engine-Shiftpaper%203D-purple?style=for-the-badge)
![Model](https://img.shields.io/badge/Model-MoGe--2%20Metric%20Depth-orange?style=for-the-badge)

</div>

---

## 🎬 Showcase

https://github.com/user-attachments/assets/a0bbdce1-7f29-46b3-af2b-52f99c56efb3

<div align="center">
  <p><i>Real-time 3D camera parallax perspective reacting to mouse movement on Wayland.</i></p>
</div>

---

## ✨ Features & Highlights

### 🌌 1. 3D Spatial Mouse Parallax Engine
* **Engine:** Powered by [`shiftpaper`](https://github.com/CPritch/shiftpaper) with **MoGe-2** metric depth estimation.
* **Smooth Camera Projection:** Configured with a tuned `parallax_intensity = 0.004` in `config.toml` for smooth, responsive 3D perspective tilting without blurry edge-stretching artifacts.
* **Universal Wayland Compatibility:** Works out-of-the-box on any Wayland compositor supporting `wlr-layer-shell` (Niri, Hyprland, Sway, River, Wayfire, Labwc).
* **Low Overhead:** Native OpenGL/Vulkan rendering on the `background` layer (~0% CPU, low VRAM).

### 📐 2. Automatic Screen Resolution Scaling
* **Zero Distortion:** Automatically detects your active monitor resolution from sysfs (e.g. 1600×900, 1080p, 1440p, 4K).
* **Lanczos Resampling:** Scales and crops chosen wallpapers to match your screen resolution without stretching or quality loss.

### 🖼️ 3. Curated GUWEIZ Wallpaper Collection
Includes 5 dark fantasy and urban anime wallpapers by GUWEIZ ready to bake:
1. `Image 1.jpg` - Katana in Moody Dark Mist
2. `Image 2.png` - Urban Street with Headphones
3. `Image 3.jpg` - Cyberpunk Girl in Rainy Neon City
4. `Image 4.png` - Rainy Alleyway with Black Cat
5. `Image 5.png` - Warrior Girl with Glowing Spear & Armor (Showcase Default)

---

## 🛠️ Requirements

* **Wayland Compositor** (Niri, Hyprland, Sway, River, etc.)
* **shiftpaper** (AUR: `shiftpaper` or `shiftpaper-git`)
* **python** & **python-pillow** (for automated resolution scaling)

---

## 📥 Installation

```bash
# 1. Clone the repository
git clone https://github.com/LawrenceTanny/Noctalia-Desktop-Rice.git ~/TannyRice
cd ~/TannyRice

# 2. Run the installer
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your active display resolution.
2. Check for dependencies and offer to install any missing packages via `paru`, `yay`, or `pacman`.
3. Let you choose a wallpaper from the pack (or use your own).
4. Scale the wallpaper to your resolution.
5. Bake the 3D depth map with MoGe-2 and enable the background daemon (`shiftpaperd.service`).

---

## ⚙️ Manual Adjustments

To switch wallpapers at any time:

```bash
shiftpaper set /path/to/your/image.png
```

To adjust the 3D tilt strength, edit `~/.config/shiftpaper/config.toml`:

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

## 🎨 Special Thanks & Artwork Credits

A massive thank you and deep appreciation to **Zheng Wei Gu ([GUWEIZ](https://www.artstation.com/guweiz))** for creating the extraordinary, atmospheric dark fantasy and urban anime artwork featured in this project. 

Please support the original artist across their platforms:

* 🎨 **ArtStation:** [artstation.com/guweiz](https://www.artstation.com/guweiz)
* 🐦 **X (Twitter):** [@ttguweiz](https://x.com/ttguweiz)
* 📸 **Instagram:** [@guweiz](https://www.instagram.com/guweiz/)
* 💖 **Patreon:** [patreon.com/guweiz](https://www.patreon.com/guweiz)
* 🎬 **YouTube:** [@GUWEIZ](https://www.youtube.com/@GUWEIZ)

---

## 📜 System & Open Source Credits
* [Shiftpaper](https://github.com/CPritch/shiftpaper) by CPritch for the 3D depth-map parallax daemon.
* [CachyOS Team](https://cachyos.org/) for the Linux kernel and Wayland gaming distribution.
* [Wallhaven](https://wallhaven.cc/) community for wallpaper curation.
