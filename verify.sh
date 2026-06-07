#!/usr/bin/env bash
#
# verify.sh — Check that everything from the setup is in place.
# Run after setup.sh; prints OK/missing for each thing.
#

# Don't set -e — we want to keep going even when checks fail

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

check_cmd() {
  if command -v "$1" &>/dev/null; then
    printf "${GREEN}✓${NC} %-12s %s\n" "$1" "$(command -v "$1")"
  else
    printf "${RED}✗${NC} %-12s ${RED}missing${NC}\n" "$1"
  fi
}

check_app() {
  local name="$1"
  if [ -d "/Applications/$name.app" ] || [ -d "$HOME/Applications/$name.app" ]; then
    printf "${GREEN}✓${NC} %s.app\n" "$name"
  else
    printf "${RED}✗${NC} %s.app ${RED}missing${NC}\n" "$name"
  fi
}

echo "═══ CLI tools ═══"
check_cmd brew
check_cmd git
check_cmd gh
check_cmd mise
check_cmd uv
check_cmd rg
check_cmd fd
check_cmd bat
check_cmd eza
check_cmd fzf
check_cmd jq
check_cmd yq
check_cmd starship
check_cmd direnv
check_cmd delta

echo ""
echo "═══ Languages ═══"
check_cmd node
check_cmd npm
check_cmd go
check_cmd python3
check_cmd claude       # Claude Code

echo ""
echo "═══ Apps ═══"
check_app "Zed"
check_app "Visual Studio Code"
check_app "Ghostty"
check_app "cmux"
check_app "Conductor"
check_app "Google Chrome"
check_app "Firefox"
check_app "OrbStack"
check_app "TablePlus"
check_app "Bruno"
check_app "1Password"
check_cmd op            # 1Password CLI is a binary, not an .app bundle
check_app "Rectangle"
check_app "Tuna"        # app launcher (swap to Raycast if you change your mind)
check_app "Slack"

echo ""
echo "═══ Git config ═══"
NAME="$(git config --global user.name || echo)"
EMAIL="$(git config --global user.email || echo)"
SIGNKEY="$(git config --global user.signingkey || echo)"
GPGFMT="$(git config --global gpg.format || echo)"
[ -n "$NAME" ]  && printf "${GREEN}✓${NC} name:        %s\n" "$NAME"   || printf "${RED}✗${NC} name not set\n"
[ -n "$EMAIL" ] && printf "${GREEN}✓${NC} email:       %s\n" "$EMAIL" || printf "${RED}✗${NC} email not set\n"
[ "$GPGFMT" = "ssh" ] && printf "${GREEN}✓${NC} gpg.format:  ssh\n" || printf "${YELLOW}?${NC} gpg.format not 'ssh' (signing won't work)\n"
[ -n "$SIGNKEY" ] && printf "${GREEN}✓${NC} signingkey:  %s\n" "$SIGNKEY" || printf "${YELLOW}?${NC} no signingkey set\n"

echo ""
echo "═══ SSH (1Password agent) ═══"
# Check 1Password agent socket is configured in ~/.ssh/config
if grep -q "1password" ~/.ssh/config 2>/dev/null; then
  printf "${GREEN}✓${NC} ~/.ssh/config points at 1Password agent\n"
else
  printf "${RED}✗${NC} ~/.ssh/config doesn't reference 1Password\n"
fi

# Check the agent socket actually exists (1Password is running and SSH agent is enabled)
SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [ -S "$SOCK" ]; then
  printf "${GREEN}✓${NC} 1Password agent socket exists\n"
else
  printf "${RED}✗${NC} 1Password agent socket missing — is 1Password running with SSH agent enabled?\n"
fi

# Check ssh-add can see keys via the agent
if SSH_AUTH_SOCK="$SOCK" ssh-add -l &>/dev/null; then
  KEY_COUNT="$(SSH_AUTH_SOCK="$SOCK" ssh-add -l | wc -l | tr -d ' ')"
  printf "${GREEN}✓${NC} %s SSH key(s) loaded in 1Password agent\n" "$KEY_COUNT"
else
  printf "${YELLOW}?${NC} no SSH keys visible via agent (create one in 1Password)\n"
fi

# Warn if a stale on-disk key exists
if [ -f ~/.ssh/id_ed25519 ]; then
  printf "${YELLOW}!${NC} ~/.ssh/id_ed25519 exists on disk — delete it if you've switched to 1Password\n"
fi

# Actually test GitHub auth
if ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  printf "${GREEN}✓${NC} GitHub SSH works\n"
else
  printf "${YELLOW}?${NC} GitHub SSH not working — make sure 1Password is unlocked and the key is added to your GitHub account\n"
fi

echo ""
echo "═══ Configs ═══"
check_file() {
  if [ -e "$1" ]; then printf "${GREEN}✓${NC} %s\n" "$1"; else printf "${YELLOW}?${NC} %s ${YELLOW}not deployed${NC}\n" "$1"; fi
}
check_file "$HOME/.config/ghostty/config"
check_file "$HOME/.config/starship.toml"
check_file "$HOME/.config/mise/config.toml"
check_file "$HOME/.config/zed/settings.json"
check_file "$HOME/.config/cli-tools.tsv"
check_file "$HOME/.config/karabiner/assets/complex_modifications/cmd-q-hold.json"

echo ""
echo "Done."
