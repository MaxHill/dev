#!/bin/bash

set -euo pipefail

if (( EUID == 0 )); then
    echo "Run ./install.sh as your normal user, not sudo ./install.sh." >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


# Unlock credentials before the long package/build/configuration steps.
./install-age.sh
./install-sops.sh
./install-ssh.sh --require-agent

# ./remove-apps.sh

./install-hyprland.sh

./install-stow.sh
./install-scripts.sh
./install-neovim.sh
./install-shell.sh
./install-fzf.sh
./install-configs.sh
./install-mise.sh
./install-delta.sh
./install-vale.sh
./install-ghostty.sh
./install-kitty.sh
./install-ai.sh
./install-wget.sh
# ./install-hyprland-overrides.sh
./install-tmux.sh
./install-browsers.sh
./install-dekit.sh
./install-azure-cli.sh
./install-1password.sh
./install-fonts.sh
./install-notifications.sh

# Skip the systemd-boot menu. Hold Space during boot to show it.
sudo bootctl set-timeout 0
