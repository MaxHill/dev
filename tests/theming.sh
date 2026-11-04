#!/usr/bin/env bash
# Requires a graphical session, Stow, a C compiler, and GTK3/GTK4/libadwaita headers.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/home" "$work/packages/normal/.config/example"
printf 'normal\n' > "$work/packages/normal/.config/example/config"
cp -a "$repo/configs/"{gtk,firefox,thunderbird} "$work/packages/"
stow --dir="$work/packages" --target="$work/home" normal gtk
stow --dir="$work/packages" --target="$work/home" --no-folding firefox thunderbird
test -L "$work/home/.config/example"
for profile in .mozilla/firefox/dotfiles .thunderbird/dotfiles; do
    test ! -L "$work/home/$profile"
    test -L "$work/home/$profile/user.js"
    test -L "$work/home/$profile/chrome/userChrome.css"
    printf 'runtime\n' > "$work/home/$profile/runtime-test"
done
test ! -e "$work/packages/firefox/.mozilla/firefox/dotfiles/runtime-test"
test ! -e "$work/packages/thunderbird/.thunderbird/dotfiles/runtime-test"

cc "$repo/tests/gtk-palette.c" -o "$work/gtk3" $(pkg-config --cflags --libs gtk+-3.0)
cc "$repo/tests/gtk-palette.c" -o "$work/gtk4" -Wno-deprecated-declarations $(pkg-config --cflags --libs gtk4)
cc "$repo/tests/gtk-palette.c" -o "$work/adwaita" -DWITH_ADWAITA -Wno-deprecated-declarations $(pkg-config --cflags --libs gtk4 libadwaita-1)
config="$work/home/.config"
mkdir -p "$config/theme"
for appearance in light dark; do
    rsync -a --checksum --delete "$repo/themes/$appearance/" "$config/theme/"
    expected='#fbf1c7'
    [[ "$appearance" == dark ]] && expected='#000000'
    for toolkit in gtk3 gtk4 adwaita; do
        echo "Checking $toolkit $appearance"
        XDG_CONFIG_HOME="$config" "$work/$toolkit" "$expected" > "$work/output" 2>&1 || {
            grep . "$work/output"
            exit 1
        }
        if grep -i 'theme parser error' "$work/output"; then exit 1; fi
        grep 'Loaded window background' "$work/output"
    done
done
bash -n "$repo/install-configs.sh"
luac -p "$repo/scripts/theme"
echo 'PASS: GTK palettes, CSS loading, syntax, and isolated Mozilla Stow profiles'
