#!/bin/bash

set -euo pipefail

# Zsh key bindings and fuzzy completion are enabled in configs/zsh/.zshrc.
yay -S --noconfirm --needed fzf
