#!/bin/bash

set -euo pipefail

# Install mise package if not present
yay -S --noconfirm --needed mise-bin

# Install configured tools (Python, Node, etc.)
echo "Installing mise tools from ~/.config/mise/config.toml..."
mise install

echo "mise setup complete!"
