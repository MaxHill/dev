#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/hypr"
modules=(monitors input bindings looknfeel)
fail() { echo "Error: $*" >&2; exit 1; }

command -v luac >/dev/null || fail "luac is required for Lua syntax checks."
command -v hyprctl >/dev/null || fail "Run this installer inside Hyprland."
[[ -f "$CONFIG_DIR/hyprland.lua" ]] || fail "Install Omarchy's Lua configuration first."

# Validate every target before changing any user configuration.
for module in "${modules[@]}"; do
    target="$CONFIG_DIR/$module.lua"
    [[ -f $target && ! -L $target && -w $target ]] ||
        fail "Expected writable, non-symlink file: $target"
    grep -Fq "require(\"hypr.$module\")" "$CONFIG_DIR/hyprland.lua" ||
        fail "hyprland.lua does not load hypr.$module."
    luac -p "$SCRIPT_DIR/overrides/hypr/$module.lua"
    luac -p "$target"
done
hyprctl eval 'return true' >/dev/null || fail "The running Hyprland must support Lua."

lua_repo=${SCRIPT_DIR//\\/\\\\}
lua_repo=${lua_repo//\"/\\\"}
loader() { printf 'dofile("%s/overrides/hypr/%s.lua")' "$lua_repo" "$1"; }
changed=()
for module in "${modules[@]}"; do
    if grep -Fxq "$(loader "$module")" "$CONFIG_DIR/$module.lua"; then
        echo "Already installed: $module.lua"
    else
        changed+=("$module")
    fi
done

backup=""
if (( ${#changed[@]} )); then
    backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dev/hyprland-backups"
    mkdir -p "$backup_root"
    backup=$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S).XXXXXX")
    for module in "${changed[@]}"; do
        cp -p -- "$CONFIG_DIR/$module.lua" "$backup/$module.lua"
    done
    echo "Backup: $backup"
fi

rollback() {
    status=$?
    trap - EXIT
    if (( status != 0 )) && [[ -n $backup ]]; then
        echo "Installation failed; restoring configs from $backup" >&2
        for module in "${changed[@]}"; do
            cp -p -- "$backup/$module.lua" "$CONFIG_DIR/$module.lua"
        done
        hyprctl reload >/dev/null 2>&1 || true
    fi
    exit "$status"
}
trap rollback EXIT

for module in "${changed[@]}"; do
    printf '\n-- Personal overrides from %s.\n%s\n' \
        "$SCRIPT_DIR" "$(loader "$module")" >> "$CONFIG_DIR/$module.lua"
    luac -p "$CONFIG_DIR/$module.lua"
    echo "Installed: $module.lua"
done
hyprctl reload
errors=$(hyprctl configerrors)
if [[ -n ${errors//[[:space:]]/} && $errors != "ok" ]]; then
    fail "Hyprland reported config errors: $errors"
fi
echo "Hyprland overrides installed and config validated."
