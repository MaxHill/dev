# Migrate tmux-sessionizer to Lua

## Context

Move `scripts/tmux-sessionizer` and its app configuration onto the same Lua executable/shared `lib` setup as the other scripts, while preserving its CLI and tmux workflows. User confirmed the config should become Lua; `~/.tmux-sessionizer` hydration files remain tmux command files.

## Approach

- Keep the installed executable name `tmux-sessionizer` and its current command-line behavior, including the 0-based `-s` index used by existing keybindings.
- Port orchestration to Lua and reuse `lib.run`, `lib.exec`, `lib.shell_quote`, and shared filesystem/process helpers as appropriate.
- Replace Bash config sourcing with one user-level Lua config returning a table at `${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer/tmux-sessionizer.lua`. Configure search locations in one `search_paths` list; each entry may be a path string or `{ path = "...", depth = N }`. Entries without an explicit depth use depth 1. The table also supports `session_commands`, `log`, and `log_file`; all fields are optional. Preserve 0-based CLI indexing into `session_commands`. Do not load current-directory/local config files.
- Put a commented example of the Lua config table and its fields at the top of `scripts/tmux-sessionizer`, as requested, and keep the full usage/config explanation in `docs/tmux-sessionizer.md`.
- Preserve project search, session/window/pane switching, hydration, logging, and pane-cache behavior. Extract common fzf invocation/output handling into `lib.fzf` for both `git-b` and tmux-sessionizer.
- Keep `~/.tmux-sessionizer` and project `.tmux-sessionizer` hydration files as tmux command files. The current home hydration file creates scratch/opencode windows and opens Neovim; it is not part of the config migration.
- The repo Stow package includes a tmux-sessionizer config, which is migrated from Bash `tmux-sessionizer.conf` to the Lua table. The tmux config invokes `tmux-sessionizer` unchanged and uses `-s 0` for its session-command binding.
- Implement the documented logging intent: `log = true` appends diagnostics to `log_file` or the default `~/.local/share/tmux-sessionizer/tmux-sessionizer.logs`; `log = "echo"` emits diagnostics to stderr; `log = false` disables logging.

## Files to modify

- `scripts/tmux-sessionizer` — Lua implementation; retain its command name.
- `scripts/lib/lib.lua` — add shared `lib.fzf(options)` selection helper and any minimal process/filesystem helpers needed by the port.
- `install-scripts.sh` — likely no change; it already installs scripts and the shared module.
- `docs/tmux-sessionizer.md` — document the Lua config schema, old-to-new filename migration, and CLI examples.
- `TODO.md` — update the obsolete `tmux-sessionizer.conf` note to reference the Lua config.

## Reuse

- `scripts/lib/lib.lua`: shell quoting, command execution/capture, program checks. Its verbose command diagnostics go to stderr.
- `scripts/git-b`: existing fzf selection, query, and cancellation behavior; refactor it to call the shared helper while preserving its type-new-branch workflow.
- `install-scripts.sh`: copies executable scripts to `~/.local/bin` and `lib.lua` to `~/.local/lib/lua/lib.lua`.

## Steps

- [x] Decide to use Lua-only config; retain tmux command files for hydration.
- [x] Decide that `log = true` must write to the default log file as documented.
- [x] Add reusable `lib.fzf(options) -> selection | nil, query | nil`. Options include `items`, optional `args`, and `print_query`; return `(nil, query)` when Enter submits an unmatched query, and `(nil, nil)` on cancel. Handle temporary candidate input, fzf exit status, and output parsing inside the helper.
- [x] Update `scripts/git-b` to use `lib.fzf` without changing branch selection or branch creation behavior.
- [x] Port CLI parsing, defaults, single user-level Lua config loading, logging, and search-directory enumeration. Normalize string/table `search_paths` entries and apply depth 1 when an entry omits depth; preserve the `-s 0` command index convention.
- [x] Port tmux session selection/switching, session commands, hydration, and pane cache operations.
- [x] Keep default and custom search paths, optional per-path depth, and fzf cancellation behavior.
- [x] Add the commented config example at the top of `scripts/tmux-sessionizer`, update documentation for the user-level Lua config, and remove Bash implementation while preserving the installed command name.

## Verification

- [x] Run Lua syntax checks and the script's `--help`/`--version` paths.
- [x] Test `lib.fzf` with stub fzf for selection, query-only/no-match, and cancellation; cover both `git-b` and tmux-sessionizer call patterns.
- [x] Use stub `tmux` and filesystem fixtures to test string and `{ path, depth }` search entries, default depth, current-session exclusion, session creation/switching, hydration, and pane-cache cleanup.
- [x] Test session command index validation and both split directions, including cached-pane reuse.
- [x] Test `log = true`, `log = "echo"`, and `log = false`, including a custom log-file path.
- [x] Run `./install-scripts.sh` in a temporary home and verify the installed executable can require `lib`.
- [x] Confirm the existing tmux keybindings still invoke `~/.local/bin/tmux-sessionizer` unchanged.
