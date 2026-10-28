#!/bin/sh

set -e

# Install nightly builds, as before, rather than the stable package.
# Accept replacing a conflicting stable package in the same transaction.
yay -S --needed --noconfirm --ask=4 neovim-nightly-bin
