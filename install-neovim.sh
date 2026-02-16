#!/bin/sh

# Remove conflicting neovim package if it exists
if pacman -Qi neovim &> /dev/null; then
    echo "Removing conflicting neovim package..."
    sudo pacman -Rdd --noconfirm neovim
fi

# Install nightly build with vim.pack support
yay -S --needed --noconfirm neovim-nightly-bin
