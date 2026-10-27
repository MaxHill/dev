#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$SCRIPT_DIR/system-configs"

sudo pacman -S --needed --noconfirm stow terminus-font

# Check every destination before moving any files. Never overwrite a backup
# or replace a symlink managed outside this package.
for relative_path in etc/vconsole.conf etc/ly/config.ini; do
    target="/$relative_path"
    source="$STOW_DIR/ly/$relative_path"

    if [[ -L "$target" ]]; then
        if [[ "$(readlink -f "$target")" != "$source" ]]; then
            echo "Refusing to replace unmanaged symlink: $target" >&2
            exit 1
        fi
    elif [[ -e "$target" ]]; then
        if [[ ! -f "$target" || -e "$target.before-stow" || -L "$target.before-stow" ]]; then
            echo "Cannot back up $target; check its type and $target.before-stow" >&2
            exit 1
        fi
    fi
done

for relative_path in etc/vconsole.conf etc/ly/config.ini; do
    target="/$relative_path"
    if [[ ! -L "$target" && -f "$target" ]]; then
        sudo mv -- "$target" "$target.before-stow"
    fi
done

sudo stow --no-folding --dir="$STOW_DIR" --target=/ ly

echo "Ly configuration linked. Reboot to apply the console font."
