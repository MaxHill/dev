#!/bin/sh

set -e

./remove-apps.sh

./install-stow.sh
./install-scripts.sh
./install-configs.sh
./install-mise.sh
./install-age.sh
./install-sops.sh
./install-delta.sh
./install-vale.sh
./install-nom.sh
./install-ssh.sh
./install-ghostty.sh
./install-neovim.sh
./install-ai.sh
./install-wget.sh
./install-bash-overrides.sh
./install-hyprland-overrides.sh
./install-input-overrides.sh
./install-tmux.sh
./install-browsers.sh
./install-mproc.sh
./install-azure-cli.sh
