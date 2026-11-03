#!/bin/sh

set -e

# Install hyperland stuff
yay -S --needed --noconfirm \
    hyprpolkitagent \
    wl-clipboard \
    waybar \
    pavucontrol \
    network-manager-applet \
    rofi \
    hypridle \
    hyprpaper \
    rsync \
    hyprlock \
    # xdg-desktop-portal-hyprland-git \ # Commented out since i installed this with archinstall
    grim slurp # needed for xdg-desktop-portal-hyprland-git

