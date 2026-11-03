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

./install-yay.sh
./install-hyprland.sh
./install-screenshot.sh

 # TODO: I should maybe move install-stow.sh to install-terminal-programs.sh maybe needs to happen before install configs. 
./install-stow.sh
./install-scripts.sh
./install-shell.sh
./install-configs.sh

# Create the active theme files required by Kitty, Waybar, and Hyprpaper.
LUA_PATH="$HOME/.local/lib/lua/?.lua;;" "$HOME/.local/bin/theme" dark

./install-ghostty.sh
./install-kitty.sh
./install-browsers.sh
./install-terminal-programs.sh
./install-1password.sh
./install-fonts.sh
./install-notifications.sh
./install-music.sh
./install-gui-programs.sh

./install-wifi.sh

# Skip the systemd-boot menu. Hold Space during boot to show it.
sudo bootctl set-timeout 0
