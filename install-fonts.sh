#!/bin/bash

set -euo pipefail

yay -S --noconfirm --needed \
    maplemono-ttf \
    maplemono-nf-unhinted \
    maplemono-nf-cn-unhinted

yay -S --noconfirm --needed \
    ttf-jetbrains-mono-nerd \
    ttf-jetbrains-mono
