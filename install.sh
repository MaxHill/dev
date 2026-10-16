#!/bin/sh

set -e

./remove-apps.sh

./install-stow.sh
./install-scripts.sh
./install-neovim.sh
./install-configs.sh
./install-mise.sh
./install-age.sh
./install-sops.sh
./install-delta.sh
./install-vale.sh
./install-ssh.sh
./install-ghostty.sh
./install-ai.sh
./install-wget.sh
./install-bash-overrides.sh
./install-hyprland-overrides.sh
./install-tmux.sh
./install-browsers.sh
./install-dekit.sh
./install-azure-cli.sh
