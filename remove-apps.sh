#!/bin/sh

set -e

for app in "HEY" "Basecamp" "X" "Zoom" "Discord"; do
    omarchy webapp remove "$app"
done

# TODO: Uninsall omarchy pi
if pacman -Qi obsidian >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm obsidian
fi
