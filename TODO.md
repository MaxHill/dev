# Dotfiles migration TODO

Porting changes from `~/dotfiles_old/configs` into `~/dev/configs`. Work through one at a time.

## Theme (gruvbox-material)

- [x] **nvim**: switch to `gruvbox-material` (hard bg, material fg, italic). Remove `matteblack`/transparency block. Keep `rose-pine` optional.
- [x] **ghostty**: `theme = gruvbox-material-dark-hard`, font `JetBrains Mono` size 16. Keep Linux-specific `async-backend = epoll` and tmux auto-attach `command`. *(font left as-is per request)*
- [x] **tmux**: `@minimal-tmux-bg #1d2021`, `@minimal-tmux-fg #d4be98`, `mode-style bg=#d8a657,fg=#1d2021`.
- [x] **opencode**: add `themes/gruvbox-material-dark-hard.json` (drop `matteblack.json` if unused).

## OCaml

- [x] Add `lua/user/languages/ocaml.lua` (190 lines).
- [x] Add `snippets/ocaml.lua` (123 lines).
- [x] Register `require("user.languages.ocaml")` in `init.lua`.

## Neogit + git tooling

- [x] `init.lua`: add plugins `NeogitOrg/neogit`, `sindrets/diffview.nvim`.
- [x] `init.lua`: `neogit.setup{ kind="tab", integrations.diffview=true, diff_viewer="diffview" }`.
- [x] `init.lua`: keymaps `<leader>gg` Neogit, `<leader>gc` commit, `<leader>gp` push.
- [ ] **Skipped**: `lua/user/languages/git.lua` (prr-specific, prr plugin not wanted).
- [x] **tmux.conf**: `<prefix>g` popup → `nvim -c 'Neogit'` (was lazygit).
- [ ] **tmux-sessionizer**: window 1 command → `nvim -c "Neogit"`. *(covered in sessionizer section)*
- [ ] **~/.gitconfig**:
  - [x] `pager = delta`, `interactive.diffFilter = delta --color-only`, `[delta]` block (navigate, line-numbers, side-by-side, syntax-theme=gruvbox-dark). *(created `install-delta.sh`, added to `install.sh`)*
  - [x] `push.autoSetupRemote = true`.
  - [ ] **Skipped**: `[color]` + `[color "diff"]` blocks.
  - [x] `diff.algorithm=histogram`, `colorMoved=zebra`, `colorMovedWS=allow-indentation-change`.
  - [ ] **Skipped**: `merge.conflictstyle = zdiff3`.
  - [ ] **Skipped**: aliases `lg`, `dv`, `dvd`.
  - [x] Difftool: `nvimdiff` with `/usr/bin/nvim` (Linux path), `prompt = false`.

## nom

- [x] Add `configs/nom/.config/nom/config.yml` stow package (path adapted from macOS `~/Library/Application Support/nom/` to Linux XDG `~/.config/nom/`). Created `install-nom.sh` (`yay -S nom`) and added to `install.sh`.

## nvim init.lua refactor

- [x] Add `lua/user/treesitter_install.lua` and switch to dynamic parser install from `M.treesitter_parsers` per language.
- [ ] Add per-language `M.filetypes` and `M.treesitter_parsers` in every language file. *(will happen in language-specific section)*
- [x] Enable inlay hints on LSP attach.
- [x] Expose `_G.default_on_attach`.
- [x] Preserve language-provided `on_attach` (only default when missing).
- [x] Remove `print("LSP attached: ...")` debug.
- [x] Telescope: switch defaults to `layout_strategy = "bottom_pane"`, `height = 0.4`. *(kept hidden-file support)*

*(Skipped: `markdown-preview.nvim`, `prr` plugins — not wanted.)*

## Mise integration (nvim)

- [ ] **Skipped**: `options.lua` static `makeprg` (overridden by buffer-local autocmd).
- [x] `init.lua`: `find_mise_root()` helper.
- [x] `init.lua`: `run_mise_task()` helper (terminal split).
- [x] Keymaps: `<leader>mb` `:make build`, `<leader>mt` `:make test`, `<leader>mr` `run` (terminal split).
- [x] Autocmd: buffer-local `makeprg = mise -C <root> run --raw $*` (accepts any task), generalized errorformat filter (any `[taskname] $ ...` / `[taskname] ERROR ...`), auto `:cwindow` on `QuickFixCmdPost`, and lcd/restore around `:make`.

## nvim options.lua

- [ ] LSP folding: `foldmethod=expr`, `foldexpr=v:lua.vim.lsp.foldexpr()`, `foldlevel=99`, `foldenable=true`.

## nvim types.lua

- [x] Add `treesitter_parsers?: string[]` field.

## Language-specific nvim configs

- [ ] **Skipped**: `typescript.lua` (dual Deno/ts_ls, deno fmt).
- [x] **csharp.lua**: disable semantic tokens on attach (anti-flicker); add `vim.cmd.compiler("dotnet")`; override `<leader>dc` to build-then-debug. Also added `M.treesitter_parsers`.
- [ ] **Skipped**: `go.lua` (not enabled currently).
- [x] **md.lua**: add `vale-ls` LSP; prettier with `--prose-wrap always --print-width 75`; added `M.filetypes` / `M.treesitter_parsers`. *(created `install-vale.sh`; ported `configs/vale/` stow package with `.vale.ini` at `$HOME` and styles under `~/.vale/styles/`)*
- [x] **zig.lua**: add `errorformat` block; safer `root()` handling; added `M.treesitter_parsers`.
- [x] **lua.lua**: added `filetypes`, `treesitter_parsers`, stylua formatter.
- [x] **html.lua**: added `filetypes`, `treesitter_parsers`. *(kept commented out in init.lua)*
- [x] **css.lua**: added `filetypes`, `treesitter_parsers`, prettierd/prettier formatters. *(kept commented out in init.lua)*
- [ ] **Skipped**: `astro.lua`, `beancount.lua` metadata backfill.

## tmux.conf (non-theme changes)

- [ ] **Skipped**: `default-shell`/`default-command` (fish, macOS path).
- [x] `mode-keys vi`.
- [x] `@vim_navigator_no_wrap 1`.
- [x] Pane resize: `bind -r C-h/j/k/l resize-pane ...`.
- [ ] **Skipped**: change `prefix2` from `C-Space` → `C-s`.
- [x] Splits/new-windows preserve `pane_current_path`: rebind `"`, `%`, `c`.
- [ ] **Skipped**: `history-limit 200000`.
- [x] `escape-time 0`.
- [x] `extended-keys csi-u`, `xterm-keys on`.
- [ ] **Skipped**: `status-position bottom`.
- [ ] **Skipped**: `send-prefix` bindings and `unbind-key C-z`.
- [ ] **Skipped**: remove TPM block (breaks current plugins).
- [ ] **Skipped**: sessionizer path changes and daily-note/TODO bindings (handled elsewhere).

## tmux-sessionizer.conf

- [ ] **Skipped** — current config is correct for this machine (old paths were macOS-specific: `~/dotfiles`, `~/mhc`).

## opencode.json

- [ ] **Skipped** — current config is preferred.

## mise config.toml

- [ ] **Skipped** — current config is correct.

## Linux portability watch-list

- [ ] `.gitconfig`: no `osxkeychain`, no `/opt/homebrew/bin/nvim`.
- [ ] `tmux.conf`: no `/opt/homebrew/bin/fish`.
- [ ] tmux + sessionizer: `~/dotfiles/scripts/...` paths — repo lives at `~/dev` now.
- [ ] ghostty: keep Linux-only `async-backend = epoll` and tmux auto-attach `command`.

## Things current has that old doesn't (don't overwrite)

- `configs/himalaya`, `configs/qutebrowser`.
- tmux plugins: `minimal-tmux-status`, `vim-tmux-navigator`, full `tpm` checkout.
- ghostty `matte-black` theme.
- nvim treesitter queries: `supermd`, `supermd_inline`, `ziggy`, `ziggy_schema`.
- opencode `matteblack.json` theme.
