# Login-shell environment

export EDITOR=nvim
export VISUAL=nvim

# Shared modules for Lua scripts; ;; preserves Lua’s default module paths.
export LUA_PATH="$HOME/.local/lib/lua/?.lua;$HOME/.local/lib/lua/?/init.lua;;"

# Keep the local scripts directory first without duplicating PATH entries.
typeset -U path
path=("$HOME/.local/bin" $path)
export PATH

# XDG directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_MUSIC_DIR="$HOME/music"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export MANPAGER="less -R --use-color -Dd+r -Du+b" # colored man pages

# Public search endpoints for pi-web-tools
export PI_WEB_TOOLS_EXA_ENDPOINT="https://mcp.exa.ai/mcp"
export PI_WEB_TOOLS_PARALLEL_ENDPOINT="https://search.parallel.ai/mcp"

# Use the systemd user ssh-agent enabled by install-ssh.sh.
if [[ -n "$XDG_RUNTIME_DIR" && -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
