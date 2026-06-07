# Brewfile — declarative list of everything to install via Homebrew
# Run with: brew bundle --file=./Brewfile

# ─── CLI essentials ────────────────────────────────────────────────
brew "git"
brew "gh"                 # GitHub CLI (PRs, issues, releases from terminal)
brew "mise"               # Multi-language version manager (Node, Go, Ruby, etc.)
brew "uv"                 # Python tooling (replaces pip + venv + pyenv for Python)

# ─── Modern CLI replacements ───────────────────────────────────────
brew "ripgrep"            # rg — better grep
brew "fd"                 # better find
brew "bat"                # cat with syntax highlighting
brew "eza"                # better ls
brew "git-delta"          # better git diff viewer
brew "fzf"                # fuzzy finder (Ctrl+R for history, Ctrl+T for files)
brew "jq"                 # JSON processor
brew "yq"                 # YAML processor

# ─── Shell ─────────────────────────────────────────────────────────
brew "starship"           # Cross-shell prompt with git/lang/etc. info
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fzf-tab"            # Fuzzy, previewable TAB completion (replaces zsh's menu)
brew "direnv"             # Per-project environment variables

# ─── More CLI (recommended) ────────────────────────────────────────
brew "git-lfs"            # Version large binary files (model weights, datasets)
brew "zoxide"             # Smarter cd that learns your dirs — `z proj`
brew "lazygit"            # Fast git TUI (renders diffs via delta)
brew "tealdeer"           # tldr — example-first command help (`tldr tar`)
brew "btop"               # Interactive system / resource monitor
brew "shellcheck"         # Lint shell scripts (like the ones in this repo)
brew "shfmt"              # Format shell scripts
brew "watchexec"          # Run a command when files change (`watchexec -e py pytest`)
brew "mas"                # Mac App Store CLI — declare App Store apps too
brew "croc"               # Send files/secrets between machines securely

# ─── Optional: databases (uncomment if needed) ─────────────────────
# brew "postgresql@16"
# brew "redis"
# brew "sqlite"

# ═══════════════════════════════════════════════════════════════════
# Casks (GUI apps)
# ═══════════════════════════════════════════════════════════════════

# ─── Editors ───────────────────────────────────────────────────────
cask "zed"                # Primary editor
cask "visual-studio-code" # Backup / for things that require it

# ─── Terminal & AI agent tools ─────────────────────────────────────
cask "ghostty"            # Terminal emulator
cask "cmux"               # AI-agents-aware terminal (Ghostty-based) — in homebrew/cask
cask "conductor"          # Parallel AI agent runner with GUI dashboard — in homebrew/cask
cask "claude"
cask "chatgpt"

# ─── Browsers ──────────────────────────────────────────────────────
cask "google-chrome"      # For web dev + DevTools
cask "firefox"            # Cross-browser testing

# ─── Development ───────────────────────────────────────────────────
cask "orbstack"           # Docker alternative — way faster on Apple Silicon
cask "tableplus"          # Database GUI
cask "bruno"              # API client (Postman alternative, files in git)

# ─── Security & secrets ────────────────────────────────────────────
cask "1password"
cask "1password-cli"      # `op` command for scripting secrets

# ─── Productivity ──────────────────────────────────────────────────
cask "rectangle"          # Window management (keyboard shortcuts)
#cask "raycast"            # App launcher — left off; going with Tuna instead
cask "tuna"               # App launcher (tunaformac.com) — in homebrew/cask

# ─── Optional ──────────────────────────────────────────────────────
cask "homerow"          # Keyboard-only clicking — install once you decide
cask "karabiner-elements" # Key remapping — used for the "hold ⌘Q to quit" rule
cask "obsidian"         # Notes — if you want it
cask "paste"            # Clipboard history — you already use this

# ─── Communication ─────────────────────────────────────────────────
cask "slack"              # Work
# cask "discord"          # Add if needed

# ─── Fonts (recommended for terminal + editor) ─────────────────────
# Nerd Fonts have icons for Starship, file-type glyphs in Zed, etc.
cask "font-jetbrains-mono-nerd-font"
# cask "font-fira-code-nerd-font"   # Alternative
