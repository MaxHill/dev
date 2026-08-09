#!/bin/sh

set -e

echo "=== sops Key Installation ==="

# Install sops first.
yay -S --noconfirm --needed sops

if ! command -v age >/dev/null 2>&1; then
    echo "Error: age not found"
    echo "Please run: ./install-age.sh first"
    exit 1
fi

# Resolve script directory and key paths.
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOPS_SOURCE_FILE="$SCRIPT_DIR/keys/sops_keys.age"
SOPS_DEST_DIR="$HOME/.config/sops/age"
SOPS_DEST_FILE="$SOPS_DEST_DIR/keys.txt"

if [ ! -f "$SOPS_SOURCE_FILE" ]; then
    echo "Error: encrypted sops key not found at $SOPS_SOURCE_FILE"
    exit 1
fi

mkdir -p "$SOPS_DEST_DIR"
chmod 0700 "$SOPS_DEST_DIR"

echo "Decrypting sops age key..."
echo "You will be prompted for the encryption passphrase."
if ! age --decrypt --output "$SOPS_DEST_FILE" "$SOPS_SOURCE_FILE"; then
    echo "Error: Failed to decrypt sops key"
    exit 1
fi

chmod 0600 "$SOPS_DEST_FILE"

echo "sops key installation complete!"
echo "Key installed at: $SOPS_DEST_FILE"
