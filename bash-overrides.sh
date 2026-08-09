# Bash configuration overrides
# Add your custom settings here

# Local scripts directory
export PATH=$HOME/.local/bin:$PATH

# Route SSH to the systemd user ssh-agent (enabled by install-ssh.sh)
if [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
