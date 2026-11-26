# Structured Neovim DAP setup

## Context
Bring the useful workflows from `MaxHill/dotfiles` into this repository, with clearer ownership and without the launch/argument/test bugs found in the review.

Initial local findings:
- `configs/nvim/.config/nvim/init.lua` already declares nvim-dap, dap-ui, and nio, and mixes language setup with global DAP configuration.
- `lua/user/languages/zig.lua` already implements build/launch/test/attach with CodeLLDB, but has the same coroutine, cancellation, argument, test-artifact, and cwd defects.
- Zig language configuration has uncommitted user changes: mise ZLS shim and `mise exec zig@0.17.1` formatting. Preserve these; decide toolchain policy explicitly rather than replacing them.
- Local setup also loads a vendored macOS .NET debugger. Platform and language scope need confirmation.

## Approach
Keep the existing file layout as requested: shared DAP UI/keymaps remain in `init.lua`, Zig debugging remains in `languages/zig.lua`, and TypeScript debugging remains in `languages/typescript.lua`. Improve structure through local helpers and clear sections, not new DAP modules. Target Linux only, Zig and TypeScript. Use project-selected mise toolchains, readable bounded LLDB slice/container summaries, a bottom panel with watches, and an explicit build-only test artifact contract. Preserve unrelated C# behavior; do not broaden the refactor.

## Files to modify
Tentative, subject to scope decisions:
- `configs/nvim/.config/nvim/init.lua`: retain shared setup in place; add watches and correct watch/toggle behavior; make missing native FZF non-fatal so DAP setup remains reachable.
- `configs/nvim/.config/nvim/lua/user/languages/zig.lua`: organize local project/build/picker/config helpers in place; fix abort/coroutine/argument/cwd handling; use project mise Zig; load compatible LLDB formatters.
- `configs/nvim/.config/nvim/lua/user/languages/typescript.lua`: replace Astro-only defaults with useful Node/TypeScript launch and inspector attach, while allowing project launch configurations.
- `configs/nvim/.config/nvim/lldb/zig.py` (new support file, not a Lua layout refactor): load the selected Zig distribution's formatters and apply bounded string previews plus focused container summaries. Keep upstream formatters in the toolchain rather than vendoring an obsolete copy.
- `tests/nvim-dap.lua` (new): isolated headless regression harness for language setup and DAP preparation; no new test framework.
- `tests/zig-lldb.py` (new): formatter tests with minimal LLDB value doubles; supplement with actual CodeLLDB sessions.
- `docs/nvim-debugging.md` (new): prerequisites, commands/keymaps, project contracts, troubleshooting, and smoke-test results.
- `~/code/maxhill_me/work/apps/syncdb-compaction/build.zig`: user explicitly permits a build-only debug-test target. Leave this change uncommitted and unstaged for review. Do not modify its test/run behavior or application code.
- No system LLDB install-script change: reuse installed Mason CodeLLDB.

## Reuse
- Existing nvim-dap, dap-ui, nio plugin declarations in `init.lua`.
- Existing `root`, executable scanning, and async `vim.system` build flow in `languages/zig.lua`; move and correct rather than duplicate.
- Existing Mason helper and per-language layout preferences: inspect before deciding whether to retain or replace.

## Steps
- [x] Confirm platforms, languages, Zig toolchain, and desired debugging workflows: Linux, Zig + TypeScript, project mise Zig, readable LLDB values, bottom panel with watches, build-only debug tests, existing file layout.
- [x] Inspect remaining DAP/UI/language setup, installation patterns, project-task conventions, and available test tooling.
- [x] Finalize module seams, configuration interface, startup order, and adapter/test-artifact policies (below).
- [ ] Implement shared setup and Zig workflows, preserving unrelated and uncommitted changes.
- [ ] Add focused regression tests and concise setup/debugging documentation.
- [ ] Verify startup and supported launch/test/attach/UI workflows.

## Verification
Test zero/one/multiple executables, cancellation, failed builds, argument propagation, project-root consistency, adapter absence, and explicit test artifacts. Verify preferred-layout toggling and real watches. Use isolated headless tests that do not install dependencies or touch the normal Neovim profile. Manual debugger smoke checks depend on approved platforms/toolchains.

## Open decisions
Resolved: Node + tsx launch and Node inspector attach only; browser debugging deferred. External build-only debug-test change is permitted but must remain uncommitted/unstaged. No outstanding scope decisions.

## Latest discoveries
- `languages/typescript.lua` currently offers only Astro Dev Server and uses Mason's js-debug adapter. Reuse that adapter, not an additional JS DAP plugin.
- Existing `user.mason.install` already refreshes the registry and guards duplicate installation; reuse it.
- `syncdb-compaction/mise.toml` selects Zig `0.17`; its build installs three executables and creates two test runners, but has no build-only installed test target. This is a useful multiple-artifact test case.
- The user-approved mise selection supersedes the current hard-coded `zig@0.17.1` formatter version; keep the local ZLS shim fix. Run builds and formatting with the same project context.
- Neither `lldb` nor `lldb-dap` is on PATH, but Mason CodeLLDB (including LLDB) and js-debug-adapter are already installed. Use CodeLLDB's server transport with an allocated `${port}`, not its current incorrect stdio/executable transport.
- Installed Zig 0.17.1 includes `lib/lldb/pretty_printers.py`, whose language category is `zig.lang` (not the older `zig`). Discover paths/categories from the selected toolchain; never assume the old 0.13 layout.
- External `AGENTS.md` and `CONTEXT.md` have been read. Keep planning artifacts in this repo only; no durable plan in the external workspace.

## Implementation design

### Existing-file seams and startup
- `init.lua` continues owning plugin declarations, shared bottom layouts, listeners and keymaps. Language `M.setup()` remains the registration interface. Keep project-specific state inside each launch preparation, not global mutable cwd/artifact variables.
- Preserve the existing Mason helper and locked plugins. Guard FZF loading with a useful warning rather than letting an optional sorter abort DAP setup. Keep C# configuration out of scope; guard the macOS-only vendored debugger activation on Linux instead of redesigning C#.
- Keep two existing bottom layouts if required by untouched languages; add watches to each and toggle only the active/preferred one. Determine session layout from the session configuration/adapter rather than whichever buffer happens to be current at `initialized`. `<leader>dw` uses the real watches element add function; retain hover/eval and existing continue/step/breakpoint keys. Add a clear REPL access mapping and step-out mapping without colliding with existing keys.

### Zig workflow (`languages/zig.lua`)
- Local helpers capture the buffer's Zig root once, resolve `mise exec -- zig` in that cwd, build asynchronously, select artifacts and prepare an entire configuration through nvim-dap's supported asynchronous configuration seam. Schedule completion safely and complete exactly once; every missing artifact, cancelled input, build failure or process-start failure aborts before starting the adapter.
- Configurations: Build & Launch, Launch (no build), Build & Test (build-only), Attach to Process. Validate adapter and artifact executability; sort candidate executables. Use root consistently for build, selection, mise/tool resolution, formatting and debuggee cwd.
- Use `mise exec -- zig build -Doptimize=Debug`; test mode uses `mise exec -- zig build debug-test -Doptimize=Debug`, then selects only artifacts under `zig-out/debug-tests/`. Do not scan Zig caches or run `zig build test` first. Missing target/artifacts produce the exact build-only contract and recovery instructions.
- Prompt for arguments as a JSON string array, validate strings and preserve spaces/quotes exactly; empty input means no arguments and cancellation aborts. This avoids shell execution and a custom shell parser. Mirror this convention for TypeScript launch arguments.
- Keep the user's portable ZLS shim fix, include `zon` in ZLS filetypes, and replace only the formatter's fixed `zig@0.17.1` with project-context `mise exec -- zig fmt --stdin`. Do not change global mise versions.
- Resolve the selected compiler via mise/`zig env`, locate its LLDB Python module, and load it using safely quoted LLDB/Python commands. Enable its actual language and stdlib categories, not compiler-internals categories. Support known distribution path/category variants; missing/incompatible formatters get an actionable warning without silently importing the wrong toolchain.
- The small support script uses upstream slice/container providers where valid, bounds byte previews (for example 256 bytes), shows truncation and original length, distinguishes unreadable data, and adds summaries for ArrayList (`items`), SplitIterator and tested HashMap layouts. Preserve raw expansion on unknown layouts; cap expensive map inspection instead of scanning arbitrarily large capacity. No blanket promise to pretty-print every Zig stdlib version/container.

### TypeScript workflow (`languages/typescript.lua`)
- Reuse Mason js-debug with its server transport. Check server script and runtime availability with clear `:Mason` recovery messages.
- Provide Node + tsx Launch current file and Node inspector Attach (default port 9229, loopback only) for the existing JS/TS filetypes. Launch Node through project-context mise with `--import tsx`, preserving source maps and using the selected file's project root. Resolve tsx locally (including ancestor workspace node_modules); never download it automatically. Explain the prerequisite if absent.
- Keep project `.vscode/launch.json` support provided by nvim-dap; no additional JS DAP plugin or browser configurations. Document how project-specific arguments/cwd can override defaults.

### External debug-test build graph
- Reuse `mod_tests` and `exe_tests`. Add install-artifact steps depending on compilation only, with distinct filenames beneath `zig-out/debug-tests/`, and a `debug-test` top-level step depending on those installs. Do not attach this installation to the normal default build or execute the test binaries in that step. Leave the existing `test` step intact.

### Call flow
`<leader>dc` → nvim-dap selects configuration → capture root → resolve project tools → optional asynchronous debug build → choose validated artifact + arguments → start CodeLLDB/js-debug → load Zig formatters where applicable → initialize bottom scopes/watches/output → stop/inspect/step → termination cleanup. Attach skips build and artifact selection.

## Detailed verification
- Regression harness loads language modules with stubbed dependencies without sourcing the full plugin-installing init. Assert zero/one/many executable handling, synchronous and asynchronous selection, cancellation, process-spawn failure, failed builds, JSON argv validation, project root stability after buffer changes, missing adapters, and no test execution in test preparation.
- Python tests verify empty, escaped, non-ASCII, truncated and unreadable byte slices; requested reads stay bounded. Exercise known container summaries and safe fallback.
- Check Lua/Python syntax and formatting; run headless tests with isolated state. Confirm fresh configuration continues when optional FZF is absent and that watch/toggle mappings use the intended layout.
- External workspace: inspect its current status before editing; add only the allowed build target. Build from `syncdb-compaction` with its mise-selected version; verify both debug-test artifacts exist and the build target does not run them. Preserve all unrelated changes, do not stage or commit anything.
- Run a bounded CodeLLDB DAP launch against one installed debug-test executable, set a breakpoint, inspect slice/container values, step, and disconnect. Build/select the normal app but do not run compaction against user data. Use a disposable fixture when application execution is needed.
- Run Node+tsx launch on a disposable script with breakpoint/source mapping and spaced arguments, then loopback inspector attach. Use existing workspace tsx or report missing prerequisites; no browser test.
- Record actual commands/results and platform/ptrace/toolchain limitations. If the external app cannot compile with installed dependencies, report the blocker rather than updating its application code or dependencies.
