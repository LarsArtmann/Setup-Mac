#!/usr/bin/env bash
# Quick fix for updating GitHub token - uses sudo for sops
# Run this on evo-x2

set -euo pipefail

cd ~/Setup-Mac || cd ~/projects/SystemNix || exit 1

# Get token from gh
GITHUB_TOKEN=$(gh auth token)
GITHUB_USER=$(gh api user -q .login 2>/dev/null || echo "")

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: No GitHub token. Run: gh auth login"
  exit 1
fi

echo "Got token for user: $GITHUB_USER"

# Use sudo with the SSH key for sops
SECRETS_FILE="platforms/nixos/secrets/secrets.yaml"
SSH_KEY="/etc/ssh/ssh_host_ed25519_key"

# Set up environment for sops to use the host SSH key
export SOPS_AGE_SSH_PRIVATE_KEY_FILE="$SSH_KEY"

echo "Updating github_token..."
sudo -E sops set "$SECRETS_FILE" '["github_token"]' "\"$GITHUB_TOKEN\""

echo "Updating github_user..."
sudo -E sops set "$SECRETS_FILE" '["github_user"]' "\"$GITHUB_USER\""

echo ""
echo "✅ Done! Now run: nh os switch ."
