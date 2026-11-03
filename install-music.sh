#!/bin/sh

set -e

yay -S --needed --noconfirm spotify


mkdir -p ~/.config

cat > ~/.config/spotify-flags.conf <<EOF
--enable-features=UseOzonePlatform,WaylandWindowDecorations
--ozone-platform=wayland
--enable-wayland-ime
EOF
