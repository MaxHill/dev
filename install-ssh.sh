#!/bin/sh

set -e

echo "=== SSH Key Installation ==="

# Get script directory
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SSH_SOURCE_DIR="$SCRIPT_DIR/keys"
SSH_DEST_DIR="$HOME/.ssh"

setup_ssh_agent() {
    # Enable the systemd user ssh-agent so the passphrase is cached per session.
    if command -v systemctl >/dev/null 2>&1; then
        echo "Enabling systemd user ssh-agent..."
        systemctl --user enable --now ssh-agent.service || \
            echo "Warning: could not enable ssh-agent.service (continuing)"
    fi

    # Load the key into the running agent now so this session is also unlocked.
    AGENT_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"
    if [ -S "$AGENT_SOCK" ] && [ -f "$SSH_DEST_DIR/id_ed25519" ]; then
        echo "Adding key to ssh-agent (you may be prompted for the key passphrase)..."
        SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add "$SSH_DEST_DIR/id_ed25519" || \
            echo "Warning: ssh-add failed (you can run it manually later)"
    else
        echo "Warning: ssh-agent socket not found at $AGENT_SOCK; skipping ssh-add"
    fi
}

# Check if keys already exist
if [ -f "$SSH_DEST_DIR/id_ed25519" ] && [ -f "$SSH_DEST_DIR/id_ed25519.pub" ]; then
    echo "SSH keys already exist in ~/.ssh/"
    echo "Skipping key installation to preserve existing keys."
    setup_ssh_agent
    exit 0
fi

# Check if age is installed
if ! command -v age >/dev/null 2>&1; then
    echo "Error: age not found"
    echo "Please run: ./install-age.sh first"
    exit 1
fi

# Ensure .ssh directory exists with correct permissions
mkdir -p "$SSH_DEST_DIR"
chmod 0700 "$SSH_DEST_DIR"

# Decrypt and install private key
echo "Decrypting SSH private key..."
echo "You will be prompted for the encryption passphrase."
if ! age --decrypt --output "$SSH_DEST_DIR/id_ed25519" "$SSH_SOURCE_DIR/id_ed25519.age"; then
    echo "Error: Failed to decrypt SSH private key"
    exit 1
fi
chmod 0600 "$SSH_DEST_DIR/id_ed25519"
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
