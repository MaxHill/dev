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

echo "=== sops Key Installation ==="

# This installer can run independently, before yay is available.
sudo pacman -S --needed --noconfirm age sops

# Resolve script directory and key paths.
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOPS_SOURCE_FILE="$SCRIPT_DIR/keys/sops_keys.age"
SOPS_DEST_DIR="$HOME/.config/sops/age"
SOPS_DEST_FILE="$SOPS_DEST_DIR/keys.txt"

if [ -f "$SOPS_DEST_FILE" ]; then
    echo "SOPS age key already exists at $SOPS_DEST_FILE"
    echo "Skipping decryption to preserve the existing key."
    exit 0
fi

if [ ! -f "$SOPS_SOURCE_FILE" ]; then
    echo "Error: encrypted sops key not found at $SOPS_SOURCE_FILE"
    exit 1
fi

mkdir -p "$SOPS_DEST_DIR"
chmod 0700 "$SOPS_DEST_DIR"

echo "Decrypting sops age key..."
echo "You will be prompted for the encryption passphrase."
TEMP_KEY=$(mktemp "$SOPS_DEST_DIR/.keys.txt.XXXXXX")
if ! age --decrypt --output "$TEMP_KEY" "$SOPS_SOURCE_FILE"; then
    echo "Error: Failed to decrypt sops key"
    exit 1
fi

chmod 0600 "$TEMP_KEY"
mv -f -- "$TEMP_KEY" "$SOPS_DEST_FILE"
TEMP_KEY=

echo "sops key installation complete!"
echo "Key installed at: $SOPS_DEST_FILE"
