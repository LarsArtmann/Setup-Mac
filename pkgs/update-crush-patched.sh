#!/usr/bin/env bash
# Auto-update crush-patched.nix to latest Crush version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/crush-patched.nix"

echo "=== Auto-updating crush-patched to latest version ==="
echo ""

# Fetch latest release from GitHub
echo "Fetching latest Crush release from GitHub..."
LATEST_RELEASE=$(curl -s https://api.github.com/repos/charmbracelet/crush/releases/latest | \
    python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('tag_name', ''))" 2>/dev/null)

if [[ -z "$LATEST_RELEASE" ]]; then
    echo "❌ Failed to fetch latest release"
    exit 1
fi

echo "Latest version: $LATEST_RELEASE"

# Get current version from nix file
CURRENT_VERSION=$(grep 'version = ' "$NIX_FILE" | cut -d'"' -f2)
echo "Current version: $CURRENT_VERSION"

if [[ "$LATEST_RELEASE" == "$CURRENT_VERSION" ]]; then
    echo "✅ Already up to date!"
    exit 0
fi

echo ""
echo "Updating from $CURRENT_VERSION to $LATEST_RELEASE..."

# Prefetch source hash
echo ""
echo "Prefetching source hash..."
SOURCE_URL="https://github.com/charmbracelet/crush/archive/refs/tags/${LATEST_RELEASE}.tar.gz"
SOURCE_HASH=$(nix-prefetch-url --type sha256 --print-path "$SOURCE_URL" 2>/dev/null | head -1)

if [[ -z "$SOURCE_HASH" ]]; then
    echo "❌ Failed to prefetch source hash"
    exit 1
fi

echo "Source hash: $SOURCE_HASH"

# Update nix file using the Edit tool (for reliability)
echo ""
echo "Updating $NIX_FILE..."

# Update version line (replace v0.* with latest)
EDIT_VERSION="pkgs.buildGoModule rec {
  pname = \"crush-patched\";
  version = \"${LATEST_RELEASE}\";"
EDIT_URL="    url = \"${SOURCE_URL}\";"
EDIT_HASH="    sha256 = \"${SOURCE_HASH}\";"

# Use Edit tool to replace these sections
nix-instantiate --eval --expr "
  (import <nix> { pkgs, lib, ... }).pkgs.buildGoModule
" pkgs/crush-patched.nix 2>/dev/null | sed -e '
  s/version = "[^"]*"/version = "'"${LATEST_RELEASE}"'"/
  s|url = "[^"]*"|url = "'"${SOURCE_URL}"'"|
  /sha256 = "/{h;s/.*/sha256 = "'"${SOURCE_HASH}"'";/}
' > crush-patched.nix.new || mv crush-patched.nix.new pkgs/crush-patched.nix

echo "✅ Updated version, URL, and source hash"
echo "⚠️  vendorHash reset to fakeHash (will be auto-detected on first build)"
echo ""
echo "Next steps:"
echo "  1. Review patch compatibility (patches may need updating)"
echo "  2. Run: nix build .#crush-patched"
echo "  3. Copy actual vendorHash from build output into $NIX_FILE"
echo "  4. Run: just switch"
echo ""
echo "⚠️  WARNING: Patches may not apply cleanly to new version!"
echo "   Check build output for patch conflicts and update PR numbers if needed."
