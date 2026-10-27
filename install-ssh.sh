#!/bin/sh

set -e
umask 077

TEMP_KEY=
cleanup() {
    if [ -n "$TEMP_KEY" ]; then
        rm -f -- "$TEMP_KEY"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

REQUIRE_AGENT=false
case "${1:-}" in
    --require-agent) REQUIRE_AGENT=true; shift ;;
esac
if [ "$#" -ne 0 ]; then
    echo "Usage: $0 [--require-agent]" >&2
    exit 1
fi

echo "=== SSH Key Installation ==="

sudo pacman -S --needed --noconfirm age openssh

# Get script directory
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SSH_SOURCE_DIR="$SCRIPT_DIR/keys"
SSH_DEST_DIR="$HOME/.ssh"

agent_failure() {
    if [ "$REQUIRE_AGENT" = true ]; then
        echo "Error: $*; unlock the systemd user SSH agent before retrying." >&2
        exit 1
    fi
    echo "Warning: $* (you can run ssh-add manually later)" >&2
}

setup_ssh_agent() {
    # Enable the systemd user ssh-agent so the passphrase is cached per session.
    if command -v systemctl >/dev/null 2>&1; then
        echo "Enabling systemd user ssh-agent..."
        if ! systemctl --user enable --now ssh-agent.service; then
            agent_failure "could not enable ssh-agent.service"
        fi
    else
        agent_failure "systemctl is unavailable"
    fi

    # Load the key into the running agent now so this session is also unlocked.
    AGENT_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"
    if [ -S "$AGENT_SOCK" ] && [ -f "$SSH_DEST_DIR/id_ed25519" ]; then
        # Compare fingerprints, not comments: other loaded keys do not count.
        KEY_FINGERPRINT=$(ssh-keygen -lf "$SSH_DEST_DIR/id_ed25519.pub" | awk '{print $2}')
        if [ -n "$KEY_FINGERPRINT" ] && \
           SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add -l 2>/dev/null | \
               awk '{print $2}' | grep -qxF "$KEY_FINGERPRINT"; then
            echo "SSH key is already loaded in ssh-agent; skipping ssh-add."
            return 0
        fi

        echo "Adding key to ssh-agent (you may be prompted for the key passphrase)..."
        if ! SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add "$SSH_DEST_DIR/id_ed25519"; then
            agent_failure "ssh-add failed"
        fi
    else
        agent_failure "SSH agent socket not found at $AGENT_SOCK"
    fi
}

# Check if keys already exist
if [ -f "$SSH_DEST_DIR/id_ed25519" ] && [ -f "$SSH_DEST_DIR/id_ed25519.pub" ]; then
    echo "SSH keys already exist in ~/.ssh/"
    echo "Skipping key installation to preserve existing keys."
    setup_ssh_agent
    exit 0
fi

# Never replace a partial existing key pair with a different private key.
if [ -e "$SSH_DEST_DIR/id_ed25519" ] || [ -L "$SSH_DEST_DIR/id_ed25519" ] || \
   [ -e "$SSH_DEST_DIR/id_ed25519.pub" ] || [ -L "$SSH_DEST_DIR/id_ed25519.pub" ]; then
    echo "Error: incomplete SSH key pair in $SSH_DEST_DIR; restore the missing file before retrying." >&2
    exit 1
fi

# Ensure .ssh directory exists with correct permissions
mkdir -p "$SSH_DEST_DIR"
chmod 0700 "$SSH_DEST_DIR"

# Decrypt and install private key
echo "Decrypting SSH private key..."
echo "You will be prompted for the encryption passphrase."
TEMP_KEY=$(mktemp "$SSH_DEST_DIR/.id_ed25519.XXXXXX")
if ! age --decrypt --output "$TEMP_KEY" "$SSH_SOURCE_DIR/id_ed25519.age"; then
    echo "Error: Failed to decrypt SSH private key"
    exit 1
fi
chmod 0600 "$TEMP_KEY"
mv -f -- "$TEMP_KEY" "$SSH_DEST_DIR/id_ed25519"
TEMP_KEY=
echo "Private key installed: ~/.ssh/id_ed25519"

# Copy public key
cp "$SSH_SOURCE_DIR/id_ed25519.pub" "$SSH_DEST_DIR/id_ed25519.pub"
chmod 0644 "$SSH_DEST_DIR/id_ed25519.pub"
echo "Public key installed: ~/.ssh/id_ed25519.pub"

# Add public key to authorized_keys
touch "$SSH_DEST_DIR/authorized_keys"
chmod 0600 "$SSH_DEST_DIR/authorized_keys"

if ! grep -qxF "$(cat "$SSH_DEST_DIR/id_ed25519.pub")" "$SSH_DEST_DIR/authorized_keys" 2>/dev/null; then
    cat "$SSH_DEST_DIR/id_ed25519.pub" >> "$SSH_DEST_DIR/authorized_keys"
    echo "Public key added to authorized_keys"
else
    echo "Public key already in authorized_keys"
fi

echo ""
echo "SSH key installation complete!"
echo "Keys are ready to use at ~/.ssh/id_ed25519"

setup_ssh_agent
