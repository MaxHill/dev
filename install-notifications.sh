#!/bin/sh

set -e

# Install the replacement before removing the existing notification daemon.
sudo pacman -S --needed --noconfirm swaync libnotify

# Prevent D-Bus from restarting Dunst if it has a systemd user unit.
# Some Dunst installations use D-Bus activation without a systemd unit.
if pacman -Q dunst >/dev/null 2>&1; then
    if systemctl --user cat dunst.service >/dev/null 2>&1; then
        systemctl --user mask --now dunst.service
    fi
    sudo pacman -Rns --noconfirm dunst
fi

# Remove any mask left by this script or an earlier manual migration.
systemctl --user unmask dunst.service
systemctl --user daemon-reload

systemctl --user enable --now swaync.service

