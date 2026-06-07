#!/usr/bin/env bash
#
# setup.sh — Mac setup orchestrator
#
# Runs in phases with pauses for manual steps. Idempotent: safe to re-run
# at any point. If a phase fails, fix the issue and re-run from the top.
#
# Usage:  ./setup.sh
#

set -euo pipefail

# ─── Colors ────────────────────────────────────────────────────────
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
NC=$'\033[0m'

info()    { echo "${BLUE}[INFO]${NC} $1"; }
success() { echo "${GREEN}[ OK ]${NC} $1"; }
warn()    { echo "${YELLOW}[WARN]${NC} $1"; }
err()     { echo "${RED}[ERR ]${NC} $1" >&2; }

pause() {
  echo ""
  echo "${YELLOW}${BOLD}━━━ MANUAL STEP ━━━${NC}"
  echo "$1"
  echo ""
  read -rp "Press enter when done..."
  echo ""
}

# Copy a starter config into place, but never clobber an existing one.
deploy_config() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    warn "missing starter config: $src (skipping)"
  elif [ -e "$dest" ]; then
    success "config already present, leaving as-is: $dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    success "installed config: $dest"
  fi
}

# ─── Phase 1: Prerequisites ────────────────────────────────────────
phase_1_prereqs() {
  info "Phase 1: Prerequisites"

  # Xcode Command Line Tools
  if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install || true
    pause "A popup will install Xcode CLI tools. Wait for it to finish, then continue."
  else
    success "Xcode CLI tools already installed"
  fi

  # Homebrew (Apple Silicon path)
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for current and future shells
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    success "Homebrew already installed"
  fi
}

# ─── Phase 2: Install everything from Brewfile ─────────────────────
phase_2_apps() {
  info "Phase 2: Installing apps via Brewfile"
  # Optional $1 = path to a Brewfile (adapt-this-mac.sh passes a trimmed one);
  # defaults to the repo Brewfile for a normal setup run.
  local brewfile; brewfile="${1:-$(dirname "$0")/Brewfile}"

  # `brew update` first: a stale Homebrew can crash on the cask API.
  brew update

  # brew bundle attempts EVERY entry and exits non-zero if any failed. Wrapping
  # it in `if` keeps `set -e` from aborting the whole run over one flaky/renamed
  # cask — so shell/git/ssh/macOS phases still happen. Report what's left.
  if brew bundle --file="$brewfile"; then
    success "Brewfile complete"
  else
    warn "Some Brewfile entries failed. Continuing with the rest of setup."
    warn "Still missing:"
    brew bundle check --file="$brewfile" --verbose || true
    warn "Fix or comment those out, then re-run:  brew bundle --file=\"$brewfile\""
  fi
}

# ─── Phase 2.5: VS Code extensions ─────────────────────────────────
# Restores the extension set captured in vscode-extensions.txt
# (regenerate anytime with: code --list-extensions > vscode-extensions.txt).
phase_2_5_vscode_extensions() {
  info "Phase 2.5: VS Code extensions"
  local ext_file; ext_file="$(dirname "$0")/vscode-extensions.txt"

  if ! command -v code &>/dev/null; then
    warn "'code' CLI not on PATH — open VS Code once, run the command palette's"
    warn "'Shell Command: Install code command in PATH', then re-run this phase."
    return 0
  fi
  if [ ! -f "$ext_file" ]; then
    warn "vscode-extensions.txt not found — skipping"
    return 0
  fi

  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    code --install-extension "$ext" --force
  done < "$ext_file"
  success "VS Code extensions installed"
}

# ─── Phase 3: Shell configuration ──────────────────────────────────
phase_3_shell() {
  info "Phase 3: Shell setup"

  # Add config block to .zshrc only if not already there
  if ! grep -q "# >>> mac-setup managed >>>" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc <<'EOF'

# >>> mac-setup managed >>>
# Starship prompt (must be near the end of the file)
eval "$(starship init zsh)"

# mise (Node, Go, etc.)
eval "$(mise activate zsh)"

# direnv (per-project env vars)
eval "$(direnv hook zsh)"

# zoxide (smarter cd — `z <partial-dir>` jumps to your most-used match)
eval "$(zoxide init zsh)"

# fzf (fuzzy finder — Ctrl+R for history, Ctrl+T for files)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Completion system + plugins — ORDER MATTERS:
#   compinit → fzf-tab → zsh-autosuggestions → zsh-syntax-highlighting (must be last).
# fzf-tab turns TAB completion into a fuzzy, previewable fzf picker; it has to load
# after compinit and before the two widget-wrapping plugins below.
(( $+functions[compdef] )) || { autoload -Uz compinit && compinit }
source "$(brew --prefix)/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# History — bigger, shared across tabs, deduped
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS EXTENDED_HISTORY

# fzf — drive it with fd (respects .gitignore) + TokyoNight Night colors
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 60% --layout reverse --border --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff,info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"

# fzf-tab — preview dirs with eza, files with bat
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always "$realpath"'
zstyle ':fzf-tab:complete:*:*' fzf-preview '[ -d "$realpath" ] && eza -1 --color=always --icons=always "$realpath" || bat --color=always --style=numbers --line-range=:200 "$realpath" 2>/dev/null'

# bat — colored man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# Modern CLI replacements
alias ls='eza'
alias ll='eza -lah --git'
# Deliberately NOT aliasing cat/find/grep — their real behavior is relied on by
# scripts and muscle memory (fd's syntax differs from find entirely).
# Use `bat`, `fd`, and `rg` explicitly when you want them.

# Git shortcuts
alias gs='git status'
alias gp='git push'
alias gco='git checkout'
alias gl='git log --oneline --decorate --graph'

# `tools`        — cheat-sheet of the CLI tools you have (name · what · example)
# `tools <term>` — filter (e.g. `tools git`, `tools json`). "(opt)" = not installed by default.
tools() {
  local f="$HOME/.config/cli-tools.tsv"
  [ -f "$f" ] || { echo "cli-tools.tsv not found — deploy it from your mac_setup repo"; return 1; }
  if [ -n "$1" ]; then
    { head -1 "$f"; grep -i -- "$1" "$f"; } | column -t -s $'\t'
  else
    column -t -s $'\t' "$f"
  fi
}

# claude-backup — archive chat transcripts now (also runs daily via launchd)
alias claude-backup="$HOME/.claude/backup-transcripts.sh"

# wt-prune — remove git worktrees whose branch is merged into the default branch.
# Skips dirty worktrees and the main checkout. (Squash-merged branches can't be
# detected by git as merged — remove those with `git worktree remove <path>`.)
wt-prune() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not in a git repo"; return 1; }
  local base main_wt wt br
  base="$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null)"; : "${base:=origin/main}"
  main_wt="$(git rev-parse --show-toplevel)"
  git worktree list --porcelain | awk '/^worktree /{print $2}' | while IFS= read -r wt; do
    [ "$wt" = "$main_wt" ] && continue
    br="$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null)"
    [ -z "$br" ] && { echo "skip (detached): $wt"; continue; }
    if git merge-base --is-ancestor "$br" "$base" 2>/dev/null; then
      if git worktree remove "$wt" 2>/dev/null; then
        git branch -d "$br" 2>/dev/null; echo "pruned: $wt ($br)"
      else
        echo "skip (uncommitted changes): $wt ($br)"
      fi
    else
      echo "keep (not merged): $wt ($br)"
    fi
  done
}

# wt-local <name> — create a worktree from your CURRENT local HEAD (claude
# --worktree branches from origin/HEAD instead), copy any .worktreeinclude
# files, and cd in. Then run `claude` or `codex` there.
wt-local() {
  [ -n "$1" ] || { echo "usage: wt-local <name>"; return 1; }
  local root dir line
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not in a git repo"; return 1; }
  dir="$root/.claude/worktrees/$1"
  git worktree add "$dir" -b "worktree-$1" HEAD || return 1
  if [ -f "$root/.worktreeinclude" ]; then
    while read -r line; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      [ -e "$root/$line" ] && { mkdir -p "$dir/$(dirname "$line")"; cp -R "$root/$line" "$dir/$line"; }
    done < "$root/.worktreeinclude"
  fi
  cd "$dir" && echo "→ $dir  (branch worktree-$1, from local HEAD). Run: claude  or  codex"
}
# <<< mac-setup managed <<<
EOF
    success "Shell config added to ~/.zshrc"
  else
    success "Shell config already in ~/.zshrc"
  fi

  # fzf keybindings (Ctrl+R, Ctrl+T)
  if [ ! -f ~/.fzf.zsh ]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish
  fi

  # Starter configs (never overwrite an existing one)
  local cfg; cfg="$(dirname "$0")/config"
  # Ghostty on macOS reads from Application Support (it loads last / wins over XDG,
  # and is what the in-app Settings opens), so deploy there — not ~/.config — to
  # avoid a competing second config file.
  deploy_config "$cfg/ghostty/config"    "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  deploy_config "$cfg/starship.toml"     "$HOME/.config/starship.toml"
  deploy_config "$cfg/mise/config.toml"  "$HOME/.config/mise/config.toml"
  deploy_config "$cfg/zed/settings.json" "$HOME/.config/zed/settings.json"
  deploy_config "$cfg/zed/keymap.json"   "$HOME/.config/zed/keymap.json"
  deploy_config "$cfg/cli-tools.tsv"     "$HOME/.config/cli-tools.tsv"
  deploy_config "$cfg/git/ignore"        "$HOME/.config/git/ignore"

  # Karabiner "hold ⌘Q to quit" rule — copied in; you still ENABLE it in the
  # Karabiner UI (Complex Modifications → Add rule). See phase 8.
  deploy_config "$(dirname "$0")/karabiner/cmd-q-hold.json" \
    "$HOME/.config/karabiner/assets/complex_modifications/cmd-q-hold.json"
}

# ─── Phase 4: Git + SSH (1Password-managed) ────────────────────────
# Private SSH keys live in 1Password's vault, never on disk.
# ssh, git, and other tools talk to 1Password's agent socket.
# You approve each use with Touch ID.
phase_4_git_ssh() {
  info "Phase 4: Git and SSH (1Password SSH agent)"

  # Git identity
  if [ -z "$(git config --global user.name || true)" ]; then
    read -rp "Git user name: " GIT_NAME
    read -rp "Git user email: " GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
  fi

  # Sensible Git defaults
  git config --global init.defaultBranch main
  git config --global push.autoSetupRemote true
  git config --global pull.rebase false
  git config --global core.excludesfile ~/.config/git/ignore
  git config --global core.pager 'delta'
  git config --global interactive.diffFilter 'delta --color-only'
  git config --global delta.navigate true
  git config --global delta.line-numbers true
  git config --global merge.conflictstyle diff3

  # Commit signing via SSH key (1Password supports this natively).
  # gpg.format + program are safe to set now. commit.gpgsign / tag.gpgsign are
  # enabled LATER, only once a signing key actually exists — otherwise every
  # `git commit` would fail with "gpg failed to sign the data" in the meantime.
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

  success "Git configured (SSH commit signing prepared)"

  # ~/.ssh/config — point at the 1Password agent socket
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  if ! grep -q "1password" ~/.ssh/config 2>/dev/null; then
    cat >> ~/.ssh/config <<'EOF'

# 1Password SSH agent
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
    chmod 600 ~/.ssh/config
    success "~/.ssh/config points at 1Password agent"
  else
    success "~/.ssh/config already configured for 1Password"
  fi

  # If a stale on-disk key from a previous run exists, warn about it
  if [ -f ~/.ssh/id_ed25519 ]; then
    warn "Found ~/.ssh/id_ed25519 on disk."
    warn "If you're switching to 1Password-managed keys, you can delete this"
    warn "(and id_ed25519.pub) after you've verified the 1Password key works."
  fi

  pause "Now create your SSH key inside 1Password:

  1. Open 1Password
  2. Settings → Developer → enable:
       • 'Use the SSH agent'
       • 'Display key names when authorizing connections'
  3. + New Item → SSH Key → 'Add SSH Key' → Generate a new key
     • Type: Ed25519
     • Title: 'GitHub - <work or personal>'
  4. Click 'Configure' on the new key → 'Copy Public Key'
  5. Add the public key to GitHub at:
       https://github.com/settings/ssh/new
     (Use 'Authentication Key' type — we'll add it again as a Signing Key in the next step)
  6. Add the SAME public key again as a 'Signing Key' at:
       https://github.com/settings/ssh/new
     This lets GitHub mark your commits as 'Verified'.

Come back when done."

  # Test SSH to GitHub through the 1Password agent
  info "Testing SSH to GitHub (Touch ID prompt will appear)..."
  ssh -o StrictHostKeyChecking=accept-new -T git@github.com || true

  pause "Last step: set the signing key for Git.

  1. In 1Password, open your new SSH key item
  2. Copy the PUBLIC key text (starts with 'ssh-ed25519 AAAA...')
  3. Paste it here when prompted."

  read -rp "Paste your public key here: " SIGNING_KEY
  if [ -n "$SIGNING_KEY" ]; then
    # Store the public key in a file that Git can reference
    mkdir -p ~/.config/git
    echo "$SIGNING_KEY" > ~/.config/git/signing_key.pub
    chmod 644 ~/.config/git/signing_key.pub
    git config --global user.signingkey ~/.config/git/signing_key.pub
    # Now that a key exists, it's safe to turn signing on.
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true
    success "Commit signing configured. Your commits will now be signed via SSH (1Password)."
  else
    warn "No key pasted — skipping signing config. Run this phase again later if you want it."
  fi
}

# ─── Phase 5: Language toolchains ──────────────────────────────────
phase_5_languages() {
  info "Phase 5: Languages"

  # mise needs to be activated for this shell
  eval "$(mise activate bash)"

  # Global tool versions live in ~/.config/mise/config.toml (deployed in phase 3).
  # `mise install` reads that file and installs everything it declares (Node, Go).
  mise install

  # Python via uv (separate from mise — better Python toolchain).
  # No version pin → installs the latest available CPython.
  uv python install

  # Standalone Python CLIs (installed as isolated uv tools)
  uv tool install claude-code-transcripts   # render Claude sessions to HTML

  success "Languages installed (mise tools from config.toml + latest Python via uv)"
}

# ─── Phase 3.5: 1Password sign-in (needed before SSH setup) ────────
phase_3_5_1password() {
  pause "Sign into 1Password now — it's needed for the next phase.

  1. Open 1Password from /Applications
  2. Sign in with your account
  3. Settings → Developer → enable:
       • 'Use the SSH agent'
       • 'Display key names when authorizing connections'
       • 'Integrate with 1Password CLI' (lets the 'op' command work)
  4. Settings → Security → enable Touch ID unlock if you want it

Come back when 1Password is unlocked and the SSH agent is enabled."
}

# ─── Phase 6: Sign-in to remaining apps ────────────────────────────
phase_6_signin() {
  pause "Sign into your other installed apps now:

  • Slack       → your workspace
  • Zed         → your account (for sync) if you want
  • Chrome      → your Google account for bookmark sync (or skip)
  • Conductor   → log in with your Claude account
  • cmux        → it'll use your existing Claude Code login
  • Bruno       → no account needed
  • TablePlus   → enter your license or start the trial

Then come back here."
}

# ─── Phase 7: macOS defaults ───────────────────────────────────────
phase_7_macos_defaults() {
  info "Phase 7: macOS preferences"
  bash "$(dirname "$0")/macos-defaults.sh"
}

# ─── Phase 8: Accessibility permissions ────────────────────────────
phase_8_permissions() {
  pause "The following apps need Accessibility permission to work fully.
Grant them in:  System Settings → Privacy & Security → Accessibility

  • Rectangle  (required for window snapping)
  • Tuna       (required for global hotkeys)
  • Homerow    (if you installed it)
  • cmux       (for some keyboard features)
  • Karabiner-Elements (needs Input Monitoring + Accessibility for key remapping)

Then ENABLE the quit-shortcut rule (the file was copied into place in phase 3):
  Karabiner-Elements → Complex Modifications → Add rule →
  enable 'Hold ⌘Q for 1 second to quit'

macOS will also prompt you on first use, so this can wait if you prefer."
}

# ─── Phase 9: AI agents CLI ────────────────────────────────────────
phase_9_ai_agents() {
  info "Phase 9: AI agent CLIs"

  # Claude Code via npm (installed by mise's node)
  if ! command -v claude &>/dev/null; then
    npm install -g @anthropic-ai/claude-code
    success "Claude Code installed"
  else
    success "Claude Code already installed"
  fi

  # Codex CLI — uncomment if you want it
  # if ! command -v codex &>/dev/null; then
  #   npm install -g @openai/codex
  # fi

  # Global Claude defaults — merge without clobbering anything Claude writes itself:
  #  • cleanupPeriodDays  — transcript retention + stale subagent/background worktree
  #                         sweep (NOT your named `--worktree` dirs).
  #  • remoteControlAtStartup — turn on Remote Control for every interactive session
  #                         (the /config "Enable Remote Control for all sessions" toggle),
  #                         so you can drive any session from claude.ai or the mobile app.
  #                         Requires a claude.ai (Pro/Max/Team/Enterprise) login; on
  #                         Team/Enterprise an admin must also enable the org-wide toggle.
  mkdir -p ~/.claude
  CLAUDE_DEFAULTS='{ "cleanupPeriodDays": 14, "remoteControlAtStartup": true }'
  if [ -f ~/.claude/settings.json ]; then
    tmp="$(mktemp)"
    jq --argjson d "$CLAUDE_DEFAULTS" '. + $d' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
  else
    echo "$CLAUDE_DEFAULTS" > ~/.claude/settings.json
  fi
  success "Claude defaults set (cleanupPeriodDays=14, remoteControlAtStartup=true)"

  # Transcript backup forever: install the script and schedule it daily. rsync
  # has no --delete, so transcripts Claude later prunes are kept in the archive.
  cp "$(dirname "$0")/config/claude/backup-transcripts.sh" ~/.claude/backup-transcripts.sh
  chmod +x ~/.claude/backup-transcripts.sh
  mkdir -p ~/Library/LaunchAgents
  cat > ~/Library/LaunchAgents/com.claude.transcripts-backup.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.claude.transcripts-backup</string>
  <key>ProgramArguments</key>
  <array><string>$HOME/.claude/backup-transcripts.sh</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$HOME/.claude/backup-transcripts.log</string>
  <key>StandardErrorPath</key><string>$HOME/.claude/backup-transcripts.log</string>
</dict>
</plist>
PLIST
  launchctl bootout "gui/$(id -u)/com.claude.transcripts-backup" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.claude.transcripts-backup.plist || true
  success "Transcript backup scheduled daily -> ~/Documents/Claude-Transcripts"

  pause "Run \`claude\` once to log in to Claude Code, then return here.
(You can skip this and do it later inside cmux/Conductor.)"
}

# ─── Main ──────────────────────────────────────────────────────────
main() {
  echo "${BOLD}Mac setup script${NC}"
  echo "================="
  echo ""

  phase_1_prereqs
  phase_2_apps
  phase_2_5_vscode_extensions
  phase_3_shell
  phase_3_5_1password
  phase_4_git_ssh
  phase_5_languages
  phase_6_signin
  phase_7_macos_defaults
  phase_8_permissions
  phase_9_ai_agents

  echo ""
  success "All phases complete."
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal so the new shell config takes effect"
  echo "  2. Run ./verify.sh to confirm everything is installed"
  echo "  3. Clone your dotfiles repo when you have one"
  echo "  4. Configure Zed and Ghostty/cmux to your preferences"
}

# Only auto-run when executed directly — not when sourced (e.g. by adapt-this-mac.sh,
# which reuses the phase functions above without running the whole flow).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
