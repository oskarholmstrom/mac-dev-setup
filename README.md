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

## Adapting your current (already-configured) Mac

`setup.sh` is meant for a *fresh* machine. Do **not** run it top-to-bottom on a Mac
you already use — phase 4 (git/SSH) would repoint `~/.ssh/config` at the 1Password
agent and break working auth, and phase 7 rewrites system prefs.

Use `adapt-this-mac.sh` instead:

```bash
./adapt-this-mac.sh   # backs up your dotfiles + defaults, then runs only the
                      # additive phases (apps/CLI, extensions, shell+configs, languages)
```

It reuses `setup.sh`'s phase functions, snapshots everything it touches into
`~/mac-setup-backup-<timestamp>/` first (zshrc, gitconfig, ssh config, **fish**,
**Zellij**, **Ghostty**, login shell, a `brew bundle dump`, and the macOS defaults
domains), then:

- installs the missing apps/CLI (skipping casks listed in `ADAPT_SKIP_CASKS` that
  you already have or don't want on this machine);
- **switches you off fish + Zellij** onto the new zsh setup — sets the login shell
  to zsh and replaces the Ghostty config (fish & Zellij stay installed but unused);
- deliberately **skips** git/SSH and macOS defaults (it prints how to run those by hand).

Everything is reversible from the backup dir (the script prints the exact revert
commands). Apps you installed outside Homebrew show up as "needs install" — adopt
them with `brew install --cask --adopt <name>` if you want brew to manage them.

## Before you run it

A few things to verify or customize:

1. **Cask names** — verified: `conductor`, `cmux`, and `tuna` are all in central `homebrew/cask` (checked against the live API), so no custom tap is needed. If a `brew bundle` run ever fails on one cask, run `brew update` first (a stale Homebrew can crash on the cask API), then re-run.
2. **Editor extensions** — VS Code's are captured in `vscode-extensions.txt` and replayed automatically. For Zed, prefer `auto_install_extensions` in `~/.config/zed/settings.json` plus account sign-in for settings sync.
3. **Dotfiles** — this script doesn't manage your `.zshrc`, `.gitconfig`, or `~/.config/*` beyond a basic block. Once you have a dotfiles repo, add a phase that clones and symlinks it.
4. **Slack workspace, 1Password account, etc.** — manual sign-ins after install.

## Pattern

Every phase is shaped like:

```bash
phase_N_name() {
  if <thing already done>; then
    success "already done"
  else
    <do the thing>
  fi
}
```

So you can comment out phases, reorder them, or run individual phases by editing `main()`. It's a starting point, not a fixed recipe.

## What's deliberately not automated

- Accessibility permissions (Apple makes these manual on purpose)
- App license keys (paste them yourself; store in 1Password)
- App preferences/themes (use each app's own sync feature)
- iCloud sign-in (personal decision per machine)

## Adding things over time

When you set up something new and want to keep it for next time, add it to the relevant file:

- New CLI tool → `Brewfile`
- New shell config → the heredoc block in `phase_3_shell` of `setup.sh`
- New macOS tweak → `macos-defaults.sh`
- New check → `verify.sh`

Commit to git after each change. Future-you will be grateful.
