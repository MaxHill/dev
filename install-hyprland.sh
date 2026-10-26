#!/bin/sh

set -e

# Get the user who ran sudo
REAL_USER=${SUDO_USER:$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)


sudo pacman -S --needed --noconfirm git base-devel go

rm -rf /tmp/yay
set -e
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay

makepkg -si --noconfirm

# Install the build package as root
sudo pacman -U --noconfirm /tmp/yay/yay-*.pkg.tar.zst

# Cleanup
rm -rf /tmp/yay


# Install hyperland stuff
yay -S --needed --noconfirm hyprpolkitagent wl-clipboard waybar

