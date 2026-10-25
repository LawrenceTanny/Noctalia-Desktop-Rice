#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DATE="$(date +%Y%m%d_%H%M%S)"

clear 2>/dev/null || true

is_windows() {
    case "$(uname -s)" in
        CYGWIN*|MINGW*|MSYS*) return 0 ;;
        *)
            if [ "$OS" = "Windows_NT" ]; then
                return 0
            fi
            return 1
            ;;
    esac
}

scale_image() {
    local src="$1"
    local tw="$2"
    local th="$3"
    local out="$4"

    if python3 -c "import PIL" &>/dev/null; then
        python3 -c "
import sys
from PIL import Image
src, tw, th, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
im = Image.open(src)
scale = max(tw / im.width, th / im.height)
nw, nh = int(round(im.width * scale)), int(round(im.height * scale))
res = im.resize((nw, nh), Image.Resampling.LANCZOS)
x0, y0 = (nw - tw) // 2, (nh - th) // 2
res.crop((x0, y0, x0 + tw, y0 + th)).save(out, format='PNG')
" "$src" "$tw" "$th" "$out"
    elif python -c "import PIL" &>/dev/null; then
        python -c "
import sys
from PIL import Image
src, tw, th, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
im = Image.open(src)
scale = max(tw / im.width, th / im.height)
nw, nh = int(round(im.width * scale)), int(round(im.height * scale))
res = im.resize((nw, nh), Image.Resampling.LANCZOS)
x0, y0 = (nw - tw) // 2, (nh - th) // 2
res.crop((x0, y0, x0 + tw, y0 + th)).save(out, format='PNG')
" "$src" "$tw" "$th" "$out"
    elif command -v powershell.exe &>/dev/null; then
        powershell.exe -NoProfile -Command "
            Add-Type -AssemblyName System.Drawing
            \$src = [System.Drawing.Image]::FromFile('$src')
            \$bmp = New-Object System.Drawing.Bitmap($tw, $th)
            \$g = [System.Drawing.Graphics]::FromImage(\$bmp)
            \$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            \$scale = [Math]::Max($tw / \$src.Width, $th / \$src.Height)
            \$nw = [int][Math]::Round(\$src.Width * \$scale)
            \$nh = [int][Math]::Round(\$src.Height * \$scale)
            \$x0 = [int](($tw - \$nw) / 2)
            \$y0 = [int](($th - \$nh) / 2)
            \$g.DrawImage(\$src, \$x0, \$y0, \$nw, \$nh)
            \$bmp.Save('$out', [System.Drawing.Imaging.ImageFormat]::Png)
            \$src.Dispose()
            \$g.Dispose()
            \$bmp.Dispose()
        " 2>/dev/null || cp -f "$src" "$out"
    else
        cp -f "$src" "$out"
    fi
}

if is_windows; then
    echo -e "${CYAN}${BOLD}Windows 3D Spatial Wallpaper Setup${NC}\n"

    detect_windows_res() {
        local r=""
        if command -v powershell.exe &>/dev/null; then
            r=$(powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width.ToString() + 'x' + [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height.ToString()" 2>/dev/null | tr -d '\r')
        fi
        if [ -n "$r" ]; then
            echo "$r"
        else
            echo "1920x1080"
        fi
    }

    WIN_RES="$(detect_windows_res)"
    echo -e "${BOLD}${BLUE}==> [1/3] Detected Screen Resolution:${NC} ${GREEN}$WIN_RES${NC}\n"

    echo -e "${BOLD}${BLUE}==> [2/3] Checking Required Dependencies:${NC}"
    if command -v Lively.exe &>/dev/null || [ -f "$LOCALAPPDATA/Programs/Lively Wallpaper/Lively.exe" ] || [ -f "C:/Program Files/Lively Wallpaper/Lively.exe" ]; then
        echo -e "  [OK] Lively Wallpaper"
    else
        echo -e "  [MISSING] Lively Wallpaper (Open Source 3D Wallpaper Engine for Windows)"
        if command -v winget.exe &>/dev/null || command -v winget &>/dev/null; then
            read -rp "Install Lively Wallpaper via winget now? [Y/n]: " do_winget
            do_winget="${do_winget:-y}"
            if [[ "$do_winget" =~ ^[Yy]$ ]]; then
                winget install --id rocksdanister.LivelyWallpaper -e --accept-package-agreements --accept-source-agreements || true
            fi
        fi
    fi

    echo -e "\n${BOLD}${BLUE}==> [3/3] Choose Wallpaper to Install:${NC}"
    WALLPAPERS=()
    while IFS= read -r -d '' file; do
        WALLPAPERS+=("$file")
    done < <(find "$DOTFILES_DIR/assets/wallpapers" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -iname "*.depth.png" -print0 | sort -z)

    TOTAL_WP=${#WALLPAPERS[@]}
    if [ $TOTAL_WP -eq 0 ]; then
        echo -e "  ${YELLOW}No wallpapers found in $DOTFILES_DIR/assets/wallpapers/${NC}"
        exit 1
    fi

    for i in "${!WALLPAPERS[@]}"; do
        echo -e "  $((i+1))) $(basename "${WALLPAPERS[$i]}")"
    done
    echo -e "  s) Skip wallpaper selection\n"

    read -rp "Select wallpaper [1-$TOTAL_WP, Default: 1]: " wp_choice
    wp_choice="${wp_choice:-1}"

    if [[ "$wp_choice" =~ ^[0-9]+$ ]] && [ "$wp_choice" -ge 1 ] && [ "$wp_choice" -le "$TOTAL_WP" ]; then
        CHOSEN_WALLPAPER="${WALLPAPERS[$((wp_choice-1))]}"
        DEPTH_MAP="${CHOSEN_WALLPAPER%.*}.depth.png"
        TARGET_W="${WIN_RES%x*}"
        TARGET_H="${WIN_RES#*x}"

        BUNDLE_DIR="$DOTFILES_DIR/assets/lively-parallax"
        mkdir -p "$BUNDLE_DIR"

        echo -e "\n${CYAN}Preparing $(basename "$CHOSEN_WALLPAPER") for $WIN_RES...${NC}"
        scale_image "$CHOSEN_WALLPAPER" "$TARGET_W" "$TARGET_H" "$BUNDLE_DIR/wallpaper.png"

        if [ -f "$DEPTH_MAP" ]; then
            echo -e "  [OK] Found matching 3D depth map."
            scale_image "$DEPTH_MAP" "$TARGET_W" "$TARGET_H" "$BUNDLE_DIR/depth.png"
        fi

        LIVELY_LIB_DIR="$LOCALAPPDATA/Lively Wallpaper/Library/wallpapers/3D_Spatial_Wallpaper"
        if [ -d "$LOCALAPPDATA/Lively Wallpaper" ]; then
            mkdir -p "$LIVELY_LIB_DIR"
            cp -rf "$BUNDLE_DIR/"* "$LIVELY_LIB_DIR/"
            echo -e "  [OK] Copied 3D wallpaper bundle to Lively Wallpaper library."
        fi

        LIVELY_BIN=""
        if command -v Lively.exe &>/dev/null; then
            LIVELY_BIN="Lively.exe"
        elif [ -f "$LOCALAPPDATA/Programs/Lively Wallpaper/Lively.exe" ]; then
            LIVELY_BIN="$LOCALAPPDATA/Programs/Lively Wallpaper/Lively.exe"
        elif [ -f "C:/Program Files/Lively Wallpaper/Lively.exe" ]; then
            LIVELY_BIN="C:/Program Files/Lively Wallpaper/Lively.exe"
        fi

        if [ -n "$LIVELY_BIN" ]; then
            "$LIVELY_BIN" setwp --file "$BUNDLE_DIR" 2>/dev/null || "$LIVELY_BIN" 2>/dev/null || true
            echo -e "  [OK] Dispatched wallpaper to Lively Wallpaper."
        else
            echo -e "\n  To activate in Lively Wallpaper:"
            echo -e "  1. Open Lively Wallpaper."
            echo -e "  2. Drag and drop the folder into Lively:"
            echo -e "     $BUNDLE_DIR"
        fi
    fi

    echo -e "\n${GREEN}${BOLD}Windows setup completed.${NC}\n"
    exit 0
fi

echo -e "${CYAN}${BOLD}Wayland 3D Spatial Wallpaper Setup${NC}\n"

detect_resolution() {
    for p in /sys/class/drm/card*-*; do
        if [ -f "$p/enabled" ] && grep -q "^enabled" "$p/enabled" 2>/dev/null; then
            local mode
            mode=$(head -n1 "$p/modes" 2>/dev/null)
            if [ -n "$mode" ]; then
                echo "$mode"
                return
            fi
        fi
    done
    echo "1920x1080"
}

RES="$(detect_resolution)"
echo -e "${BOLD}${BLUE}==> [1/3] Detected Screen Resolution:${NC} ${GREEN}$RES${NC}\n"

echo -e "${BOLD}${BLUE}==> [2/3] Checking Required Dependencies:${NC}"

MISSING_PKGS=()

if command -v shiftpaper &>/dev/null; then
    echo -e "  [OK] shiftpaper (3D Parallax Daemon)"
else
    echo -e "  [MISSING] shiftpaper (3D Parallax Daemon)"
    MISSING_PKGS+=("shiftpaper")
fi

if ! python3 -c "import PIL" &>/dev/null; then
    echo -e "  [MISSING] python-pillow (Image Scaling)"
    MISSING_PKGS+=("python-pillow")
fi

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Missing dependencies:${NC} ${MISSING_PKGS[*]}"
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v pacman &>/dev/null; then
        AUR_HELPER="sudo pacman"
    fi

    if [ -n "$AUR_HELPER" ]; then
        read -rp "Install missing dependencies with $AUR_HELPER now? [Y/n]: " do_install
        do_install="${do_install:-y}"
        if [[ "$do_install" =~ ^[Yy]$ ]]; then
            $AUR_HELPER -S --needed "${MISSING_PKGS[@]}"
        fi
    fi
fi

backup_config() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local bak="${target}.bak_${BACKUP_DATE}"
        echo -e "  Backed up: $target -> $bak"
        cp -r "$target" "$bak"
    fi
}

echo -e "\n${BOLD}${BLUE}==> [3/3] Choose Wallpaper to Install:${NC}"

WALLPAPERS=()
while IFS= read -r -d '' file; do
    WALLPAPERS+=("$file")
done < <(find "$DOTFILES_DIR/assets/wallpapers" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -iname "*.depth.png" -print0 | sort -z)

TOTAL_WP=${#WALLPAPERS[@]}

if [ $TOTAL_WP -eq 0 ]; then
    echo -e "  ${YELLOW}No wallpapers found in $DOTFILES_DIR/assets/wallpapers/${NC}"
    exit 1
fi

for i in "${!WALLPAPERS[@]}"; do
    echo -e "  $((i+1))) $(basename "${WALLPAPERS[$i]}")"
done
echo -e "  s) Skip wallpaper selection\n"

read -rp "Select wallpaper [1-$TOTAL_WP, Default: 1]: " wp_choice
wp_choice="${wp_choice:-1}"

if [[ "$wp_choice" =~ ^[0-9]+$ ]] && [ "$wp_choice" -ge 1 ] && [ "$wp_choice" -le "$TOTAL_WP" ]; then
    CHOSEN_WALLPAPER="${WALLPAPERS[$((wp_choice-1))]}"
    echo -e "\n${CYAN}Scaling $(basename "$CHOSEN_WALLPAPER") to $RES...${NC}"

    mkdir -p "$HOME/Pictures" "$HOME/.config/shiftpaper"
    TARGET_W="${RES%x*}"
    TARGET_H="${RES#*x}"

    scale_image "$CHOSEN_WALLPAPER" "$TARGET_W" "$TARGET_H" "$HOME/Pictures/active_wallpaper.png"

    backup_config "$HOME/.config/shiftpaper/config.toml"
    cp -f "$DOTFILES_DIR/shiftpaper/config.toml" "$HOME/.config/shiftpaper/config.toml"

    if command -v shiftpaper &>/dev/null; then
        echo -e "  Baking 3D depth map with MoGe-2..."
        shiftpaper set "$HOME/Pictures/active_wallpaper.png" || true
        systemctl --user enable --now shiftpaperd 2>/dev/null || true
        echo -e "  [OK] shiftpaperd service enabled and running."
    fi
fi

echo -e "\n${GREEN}${BOLD}Setup completed.${NC}"
echo -e "  Move your cursor across the desktop to view the 3D parallax effect."
echo -e "  Shiftpaper configuration saved to ~/.config/shiftpaper/config.toml\n"
