#!/usr/bin/env bash
# ==============================================================================
#  ⛩️  CachyOS + Niri + Noctalia Dotfiles Installer
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
NC='\033[0m' # No Color

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
echo -e "${MAGENTA}   ⛩️  Atmospheric Dark Fantasy Rice Installer ⛩️${NC}\n"

# ------------------------------------------------------------------------------
# 1. Dependency Check
# ------------------------------------------------------------------------------
echo -e "${BOLD}${BLUE}==> [1/3] Checking Required Dependencies...${NC}"

declare -A REQUIRED_PKGS=(
    ["niri"]="Niri Scrollable Wayland Compositor"
    ["noctalia"]="Noctalia Desktop Shell (Quickshell)"
    ["shiftpaper"]="3D Spatial Parallax Wallpaper Daemon"
    ["kitty"]="GPU-accelerated Terminal"
    ["fish"]="Fish Friendly Interactive Shell"
    ["fastfetch"]="System Information Fetch Tool"
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

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Some dependencies are missing:${NC} ${MISSING_PKGS[*]}"
    
    # Detect AUR Helper or Pacman
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v pacman &>/dev/null; then
        AUR_HELPER="sudo pacman"
    fi

    if [ -n "$AUR_HELPER" ]; then
        read -rp "Would you like to attempt installing missing packages with $AUR_HELPER? [y/N]: " install_deps
        if [[ "$install_deps" =~ ^[Yy]$ ]]; then
            $AUR_HELPER -S --needed "${MISSING_PKGS[@]}" || {
                echo -e "${RED}Warning: Some packages could not be installed automatically. Please install them manually.${NC}"
            }
        fi
    fi
else
    echo -e "  ${GREEN}All primary dependencies are present!${NC}\n"
fi

# ------------------------------------------------------------------------------
# 2. Backup Function
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
# 3. Component Installation Functions
# ------------------------------------------------------------------------------

install_noctalia() {
    echo -e "\n${BOLD}${CYAN}Installing Noctalia Shell & Widgets...${NC}"
    mkdir -p ~/.config/noctalia ~/.local/state/noctalia
    backup_config ~/.config/noctalia/settings.json
    cp -f "$DOTFILES_DIR/noctalia/settings.json" ~/.config/noctalia/settings.json
    
    if [ -f "$DOTFILES_DIR/noctalia/desktop_widgets.toml" ]; then
        backup_config ~/.local/state/noctalia/settings.toml
        cp -f "$DOTFILES_DIR/noctalia/desktop_widgets.toml" ~/.local/state/noctalia/settings.toml
    fi
    echo -e "  ${GREEN}✔ Noctalia configuration & widgets applied!${NC}"
}

install_niri() {
    echo -e "\n${BOLD}${CYAN}Installing Niri Compositor Configs...${NC}"
    mkdir -p ~/.config/niri
    backup_config ~/.config/niri/config.kdl
    backup_config ~/.config/niri/cfg
    cp -rn "$DOTFILES_DIR/niri/"* ~/.config/niri/
    echo -e "  ${GREEN}✔ Niri scrollable compositor configs applied!${NC}"
}

install_kitty() {
    echo -e "\n${BOLD}${CYAN}Installing Kitty Terminal Configs...${NC}"
    mkdir -p ~/.config/kitty/themes
    backup_config ~/.config/kitty/kitty.conf
    cp -rn "$DOTFILES_DIR/kitty/"* ~/.config/kitty/
    echo -e "  ${GREEN}✔ Kitty configuration & Noctalia colors applied!${NC}"
}

install_fish_fastfetch() {
    echo -e "\n${BOLD}${CYAN}Installing Fish & Responsive Fastfetch Stickers...${NC}"
    mkdir -p ~/.config/fish ~/.config/fastfetch ~/Pictures/Fastfetch
    backup_config ~/.config/fish/config.fish
    backup_config ~/.config/fastfetch/config.jsonc
    cp -f "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/config.fish
    cp -f "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
    cp -rn "$DOTFILES_DIR/assets/fastfetch-stickers/"*.png ~/Pictures/Fastfetch/
    echo -e "  ${GREEN}✔ Fish wrapper & transparent character stickers applied!${NC}"
}

install_shiftpaper() {
    echo -e "\n${BOLD}${CYAN}Installing Shiftpaper 3D Wallpaper Configs...${NC}"
    mkdir -p ~/.config/shiftpaper ~/Pictures
    backup_config ~/.config/shiftpaper/config.toml
    cp -f "$DOTFILES_DIR/shiftpaper/config.toml" ~/.config/shiftpaper/config.toml
    cp -rn "$DOTFILES_DIR/assets/wallpapers/"* ~/Pictures/
    
    # Prompt to bake wallpaper now if shiftpaper is available
    if command -v shiftpaper &>/dev/null; then
        echo -e "  ${CYAN}Baking active wallpaper for shiftpaperd...${NC}"
        shiftpaper set ~/Pictures/wallhaven-28wy7m_1600x900.png || true
        systemctl --user enable --now shiftpaperd 2>/dev/null || true
    fi
    echo -e "  ${GREEN}✔ Shiftpaper config and wallpaper installed!${NC}"
}

# ------------------------------------------------------------------------------
# 4. Interactive Menu
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}==> [2/3] Choose Components to Install:${NC}"
echo -e "  ${BOLD}1)${NC} Noctalia Theme & Desktop Widgets Layout"
echo -e "  ${BOLD}2)${NC} Niri Compositor Configuration & Keybinds"
echo -e "  ${BOLD}3)${NC} Kitty Terminal Configuration & Theme"
echo -e "  ${BOLD}4)${NC} Fish Shell + Responsive Fastfetch Stickers (iGPU / GPU split)"
echo -e "  ${BOLD}5)${NC} Shiftpaper 3D Spatial Wallpaper Config & Wallpaper"
echo -e "  ${BOLD}6)${NC} ${GREEN}${BOLD}Full Rice (Install All of Above)${NC}"
echo -e "  ${BOLD}q)${NC} Quit without making changes\n"

read -rp "Select options (e.g. 1 3 4 or 6 for all) [Default: 6]: " choice
choice="${choice:-6}"

if [[ "$choice" =~ [Qq] ]]; then
    echo -e "\n${YELLOW}Installation cancelled. No changes were made.${NC}"
    exit 0
fi

echo -e "\n${BOLD}${BLUE}==> [3/3] Applying Configurations...${NC}"

if [[ "$choice" == "6" ]] || [[ "$choice" =~ [Aa][Ll][Ll] ]]; then
    install_noctalia
    install_niri
    install_kitty
    install_fish_fastfetch
    install_shiftpaper
else
    for opt in $choice; do
        case "$opt" in
            1) install_noctalia ;;
            2) install_niri ;;
            3) install_kitty ;;
            4) install_fish_fastfetch ;;
            5) install_shiftpaper ;;
            *) echo -e "${RED}Invalid option: $opt (Skipping)${NC}" ;;
        esac
    done
fi

# ------------------------------------------------------------------------------
# Completion Message
# ------------------------------------------------------------------------------
echo -e "\n${GREEN}${BOLD}✨ Setup successfully completed! ✨${NC}"
echo -e "${CYAN}Recommended next steps:${NC}"
echo -e "  • Run ${BOLD}noctalia msg config-reload${NC} to refresh Noctalia widgets."
echo -e "  • Open a new ${BOLD}Kitty${NC} terminal window to check your responsive Fastfetch."
echo -e "  • Any replaced files were backed up with extension ${YELLOW}.bak_${BACKUP_DATE}${NC}"
echo -e "\nEnjoy your rice! ⛩️\n"
