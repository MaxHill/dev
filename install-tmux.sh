#!/bin/sh

set -e

echo "=== Tmux Installation ==="

# Install tmux
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

echo "Tmux installation complete!"
echo "Note: tmux-sessionizer is installed via install-scripts.sh"
