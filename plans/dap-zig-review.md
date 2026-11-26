# DAP and Zig commit review

## Context
Review the entire DAP + Zig + Neovim setup on latest `main` in `MaxHill/dotfiles`, not just recent diffs. Pin the snapshot to `5686430add191a7d4725a899a8b94d58b6c2abd4` for reproducible citations. No code changes.
- GitHub's latest commit is `5686430` — Improve Zig DAP variable formatting.
- Its stated intent is to load Zig LLDB pretty-printers for launch, test, and attach; use Apple's lldb-dap; support Python 3.9; and format byte slices and SplitIterator values.
- The current local checkout is `MaxHill/dev`, not the requested repository, and has uncommitted changes. Do not use its working tree as the review target.

## Approach
Audit the pinned main snapshot end-to-end using remote source, with separate correctness/safety, performance, and developer-experience reviews. Include current-state defects even if they predate the latest commit. Read repository standards and use commit intent as context, not as a complete specification. Report prioritized evidence with file/line references; distinguish confirmed defects, platform assumptions, and unverified runtime concerns. Cover general Neovim initialization and plugin integration as well as the Zig-specific workflow. No fixes are part of this review.

## Files to modify
No code files. This Markdown plan is the only local artifact.

## Reuse
- `configs/nvim/.config/nvim/lua/user/languages/zig.lua`: `root`, `bin_dir`, `list_executables`, `pick_executable`, `zig_build`, `input_args`, and `M.setup` own project selection, build callbacks, executable selection, and DAP configuration.
- `configs/nvim/.config/nvim/init.lua`: inspect plugin loading, language setup, DAP UI/keybindings/listeners, LSP, completion, and formatting integration.
- `configs/nvim/.config/nvim/lua/user/mason.lua` and `user/treesitter_install.lua`: inspect existing dependency installation/lifecycle helpers.
- `configs/nvim/.config/nvim/nvim-pack-lock.json`: use pinned plugin versions when checking API contracts.
- `configs/lldb/lldb_pretty_printers.py`: inspect existing summary/synthetic providers and `__lldb_init_module` registration.

## Initial observations to verify
Zig setup installs codelldb but configures a hard-coded Apple lldb-dap path; formatter import assumes `~/dotfiles`. Executable selection mixes synchronous callbacks with coroutine suspension. Test debugging assumes `zig build test` produces `zig-out/bin/test`. These are investigation targets, not yet final findings.

## Steps
- [x] Confirm full current-state review scope on latest main.
- [x] Read pinned Neovim initialization, language modules, dependency helpers, lockfile, LLDB formatters, and relevant install/toolchain configuration; locate repository instructions and tests.
- [x] Trace startup → language setup → DAP registration → command/keybinding → build/select → launch/test/attach → UI lifecycle.
- [x] Check coroutine completion/cancellation, failed builds, missing executables, project root versus working directory, argument parsing, and test artifact assumptions against nvim-dap/Zig contracts.
- [x] Check adapter discovery, platform support, Zig/ZLS versions, Python 3.9 compatibility, formatter registration, invalid values, large slices, and container layouts.
- [x] Review plugin/API compatibility, LSP/formatting/Tree-sitter wiring, unnecessary installation, blocking work, and actionable diagnostics.
- [x] Run isolated specialist reviews where supported using remote pinned source and read-only constraints; synthesize deduplicated findings.
- [x] Produce prioritized findings with source links, concrete impact, recommended fixes, and a verification checklist. Do not implement fixes.

## Verification
Check findings against exact pinned remote source and primary LLDB/Zig documentation where needed. Identify existing tests and propose launch/test/attach smoke checks. Do not install dependencies or execute workflows that modify the checkout during planning.

## Review boundaries
Scope is the full latest-main setup, with macOS and Linux assumptions explicitly identified from source. No originating issue/spec was supplied; do not invent requirements. Runtime validation that requires installations or generated non-Markdown files is deferred; clearly label static-only conclusions. Preserve the unrelated local checkout and its uncommitted changes.
