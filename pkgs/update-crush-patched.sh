#!/usr/bin/env bash
# Auto-update crush-patched: version, vendorHash, build - all automated
# Usage: ./pkgs/update-crush-patched.sh [VERSION]
# If VERSION not provided, assumes current version is up to date

set -uo pipefail

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

# If no version provided, auto-detect latest from GitHub
if [[ -z "$NEW_VERSION" ]]; then
    echo "🔍 Detecting latest version from GitHub..."
    LATEST_VERSION=$(git ls-remote --tags --sort=-v:refname https://github.com/charmbracelet/crush.git \
      | head -1 | sed 's|.*refs/tags/\(v[0-9.]*\).*|\1|')

    if [[ -z "$LATEST_VERSION" ]]; then
        echo "❌ Failed to detect latest version from GitHub"
        exit 1
    fi

    echo "Latest:  $LATEST_VERSION"

    if [[ "$LATEST_VERSION" == "$CURRENT_VERSION" ]]; then
        echo "✅ Already at latest version $CURRENT_VERSION"
        exit 0
    fi

    NEW_VERSION="$LATEST_VERSION"
    echo "Target:  $NEW_VERSION"
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

# Backup original Nix file
BACKUP_FILE="${NIX_FILE}.backup-$(date +%s)"
cp "$NIX_FILE" "$BACKUP_FILE"

# Update Nix file
echo ""
echo "📝 Updating $NIX_FILE..."
sed -i.tmp \
  -e "s|^  version = \".*\";|  version = \"$NEW_VERSION\";|" \
  -e "s|^    url = \".*\";$|    url = \"$SOURCE_URL\";|" \
  -e "s|^    sha256 = \".*\";|    sha256 = \"$SOURCE_HASH\";|" \
  -e "s|^  vendorHash = \".*\";|  vendorHash = null;|" \
  "$NIX_FILE"
rm -f "${NIX_FILE}.tmp"
echo "✅ Version updated to $NEW_VERSION"

# Build to get vendorHash
echo ""
echo "🔨 Building to detect vendorHash..."
nix build .#crush-patched 2>&1 | tee /tmp/crush-build.log || true

if grep -q "got:.*sha256-" /tmp/crush-build.log; then
    # Extract hash from error message (build succeeded but vendorHash was wrong)
    VENDOR_HASH=$(grep 'got:.*sha256-' /tmp/crush-build.log | \
      sed 's/.*sha256-//' | head -1)
elif [[ -f ./result ]]; then
    # Build succeeded, extract from store
    echo "✅ Build succeeded!"
    VENDOR_HASH=$(nix-store --query --requisites ./result 2>/dev/null | \
      grep 'crush-patched.*go-modules' | sed 's|.*/\([a-z0-9]*\)-.*|\1|' | head -1)
else
    # Build failed for real reason (patches, etc.)
    VENDOR_HASH=""
fi

if [[ -z "$VENDOR_HASH" ]]; then
    echo "❌ Could not extract vendorHash"
    echo "   Check /tmp/crush-build.log"
    echo ""
    echo "🔄 Rolling back to previous version..."
    cp "$BACKUP_FILE" "$NIX_FILE"
    rm -f "$BACKUP_FILE"
    echo "✅ Rolled back to $CURRENT_VERSION"
    echo "   Your system is in a consistent state."
    echo ""
    echo "💡 This usually means patches need to be updated for the new version."
    echo "   Check pkgs/crush-patched.nix to update or remove incompatible patches."
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
if ! nix build .#crush-patched 2>&1 | tee /tmp/crush-build-final.log; then
    echo ""
    echo "❌ Final build failed"
    echo "   Check /tmp/crush-build-final.log"
    echo ""
    echo "🔄 Rolling back to previous version..."
    cp "$BACKUP_FILE" "$NIX_FILE"
    rm -f "$BACKUP_FILE"
    echo "✅ Rolled back to $CURRENT_VERSION"
    echo "   Your system is in a consistent state."
    exit 1
fi

# Clean up backup on success
rm -f "$BACKUP_FILE"

echo ""
echo "✅ Update complete! Run 'just switch' to install."
