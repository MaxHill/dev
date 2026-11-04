#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 
CONFIGS_DIR="$SCRIPT_DIR/configs"

cd "$CONFIGS_DIR"

echo "Stowing config directories"
packages=()
for package in */; do
    if [[ "$package" != "mozilla/" ]]; then
        packages+=("$package")
    fi
done
stow -t "$HOME" "${packages[@]}"

# Mozilla apps must write runtime profile data into real directories, not the repo.
# Betterbird uses Thunderbird's profile directory.
stow --no-folding -t "$HOME" mozilla

# Initialize neovim to install plugins (now that config is linked)
echo "Installing Neovim plugins..."
nvim --headless "+lua vim.pack.update()" +qall

# Build telescope-fzf-native
FZF_PATH="$HOME/.local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim"
if [ -d "$FZF_PATH" ]; then
    echo "Building telescope-fzf-native..."
    cd "$FZF_PATH" && make
    echo "telescope-fzf-native built successfully"
fi
