#!/usr/bin/env bash
# Update to the latest version of Crush from NUR (Nix User Repository)
# This script ensures you're always on the bleeding edge version
#
# Usage: ./scripts/update-crush-latest.sh [--switch]
#   --switch: Automatically switch to the new configuration after building

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SWITCH=false
if [ "$1" = "--switch" ]; then
  SWITCH=true
fi

echo "🚀 Checking for latest Crush version from NUR..."

# Get current version info
echo ""
echo "Current system Crush:"
crush --version 2>/dev/null || echo "  (will be installed)"

# Check what NUR has
echo ""
echo "📡 Fetching latest NUR Crush version..."
NUR_VERSION=$(nix eval --json 'github:nix-community/NUR#repos.charmbracelet.crush.version' 2>/dev/null || echo "unknown")
echo "  NUR has: v$NUR_VERSION"

# Update flake inputs to get latest NUR
echo ""
echo "📦 Updating flake inputs (NUR)..."
cd "$REPO_ROOT"
nix flake update nur

# Build the new configuration
echo ""
echo "🔨 Building NixOS configuration with latest Crush..."
nix build .#nixosConfigurations.evo-x2.config.system.build.toplevel

echo ""
echo "✅ Build complete!"
echo ""

# Show what version we'll have
echo "📊 Version update:"
echo "  Before: $(crush --version 2>/dev/null | cut -d' ' -f3 || echo 'N/A')"
NEW_CRUSH_PATH=$(find /nix/store -maxdepth 1 -name "*crush*" -newer /nix/store/.links 2>/dev/null | grep -E "crush-[0-9]" | head -1)
if [ -n "$NEW_CRUSH_PATH" ]; then
  echo "  After:  $($NEW_CRUSH_PATH/bin/crush --version | cut -d' ' -f3)"
fi

if [ "$SWITCH" = true ]; then
  echo ""
  echo "🔄 Switching to new configuration..."
  sudo ./result/bin/switch-to-configuration switch
  echo ""
  echo "✨ Crush updated! New version:"
  crush --version
else
  echo ""
  echo "📝 To activate the new configuration, run:"
  echo "  sudo ./result/bin/switch-to-configuration switch"
  echo ""
  echo "Or use your usual switch command:"
  echo "  just switch"
fi
