#!/usr/bin/env bash
# Auto-update crush-patched: version, vendorHash, build - all automated
# Usage: ./pkgs/update-crush-patched.sh [VERSION]
# If VERSION not provided, assumes current version is up to date

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/crush-patched.nix"

# Get current version from Nix file
CURRENT_VERSION=$(grep 'version = ' "$NIX_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
NEW_VERSION="${1:-}"

echo "🔄 Updating crush-patched..."
echo "Current: $CURRENT_VERSION"
if [[ -n "$NEW_VERSION" ]]; then
    echo "Target:  $NEW_VERSION"
fi

# If no version provided, check if we're already up to date
if [[ -z "$NEW_VERSION" ]]; then
    echo "ℹ️  No version specified, skipping update"
    echo "   To update to a new version, run: ./pkgs/update-crush-patched.sh v0.39.3"
    exit 0
fi

# Same version? Nothing to do
if [[ "$NEW_VERSION" == "$CURRENT_VERSION" ]]; then
    echo "✅ Already at $NEW_VERSION"
    exit 0
fi

# Prefetch source hash
echo ""
echo "📥 Fetching source hash for $NEW_VERSION..."
SOURCE_URL="https://github.com/charmbracelet/crush/archive/refs/tags/${NEW_VERSION}.tar.gz"
SOURCE_HASH=$(nix-prefetch-url --type sha256 "$SOURCE_URL" 2>/dev/null)

if [[ -z "$SOURCE_HASH" ]]; then
    echo "❌ Failed to fetch $NEW_VERSION"
    echo "   Check that version exists at: https://github.com/charmbracelet/crush/releases"
    exit 1
fi

echo "✅ Source hash: $SOURCE_HASH"

# Update Nix file
echo ""
echo "📝 Updating $NIX_FILE..."
sed -i.bak \
  -e "s|^version = \".*\";|version = \"$NEW_VERSION\";|" \
  -e "s|^    url = \".*\";$|    url = \"$SOURCE_URL\";|" \
  -e "s|^    sha256 = \".*\";|    sha256 = \"$SOURCE_HASH\";|" \
  -e "s|^  vendorHash = \".*\";|  vendorHash = null;|" \
  "$NIX_FILE"
rm -f "${NIX_FILE}.bak"
echo "✅ Version updated to $NEW_VERSION"

# Build to get vendorHash
echo ""
echo "🔨 Building to detect vendorHash..."
if nix build .#crush-patched 2>&1 | tee /tmp/crush-build.log; then
    echo "✅ Build succeeded!"
    VENDOR_HASH=$(nix-store --query --requisites ./result 2>/dev/null | \
      grep 'crush-patched.*go-modules' | sed 's|.*/\([a-z0-9]*\)-.*|\1|' | head -1)
else
    # Extract hash from error message
    VENDOR_HASH=$(grep 'got:.*sha256-' /tmp/crush-build.log | \
      sed 's/.*sha256-//' | head -1)
fi

if [[ -z "$VENDOR_HASH" ]]; then
    echo "❌ Could not extract vendorHash"
    echo "   Check /tmp/crush-build.log"
    exit 1
fi

echo "✅ vendorHash: $VENDOR_HASH"

# Update vendorHash in Nix file
echo ""
echo "📝 Updating vendorHash in $NIX_FILE..."
sed -i.bak "s|^  vendorHash = null;|  vendorHash = \"sha256-$VENDOR_HASH\";|" "$NIX_FILE"
rm -f "${NIX_FILE}.bak"
echo "✅ vendorHash updated"

# Rebuild with correct hash
echo ""
echo "🔨 Rebuilding with correct vendorHash..."
rm -f result
nix build .#crush-patched

echo ""
echo "✅ Update complete! Run 'just switch' to install."
