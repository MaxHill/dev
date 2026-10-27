# Installer authentication

## Context
`install.sh` runs separate child scripts. Sudo authentication can expire during the run. `install-sops.sh` decrypts `keys/sops_keys.age` with age; `install-ssh.sh` separately decrypts `keys/id_ed25519.age`, then calls `ssh-add`, which can request the SSH key's own passphrase. These are distinct authentication layers, not necessarily the same password.

## Approach
- Authenticate sudo once with `sudo -v` at entry, then refresh with a noninteractive `sudo -n -v` keepalive every 30 seconds. Stop and reap the keepalive on success, failure, or interruption. Do not invalidate an existing sudo session on exit. `sudo -v` only validates/caches authorization; it does not change the installer's UID. Invoke child scripts directly, never through sudo: `make`, `makepkg`, yay, and home configuration remain normal-user processes. Only individual commands explicitly prefixed with sudo (such as pacman) run as root. Reject `sudo ./install.sh` with instructions to run `./install.sh` instead.
- Move existing age, SOPS, and SSH installation steps before the long package/configuration work. Each child installer owns installing its own dependencies using sudo/pacman, not the top-level orchestrator: `install-age.sh` installs age; `install-sops.sh` ensures both age and SOPS; `install-ssh.sh` ensures both age and OpenSSH. Use official Arch packages so these scripts do not depend on yay, which is bootstrapped later by `install-hyprland.sh`. Each authentication installer runs only once; repeated dependency checks use `--needed` and do not trigger duplicate decryption. Keep each script directly runnable on its own.
- Let age prompt separately for the two different backup passphrases. Let ssh-add prompt for the private key's own passphrase if required. Do not capture, cache, or export passwords. This achieves early prompts without introducing a credential broker or temporary shared secrets.
- Preserve standalone scripts, existing SSH keys, destination permissions, public-key setup, and authorized_keys deduplication. Retain the current SOPS replacement behaviour, but decrypt into a private temporary file in its destination directory and rename only after success. Apply the same atomic installation pattern to a newly decrypted SSH private key. Clean temporary files on failure/interruption.
- Reuse the systemd user SSH agent at `$XDG_RUNTIME_DIR/ssh-agent.socket`. In the full install, require successful agent startup and key loading before continuing; otherwise fail early with a useful diagnostic. Standalone SSH installation retains its current warning-only agent behaviour. Do not create a short-lived fallback agent that disappears with the installer.
- This moves known credential prompts ahead of long-running installation, not necessarily before prerequisite packages are installed. External package tools or custom sudo policies may still introduce their own prompts.

## Files to modify
- `install.sh`: sudo lifecycle, cleanup traps, early authentication phase, and removal of later duplicate calls. Orchestrates child scripts as the current user; does not install their dependencies itself. Resolve and enter the repo directory so child paths work from any caller directory.
- `install-age.sh`: use official Arch age package via sudo/pacman without requiring yay.
- `install-sops.sh`: ensure its own age and SOPS dependencies via sudo/pacman, replacing the instruction to run the age installer first; atomic decryption and cleanup.
- `install-ssh.sh`: ensure its own age and OpenSSH dependencies via sudo/pacman, replacing the instruction to run the age installer first; atomic decryption and optional strict agent mode (`--require-agent`) used by the full installer.
- `tests/install-auth.sh`: isolated shell regression tests with fake commands and temporary HOME; no real keys or system changes.

## Reuse
- Existing age decryption and destination permissions in `install-sops.sh` and `install-ssh.sh`.
- Existing `setup_ssh_agent()` and systemd user agent socket in `install-ssh.sh`.
- Existing sequential installer flow in `install.sh`.

## Steps
- [ ] Before making any authentication implementation changes, review `git status`, existing diffs, and untracked files, then commit the current work as a separate checkpoint. Include the existing Ly setup and current Hyprland work (and other intended current changes found during review); exclude credentials, decrypted private keys, and generated files. Use explicit staging after reviewing contents. Verify the commit succeeded and record its hash before starting implementation. Perform this commit only after plan approval, since planning mode prohibits commits.
- [ ] Add normal-user validation, repo path resolution, upfront sudo authentication, keepalive, and EXIT/INT/TERM cleanup to `install.sh`. Use Bash if needed for reliable traps and process management; align the shebang and syntax checks.
- [ ] Make each early key installer self-contained: install its own dependencies with `sudo pacman -S --needed --noconfirm` before use, without requiring yay or a prior run of another installer. Keep dependency installation out of `install.sh`.
- [ ] Make private-key installation atomic with restrictive umask, mode 0600, same-directory temporary files, and cleanup traps. A failed decrypt must leave existing destination files untouched.
- [ ] Add `--require-agent` to `install-ssh.sh`; propagate systemd/ssh-add errors in this mode while preserving standalone defaults. Do not duplicate ssh-add later.
- [ ] Order the full run as sudo validation → direct `./install-age.sh` → direct `./install-sops.sh` → direct `./install-ssh.sh --require-agent` → existing remaining installation sequence. Each child handles its own dependencies; none is invoked through sudo. Keep unrelated installer changes untouched.
- [ ] Add mock-based regression tests and run syntax checks.

## Verification
- Verify the pre-implementation checkpoint commit contains the intended current work and that subsequent authentication changes are separate from that baseline.
- Shell syntax checks for changed scripts.
- Mock sudo, age, package managers, and SSH tools to verify prompt order and invocation counts.
- Assert that child scripts, make, makepkg, and yay are not invoked through sudo; only designated privileged commands are. Check that running the orchestrator as root is rejected before changes.
- Test each key installer independently with missing dependencies: it must request its own official packages without requiring yay or another installer to have run.
- Cover wrong credentials, sudo cancellation/refresh failure, failed child scripts, interrupts, existing SSH keys, missing agent socket/service, ssh-add failure, and cleanup of temporary secrets/background processes. A failed noninteractive refresh must never open a background password prompt.
- Verify exact early child ordering, absence of later duplicate decrypt/ssh-add calls, standalone warning-only behaviour versus strict full-install behaviour, and that failed decrypts preserve existing destination contents.
- Use disposable encrypted test fixtures for a manual age/ssh-add check; never log or read the real private keys.
- Manual full-run check on the user's machine: no repeated sudo prompts; expected age and SSH prompts only; correct private-file permissions.

## Confirmed requirements and limits
- The two age backup files use different passphrases; both prompts are necessary.
- The user wants prompts early where possible. Whether the SSH private key has another passphrase is uncertain; ssh-add detects that without the installer inspecting or storing the password.
- The SSH private-key passphrase is distinct from sudo/login authentication, even if the user happened to choose the same text.
- No changes to encryption formats or stored passphrases. No promise of a single password prompt for independent credentials.
