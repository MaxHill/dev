#!/bin/bash

set -e

INPUT_CONFIG="$HOME/.config/hypr/input.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERRIDES_CONFIG="$SCRIPT_DIR/input-overrides.conf"
SOURCE_LINE="source = $OVERRIDES_CONFIG"

# Check if input config exists
if [ ! -f "$INPUT_CONFIG" ]; then
    echo "Hyprland input config not found at $INPUT_CONFIG"
    echo "Please install Omarchy first"
    exit 1
fi

# Check if overrides config exists
if [ ! -f "$OVERRIDES_CONFIG" ]; then
    echo "Input overrides config not found at $OVERRIDES_CONFIG"
    exit 1
fi

# Check if source line already exists in input.conf
if grep -Fxq "$SOURCE_LINE" "$INPUT_CONFIG"; then
    echo "Input overrides already configured in $INPUT_CONFIG"
else
    echo "Adding input overrides to $INPUT_CONFIG"
    echo "" >> "$INPUT_CONFIG"
    echo "$SOURCE_LINE" >> "$INPUT_CONFIG"
    echo "Input overrides added successfully"
fi

echo "Input overrides setup complete!"
echo "Hyprland will auto-reload the configuration."
echo "Use Left Alt + Right Alt to toggle between US and Swedish layouts."
