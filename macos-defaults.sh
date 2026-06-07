#!/usr/bin/env bash
#
# macos-defaults.sh — sensible macOS preferences for development
#
# Most of these are idempotent (safe to run repeatedly). A few changes
# require a logout to fully apply.
#

set -uo pipefail

echo "Applying macOS defaults..."

# ─── Finder ────────────────────────────────────────────────────────
defaults write com.apple.finder AppleShowAllFiles -bool true          # Show hidden files
defaults write com.apple.finder ShowPathbar -bool true                # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true              # Show status bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true    # Full path in title
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # List view by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true       # Show all extensions
chflags nohidden ~/Library                                            # Show Library folder

# ─── Dock ──────────────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true                     # Auto-hide
defaults write com.apple.dock autohide-delay -float 0                 # No delay
defaults write com.apple.dock autohide-time-modifier -float 0.4       # Faster animation
defaults write com.apple.dock show-process-indicators -bool true      # Dots under open apps
defaults write com.apple.dock mineffect -string "scale"               # Faster minimize
defaults write com.apple.dock show-recents -bool false                # Hide recent apps section

# ─── Keyboard ──────────────────────────────────────────────────────
defaults write NSGlobalDomain KeyRepeat -int 2                        # Fast repeat rate
defaults write NSGlobalDomain InitialKeyRepeat -int 15                # Short delay before repeat
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false    # Enable key repeat in all apps (important for Vim users)

# ─── Trackpad ──────────────────────────────────────────────────────
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1                  # Tap to click everywhere

# ─── Screenshots ───────────────────────────────────────────────────
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true      # No drop shadow

# ─── Chrome ────────────────────────────────────────────────────────
# Prevent left/right swipe from navigating back/forward (annoying when scrolling)
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

# ─── Safari (for dev) ──────────────────────────────────────────────
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# ─── Misc ──────────────────────────────────────────────────────────
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false  # Save to disk, not iCloud, by default
defaults write com.apple.LaunchServices LSQuarantine -bool false             # Disable "are you sure you want to open" dialog

# ─── Restart affected services ─────────────────────────────────────
for app in Finder Dock SystemUIServer; do
  killall "$app" 2>/dev/null || true
done

echo "Done. Some changes require a logout to fully apply."
