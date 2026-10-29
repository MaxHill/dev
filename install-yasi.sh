#!/bin/bash

set -euo pipefail

yay -S --noconfirm --needed yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick

# Install Gruvbox flavors for both terminal background modes.
FLAVORS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi/flavors"
for flavor in bennyyip/gruvbox-dark Sh00Fly/gruvbox-light; do
    if [[ ! -d "$FLAVORS_DIR/${flavor##*/}.yazi" ]]; then
        ya pkg add "$flavor"
    fi
done
