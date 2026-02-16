#!/bin/sh


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 
CONFIGS_DIR="$SCRIPT_DIR/configs"

cd "$CONFIGS_DIR"

# Remove omarchy configs

echo "Removing old config directories"
rm -rf $HOME/.config/nvim


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
