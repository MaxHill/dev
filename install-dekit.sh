#!/bin/sh

set -e

# Use the prebuilt release to avoid compiling Dekit's Rust dependencies.
yay -S --noconfirm --needed --ask=4 dekit-bin

# Match installed package names exactly: mprocs-bin also provides "mprocs".
for package in mprocs mprocs-bin; do
    if pacman -Qq | grep -Fxq "$package"; then
        sudo pacman -R --noconfirm "$package"
    fi
done
