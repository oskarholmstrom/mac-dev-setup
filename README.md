# Mac setup

My personal macOS dev-machine bootstrap: Homebrew packages, dotfiles (zsh,
Ghostty, Starship, Zed, mise), macOS defaults, and a verifier. A sketch — meant
to be read and edited, not run blindly on someone else's machine.

## Quick start

```bash
git clone git@github.com:oskarholmstrom/mac-dev-setup.git
cd mac-dev-setup
chmod +x setup.sh macos-defaults.sh verify.sh adapt-this-mac.sh

./setup.sh        # FRESH machine: walks through phases, pauses for manual steps
./verify.sh       # confirm everything's in place
```

On a Mac you already use, run `./adapt-this-mac.sh` instead — see below.

## Files

| File                    | What it does                                              |
|-------------------------|-----------------------------------------------------------|
| `Brewfile`              | Declarative list of all Homebrew packages and casks       |
| `setup.sh`              | Orchestrator — runs phases, pauses for manual steps       |
| `macos-defaults.sh`     | macOS preferences (Finder, Dock, keyboard, etc.)          |
| `verify.sh`             | Post-install check — prints ✓/✗ for each thing            |
| `adapt-this-mac.sh`     | Safely bring your *current* (already-configured) Mac to parity |
| `vscode-extensions.txt` | VS Code extension list — replayed by `setup.sh` phase 2.5 |
| `config/`               | Starter dotfiles (ghostty, starship, mise, zed) — copied in |
| `config/cli-tools.tsv`  | CLI cheat-sheet behind the `tools` command (name/what/example) |
| `config/claude/`        | Claude Code transcript-backup script (scheduled via launchd) |
| `config/git/ignore`     | Global gitignore wired via `core.excludesfile`            |
| `karabiner/`            | "Hold ⌘Q to quit" rule — copied in, enabled in the app    |

`setup.sh` is **idempotent** — safe to re-run if a phase fails. Fix the issue and run it again from the top; phases that already completed will skip.

