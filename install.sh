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
echo -e "${CYAN}${BOLD}CachyOS + Niri + Noctalia Rice Installer${NC}\n"

detect_compositor() {
    if pgrep -x niri >/dev/null; then
        echo "Niri"
    elif pgrep -x Hyprland >/dev/null; then
        echo "Hyprland"
    elif pgrep -x sway >/dev/null; then
        echo "Sway"
    elif pgrep -x river >/dev/null; then
        echo "River"
    elif pgrep -x wayfire >/dev/null; then
        echo "Wayfire"
    elif [ -n "$XDG_CURRENT_DESKTOP" ]; then
        echo "$XDG_CURRENT_DESKTOP"
    else
        echo "Unknown"
    fi
}

detect_shell() {
    if pgrep -x noctalia >/dev/null; then
        echo "Noctalia"
    elif pgrep -x waybar >/dev/null; then
        echo "Waybar"
    elif pgrep -x ags >/dev/null; then
        echo "Ags"
    else
        echo "None"
    fi
}

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

COMPOSITOR="$(detect_compositor)"
SHELL_NAME="$(detect_shell)"
RES="$(detect_resolution)"

echo -e "${BOLD}${BLUE}==> [1/4] Detected Environment:${NC}"
echo -e "  Compositor:     ${GREEN}$COMPOSITOR${NC}"
echo -e "  Desktop Shell:  ${GREEN}$SHELL_NAME${NC}"
echo -e "  Resolution:     ${GREEN}$RES${NC}\n"

echo -e "${BOLD}${BLUE}==> [2/4] Checking Required Dependencies:${NC}"

declare -A REQUIRED_PKGS=(
    ["shiftpaper"]="3D Spatial Wallpaper Daemon"
    ["kitty"]="Terminal Emulator"
    ["fish"]="Fish Shell"
    ["fastfetch"]="System Fetch Tool"
    ["python"]="Python 3"
)

MISSING_PKGS=()

for cmd in "${!REQUIRED_PKGS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "  [OK] $cmd (${REQUIRED_PKGS[$cmd]})"
    else
        echo -e "  [MISSING] $cmd (${REQUIRED_PKGS[$cmd]})"
        MISSING_PKGS+=("$cmd")
    fi
done

if ! python3 -c "import PIL" &>/dev/null; then
    echo -e "  [MISSING] python-pillow"
    MISSING_PKGS+=("python-pillow")
fi

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Missing packages:${NC} ${MISSING_PKGS[*]}"
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v pacman &>/dev/null; then
        AUR_HELPER="sudo pacman"
    fi

    if [ -n "$AUR_HELPER" ]; then
        read -rp "Install missing packages with $AUR_HELPER now? [Y/n]: " do_install
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

echo -e "\n${BOLD}${BLUE}==> [3/4] Choose Wallpaper to Install:${NC}"

WALLPAPERS=()
while IFS= read -r -d '' file; do
    WALLPAPERS+=("$file")
done < <(find "$DOTFILES_DIR/assets/wallpapers" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 | sort -z)

TOTAL_WP=${#WALLPAPERS[@]}

if [ $TOTAL_WP -eq 0 ]; then
    echo -e "  ${YELLOW}No wallpapers found in $DOTFILES_DIR/assets/wallpapers/${NC}"
else
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
print(f'  [OK] Saved scaled wallpaper ({target_w}x{target_h}) to {out_path}')
" "$CHOSEN_WALLPAPER" "$TARGET_W" "$TARGET_H" "$HOME/Pictures/active_wallpaper.png"

        backup_config "$HOME/.config/shiftpaper/config.toml"
        cp -f "$DOTFILES_DIR/shiftpaper/config.toml" "$HOME/.config/shiftpaper/config.toml"

        if command -v shiftpaper &>/dev/null; then
            echo -e "  Baking depth map with shiftpaper..."
            shiftpaper set "$HOME/Pictures/active_wallpaper.png" || true
            systemctl --user enable --now shiftpaperd 2>/dev/null || true
            echo -e "  [OK] Shiftpaper 3D spatial wallpaper activated."
        fi
    else
        echo -e "  Skipping wallpaper change."
    fi
fi

echo -e "\n${BOLD}${BLUE}==> [4/4] Desktop & Terminal Components to Install:${NC}"
echo -e "  1) Noctalia Desktop Shell & Widgets Layout"
echo -e "  2) Niri Compositor Configs & Keybinds"
echo -e "  3) Kitty Terminal + Responsive Fastfetch Stickers"
echo -e "  4) Full Rice (Install 1, 2, and 3)"
echo -e "  q) Skip Desktop Components\n"

read -rp "Select components [Default: 4]: " rice_choice
rice_choice="${rice_choice:-4}"

install_noctalia() {
    echo -e "\n${BOLD}${CYAN}Installing Noctalia Shell & Widgets Layout...${NC}"
    if [ "$SHELL_NAME" != "Noctalia" ]; then
        echo -e "  Notice: Detected shell is '$SHELL_NAME'."
    fi
    mkdir -p "$HOME/.config/noctalia" "$HOME/.local/state/noctalia"
    backup_config "$HOME/.config/noctalia/settings.json"
    backup_config "$HOME/.local/state/noctalia/settings.toml"
    cp -f "$DOTFILES_DIR/noctalia/settings.json" "$HOME/.config/noctalia/settings.json"
    cp -f "$DOTFILES_DIR/noctalia/desktop_widgets.toml" "$HOME/.local/state/noctalia/settings.toml"
    if command -v noctalia &>/dev/null; then
        noctalia msg config-reload 2>/dev/null || true
    fi
    echo -e "  [OK] Noctalia configuration applied."
}

install_niri() {
    echo -e "\n${BOLD}${CYAN}Installing Niri Compositor Configs...${NC}"
    if [ "$COMPOSITOR" != "Niri" ]; then
        echo -e "  Notice: Detected compositor is '$COMPOSITOR'. Niri files will be placed in ~/.config/niri."
    fi
    mkdir -p "$HOME/.config/niri"
    backup_config "$HOME/.config/niri/config.kdl"
    backup_config "$HOME/.config/niri/cfg"
    cp -rn "$DOTFILES_DIR/niri/"* "$HOME/.config/niri/"
    echo -e "  [OK] Niri configuration applied."
}

install_kitty_fastfetch() {
    echo -e "\n${BOLD}${CYAN}Installing Kitty & Responsive Fastfetch Stickers...${NC}"
    mkdir -p "$HOME/.config/kitty/themes" "$HOME/.config/fish" "$HOME/.config/fastfetch" "$HOME/Pictures/Fastfetch"
    backup_config "$HOME/.config/kitty/kitty.conf"
    backup_config "$HOME/.config/fish/config.fish"
    backup_config "$HOME/.config/fastfetch/config.jsonc"

    cp -rn "$DOTFILES_DIR/kitty/"* "$HOME/.config/kitty/"
    cp -f "$DOTFILES_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
    cp -f "$DOTFILES_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    
    find "$DOTFILES_DIR/assets/fastfetch-stickers" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.webp" \) -exec cp -f {} "$HOME/Pictures/Fastfetch/" \; 2>/dev/null || true

    echo -e "  [OK] Kitty and Fastfetch stickers applied."
}

if [[ "$rice_choice" == "4" ]] || [[ "$rice_choice" =~ [Aa][Ll][Ll] ]]; then
    install_noctalia
    install_niri
    install_kitty_fastfetch
elif [[ ! "$rice_choice" =~ [Qq] ]]; then
    for opt in $rice_choice; do
        case "$opt" in
            1) install_noctalia ;;
            2) install_niri ;;
            3) install_kitty_fastfetch ;;
            *) echo -e "  [WARNING] Invalid option: $opt" ;;
        esac
    done
fi

echo -e "\n${GREEN}${BOLD}Installation completed.${NC}"
echo -e "  Backups saved with timestamp: .bak_${BACKUP_DATE}"
echo -e "  Run 'noctalia msg config-reload' if Noctalia is running."
echo -e "  Open a new Kitty window to test responsive Fastfetch.\n"
