#!/bin/bash

set -euo pipefail

yay -S --noconfirm --needed rsync
yay -S --noconfirm --needed azure-cli
yay -S --noconfirm --needed wget
yay -S --noconfirm --needed vale
yay -S --noconfirm --needed git-delta
yay -S --noconfirm --needed lazygit
yay -S --noconfirm --needed bat
yay -S --noconfirm --needed tldr
yay -S --noconfirm --needed --ask=4 dekit-bin

# Zsh key bindings and fuzzy completion are enabled in configs/zsh/.zshrc.
yay -S --noconfirm --needed fzf



# Install nightly builds, as before, rather than the stable package.
# Accept replacing a conflicting stable package in the same transaction.
yay -S --needed --noconfirm --ask=4 neovim-nightly-bin


#  ------------------------------------------------------------------------
#  YAZI                                                                     
#  ------------------------------------------------------------------------ 
yay -S --noconfirm --needed yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick

# Install Gruvbox flavors for both terminal background modes.
FLAVORS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi/flavors"
for flavor in bennyyip/gruvbox-dark Sh00Fly/gruvbox-light; do
    if [[ ! -d "$FLAVORS_DIR/${flavor##*/}.yazi" ]]; then
        ya pkg add "$flavor"
    fi
done

#  ------------------------------------------------------------------------
#  TMUX                                                                     
#  ------------------------------------------------------------------------ 
yay -S --noconfirm --needed tmux

# Clone TPM (Tmux Plugin Manager) if not already installed
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "TPM installed successfully!"
    echo "To install plugins: Open tmux and press prefix + I"
else
    echo "TPM already installed at $TPM_DIR"
fi
echo "Note: tmux-sessionizer is installed via install-scripts.sh"

#  ------------------------------------------------------------------------
#  Mise                                                                     
#  ------------------------------------------------------------------------ 
yay -S --noconfirm --needed mise-bin

echo "Installing mise tools from ~/.config/mise/config.toml..."
mise install


#  ------------------------------------------------------------------------
#  AI                                                                     
#  ------------------------------------------------------------------------ 
# curl -fsSL https://opencode.ai/install | bash
mise exec -- npm install -g --ignore-scripts @earendil-works/pi-coding-agent
