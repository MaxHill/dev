#!/bin/sh

set -e

# Use the prebuilt release to avoid compiling Dekit's Rust dependencies.
yay -S --noconfirm --needed --ask=4 dekit-bin

