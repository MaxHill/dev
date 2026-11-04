#!/bin/bash
# Check a cropped Pavucontrol Playback screenshot with at least one visible slider.
# Requires ImageMagick. Capture with grim using the window's Hyprland geometry.
set -euo pipefail
if [[ $# != 2 || ( "$1" != dark && "$1" != light ) ]]; then
    echo "Usage: $0 dark|light screenshot.png" >&2
    exit 2
fi
background='#000000'
[[ "$1" == light ]] && background='#FBF1C7'
histogram=$(magick "$2" -depth 8 -format '%c' histogram:info:)
# The main pane must dominate the image; gold must appear in active controls.
dominant=$(printf '%s\n' "$histogram" | sort -nr | awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i ~ /^#/) print $i }')
if [[ "${dominant^^}" != "$background" ]]; then
    echo "FAIL: dominant background is $dominant, expected $background" >&2
    exit 1
fi
if ! grep -qi '#D79921' <<< "$histogram"; then
    echo 'FAIL: gold accent is missing' >&2
    exit 1
fi
echo "PASS: $1 background and gold accent"
