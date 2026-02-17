#!/bin/sh

set -e

./install-stow.sh
./install-configs.sh
./install-mise.sh
./install-age.sh
./install-ssh.sh
./install-ghostty.sh
./install-neovim.sh
./install-opencode.sh
./install-wget.sh
./install-hyprland-overrides.sh
./install-zellij.sh

