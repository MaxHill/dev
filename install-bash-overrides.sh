#!/bin/bash

set -e

BASHRC="$HOME/.bashrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERRIDES_CONFIG="$SCRIPT_DIR/bash-overrides.sh"
SOURCE_LINE="source $OVERRIDES_CONFIG"

# Check if bashrc exists
if [ ! -f "$BASHRC" ]; then
    echo "Bashrc not found at $BASHRC"
    echo "Please install bash configuration first"
    exit 1
fi

# Check if overrides config exists
if [ ! -f "$OVERRIDES_CONFIG" ]; then
    echo "Overrides config not found at $OVERRIDES_CONFIG"
    exit 1
fi

# Check if source line already exists in bashrc
if grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    echo "Source line already exists in $BASHRC"
else
    echo "Adding source line to $BASHRC"
    echo "" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo "Source line added successfully"
fi

echo "Bash overrides setup complete!"
