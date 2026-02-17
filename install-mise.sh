#!/bin/sh

# Install mise package if not present
yay -S --noconfirm --needed mise

# Activate mise in current shell
eval "$(mise activate bash)"

# Install configured tools (Python, Node, etc.)
echo "Installing mise tools from ~/.config/mise/config.toml..."
mise install

echo "mise setup complete!"
