#!/bin/sh

set -e

yay -S --noconfirm --needed zen-browser-bin

yay -S --noconfirm --needed firefox
yay -S --noconfirm --needed librewolf
yay -S --noconfirm --needed chromium

# This switch has no equivalent managed policy. Preserve other launcher flags.
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FLAGS_FILE="$CONFIG_HOME/chromium-flags.conf"
mkdir -p "$CONFIG_HOME"
if ! grep -Fxq -- '--extensions-on-chrome-urls' "$FLAGS_FILE" 2>/dev/null; then
    printf '\n%s\n' '--extensions-on-chrome-urls' >> "$FLAGS_FILE"
fi

# Suppresses warnings for ALL dangerous command-line flags, not only the above.
# This intentionally makes Chromium report that it is managed.
POLICY_DIR=/etc/chromium/policies/managed
sudo install -d -m 755 "$POLICY_DIR"
printf '%s\n' '{"CommandLineFlagSecurityWarningsEnabled":false}' \
    | sudo tee "$POLICY_DIR/dotfiles-command-line-warnings.json" >/dev/null
sudo chmod 644 "$POLICY_DIR/dotfiles-command-line-warnings.json"
echo "Chromium flags configured; fully quit and restart Chromium to apply."

# Remove only the policy link from our former seed-color setup.
# Chromium now uses the desktop GTK theme (Appearance -> Use GTK).
POLICY_LINK=/etc/chromium/policies/managed/dotfiles-theme.json
POLICY_SOURCE="${XDG_CONFIG_HOME:-$HOME/.config}/theme/chromium-policy.json"
if [ -L "$POLICY_LINK" ] && [ "$(readlink "$POLICY_LINK")" = "$POLICY_SOURCE" ]; then
    sudo rm -- "$POLICY_LINK"
    rm -f -- "$POLICY_SOURCE"
    if pgrep -u "$(id -u)" -x chromium >/dev/null; then
        chromium --refresh-platform-policy --no-startup-window
    fi
fi
