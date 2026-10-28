#!/bin/bash

set -euo pipefail

if (( EUID == 0 )); then
    echo "Run ./install-shell.sh as your normal user, not sudo ./install-shell.sh." >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# util-linux provides chsh on Arch Linux.
yay -S --noconfirm --needed zsh util-linux zsh-autosuggestions zsh-syntax-highlighting

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ ! -r "/usr/share/zsh/plugins/$plugin/$plugin.zsh" ]; then
        echo "Missing plugin file for $plugin after installation." >&2
        exit 1
    fi
done

# Remove conflicting configs before install-configs.sh links the defaults.
# Keep managed links so repeated runs do not unlink the active configuration.
for config in .zprofile .zshrc; do
    target="$HOME/$config"
    source="$SCRIPT_DIR/configs/zsh/$config"
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$source" ]; then
        continue
    fi
    rm -f -- "$target"
done
echo "Zsh and plugins installed; configs will be linked by install-configs.sh."

ZSH_PATH="$(command -v zsh)"
# chsh checks literal paths, not executable identity. Arch may expose Zsh
# through /usr/sbin while registering only /bin/zsh and /usr/bin/zsh.
REGISTERED_ZSH=""
while IFS= read -r shell; do
    if [[ "$shell" = /* ]] && [ "$shell" -ef "$ZSH_PATH" ]; then
        REGISTERED_ZSH="$shell"
        break
    fi
done < <(chsh -l)
if [ -z "$REGISTERED_ZSH" ]; then
    echo "No installed Zsh path is registered in /etc/shells. Check chsh -l." >&2
    exit 1
fi
ZSH_PATH="$REGISTERED_ZSH"
LOGIN_USER="$(id -un)"
CURRENT_SHELL="$(getent passwd "$LOGIN_USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ] && ! [ "$CURRENT_SHELL" -ef "$ZSH_PATH" ]; then
    chsh -s "$ZSH_PATH" "$LOGIN_USER"
    echo "Default shell changed to Zsh. Log out and back in to use it."
else
    echo "Zsh is already the default shell."
fi

# Update a running tmux server without terminating any sessions. Its defaults
# may still come from the old desktop SHELL environment. Existing panes keep
# their current processes; new windows and panes will start Zsh.
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
    tmux set-option -g default-shell "$ZSH_PATH"
    tmux set-option -g default-command ""
    tmux set-environment -g SHELL "$ZSH_PATH"
    echo "Updated tmux defaults. Open a new window or pane to use Zsh."
fi
