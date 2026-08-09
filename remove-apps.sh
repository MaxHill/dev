#!/bin/sh

omarchy-webapp-remove "HEY" "Basecamp" "X" "Zoom" "Discord"

if pacman -Qi obsidian >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm obsidian
fi
