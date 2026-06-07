#!/usr/bin/env bash
#
# adapt-this-mac.sh — switch THIS machine over to the new (zsh, no-Zellij) setup.
# It reuses setup.sh's phase functions and:
#
#   • backs up everything it touches first (timestamped, fully reversible)
#   • installs the missing apps/CLI, VS Code extensions, shell + configs, languages
#   • SWITCHES you off fish + Zellij onto the new setup:
#       - sets your login shell to zsh
#       - replaces the Ghostty config (stops the Zellij autostart / key-forwarding)
#     fish & Zellij stay INSTALLED but unused — `brew uninstall fish zellij` to remove.
#   • SKIPS the two intrusive phases:
#       - git/SSH        → would repoint ~/.ssh/config at the 1Password agent and
#                          break your current (on-disk-key) GitHub SSH
#       - macOS defaults → rewrites Finder/Dock/keyboard prefs and restarts the UI
#
# Usage:   ./adapt-this-mac.sh
# Re-run:  safe — already-done steps skip.
#

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helpers + phase functions from setup.sh WITHOUT running its main().
# (setup.sh enables `set -euo pipefail`; relax -e afterward so a single failed
#  cask — e.g. an app you already installed outside brew — won't abort the adapt.)
source "$HERE/setup.sh"
set +e

echo "${BOLD}Adapt this Mac to the setup repo${NC}"
echo "================================="
echo ""

# ─── Backups (so everything here is reversible) ────────────────────
BK="$HOME/mac-setup-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
info "Backing up current state to: $BK"
cp ~/.zshrc      "$BK/zshrc"      2>/dev/null && success "saved ~/.zshrc"
cp ~/.gitconfig  "$BK/gitconfig"  2>/dev/null
cp ~/.ssh/config "$BK/ssh_config" 2>/dev/null
git config --global --list > "$BK/gitconfig.list" 2>/dev/null
if brew bundle dump --describe --force --file="$BK/Brewfile.before" 2>/dev/null; then
  success "snapshotted current Homebrew state -> $BK/Brewfile.before"
fi
for d in com.apple.finder com.apple.dock NSGlobalDomain com.apple.screencapture; do
  defaults export "$d" "$BK/defaults.$d.plist" 2>/dev/null
done
# The fish + Zellij + Ghostty state we're about to switch away from
cp -R ~/.config/fish   "$BK/fish"   2>/dev/null && success "saved ~/.config/fish"
cp -R ~/.config/zellij "$BK/zellij" 2>/dev/null && success "saved ~/.config/zellij"
cp "$HOME/Library/Application Support/com.mitchellh.ghostty/config" \
   "$BK/ghostty.appsupport.config" 2>/dev/null && success "saved Ghostty config"
dscl . -read "/Users/$USER" UserShell > "$BK/login-shell.txt" 2>/dev/null
success "Backups complete in $BK"
warn  "To fully revert: cp $BK/zshrc ~/.zshrc ; cp $BK/ghostty.appsupport.config \\"
warn  "  \"\$HOME/Library/Application Support/com.mitchellh.ghostty/config\" ; chsh -s /opt/homebrew/bin/fish"
echo ""

# ─── Additive phases (reused from setup.sh, in dependency order) ───

# Casks you already have or don't want on THIS machine. The repo Brewfile is left
# untouched — a fresh machine via setup.sh still gets every one of these.
ADAPT_SKIP_CASKS=(
  tuna 1password                         # already installed (1password-cli still installs)
  slack obsidian paste                   # not needed here
  google-chrome firefox                  # browsers — already installed
  ghostty cmux conductor claude chatgpt  # terminal & agent tools — already installed
  zed visual-studio-code                 # editors — already installed
)
ADAPT_BREWFILE="$BK/Brewfile.adapt"
skip_re="$(IFS='|'; echo "${ADAPT_SKIP_CASKS[*]}")"
grep -Ev "^[[:space:]]*cask \"(${skip_re})\"" "$HERE/Brewfile" > "$ADAPT_BREWFILE"
info "Trimmed Brewfile (skipping ${#ADAPT_SKIP_CASKS[@]} casks you don't need here): $ADAPT_BREWFILE"

phase_2_apps "$ADAPT_BREWFILE"  # installs only what's missing & wanted: CLI tools +
                                # OrbStack, TablePlus, Bruno, Rectangle, op, homerow, …
phase_2_5_vscode_extensions  # extensions (already in sync — effectively a refresh)
phase_3_shell                # appends the managed ~/.zshrc block + deploys configs
                             # (Zed settings already exist here, so they're left alone)
phase_5_languages            # mise install (node, go) + latest Python via uv

# ─── Switch off fish + Zellij onto the new setup ───────────────────
echo ""
info "Switching this machine to the new setup (fish + Zellij -> zsh)…"

# Ghostty: macOS loads the Application Support config LAST (it wins), so write the
# clean repo config there, replacing the one that launches/forwards to Zellij.
GHOSTTY_APPSUP="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
mkdir -p "$(dirname "$GHOSTTY_APPSUP")"
if cp "$HERE/config/ghostty/config" "$GHOSTTY_APPSUP"; then
  success "Ghostty config replaced (old one backed up in $BK)"
fi

# Login shell: fish -> zsh (system /bin/zsh is already in /etc/shells).
current_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$current_shell" = "/bin/zsh" ]; then
  success "login shell already /bin/zsh"
else
  info "Setting login shell to zsh (you'll be prompted for your password)…"
  if chsh -s /bin/zsh; then
    success "login shell set to /bin/zsh — new terminals open in the new setup"
  else
    warn "chsh failed — set it yourself with:  chsh -s /bin/zsh"
  fi
fi

# ─── Deliberately NOT run here ─────────────────────────────────────
echo ""
warn "Skipped on purpose — run manually only if you want them on THIS machine:"
warn "  • git/SSH     : setup.sh phase_4 — but set up the 1Password SSH agent FIRST,"
warn "                  or it will break your current GitHub SSH."
warn "  • macOS prefs : preview ->  sed 's/^defaults write/echo &/' macos-defaults.sh | bash"
warn "                  apply   ->  bash macos-defaults.sh   (domains backed up above)"
echo ""
warn "Apps you already had may show as 'needs install' (they're not brew-managed)."
warn "To hand them to brew without redownloading:  brew install --cask --adopt <name>"
echo ""
success "Done. Open a NEW terminal (you'll land in zsh), then run ./verify.sh."
