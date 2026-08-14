#!/bin/sh


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 
CONFIGS_DIR="$SCRIPT_DIR/configs"

cd "$CONFIGS_DIR"

# Remove omarchy configs

echo "Removing old config directories"
rm -rf "$HOME/.config/nvim"
rm -rf "$HOME/.agents"

PI_CONFIG_SOURCE="$CONFIGS_DIR/pi/.pi"
if [ -L "$HOME/.pi" ] && [ "$(readlink -f "$HOME/.pi")" = "$(readlink -f "$PI_CONFIG_SOURCE")" ]; then
    echo "Keeping existing managed ~/.pi symlink"
else
    rm -rf "$HOME/.pi"
fi

echo "Stowing config directories"
stow -t "$HOME" */

# Initialize neovim to install plugins (now that config is linked)
echo "Installing Neovim plugins..."
nvim --headless "+lua vim.pack.update()" +qall 2>/dev/null || true

# Build telescope-fzf-native
FZF_PATH="$HOME/.local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim"
if [ -d "$FZF_PATH" ]; then
    echo "Building telescope-fzf-native..."
    cd "$FZF_PATH" && make
    echo "telescope-fzf-native built successfully"
fi
