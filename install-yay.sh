#!/bin/sh

set -e

if ! command -v yay >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm git base-devel go

    rm -rf /tmp/yay
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay

    # Build as the normal user. The -s/-i modes force fresh sudo prompts.
    makepkg --noconfirm
    sudo pacman -U --noconfirm /tmp/yay/yay-*.pkg.tar.zst

    cd /
    rm -rf /tmp/yay
else
    echo "yay is already installed; skipping bootstrap."
fi
