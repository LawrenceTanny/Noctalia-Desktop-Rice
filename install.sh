#!/usr/bin/env bash
# ==============================================================================
#  ⛩️  CachyOS + Niri + Noctalia Dotfiles & 3D Spatial Wallpaper Installer
# ==============================================================================

set -e

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DATE="$(date +%Y%m%d_%H%M%S)"

clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
  ███╗   ██╗██╗██████╗ ██╗    ██████╗ ██████╗ ████████╗███████╗
  ████╗  ██║██║██╔══██╗██║    ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
  ██╔██╗ ██║██║██████╔╝██║    ██║  ██║██║  ██║   ██║   ███████╗
  ██║╚██╗██║██║██╔══██╗██║    ██║  ██║██║  ██║   ██║   ╚════██║
  ██║ ╚████║██║██║  ██║██║    ██████╔╝██████╔╝   ██║   ███████║
  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝    ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝
EOF
echo -e "${MAGENTA}   ⛩️  Universal 3D Spatial Wallpaper & Rice Installer ⛩️${NC}\n"

# ------------------------------------------------------------------------------
# 1. Environment & Hardware Detection
# ------------------------------------------------------------------------------
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
echo -e "  • ${BOLD}Compositor:${NC}     ${GREEN}$COMPOSITOR${NC}"
echo -e "  • ${BOLD}Desktop Shell:${NC}  ${GREEN}$SHELL_NAME${NC}"
echo -e "  • ${BOLD}Screen Res:${NC}     ${GREEN}$RES${NC} (Auto-detected active monitor)\n"

# ------------------------------------------------------------------------------
# 2. Dependency Check & Interactive Package Installation
# ------------------------------------------------------------------------------
echo -e "${BOLD}${BLUE}==> [2/4] Checking Required Software:${NC}"

declare -A REQUIRED_PKGS=(
    ["shiftpaper"]="3D Spatial Wallpaper Daemon (Universal Wayland)"
    ["kitty"]="GPU-accelerated Terminal"
    ["fish"]="Fish Shell"
    ["fastfetch"]="System Information Fetch Tool"
    ["python"]="Python 3 Runtime (for wallpaper scaling)"
)

MISSING_PKGS=()

for cmd in "${!REQUIRED_PKGS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "  [${GREEN}✔${NC}] ${BOLD}$cmd${NC} (${REQUIRED_PKGS[$cmd]})"
    else
        echo -e "  [${RED}✘${NC}] ${BOLD}$cmd${NC} (${REQUIRED_PKGS[$cmd]}) - ${YELLOW}NOT FOUND${NC}"
        MISSING_PKGS+=("$cmd")
    fi
done

# Check python Pillow
if ! python3 -c "import PIL" &>/dev/null; then
    echo -e "  [${RED}✘${NC}] ${BOLD}python-pillow${NC} (Image Scaling Library) - ${YELLOW}NOT FOUND${NC}"
    MISSING_PKGS+=("python-pillow")
fi

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Some required packages are missing:${NC} ${MISSING_PKGS[*]}"
    
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v pacman &>/dev/null; then
        AUR_HELPER="sudo pacman"
    fi

    if [ -n "$AUR_HELPER" ]; then
        echo -e "${CYAN}Please input your password if prompted by $AUR_HELPER:${NC}"
        read -rp "Install missing packages with $AUR_HELPER now? [Y/n]: " do_install
        do_install="${do_install:-y}"
        if [[ "$do_install" =~ ^[Yy]$ ]]; then
            $AUR_HELPER -S --needed "${MISSING_PKGS[@]}"
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Backup Helper
# ------------------------------------------------------------------------------
backup_config() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local bak="${target}.bak_${BACKUP_DATE}"
        echo -e "  ${YELLOW}Backed up existing:${NC} $target -> $bak"
        cp -r "$target" "$bak"
    fi
}

# ------------------------------------------------------------------------------
# 3. Wallpaper Selection & Automatic Resolution Scaling
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}==> [3/4] Which GUWEIZ 3D Wallpaper Would You Like to Use?${NC}"
echo -e "  ${BOLD}1)${NC} Warrior Girl with Glowing Spear & Armor (Default)"
echo -e "  ${BOLD}2)${NC} Cyberpunk Girl in Rainy Neon City"
echo -e "  ${BOLD}3)${NC} Katana in Moody Dark Mist"
echo -e "  ${BOLD}4)${NC} Rainy Alleyway with Black Cat"
echo -e "  ${BOLD}5)${NC} Urban Street with Headphones"
echo -e "  ${BOLD}6)${NC} Skip Wallpaper Selection (Keep current wallpaper)\n"

read -rp "Select wallpaper [1-6, Default: 1]: " wp_choice
wp_choice="${wp_choice:-1}"

CHOSEN_WALLPAPER=""
case "$wp_choice" in
    1) CHOSEN_WALLPAPER="$DOTFILES_DIR/assets/wallpapers/wallhaven-28wy7m_1600x900.png" ;;
    2) CHOSEN_WALLPAPER="$DOTFILES_DIR/assets/wallpapers/wallhaven-13vym3.jpg" ;;
    3) CHOSEN_WALLPAPER="$DOTFILES_DIR/assets/wallpapers/wallhaven-rdwjj7.jpg" ;;
    4) CHOSEN_WALLPAPER="$DOTFILES_DIR/assets/wallpapers/wallhaven-q67req_1600x900.png" ;;
    5) CHOSEN_WALLPAPER="$DOTFILES_DIR/assets/wallpapers/wallhaven-21623g_1600x900.png" ;;
    6) echo -e "  ${YELLOW}Skipping wallpaper selection.${NC}" ;;
    *) echo -e "  ${YELLOW}Invalid choice, using default wallpaper.${NC}"
       CHOSEN_WALLPAPER="$DOTFILES_DIR/assets/wallpapers/wallhaven-28wy7m_1600x900.png" ;;
esac

if [ -n "$CHOSEN_WALLPAPER" ] && [ -f "$CHOSEN_WALLPAPER" ]; then
    echo -e "\n${CYAN}Auto-scaling chosen wallpaper to match your screen resolution ($RES)...${NC}"
    mkdir -p ~/Pictures ~/.config/shiftpaper

    TARGET_W="${RES%x*}"
    TARGET_H="${RES#*x}"

    python3 -c "
from PIL import Image
import sys

src = '$CHOSEN_WALLPAPER'
target_w, target_h = int('$TARGET_W'), int('$TARGET_H')

im = Image.open(src)
scale = max(target_w / im.width, target_h / im.height)
new_w = int(round(im.width * scale))
new_h = int(round(im.height * scale))

resized = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
x0 = (new_w - target_w) // 2
y0 = (new_h - target_h) // 2
cropped = resized.crop((x0, y0, x0 + target_w, y0 + target_h))

out_path = '/home/$USER/Pictures/active_wallpaper.png'
cropped.save(out_path, format='PNG')
print(f'  [✔] Perfectly scaled {im.size} -> {cropped.size} at {out_path}')
"
    # Copy tuned shiftpaper config
    backup_config ~/.config/shiftpaper/config.toml
    cp -f "$DOTFILES_DIR/shiftpaper/config.toml" ~/.config/shiftpaper/config.toml

    # Bake wallpaper with shiftpaper
    if command -v shiftpaper &>/dev/null; then
        echo -e "  ${CYAN}Baking 3D depth map with MoGe-2 (this may take a few seconds)...${NC}"
        shiftpaper set ~/Pictures/active_wallpaper.png || true
        systemctl --user enable --now shiftpaperd 2>/dev/null || true
        echo -e "  ${GREEN}✔ 3D Spatial Wallpaper active & tracking mouse cursor!${NC}"
    fi
fi

# ------------------------------------------------------------------------------
# 4. Desktop & Terminal Ricing Components
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}==> [4/4] Desktop & Terminal Ricing Components:${NC}"
echo -e "  ${BOLD}1)${NC} Noctalia Desktop Shell & Widgets (Balanced Left Dashboard)"
echo -e "  ${BOLD}2)${NC} Niri Compositor Configs & Keybinds (Scrollable Wayland)"
echo -e "  ${BOLD}3)${NC} Kitty Terminal + Responsive Character Fastfetch (iGPU/GPU detection)"
echo -e "  ${BOLD}4)${NC} ${GREEN}${BOLD}Full Rice (Install All of Above)${NC}"
echo -e "  ${BOLD}q)${NC} Skip Desktop Ricing\n"

read -rp "Select components (e.g. 1 3 or 4 for all) [Default: 4]: " rice_choice
rice_choice="${rice_choice:-4}"

install_noctalia() {
    echo -e "\n${BOLD}${CYAN}Applying Noctalia Shell & Widget Layout...${NC}"
    if [ "$SHELL_NAME" != "Noctalia" ]; then
        echo -e "  ${YELLOW}Notice: Current desktop shell is '$SHELL_NAME' (not Noctalia).${NC}"
    fi
    mkdir -p ~/.config/noctalia ~/.local/state/noctalia
    backup_config ~/.config/noctalia/settings.json
    backup_config ~/.local/state/noctalia/settings.toml
    cp -f "$DOTFILES_DIR/noctalia/settings.json" ~/.config/noctalia/settings.json
    cp -f "$DOTFILES_DIR/noctalia/desktop_widgets.toml" ~/.local/state/noctalia/settings.toml
    if command -v noctalia &>/dev/null; then
        noctalia msg config-reload 2>/dev/null || true
    fi
    echo -e "  ${GREEN}✔ Noctalia widgets & layout applied!${NC}"
}

install_niri() {
    echo -e "\n${BOLD}${CYAN}Applying Niri Compositor Configs...${NC}"
    if [ "$COMPOSITOR" != "Niri" ]; then
        echo -e "  ${YELLOW}Notice: Current compositor is '$COMPOSITOR'. Niri configs will be installed to ~/.config/niri but won't affect $COMPOSITOR.${NC}"
    fi
    mkdir -p ~/.config/niri
    backup_config ~/.config/niri/config.kdl
    backup_config ~/.config/niri/cfg
    cp -rn "$DOTFILES_DIR/niri/"* ~/.config/niri/
    echo -e "  ${GREEN}✔ Niri compositor configs applied!${NC}"
}

install_kitty_fastfetch() {
    echo -e "\n${BOLD}${CYAN}Applying Kitty & Responsive Fastfetch Stickers...${NC}"
    mkdir -p ~/.config/kitty/themes ~/.config/fish ~/.config/fastfetch ~/Pictures/Fastfetch
    backup_config ~/.config/kitty/kitty.conf
    backup_config ~/.config/fish/config.fish
    backup_config ~/.config/fastfetch/config.jsonc

    cp -rn "$DOTFILES_DIR/kitty/"* ~/.config/kitty/
    cp -f "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/config.fish
    cp -f "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
    cp -rn "$DOTFILES_DIR/assets/fastfetch-stickers/"*.png ~/Pictures/Fastfetch/
    echo -e "  ${GREEN}✔ Kitty & responsive Fastfetch stickers applied!${NC}"
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
            *) echo -e "${RED}Invalid option: $opt (Skipping)${NC}" ;;
        esac
    done
fi

echo -e "\n${GREEN}${BOLD}✨ Installation & Configuration Completed! ✨${NC}"
echo -e "  • Any modified files were backed up with ${YELLOW}.bak_${BACKUP_DATE}${NC}"
echo -e "  • Open a new ${BOLD}Kitty${NC} window to test responsive Fastfetch."
echo -e "  • Move your mouse across the desktop to experience the 3D parallax wallpaper."
echo -e "\nEnjoy your rice! ⛩️\n"
