#!/bin/sh

set -e

# Explicitly install the stable package, including on machines without Neovim.
# Accept replacing a conflicting nightly package in the same transaction.
yay -S --needed --noconfirm --ask=4 neovim
