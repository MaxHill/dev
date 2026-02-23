#!/bin/sh

set -e

echo "=== Scripts Installation ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_SOURCE_DIR="$SCRIPT_DIR/scripts"
SCRIPTS_DEST_DIR="$HOME/.local/bin"

# Ensure destination directory exists
mkdir -p "$SCRIPTS_DEST_DIR"

# Copy all scripts from scripts/ directory
echo "Installing scripts to ~/.local/bin..."
for script in "$SCRIPTS_SOURCE_DIR"/*; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        echo "  Installing $script_name..."
        cp "$script" "$SCRIPTS_DEST_DIR/$script_name"
        chmod +x "$SCRIPTS_DEST_DIR/$script_name"
    fi
done

echo "Scripts installation complete!"
