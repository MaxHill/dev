# tmux-sessionizer

`tmux-sessionizer` finds project directories, lets you select one with fzf, then creates or switches to a tmux session for it. It is installed as `~/.local/bin/tmux-sessionizer` by `./install-scripts.sh` and uses the shared Lua module installed at `~/.local/lib/lua/lib.lua`.

## Requirements

- Lua
- tmux
- fzf
- `LUA_PATH` set by the Zsh profile installed from this repo, or otherwise configured to include `~/.local/lib/lua/?.lua`

## Configuration

The repo provides a Stow-managed config at `${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer/tmux-sessionizer.lua`. Edit that file or create your own at the same path. It must return a Lua table. All fields are optional:

```lua
return {
    -- A string searches this path to depth 1. A table can set a depth.
    -- Depth 0 selects only the path itself.
    search_paths = {
        "~/",
        "~/personal",
        { path = "~/Git", depth = 3 },
        { path = "~/.config", depth = 2 },
    },

    -- CLI indexes are zero-based: -s 0 runs the first command.
    session_commands = {
        "nvim -c Neogit",
        "lazygit",
    },

    -- true writes diagnostics to log_file or the default log path.
    -- "echo" writes diagnostics to stderr; false disables logging.
    log = false,
    log_file = "~/.local/share/tmux-sessionizer/tmux-sessionizer.logs",
}
```

Paths beginning with `~/` expand to the home directory. Search excludes `.git` directories. Without `search_paths`, the defaults are `~/`, `~/personal`, and `~/personal/dev/env/.config`, each at depth 1.

The former Bash configuration filename (`tmux-sessionizer.conf`) is no longer loaded; its repo config has been migrated to `tmux-sessionizer.lua`. Current-directory config files are not supported.

## Hydration

Hydration files are separate from application configuration and remain tmux command files:

- `~/.tmux-sessionizer` applies to newly created sessions.
- `<project>/.tmux-sessionizer` takes precedence for that project.

The file is sourced inside the tmux session after it is created. Session-command windows and panes skip hydration.

## Usage

```sh
tmux-sessionizer                 # Pick a directory or another tmux session
tmux-sessionizer /path/to/project # Use a selected path directly
tmux-sessionizer --help
tmux-sessionizer --version
```

Configure `session_commands` to use indexed commands:

```sh
tmux-sessionizer -s 0           # Run the first command in a dedicated window
tmux-sessionizer -s 0 --vsplit  # Run it in a vertical split
tmux-sessionizer -s 0 --hsplit  # Run it in a horizontal split
```

The split command reuses its pane while that pane is alive. Pane IDs are cached under `${XDG_CACHE_HOME:-$HOME/.cache}/tmux-sessionizer/`.
