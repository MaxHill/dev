#!/bin/bash

set -e

echo "=== Installing Himalaya Email Client ==="

# Install himalaya and w3m for HTML rendering
echo "Installing himalaya and w3m..."
yay -S --noconfirm --needed himalaya w3m

# Check if 1Password CLI is installed and authenticated
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI (op) is not installed"
    echo "Please install it first: yay -S 1password-cli"
    exit 1
fi

echo "✓ 1Password CLI is installed"

# Check if user is signed in to 1Password
if ! op account list &> /dev/null; then
    echo ""
    echo "⚠️  You need to sign in to 1Password CLI first"
    echo "Run: op signin"
    echo ""
    echo "After signing in, run this script again or continue with install.sh"
    exit 1
fi

echo "✓ 1Password CLI is authenticated"

# The config files will be stowed by install-configs.sh
# So we just verify the structure exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE="$SCRIPT_DIR/configs/himalaya/.config/himalaya"

if [ ! -f "$CONFIG_SOURCE/config.toml" ]; then
    echo "Error: Himalaya config not found at $CONFIG_SOURCE/config.toml"
    exit 1
fi

echo "✓ Himalaya configuration files ready"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Create email credentials in 1Password:"
echo "   - Open 1Password app"
echo "   - Create a new Login item:"
echo "     • Title: 'macl-tech-email'"
echo "     • Username: 'max@macl.tech'"
echo "     • Password: [your email password]"
echo "     • Vault: Private"
echo ""
echo "   OR use the CLI:"
echo "   op item create --category=login --title='macl-tech-email' \\"
echo "     --vault=Private username=max@macl.tech password=[your-password]"
echo ""
echo "2. Test 1Password retrieval:"
echo "   op read 'op://Private/macl-tech-email/password'"
echo ""
echo "3. After install-configs.sh runs, test Himalaya:"
echo "   himalaya"
echo "   himalaya list"
echo ""
echo "✓ Himalaya installation complete!"
