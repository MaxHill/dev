# Bash configuration overrides
# Add your custom settings here

# Local scripts directory
export PATH=$HOME/.local/bin:$PATH

# Public search endpoints for pi-web-tools
export PI_WEB_TOOLS_EXA_ENDPOINT="https://mcp.exa.ai/mcp"
export PI_WEB_TOOLS_PARALLEL_ENDPOINT="https://search.parallel.ai/mcp"

# Route SSH to the systemd user ssh-agent (enabled by install-ssh.sh)
if [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
