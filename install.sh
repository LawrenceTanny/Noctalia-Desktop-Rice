#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing Dotfiles from $DOTFILES_DIR..."

# Create target directories
mkdir -p ~/.config/{niri,noctalia,kitty,fish,fastfetch,shiftpaper,btop,yazi}
mkdir -p ~/Pictures/Fastfetch
mkdir -p ~/Pictures/Wallpapers

# Copy/Symlink Configs
echo "-> Linking Niri configs..."
cp -rn "$DOTFILES_DIR/niri/"* ~/.config/niri/

echo "-> Linking Kitty configs..."
cp -rn "$DOTFILES_DIR/kitty/"* ~/.config/kitty/

echo "-> Linking Fish config..."
cp -n "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/config.fish

echo "-> Linking Fastfetch config & stickers..."
cp -n "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
cp -rn "$DOTFILES_DIR/assets/fastfetch-stickers/"*.png ~/Pictures/Fastfetch/

echo "-> Linking Noctalia & Shiftpaper..."
cp -n "$DOTFILES_DIR/noctalia/settings.json" ~/.config/noctalia/settings.json
cp -n "$DOTFILES_DIR/shiftpaper/config.toml" ~/.config/shiftpaper/config.toml
cp -n "$DOTFILES_DIR/assets/wallpapers/"* ~/Pictures/

echo "-> Linking Themes (Btop & Yazi)..."
cp -n "$DOTFILES_DIR/btop/btop.conf" ~/.config/btop/btop.conf
cp -n "$DOTFILES_DIR/yazi/theme.toml" ~/.config/yazi/theme.toml

echo "==> Installation complete! Restart Niri or log out to apply all changes."
