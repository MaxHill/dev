#!/bin/sh


omarchy-webapp-remove "HEY" "Basecamp" "X" "Zoom" "Discord"

if pacman -Qi obsidian &> /dev/null; then
    sudo pacman -Rns --noconfirm obsidian
fi
