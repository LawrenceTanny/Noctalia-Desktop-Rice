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
done < <(find "$DOTFILES_DIR/assets/wallpapers" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 | sort -z)

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

    python3 -c "
import sys
from PIL import Image

src = sys.argv[1]
target_w = int(sys.argv[2])
target_h = int(sys.argv[3])
out_path = sys.argv[4]

im = Image.open(src)
scale = max(target_w / im.width, target_h / im.height)
new_w = int(round(im.width * scale))
new_h = int(round(im.height * scale))

resized = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
x0 = (new_w - target_w) // 2
y0 = (new_h - target_h) // 2
cropped = resized.crop((x0, y0, x0 + target_w, y0 + target_h))
cropped.save(out_path, format='PNG')
print(f'  [OK] Scaled wallpaper to {target_w}x{target_h} at {out_path}')
" "$CHOSEN_WALLPAPER" "$TARGET_W" "$TARGET_H" "$HOME/Pictures/active_wallpaper.png"

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
